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

  final _vehicleTypeController = TextEditingController();
  final _brandModelController = TextEditingController();
  final _issueDescriptionController = TextEditingController();
  final _pickupLabelController =
      TextEditingController(text: 'Ma position actuelle');
  final _landmarkController = TextEditingController();
  final _destinationController = TextEditingController();

  String _payment = 'Especes';
  String _urgency = 'Standard';
  bool _isSubmitting = false;

  LatLng? _selectedDestinationPoint;

  LatLng get _customerPosition =>
      widget.store.customerCurrentPosition ?? const LatLng(36.7538, 3.0588);

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

  LatLng _fallbackDestinationFromText(String text) {
    if (text.trim().isEmpty) {
      return LatLng(
        _customerPosition.latitude + 0.012,
        _customerPosition.longitude + 0.012,
      );
    }

    final hash = text.trim().codeUnits.fold<int>(0, (a, b) => a + b);
    final latOffset = ((hash % 12) + 6) / 1000;
    final lngOffset = (((hash ~/ 7) % 12) + 6) / 1000;

    return LatLng(
      _customerPosition.latitude + latOffset,
      _customerPosition.longitude + lngOffset,
    );
  }

  double get _estimatedDistanceKm {
    final target = _selectedDestinationPoint ??
        _fallbackDestinationFromText(_destinationController.text);

    return widget.store.estimateDistanceKm(
      from: _customerPosition,
      to: target,
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
      urgency: _urgency,
    );
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PickDestinationPage(
          store: widget.store,
          initialCenter: _customerPosition,
          initialText: _destinationController.text,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _destinationController.text = (result['label'] as String?) ?? '';
      _selectedDestinationPoint = result['point'] as LatLng?;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La destination est obligatoire.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final destinationPosition =
    _selectedDestinationPoint ??
    _fallbackDestinationFromText(_destinationController.text);

await widget.store.createRequest(
  service: widget.service,
  customerPosition: _customerPosition,
  pickupLabel: _pickupLabelController.text.trim(),
  pickupSubtitle: 'Position client',
  vehicleType: _vehicleTypeController.text.trim(),
  brandModel: _brandModelController.text.trim(),
  payment: _payment,
  landmark: _landmarkController.text.trim(),
  issueDescription: _issueDescriptionController.text.trim(),
  urgency: _urgency,
  destination: _destinationController.text.trim(),
  destinationPosition: destinationPosition, // ✅ NEW
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

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _brandModelController.dispose();
    _issueDescriptionController.dispose();
    _pickupLabelController.dispose();
    _landmarkController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2563EB);
    final serviceLabel = _serviceLabel(widget.service);

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceLabel),
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
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      // ignore: deprecated_member_use
                      accent.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        _serviceIcon(widget.service),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 21,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Remplissez seulement les informations essentielles.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
  title: 'Destination obligatoire',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _destinationController,
        readOnly: true,
        validator: (_) {
          if (_destinationController.text.trim().isEmpty) {
            return 'Choisissez la destination';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Rechercher ou choisir une destination',
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _pickDestination,
          icon: const Icon(Icons.search),
          label: Text(
            _destinationController.text.trim().isEmpty
                ? 'Rechercher une destination'
                : 'Modifier la destination',
          ),
        ),
      ),
      if (_selectedDestinationPoint != null) ...[
        const SizedBox(height: 10),
        Text(
          'Lat: ${_selectedDestinationPoint!.latitude.toStringAsFixed(5)} • Lng: ${_selectedDestinationPoint!.longitude.toStringAsFixed(5)}',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    ],
  ),
),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Vehicule',
                child: Column(
                  children: [
                    _LabeledField(
                      controller: _vehicleTypeController,
                      label: 'Type de vehicule',
                      hint: 'Ex: Citadine, SUV, utilitaire',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Entrez le type de vehicule';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      controller: _brandModelController,
                      label: 'Marque / modele',
                      hint: 'Ex: Renault Clio 4',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Entrez la marque et le modele';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Mission',
                child: Column(
                  children: [
                    _LabeledField(
                      controller: _issueDescriptionController,
                      label: 'Probleme',
                      hint: 'Ex: voiture ne demarre plus',
                      maxLines: 3,
                      validator: (value) {
                        if ((value ?? '').trim().length < 6) {
                          return 'Decrivez le probleme';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      controller: _landmarkController,
                      label: 'Repere',
                      hint: 'Ex: pres du cafe, devant la pharmacie',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Ajoutez un repere';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Urgence',
                      value: _urgency,
                      items: const [
                        DropdownMenuItem(
                          value: 'Standard',
                          child: Text('Standard'),
                        ),
                        DropdownMenuItem(
                          value: 'Urgent',
                          child: Text('Urgent'),
                        ),
                        DropdownMenuItem(
                          value: 'Critique',
                          child: Text('Critique'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _urgency = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Paiement',
                      value: _payment,
                      items: const [
                        DropdownMenuItem(
                          value: 'Especes',
                          child: Text('Especes'),
                        ),
                        DropdownMenuItem(
                          value: 'Carte',
                          child: Text('Carte'),
                        ),
                        DropdownMenuItem(
                          value: 'Virement',
                          child: Text('Virement'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _payment = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EstimateCard(
                distanceKm: _estimatedDistanceKm,
                etaMinutes: _estimatedEtaMinutes,
                estimatedPrice: _estimatedPrice,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.distanceKm,
    required this.etaMinutes,
    required this.estimatedPrice,
  });

  final double distanceKm;
  final int etaMinutes;
  final double estimatedPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF86EFAC),
        ),
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
          const SizedBox(height: 10),
          const Text(
            'Le prix et le delai sont calcules selon la destination et le service.',
            style: TextStyle(height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _EstimateBox(
                  title: 'Distance',
                  value: '${distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EstimateBox(
                  title: 'ETA',
                  value: '$etaMinutes min',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EstimateBox(
                  title: 'Prix',
                  value: '${estimatedPrice.toStringAsFixed(0)} DA',
                ),
              ),
            ],
          ),
        ],
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