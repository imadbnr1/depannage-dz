import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'onTheWay':
        return Colors.orange;
      case 'arrived':
        return Colors.deepOrange;
      case 'inService':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('Aucune demande'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = (data['status'] ?? 'searching').toString();

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (data['customerName'] ?? 'Client').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: _statusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusText(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    title: 'Service',
                    value: (data['service'] ?? '--').toString(),
                  ),
                  _InfoRow(
                    title: 'Telephone',
                    value: (data['customerPhone'] ?? '--').toString(),
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
                    title: 'Prix',
                    value: data['estimatedPrice'] == null
                        ? '--'
                        : '${(data['estimatedPrice'] as num).toStringAsFixed(0)} DA',
                  ),
                ],
              ),
            );
          },
        );
      },
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