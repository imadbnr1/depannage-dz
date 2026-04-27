import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/alert_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../models/app_request.dart';
import '../../../models/service_type.dart';
import '../../../state/app_store.dart';
import '../../shared/pages/chat_page.dart';
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
  String? _pendingOfferDialogRequestId;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _chatSubscriptions = {};
  final Map<String, String> _lastChatSignatures = {};

  @override
  void initState() {
    super.initState();
    _index = widget.store.providerTab;
    widget.store.addListener(_onStoreChanged);
    FcmService.payloadNotifier.addListener(_onFcmPayload);
    widget.store.setAdminNotificationDeliveryReady(_index == 0);
    _syncChatListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _detectNewOfferedMission();
    });
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

    if (widget.store.providerTab != _index) {
      _index = widget.store.providerTab;
    }

    widget.store.setAdminNotificationDeliveryReady(_index == 0);
    _detectNewOfferedMission();
    _checkRatingRequired();
    _syncChatListeners();
    setState(() {});
  }

  void _syncChatListeners() {
    final requestIds = widget.store.providerAssignedRequests
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
    final senderName = request?.customerName.trim().isNotEmpty == true
        ? request!.customerName
        : 'Client';

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
                  title: 'Chat client',
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
      final stillOfferedToMe =
          current == providerId && request.status.name == 'searching';

      if (!stillOfferedToMe) {
        _shownOfferAlerts.remove(request.id);
      }

      final newlyOfferedToMe = current == providerId && previous != providerId;

      if (newlyOfferedToMe &&
          request.status.name == 'searching' &&
          !_shownOfferAlerts.contains(request.id)) {
        _shownOfferAlerts.add(request.id);
        _scheduleMissionOfferDialog(request.id);
      }

      _previousOfferedMap[request.id] = current;
    }

    for (final request in widget.store.providerAvailableRequests) {
      if (_offerDialogOpen) break;
      if (_shownOfferAlerts.contains(request.id)) continue;
      _shownOfferAlerts.add(request.id);
      _scheduleMissionOfferDialog(request.id);
    }
  }

  void _scheduleMissionOfferDialog(String requestId) {
    if (_offerDialogOpen || _pendingOfferDialogRequestId == requestId) return;

    final latest = widget.store.findRequest(requestId);
    final providerId = widget.store.selectedProviderOrNull?.id;
    if (latest == null ||
        providerId == null ||
        latest.status.name != 'searching' ||
        latest.offeredProviderUid != providerId) {
      return;
    }

    _pendingOfferDialogRequestId = requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _pendingOfferDialogRequestId = null;
        return;
      }

      final pendingId = _pendingOfferDialogRequestId;
      _pendingOfferDialogRequestId = null;
      if (pendingId == null) return;

      unawaited(_showMissionOfferDialog(pendingId));
    });
  }

  Future<void> _showMissionOfferDialog(String requestId) async {
    if (_offerDialogOpen) return;

    final request = widget.store.findRequest(requestId);
    final providerId = widget.store.selectedProviderOrNull?.id;
    if (request == null ||
        providerId == null ||
        request.status.name != 'searching' ||
        request.offeredProviderUid != providerId) {
      return;
    }

    _offerDialogOpen = true;
    try {
      await AlertService.startProviderAlertLoop();

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return _MissionOfferDialog(
            requestId: requestId,
            initialRequest: request,
            store: widget.store,
            onAccept: () async {
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
              await widget.store.rejectRequestForCurrentProvider(request.id);
            },
            onLater: () async {
              widget.store.setProviderTab(1);
            },
            onTimeout: () async {
              await widget.store.rejectRequestForCurrentProvider(request.id);
              widget.store.setProviderTab(1);
            },
          );
        },
      );
    } finally {
      await AlertService.stopProviderAlertLoop();
      _offerDialogOpen = false;
    }
  }

  void _checkRatingRequired() {
    final providerId = widget.store.currentProviderUid;
    if (providerId == null) return;
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
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          widget.store.setProviderTab(value);
          widget.store.setAdminNotificationDeliveryReady(value == 0);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.car_repair_outlined),
            selectedIcon: Icon(Icons.car_repair),
            label: 'Missions',
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

class _MissionOfferDialog extends StatefulWidget {
  const _MissionOfferDialog({
    required this.requestId,
    required this.initialRequest,
    required this.store,
    required this.onAccept,
    required this.onReject,
    required this.onLater,
    required this.onTimeout,
  });

  final String requestId;
  final AppRequest initialRequest;
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
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.store.offerSecondsRemaining(widget.requestId) ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final latest = widget.store.findRequest(widget.requestId);
      final providerId = widget.store.currentProviderUid;

      if (latest == null ||
          providerId == null ||
          latest.status.name != 'searching' ||
          latest.offeredProviderUid != providerId) {
        timer.cancel();
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      final nextSeconds =
          widget.store.offerSecondsRemaining(widget.requestId) ?? 0;

      if (nextSeconds <= 0) {
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
          _secondsLeft = nextSeconds;
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
    final request =
        widget.store.findRequest(widget.requestId) ?? widget.initialRequest;
    final providerPosition = widget.store.selectedProviderOrNull?.position ??
        request.providerPosition;
    final customerPosition = request.customerPosition;
    final distanceKm = providerPosition == null
        ? null
        : const Distance().as(
            LengthUnit.Kilometer,
            providerPosition,
            customerPosition,
          );
    final approachDurationMinutes = request.providerApproachDurationMinutes ??
        (distanceKm == null
            ? null
            : widget.store.estimateApproachDurationMinutes(distanceKm));
    final approachFee = request.providerApproachFee ??
        (distanceKm == null
            ? null
            : widget.store.estimateProviderApproachFee(distanceKm));
    final missionPrice = (request.estimatedPrice ?? 0) +
        ((approachFee ?? 0) > 0 ? approachFee! : 0);
    final countdownProgress = (_secondsLeft / 20).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        offset: _entered ? Offset.zero : const Offset(0, 0.08),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          scale: _entered ? 1 : 0.92,
          child: AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Color(0xFF1D4ED8),
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_secondsLeft),
                      tween: Tween<double>(
                        begin: countdownProgress,
                        end: countdownProgress,
                      ),
                      duration: const Duration(milliseconds: 320),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4338CA),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (distanceKm != null)
                        _OfferBadge(
                          icon: Icons.near_me_outlined,
                          label:
                              'Vers client ${distanceKm.toStringAsFixed(1)} km',
                        ),
                      if (approachDurationMinutes != null)
                        _OfferBadge(
                          icon: Icons.timer_outlined,
                          label: 'Client ~$approachDurationMinutes min',
                        ),
                      if (request.estimatedDurationMinutes != null)
                        _OfferBadge(
                          icon: Icons.route_outlined,
                          label:
                              'Mission ${request.estimatedDurationMinutes} min',
                        ),
                      if (request.estimatedPrice != null)
                        _OfferBadge(
                          icon: Icons.payments_rounded,
                          label: 'Prix ${missionPrice.toStringAsFixed(0)} DA',
                        ),
                      if (approachFee != null && approachFee > 0)
                        _OfferBadge(
                          icon: Icons.add_road_outlined,
                          label: 'Frais ${approachFee.toStringAsFixed(0)} DA',
                        ),
                      _OfferBadge(
                        icon: Icons.handyman_rounded,
                        label: request.service.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoLine(label: 'Pick up', value: request.pickupLabel),
                  _InfoLine(
                    label: 'Vehicule',
                    value:
                        '${request.vehicleType}${request.brandModel.trim().isEmpty ? '' : ' · ${request.brandModel}'}',
                  ),
                  if (request.destination.isNotEmpty)
                    _InfoLine(label: 'Destination', value: request.destination),
                  if (approachDurationMinutes != null)
                    _InfoLine(
                      label: 'Temps vers client',
                      value: '$approachDurationMinutes min',
                    ),
                  if (request.estimatedDurationMinutes != null)
                    _InfoLine(
                      label: 'Temps mission',
                      value: '${request.estimatedDurationMinutes} min',
                    ),
                  if (request.estimatedPrice != null)
                    _InfoLine(
                      label: 'Prix mission',
                      value: '${missionPrice.toStringAsFixed(0)} DA',
                    ),
                  if (approachFee != null && approachFee > 0)
                    _InfoLine(
                      label: 'Frais acces',
                      value: '${approachFee.toStringAsFixed(0)} DA',
                    ),
                ],
              ),
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
                        label: const Text('Accepter'),
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
                      child: const Text('Voir plus tard'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
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
