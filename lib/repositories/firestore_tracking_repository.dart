import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'tracking_repository.dart';

class FirestoreTrackingRepository implements TrackingRepository {
  FirestoreTrackingRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final Map<String, TrackingSnapshot?> _cache = {};
  final Map<String, StreamController<TrackingSnapshot?>> _controllers = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _requestsSub;

  void _ensureListening() {
    _requestsSub ??=
        _firestore.collection('requests').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        final tracking = _fromRequestDoc(doc);
        _cache[doc.id] = tracking;
        if (_controllers.containsKey(doc.id)) {
          _controllers[doc.id]!.add(tracking);
        }
      }
    });
  }

  TrackingSnapshot? _fromRequestDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;

    final customerRaw = data['customerPosition'];
    if (customerRaw is! Map<String, dynamic>) return null;

    final customerLat = customerRaw['lat'];
    final customerLng = customerRaw['lng'];
    if (customerLat is! num || customerLng is! num) return null;

    LatLng? providerPosition;
    final providerRaw = data['providerPosition'];
    if (providerRaw is Map<String, dynamic>) {
      final providerLat = providerRaw['lat'];
      final providerLng = providerRaw['lng'];
      if (providerLat is num && providerLng is num) {
        providerPosition = LatLng(
          providerLat.toDouble(),
          providerLng.toDouble(),
        );
      }
    }

    return TrackingSnapshot(
      requestId: doc.id,
      customerPosition: LatLng(
        customerLat.toDouble(),
        customerLng.toDouble(),
      ),
      providerPosition: providerPosition,
    );
  }

  StreamController<TrackingSnapshot?> _controllerFor(String requestId) {
    return _controllers.putIfAbsent(
      requestId,
      () => StreamController<TrackingSnapshot?>.broadcast(
        onListen: () async {
          _ensureListening();

          if (_cache.containsKey(requestId)) {
            _controllers[requestId]?.add(_cache[requestId]);
            return;
          }

          final doc =
              await _firestore.collection('requests').doc(requestId).get();
          final tracking = _fromRequestDoc(doc);
          _cache[requestId] = tracking;
          _controllers[requestId]?.add(tracking);
        },
      ),
    );
  }

  @override
  Stream<TrackingSnapshot?> watchTracking(String requestId) {
    _ensureListening();
    return _controllerFor(requestId).stream;
  }

  @override
  TrackingSnapshot? currentTracking(String requestId) {
    _ensureListening();
    return _cache[requestId];
  }

  @override
  TrackingSnapshot? getTracking(String requestId) {
    _ensureListening();
    return _cache[requestId];
  }

  @override
  Future<void> setTracking(TrackingSnapshot snapshot) async {
    _ensureListening();

    _cache[snapshot.requestId] = snapshot;
    if (_controllers.containsKey(snapshot.requestId)) {
      _controllers[snapshot.requestId]!.add(snapshot);
    }

    await _firestore.collection('requests').doc(snapshot.requestId).set({
      'customerPosition': {
        'lat': snapshot.customerPosition.latitude,
        'lng': snapshot.customerPosition.longitude,
      },
      'providerPosition': snapshot.providerPosition == null
          ? null
          : {
              'lat': snapshot.providerPosition!.latitude,
              'lng': snapshot.providerPosition!.longitude,
            },
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearTracking(String requestId) async {
    _ensureListening();

    final current = _cache[requestId];
    if (current != null) {
      final cleared = current.copyWith(providerPosition: null);
      _cache[requestId] = cleared;
      if (_controllers.containsKey(requestId)) {
        _controllers[requestId]!.add(cleared);
      }
    } else {
      _cache.remove(requestId);
      if (_controllers.containsKey(requestId)) {
        _controllers[requestId]!.add(null);
      }
    }

    await _firestore.collection('requests').doc(requestId).set({
      'providerPosition': null,
    }, SetOptions(merge: true));
  }

  void dispose() {
    _requestsSub?.cancel();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}