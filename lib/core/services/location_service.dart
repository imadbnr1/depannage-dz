import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AppLocationResult {
  const AppLocationResult({
    required this.position,
    required this.message,
    required this.isRealLocation,
  });

  final LatLng position;
  final String message;
  final bool isRealLocation;
}

class LocationService {
  StreamSubscription<Position>? _positionStream;
  Position? _lastKnownPosition;
  bool _isHighAccuracyMode = false;
  
  /// Get current position with fallback
  Future<AppLocationResult> getCurrentPosition({
    required LatLng fallback,
    required String successMessage,
    required String deniedMessage,
    required String disabledMessage,
    required String errorMessage,
  }) async {
    try {
      final serviceEnabled = kIsWeb
          ? true
          : await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return AppLocationResult(
          position: fallback,
          message: disabledMessage,
          isRealLocation: false,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return AppLocationResult(
          position: fallback,
          message: deniedMessage,
          isRealLocation: false,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return AppLocationResult(
          position: fallback,
          message: 'Permission refusee definitivement',
          isRealLocation: false,
        );
      }

      final gps = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.best,
      );

      final lat = gps.latitude;
      final lng = gps.longitude;

      if (!lat.isFinite || !lng.isFinite || lat.isNaN || lng.isNaN) {
        return AppLocationResult(
          position: fallback,
          message: errorMessage,
          isRealLocation: false,
        );
      }

      return AppLocationResult(
        position: LatLng(lat, lng),
        message: successMessage,
        isRealLocation: true,
      );
    } catch (_) {
      return AppLocationResult(
        position: fallback,
        message: errorMessage,
        isRealLocation: false,
      );
    }
  }
  
  /// Get current position (for real-time tracking)
  Future<LatLng?> getCurrentPositionRaw() async {
    try {
      // Return last known position if available (faster)
      if (_lastKnownPosition != null) {
        return LatLng(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
        );
      }
      
      final serviceEnabled = kIsWeb
          ? true
          : await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      final gps = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.best,
      );
      
      _lastKnownPosition = gps;
      
      return LatLng(gps.latitude, gps.longitude);
    } catch (e) {
      return _lastKnownPosition != null
          ? LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude)
          : null;
    }
  }
  
  /// Request location permission
  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }
  
  /// Start high-accuracy location tracking (for real-time updates)
  Future<void> startHighAccuracyTracking() async {
    if (_isHighAccuracyMode) return;
    
    _isHighAccuracyMode = true;
    
    // Listen to continuous location updates
    _positionStream = Geolocator.getPositionStream(
      // ignore: deprecated_member_use
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters of movement
        timeLimit: null, // No timeout
      ),
    ).listen((Position position) {
      _lastKnownPosition = position;
    });
  }
  
  /// Stop high-accuracy tracking (save battery)
  Future<void> stopHighAccuracyTracking() async {
    if (!_isHighAccuracyMode) return;
    
    _isHighAccuracyMode = false;
    _positionStream?.cancel();
    _positionStream = null;
  }
  
  /// Check if high-accuracy mode is active
  bool get isHighAccuracyMode => _isHighAccuracyMode;
}
