import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    final store = widget.store;
    final customerPosition =
        store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);
    final activeRequest = store.activeCustomerRequests.isNotEmpty
        ? store.activeCustomerRequests.first
        : null;

    return Scaffold(
      body: Stack(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.depannage.customer',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: customerPosition,
                    width: 86,
                    height: 86,
                    child: const MapPin(
                      label: 'Vous',
                      icon: Icons.place,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text(
                      'Besoin d un service ?',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.customerLocationLoading
                          ? 'Localisation en cours...'
                          : (store.customerLocationMessage ??
                              'Choisissez votre trajet rapidement.'),
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
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
                              ? 'Suivre ma mission actuelle'
                              : 'Choisir destination',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 180,
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
        ],
      ),
    );
  }
}
