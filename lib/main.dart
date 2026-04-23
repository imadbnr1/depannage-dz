import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/alert_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'features/auth/pages/auth_gate.dart';
import 'features/shared/pages/splash_page.dart';
import 'widgets/live_alert_overlay.dart';
import 'firebase_options.dart';
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
      title: 'Depaniny',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          primary: const Color(0xFFF59E0B),
          secondary: const Color(0xFF1F2937),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F1E7),
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
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: const Color(0xFF1F2937),
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

class _AppEntryState extends State<_AppEntry> with WidgetsBindingObserver {
  bool _splashDone = false;
  bool _authPreferenceReady = false;
  bool _preferSignup = false;
  InAppNotificationItem? _lastPopup;
  bool _isShowingPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    InAppNotificationService.notifier.addListener(_handlePopupNotification);
    _loadFirstRunPreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    InAppNotificationService.notifier.removeListener(_handlePopupNotification);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _replayOpenAppPopups();
    }
  }

  Future<void> _loadFirstRunPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final hasOpenedBefore = prefs.getBool('has_opened_auth_entry') ?? false;

    if (!hasOpenedBefore) {
      await prefs.setBool('has_opened_auth_entry', true);
    }

    if (!mounted) return;
    setState(() {
      _preferSignup = !hasOpenedBefore;
      _authPreferenceReady = true;
    });
  }

  void _handlePopupNotification() {
    final item = InAppNotificationService.notifier.value;
    if (item == null || item == _lastPopup) return;
    _lastPopup = item;

    final role = widget.store.currentUserRoleName;
    final canReceivePopup = role == 'customer' || role == 'provider';
    if (!canReceivePopup || !widget.store.canReceiveAdminNotifications) return;

    if (!_shouldShowFloatingPopup(item.type)) return;
    if (!mounted) return;

    _showPopup(item);
  }

  Future<void> _replayOpenAppPopups() async {
    final role = widget.store.currentUserRoleName;
    if (role != 'customer' && role != 'provider') return;
    if (!widget.store.canReceiveAdminNotifications) return;

    for (final item in widget.store.activeAdminPopupNotifications) {
      if (item.popupMode != 'always_on_open') continue;
      await _showPopup(item);
    }
  }

  Future<void> _showPopup(InAppNotificationItem item) async {
    if (_isShowingPopup || !mounted) return;
    _isShowingPopup = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isShowingPopup = false;
      return;
    }

    if (item.playSound) {
      await AlertService.playAdminPopupAlert();
    }
    if (!mounted) {
      _isShowingPopup = false;
      return;
    }

    final visual = _visualForType(item.type);

    await showLiveAlertOverlay(
      context: context,
      icon: visual.icon,
      title: item.title,
      message: item.body,
      imageUrl: item.imageUrl,
      accentColor: visual.color,
      primaryLabel: 'Fermer',
    );

    _isShowingPopup = false;
  }

  bool _shouldShowFloatingPopup(String type) {
    return type == 'admin_offer' ||
        type == 'admin_discount' ||
        type == 'admin_info' ||
        type == 'admin_broadcast';
  }

  _PopupVisual _visualForType(String type) {
    return const _PopupVisual(
      icon: Icons.notifications_none_rounded,
      color: Color(0xFF1F2937),
    );
  }

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

    if (!_authPreferenceReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AuthGate(
      authService: widget.authService,
      store: widget.store,
      preferSignup: _preferSignup,
    );
  }
}

class _PopupVisual {
  const _PopupVisual({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}
