import 'package:flutter/material.dart';

import '../../../core/services/app_feedback.dart';
import '../../../core/services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String _role = 'customer';

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await widget.authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
      );

      if (!mounted) return;

      if (_role == 'provider') {
        AppFeedback.showSuccess(
          context,
          'Compte provider cree. Validation admin en attente.',
        );
      } else {
        AppFeedback.showSuccess(context, 'Compte cree avec succes.');
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _roleTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _role == value;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5DB) : const Color(0xFFF8F5EF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE7DFD1),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  selected ? const Color(0xFFF59E0B) : const Color(0xFFEDE4D3),
              child: Icon(
                icon,
                color: selected
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFFF59E0B) : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF171717),
              Color(0xFF2B2114),
              Color(0xFFF59E0B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.car_repair_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Depaniny',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inscription rapide pour commencer sans friction',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Creer un compte',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Choisissez votre profil puis remplissez le strict minimum',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            _roleTile(
                              value: 'customer',
                              title: 'Client',
                              subtitle:
                                  'Commander un depannage et suivre la mission.',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 10),
                            _roleTile(
                              value: 'provider',
                              title: 'Provider',
                              subtitle:
                                  'Recevoir les missions et intervenir sur le terrain.',
                              icon: Icons.car_repair_outlined,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Entrez votre nom';
                                }
                                if (text.length < 3) {
                                  return 'Nom trop court';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: Icon(Icons.badge_outlined),
                                fillColor: Color(0xFFF8F5EF),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Entrez votre numero';
                                }
                                if (text.length < 8) {
                                  return 'Numero invalide';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Numero de telephone',
                                prefixIcon: Icon(Icons.phone_outlined),
                                fillColor: Color(0xFFF8F5EF),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Entrez votre email';
                                }
                                if (!text.contains('@')) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                fillColor: Color(0xFFF8F5EF),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Entrez un mot de passe';
                                }
                                if (text.length < 6) {
                                  return 'Minimum 6 caracteres';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() => _obscure = !_obscure);
                                  },
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                fillColor: const Color(0xFFF8F5EF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F5EF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                _role == 'provider'
                                    ? 'Les comptes provider restent soumis a la validation admin avant de recevoir des missions.'
                                    : 'Inscription directe: vous pourrez commander votre premiere mission juste apres.',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _signup,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  _loading ? 'Creation...' : 'Creer le compte',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.login),
                                label: const Text('J ai deja un compte'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
