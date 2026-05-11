import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuditService {
  AdminAuditService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> logAction({
    required String action,
    required String targetCollection,
    required String targetId,
    required String summary,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    String? actorUid = user?.uid;
    String actorName = 'Admin';
    String actorRole = 'admin';

    if (actorUid != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(actorUid).get();
        final data = userDoc.data();
        if (data != null) {
          actorName = (data['fullName'] ?? 'Admin').toString();
          actorRole = (data['role'] ?? 'admin').toString();
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    final payload = {
      'action': action,
      'targetCollection': targetCollection,
      'targetId': targetId,
      'summary': summary,
      'metadata': metadata ?? <String, dynamic>{},
      'actorUid': actorUid,
      'actorName': actorName,
      'actorRole': actorRole,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': now.toIso8601String(),
    };

    await _firestore.collection('admin_activity_logs').add(payload);
    await _firestore.collection('adminLogs').add({
      'adminUid': actorUid,
      'action': action,
      'targetType': targetCollection,
      'targetId': targetId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': now.toIso8601String(),
      'metadata': metadata ?? <String, dynamic>{},
    });
  }
}
