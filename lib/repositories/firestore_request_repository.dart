import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_request.dart';
import '../models/request_status.dart';
import 'request_repository.dart';

class FirestoreRequestRepository implements RequestRepository {
  FirestoreRequestRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  List<AppRequest> _cache = const [];

  @override
  Stream<List<AppRequest>> watchRequests() {
    return _requests
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return _cacheAndSort(snapshot.docs.map(AppRequest.fromDoc));
    });
  }

  @override
  Stream<List<AppRequest>> watchCustomerRequests(String customerUid) {
    return _requests
        .where('customerUid', isEqualTo: customerUid)
        .snapshots()
        .map((snapshot) {
      return _cacheAndSort(snapshot.docs.map(AppRequest.fromDoc));
    });
  }

  @override
  Stream<List<AppRequest>> watchProviderRequests(String providerUid) {
    late final StreamController<List<AppRequest>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? offeredSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? assignedSub;
    var offered = <String, AppRequest>{};
    var assigned = <String, AppRequest>{};

    void emit() {
      final merged = <String, AppRequest>{...offered, ...assigned};
      controller.add(_cacheAndSort(merged.values));
    }

    controller = StreamController<List<AppRequest>>(
      onListen: () {
        offeredSub = _requests
            .where('offeredProviderUid', isEqualTo: providerUid)
            .snapshots()
            .listen(
          (snapshot) {
            offered = {
              for (final doc in snapshot.docs) doc.id: AppRequest.fromDoc(doc),
            };
            emit();
          },
          onError: controller.addError,
        );

        assignedSub = _requests
            .where('providerUid', isEqualTo: providerUid)
            .snapshots()
            .listen(
          (snapshot) {
            assigned = {
              for (final doc in snapshot.docs) doc.id: AppRequest.fromDoc(doc),
            };
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await offeredSub?.cancel();
        await assignedSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  List<AppRequest> currentRequests() => List.unmodifiable(_cache);

  List<AppRequest> _cacheAndSort(Iterable<AppRequest> requests) {
    final items = requests.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = items;
    return items;
  }

  @override
  Future<void> addRequest(AppRequest request) async {
    await _requests.doc(request.id).set({
      ...request.toMap(),
      'createdAtIso': request.createdAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateRequest(String requestId, AppRequest request) async {
    await _requests.doc(requestId).set(
      {
        ...request.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateStatus(String requestId, RequestStatus status) async {
    await _requests.doc(requestId).set({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': DateTime.now().toIso8601String(),
      if (status == RequestStatus.completed)
        'completedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> offerRequestToProvider({
    required String requestId,
    required String providerUid,
    required DateTime offeredAt,
    required DateTime offerExpiresAt,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final ref = _requests.doc(requestId);
        final snap = await tx.get(ref);
        final data = snap.data();
        if (!snap.exists || data == null) return false;

        final status = (data['status'] ?? '').toString();
        final currentProviderUid = (data['providerUid'] ?? '').toString();
        final currentOfferedUid = (data['offeredProviderUid'] ?? '').toString();
        final rejected = List<String>.from(
          (data['rejectedProviderUids'] ?? const <String>[]),
        );

        if (status != RequestStatus.searching.name) return false;
        if (currentProviderUid.isNotEmpty) return false;
        if (currentOfferedUid.isNotEmpty) return false;
        if (rejected.contains(providerUid)) return false;

        tx.set(
            ref,
            {
              'offeredProviderUid': providerUid,
              'offeredAt': offeredAt.toIso8601String(),
              'offerExpiresAt': offerExpiresAt.toIso8601String(),
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedAtIso': DateTime.now().toIso8601String(),
            },
            SetOptions(merge: true));
        return true;
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint('[Dispatch] offer failed permission-denied');
        }
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> rejectOfferedRequest({
    required String requestId,
    required String providerUid,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final ref = _requests.doc(requestId);
        final snap = await tx.get(ref);
        final data = snap.data();
        if (!snap.exists || data == null) return false;

        final status = (data['status'] ?? '').toString();
        final offeredUid = (data['offeredProviderUid'] ?? '').toString();
        final rejected = List<String>.from(
          (data['rejectedProviderUids'] ?? const <String>[]),
        );

        if (status != RequestStatus.searching.name) return false;
        if (offeredUid != providerUid) return false;

        if (!rejected.contains(providerUid)) {
          rejected.add(providerUid);
        }

        tx.set(
            ref,
            {
              'offeredProviderUid': null,
              'offeredAt': null,
              'offerExpiresAt': null,
              'rejectedProviderUids': rejected,
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedAtIso': DateTime.now().toIso8601String(),
            },
            SetOptions(merge: true));
        return true;
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint('[Dispatch] reject failed permission-denied');
        }
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> acceptOfferedRequest({
    required String requestId,
    required String providerUid,
    required String providerName,
    required String providerPhone,
    required String providerVehicle,
    required String providerPlate,
    required LatLng providerPosition,
  }) async {
    return _firestore.runTransaction((tx) async {
      final ref = _requests.doc(requestId);
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return false;

      final status = (data['status'] ?? '').toString();
      final offeredUid = (data['offeredProviderUid'] ?? '').toString();
      final currentProviderUid = (data['providerUid'] ?? '').toString();

      if (status != RequestStatus.searching.name) return false;
      if (offeredUid != providerUid) return false;
      if (currentProviderUid.isNotEmpty) return false;

      tx.set(
          ref,
          {
            'status': RequestStatus.accepted.name,
            'providerUid': providerUid,
            'providerName': providerName,
            'providerPhone': providerPhone,
            'providerVehicle': providerVehicle,
            'providerPlate': providerPlate,
            'providerPosition': {
              'lat': providerPosition.latitude,
              'lng': providerPosition.longitude,
            },
            'offeredProviderUid': null,
            'offeredAt': null,
            'offerExpiresAt': null,
            'acceptedAt': DateTime.now().toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedAtIso': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true));
      return true;
    });
  }
}
