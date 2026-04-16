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
    if (!_formKey.currentState!.validate()) return;

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

      AppFeedback.showSuccess(
        context,
        _role == 'provider'
            ? 'Compte provider cree. Validation admin requise.'
            : 'Compte cree avec succes.',
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _roleCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    final selected = _role == value;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() => _role = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: colors.first.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  selected ? Colors.white24 : const Color(0xFFEFF6FF),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected ? Colors.white : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = _role == 'provider'
        ? 'Creer un compte provider'
        : 'Creer un compte customer';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF2563EB),
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Depannage DZ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      roleTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Choisissez votre role',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _roleCard(
                              value: 'customer',
                              title: 'Customer',
                              subtitle:
                                  'Commander une assistance et suivre la mission.',
                              icon: Icons.person_outline,
                              colors: const [
                                Color(0xFF2563EB),
                                Color(0xFF38BDF8),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _roleCard(
                              value: 'provider',
                              title: 'Provider',
                              subtitle:
                                  'Recevoir des missions et intervenir sur le terrain.',
                              icon: Icons.local_shipping_outlined,
                              colors: const [
                                Color(0xFF059669),
                                Color(0xFF34D399),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _fullNameController,
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
                                prefixIcon:
                                    const Icon(Icons.badge_outlined),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
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
                              decoration: InputDecoration(
                                labelText: 'Telephone',
                                prefixIcon:
                                    const Icon(Icons.phone_outlined),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
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
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon:
                                    const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
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
                                prefixIcon:
                                    const Icon(Icons.lock_outline),
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
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
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
                                  _loading
                                      ? 'Creation...'
                                      : 'Creer le compte',
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
                                label: const Text('Retour connexion'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _role == 'provider'
                          ? 'Les comptes provider doivent etre approuves par l administration.'
                          : 'Creer votre compte pour commencer a utiliser la plateforme.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
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