import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/auth_service.dart';
import '../../../models/provider_agent.dart';
import '../../../models/request_status.dart';
import '../../../models/service_type.dart';
import '../../../state/app_store.dart';
import '../../../widgets/map_pin.dart';
import '../../../widgets/panel_card.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({super.key, required this.store});

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

  String _serviceText(ServiceType service) {
    try {
      final dynamic label = (service as dynamic).label;
      if (label is String && label.trim().isNotEmpty) return label;
    } catch (_) {}

    final raw = service.toString();
    if (raw.contains('.')) {
      return raw.split('.').last;
    }
    return raw;
  }

  Future<void> _detectAndCenterProvider() async {
    await widget.store.requestProviderLocation();

    final provider = widget.store.selectedProviderOrNull;
    final position = widget.store.providerCurrentPosition ??
        provider?.position ??
        const LatLng(36.7538, 3.0588);

    if (!_mapReady) return;
    if (!position.latitude.isFinite || !position.longitude.isFinite) return;

    try {
      _mapController.move(position, 16);
    } catch (_) {}
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final provider = store.selectedProvider;
    final providerPosition = store.providerCurrentPosition ?? provider.position;
    final availableCount = store.providerAvailableRequests.length;
    final activeCount = store.providerAssignedRequests.length;
    final completedCount = provider.missionsCompleted;

    final providerId = provider.id;
    final todayCompleted = store.requests.where((r) {
      if (r.providerUid != providerId) return false;
      if (r.status != RequestStatus.completed) return false;
      final completedAt = r.completedAt ?? r.createdAt;
      return _isToday(completedAt);
    }).toList();

    final todayRevenue = todayCompleted.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    final todayCommission = todayCompleted.fold<double>(
      0,
      (sum, item) => sum + store.estimateCommissionAmount(item.estimatedPrice ?? 0),
    );

    final todayNet = todayRevenue - todayCommission;

    final nearestRequest = store.providerAvailableRequests.isNotEmpty
        ? store.providerAvailableRequests.first
        : null;

    final mapCenter = nearestRequest != null
        ? LatLng(
            (providerPosition.latitude +
                    nearestRequest.customerPosition.latitude) /
                2,
            (providerPosition.longitude +
                    nearestRequest.customerPosition.longitude) /
                2,
          )
        : providerPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _IdentityHeader(
              provider: provider,
              locationMessage: store.providerLocationLoading
                  ? 'Localisation provider en cours...'
                  : (store.providerLocationMessage ??
                      'Position provider inconnue'),
              onToggleOnline: (value) async {
                await store.updateProviderOnlineStatus(provider.id, value);
              },
              onOpenProfile: () {
                store.setProviderTab(3);
              },
            ),
            const SizedBox(height: 10),

            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gains du jour',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MoneyBox(
                          title: 'Brut',
                          value: '${todayRevenue.toStringAsFixed(0)} DA',
                          subtitle: '${todayCompleted.length} mission(s)',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MoneyBox(
                          title: 'Commission',
                          value: '${todayCommission.toStringAsFixed(0)} DA',
                          subtitle:
                              '${store.pricingCommissionPercent.toStringAsFixed(0)} % plateforme',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MoneyBox(
                          title: 'Net',
                          value: '${todayNet.toStringAsFixed(0)} DA',
                          subtitle: 'Profit journalier',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Carte live provider',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          onTap: _detectAndCenterProvider,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: store.providerLocationLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 230,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: mapCenter,
                          initialZoom: 13,
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
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: providerPosition,
                                width: 74,
                                height: 74,
                                child: const MapPin(
                                  label: 'Provider',
                                  icon: Icons.local_shipping,
                                  color: Colors.blue,
                                ),
                              ),
                              if (nearestRequest != null)
                                Marker(
                                  point: nearestRequest.customerPosition,
                                  width: 70,
                                  height: 70,
                                  child: const MapPin(
                                    label: 'Client',
                                    icon: Icons.place,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          if (nearestRequest != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    providerPosition,
                                    nearestRequest.customerPosition,
                                  ],
                                  strokeWidth: 4,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (nearestRequest != null) ...[
                    Text(
                      nearestRequest.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_serviceText(nearestRequest.service)} · ${nearestRequest.vehicleType} · ${nearestRequest.brandModel}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nearestRequest.landmark,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (nearestRequest.estimatedDistanceKm != null)
                          _MiniBadge(
                            label:
                                '${nearestRequest.estimatedDistanceKm!.toStringAsFixed(1)} km',
                          ),
                        if (nearestRequest.estimatedDurationMinutes != null)
                          _MiniBadge(
                            label:
                                'ETA ${nearestRequest.estimatedDurationMinutes} min',
                          ),
                        if (nearestRequest.estimatedPrice != null)
                          _MiniBadge(
                            label:
                                '${nearestRequest.estimatedPrice!.toStringAsFixed(0)} DA',
                          ),
                      ],
                    ),
                  ] else
                    const Text(
                      'Aucune mission disponible pour ce provider',
                      style: TextStyle(color: Colors.black54),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.45,
              children: [
                _StatCard(
                  title: 'Disponibles',
                  value: '$availableCount',
                  icon: Icons.notifications_active_outlined,
                  subtitle: 'Demandes visibles',
                ),
                _StatCard(
                  title: 'En cours',
                  value: '$activeCount',
                  icon: Icons.local_shipping_outlined,
                  subtitle: 'Missions actives',
                ),
                _StatCard(
                  title: 'Missions',
                  value: '$completedCount',
                  icon: Icons.check_circle_outline,
                  subtitle: 'Historique complet',
                ),
                _StatCard(
                  title: 'Note',
                  value: provider.rating.toStringAsFixed(1),
                  icon: Icons.star_outline,
                  subtitle: '${provider.ratingCount} avis',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({
    required this.provider,
    required this.locationMessage,
    required this.onToggleOnline,
    required this.onOpenProfile,
  });

  final ProviderAgent provider;
  final String locationMessage;
  final ValueChanged<bool> onToggleOnline;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: provider.isOnline
            ? const Color(0xFFECFDF5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: provider.isOnline
              ? const Color(0xFF86EFAC)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: provider.isOnline
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF94A3B8),
                child: Text(
                  provider.avatarText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        if (provider.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationMessage,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniBadge(
                          label: provider.vehicleType.isEmpty
                              ? 'Vehicule non renseigne'
                              : provider.vehicleType,
                        ),
                        _MiniBadge(
                          label: provider.plate.isEmpty
                              ? 'Plaque manquante'
                              : provider.plate,
                        ),
                        _MiniBadge(
                          label: provider.isOnline ? 'En ligne' : 'Hors ligne',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.isOnline,
                onChanged: onToggleOnline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenProfile,
              icon: const Icon(Icons.person_outline),
              label: const Text('Mon profil'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

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
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MoneyBox extends StatelessWidget {
  const _MoneyBox({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}