import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/map_pin.dart';
import 'provider_earnings_page.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  double _panelExtent = 0.22;

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

  double _todayNetRevenue() {
    final provider = widget.store.selectedProviderOrNull;
    if (provider == null) return 0;

    final todayCompleted = widget.store.requests.where((r) {
      if (r.providerUid != provider.id) return false;
      if (r.status != RequestStatus.completed) return false;
      final completedAt = r.completedAt ?? r.createdAt;
      return _isToday(completedAt);
    });

    final gross = todayCompleted.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    final commission = todayCompleted.fold<double>(
      0,
      (sum, item) =>
          sum + widget.store.estimateCommissionAmount(item.estimatedPrice ?? 0),
    );

    return gross - commission;
  }

  void _navigateToAvailableMissions() {
    widget.store.setProviderTab(1);
  }

  void _navigateToActiveMissions() {
    widget.store.setProviderTab(1);
  }

  void _navigateToProfile() {
    widget.store.setProviderTab(3);
  }

  void _navigateToEarnings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderEarningsPage(store: widget.store),
      ),
    );
  }

  Future<void> _centerProvider() async {
    await widget.store.requestProviderLocation();

    final provider = widget.store.selectedProviderOrNull;
    final position = widget.store.providerCurrentPosition ??
        provider?.position ??
        const LatLng(36.7538, 3.0588);

    if (!_mapReady) return;

    try {
      _mapController.move(position, 16);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final store = widget.store;
    final provider = store.selectedProviderOrNull;
    if (provider == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final providerPosition = store.providerCurrentPosition ?? provider.position;

    final active = store.providerAssignedRequests;
    final available = store.providerAvailableRequests;
    final markers = <Marker>[
      Marker(
        point: providerPosition,
        width: 86,
        height: 86,
        child: MapPin(
          label: strings.t('provider'),
          icon: Icons.car_repair_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ),
    ];

    for (final item in active.take(1)) {
      markers.add(
        Marker(
          point: item.customerPosition,
          width: 82,
          height: 82,
          child: MapPin(
            label: strings.t('client'),
            icon: Icons.place,
            color: Colors.red,
          ),
        ),
      );
    }

    final netRevenue = _todayNetRevenue();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final safe = MediaQuery.paddingOf(context);
          final compactHeight = constraints.maxHeight < 620;
          final minExtent = compactHeight ? 0.18 : 0.16;
          final initialExtent = compactHeight ? 0.28 : 0.22;
          final maxExtent = compactHeight ? 0.62 : 0.50;
          final clampedExtent =
              _panelExtent.clamp(minExtent, maxExtent).toDouble();
          final buttonBottom =
              (constraints.maxHeight * clampedExtent) + safe.bottom + 14;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: providerPosition,
                  initialZoom: 13.5,
                  onMapReady: () {
                    _mapReady = true;
                    try {
                      _mapController.move(providerPosition, 15);
                    } catch (_) {}
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dz.depannage.provider',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                top: safe.top + 12,
                left: 14 + safe.left,
                child: _FloatingPill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.isOnline ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: provider.isOnline
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: provider.isOnline,
                        onChanged: (value) async {
                          await store.updateProviderOnlineStatus(
                            provider.id,
                            value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: safe.top + 12,
                right: 14 + safe.right,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _navigateToEarnings,
                    child: _FloatingPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${netRevenue.toStringAsFixed(0)} DA',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14 + safe.right,
                bottom: buttonBottom,
                child: Column(
                  children: [
                    _RoundMapButton(
                      icon: Icons.gps_fixed,
                      tooltip: strings.t('center_location'),
                      onTap: _centerProvider,
                    ),
                    const SizedBox(height: 10),
                    _RoundMapButton(
                      icon: Icons.payments_outlined,
                      tooltip: strings.t('earnings'),
                      onTap: _navigateToEarnings,
                    ),
                    const SizedBox(height: 10),
                    _RoundMapButton(
                      icon: Icons.logout,
                      tooltip: strings.t('admin_logout'),
                      onTap: () async {
                        await AuthService().signOut();
                      },
                    ),
                  ],
                ),
              ),
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if ((notification.extent - _panelExtent).abs() > 0.002) {
                    setState(() => _panelExtent = notification.extent);
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
                  minChildSize: minExtent,
                  initialChildSize: initialExtent,
                  maxChildSize: maxExtent,
                  snap: true,
                  snapSizes: [minExtent, initialExtent, maxExtent],
                  builder: (context, scrollController) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 20,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          children: [
                            const _SheetHandle(),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.t('provider_dashboard_title'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 21,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        provider.name.trim().isEmpty
                                            ? strings.t('provider')
                                            : provider.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _OnlineBadge(isOnline: provider.isOnline),
                              ],
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, cardConstraints) {
                                final compact = cardConstraints.maxWidth < 360;
                                final children = [
                                  _StatAction(
                                    onTap: available.isNotEmpty
                                        ? _navigateToAvailableMissions
                                        : null,
                                    child: _MiniStat(
                                      title: strings.t('available'),
                                      value: '${available.length}',
                                      highlight: available.isNotEmpty,
                                    ),
                                  ),
                                  _StatAction(
                                    onTap: active.isNotEmpty
                                        ? _navigateToActiveMissions
                                        : null,
                                    child: _MiniStat(
                                      title: strings.t('actives'),
                                      value: '${active.length}',
                                      highlight: active.isNotEmpty,
                                    ),
                                  ),
                                  _StatAction(
                                    onTap: _navigateToProfile,
                                    child: _MiniStat(
                                      title: strings.t('note'),
                                      value: provider.rating.toStringAsFixed(1),
                                    ),
                                  ),
                                  _StatAction(
                                    onTap: _navigateToEarnings,
                                    child: _MiniStat(
                                      title: strings.t('net_today'),
                                      value:
                                          '${netRevenue.toStringAsFixed(0)} DA',
                                      highlight: netRevenue > 0,
                                    ),
                                  ),
                                ];

                                if (compact) {
                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (final child in children)
                                        SizedBox(
                                          width:
                                              (cardConstraints.maxWidth - 10) /
                                                  2,
                                          child: child,
                                        ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: children[0]),
                                        const SizedBox(width: 10),
                                        Expanded(child: children[1]),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: children[2]),
                                        const SizedBox(width: 10),
                                        Expanded(child: children[3]),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingPill extends StatelessWidget {
  const _FloatingPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOnline ? 'ON' : 'OFF',
        style: TextStyle(
          color: isOnline ? const Color(0xFF166534) : const Color(0xFF475569),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatAction extends StatelessWidget {
  const _StatAction({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  final String title;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight ? const Color(0xFFF59E0B) : Colors.black54,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: highlight ? const Color(0xFFF59E0B) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
