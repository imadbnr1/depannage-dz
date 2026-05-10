import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class ProviderPresenceService {
  ProviderPresenceService({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance;

  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  Timer? _heartbeatTimer;

  Future<void> goOnline(String providerUid) async {
    final presenceRef = _database.ref('presence/providers/$providerUid');

    await presenceRef.onDisconnect().set({
      'isOnline': false,
      'lastSeenAt': ServerValue.timestamp,
    });

    await presenceRef.set({
      'isOnline': true,
      'lastSeenAt': ServerValue.timestamp,
    });

    await _firestore.collection('providers').doc(providerUid).set({
      'isOnline': true,
      'online': true,
      'lastSeenAtIso': DateTime.now().toIso8601String(),
      'updatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _firestore.collection('providers').doc(providerUid).set({
        'isOnline': true,
        'online': true,
        'lastSeenAtIso': DateTime.now().toIso8601String(),
        'updatedAtIso': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> goOffline(String providerUid) async {
    _heartbeatTimer?.cancel();

    await _database.ref('presence/providers/$providerUid').set({
      'isOnline': false,
      'lastSeenAt': ServerValue.timestamp,
    });

    await _firestore.collection('providers').doc(providerUid).set({
      'isOnline': false,
      'online': false,
      'updatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
