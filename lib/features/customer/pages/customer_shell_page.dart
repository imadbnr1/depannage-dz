import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/fcm_service.dart';
import '../../../state/app_store.dart';
import '../../shared/pages/chat_page.dart';
import 'customer_history_page.dart';
import 'customer_home_page.dart';
import 'customer_profile_page.dart';
import 'customer_requests_page.dart';
import 'customer_support_page.dart';

class CustomerShellPage extends StatefulWidget {
  const CustomerShellPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<CustomerShellPage> createState() => _CustomerShellPageState();
}

class _CustomerShellPageState extends State<CustomerShellPage> {
  int _index = 0;
  String? _lastFcmSignature;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _chatSubscriptions = {};
  final Map<String, String> _lastChatSignatures = {};

  @override
  void initState() {
    super.initState();
    _index = widget.store.customerTab;
    widget.store.addListener(_onStoreChanged);
    FcmService.payloadNotifier.addListener(_onFcmPayload);
    widget.store.setAdminNotificationDeliveryReady(_index == 0);
    _syncChatListeners();
  }

  @override
  void dispose() {
    widget.store.setAdminNotificationDeliveryReady(false);
    widget.store.removeListener(_onStoreChanged);
    FcmService.payloadNotifier.removeListener(_onFcmPayload);
    for (final sub in _chatSubscriptions.values) {
      sub.cancel();
    }
    _chatSubscriptions.clear();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    if (widget.store.customerTab != _index) {
      _index = widget.store.customerTab;
    }
    widget.store.setAdminNotificationDeliveryReady(_index == 0);
    _syncChatListeners();
    setState(() {});
  }

  void _syncChatListeners() {
    final requestIds = widget.store.activeCustomerRequests
        .map((request) => request.id)
        .toSet();

    final staleIds = _chatSubscriptions.keys
        .where((requestId) => !requestIds.contains(requestId))
        .toList();

    for (final requestId in staleIds) {
      _chatSubscriptions.remove(requestId)?.cancel();
      _lastChatSignatures.remove(requestId);
    }

    for (final requestId in requestIds) {
      if (_chatSubscriptions.containsKey(requestId)) continue;

      _chatSubscriptions[requestId] = FirebaseFirestore.instance
          .collection('request_chats')
          .doc(requestId)
          .snapshots()
          .listen((doc) {
        final data = doc.data();
        if (data == null) return;
        _handleChatMetadata(requestId, data);
      });
    }
  }

  void _handleChatMetadata(String requestId, Map<String, dynamic> data) {
    final senderUid = (data['lastMessageSenderUid'] ?? '').toString();
    final createdAtIso = (data['lastMessageCreatedAtIso'] ?? '').toString();
    final messageText = (data['lastMessageText'] ?? '').toString().trim();

    if (senderUid.isEmpty || createdAtIso.isEmpty || messageText.isEmpty) {
      return;
    }

    final signature = '$senderUid|$createdAtIso|$messageText';
    final previous = _lastChatSignatures[requestId];
    _lastChatSignatures[requestId] = signature;

    if (previous == null || previous == signature) {
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (senderUid == currentUid) return;

    final request = widget.store.findRequest(requestId);
    final senderName = request?.providerName?.trim().isNotEmpty == true
        ? request!.providerName!
        : 'Provider';

    widget.store.pushExternalNotification(
      title: 'Nouveau message',
      body: '$senderName: $messageText',
      type: 'chat',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nouveau message de $senderName'),
        action: SnackBarAction(
          label: 'Ouvrir',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  requestId: requestId,
                  title: 'Chat provider',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onFcmPayload() {
    if (!mounted) return;
    final payload = FcmService.payloadNotifier.value;
    if (payload == null) return;

    final signature =
        '${payload['type']}-${payload['requestId']}-${payload['status']}-${payload['senderRole']}';
    if (_lastFcmSignature == signature) return;
    _lastFcmSignature = signature;

    final type = payload['type'] ?? '';
    final requestId = payload['requestId'] ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (type == 'chat' && requestId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              requestId: requestId,
              title: 'Chat provider',
            ),
          ),
        );
      }

      FcmService.clearPayload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerHomePage(store: widget.store),
      CustomerRequestsPage(store: widget.store),
      CustomerHistoryPage(store: widget.store),
      const CustomerProfilePage(),
      const CustomerSupportPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          widget.store.setCustomerTab(value);
          widget.store.setAdminNotificationDeliveryReady(value == 0);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Demandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.headset_mic_outlined),
            selectedIcon: Icon(Icons.headset_mic),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
