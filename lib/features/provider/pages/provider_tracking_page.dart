import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/map_pin.dart';
import '../../shared/pages/chat_page.dart';
import 'provider_rate_client_page.dart';

class ProviderTrackingPage extends StatefulWidget {
  const ProviderTrackingPage({
    super.key,
    required this.store,
    required this.requestId,
  });

  final AppStore store;
  final String requestId;

  @override
  State<ProviderTrackingPage> createState() => _ProviderTrackingPageState();
}

class _ProviderTrackingPageState extends State<ProviderTrackingPage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  String? _handledRatingRequestId;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.store.startLiveTracking(widget.requestId);
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _checkForcedRating();
    setState(() {});
  }

  void _checkForcedRating() {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;
    if (!request.canProviderRate) return;
    if (_handledRatingRequestId == request.id) return;

    _handledRatingRequestId = request.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProviderRateClientPage(
            store: widget.store,
            requestId: request.id,
            forceMode: true,
          ),
        ),
      );
    });
  }

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('tel:$cleaned');
    await launchUrl(uri);
  }

  Future<void> _openInGoogleMaps(LatLng point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _buttonLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 'Demarrer trajet';
      case RequestStatus.onTheWay:
        return 'Confirmer arrivee';
      case RequestStatus.arrived:
        return 'Commencer service';
      case RequestStatus.inService:
        return 'Terminer mission';
      case RequestStatus.completed:
        return 'Mission terminee';
      case RequestStatus.cancelled:
        return 'Mission annulee';
      case RequestStatus.searching:
        return 'En attente';
    }
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.onTheWay:
        return Colors.orange;
      case RequestStatus.arrived:
        return Colors.deepOrange;
      case RequestStatus.inService:
        return Colors.purple;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
      case RequestStatus.searching:
        return Colors.grey;
    }
  }

  bool _isActionEnabled(RequestStatus status) {
    return status == RequestStatus.accepted ||
        status == RequestStatus.onTheWay ||
        status == RequestStatus.arrived ||
        status == RequestStatus.inService;
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.store.findRequest(widget.requestId);

    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('Mission introuvable')),
      );
    }

    final providerPosition =
        request.providerPosition ?? widget.store.providerCurrentPosition;
    final customerPosition = request.customerPosition;

    final center = providerPosition == null
        ? customerPosition
        : LatLng(
            (providerPosition.latitude + customerPosition.latitude) / 2,
            (providerPosition.longitude + customerPosition.longitude) / 2,
          );

    if (_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(center, 13.5);
        } catch (_) {}
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking mission'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.5,
                  onMapReady: () {
                    _mapReady = true;
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dz.depannage.provider',
                  ),
                  PolylineLayer(
                    polylines: [
                      if (providerPosition != null)
                        Polyline(
                          points: [providerPosition, customerPosition],
                          strokeWidth: 4,
                          color: Colors.green,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: customerPosition,
                        width: 74,
                        height: 74,
                        child: const MapPin(
                          label: 'Client',
                          icon: Icons.place,
                          color: Colors.red,
                        ),
                      ),
                      if (providerPosition != null)
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
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.status.label,
                    style: TextStyle(
                      color: _statusColor(request.status),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    request.landmark,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (request.destination.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Destination: ${request.destination}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionSquareButton(
                          icon: Icons.call_outlined,
                          label: 'Appeler',
                          onTap: () => _callPhone(request.customerPhone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionSquareButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  requestId: request.id,
                                  title: 'Chat client',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionSquareButton(
                          icon: Icons.map_outlined,
                          label: 'Maps',
                          onTap: () => _openInGoogleMaps(customerPosition),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isActionEnabled(request.status)
                          ? () async {
                              await widget.store.advanceMission(request.id);
                            }
                          : null,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(_buttonLabel(request.status)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSquareButton extends StatelessWidget {
  const _ActionSquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}