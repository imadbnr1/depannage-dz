import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/auth_service.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _plateController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _isApproved = false;
  String _email = '';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final userDoc = await firestore.collection('users').doc(uid).get();
      final providerDoc = await firestore.collection('providers').doc(uid).get();

      final userData = userDoc.data() ?? <String, dynamic>{};
      final providerData = providerDoc.data() ?? <String, dynamic>{};

      _fullNameController.text =
          (providerData['fullName'] ?? userData['fullName'] ?? '').toString();
      _phoneController.text =
          (providerData['phone'] ?? userData['phone'] ?? '').toString();
      _vehicleTypeController.text =
          (providerData['vehicleType'] ?? '').toString();
      _plateController.text = (providerData['plate'] ?? '').toString();
      _email = (providerData['email'] ?? userData['email'] ?? '').toString();
      _isApproved =
          providerData['isApproved'] == true || userData['isApproved'] == true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement profil: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _avatarText(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .toList();

    if (parts.isEmpty) return 'PR';
    return parts.join();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _uid;
    if (uid == null) return;

    setState(() => _saving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final fullName = _fullNameController.text.trim();
      final phone = _phoneController.text.trim();
      final vehicleType = _vehicleTypeController.text.trim();
      final plate = _plateController.text.trim();

      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
      }, SetOptions(merge: true));

      await firestore.collection('providers').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'email': _email,
        'phone': phone,
        'vehicleType': vehicleType,
        'plate': plate,
        'avatarText': _avatarText(fullName),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil provider mis a jour')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sauvegarde: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil provider')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = _fullNameController.text.trim();
    final avatar = _avatarText(fullName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil provider'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      avatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'Provider' : fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email.isEmpty ? 'Email non disponible' : _email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isApproved
                          ? const Color(0x3322C55E)
                          : const Color(0x33F97316),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _isApproved ? 'Approuve' : 'En attente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
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
                      controller: _fullNameController,
                      label: 'Nom complet',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Entrez votre nom complet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _phoneController,
                      label: 'Telephone',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Entrez votre telephone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _vehicleTypeController,
                      label: 'Type de vehicule',
                      hint: 'Ex: Depanneuse, camion leger...',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Entrez le type de vehicule';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _plateController,
                      label: 'Plaque',
                      hint: 'Ex: 12345 116 16',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Entrez la plaque';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving ? 'Sauvegarde...' : 'Sauvegarder',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Infos',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ce profil est maintenant base sur vos vraies donnees Firestore. Les champs saisis ici seront utilises dans les missions, le dashboard et l administration.',
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.35,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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