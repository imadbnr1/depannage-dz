import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/services/app_feedback.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/language_selector.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _confirmObscure = true;
  String _role = 'customer';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createAccountDirectly() async {
    final strings = AppLocalizations.of(context);

    FocusScope.of(context).unfocus();

    if (_loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.showError(context, strings.t('checkInfo'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AppFeedback.showError(context, strings.t('passwordMismatch'));
      return;
    }

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
            ? strings.t('providerCreated')
            : strings.t('accountCreated'),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
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

  Widget _roleTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _role == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _loading ? null : () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5DB) : const Color(0xFFF8F5EF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE7DFD1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  selected ? const Color(0xFFF59E0B) : const Color(0xFFEDE4D3),
              radius: 22,
              child: Icon(
                icon,
                color: selected
                    ? const Color(0xFF1F293B)
                    : const Color(0xFF6B7280),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color:
                          selected ? const Color(0xFF0F172A) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected ? Colors.black54 : Colors.black45,
                      height: 1.25,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFFF59E0B) : Colors.black38,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardInset > 0;
    final availableHeight = screenSize.height - keyboardInset;
    final compact = keyboardOpen || availableHeight < 720;

    final logoWidth = compact ? 420.0 : 560.0;

    final scrollPadding = EdgeInsets.fromLTRB(
      compact ? 18 : 20,
      keyboardOpen ? 4 : 6,
      compact ? 18 : 20,
      compact ? 10 : 14,
    );

    final cardPadding = EdgeInsets.all(compact ? 20 : 24);
    final heroCardGap = compact ? 4.0 : 6.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFFF59E0B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: scrollPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: FadeTransition(
                  opacity: _fadeAnimation,
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
                              size: 26,
                            ),
                          ),
                          const Spacer(),
                          LanguageSelector(
                            compact: compact,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.96),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 0 : 1),
                      Image.asset(
                        'assets/logo/applogo.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.t('app_subtitle'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: heroCardGap),
                      Container(
                        padding: cardPadding,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 35,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('signupTitle'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                strings.t('signupSubtitle'),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _roleTile(
                                value: 'customer',
                                title: strings.t('signupCustomer'),
                                subtitle: strings.t('signupCustomerDesc'),
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _roleTile(
                                value: 'provider',
                                title: strings.t('signupProvider'),
                                subtitle: strings.t('signupProviderDesc'),
                                icon: Icons.car_repair_outlined,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _fullNameController,
                                validator: (value) {
                                  final text = (value ?? '').trim();

                                  if (text.isEmpty) {
                                    return strings.t('enterFullName');
                                  }

                                  if (text.length < 3) {
                                    return strings.t('nameTooShort');
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('full_name'),
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\s]'),
                                  ),
                                ],
                                validator: (value) {
                                  final text = (value ?? '').trim();

                                  if (text.isEmpty) {
                                    return strings.t('enterPhone');
                                  }

                                  final digits =
                                      text.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length < 9) {
                                    return strings.t('phoneInvalid');
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('phone'),
                                  hintText: '0696 93 85 26',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final text = (value ?? '').trim();

                                  if (text.isEmpty) {
                                    return strings.t('enterEmail');
                                  }

                                  if (!text.contains('@')) {
                                    return strings.t('invalidEmail');
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('email'),
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                validator: (value) {
                                  final text = (value ?? '').trim();

                                  if (text.isEmpty) {
                                    return strings.t('enterPassword');
                                  }

                                  if (text.length < 6) {
                                    return strings.t('passwordTooShort');
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('password'),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _confirmObscure,
                                validator: (value) {
                                  final text = (value ?? '').trim();

                                  if (text.isEmpty) {
                                    return strings.t('confirmPassword');
                                  }

                                  if (text != _passwordController.text) {
                                    return strings.t('passwordsMismatch');
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('confirmPassword'),
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _confirmObscure = !_confirmObscure,
                                    ),
                                    icon: Icon(
                                      _confirmObscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5EF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2D6C2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFFF59E0B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _role == 'provider'
                                            ? strings.t('providerNote')
                                            : strings.t('customerNote'),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          height: 1.35,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      _loading ? null : _createAccountDirectly,
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_add_alt_1_outlined,
                                        ),
                                  label: Text(strings.t('create_account')),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.login),
                                  label: Text(strings.t('alreadyAccount')),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
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
      ),
    );
  }
}
