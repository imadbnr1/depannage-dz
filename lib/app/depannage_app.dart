import 'package:flutter/material.dart';

import '../features/customer/pages/customer_shell_page.dart';
import '../features/provider/pages/provider_shell_page.dart';
import '../models/app_role.dart';
import '../repositories/firestore_request_repository.dart';
import '../repositories/firestore_tracking_repository.dart';
import '../state/app_store.dart';

class DepannageApp extends StatefulWidget {
  const DepannageApp({super.key});

  @override
  State<DepannageApp> createState() => _DepannageAppState();
}

class _DepannageAppState extends State<DepannageApp> {
  late final AppStore store;

  @override
  void initState() {
    super.initState();
    store = AppStore(
      requestRepository: FirestoreRequestRepository(),
      trackingRepository: FirestoreTrackingRepository(),
    );
    store.bootstrap();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Depaniny',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF59E0B),
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F1E7),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          home: RootPage(store: store),
        );
      },
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return store.role == AppRole.customer
        ? CustomerShellPage(store: store)
        : ProviderShellPage(store: store);
  }
}
