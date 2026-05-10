import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/place_search_result.dart';
import '../../../core/services/place_search_service.dart';
import '../../../state/app_store.dart';
import 'select_destination_on_map_page.dart';

enum LocationPickMode {
  pickup,
  destination,
}

class PickDestinationPage extends StatefulWidget {
  const PickDestinationPage({
    super.key,
    required this.store,
    required this.initialCenter,
    this.mode = LocationPickMode.destination,
    this.initialText,
  });

  final AppStore store;
  final LatLng initialCenter;
  final LocationPickMode mode;
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
  bool _loadingCurrentLocation = false;
  List<PlaceSearchResult> _results = [];
  List<PlaceSearchResult> _nearbySuggestions = [];

  bool get _isPickup => widget.mode == LocationPickMode.pickup;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');

    // Listen to position changes to update nearby suggestions
    widget.store.addListener(_onPositionChanged);

    final initialText = _controller.text.trim();
    final currentLocationLabels = {
      'Ma position actuelle',
      'My current location',
      'موقعي الحالي',
    };
    if (initialText.isNotEmpty &&
        !(_isPickup && currentLocationLabels.contains(initialText))) {
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
        final position =
            widget.store.customerCurrentPosition ?? widget.initialCenter;
        final places =
            await _searchService.fetchNearbyPlaces(position, limit: 8);

        if (!mounted) return;
        setState(() {
          _nearbySuggestions =
              places.isNotEmpty ? places : _localFallbackSuggestions(position);
        });
      } catch (e) {
        final position =
            widget.store.customerCurrentPosition ?? widget.initialCenter;
        if (!mounted) return;
        setState(() {
          _nearbySuggestions = _localFallbackSuggestions(position);
        });
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context).t('search_unavailable_try_map'),
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
          isPickup: _isPickup,
        ),
      ),
    );

    if (result == null || !mounted) return;
    final address = await _searchService.reverseLookupNearestNamedPlace(result);
    if (!mounted) return;

    Navigator.of(context).pop({
      'label': address?.trim().isNotEmpty == true
          ? address
          : _mapFallbackLabel(result),
      'point': result,
    });
  }

  void _selectResult(PlaceSearchResult item) {
    Navigator.of(context).pop({
      'label': item.displayName,
      'point': item.position,
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingCurrentLocation) return;

    setState(() => _loadingCurrentLocation = true);
    try {
      await widget.store.requestCustomerLocation();
      final position =
          widget.store.customerCurrentPosition ?? widget.initialCenter;
      final address =
          await _searchService.reverseLookupNearestNamedPlace(position);

      if (!mounted) return;
      Navigator.of(context).pop({
        'label': address?.trim().isNotEmpty == true
            ? address
            : AppLocalizations.of(context).t('current_location'),
        'point': position,
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).t('position_unavailable_choose_map'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingCurrentLocation = false);
    }
  }

  String _mapFallbackLabel(LatLng point) {
    final strings = AppLocalizations.of(context);
    final prefix = _isPickup
        ? strings.t('map_pickup_label')
        : strings.t('map_destination_label');
    return '$prefix (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
  }

  List<PlaceSearchResult> _localFallbackSuggestions(LatLng center) {
    final items = _isPickup
        ? [
            (AppLocalizations.of(context).t('current_location'), 0.0, 0.0),
            ('Route principale proche', 0.006, 0.004),
            ('Station service proche', -0.004, 0.006),
            ('Garage proche', 0.005, -0.005),
            ('Centre ville proche', -0.006, -0.003),
          ]
        : [
            ('Garage proche', 0.005, -0.005),
            ('Station service proche', -0.004, 0.006),
            ('Zone industrielle proche', 0.012, 0.008),
            ('Centre ville proche', -0.006, -0.003),
            ('Route principale proche', 0.006, 0.004),
          ];

    return items.map((item) {
      return PlaceSearchResult(
        displayName: item.$1,
        position: LatLng(
          center.latitude + item.$2,
          center.longitude + item.$3,
        ),
      );
    }).toList();
  }

  String get _title {
    final strings = AppLocalizations.of(context);
    return _isPickup
        ? strings.t('choose_pickup')
        : strings.t('choisir_destination');
  }

  String get _hintText {
    final strings = AppLocalizations.of(context);
    return _isPickup
        ? strings.t('pickup_search_hint')
        : strings.t('destination_search_hint');
  }

  String get _emptyTitle {
    final strings = AppLocalizations.of(context);
    return _isPickup
        ? strings.t('no_pickup_suggestion')
        : strings.t('no_destination_found');
  }

  String get _emptySubtitle {
    final strings = AppLocalizations.of(context);
    return _isPickup
        ? strings.t('no_pickup_suggestion_sub')
        : strings.t('no_destination_found_sub');
  }

  /// Search seeds shown only if dynamic nearby lookup is still empty.
  List<String> _getAutomotiveSuggestions() {
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

  Future<void> _selectSeedSuggestion(String label) async {
    setState(() {
      _controller.text = label;
      _loading = true;
    });

    try {
      final results = await _searchService.searchPlaces(label);
      if (!mounted) return;

      if (results.isNotEmpty) {
        _selectResult(results.first);
        return;
      }

      final center =
          widget.store.customerCurrentPosition ?? widget.initialCenter;
      final fallback = _localFallbackSuggestions(center).firstWhere(
        (item) => item.displayName
            .toLowerCase()
            .contains(label.split(' ').first.toLowerCase()),
        orElse: () => PlaceSearchResult(
          displayName: label,
          position: center,
        ),
      );
      _selectResult(fallback);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getAutomotiveSuggestions();
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
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
                hintText: _hintText,
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
            if (_isPickup) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _loadingCurrentLocation ? null : _useCurrentLocation,
                  icon: _loadingCurrentLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                  label: Text(strings.t('current_location')),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(strings.t('choisir_sur_la_carte')),
              ),
            ),
            const SizedBox(height: 18),
            if (_results.isNotEmpty) ...[
              Text(
                strings.t('result_count'),
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
                    onTap: () {
                      if (_isPickup &&
                          item.displayName == strings.t('current_location')) {
                        _useCurrentLocation();
                        return;
                      }
                      _selectResult(item);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (_nearbySuggestions.isNotEmpty || _loadingNearby) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.t('nearby_auto_services'),
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
                    onTap: () {
                      if (_isPickup &&
                          item.displayName == strings.t('current_location')) {
                        _useCurrentLocation();
                        return;
                      }
                      _selectResult(item);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            // Show static fallback suggestions only if no nearby places found
            if (_nearbySuggestions.isEmpty && !_loadingNearby) ...[
              Text(
                strings.t('local_suggestions'),
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
                    onTap: () => _selectSeedSuggestion(item),
                  ),
                ),
              ),
            ],
            if (_results.isEmpty &&
                _nearbySuggestions.isEmpty &&
                !_loading &&
                !_loadingNearby) ...[
              const SizedBox(height: 18),
              _EmptyLocationState(
                title: _emptyTitle,
                subtitle: _emptySubtitle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyLocationState extends StatelessWidget {
  const _EmptyLocationState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.black45),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
