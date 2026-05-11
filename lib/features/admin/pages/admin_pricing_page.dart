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
  final _commissionController = TextEditingController();
  final _dispatchRadiusController = TextEditingController();
  final _providerTimeoutController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _maintenanceMode = false;
  bool _appEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _pricePerKmController.dispose();
    _commissionController.dispose();
    _dispatchRadiusController.dispose();
    _providerTimeoutController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    setState(() => _loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('pricing')
        .get();
    final settingsDoc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('main')
        .get();

    final data = doc.data() ?? <String, dynamic>{};
    final settings = settingsDoc.data() ?? <String, dynamic>{};

    _basePriceController.text = '${data['basePrice'] ?? 1500}';
    _pricePerKmController.text = '${data['pricePerKm'] ?? 80}';
    _commissionController.text = '${data['commissionPercent'] ?? 10}';
    _dispatchRadiusController.text = '${settings['dispatchRadiusKm'] ?? 15}';
    _providerTimeoutController.text =
        '${settings['providerOfferTimeoutSec'] ?? 20}';
    _maintenanceMode = settings['maintenanceMode'] == true;
    _appEnabled = settings['appEnabled'] != false;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    final pricingData = {
      'basePrice': double.parse(_basePriceController.text.trim()),
      'pricePerKm': double.parse(_pricePerKmController.text.trim()),
      'commissionPercent': double.parse(_commissionController.text.trim()),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    final settingsData = {
      'dispatchRadiusKm': double.parse(_dispatchRadiusController.text.trim()),
      'providerOfferTimeoutSec':
          int.parse(_providerTimeoutController.text.trim()),
      'maintenanceMode': _maintenanceMode,
      'appEnabled': _appEnabled,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('pricing')
          .set(pricingData, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('main')
          .set(settingsData, SetOptions(merge: true));

      try {
        await _auditService.logAction(
          action: 'update_pricing',
          targetCollection: 'app_config',
          targetId: 'pricing',
          summary: 'Configuration tarifaire mise a jour',
          metadata: {
            'basePrice': _basePriceController.text.trim(),
            'pricePerKm': _pricePerKmController.text.trim(),
            'commissionPercent': _commissionController.text.trim(),
            'dispatchRadiusKm': _dispatchRadiusController.text.trim(),
            'providerOfferTimeoutSec': _providerTimeoutController.text.trim(),
            'maintenanceMode': _maintenanceMode,
            'appEnabled': _appEnabled,
          },
        );
      } catch (e) {
        debugPrint('Admin audit log failed after pricing update: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarification mise a jour'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
                'Modifiez la base, le kilometre et la commission avec une lecture plus premium.',
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
                  controller: _commissionController,
                  label: 'Commission (%)',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _dispatchRadiusController,
                  label: 'Rayon dispatch (km)',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _providerTimeoutController,
                  label: 'Timeout offre provider (sec)',
                  integerOnly: true,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _maintenanceMode,
                  onChanged: (value) =>
                      setState(() => _maintenanceMode = value),
                  title: const Text('Mode maintenance'),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _appEnabled,
                  onChanged: (value) => setState(() => _appEnabled = value),
                  title: const Text('Application active'),
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
    this.integerOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final bool integerOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Champ obligatoire';
        if (integerOnly) {
          if (int.tryParse(text) == null) return 'Valeur entiere invalide';
        } else if (double.tryParse(text) == null) {
          return 'Valeur numerique invalide';
        }
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
