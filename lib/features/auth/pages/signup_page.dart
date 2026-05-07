import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/app_feedback.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/i18n/app_localizations.dart';

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
  SharedPreferences? _sharedPreferences;

  bool _loading = false;
  bool _obscure = true;
  bool _confirmObscure = true;
  String _role = 'customer';

  // OTP verification state - using email OTP now
  bool _otpSent = false;
  String _emailOtpCode = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
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

  Future<void> _initSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
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

  Future<void> _sendOTP() async {
    final strings = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppFeedback.showError(context, strings.t('invalidEmail'));
      return;
    }

    setState(() => _loading = true);

    try {
      String? generatedOtp;

      await widget.authService.sendEmailOTP(
        email: email,
        onSent: () {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _otpSent = true;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _loading = false);
          AppFeedback.showError(context, error);
        },
      );

      await Future.delayed(const Duration(milliseconds: 200));

      generatedOtp = _sharedPreferences?.getString('email_otp_code');

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Text(strings.t('otp_sent')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.t('your_6_digit_code')),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                  ),
                  child: Text(
                    generatedOtp ?? strings.t('not_available'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.t('copy_paste_code'),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            actions: [
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.check_circle),
                label: Text(strings.t('understood')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppFeedback.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _verifyAndSignup() async {
    final strings = AppLocalizations.of(context);
    if (_loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.showError(context, strings.t('checkInfo'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AppFeedback.showError(context, strings.t('passwordMismatch'));
      return;
    }

    if (_emailOtpCode.trim().length != 6) {
      AppFeedback.showError(context, strings.t('enter6DigitCode'));
      return;
    }

    setState(() => _loading = true);

    try {
      await widget.authService.signUpWithEmailOTP(
        email: _emailController.text.trim(),
        otpCode: _emailOtpCode.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (_role == 'provider') {
        AppFeedback.showSuccess(context, strings.t('providerCreated'));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        AppFeedback.showSuccess(context, strings.t('accountCreated'));
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e.toString().replaceFirst('Exception: ', ''));
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
      onTap: _loading || _otpSent ? null : () => setState(() => _role = value),
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
                      color: selected ? const Color(0xFF0F172A) : Colors.black87,
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
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _loading || _otpSent
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // logo
                      Image.asset('assets/logo/applogo.png', width: 500, height: 200, fit: BoxFit.contain),
                      const SizedBox(height: 2),
                      Text(
                        strings.t('app_name'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.t('app_subtitle'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Premium signup card
                      Container(
                        padding: const EdgeInsets.all(26),
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
                              const SizedBox(height: 20),
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
                                enabled: !_otpSent,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return strings.t('enterFullName');
                                  if (text.length < 3) return strings.t('nameTooShort');
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
                                enabled: !_otpSent,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return strings.t('enterPhone');
                                  if (text.length < 8) return strings.t('phoneInvalid');
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('phone'),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: _otpSent
                                      ? const Icon(Icons.check_circle, color: Color(0xFF059669))
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                enabled: !_otpSent,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return strings.t('enterEmail');
                                  if (!text.contains('@')) return strings.t('invalidEmail');
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
                                enabled: !_otpSent,
                                obscureText: _obscure,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return strings.t('enterPassword');
                                  if (text.length < 6) return strings.t('passwordTooShort');
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('password'),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
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
                                enabled: !_otpSent,
                                obscureText: _confirmObscure,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return strings.t('confirmPassword');
                                  if (text != _passwordController.text) {
                                    return strings.t('passwordsMismatch');
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('confirmPassword'),
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _confirmObscure = !_confirmObscure),
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
                                    const Icon(Icons.info_outline,
                                        color: Color(0xFFF59E0B), size: 20),
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
                              if (!_otpSent)
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _loading ? null : _sendOTP,
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.email_outlined),
                                    label: Text(strings.t('sendOTP')),
                                  ),
                                )
                              else ...[
                                TextFormField(
                                  onChanged: (value) => _emailOtpCode = value,
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  validator: (value) {
                                    final text = (value ?? '').trim();
                                    if (text.isEmpty) return strings.t('enterOTPCode');
                                    if (text.length != 6) return strings.t('code_must_be_6_digits');
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: strings.t('enter_otp_code'),
                                    hintText: '123456',
                                    prefixIcon: const Icon(Icons.pin_outlined),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F5EF),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                    counterText: '',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _loading ? null : _verifyAndSignup,
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: Text(strings.t('verifyAndCreate')),
                                  ),
                                ),
                              ],
                              if (_otpSent) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _otpSent = false;
                                        _emailOtpCode = '';
                                      });
                                    },
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: Text(strings.t('change_email')),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              // Already have an account button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.login),
                                  label: Text(strings.t('alreadyAccount')),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
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