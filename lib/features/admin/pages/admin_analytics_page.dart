import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final requestsStream =
        FirebaseFirestore.instance.collection('requests').snapshots();

    final pricingStream = FirebaseFirestore.instance
        .collection('app_config')
        .doc('pricing')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: requestsStream,
      builder: (context, requestsSnapshot) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: pricingStream,
          builder: (context, pricingSnapshot) {
            if (requestsSnapshot.connectionState == ConnectionState.waiting ||
                pricingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final requestDocs = requestsSnapshot.data?.docs ?? [];
            final pricingData = pricingSnapshot.data?.data() ?? <String, dynamic>{};

            final commissionPercent =
                _toDouble(pricingData['commissionPercent']).clamp(0, 100);

            final totalRequests = requestDocs.length;
            final completedDocs = requestDocs
                .where((d) => (d.data()['status'] ?? '') == 'completed')
                .toList();
            final cancelledDocs = requestDocs
                .where((d) => (d.data()['status'] ?? '') == 'cancelled')
                .toList();
            final activeDocs = requestDocs.where((d) {
              final s = (d.data()['status'] ?? '').toString();
              return s == 'accepted' ||
                  s == 'onTheWay' ||
                  s == 'arrived' ||
                  s == 'inService';
            }).toList();

            double totalRevenue = 0;
            for (final doc in completedDocs) {
              totalRevenue += _toDouble(doc.data()['estimatedPrice']);
            }

            final totalCommission =
                totalRevenue * (commissionPercent / 100.0);

            final averageTicket =
                completedDocs.isEmpty ? 0 : totalRevenue / completedDocs.length;

            final recentCompleted = [...completedDocs];
            recentCompleted.sort((a, b) {
              final aDate = (a.data()['completedAt'] ?? '').toString();
              final bDate = (b.data()['completedAt'] ?? '').toString();
              return bDate.compareTo(aDate);
            });

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.28,
                  children: [
                    _StatCard(
                      title: 'Total demandes',
                      value: '$totalRequests',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _StatCard(
                      title: 'Actives',
                      value: '${activeDocs.length}',
                      icon: Icons.local_shipping_outlined,
                    ),
                    _StatCard(
                      title: 'Terminees',
                      value: '${completedDocs.length}',
                      icon: Icons.check_circle_outline,
                    ),
                    _StatCard(
                      title: 'Annulees',
                      value: '${cancelledDocs.length}',
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  childAspectRatio: 3.1,
                  children: [
                    _MoneyCard(
                      title: 'Chiffre estime',
                      value: '${totalRevenue.toStringAsFixed(0)} DA',
                      subtitle: 'Somme des missions completees',
                      icon: Icons.payments_outlined,
                    ),
                    _MoneyCard(
                      title: 'Commission plateforme',
                      value:
                          '${totalCommission.toStringAsFixed(0)} DA',
                      subtitle: 'Basee sur $commissionPercent %',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _MoneyCard(
                      title: 'Panier moyen',
                      value: '${averageTicket.toStringAsFixed(0)} DA',
                      subtitle: 'Moyenne par mission terminee',
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Dernieres missions terminees',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                if (recentCompleted.isEmpty)
                  const _EmptyCard(
                    text: 'Aucune mission terminee pour le moment',
                  ),
                ...recentCompleted.take(10).map((doc) {
                  final data = doc.data();
                  final customerName =
                      (data['customerName'] ?? 'Client').toString();
                  final providerName =
                      (data['providerName'] ?? '--').toString();
                  final destination =
                      (data['destination'] ?? '--').toString();
                  final price = _toDouble(data['estimatedPrice']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(title: 'Provider', value: providerName),
                        _InfoRow(title: 'Destination', value: destination),
                        _InfoRow(
                          title: 'Montant',
                          value: '${price.toStringAsFixed(0)} DA',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF8FAFC),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 6),
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
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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