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
  });

  final AuthService authService;
  final AppStore store;

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
          return LoginPage(authService: authService);
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
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () async {
                              await authService.signOut();
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

              return ProviderShellPage(store: store);
            }

            return CustomerShellPage(store: store);
          },
        );
      },
    );
  }
}