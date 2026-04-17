import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/alert_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../state/app_store.dart';
import '../../shared/pages/chat_page.dart';
import '../../shared/pages/notifications_page.dart';
import 'provider_dashboard_page.dart';
import 'provider_history_page.dart';
import 'provider_profile_page.dart';
import 'provider_rate_client_page.dart';
import 'provider_requests_page.dart';
import 'provider_support_page.dart';
import 'provider_tracking_page.dart';

class ProviderShellPage extends StatefulWidget {
  const ProviderShellPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<ProviderShellPage> createState() => _ProviderShellPageState();
}

class _ProviderShellPageState extends State<ProviderShellPage> {
  int _index = 0;
  String? _lastRatingHandled;
  final Map<String, String?> _previousOfferedMap = {};
  final Set<String> _shownOfferAlerts = {};
  String? _lastFcmSignature;
  bool _offerDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _index = widget.store.providerTab;
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

    if (widget.store.providerTab != _index) {
      _index = widget.store.providerTab;
    }

    _detectNewOfferedMission();
    _checkRatingRequired();
    setState(() {});
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

      if (type == 'new_order' && requestId.isNotEmpty) {
        final request = widget.store.findRequest(requestId);
        if (request != null) {
          _showMissionOfferDialog(requestId);
        }
      } else if (type == 'chat' && requestId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              requestId: requestId,
              title: 'Chat client',
            ),
          ),
        );
      }

      FcmService.clearPayload();
    });
  }

  void _detectNewOfferedMission() {
    final provider = widget.store.selectedProviderOrNull;
    if (provider == null || !provider.isOnline) return;

    final providerId = provider.id;

    for (final request in widget.store.requests) {
      final previous = _previousOfferedMap[request.id];
      final current = request.offeredProviderUid;

      final newlyOfferedToMe = current == providerId && previous != providerId;

      if (newlyOfferedToMe &&
          request.status.name == 'searching' &&
          !_shownOfferAlerts.contains(request.id)) {
        _shownOfferAlerts.add(request.id);
        _showMissionOfferDialog(request.id);
      }

      _previousOfferedMap[request.id] = current;
    }
  }

  Future<void> _showMissionOfferDialog(String requestId) async {
    if (_offerDialogOpen) return;

    final request = widget.store.findRequest(requestId);
    if (request == null) return;

    _offerDialogOpen = true;
    await AlertService.startProviderAlertLoop();

    if (!mounted) {
      _offerDialogOpen = false;
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MissionOfferDialog(
          requestId: requestId,
          store: widget.store,
          onAccept: () async {
            await AlertService.stopProviderAlertLoop();
            await widget.store.acceptRequest(request.id);

            if (!mounted) return;
            widget.store.setProviderTab(1);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProviderTrackingPage(
                  store: widget.store,
                  requestId: request.id,
                ),
              ),
            );
          },
          onReject: () async {
            await AlertService.stopProviderAlertLoop();
            await widget.store.rejectRequestForCurrentProvider(request.id);
          },
          onLater: () async {
            await AlertService.stopProviderAlertLoop();
            widget.store.setProviderTab(1);
          },
          onTimeout: () async {
            await AlertService.stopProviderAlertLoop();
            widget.store.setProviderTab(1);
          },
        );
      },
    );

    _offerDialogOpen = false;
  }

  void _checkRatingRequired() {
    final providerId = widget.store.selectedProvider.id;
    final pending = widget.store.requests.where((r) {
      return r.providerUid == providerId && r.canProviderRate;
    }).toList();

    if (pending.isEmpty) return;

    final request = pending.first;
    if (_lastRatingHandled == request.id) return;
    _lastRatingHandled = request.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProviderRateClientPage(
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
      ProviderDashboardPage(store: widget.store),
      ProviderRequestsPage(store: widget.store),
      ProviderHistoryPage(store: widget.store),
      const ProviderProfilePage(),
      const ProviderSupportPage(),
    ];

    return Scaffold(
  body: Stack(
    children: [
      // MAIN CONTENT
      IndexedStack(
        index: _index,
        children: pages,
      ),

      // 🔔 FLOATING NOTIFICATION BUTTON
      Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 16,
        child: Material(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          child: IconButton(
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
        ),
      ),
    ],
  ),

  bottomNavigationBar: NavigationBar(
    selectedIndex: _index,
    onDestinationSelected: (value) {
      setState(() => _index = value);
      widget.store.setProviderTab(value);
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Accueil',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Missions',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Historique',
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

class _MissionOfferDialog extends StatefulWidget {
  const _MissionOfferDialog({
    required this.requestId,
    required this.store,
    required this.onAccept,
    required this.onReject,
    required this.onLater,
    required this.onTimeout,
  });

  final String requestId;
  final AppStore store;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;
  final Future<void> Function() onLater;
  final Future<void> Function() onTimeout;

  @override
  State<_MissionOfferDialog> createState() => _MissionOfferDialogState();
}

class _MissionOfferDialogState extends State<_MissionOfferDialog> {
  late int _secondsLeft;
  Timer? _timer;
  bool _actionTaken = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final latest = widget.store.findRequest(widget.requestId);
      final providerId = widget.store.selectedProvider.id;

      if (latest == null ||
          latest.status.name != 'searching' ||
          latest.offeredProviderUid != providerId) {
        timer.cancel();
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        if (!_actionTaken) {
          _actionTaken = true;
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          await widget.onTimeout();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _secondsLeft -= 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_actionTaken) return;
    _actionTaken = true;
    _timer?.cancel();
    Navigator.of(context).pop();
    await widget.onAccept();
  }

  Future<void> _reject() async {
    if (_actionTaken) return;
    _actionTaken = true;
    _timer?.cancel();
    Navigator.of(context).pop();
    await widget.onReject();
  }

  Future<void> _later() async {
    if (_actionTaken) return;
    _actionTaken = true;
    _timer?.cancel();
    Navigator.of(context).pop();
    await widget.onLater();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) {
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Nouvelle mission',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Temps restant: ${_secondsLeft}s',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              request.customerName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            _InfoLine(label: 'Telephone', value: request.customerPhone),
            _InfoLine(
              label: 'Vehicule',
              value: '${request.vehicleType} · ${request.brandModel}',
            ),
            _InfoLine(label: 'Lieu', value: request.pickupLabel),
            _InfoLine(label: 'Repere', value: request.landmark),
            if (request.destination.isNotEmpty)
              _InfoLine(label: 'Destination', value: request.destination),
            if (request.estimatedPrice != null)
              _InfoLine(
                label: 'Prix estime',
                value: '${request.estimatedPrice!.toStringAsFixed(0)} DA',
              ),
            const SizedBox(height: 8),
            Text(
              request.issueDescription,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _accept,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accepter maintenant'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _later,
                  child: const Text('Voir plus tard dans Missions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}