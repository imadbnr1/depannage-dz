import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppFeedback.showError(context, 'Entrez un email valide.');
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
      
      // Wait a bit for storage to complete
      await Future.delayed(Duration(milliseconds: 200));
      
      // Read OTP from SharedPreferences (most reliable)
      generatedOtp = _sharedPreferences?.getString('email_otp_code');
      
      if (!mounted) return;
      
      // Show prominent OTP dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: Color(0xFFF59E0B)),
                SizedBox(width: 12),
                Text('Code OTP envoye'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre code de verification a 6 chiffres:'),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFF59E0B), width: 2),
                  ),
                  child: Text(
                    generatedOtp ?? 'NON DISPONIBLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 8,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Copiez ce code et collez-le dans le champ ci-dessous.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            actions: [
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: Icon(Icons.check_circle),
                label: Text('Compris'),
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
    if (_loading) return;

    // Validate form first
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.showError(context, 'Verifiez vos informations.');
      return;
    }

    // Check password match
    if (_passwordController.text != _confirmPasswordController.text) {
      AppFeedback.showError(context, 'Les mots de passe ne correspondent pas.');
      return;
    }

    // Check OTP code
    if (_emailOtpCode.trim().length != 6) {
      AppFeedback.showError(context, 'Veuillez entrer le code a 6 chiffres.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Sign up with email OTP
      await widget.authService.signUpWithEmailOTP(
        email: _emailController.text.trim(),
        otpCode: _emailOtpCode.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Auto-redirect based on role
      if (_role == 'provider') {
        // Provider needs admin approval - redirect to login
        AppFeedback.showSuccess(
          context,
          'Compte provider cree. Validation admin en attente.',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Customer - auth state change will handle navigation to home
        AppFeedback.showSuccess(context, 'Compte cree avec succes!');
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
                    ? const Color(0xFF1F2937)
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
                      const SizedBox(height: 8),
                      // Premium logo
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white38,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 45,
                              offset: const Offset(0, 22),
                            ),
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.car_repair_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'DEPANINY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Inscription rapide et securisee',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                              const Text(
                                'Creer un compte',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Choisissez votre profil puis remplissez le strict minimum',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _roleTile(
                                value: 'customer',
                                title: 'Client',
                                subtitle:
                                    'Commander un depannage et suivre la mission.',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _roleTile(
                                value: 'provider',
                                title: 'Provider',
                                subtitle:
                                    'Recevoir les missions et intervenir sur le terrain.',
                                icon: Icons.car_repair_outlined,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _fullNameController,
                                enabled: !_otpSent,
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
                                decoration: InputDecoration(
                                  labelText: 'Nom complet',
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
                                  if (text.isEmpty) {
                                    return 'Entrez votre numero';
                                  }
                                  if (text.length < 8) {
                                    return 'Numero invalide';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Numero de telephone',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: _otpSent
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF059669),
                                        )
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
                                  if (text.isEmpty) {
                                    return 'Confirmez le mot de passe';
                                  }
                                  if (text != _passwordController.text) {
                                    return 'Les mots de passe ne correspondent pas';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Confirmer le mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() => _confirmObscure = !_confirmObscure);
                                    },
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
                              // Info box
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
                                            ? 'Les comptes provider restent soumis a la validation admin avant de recevoir des missions.'
                                            : 'Inscription directe: vous pourrez commander votre premiere mission juste apres.',
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
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.email_outlined),
                                    label: const Text('Envoyer le code OTP'),
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
                                    if (text.isEmpty) {
                                      return 'Entrez le code OTP';
                                    }
                                    if (text.length != 6) {
                                      return 'Le code doit avoir 6 chiffres';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Code OTP (6 chiffres)',
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
                                    label: const Text('Verifier et creer le compte'),
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
                                    label: const Text('Changer d email'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loading || _otpSent
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.login),
                                  label: const Text('J ai deja un compte'),
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
