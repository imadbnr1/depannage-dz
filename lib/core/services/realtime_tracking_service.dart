import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// Real-time GPS tracking service for providers
/// Updates provider position in Firestore every 3 seconds during active missions
class RealtimeTrackingService {
  RealtimeTrackingService({
    LocationService? locationService,
  }) : _locationService = locationService ?? LocationService();

  final LocationService _locationService;
  
  Timer? _trackingTimer;
  bool _isTracking = false;
  
  /// Start real-time GPS tracking (updates every 3 seconds)
  Future<void> startTracking(String providerId) async {
    if (_isTracking) return;
    
    debugPrint('🛰️ Starting real-time GPS tracking for provider: $providerId');
    _isTracking = true;
    
    // Request location permissions if needed
    await _locationService.requestPermission();
    
    // Start high-accuracy location updates
    await _locationService.startHighAccuracyTracking();
    
    // Update position every 3 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      
      try {
        await _updatePosition(providerId);
      } catch (e) {
        debugPrint('❌ Error updating position: $e');
      }
    });
    
    // Do first update immediately
    await _updatePosition(providerId);
  }
  
  /// Update provider position in Firestore
  Future<void> _updatePosition(String providerId) async {
    try {
      final position = await _locationService.getCurrentPositionRaw();
      if (position == null) {
        debugPrint('⚠️ No GPS position available');
        return;
      }
      
      // Get current speed and heading from last known position
      Position? lastPosition;
      try {
        lastPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {
        // Ignore if no last position available
      }
      
      final speed = lastPosition?.speed ?? 0;
      final heading = lastPosition?.heading ?? 0;
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .set({
        'position': {
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': 10, // Default accuracy in meters
          'heading': heading,
          'speed': speed,
        },
        'positionUpdatedAtIso': DateTime.now().toIso8601String(),
        'isOnline': true,
      }, SetOptions(merge: true));
      
      debugPrint(
        '📍 Position updated: ${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)} '
        '(speed: ${speed.toStringAsFixed(1)} m/s)',
      );
    } catch (e) {
      debugPrint('❌ Failed to update position: $e');
    }
  }
  
  /// Stop real-time tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    debugPrint('⏹️ Stopping real-time GPS tracking');
    _isTracking = false;
    
    _trackingTimer?.cancel();
    _trackingTimer = null;
    
    // Stop high-accuracy mode to save battery
    await _locationService.stopHighAccuracyTracking();
  }
  
  /// Check if tracking is active
  bool get isTracking => _isTracking;
}
