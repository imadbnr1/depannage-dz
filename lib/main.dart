import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'features/auth/pages/auth_gate.dart';
import 'features/shared/pages/onboarding_page.dart';
import 'features/shared/pages/splash_page.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'repositories/firestore_request_repository.dart';
import 'repositories/firestore_tracking_repository.dart';
import 'state/app_store.dart';
import 'core/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   try {
  await FcmService.init();
} catch (e) {
  debugPrint('FCM init skipped: $e');
}
  final store = AppStore(
    requestRepository: FirestoreRequestRepository(),
    trackingRepository: FirestoreTrackingRepository(),
  )..bootstrap();

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Depannage DZ',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: _AppEntry(
        authService: authService,
        store: store,
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({
    required this.authService,
    required this.store,
  });

  final AuthService authService;
  final AppStore store;

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _splashDone = false;
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashPage(
        onDone: () {
          if (!mounted) return;
          setState(() => _splashDone = true);
        },
      );
    }

    if (!_onboardingDone) {
      return OnboardingPage(
        onFinish: () {
          if (!mounted) return;
          setState(() => _onboardingDone = true);
        },
      );
    }

    return AuthGate(
      authService: widget.authService,
      store: widget.store,
    );
  }
}