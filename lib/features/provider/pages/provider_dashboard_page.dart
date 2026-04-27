import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        child: const MapPin(
          label: 'Provider',
          icon: Icons.car_repair_rounded,
          color: Color(0xFFF59E0B),
        ),
      ),
    ];

    for (final item in active.take(1)) {
      markers.add(
        Marker(
          point: item.customerPosition,
          width: 82,
          height: 82,
          child: const MapPin(
            label: 'Client',
            icon: Icons.place,
            color: Colors.red,
          ),
        ),
      );
    }

    final netRevenue = _todayNetRevenue();

    return Scaffold(
      body: Stack(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.depannage.provider',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 14,
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
                      await store.updateProviderOnlineStatus(provider.id, value);
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderEarningsPage(store: store),
                    ),
                  );
                },
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
            right: 14,
            bottom: 110,
            child: Column(
              children: [
                _RoundMapButton(
                  icon: Icons.gps_fixed,
                  onTap: _centerProvider,
                ),
                const SizedBox(height: 10),
                _RoundMapButton(
                  icon: Icons.assignment_outlined,
                  onTap: () {
                    store.setProviderTab(1);
                  },
                ),
                const SizedBox(height: 10),
                _RoundMapButton(
                  icon: Icons.logout,
                  onTap: () async {
                    await AuthService().signOut();
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: _FloatingBottomCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 360) {
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: _MiniStat(
                            title: 'Disponibles',
                            value: '${available.length}',
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: _MiniStat(
                            title: 'Actives',
                            value: '${active.length}',
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth,
                          child: _MiniStat(
                            title: 'Note',
                            value: provider.rating.toStringAsFixed(1),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          title: 'Disponibles',
                          value: '${available.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          title: 'Actives',
                          value: '${active.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          title: 'Note',
                          value: provider.rating.toStringAsFixed(1),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
    );
  }
}

class _FloatingBottomCard extends StatelessWidget {
  const _FloatingBottomCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
