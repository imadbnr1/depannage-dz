import 'package:cloud_firestore/cloud_firestore.dart';

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
      final items = snapshot.docs.map(AppRequest.fromDoc).toList();
      _cache = items;
      return items;
    });
  }

  @override
  List<AppRequest> currentRequests() => List.unmodifiable(_cache);

  @override
  Future<void> addRequest(AppRequest request) async {
    await _requests.doc(request.id).set(request.toMap());
  }

  @override
  Future<void> updateRequest(String requestId, AppRequest request) async {
    await _requests.doc(requestId).set(
          request.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateStatus(String requestId, RequestStatus status) async {
    await _requests.doc(requestId).set({
      'status': status.name,
      if (status == RequestStatus.completed)
        'completedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}