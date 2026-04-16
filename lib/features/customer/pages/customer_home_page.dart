import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/service_type.dart';
import '../../../state/app_store.dart';
import 'create_order_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key, required this.store});

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

  String _serviceLabel(ServiceType service) {
    try {
      final dynamic label = (service as dynamic).label;
      if (label is String && label.trim().isNotEmpty) return label;
    } catch (_) {}

    final raw = service.toString();
    if (raw.contains('.')) return raw.split('.').last;
    return raw;
  }

  IconData _serviceIcon(ServiceType service) {
    try {
      final dynamic icon = (service as dynamic).icon;
      if (icon is IconData) return icon;
    } catch (_) {}

    final label = _serviceLabel(service).toLowerCase();
    if (label.contains('remorquage')) return Icons.local_shipping_outlined;
    if (label.contains('batterie')) return Icons.battery_charging_full;
    if (label.contains('pneu')) return Icons.tire_repair;
    return Icons.build_circle_outlined;
  }

  String _serviceDescription(ServiceType service) {
    final label = _serviceLabel(service).toLowerCase();

    if (label.contains('remorquage')) {
      return 'Transport vehicule';
    } else if (label.contains('batterie')) {
      return 'Batterie ou demarrage';
    } else if (label.contains('pneu')) {
      return 'Crevaison ou roue';
    } else {
      return 'Depannage rapide';
    }
  }

  Future<void> _detectAndCenterCustomer() async {
    await widget.store.requestCustomerLocation();

    final position =
        widget.store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);

    if (!_mapReady) return;
    if (!position.latitude.isFinite || !position.longitude.isFinite) return;

    try {
      _mapController.move(position, 16);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final currentPosition =
        store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);
    final services = ServiceType.values.toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPosition,
              initialZoom: 13.8,
              onMapReady: () {
                _mapReady = true;
                try {
                  _mapController.move(currentPosition, 15);
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
                    point: currentPosition,
                    width: 76,
                    height: 76,
                    child: const _MapUserPin(),
                  ),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFDBEAFE),
                            child: Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              store.customerLocationLoading
                                  ? 'Localisation en cours...'
                                  : (store.customerLocationMessage ??
                                      'Position GPS active'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white.withOpacity(0.96),
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: _detectAndCenterCustomer,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: store.customerLocationLoading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.26,
            minChildSize: 0.15,
            maxChildSize: 0.76,
            snap: true,
            snapSizes: const [0.15, 0.26, 0.46, 0.76],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 26,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Besoin d aide ?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Choisissez un service et envoyez votre demande rapidement.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      height: 1.3,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          'Services',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          'Choisissez un service pour continuer.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      GridView.builder(
                        itemCount: services.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.08,
                        ),
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return _ServiceCard(
                            label: _serviceLabel(service),
                            icon: _serviceIcon(service),
                            description: _serviceDescription(service),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreateOrderPage(
                                    store: store,
                                    service: service,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pourquoi Depannage DZ',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 12),
                            _FeatureRow(
                              icon: Icons.verified_user_outlined,
                              title: 'Providers verifies',
                              text: 'Intervenants suivis et fiables.',
                            ),
                            SizedBox(height: 10),
                            _FeatureRow(
                              icon: Icons.route_outlined,
                              title: 'Tracking direct',
                              text: 'Suivez votre mission en temps reel.',
                            ),
                            SizedBox(height: 10),
                            _FeatureRow(
                              icon: Icons.price_check_outlined,
                              title: 'Prix estime',
                              text: 'Estimation avant confirmation.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapUserPin extends StatelessWidget {
  const _MapUserPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Text(
            'Vous',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Icon(
          Icons.place,
          color: Colors.red,
          size: 34,
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 11.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.25,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}