import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectDestinationOnMapPage extends StatefulWidget {
  const SelectDestinationOnMapPage({
    super.key,
    required this.initialCenter,
  });

  final LatLng initialCenter;

  @override
  State<SelectDestinationOnMapPage> createState() =>
      _SelectDestinationOnMapPageState();
}

class _SelectDestinationOnMapPageState
    extends State<SelectDestinationOnMapPage> {
  late final MapController _mapController;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir destination'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 14,
              onTap: (_, point) {
                setState(() {
                  _selectedPoint = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.depannage.customer',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 80,
                      height: 80,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 42,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Touchez la carte pour choisir la destination',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedPoint != null)
                      Text(
                        'Lat: ${_selectedPoint!.latitude.toStringAsFixed(5)} • Lng: ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _selectedPoint == null
                            ? null
                            : () {
                                Navigator.of(context).pop(_selectedPoint);
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmer cette destination'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}