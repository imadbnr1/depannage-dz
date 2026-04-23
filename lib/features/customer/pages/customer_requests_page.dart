import 'package:depannage_dz_pro_structured/models/request_status.dart';
import 'package:flutter/material.dart';

import '../../../state/app_store.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/panel_card.dart';
import 'customer_tracking_page.dart';

class CustomerRequestsPage extends StatefulWidget {
  const CustomerRequestsPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<CustomerRequestsPage> createState() => _CustomerRequestsPageState();
}

class _CustomerRequestsPageState extends State<CustomerRequestsPage> {
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
    final requests = widget.store.activeCustomerRequests;

    return Scaffold(
      body: SafeArea(
        child: requests.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aucune demande active',
                  message:
                      'Vos demandes en cours apparaitront ici. Les demandes terminees sont dans Historique.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];

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
                          request.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InfoRow(
                          title: 'Service',
                          value: request.service.toString().split('.').last,
                        ),
                        InfoRow(
                          title: 'Vehicule',
                          value: '${request.vehicleType} · ${request.brandModel}',
                        ),
                        InfoRow(
                          title: 'Position',
                          value: request.pickupLabel,
                        ),
                        if (request.destination.isNotEmpty)
                          InfoRow(
                            title: 'Destination',
                            value: request.destination,
                          ),
                        InfoRow(
                          title: 'Repere',
                          value: request.landmark,
                        ),
                        if (request.providerName != null)
                          InfoRow(
                            title: 'Provider',
                            value: request.providerName!,
                          ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 420) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CustomerTrackingPage(
                                              store: widget.store,
                                              requestId: request.id,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text('Tracking'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        await widget.store
                                            .cancelRequest(request.id);
                                      },
                                      icon: const Icon(Icons.close),
                                      label: const Text('Annuler'),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CustomerTrackingPage(
                                            store: widget.store,
                                            requestId: request.id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('Tracking'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      await widget.store
                                          .cancelRequest(request.id);
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Annuler'),
                                  ),
                                ),
                              ],
                            );
                          },
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
