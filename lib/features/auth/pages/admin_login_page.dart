import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import 'login_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      authService: authService,
      adminOnly: true,
    );
  }
}
