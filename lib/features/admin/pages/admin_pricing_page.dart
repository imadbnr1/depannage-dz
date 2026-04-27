import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/admin_audit_service.dart';

class AdminPricingPage extends StatefulWidget {
  const AdminPricingPage({super.key});

  @override
  State<AdminPricingPage> createState() => _AdminPricingPageState();
}

class _AdminPricingPageState extends State<AdminPricingPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminAuditService _auditService = AdminAuditService();

  final _basePriceController = TextEditingController();
  final _pricePerKmController = TextEditingController();
  final _urgentFeeController = TextEditingController();
  final _commissionController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _pricePerKmController.dispose();
    _urgentFeeController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    setState(() => _loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('pricing')
        .get();

    final data = doc.data() ?? <String, dynamic>{};

    _basePriceController.text = '${data['basePrice'] ?? 1500}';
    _pricePerKmController.text = '${data['pricePerKm'] ?? 80}';
    _urgentFeeController.text = '${data['urgentFee'] ?? 500}';
    _commissionController.text = '${data['commissionPercent'] ?? 10}';

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await FirebaseFirestore.instance
        .collection('app_config')
        .doc('pricing')
        .set({
      'basePrice': double.parse(_basePriceController.text.trim()),
      'pricePerKm': double.parse(_pricePerKmController.text.trim()),
      'urgentFee': double.parse(_urgentFeeController.text.trim()),
      'commissionPercent': double.parse(_commissionController.text.trim()),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _auditService.logAction(
      action: 'update_pricing',
      targetCollection: 'app_config',
      targetId: 'pricing',
      summary: 'Configuration tarifaire mise a jour',
      metadata: {
        'basePrice': _basePriceController.text.trim(),
        'pricePerKm': _pricePerKmController.text.trim(),
        'urgentFee': _urgentFeeController.text.trim(),
        'commissionPercent': _commissionController.text.trim(),
      },
    );

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarification mise a jour'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1D4ED8),
                Color(0xFF0891B2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pricing Lab',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Modifiez la base, le km, l urgence et la commission avec une lecture plus premium.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _Field(
                  controller: _basePriceController,
                  label: 'Prix de base (DA)',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _pricePerKmController,
                  label: 'Prix par km (DA)',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _urgentFeeController,
                  label: 'Frais urgence (DA)',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _commissionController,
                  label: 'Commission (%)',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _savePricing,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Sauvegarde...' : 'Sauvegarder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Champ obligatoire';
        if (double.tryParse(text) == null) return 'Valeur numerique invalide';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
