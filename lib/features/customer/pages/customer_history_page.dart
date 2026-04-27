import 'package:flutter/material.dart';

import '../../../models/request_status.dart';
import '../../../models/service_type.dart';
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HistoryHero(),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const AppEmptyState(
                icon: Icons.history_outlined,
                title: 'Aucun historique',
                message: 'Vos demandes terminees ou annulees apparaitront ici.',
              )
            else
              ...history.map(
                (request) => PanelCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request.status.label,
                            style: TextStyle(
                              color: request.status.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          if (request.estimatedPrice != null)
                            Text(
                              '${request.estimatedPrice!.toStringAsFixed(0)} DA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        request.service.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
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
                      if (request.providerName != null)
                        InfoRow(
                          title: 'Provider',
                          value: request.providerName!,
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

class _HistoryHero extends StatelessWidget {
  const _HistoryHero();

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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryHeroIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique des missions',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Retrouvez ici vos missions passees, terminees ou annulees.',
                  style: TextStyle(
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

class _HistoryHeroIcon extends StatelessWidget {
  const _HistoryHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.history_outlined,
        color: Color(0xFF7C3AED),
      ),
    );
  }
}
