import 'package:flutter/material.dart';

import '../../../state/app_store.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/panel_card.dart';

class CustomerHistoryPage extends StatefulWidget {
  const CustomerHistoryPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
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

  @override
  Widget build(BuildContext context) {
    final history = widget.store.historyCustomerRequests;

    return Scaffold(
      body: SafeArea(
        child: history.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: AppEmptyState(
                  icon: Icons.history_outlined,
                  title: 'Aucun historique',
                  message:
                      'Vos demandes terminees ou annulees apparaitront ici.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final request = history[index];

                  return PanelCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.status.label,
                          style: TextStyle(
                            color: request.status.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.service.toString().split('.').last,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InfoRow(
                          title: 'Vehicule',
                          value: '${request.vehicleType} · ${request.brandModel}',
                        ),
                        InfoRow(
                          title: 'Depart',
                          value: request.pickupLabel,
                        ),
                        if (request.destination.isNotEmpty)
                          InfoRow(
                            title: 'Destination',
                            value: request.destination,
                          ),
                        if (request.providerName != null)
                          InfoRow(
                            title: 'Provider',
                            value: request.providerName!,
                          ),
                        if (request.estimatedPrice != null)
                          InfoRow(
                            title: 'Prix',
                            value:
                                '${request.estimatedPrice!.toStringAsFixed(0)} DA',
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}