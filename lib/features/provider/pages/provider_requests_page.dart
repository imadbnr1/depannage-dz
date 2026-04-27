import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/app_request.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/panel_card.dart';
import 'provider_mission_details_page.dart';
import 'provider_tracking_page.dart';

class ProviderRequestsPage extends StatefulWidget {
  const ProviderRequestsPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<ProviderRequestsPage> createState() => _ProviderRequestsPageState();
}

class _ProviderRequestsPageState extends State<ProviderRequestsPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final active = store.providerAssignedRequests;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _RequestsHero(),
            const SizedBox(height: 16),
            if (active.isEmpty)
              const SizedBox(
                height: 280,
                child: AppEmptyState(
                  icon: Icons.car_repair_outlined,
                  title: 'Aucune mission active',
                  message:
                      'Les nouvelles missions arrivent en popup. Seules les missions en cours restent ici.',
                ),
              ),
            ...active.map(
              (item) => _ProviderActiveCard(
                store: store,
                item: item,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingMissionCard extends StatefulWidget {
  const _IncomingMissionCard({
    required this.store,
    required this.item,
  });

  final AppStore store;
  final AppRequest item;

  @override
  State<_IncomingMissionCard> createState() => _IncomingMissionCardState();
}

class _IncomingMissionCardState extends State<_IncomingMissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _startLocalCountdown();
  }

  @override
  void didUpdateWidget(covariant _IncomingMissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldOffered =
        oldWidget.store.currentOfferedProviderName(oldWidget.item.id);
    final newOffered = widget.store.currentOfferedProviderName(widget.item.id);

    if (oldOffered != newOffered) {
      _startLocalCountdown();
    }
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    _secondsLeft = widget.store.offerSecondsRemaining(widget.item.id) ?? 0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final stillSearching = widget.store.findRequest(widget.item.id)?.status ==
          RequestStatus.searching;

      if (!stillSearching) {
        timer.cancel();
        return;
      }

      final nextSeconds =
          widget.store.offerSecondsRemaining(widget.item.id) ?? 0;

      if (nextSeconds <= 0) {
        setState(() => _secondsLeft = 0);
        timer.cancel();
      } else {
        setState(() => _secondsLeft = nextSeconds);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _serviceLabel(AppRequest request) {
    try {
      final dynamic label = (request.service as dynamic).label;
      if (label is String && label.trim().isNotEmpty) return label;
    } catch (_) {}

    final raw = request.service.toString();
    if (raw.contains('.')) return raw.split('.').last;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final latest = store.findRequest(widget.item.id) ?? widget.item;
    final offeredProvider = store.currentOfferedProviderName(latest.id);
    final secondsLeft = store.offerSecondsRemaining(latest.id) ?? _secondsLeft;
    final estimatedPrice = latest.estimatedPrice;
    final netEarning = estimatedPrice == null
        ? null
        : estimatedPrice - store.estimateCommissionAmount(estimatedPrice);

    return FadeTransition(
      opacity: _pulseController.drive(Tween(begin: 0.75, end: 1)),
      child: PanelCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latest.customerPhone,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Nouveau',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (offeredProvider != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mission proposee a vous',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$secondsLeft s',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniBadge(label: _serviceLabel(latest)),
                _MiniBadge(label: latest.urgency),
                if (latest.estimatedDistanceKm != null)
                  _MiniBadge(
                    label:
                        '${latest.estimatedDistanceKm!.toStringAsFixed(1)} km',
                  ),
                if (latest.estimatedPrice != null)
                  _MiniBadge(
                    label: '${latest.estimatedPrice!.toStringAsFixed(0)} DA',
                  ),
                if (netEarning != null)
                  _MiniBadge(
                    label: 'Net ${netEarning.toStringAsFixed(0)} DA',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              title: 'Vehicule',
              value: '${latest.vehicleType} · ${latest.brandModel}',
            ),
            InfoRow(
              title: 'Position',
              value: '${latest.pickupLabel}\n${latest.pickupSubtitle}',
            ),
            InfoRow(
              title: 'Repere',
              value: latest.landmark,
            ),
            InfoRow(
              title: 'Description',
              value: latest.issueDescription,
            ),
            if (latest.destination.isNotEmpty)
              InfoRow(
                title: 'Destination',
                value: latest.destination,
              ),
            if (netEarning != null)
              InfoRow(
                title: 'Gain estime',
                value: '${netEarning.toStringAsFixed(0)} DA apres commission',
              ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                if (compact) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await store.acceptRequest(latest.id);
                            if (!mounted) return;
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProviderTrackingPage(
                                  store: store,
                                  requestId: latest.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Accepter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await store
                                .rejectRequestForCurrentProvider(latest.id);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Rejeter'),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await store.acceptRequest(latest.id);
                          if (!mounted) return;
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProviderTrackingPage(
                                store: store,
                                requestId: latest.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Accepter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await store
                              .rejectRequestForCurrentProvider(latest.id);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Rejeter'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderMissionDetailsPage(
                        store: store,
                        requestId: latest.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Voir tous les details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderActiveCard extends StatelessWidget {
  const _ProviderActiveCard({
    required this.store,
    required this.item,
  });

  final AppStore store;
  final AppRequest item;

  String _buttonLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 'Passer en route';
      case RequestStatus.onTheWay:
        return 'Confirmer arrivee';
      case RequestStatus.arrived:
        return 'Commencer service';
      case RequestStatus.inService:
        return 'Terminer mission';
      default:
        return 'Suivi en cours';
    }
  }

  bool _canAdvance(RequestStatus status) {
    return status == RequestStatus.accepted ||
        status == RequestStatus.onTheWay ||
        status == RequestStatus.arrived ||
        status == RequestStatus.inService;
  }

  String _serviceLabel(AppRequest request) {
    try {
      final dynamic label = (request.service as dynamic).label;
      if (label is String && label.trim().isNotEmpty) return label;
    } catch (_) {}

    final raw = request.service.toString();
    if (raw.contains('.')) return raw.split('.').last;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final latest = store.findRequest(item.id) ?? item;

    return PanelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: latest.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: latest.status.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latest.status.label,
                      style: TextStyle(
                        color: latest.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                latest.estimatedPrice != null
                    ? '${latest.estimatedPrice!.toStringAsFixed(0)} DA'
                    : '--',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: _serviceLabel(latest)),
              _MiniBadge(label: latest.urgency),
              if (latest.estimatedDistanceKm != null)
                _MiniBadge(
                  label: '${latest.estimatedDistanceKm!.toStringAsFixed(1)} km',
                ),
              if (latest.estimatedDurationMinutes != null)
                _MiniBadge(
                  label: '${latest.estimatedDurationMinutes} min',
                ),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow(title: 'Telephone', value: latest.customerPhone),
          InfoRow(
            title: 'Vehicule',
            value: '${latest.vehicleType} · ${latest.brandModel}',
          ),
          InfoRow(
            title: 'Position',
            value: '${latest.pickupLabel}\n${latest.pickupSubtitle}',
          ),
          InfoRow(title: 'Repere', value: latest.landmark),
          if (latest.destination.isNotEmpty)
            InfoRow(title: 'Destination', value: latest.destination),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              if (compact) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProviderTrackingPage(
                                store: store,
                                requestId: latest.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ouvrir le suivi'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _canAdvance(latest.status)
                            ? () async {
                                await store.advanceMission(latest.id);
                              }
                            : null,
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(_buttonLabel(latest.status)),
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
                            builder: (_) => ProviderTrackingPage(
                              store: store,
                              requestId: latest.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ouvrir le suivi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _canAdvance(latest.status)
                          ? () async {
                              await store.advanceMission(latest.id);
                            }
                          : null,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(_buttonLabel(latest.status)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RequestsHero extends StatelessWidget {
  const _RequestsHero();

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
          _RequestsHeroIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missions en cours',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pilotez vos missions actives et gardez un acces direct au suivi terrain.',
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

class _RequestsHeroIcon extends StatelessWidget {
  const _RequestsHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.assignment_outlined,
        color: Color(0xFFF59E0B),
      ),
    );
  }
}
