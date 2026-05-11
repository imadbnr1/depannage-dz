import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/admin_audit_service.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final AdminAuditService _auditService = AdminAuditService();
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _assignmentFilter = 'all';
  String _sortMode = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF2563EB);
      case 'onTheWay':
        return const Color(0xFFEA580C);
      case 'arrived':
        return const Color(0xFFD97706);
      case 'inService':
        return const Color(0xFF0F766E);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF475569);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptee';
      case 'onTheWay':
        return 'En route';
      case 'arrived':
        return 'Arrivee';
      case 'inService':
        return 'En service';
      case 'completed':
        return 'Terminee';
      case 'cancelled':
        return 'Annulee';
      default:
        return 'Recherche';
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    return (data['customerName'] ?? '').toString().toLowerCase().contains(q) ||
        (data['customerPhone'] ?? '').toString().toLowerCase().contains(q) ||
        (data['providerName'] ?? '').toString().toLowerCase().contains(q) ||
        (data['pickupLabel'] ?? '').toString().toLowerCase().contains(q) ||
        (data['destination'] ?? '').toString().toLowerCase().contains(q);
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'searching').toString();
    final providerName = (data['providerName'] ?? '').toString().trim();

    if (_statusFilter != 'all' && status != _statusFilter) {
      return false;
    }

    if (_assignmentFilter == 'assigned' && providerName.isEmpty) {
      return false;
    }

    if (_assignmentFilter == 'unassigned' && providerName.isNotEmpty) {
      return false;
    }

    return _matchesSearch(data);
  }

  Future<void> _forceCancel(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
      'status': 'cancelled',
      'offeredProviderUid': null,
      'offeredAt': null,
      'offerExpiresAt': null,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedAtIso': DateTime.now().toIso8601String(),
      'cancelledAtIso': DateTime.now().toIso8601String(),
      'statusChangedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'force_cancel_request',
      targetCollection: 'requests',
      targetId: requestId,
      summary: 'Mission annulee par l administration',
      metadata: {
        'status': 'cancelled',
      },
    );
  }

  Future<void> _clearOffer(String requestId) async {
    final now = DateTime.now().toIso8601String();
    await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
      'offeredProviderUid': null,
      'offeredAt': null,
      'offerExpiresAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'clear_request_offer',
      targetCollection: 'requests',
      targetId: requestId,
      summary: 'Offre provider active effacee par l administration',
    );
  }

  Future<void> _resetSearching(String requestId) async {
    final now = DateTime.now().toIso8601String();
    await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
      'status': 'searching',
      'providerUid': null,
      'providerName': null,
      'providerPhone': null,
      'providerVehicle': null,
      'providerPlate': null,
      'providerPosition': null,
      'offeredProviderUid': null,
      'offeredAt': null,
      'offerExpiresAt': null,
      'rejectedProviderUids': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': now,
      'statusChangedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'reset_searching_request',
      targetCollection: 'requests',
      targetId: requestId,
      summary: 'Mission remise en recherche par l administration',
    );
  }

  Future<void> _forceComplete(String requestId) async {
    final now = DateTime.now().toIso8601String();
    await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
      'status': 'completed',
      'offeredProviderUid': null,
      'offeredAt': null,
      'offerExpiresAt': null,
      'completedAt': now,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': now,
      'statusChangedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'force_complete_request',
      targetCollection: 'requests',
      targetId: requestId,
      summary: 'Mission forcee terminee par l administration',
    );
  }

  Future<void> _reassignRequest(String requestId) async {
    final providers = await FirebaseFirestore.instance
        .collection('providers')
        .where('isApproved', isEqualTo: true)
        .get();

    if (!mounted) return;

    final providerId = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reassigner a un provider'),
          content: SizedBox(
            width: 420,
            child: providers.docs.isEmpty
                ? const Text('Aucun provider approuve disponible.')
                : ListView(
                    shrinkWrap: true,
                    children: providers.docs.map((doc) {
                      final data = doc.data();
                      return ListTile(
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text((data['fullName'] ?? doc.id).toString()),
                        subtitle: Text(
                          'Online: ${data['isOnline'] == true ? 'oui' : 'non'} - Busy: ${data['isBusy'] == true ? 'oui' : 'non'}',
                        ),
                        onTap: () => Navigator.of(context).pop(doc.id),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (providerId == null) return;

    final provider = providers.docs.firstWhere((doc) => doc.id == providerId);
    final data = provider.data();
    final now = DateTime.now().toIso8601String();

    await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
      'status': 'accepted',
      'providerUid': providerId,
      'providerName': (data['fullName'] ?? '').toString(),
      'providerPhone': (data['phone'] ?? '').toString(),
      'providerVehicle': (data['vehicleType'] ?? '').toString(),
      'providerPlate': (data['plate'] ?? '').toString(),
      'offeredProviderUid': null,
      'offeredAt': null,
      'offerExpiresAt': null,
      'acceptedAt': now,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': now,
      'statusChangedAtIso': now,
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('providers')
        .doc(providerId)
        .set({
      'isBusy': true,
      'busy': true,
      'hasActiveMission': true,
      'activeMissionId': requestId,
      'currentRequestId': requestId,
      'assignedRequestId': requestId,
      'updatedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'reassign_request',
      targetCollection: 'requests',
      targetId: requestId,
      summary: 'Mission reaffectee manuellement',
      metadata: {'providerUid': providerId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Panel(
            title: 'Demandes indisponibles',
            subtitle:
                'Le flux des missions n a pas pu charger. Verifiez les index Firestore, les regles admin ou la connexion.',
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs
            .where((doc) => _matchesFilters(doc.data()))
            .toList(growable: false)
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            if (_sortMode == 'price_desc') {
              final aPrice = (aData['estimatedPrice'] as num?)?.toDouble() ?? 0;
              final bPrice = (bData['estimatedPrice'] as num?)?.toDouble() ?? 0;
              return bPrice.compareTo(aPrice);
            }
            final aDate =
                DateTime.tryParse((aData['createdAt'] ?? '').toString()) ??
                    DateTime.tryParse((aData['updatedAt'] ?? '').toString()) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                DateTime.tryParse((bData['createdAt'] ?? '').toString()) ??
                    DateTime.tryParse((bData['updatedAt'] ?? '').toString()) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
            return _sortMode == 'oldest'
                ? aDate.compareTo(bDate)
                : bDate.compareTo(aDate);
          });

        final activeCount = docs.where((doc) {
          final status = (doc.data()['status'] ?? '').toString();
          return status == 'accepted' ||
              status == 'onTheWay' ||
              status == 'arrived' ||
              status == 'inService';
        }).length;
        final searchingCount = docs
            .where((doc) => (doc.data()['status'] ?? '') == 'searching')
            .length;
        final assignedCount = docs.where((doc) {
          return (doc.data()['providerName'] ?? '')
              .toString()
              .trim()
              .isNotEmpty;
        }).length;

        final compactStats = MediaQuery.of(context).size.width < 720;

        return ListView(
          children: [
            _Panel(
              title: 'Mission filters',
              subtitle:
                  'Chercher vite, isoler les missions bloquees et suivre les demandes sensibles.',
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'Rechercher client, provider, telephone, depart ou destination...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label: 'Toutes',
                        selected: _statusFilter == 'all',
                        onTap: () => setState(() => _statusFilter = 'all'),
                      ),
                      _Chip(
                        label: 'Recherche',
                        selected: _statusFilter == 'searching',
                        onTap: () =>
                            setState(() => _statusFilter = 'searching'),
                      ),
                      _Chip(
                        label: 'Actives',
                        selected: _statusFilter == 'accepted',
                        onTap: () => setState(() => _statusFilter = 'accepted'),
                      ),
                      _Chip(
                        label: 'En route',
                        selected: _statusFilter == 'onTheWay',
                        onTap: () => setState(() => _statusFilter = 'onTheWay'),
                      ),
                      _Chip(
                        label: 'Terminees',
                        selected: _statusFilter == 'completed',
                        onTap: () =>
                            setState(() => _statusFilter = 'completed'),
                      ),
                      _Chip(
                        label: 'Annulees',
                        selected: _statusFilter == 'cancelled',
                        onTap: () =>
                            setState(() => _statusFilter = 'cancelled'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label: 'Toutes affectations',
                        selected: _assignmentFilter == 'all',
                        onTap: () => setState(() => _assignmentFilter = 'all'),
                      ),
                      _Chip(
                        label: 'Affectees',
                        selected: _assignmentFilter == 'assigned',
                        onTap: () =>
                            setState(() => _assignmentFilter = 'assigned'),
                      ),
                      _Chip(
                        label: 'Sans provider',
                        selected: _assignmentFilter == 'unassigned',
                        onTap: () =>
                            setState(() => _assignmentFilter = 'unassigned'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _sortMode,
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Plus recentes'),
                      ),
                      DropdownMenuItem(
                        value: 'oldest',
                        child: Text('Plus anciennes'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Prix le plus eleve'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortMode = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Tri',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (compactStats)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: 'Actives',
                            value: '$activeCount',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: 'Recherche',
                            value: '$searchingCount',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: 'Sans provider',
                            value: '${docs.length - assignedCount}',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: 'Affectees',
                            value: '$assignedCount',
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Actives',
                            value: '$activeCount',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: 'Recherche',
                            value: '$searchingCount',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: 'Sans provider',
                            value: '${docs.length - assignedCount}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: 'Affectees',
                            value: '$assignedCount',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const _Panel(
                title: 'Aucun resultat',
                subtitle: 'Ajustez les filtres pour afficher des missions.',
                child: SizedBox.shrink(),
              ),
            ...filtered.map((doc) {
              final data = doc.data();
              final status = (data['status'] ?? 'searching').toString();
              final statusColor = _statusColor(status);
              final estimatedPrice = data['estimatedPrice'];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['customerName'] ?? 'Client').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (data['customerPhone'] ?? '--').toString(),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (estimatedPrice is num)
                          _Pill(
                            label: '${estimatedPrice.toStringAsFixed(0)} DA',
                            background: const Color(0xFFECFDF5),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      title: 'Depart',
                      value: (data['pickupLabel'] ?? '--').toString(),
                    ),
                    _InfoRow(
                      title: 'Destination',
                      value: (data['destination'] ?? '--').toString(),
                    ),
                    _InfoRow(
                      title: 'Provider',
                      value: (data['providerName'] ?? '--').toString(),
                    ),
                    _InfoRow(
                      title: 'Vehicule',
                      value:
                          '${data['vehicleType'] ?? '--'} · ${data['brandModel'] ?? '--'}',
                    ),
                    if ((data['offeredProviderUid'] ?? '')
                        .toString()
                        .isNotEmpty)
                      _InfoRow(
                        title: 'Offre active',
                        value: (data['offeredProviderUid'] ?? '--').toString(),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionButton(
                          icon: Icons.clear_all_outlined,
                          label: 'Effacer offre',
                          onPressed: () => _clearOffer(doc.id),
                        ),
                        _ActionButton(
                          icon: Icons.restart_alt_outlined,
                          label: 'Relancer recherche',
                          onPressed: () => _resetSearching(doc.id),
                        ),
                        _ActionButton(
                          icon: Icons.assignment_ind_outlined,
                          label: 'Reassigner',
                          onPressed: () => _reassignRequest(doc.id),
                        ),
                        _ActionButton(
                          icon: Icons.task_alt_outlined,
                          label: 'Terminer',
                          onPressed: () => _forceComplete(doc.id),
                        ),
                        _ActionButton(
                          icon: Icons.cancel_outlined,
                          label: 'Forcer annulation',
                          onPressed: () => _forceCancel(doc.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
  });

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
