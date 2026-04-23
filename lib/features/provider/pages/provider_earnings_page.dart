import 'package:flutter/material.dart';

import '../../../models/request_status.dart';
import '../../../state/app_store.dart';

class ProviderEarningsPage extends StatefulWidget {
  const ProviderEarningsPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<ProviderEarningsPage> createState() => _ProviderEarningsPageState();
}

class _ProviderEarningsPageState extends State<ProviderEarningsPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final provider = store.selectedProviderOrNull;
    final providerId = store.currentProviderUid;

    if (providerId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Provider introuvable'),
        ),
      );
    }

    final allCompleted = store.requests.where((r) {
      return r.providerUid == providerId && r.status == RequestStatus.completed;
    }).toList();

    final todayCompleted = allCompleted.where((r) {
      final completedAt = r.completedAt ?? r.createdAt;
      return _isToday(completedAt);
    }).toList();

    final todayGross = todayCompleted.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    final todayCommission = todayCompleted.fold<double>(
      0,
      (sum, item) =>
          sum + store.estimateCommissionAmount(item.estimatedPrice ?? 0),
    );

    final todayNet = todayGross - todayCommission;

    final totalGross = allCompleted.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    final totalCommission = allCompleted.fold<double>(
      0,
      (sum, item) =>
          sum + store.estimateCommissionAmount(item.estimatedPrice ?? 0),
    );

    final totalNet = totalGross - totalCommission;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenus'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net aujourd hui',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${todayNet.toStringAsFixed(0)} DA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 360) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _DarkMiniStat(
                                title: 'Brut',
                                value: '${todayGross.toStringAsFixed(0)} DA',
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: _DarkMiniStat(
                                title: 'Commission',
                                value:
                                    '${todayCommission.toStringAsFixed(0)} DA',
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _DarkMiniStat(
                              title: 'Brut',
                              value: '${todayGross.toStringAsFixed(0)} DA',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DarkMiniStat(
                              title: 'Commission',
                              value: '${todayCommission.toStringAsFixed(0)} DA',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _LightStatCard(
                    title: 'Missions du jour',
                    value: '${todayCompleted.length}',
                    icon: Icons.today_outlined,
                  ),
                  _LightStatCard(
                    title: 'Total missions',
                    value: '${allCompleted.length}',
                    icon: Icons.check_circle_outline,
                  ),
                  _LightStatCard(
                    title: 'Net total',
                    value: '${totalNet.toStringAsFixed(0)} DA',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _LightStatCard(
                    title: 'Note',
                    value: (provider?.rating ?? 5.0).toStringAsFixed(1),
                    icon: Icons.star_outline,
                  ),
                ];

                if (constraints.maxWidth < 420) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: cards
                        .map(
                          (card) => SizedBox(
                            width: (constraints.maxWidth - 10) / 2,
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 10),
                        Expanded(child: cards[1]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: cards[2]),
                        const SizedBox(width: 10),
                        Expanded(child: cards[3]),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Resume financier',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _InfoTile(
              label: 'Brut aujourd hui',
              value: '${todayGross.toStringAsFixed(0)} DA',
            ),
            _InfoTile(
              label: 'Commission aujourd hui',
              value: '${todayCommission.toStringAsFixed(0)} DA',
            ),
            _InfoTile(
              label: 'Net aujourd hui',
              value: '${todayNet.toStringAsFixed(0)} DA',
            ),
            _InfoTile(
              label: 'Brut total',
              value: '${totalGross.toStringAsFixed(0)} DA',
            ),
            _InfoTile(
              label: 'Commission totale',
              value: '${totalCommission.toStringAsFixed(0)} DA',
            ),
            _InfoTile(
              label: 'Net total',
              value: '${totalNet.toStringAsFixed(0)} DA',
            ),
            const SizedBox(height: 18),
            const Text(
              'Dernieres missions terminees',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            if (allCompleted.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Aucune mission terminee pour le moment.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ...allCompleted.reversed.take(8).map(
                  (item) => Container(
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
                        Text(
                          item.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.destination.isNotEmpty
                              ? item.destination
                              : item.pickupLabel,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${(item.estimatedPrice ?? 0).toStringAsFixed(0)} DA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${store.estimateCommissionAmount(item.estimatedPrice ?? 0).toStringAsFixed(0)} DA commission',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DarkMiniStat extends StatelessWidget {
  const _DarkMiniStat({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightStatCard extends StatelessWidget {
  const _LightStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
