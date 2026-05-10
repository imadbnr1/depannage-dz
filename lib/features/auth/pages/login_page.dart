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

  int _tapCount = 0;
  late DateTime _firstTapTime;

  @override
  void initState() {
    super.initState();
    _firstTapTime = DateTime.now();

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

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      AppFeedback.showError(
        context,
        AppLocalizations.of(context).t('checkInfo'),
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
    final strings = AppLocalizations.of(context);
    final normalized = message.toLowerCase();
    final needsDialog = normalized.contains('bloque') ||
        normalized.contains('internet') ||
        normalized.contains('règles de sécurité') ||
        normalized.contains('administrateur');

    if (!needsDialog) {
      AppFeedback.showError(context, message);
      return;
    }

    final title = normalized.contains('bloque')
        ? strings.t('blocked_account_title')
        : normalized.contains('internet')
            ? strings.t('no_internet_title')
            : strings.t('access_denied_title');

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
              child: Text(strings.t('understood')),
            ),
          ],
        );
      },
    );
  }

  void _handleLogoTap() {
    final now = DateTime.now();

    if (_tapCount == 0 || now.difference(_firstTapTime).inSeconds > 10) {
      _tapCount = 1;
      _firstTapTime = now;
      return;
    }

    _tapCount++;

    if (_tapCount >= 7) {
      _tapCount = 0;
      _showAdminLogin();
    }
  }

  void _showAdminLogin() {
    if (widget.adminOnly) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          authService: widget.authService,
          adminOnly: true,
        ),
      ),
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
                      if (!sending) sendReset();
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
      MaterialPageRoute(builder: (_) => LegalPage(document: document)),
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

    final screenSize = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardInset > 0;
    final availableHeight = screenSize.height - keyboardInset;
    final compact = keyboardOpen || availableHeight < 700;

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
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handleLogoTap,
                      child: Column(
                        children: [
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
                        ],
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
                            const SizedBox(height: 12),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5EF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: const LanguageSelector(),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                  return strings.t('enter_password');
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
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed:
                                    _loading ? null : _openPasswordResetDialog,
                                child: Text(
                                  strings.t('forgot_password'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E8),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.3),
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
                                  label: Text(strings.t('create_account')),
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
                                  label: Text(strings.t('back_to_public')),
                                ),
                              ),
                            const SizedBox(height: 14),
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
                                  label: Text(strings.t('privacy_short')),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _openLegal(LegalDocument.terms),
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                  ),
                                  label: Text(strings.t('terms_short')),
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
