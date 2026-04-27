import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/admin_audit_service.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final AdminAuditService _auditService = AdminAuditService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _historySearchController = TextEditingController();

  String _targetRole = 'all';
  String _notificationType = 'admin_offer';
  String _popupMode = 'once_per_session';
  String _historyTargetFilter = 'all';
  bool _sending = false;
  bool _uploadingImage = false;
  DateTime? _startsAt;
  DateTime? _endsAt;
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    String imageUrl = _uploadedImageUrl ?? '';
    final hasSelectedImage = (_selectedImageName?.trim().isNotEmpty ?? false) &&
        ((kIsWeb && _selectedImageBytes != null) ||
            (!kIsWeb &&
                _selectedImagePath != null &&
                _selectedImagePath!.trim().isNotEmpty));

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titre et message obligatoires'),
        ),
      );
      return;
    }

    if (_startsAt != null && _endsAt != null && _endsAt!.isBefore(_startsAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit etre apres la date de debut'),
        ),
      );
      return;
    }

    if (hasSelectedImage && imageUrl.isEmpty) {
      imageUrl = await _uploadSelectedImage();
      if (imageUrl.isEmpty) return;
    }

    setState(() => _sending = true);

    final docRef =
        await FirebaseFirestore.instance.collection('app_notifications').add({
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'targetRole': _targetRole,
      'type': _notificationType,
      'presentation': 'floating',
      'playSound': true,
      'popupMode': _popupMode,
      'startsAtIso': _startsAt?.toIso8601String(),
      'endsAtIso': _endsAt?.toIso8601String(),
      'isActive': true,
      'createdAtIso': DateTime.now().toIso8601String(),
    });

    await _auditService.logAction(
      action: 'send_notification',
      targetCollection: 'app_notifications',
      targetId: docRef.id,
      summary: 'Notification admin envoyee',
      metadata: {
        'title': title,
        'targetRole': _targetRole,
        'type': _notificationType,
        'popupMode': _popupMode,
      },
    );

    if (!mounted) return;

    _titleController.clear();
    _bodyController.clear();
    _startsAt = null;
    _endsAt = null;
    _selectedImagePath = null;
    _selectedImageBytes = null;
    _selectedImageName = null;
    _uploadedImageUrl = null;
    setState(() => _sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification envoyee'),
      ),
    );
  }

  Future<void> _toggleActive(String docId, bool value) async {
    await FirebaseFirestore.instance
        .collection('app_notifications')
        .doc(docId)
        .set({
      'isActive': value,
      'updatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: value ? 'activate_notification' : 'deactivate_notification',
      targetCollection: 'app_notifications',
      targetId: docId,
      summary: value
          ? 'Notification admin reactivee'
          : 'Notification admin desactivee',
      metadata: {
        'isActive': value,
      },
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;
    if (!kIsWeb && (path == null || path.trim().isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lire cette image.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedImagePath = path;
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
      _uploadedImageUrl = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image selectionnee. Elle sera envoyee avec la notification.'),
      ),
    );
  }

  Future<String> _uploadSelectedImage() async {
    final name = _selectedImageName;
    final path = _selectedImagePath;
    final bytes = _selectedImageBytes;
    if (name == null) return '';
    if (!kIsWeb && (path == null || path.trim().isEmpty)) return '';
    if (kIsWeb && bytes == null) return '';

    setState(() => _uploadingImage = true);

    try {
      final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = FirebaseStorage.instance
          .ref()
          .child('admin_notifications/${DateTime.now().millisecondsSinceEpoch}_$safeName');

      if (kIsWeb) {
        await ref.putData(bytes!);
      } else {
        await ref.putFile(File(path!));
      }
      final url = await ref.getDownloadURL();

      if (!mounted) return url;

      setState(() {
        _uploadedImageUrl = url;
      });
      return url;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Echec de l upload de l image'),
          ),
        );
      }
      return '';
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImagePath = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startsAt ?? now) : (_endsAt ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startsAt = picked;
      } else {
        _endsAt = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1D4ED8),
                Color(0xFF0EA5E9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Broadcast Studio',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Envoyez des annonces, offres ou reductions en temps reel aux customers et providers avec popup flottant, image et planification.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              const items = [
                _HeaderStat(
                  label: 'Formats',
                  value: 'Popup + image',
                ),
                _HeaderStat(
                  label: 'Audience',
                  value: 'Customer / Provider',
                ),
                _HeaderStat(
                  label: 'Mode',
                  value: 'Session / ouverture',
                ),
              ];

              if (compact) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: items
                      .map(
                        (item) => SizedBox(
                          width: constraints.maxWidth > 360
                              ? (constraints.maxWidth - 10) / 2
                              : constraints.maxWidth,
                          child: item,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 10),
                  Expanded(child: items[1]),
                  const SizedBox(width: 10),
                  Expanded(child: items[2]),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingImage ? null : _pickImage,
                      icon: _uploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                      label: Text(
                        _selectedImageName == null
                            ? 'Choisir une image'
                            : 'Changer l image',
                      ),
                    ),
                  ),
                  if (_selectedImageName != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _uploadingImage ? null : _clearImage,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Retirer'),
                    ),
                  ],
                ],
              ),
              if (_selectedImageName != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _uploadedImageUrl == null
                        ? 'Image selectionnee: $_selectedImageName'
                        : 'Image prete: $_selectedImageName',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_selectedImagePath != null || _selectedImageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: kIsWeb
                      ? Image.memory(
                          _selectedImageBytes!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                        )
                      : Image.file(
                          File(_selectedImagePath!),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                        ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _targetRole,
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tout le monde'),
                  ),
                  DropdownMenuItem(
                    value: 'customer',
                    child: Text('Customers'),
                  ),
                  DropdownMenuItem(
                    value: 'provider',
                    child: Text('Providers'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _targetRole = value);
                },
                decoration: InputDecoration(
                  labelText: 'Cible',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _popupMode,
                items: const [
                  DropdownMenuItem(
                    value: 'once_per_session',
                    child: Text('Une fois par session'),
                  ),
                  DropdownMenuItem(
                    value: 'always_on_open',
                    child: Text('Toujours a l ouverture'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _popupMode = value);
                },
                decoration: InputDecoration(
                  labelText: 'Mode popup',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _notificationType,
                items: const [
                  DropdownMenuItem(
                    value: 'admin_offer',
                    child: Text('Offre'),
                  ),
                  DropdownMenuItem(
                    value: 'admin_discount',
                    child: Text('Reduction'),
                  ),
                  DropdownMenuItem(
                    value: 'admin_info',
                    child: Text('Annonce'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _notificationType = value);
                },
                decoration: InputDecoration(
                  labelText: 'Type popup',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isStart: true),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        _startsAt == null
                            ? 'Debut'
                            : _formatDateTime(_startsAt!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isStart: false),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(
                        _endsAt == null ? 'Fin' : _formatDateTime(_endsAt!),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startsAt != null || _endsAt != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _startsAt = null;
                        _endsAt = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Effacer la planification'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_active_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Le popup apparaitra au milieu de l ecran avec un son plus leger, et peut afficher une image.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _sendNotification,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_sending ? 'Envoi...' : 'Envoyer'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Historique live',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _historySearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Filtrer par titre, message ou type...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HistoryChip(
              label: 'Tous',
              selected: _historyTargetFilter == 'all',
              onTap: () => setState(() => _historyTargetFilter = 'all'),
            ),
            _HistoryChip(
              label: 'Clients',
              selected: _historyTargetFilter == 'customer',
              onTap: () => setState(() => _historyTargetFilter = 'customer'),
            ),
            _HistoryChip(
              label: 'Providers',
              selected: _historyTargetFilter == 'provider',
              onTap: () => setState(() => _historyTargetFilter = 'provider'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('app_notifications')
              .orderBy('createdAtIso', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _EmptyCard(
                text:
                    'Impossible de charger l historique des notifications.\n${snapshot.error}',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final historySearch =
                _historySearchController.text.trim().toLowerCase();
            final filteredDocs = docs.where((doc) {
              final data = doc.data();
              final targetRole = (data['targetRole'] ?? 'all').toString();
              final type = (data['type'] ?? 'admin_info').toString();
              final title = (data['title'] ?? '').toString().toLowerCase();
              final body = (data['body'] ?? '').toString().toLowerCase();

              final targetMatches = _historyTargetFilter == 'all' ||
                  targetRole == _historyTargetFilter ||
                  targetRole == 'all';
              final searchMatches = historySearch.isEmpty ||
                  title.contains(historySearch) ||
                  body.contains(historySearch) ||
                  type.contains(historySearch);

              return targetMatches && searchMatches;
            }).toList();

            if (filteredDocs.isEmpty) {
              return const _EmptyCard(
                text: 'Aucune notification envoyee',
              );
            }

            return Column(
              children: filteredDocs.map((doc) {
                final data = doc.data();
                final title = (data['title'] ?? '').toString();
                final body = (data['body'] ?? '').toString();
                final targetRole = (data['targetRole'] ?? 'all').toString();
                final type = (data['type'] ?? 'admin_info').toString();
                final popupMode =
                    (data['popupMode'] ?? 'once_per_session').toString();
                final imageUrl = (data['imageUrl'] ?? '').toString();
                final startsAt = _parseDate(data['startsAtIso']);
                final endsAt = _parseDate(data['endsAtIso']);
                final isActive = data['isActive'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (value) => _toggleActive(doc.id, value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),
                      if (imageUrl.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            imageUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _Pill(
                        text: 'Cible: $targetRole',
                        background: const Color(0xFFF8FAFC),
                        textColor: Colors.black87,
                      ),
                      const SizedBox(height: 8),
                      _Pill(
                        text: 'Type: ${_typeLabel(type)}',
                        background: const Color(0xFFEEF2FF),
                        textColor: const Color(0xFF3730A3),
                      ),
                      const SizedBox(height: 8),
                      _Pill(
                        text: 'Mode: ${_popupModeLabel(popupMode)}',
                        background: const Color(0xFFF0FDF4),
                        textColor: const Color(0xFF166534),
                      ),
                      if (startsAt != null || endsAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Fenetre: ${startsAt == null ? 'maintenant' : _formatDateTime(startsAt)} - ${endsAt == null ? 'sans fin' : _formatDateTime(endsAt)}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'admin_offer':
        return 'Offre';
      case 'admin_discount':
        return 'Reduction';
      default:
        return 'Annonce';
    }
  }

  String _popupModeLabel(String mode) {
    switch (mode) {
      case 'always_on_open':
        return 'Toujours a l ouverture';
      default:
        return 'Une fois par session';
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide.none,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
