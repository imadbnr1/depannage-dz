import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_feedback.dart';
import '../../../models/support_config.dart';

class AdminSupportConfigPage extends StatefulWidget {
  const AdminSupportConfigPage({super.key});

  @override
  State<AdminSupportConfigPage> createState() => _AdminSupportConfigPageState();
}

class _AdminSupportConfigPageState extends State<AdminSupportConfigPage> {
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('support')
        .get();

    final config = SupportConfig.fromMap(doc.data());

    _phoneController.text = config.phone;
    _whatsappController.text = config.whatsapp;
    _emailController.text = config.email;
    _addressController.text = config.address;
    _hoursController.text = config.hours;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final config = SupportConfig(
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        hours: _hoursController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('support')
          .set(config.toMap(), SetOptions(merge: true));

      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Support mis a jour');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E40AF),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Control',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Centralisez les canaux de contact visibles par les clients et providers.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _field('Telephone', _phoneController),
              _field('WhatsApp', _whatsappController),
              _field('Email', _emailController),
              _field('Adresse', _addressController, maxLines: 2),
              _field('Horaires', _hoursController),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Sauvegarde...' : 'Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
