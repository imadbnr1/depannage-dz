import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/i18n/app_localizations.dart';
import 'core/services/alert_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'features/auth/pages/auth_gate.dart';
import 'features/shared/pages/onboarding_page.dart';
import 'features/shared/pages/permission_gate_page.dart';
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
  final languageController = await AppLanguageController.load();

  runApp(
    MyApp(
      store: store,
      languageController: languageController,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.store,
    required this.languageController,
  });

  final AppStore store;
  final AppLanguageController languageController;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    const background = Color(0xFFF4EFE6);
    const surface = Color(0xFFFFFCF7);
    const surfaceTint = Color(0xFFFFF4DE);
    const primary = Color(0xFFE89A1E);
    const primaryContainer = Color(0xFFFFDDA7);
    const secondary = Color(0xFF123047);
    const tertiary = Color(0xFF0E8D7B);
    const outline = Color(0xFFE2D6C2);
    const muted = Color(0xFF6B7280);
    const error = Color(0xFFBE3A34);
    const colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Color(0xFF1E1400),
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF3B2500),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDCEBFA),
      onSecondaryContainer: Color(0xFF102433),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD7F4EF),
      onTertiaryContainer: Color(0xFF053B34),
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: Color(0xFF111827),
      surfaceContainerHighest: Color(0xFFF1E7D7),
      onSurfaceVariant: muted,
      outline: outline,
      shadow: Color(0x1A0F172A),
    );

    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Depaniny',
          locale: languageController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return AppLanguageScope(
              controller: languageController,
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: background,
            canvasColor: background,
            splashColor: primary.withValues(alpha: 0.08),
            highlightColor: primary.withValues(alpha: 0.04),
            dividerColor: outline,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            cardTheme: CardThemeData(
              color: surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: EdgeInsets.zero,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              labelStyle: const TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: outline),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: primary, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: error, width: 1.4),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: primary,
                foregroundColor: const Color(0xFF1E1400),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: secondary,
                side: const BorderSide(color: outline),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: surface,
                foregroundColor: secondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: surfaceTint,
              selectedColor: primary,
              disabledColor: outline.withValues(alpha: 0.5),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              labelStyle: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
              secondaryLabelStyle: const TextStyle(
                color: Color(0xFF1E1400),
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: secondary,
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              actionTextColor: primaryContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              surfaceTintColor: Colors.transparent,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: surface,
              modalBackgroundColor: surface,
              surfaceTintColor: Colors.transparent,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              indicatorColor: primaryContainer,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  color:
                      states.contains(WidgetState.selected) ? secondary : muted,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w900
                      : FontWeight.w700,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  color:
                      states.contains(WidgetState.selected) ? secondary : muted,
                );
              }),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: primary,
              linearTrackColor: Color(0xFFEADFCF),
              circularTrackColor: Color(0xFFEADFCF),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return secondary;
                }
                return Colors.white;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary.withValues(alpha: 0.45);
                }
                return outline;
              }),
            ),
            textTheme: const TextTheme(
              displaySmall: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
              headlineMedium: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
              headlineSmall: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              titleLarge: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
              titleMedium: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
              bodyLarge: TextStyle(
                color: Color(0xFF0F172A),
                height: 1.4,
              ),
              bodyMedium: TextStyle(
                color: muted,
                height: 1.45,
              ),
            ),
          ),
          home: _AppEntry(
            authService: authService,
            store: store,
          ),
        );
      },
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
  bool _startupPermissionReady = false;
  bool _preferSignup = false;
  bool _showOnboarding = false;
  bool _showPermissionGate = false;
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
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final hasOpenedBefore = prefs.getBool('has_opened_auth_entry') ?? false;

    if (!hasOpenedBefore) {
      await prefs.setBool('has_opened_auth_entry', true);
    }

    if (!mounted) return;
    setState(() {
      _showOnboarding = !hasSeenOnboarding;
      _preferSignup = !hasOpenedBefore && hasSeenOnboarding;
      _authPreferenceReady = true;
    });
    await _refreshStartupPermissionGate();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    setState(() {
      _showOnboarding = false;
      _preferSignup = false;
    });
    await _refreshStartupPermissionGate(forceGate: true);
  }

  Future<void> _refreshStartupPermissionGate({bool forceGate = false}) async {
    final locationPermission =
        await Geolocator.checkPermission().catchError((_) {
      return LocationPermission.denied;
    });
    final locationGranted = locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse;
    final locationServicesEnabled = kIsWeb
        ? true
        : await Geolocator.isLocationServiceEnabled().catchError((_) => false);

    AuthorizationStatus? notificationStatus;
    var notificationsSupported = true;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      notificationStatus = settings.authorizationStatus;
    } catch (_) {
      notificationsSupported = false;
    }
    final notificationsGranted = !notificationsSupported ||
        notificationStatus == AuthorizationStatus.authorized ||
        notificationStatus == AuthorizationStatus.provisional;

    if (!mounted) return;
    setState(() {
      _showPermissionGate = forceGate ||
          !(locationServicesEnabled && locationGranted && notificationsGranted);
      _startupPermissionReady = true;
    });
  }

  void _completePermissionGate() {
    if (!mounted) return;
    setState(() {
      _showPermissionGate = false;
      _startupPermissionReady = true;
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
      transitionCurve: visual.transitionCurve,
      slideBegin: visual.slideBegin,
      scaleBegin: visual.scaleBegin,
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
    switch (type) {
      case 'admin_discount':
        return const _PopupVisual(
          icon: Icons.local_offer_outlined,
          color: Color(0xFF059669),
          transitionCurve: Curves.easeOutBack,
          slideBegin: Offset(0, 0.08),
          scaleBegin: 0.9,
        );
      case 'admin_offer':
        return const _PopupVisual(
          icon: Icons.bolt_rounded,
          color: Color(0xFFF59E0B),
          transitionCurve: Curves.easeOutBack,
          slideBegin: Offset(0, 0.1),
          scaleBegin: 0.88,
        );
      case 'admin_broadcast':
        return const _PopupVisual(
          icon: Icons.campaign_outlined,
          color: Color(0xFF2563EB),
          transitionCurve: Curves.easeOutCubic,
          slideBegin: Offset(0.04, 0.04),
          scaleBegin: 0.93,
        );
      default:
        return const _PopupVisual(
          icon: Icons.notifications_none_rounded,
          color: Color(0xFF1F2937),
          transitionCurve: Curves.easeOutQuart,
          slideBegin: Offset(0, 0.03),
          scaleBegin: 0.95,
        );
    }
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

    if (_showOnboarding) {
      return OnboardingPage(
        onFinish: _finishOnboarding,
      );
    }

    if (!_startupPermissionReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showPermissionGate) {
      return PermissionGatePage(
        onContinue: _completePermissionGate,
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
    required this.transitionCurve,
    required this.slideBegin,
    required this.scaleBegin,
  });

  final IconData icon;
  final Color color;
  final Curve transitionCurve;
  final Offset slideBegin;
  final double scaleBegin;
}
