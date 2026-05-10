import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../models/service_type.dart';
import '../../../state/app_store.dart';
import '../../../widgets/map_pin.dart';
import 'create_order_page.dart';
import 'customer_tracking_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  double _panelExtent = 0.24;

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

  Future<void> _centerCustomer() async {
    await widget.store.requestCustomerLocation();
    final position =
        widget.store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);

    if (!_mapReady) return;

    try {
      _mapController.move(position, 16);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final store = widget.store;
    final customerPosition =
        store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);
    final activeRequest = store.activeCustomerRequests.isNotEmpty
        ? store.activeCustomerRequests.first
        : null;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final safe = MediaQuery.paddingOf(context);
          final compactHeight = constraints.maxHeight < 620;
          final minExtent = compactHeight ? 0.18 : 0.16;
          final initialExtent = compactHeight ? 0.28 : 0.24;
          final maxExtent = compactHeight ? 0.62 : 0.52;
          final clampedExtent =
              _panelExtent.clamp(minExtent, maxExtent).toDouble();
          final buttonBottom =
              (constraints.maxHeight * clampedExtent) + safe.bottom + 14;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: customerPosition,
                  initialZoom: 13.5,
                  onMapReady: () {
                    _mapReady = true;
                    try {
                      _mapController.move(customerPosition, 15);
                    } catch (_) {}
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dz.depannage.customer',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: customerPosition,
                        width: 86,
                        height: 86,
                        child: MapPin(
                          label: strings.t('vous'),
                          icon: Icons.place,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 16 + safe.right,
                bottom: buttonBottom,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    onTap: _centerCustomer,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: store.customerLocationLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gps_fixed),
                    ),
                  ),
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.t('need_service'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        store.customerLocationLoading
                                            ? strings.t('locating')
                                            : (store.customerLocationMessage ??
                                                strings.t(
                                                  'choose_trip_quickly',
                                                )),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  activeRequest == null
                                      ? Icons.route_outlined
                                      : Icons.radar_rounded,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (activeRequest != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CustomerTrackingPage(
                                          store: store,
                                          requestId: activeRequest.id,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CreateOrderPage(
                                        store: store,
                                        service: ServiceType.values.first,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.route_outlined),
                                label: Text(
                                  activeRequest != null
                                      ? strings.t('track_current_mission')
                                      : strings.t('choisir_destination'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _CustomerPanelDetails(
                              activeRequestLabel: activeRequest == null
                                  ? strings.t('no_active_request_short')
                                  : strings.t('active_request_running'),
                              pickupLabel: activeRequest?.pickupLabel ??
                                  strings.t('vous'),
                              destinationLabel: activeRequest?.destination ??
                                  strings.t('destination_waiting'),
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

class _CustomerPanelDetails extends StatelessWidget {
  const _CustomerPanelDetails({
    required this.activeRequestLabel,
    required this.pickupLabel,
    required this.destinationLabel,
  });

  final String activeRequestLabel;
  final String pickupLabel;
  final String destinationLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        _DetailRow(
          icon: Icons.assignment_turned_in_outlined,
          title: strings.t('status'),
          value: activeRequestLabel,
        ),
        const SizedBox(height: 10),
        _DetailRow(
          icon: Icons.my_location_outlined,
          title: strings.t('depart'),
          value: pickupLabel,
        ),
        const SizedBox(height: 10),
        _DetailRow(
          icon: Icons.flag_outlined,
          title: strings.t('destination'),
          value: destinationLabel,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
