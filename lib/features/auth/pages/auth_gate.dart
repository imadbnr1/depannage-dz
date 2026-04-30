import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/services/auth_service.dart';
import '../../admin/pages/admin_dashboard_page.dart';
import '../../customer/pages/customer_shell_page.dart';
import '../../provider/pages/provider_shell_page.dart';
import '../../../state/app_store.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.store,
    this.preferSignup = false,
  });

  final AuthService authService;
  final AppStore store;
  final bool preferSignup;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final firebaseUser = authService.currentFirebaseUser;
        if (firebaseUser == null) {
          return LoginPage(
            authService: authService,
            launchSignupOnOpen: preferSignup,
          );
        }

        return FutureBuilder<AppUser?>(
          future: authService.getCurrentAppUser(),
          builder: (context, appUserSnapshot) {
            if (appUserSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final appUser = appUserSnapshot.data;
            if (appUser == null) {
              return LoginPage(authService: authService);
            }

            if (appUser.isAdmin) {
              return const AdminDashboardPage();
            }

            if (appUser.isProvider) {
              if (!appUser.isApproved) {
                return _ProviderApprovalPendingScreen(
                  authService: authService,
                );
              }

              return ProviderShellPage(store: store);
            }

            return CustomerShellPage(store: store);
          },
        );
      },
    );
  }
}

class _ProviderApprovalPendingScreen extends StatefulWidget {
  const _ProviderApprovalPendingScreen({
    required this.authService,
  });

  final AuthService authService;

  @override
  State<_ProviderApprovalPendingScreen> createState() =>
      _ProviderApprovalPendingScreenState();
}

class _ProviderApprovalPendingScreenState
    extends State<_ProviderApprovalPendingScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _dialogShown) return;
      _dialogShown = true;
      
      // Show approval pending dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Validation en attente'),
              content: const Text(
                'Votre compte provider a ete cree avec succes. Vous devez attendre la validation de l administration avant de pouvoir acceder a l application.',
              ),
              actions: [
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Auto-logout and redirect to login page
                    await widget.authService.signOut();
                    // Navigate to login page and clear all routes
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Compris'),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation en attente'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_top,
                size: 64,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 20),
              const Text(
                'Votre compte provider est en attente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Validation de l administration requise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2D6C2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous recevrez une notification une fois votre compte approuve par l administration.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await widget.authService.signOut();
                  // Redirect to login
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Retour a la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
