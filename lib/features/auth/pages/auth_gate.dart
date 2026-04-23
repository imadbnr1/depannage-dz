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
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Validation provider'),
            content: const Text(
              'Votre compte a ete cree. Vous devez attendre la validation de l administration avant de recevoir des missions.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
            ],
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_top,
                size: 56,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre compte provider est en attente de validation par l admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vous recevrez les missions seulement apres approbation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await widget.authService.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se deconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
