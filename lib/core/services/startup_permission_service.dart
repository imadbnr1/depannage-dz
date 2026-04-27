import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class StartupPermissionSnapshot {
  const StartupPermissionSnapshot({
    required this.locationServiceEnabled,
    required this.locationPermission,
    required this.notificationStatus,
    required this.notificationsSupported,
  });

  final bool locationServiceEnabled;
  final LocationPermission locationPermission;
  final AuthorizationStatus? notificationStatus;
  final bool notificationsSupported;

  bool get locationGranted =>
      locationPermission == LocationPermission.always ||
      locationPermission == LocationPermission.whileInUse;

  bool get notificationsGranted =>
      !notificationsSupported ||
      notificationStatus == AuthorizationStatus.authorized ||
      notificationStatus == AuthorizationStatus.provisional;

  bool get allGranted =>
      locationServiceEnabled && locationGranted && notificationsGranted;
}

class StartupPermissionService {
  const StartupPermissionService();

  Future<StartupPermissionSnapshot> assess() async {
    final locationServiceEnabled = kIsWeb
        ? true
        : await Geolocator.isLocationServiceEnabled().catchError((_) => false);
    final locationPermission =
        await Geolocator.checkPermission().catchError((_) {
      return LocationPermission.denied;
    });

    AuthorizationStatus? notificationStatus;
    var notificationsSupported = true;

    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      notificationStatus = settings.authorizationStatus;
    } catch (_) {
      notificationsSupported = false;
    }

    return StartupPermissionSnapshot(
      locationServiceEnabled: locationServiceEnabled,
      locationPermission: locationPermission,
      notificationStatus: notificationStatus,
      notificationsSupported: notificationsSupported,
    );
  }

  Future<StartupPermissionSnapshot> requestAll() async {
    await requestLocationPermission();
    await requestNotificationPermission();
    return assess();
  }

  Future<LocationPermission> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        try {
          await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<AuthorizationStatus?> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus;
    } catch (_) {
      return null;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
