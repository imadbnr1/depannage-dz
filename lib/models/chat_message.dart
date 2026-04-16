import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderUid,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String senderUid;
  final String senderRole;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'senderUid': senderUid,
      'senderRole': senderRole,
      'text': text,
      'createdAtIso': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};

    DateTime parsedDate() {
      final raw = map['createdAtIso'];
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ChatMessage(
      id: (map['id'] ?? doc.id).toString(),
      requestId: (map['requestId'] ?? '').toString(),
      senderUid: (map['senderUid'] ?? '').toString(),
      senderRole: (map['senderRole'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      createdAt: parsedDate(),
    );
  }
}