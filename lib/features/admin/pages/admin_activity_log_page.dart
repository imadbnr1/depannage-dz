import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminActivityLogPage extends StatefulWidget {
  const AdminActivityLogPage({super.key});

  @override
  State<AdminActivityLogPage> createState() => _AdminActivityLogPageState();
}

class _AdminActivityLogPageState extends State<AdminActivityLogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _actionFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Map<String, dynamic> data) {
    if (_actionFilter != 'all' &&
        (data['action'] ?? '').toString() != _actionFilter) {
      return false;
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    return (data['summary'] ?? '').toString().toLowerCase().contains(q) ||
        (data['actorName'] ?? '').toString().toLowerCase().contains(q) ||
        (data['targetCollection'] ?? '').toString().toLowerCase().contains(q) ||
        (data['targetId'] ?? '').toString().toLowerCase().contains(q);
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is String) date = DateTime.tryParse(value);
    if (date == null) return '--';
    final local = date.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Color _actionColor(String action) {
    if (action.contains('block')) return const Color(0xFFDC2626);
    if (action.contains('approve')) return const Color(0xFF16A34A);
    if (action.contains('cancel')) return const Color(0xFFEA580C);
    if (action.contains('notification')) return const Color(0xFF2563EB);
    return const Color(0xFF475569);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('admin_activity_logs')
          .orderBy('createdAtIso', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LogPanel(
            title: 'Journal indisponible',
            subtitle: 'Impossible de charger l audit admin.',
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

        final docs = snapshot.data?.docs
                .where((doc) => _matches(doc.data()))
                .toList(growable: false) ??
            [];

        return ListView(
          children: [
            _LogPanel(
              title: 'Admin Activity Log',
              subtitle:
                  'Historique complet des actions sensibles pour garder une vraie trace operations.',
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher action, admin, cible ou resume...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AuditChip(
                        label: 'Tout',
                        selected: _actionFilter == 'all',
                        onTap: () => setState(() => _actionFilter = 'all'),
                      ),
                      _AuditChip(
                        label: 'Blocages',
                        selected: _actionFilter == 'block_account',
                        onTap: () =>
                            setState(() => _actionFilter = 'block_account'),
                      ),
                      _AuditChip(
                        label: 'Approvals',
                        selected: _actionFilter == 'approve_provider',
                        onTap: () =>
                            setState(() => _actionFilter = 'approve_provider'),
                      ),
                      _AuditChip(
                        label: 'Notifications',
                        selected: _actionFilter == 'send_notification',
                        onTap: () =>
                            setState(() => _actionFilter = 'send_notification'),
                      ),
                      _AuditChip(
                        label: 'Annulations',
                        selected: _actionFilter == 'force_cancel_request',
                        onTap: () => setState(
                          () => _actionFilter = 'force_cancel_request',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              const _LogPanel(
                title: 'Aucune activite',
                subtitle: 'Les actions admin apparaitront ici.',
                child: SizedBox.shrink(),
              ),
            ...docs.map((doc) {
              final data = doc.data();
              final action = (data['action'] ?? '--').toString();
              final accent = _actionColor(action);
              final metadata = (data['metadata'] is Map)
                  ? Map<String, dynamic>.from(data['metadata'] as Map)
                  : <String, dynamic>{};
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            action,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(data['createdAt'] ?? data['createdAtIso']),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (data['summary'] ?? '--').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin: ${(data['actorName'] ?? '--').toString()} • Cible: ${(data['targetCollection'] ?? '--').toString()}/${(data['targetId'] ?? '--').toString()}',
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          metadata.entries
                              .map((entry) => '${entry.key}: ${entry.value}')
                              .join('\n'),
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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

class _LogPanel extends StatelessWidget {
  const _LogPanel({
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

class _AuditChip extends StatelessWidget {
  const _AuditChip({
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
