import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/service_type.dart';
import '../../../state/app_store.dart';
import 'pick_destination_page.dart';
import 'request_preview_page.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    required this.store,
    required this.service,
  });

  final AppStore store;
  final ServiceType service;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();

  bool _isSubmitting = false;

  LatLng? _pickupPoint;
  LatLng? _destinationPoint;

  LatLng get _customerPosition =>
      widget.store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);

  double get _estimatedDistanceKm {
    if (_pickupPoint == null || _destinationPoint == null) return 0;
    return widget.store.estimateDistanceKm(
      from: _pickupPoint!,
      to: _destinationPoint!,
    );
  }

  int get _estimatedEtaMinutes {
    return widget.store.estimateDurationMinutes(
      distanceKm: _estimatedDistanceKm,
      service: widget.service,
    );
  }

  double get _estimatedPrice {
    return widget.store.estimatePrice(
      service: widget.service,
      distanceKm: _estimatedDistanceKm,
      hasDestination: _destinationController.text.trim().isNotEmpty,
      urgency: 'Standard',
    );
  }

  @override
  void initState() {
    super.initState();
    _pickupPoint = _customerPosition;
    _pickupController.text = 'Ma position actuelle';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickPickup() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PickDestinationPage(
          store: widget.store,
          initialCenter: _pickupPoint ?? _customerPosition,
          initialText: _pickupController.text,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _pickupController.text = (result['label'] as String?) ?? '';
      _pickupPoint = result['point'] as LatLng?;
    });
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PickDestinationPage(
          store: widget.store,
          initialCenter: _pickupPoint ?? _customerPosition,
          initialText: _destinationController.text,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _destinationController.text = (result['label'] as String?) ?? '';
      _destinationPoint = result['point'] as LatLng?;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un point de depart valide.'),
        ),
      );
      return;
    }

    if (_destinationPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez une destination valide.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.store.createRequest(
        service: widget.service,
        customerPosition: _pickupPoint!,
        pickupLabel: _pickupController.text.trim(),
        pickupSubtitle: 'Point de depart',
        vehicleType: 'Vehicule',
        brandModel: 'Non precise',
        payment: 'Especes',
        landmark: '',
        issueDescription: 'Demande rapide',
        urgency: 'Standard',
        destination: _destinationController.text.trim(),
        destinationPosition: _destinationPoint!,
        photoHint: '',
      );

      final latest =
          widget.store.requests.isNotEmpty ? widget.store.requests.first : null;

      if (!mounted || latest == null) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestPreviewPage(
            store: widget.store,
            requestId: latest.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _ReadOnlyPicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Champ obligatoire';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: const Icon(Icons.chevron_right),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre trajet'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _ReadOnlyPicker(
                      label: 'Depart',
                      controller: _pickupController,
                      onTap: _pickPickup,
                      hint: 'Choisir le point de depart',
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyPicker(
                      label: 'Destination',
                      controller: _destinationController,
                      onTap: _pickDestination,
                      hint: 'Choisir la destination',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimation',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EstimateBox(
                            title: 'Distance',
                            value: '${_estimatedDistanceKm.toStringAsFixed(1)} km',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _EstimateBox(
                            title: 'ETA',
                            value: '$_estimatedEtaMinutes min',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _EstimateBox(
                            title: 'Prix',
                            value: '${_estimatedPrice.toStringAsFixed(0)} DA',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? 'Creation...' : 'Confirmer la demande',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimateBox extends StatelessWidget {
  const _EstimateBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
        ],
      ),
    );
  }
}
