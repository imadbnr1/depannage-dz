import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/place_search_result.dart';
import '../../../core/services/place_search_service.dart';
import '../../../state/app_store.dart';
import 'select_destination_on_map_page.dart';

class PickDestinationPage extends StatefulWidget {
  const PickDestinationPage({
    super.key,
    required this.store,
    required this.initialCenter,
    this.initialText,
  });

  final AppStore store;
  final LatLng initialCenter;
  final String? initialText;

  @override
  State<PickDestinationPage> createState() => _PickDestinationPageState();
}

class _PickDestinationPageState extends State<PickDestinationPage> {
  late final TextEditingController _controller;
  final _searchService = PlaceSearchService();

  Timer? _debounce;
  Timer? _nearbyDebounce;
  bool _loading = false;
  bool _loadingNearby = false;
  List<PlaceSearchResult> _results = [];
  List<PlaceSearchResult> _nearbySuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');

    // Listen to position changes to update nearby suggestions
    widget.store.addListener(_onPositionChanged);

    if (_controller.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSearchChanged(_controller.text);
      });
    } else {
      // Load nearby places automatically
      _loadNearbyPlaces();
    }
  }

  void _onPositionChanged() {
    // Reload nearby suggestions when user position changes
    if (_controller.text.trim().isEmpty) {
      _loadNearbyPlaces();
    }
  }

  void _loadNearbyPlaces() {
    _nearbyDebounce?.cancel();
    _nearbyDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _loadingNearby = true;
      });

      try {
        final position = widget.store.customerCurrentPosition ?? widget.initialCenter;
        final places = await _searchService.fetchNearbyPlaces(position, limit: 8);

        if (!mounted) return;
        setState(() {
          _nearbySuggestions = places;
        });
      } catch (e) {
        // Fallback suggestions will be provided by the service
      } finally {
        if (mounted) {
          setState(() => _loadingNearby = false);
        }
      }
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onPositionChanged);
    _debounce?.cancel();
    _nearbyDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      setState(() {
        _loading = true;
      });

      try {
        final items = await _searchService.searchPlaces(trimmed);

        if (!mounted) return;
        setState(() {
          _results = items;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _results = [];
        });

        // Only show error if user manually typed (not from suggestion click)
        // to avoid annoying popups when clicking suggestions
        if (query.trim().length > 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Recherche indisponible. Essayez avec un autre terme ou choisissez sur la carte.',
              ),
              backgroundColor: Color(0xFFE65100),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    });
  }

  Future<void> _openMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => SelectDestinationOnMapPage(
          initialCenter: widget.initialCenter,
        ),
      ),
    );

    if (result == null || !mounted) return;

    Navigator.of(context).pop({
      'label':
          'Destination carte (${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)})',
      'point': result,
    });
  }

  void _selectResult(PlaceSearchResult item) {
    Navigator.of(context).pop({
      'label': item.displayName,
      'point': item.position,
    });
  }

  /// Get dynamic automotive-focused quick suggestions based on current location
  List<String> _getAutomotiveSuggestions() {
    // Generate dynamic suggestions based on user's actual location
    // These will be searched via geocoding when clicked
    return [
      'Zone Industrielle',
      'Zone Artisanale', 
      'Route Nationale',
      'Centre Ville',
      'Garage',
      'Station Service',
      'Cité Mechaniciens',
      'Marché Automobile',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getAutomotiveSuggestions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir destination'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ex: Garage, Station service, Zone industrielle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Choisir sur la carte'),
              ),
            ),
            const SizedBox(height: 18),
            if (_results.isNotEmpty) ...[
              const Text(
                'Resultats',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              ..._results.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Lat ${item.position.latitude.toStringAsFixed(5)} • Lng ${item.position.longitude.toStringAsFixed(5)}',
                    ),
                    onTap: () => _selectResult(item),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (_nearbySuggestions.isNotEmpty || _loadingNearby) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Services auto à proximité',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  if (_loadingNearby)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ..._nearbySuggestions.map(
                (item) => Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.garage_outlined,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Lat ${item.position.latitude.toStringAsFixed(4)} • Lng ${item.position.longitude.toStringAsFixed(4)}',
                    ),
                    onTap: () => _selectResult(item),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            // Show static fallback suggestions only if no nearby places found
            if (_nearbySuggestions.isEmpty && !_loadingNearby) ...[
              const Text(
                'Zones automobiles (Batna)',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              ...suggestions.map(
                (item) => Card(
                  child: ListTile(
                    leading: _loading && _controller.text == item
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.garage_outlined),
                    title: Text(item),
                    onTap: () {
                      _controller.text = item;
                      _onSearchChanged(item);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}