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

  bool _loading = false;
  List<PlaceSearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _results = [];
    });

    try {
      final items = await _searchService.searchPlaces(query);
      if (!mounted) return;

      setState(() {
        _results = items;
      });

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun resultat trouve. Essayez un autre texte.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      ...widget.store.savedAddresses,
      'Garage central Batna',
      'Djerma',
      'Fesdis',
      'Tazoult',
    ];

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
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Rechercher une vraie destination',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                ),
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
                    title: Text(item.displayName),
                    subtitle: Text(
                      'Lat ${item.position.latitude.toStringAsFixed(5)} • Lng ${item.position.longitude.toStringAsFixed(5)}',
                    ),
                    onTap: () => _selectResult(item),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            const Text(
              'Suggestions rapides',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            ...suggestions.map(
              (item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(item),
                  onTap: () {
                    _controller.text = item;
                    _search();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}