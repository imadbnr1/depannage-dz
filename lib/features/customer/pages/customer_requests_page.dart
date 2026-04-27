import 'package:flutter/material.dart';

import '../../../models/request_status.dart';
import '../../../models/service_type.dart';
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHero(
              icon: Icons.receipt_long_outlined,
              title: 'Demandes actives',
              subtitle:
                  'Retrouvez ici vos missions en cours, leur statut et l acces rapide au suivi.',
              accent: Color(0xFF2563EB),
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              const AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Aucune demande active',
                message:
                    'Vos demandes en cours apparaitront ici. Les demandes terminees sont dans Historique.',
              )
            else
              ...requests.map(
                (request) => PanelCard(
                  margin: const EdgeInsets.only(bottom: 12),
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
                              color:
                                  request.status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              request.status.label,
                              style: TextStyle(
                                color: request.status.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (request.estimatedPrice != null)
                            Text(
                              '${request.estimatedPrice!.toStringAsFixed(0)} DA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        request.service.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.providerName?.trim().isNotEmpty == true
                            ? 'Provider: ${request.providerName}'
                            : 'Affectation du provider en cours',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      InfoRow(
                        title: 'Repere',
                        value: request.landmark,
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
                                          builder: (_) => CustomerTrackingPage(
                                            store: widget.store,
                                            requestId: request.id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('Ouvrir le suivi'),
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
                                    label: const Text('Annuler la demande'),
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
                                        builder: (_) => CustomerTrackingPage(
                                          store: widget.store,
                                          requestId: request.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Ouvrir le suivi'),
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
                                  label: const Text('Annuler la demande'),
                                ),
                              ),
                            ],
                          );
                        },
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

class _SectionHero extends StatelessWidget {
  const _SectionHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFCF8),
            Color(0xFFF7F0E5),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8E1D5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
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
