import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_feedback.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/app_loading_view.dart';
import '../../../widgets/language_selector.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _signingOut = false;
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
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? <String, dynamic>{};

      _fullNameController.text = (data['fullName'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();
      _email = (data['email'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erreur chargement profil: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

    if (parts.isEmpty) return 'CU';
    return parts.join();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_saving || _signingOut) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      AppFeedback.showError(context, 'Verifiez les informations du profil.');
      return;
    }

    final uid = _uid;
    if (uid == null) {
      AppFeedback.showError(context, 'Utilisateur non connecte.');
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Profil customer mis a jour');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erreur sauvegarde: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_saving || _signingOut) return;

    setState(() => _signingOut = true);

    try {
      await AuthService().signOut();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erreur deconnexion: $e');
      setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(
        message: 'Chargement du profil...',
      );
    }

    final fullName = _fullNameController.text.trim();

    return SafeArea(
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
                    _avatarText(fullName),
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
                        fullName.isEmpty ? 'Customer' : fullName,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: LanguageSelector(),
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
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Entrez votre nom complet';
                      }
                      if (text.length < 3) {
                        return 'Nom trop court';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Entrez votre telephone';
                      }
                      if (text.length < 8) {
                        return 'Numero invalide';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Telephone',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_saving || _signingOut) ? null : _save,
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_saving || _signingOut) ? null : _logout,
                      icon: _signingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: Text(
                          _signingOut ? 'Deconnexion...' : 'Se deconnecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
