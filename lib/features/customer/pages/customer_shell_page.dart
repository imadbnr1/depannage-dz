import 'package:flutter/material.dart';

import '../../../core/services/fcm_service.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/live_alert_overlay.dart';
import '../../shared/pages/chat_page.dart';
import '../../shared/pages/notifications_page.dart';
import 'customer_home_page.dart';
import 'customer_profile_page.dart';
import 'customer_rate_provider_page.dart';
import 'customer_requests_page.dart';
import 'customer_support_page.dart';
import 'customer_tracking_page.dart';

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
  String? _lastRatingHandled;
  final Map<String, RequestStatus> _previousStatuses = {};
  String? _lastFcmSignature;
  bool _customerDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _index = widget.store.customerTab;
    widget.store.addListener(_onStoreChanged);
    FcmService.payloadNotifier.addListener(_onFcmPayload);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    FcmService.payloadNotifier.removeListener(_onFcmPayload);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;

    if (widget.store.customerTab != _index) {
      _index = widget.store.customerTab;
    }

    _detectCustomerRequestUpdates();
    _checkRatingRequired();
    setState(() {});
  }

  bool _shouldShowCustomerPopup(String status) {
    return status == 'accepted' || status == 'arrived' || status == 'completed';
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
    final status = payload['status'] ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (type == 'request_update' &&
          requestId.isNotEmpty &&
          _shouldShowCustomerPopup(status)) {
        final request = widget.store.findRequest(requestId);
        if (request != null) {
          await _showCustomerStatusDialog(request.id, statusOverride: status);
        }
      } else if (type == 'chat' && requestId.isNotEmpty) {
        await showLiveAlertOverlay(
          context: context,
          icon: Icons.chat_bubble_outline,
          title: 'Nouveau message',
          message: 'Vous avez recu un nouveau message.',
          primaryLabel: 'Ouvrir chat',
          onPrimary: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  requestId: requestId,
                  title: 'Chat provider',
                ),
              ),
            );
          },
          secondaryLabel: 'Fermer',
        );
      }

      FcmService.clearPayload();
    });
  }

  Future<void> _showCustomerStatusDialog(
    String requestId, {
    String? statusOverride,
  }) async {
    if (_customerDialogOpen) return;

    final request = widget.store.findRequest(requestId);
    if (request == null) return;

    final statusName = statusOverride ?? request.status.name;
    if (!_shouldShowCustomerPopup(statusName)) return;

    final title = _dialogTitle(statusName);
    final message = _dialogMessage(request, statusName);

    if (message.isEmpty) return;

    _customerDialogOpen = true;

    await showLiveAlertOverlay(
      context: context,
      icon: _dialogIcon(statusName),
      title: title,
      message: message,
      primaryLabel: _primaryLabel(statusName),
      onPrimary: () {
        if (statusName == 'accepted' || statusName == 'arrived') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerTrackingPage(
                store: widget.store,
                requestId: request.id,
              ),
            ),
          );
        } else {
          widget.store.setCustomerTab(1);
        }
      },
      secondaryLabel: 'Fermer',
    );

    _customerDialogOpen = false;
  }

  String _dialogTitle(String status) {
    switch (status) {
      case 'accepted':
        return 'Mission acceptee';
      case 'arrived':
        return 'Provider arrive';
      case 'completed':
        return 'Mission terminee';
      default:
        return 'Mise a jour mission';
    }
  }

  String _dialogMessage(dynamic request, String status) {
    final provider = request.providerName ?? 'Le provider';

    switch (status) {
      case 'accepted':
        return '$provider a accepte votre mission.\nVous pouvez suivre son trajet maintenant.';
      case 'arrived':
        return '$provider est arrive a votre position.';
      case 'completed':
        return 'Votre mission est terminee.\nMerci de laisser une evaluation.';
      default:
        return '';
    }
  }

  IconData _dialogIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'arrived':
        return Icons.place_outlined;
      case 'completed':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _primaryLabel(String status) {
    switch (status) {
      case 'accepted':
      case 'arrived':
        return 'Ouvrir tracking';
      case 'completed':
        return 'Voir demande';
      default:
        return 'Voir';
    }
  }

  void _detectCustomerRequestUpdates() {
    final currentUid = widget.store.auth.currentUser?.uid;
    if (currentUid == null) return;

    for (final request
        in widget.store.requests.where((r) => r.customerUid == currentUid)) {
      final previous = _previousStatuses[request.id];
      final current = request.status;

      if (previous != null &&
          previous != current &&
          _shouldShowCustomerPopup(current.name)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _showCustomerStatusDialog(request.id);
        });
      }

      _previousStatuses[request.id] = current;
    }
  }

  void _checkRatingRequired() {
    final pending = widget.store.historyCustomerRequests.where((r) {
      return r.canClientRate;
    }).toList();

    if (pending.isEmpty) return;

    final request = pending.first;
    if (_lastRatingHandled == request.id) return;

    _lastRatingHandled = request.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerRateProviderPage(
            store: widget.store,
            requestId: request.id,
            forceMode: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerHomePage(store: widget.store),
      CustomerRequestsPage(store: widget.store),
      const CustomerProfilePage(),
      const CustomerSupportPage(),
    ];

    final titles = const [
      'Accueil',
      'Demandes',
      'Profil',
      'Support',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(store: widget.store),
                ),
              );
            },
            icon: Badge.count(
              count: widget.store.unreadNotifications,
              isLabelVisible: widget.store.unreadNotifications > 0,
              child: const Icon(Icons.notifications_none),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          widget.store.setCustomerTab(value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Demandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}