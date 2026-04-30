import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/services/app_feedback.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/language_selector.dart';
import '../../shared/pages/legal_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authService,
    this.launchSignupOnOpen = false,
    this.adminOnly = false,
  });

  final AuthService authService;
  final bool launchSignupOnOpen;
  final bool adminOnly;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _didLaunchSignup = false;
  int _adminTapCount = 0;
  DateTime? _lastAdminTapAt;

  // Login mode: 'password' or 'email_otp'
  String _loginMode = 'password';
  bool _otpSent = false;
  String _emailOtpCode = '';

  void _openAdminLogin() {
    if (widget.adminOnly || _loading) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          authService: widget.authService,
          adminOnly: true,
        ),
      ),
    );
  }

  void _handleHiddenAdminTap() {
    if (widget.adminOnly || _loading) return;

    final now = DateTime.now();
    final lastTapAt = _lastAdminTapAt;
    if (lastTapAt == null ||
        now.difference(lastTapAt) > const Duration(seconds: 2)) {
      _adminTapCount = 0;
    }

    _lastAdminTapAt = now;
    _adminTapCount += 1;

    if (_adminTapCount >= 7) {
      _adminTapCount = 0;
      _lastAdminTapAt = null;
      _openAdminLogin();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.adminOnly ||
          !widget.launchSignupOnOpen ||
          _didLaunchSignup) {
        return;
      }
      _didLaunchSignup = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SignupPage(authService: widget.authService),
        ),
      );
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOTP() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final email = _identifierController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppFeedback.showError(context, 'Entrez un email valide.');
      return;
    }

    setState(() => _loading = true);

    try {
      // In production, the OTP would be sent via email
      // For debugging, we get it directly
      final debugOtp = await widget.authService.getDebugEmailOTP(email);
      
      await widget.authService.sendEmailOTP(
        email: email,
        onSent: () {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _otpSent = true;
          });
          AppFeedback.showSuccess(
            context,
            'Code OTP envoye a $email${debugOtp != null ? ' (Code: $debugOtp)' : ''}',
          );
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _loading = false);
          AppFeedback.showError(context, error);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppFeedback.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _verifyEmailAndLogin() async {
    if (_loading) return;

    final email = _identifierController.text.trim();
    final otpCode = _emailOtpCode.trim();
    
    if (otpCode.length != 6) {
      AppFeedback.showError(context, 'Veuillez entrer le code a 6 chiffres.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Show dialog to enter password after OTP verification
      final password = await _showPasswordDialogForEmailOTP();
      if (password == null || password.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Verify OTP and login
      await widget.authService.loginWithEmailOTP(
        email: email,
        otpCode: otpCode,
        password: password,
      );

      if (!mounted) return;
      if (widget.adminOnly && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
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

  Future<String?> _showPasswordDialogForEmailOTP() async {
    final passwordController = TextEditingController();
    String? result;

    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Entrez votre mot de passe pour vous connecter:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) {
                  result = passwordController.text;
                  Navigator.of(dialogContext).pop(result);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                result = passwordController.text;
                Navigator.of(dialogContext).pop(result);
              },
              child: const Text('Se connecter'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();
    return result;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      AppFeedback.showError(
        context,
        'Verifiez vos informations.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await widget.authService.signInWithEmailPassword(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text.trim(),
        allowAdmin: widget.adminOnly,
        adminOnly: widget.adminOnly,
      );
      if (!mounted) return;
      if (widget.adminOnly && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      _showLoginError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showLoginError(String message) {
    final normalized = message.toLowerCase();
    final needsDialog = normalized.contains('bloque') ||
        normalized.contains('internet') ||
        normalized.contains('regles de securite') ||
        normalized.contains('administrateur');

    if (!needsDialog) {
      AppFeedback.showError(context, message);
      return;
    }

    final title = normalized.contains('bloque')
        ? 'Compte bloque'
        : normalized.contains('internet')
            ? 'Connexion indisponible'
            : 'Acces refuse';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            normalized.contains('bloque')
                ? Icons.block_outlined
                : Icons.wifi_off_outlined,
            color: const Color(0xFFDC2626),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPasswordResetDialog() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final strings = AppLocalizations.of(context);
    final initialEmail = _identifierController.text.trim().contains('@')
        ? _identifierController.text.trim()
        : '';
    final controller = TextEditingController(text: initialEmail);
    var sending = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: !sending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendReset() async {
              final email = controller.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setDialogState(() {
                  errorText = strings.t('resetPasswordInvalidEmail');
                });
                return;
              }

              setDialogState(() {
                sending = true;
                errorText = null;
              });

              try {
                await widget.authService.sendPasswordResetEmail(email: email);
                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                AppFeedback.showSuccess(
                  context,
                  strings.t('resetPasswordSent'),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  sending = false;
                  errorText = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: Text(strings.t('resetPasswordTitle')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('resetPasswordBody'),
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !sending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!sending) {
                        sendReset();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: strings.t('resetPasswordEmail'),
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      sending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(strings.t('cancel')),
                ),
                FilledButton.icon(
                  onPressed: sending ? null : sendReset,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: Text(
                    sending
                        ? strings.t('resetPasswordSending')
                        : strings.t('resetPasswordSend'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  void _openLegal(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalPage(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final title = widget.adminOnly
        ? strings.t('adminLoginTitle')
        : strings.t('loginTitle');
    final subtitle = widget.adminOnly
        ? strings.t('adminLoginSubtitle')
        : strings.t('loginSubtitle');
    final helperText =
        widget.adminOnly ? strings.t('adminHelper') : strings.t('publicHelper');

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
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Premium logo with glow effect
                    GestureDetector(
                      onTap: _handleHiddenAdminTap,
                      child: Container(
                        width: 130,
                        height: 130,
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
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 50,
                              offset: const Offset(0, 25),
                            ),
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              blurRadius: 30,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.car_repair_rounded,
                          color: Colors.white,
                          size: 62,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Premium app name
                    GestureDetector(
                      onTap: _handleHiddenAdminTap,
                      child: const Text(
                        'DEPANINY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Depannage routier rapide en Algerie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Language selector
                    const LanguageSelector(),
                    const SizedBox(height: 20),
                    // Premium login card
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
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Login mode toggle (only for non-admin)
                            if (!widget.adminOnly) ...[
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5EF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _loginMode = 'password';
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _loginMode == 'password'
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: _loginMode == 'password'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(alpha: 0.08),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.password_outlined,
                                                    size: 18,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Mot de passe',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _loginMode = 'email_otp';
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _loginMode == 'email_otp'
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: _loginMode == 'email_otp'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(alpha: 0.08),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.email_outlined,
                                                    size: 18,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Email OTP',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Password login form
                            if (_loginMode == 'password') ...[
                              TextFormField(
                                controller: _identifierController,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return strings.t('enterIdentifier');
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('identifierShort'),
                                  hintText: '0550 12 34 56',
                                  prefixIcon: const Icon(Icons.person_outline),
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
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) {
                                    return strings.t('enterPassword');
                                  }
                                  if (text.length < 6) {
                                    return strings.t('minPassword');
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: strings.t('password'),
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
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : _openPasswordResetDialog,
                                  child: const Text(
                                    'Mot de passe oublie ?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (_loginMode == 'email_otp') ...[
                              // Email OTP login form
                              TextFormField(
                                controller: _identifierController,
                                enabled: !_otpSent,
                                textInputAction: TextInputAction.send,
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
                                  hintText: 'exemple@email.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
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
                              if (_otpSent) ...[
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
                                    onPressed: _loading ? null : _verifyEmailAndLogin,
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.login),
                                    label: const Text('Verifier et se connecter'),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                              ] else ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _loading ? null : _sendEmailOTP,
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
                                ),
                              ],
                            ],
                            const SizedBox(height: 18),
                            // Helper box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E8),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFFF59E0B),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      helperText,
                                      style: const TextStyle(
                                        color: Color(0xFF6B4F1D),
                                        height: 1.35,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Login button
                            if (_loginMode == 'password')
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _login,
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.login),
                                  label: Text(
                                    _loading
                                        ? strings.t('signingIn')
                                        : strings.t('signIn'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 14),
                            // Create account button
                            if (!widget.adminOnly)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SignupPage(
                                                authService: widget.authService,
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.person_add_alt_1_outlined,
                                  ),
                                  label: const Text('Creer un compte'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Retour a l entree publique'),
                                ),
                              ),
                            const SizedBox(height: 14),
                            // Legal links
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _openLegal(LegalDocument.privacy),
                                  icon: const Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Confidentialite'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _openLegal(LegalDocument.terms),
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Conditions'),
                                ),
                              ],
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
