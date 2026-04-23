import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  bool _onlyUrgent = false;

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
    final urgency = (data['urgency'] ?? '').toString().toLowerCase();

    if (_statusFilter != 'all' && status != _statusFilter) {
      return false;
    }

    if (_onlyUrgent &&
        !urgency.contains('urgent') &&
        !urgency.contains('crit')) {
      return false;
    }

    return _matchesSearch(data);
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
            .toList(growable: false);

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
        final urgentCount = docs.where((doc) {
          final urgency = (doc.data()['urgency'] ?? '').toString().toLowerCase();
          return urgency.contains('urgent') || urgency.contains('crit');
        }).length;

        final compactStats = MediaQuery.of(context).size.width < 720;

        return ListView(
          children: [
            _Panel(
              title: 'Mission filters',
              subtitle:
                  'Chercher vite, isoler les urgences et suivre les demandes sensibles.',
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
                        onTap: () =>
                            setState(() => _statusFilter = 'accepted'),
                      ),
                      _Chip(
                        label: 'En route',
                        selected: _statusFilter == 'onTheWay',
                        onTap: () =>
                            setState(() => _statusFilter = 'onTheWay'),
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
                            label: 'Urgentes',
                            value: '$urgentCount',
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
                            label: 'Urgentes',
                            value: '$urgentCount',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _onlyUrgent,
                    onChanged: (value) {
                      setState(() => _onlyUrgent = value);
                    },
                    title: const Text(
                      'Montrer seulement les missions urgentes',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
              final urgency = (data['urgency'] ?? 'Standard').toString();
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
                        _Pill(
                          label: urgency,
                          background: urgency.toLowerCase().contains('urgent')
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFEFF6FF),
                        ),
                        _Pill(
                          label: (data['service'] ?? '--').toString(),
                          background: const Color(0xFFF8FAFC),
                        ),
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
                    if ((data['offeredProviderUid'] ?? '').toString().isNotEmpty)
                      _InfoRow(
                        title: 'Offre active',
                        value: (data['offeredProviderUid'] ?? '--').toString(),
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
