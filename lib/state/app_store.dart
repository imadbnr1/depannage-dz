import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/services/geocoding_service.dart';
import '../core/services/in_app_notification_service.dart';
import '../core/services/location_service.dart';
import '../models/app_request.dart';
import '../models/app_role.dart';
import '../models/provider_agent.dart';
import '../models/request_status.dart';
import '../models/service_type.dart';
import '../repositories/request_repository.dart';
import '../repositories/tracking_repository.dart';
import '../core/services/provider_presence_service.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    required this.requestRepository,
    required this.trackingRepository,
    LocationService? locationService,
    InAppNotificationService? notificationService,
    GeocodingService? geocodingService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : locationService = locationService ?? LocationService(),
        notificationService = notificationService ?? InAppNotificationService(),
        geocodingService = geocodingService ?? GeocodingService(),
        firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  final RequestRepository requestRepository;
  final TrackingRepository trackingRepository;
  final LocationService locationService;
  final InAppNotificationService notificationService;
  final GeocodingService geocodingService;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderPresenceService presenceService = ProviderPresenceService();

  AppRole role = AppRole.customer;
  int customerTab = 0;
  int providerTab = 0;
  int unreadNotifications = 0;
  String? lastCompletedRequestId;

  LatLng? customerCurrentPosition;
  LatLng? providerCurrentPosition;
  bool customerLocationLoading = false;
  bool providerLocationLoading = false;
  String? customerLocationMessage;
  String? providerLocationMessage;

  final List<String> notifications = [];
  final List<String> savedAddresses = [
    'Maison · Park a forage , Batna',
    'Travail · Bouzouran , Batna',
  ];
  final List<String> savedVehicles = [];

  List<ProviderAgent> providers = [];
  String selectedProviderId = '';

  StreamSubscription<List<AppRequest>>? _requestsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _providersSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pricingSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _adminNotificationsSub;

  List<AppRequest> _requests = [];

  double pricingBasePrice = 1500;
  double pricingPerKm = 80;
  double pricingUrgentFee = 500;
  double pricingCommissionPercent = 10;

  String? currentUserRoleName;
  String? _currentUserUid;
  Map<String, dynamic> _currentUserProfile = const {};
  final Set<String> _seenAdminNotificationIds = {};
  Map<String, InAppNotificationItem> _activeAdminPopupItems = {};
  bool _adminNotificationDeliveryReady = false;
  bool _providersLoaded = false;
  DateTime? _providersLoadedAt;

  final Map<String, Timer> _dispatchTimers = {};
  final Map<String, StreamSubscription<Position>> _liveTrackingSubs = {};
  final Set<String> _dispatchFallbackInFlight = {};
  final Set<String> _staleBusyRepairsInFlight = {};

  // ✅ Automatic dispatch chain tracking
  final Map<String, List<String>> _dispatchChains =
      {}; // requestId -> [providerIds in order]
  final Map<String, int> _dispatchChainIndex =
      {}; // requestId -> current index in chain
  final Map<String, String> _currentOfferedProviderIds =
      {}; // requestId -> currently offered providerId
  final Map<String, int> _scannedProviderCounts = {};
  final Map<String, int> _currentDispatchAttempts = {};
  final Map<String, DateTime> _noProviderPopupMutedUntil = {};
  String? noProviderRequestId;
  bool noProviderPopupVisible = false;

  // ✅ Helper methods for dispatch chain access
  List<String>? getDispatchChain(String requestId) =>
      _dispatchChains[requestId];
  int? getDispatchChainIndex(String requestId) =>
      _dispatchChainIndex[requestId];
  int scannedProviderCount(String requestId) =>
      _scannedProviderCounts[requestId] ??
      _dispatchChains[requestId]?.length ??
      0;
  int currentDispatchAttempt(String requestId) =>
      _currentDispatchAttempts[requestId] ?? 0;

  static bool _isValidDispatchPosition(LatLng position) {
    final lat = position.latitude;
    final lng = position.longitude;
    return lat.isFinite &&
        lng.isFinite &&
        !lat.isNaN &&
        !lng.isNaN &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  static const List<String> _activeProviderStatusNames = [
    'accepted',
    'confirmed',
    'enRoute',
    'active',
    'onTheWay',
    'arrived',
    'inProgress',
    'inService',
  ];

  static bool _readDispatchBool(
    Map<String, dynamic> map,
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return fallback;
  }

  void _debugDispatchDiagnostics({
    required String? requestId,
    required int eligibleCount,
    required int rejectedCount,
    required Map<String, int> excluded,
  }) {
    if (!kDebugMode) return;
    final excludedSummary = excluded.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    debugPrint(
      '[Dispatch] request=${requestId ?? 'none'} providersLoaded=$_providersLoaded '
      'totalProviders=${providers.length} eligibleProviders=$eligibleCount '
      'rejectedProviders=$rejectedCount excluded=[$excludedSummary]',
    );
  }

  void _debugDispatch(String message) {
    if (!kDebugMode) return;
    debugPrint('[Dispatch] $message');
  }

  bool _providerHasActiveMission(String providerId) {
    return _requests.any((request) {
      if (request.providerUid != providerId) return false;
      return _activeProviderStatusNames.contains(request.status.name);
    });
  }

  Future<bool> _providerHasActiveMissionInFirestore(String providerId) async {
    try {
      final snap = await firestore
          .collection('requests')
          .where('providerUid', isEqualTo: providerId)
          .where('status', whereIn: _activeProviderStatusNames)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (error) {
      _debugDispatch(
        'active mission verification failed for provider=$providerId; keeping busy protection',
      );
      return true;
    }
  }

  bool _needsProviderStateVerification(ProviderAgent provider) {
    return (provider.isBusy || provider.hasActiveMission) &&
        !_providerHasActiveMission(provider.id);
  }

  Future<bool> _repairStaleBusyIfSafe(ProviderAgent provider) async {
    if (!_needsProviderStateVerification(provider)) return false;
    if (_staleBusyRepairsInFlight.contains(provider.id)) return false;

    _staleBusyRepairsInFlight.add(provider.id);
    try {
      final hasActiveMission =
          await _providerHasActiveMissionInFirestore(provider.id);
      if (hasActiveMission) {
        await firestore.collection('providers').doc(provider.id).set({
          'hasActiveMission': true,
          'isBusy': true,
          'busy': true,
          'updatedAtIso': DateTime.now().toIso8601String(),
          'busyStatusUpdatedAtIso': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        final index = providers.indexWhere((p) => p.id == provider.id);
        if (index != -1) {
          providers[index] = providers[index].copyWith(
            isBusy: true,
            hasActiveMission: true,
          );
        }
        return false;
      }

      await _clearProviderBusyState(provider.id);
      _debugProvider('repaired stale active mission state');
      return true;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _debugDispatch('provider stale-state repair permission-denied');
        final index = providers.indexWhere((p) => p.id == provider.id);
        if (index != -1) {
          providers[index] = providers[index].copyWith(
            isBusy: false,
            hasActiveMission: false,
          );
        }
        return true;
      }
      rethrow;
    } finally {
      _staleBusyRepairsInFlight.remove(provider.id);
    }
  }

  Future<void> _clearProviderBusyState(String providerId) async {
    await firestore.collection('providers').doc(providerId).set({
      'isBusy': false,
      'busy': false,
      'hasActiveMission': false,
      'activeMission': false,
      'onActiveMission': false,
      'activeMissionId': null,
      'activeRequestId': null,
      'currentRequestId': null,
      'assignedRequestId': null,
      'offeredRequestId': null,
      'updatedAtIso': DateTime.now().toIso8601String(),
      'busyStatusUpdatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final index = providers.indexWhere((p) => p.id == providerId);
    if (index != -1) {
      providers[index] = providers[index].copyWith(
        isBusy: false,
        hasActiveMission: false,
      );
    }
  }

  void _debugProvider(String message) {
    if (!kDebugMode) return;
    debugPrint('[Provider] $message');
  }

  Future<void> _repairProviderSessionStateIfSafe(String providerId) async {
    if (providerId.trim().isEmpty) return;
    if (_staleBusyRepairsInFlight.contains(providerId)) return;

    _staleBusyRepairsInFlight.add(providerId);
    try {
      final hasActiveMission =
          await _providerHasActiveMissionInFirestore(providerId);
      if (hasActiveMission) return;
      await _clearProviderBusyState(providerId);
      _debugProvider('repaired stale active mission state');
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _debugProvider('stale active mission repair permission-denied');
        return;
      }
      rethrow;
    } finally {
      _staleBusyRepairsInFlight.remove(providerId);
    }
  }

  void bootstrap() {
    _authSub = auth.authStateChanges().listen((user) async {
      await _adminNotificationsSub?.cancel();
      await _requestsSub?.cancel();
      await _providersSub?.cancel();
      await _pricingSub?.cancel();
      _requests = [];
      providers = [];
      _providersLoaded = false;
      _providersLoadedAt = null;
      currentUserRoleName = null;
      _currentUserUid = null;
      _currentUserProfile = const {};
      _seenAdminNotificationIds.clear();
      _activeAdminPopupItems = {};
      _adminNotificationDeliveryReady = false;
      _clearDispatchState();

      if (user == null) {
        notifyListeners();
        return;
      }

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      _currentUserUid = user.uid;
      _currentUserProfile = data ?? const {};
      currentUserRoleName =
          (data?['role'] ?? 'customer').toString().trim().toLowerCase();

      if (currentUserRoleName == 'provider') {
        selectedProviderId = user.uid;
        unawaited(_repairProviderSessionStateIfSafe(user.uid));
      }

      _startVisibleRequestsListener(user.uid, currentUserRoleName!);
      _startProvidersListener();
      _startPricingListener();
      _startAdminNotificationsListener();
      notifyListeners();
    });
  }

  void _startVisibleRequestsListener(String uid, String role) {
    final stream = switch (role) {
      'admin' => requestRepository.watchRequests(),
      'provider' => requestRepository.watchProviderRequests(uid),
      _ => requestRepository.watchCustomerRequests(uid),
    };

    _requestsSub = stream.listen((items) {
      _requests = items;
      if (currentUserRoleName == 'customer' || currentUserRoleName == 'admin') {
        _refreshSearchingDispatches();
      }
      notifyListeners();
    });
  }

  void _startProvidersListener() {
    _providersSub =
        firestore.collection('providers').snapshots().listen((snap) {
      providers = snap.docs.map((doc) {
        final map = doc.data();

        ({LatLng position, bool isValid}) parsePosition() {
          ({LatLng position, bool isValid}) parseLatLngMap(
            Map<String, dynamic> value,
          ) {
            final lat = value['lat'] ?? value['latitude'];
            final lng = value['lng'] ?? value['lon'] ?? value['longitude'];
            if (lat is num && lng is num) {
              final point = LatLng(lat.toDouble(), lng.toDouble());
              return (
                position: point,
                isValid: _isValidDispatchPosition(point),
              );
            }
            return (position: const LatLng(36.7538, 3.0588), isValid: false);
          }

          final raw = map['position'];
          if (raw is Map<String, dynamic>) {
            final parsed = parseLatLngMap(raw);
            if (parsed.isValid) return parsed;
          }
          if (raw is GeoPoint) {
            final point = LatLng(raw.latitude, raw.longitude);
            return (
              position: point,
              isValid: _isValidDispatchPosition(point),
            );
          }
          final location = map['location'] ?? map['currentLocation'];
          if (location is Map<String, dynamic>) {
            final parsed = parseLatLngMap(location);
            if (parsed.isValid) return parsed;
          }
          if (location is GeoPoint) {
            final point = LatLng(location.latitude, location.longitude);
            return (
              position: point,
              isValid: _isValidDispatchPosition(point),
            );
          }
          final lat = map['latitude'];
          final lng = map['longitude'] ?? map['lng'];
          if (lat is num && lng is num) {
            final point = LatLng(lat.toDouble(), lng.toDouble());
            return (
              position: point,
              isValid: _isValidDispatchPosition(point),
            );
          }
          return (position: const LatLng(36.7538, 3.0588), isValid: false);
        }

        final parsedPosition = parsePosition();
        final rawUid = (map['uid'] ?? '').toString().trim();
        final providerId = rawUid.isEmpty ? doc.id : rawUid;
        final docHasActiveMission = _readDispatchBool(
              map,
              const ['hasActiveMission', 'activeMission', 'onActiveMission'],
            ) ||
            (map['activeMissionId'] ?? '').toString().trim().isNotEmpty ||
            (map['activeRequestId'] ?? '').toString().trim().isNotEmpty ||
            (map['currentRequestId'] ?? '').toString().trim().isNotEmpty ||
            (map['assignedRequestId'] ?? '').toString().trim().isNotEmpty;
        final hasActiveMission =
            docHasActiveMission || _providerHasActiveMission(providerId);

        return ProviderAgent(
          id: providerId,
          name: (map['fullName'] ?? '').toString(),
          phone: (map['phone'] ?? '').toString(),
          position: parsedPosition.position,
          isOnline: _readDispatchBool(map, const ['isOnline', 'online']),
          isBusy: _readDispatchBool(map, const ['isBusy', 'busy']),
          rating: ((map['rating'] ?? 5.0) as num).toDouble(),
          ratingCount: ((map['ratingCount'] ?? 0) as num).toInt(),
          vehicleType: (map['vehicleType'] ?? '').toString(),
          plate: (map['plate'] ?? '').toString(),
          missionsCompleted: ((map['missionsCompleted'] ?? 0) as num).toInt(),
          isVerified: _readDispatchBool(map, const ['isApproved', 'approved']),
          avatarText: (map['avatarText'] ?? 'PR').toString(),
          hasValidLocation: parsedPosition.isValid,
          hasActiveMission: hasActiveMission,
        );
      }).toList();

      _providersLoaded = true;
      _providersLoadedAt = DateTime.now();

      final uid = auth.currentUser?.uid;
      if (uid != null && currentUserRoleName == 'provider') {
        selectedProviderId = uid;
        final currentProvider = findProviderById(uid);
        if (currentProvider != null &&
            _needsProviderStateVerification(currentProvider)) {
          unawaited(_repairProviderSessionStateIfSafe(uid));
        }
      } else if (providers.isNotEmpty && selectedProviderId.isEmpty) {
        selectedProviderId = providers.first.id;
      }

      final current = selectedProviderOrNull;
      if (current != null) {
        providerCurrentPosition = current.position;
        providerLocationMessage = 'Provider: ${current.name}';
      }

      if (currentUserRoleName == 'customer' || currentUserRoleName == 'admin') {
        _refreshSearchingDispatches();
      }
      notifyListeners();
    });
  }

  void _startPricingListener() {
    _pricingSub = firestore
        .collection('app_config')
        .doc('pricing')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data != null) {
        pricingBasePrice = ((data['basePrice'] ?? 1500) as num).toDouble();
        pricingPerKm = ((data['pricePerKm'] ?? 80) as num).toDouble();
        pricingUrgentFee = ((data['urgentFee'] ?? 500) as num).toDouble();
        pricingCommissionPercent =
            ((data['commissionPercent'] ?? 10) as num).toDouble();
        notifyListeners();
      }
    });
  }

  void _startAdminNotificationsListener() {
    _adminNotificationsSub = firestore
        .collection('app_notifications')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final nextActivePopupItems = <String, InAppNotificationItem>{};

      for (final doc in snapshot.docs) {
        final map = doc.data();
        final targetRole = (map['targetRole'] ?? 'all').toString();

        final role = currentUserRoleName;
        final isEndUserRole = role == 'customer' || role == 'provider';
        final allowed = isEndUserRole &&
            (targetRole == 'all' || targetRole == currentUserRoleName);

        if (!allowed) continue;
        if (!_isNotificationInSchedule(map)) continue;

        final title = (map['title'] ?? 'Notification').toString();
        final body = (map['body'] ?? '').toString();
        final type = (map['type'] ?? 'admin_info').toString();
        final imageUrl = (map['imageUrl'] ?? '').toString().trim();
        final popupMode =
            (map['popupMode'] ?? 'once_per_session').toString().trim();
        final playSound = map['playSound'] != false;

        nextActivePopupItems[doc.id] = InAppNotificationItem(
          id: doc.id,
          title: title,
          body: body,
          type: type,
          createdAt: DateTime.now(),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          popupMode: popupMode,
          playSound: playSound,
        );

        if (_adminNotificationDeliveryReady &&
            !_seenAdminNotificationIds.contains(doc.id)) {
          _seenAdminNotificationIds.add(doc.id);
          _pushLifecycleNotification(
            id: doc.id,
            title: title,
            body: body,
            type: type,
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
            popupMode: popupMode,
            playSound: playSound,
          );
        }
      }

      _activeAdminPopupItems = nextActivePopupItems;
    });
  }

  void _clearDispatchState() {
    for (final timer in _dispatchTimers.values) {
      timer.cancel();
    }
    _dispatchTimers.clear();
    _dispatchFallbackInFlight.clear();
    _staleBusyRepairsInFlight.clear();
    _dispatchChains.clear();
    _dispatchChainIndex.clear();
    _currentOfferedProviderIds.clear();
    _scannedProviderCounts.clear();
    _currentDispatchAttempts.clear();
    _noProviderPopupMutedUntil.clear();
    noProviderRequestId = null;
    noProviderPopupVisible = false;
  }

  List<InAppNotificationItem> get activeAdminPopupNotifications =>
      _activeAdminPopupItems.values.toList();
  bool get canReceiveAdminNotifications => _adminNotificationDeliveryReady;
  String? get currentProviderUid {
    final uid = auth.currentUser?.uid;
    if (uid != null && uid.trim().isNotEmpty) {
      return uid;
    }
    if (selectedProviderId.trim().isNotEmpty) {
      return selectedProviderId;
    }
    return null;
  }

  void setAdminNotificationDeliveryReady(bool ready) {
    if (_adminNotificationDeliveryReady == ready) return;
    _adminNotificationDeliveryReady = ready;

    if (ready) {
      for (final item in _activeAdminPopupItems.values) {
        final id = item.id;
        if (id == null || _seenAdminNotificationIds.contains(id)) continue;
        _seenAdminNotificationIds.add(id);
        _pushLifecycleNotification(
          id: item.id,
          title: item.title,
          body: item.body,
          type: item.type,
          imageUrl: item.imageUrl,
          popupMode: item.popupMode,
          playSound: item.playSound,
        );
      }
    } else {
      notifyListeners();
    }
  }

  ProviderAgent? get selectedProviderOrNull {
    final targetId = currentProviderUid;
    if (targetId == null || targetId.isEmpty) return null;
    try {
      return providers.firstWhere((p) => p.id == targetId);
    } catch (_) {
      return null;
    }
  }

  List<AppRequest> get requests => List.unmodifiable(_requests);

  List<AppRequest> get activeCustomerRequests {
    final uid = auth.currentUser?.uid;
    return _requests
        .where((r) => r.customerUid == uid)
        .where((r) =>
            r.status != RequestStatus.completed &&
            r.status != RequestStatus.cancelled)
        .toList();
  }

  List<AppRequest> get historyCustomerRequests {
    final uid = auth.currentUser?.uid;
    return _requests
        .where((r) => r.customerUid == uid)
        .where((r) =>
            r.status == RequestStatus.completed ||
            r.status == RequestStatus.cancelled)
        .toList();
  }

  List<AppRequest> get providerAvailableRequests {
    final providerId = currentProviderUid;
    final provider = selectedProviderOrNull;

    if (providerId == null) return const [];
    if (provider == null) return const [];
    if (!provider.isOnline) return const [];
    if (_providerHasActiveMission(provider.id)) {
      return const [];
    }
    if (provider.isBusy || provider.hasActiveMission) {
      unawaited(_repairStaleBusyIfSafe(provider));
    }

    return _requests.where((r) {
      return r.status == RequestStatus.searching &&
          r.offeredProviderUid == providerId;
    }).toList();
  }

  List<AppRequest> get providerAssignedRequests {
    final providerId = currentProviderUid;
    if (providerId == null) return const [];
    return _requests.where((r) {
      final sameProvider = r.providerUid == providerId;
      return sameProvider &&
          (r.status == RequestStatus.accepted ||
              r.status == RequestStatus.onTheWay ||
              r.status == RequestStatus.arrived ||
              r.status == RequestStatus.inService);
    }).toList();
  }

  AppRequest? findRequest(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  ProviderAgent? findProviderById(String id) {
    try {
      return providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProviderAgent? findProviderByName(String? name) {
    if (name == null) return null;
    try {
      return providers.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  String? currentOfferedProviderId(String requestId) {
    return findRequest(requestId)?.offeredProviderUid;
  }

  String? currentOfferedProviderName(String requestId) {
    final offeredUid = findRequest(requestId)?.offeredProviderUid;
    if (offeredUid == null) return null;
    return findProviderById(offeredUid)?.name;
  }

  // ✅ Get the current provider ID that the mission is being offered to (for animation)
  String? getCurrentOfferedProviderId(String requestId) {
    return _currentOfferedProviderIds[requestId];
  }

  // ✅ Check if a provider is currently being offered a specific request
  bool isProviderBeingOffered(String providerId, String requestId) {
    return _currentOfferedProviderIds[requestId] == providerId;
  }

  int? offerSecondsRemaining(String requestId) {
    final expiresAt = findRequest(requestId)?.offerExpiresAt;
    if (expiresAt == null) return null;
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining <= 0 ? 0 : remaining;
  }

  void dismissNoProviderPopup() {
    noProviderPopupVisible = false;
    noProviderRequestId = null;
    notifyListeners();
  }

  Future<void> cancelNoProviderRequest() async {
    final requestId = noProviderRequestId;
    noProviderPopupVisible = false;
    noProviderRequestId = null;
    if (requestId == null) {
      notifyListeners();
      return;
    }

    await cancelRequest(requestId);
    customerTab = 0;
    notifyListeners();
  }

  Future<void> keepWaitingForProvider(String requestId) async {
    final current = findRequest(requestId);
    if (current == null || current.status != RequestStatus.searching) {
      dismissNoProviderPopup();
      return;
    }

    noProviderPopupVisible = false;
    noProviderRequestId = null;
    _dispatchTimers[requestId]?.cancel();
    _dispatchTimers.remove(requestId);
    _dispatchChains.remove(requestId);
    _dispatchChainIndex.remove(requestId);
    _currentOfferedProviderIds.remove(requestId);
    _currentDispatchAttempts[requestId] = 0;
    _noProviderPopupMutedUntil[requestId] =
        DateTime.now().add(const Duration(seconds: 8));

    await requestRepository.updateRequest(
      requestId,
      current.copyWith(
        offeredProviderUid: null,
        offeredAt: null,
        offerExpiresAt: null,
        rejectedProviderUids: const [],
      ),
    );

    unawaited(
      _attemptFallbackDispatch(
        requestId,
        customerPosition: current.customerPosition,
        delay: const Duration(milliseconds: 500),
        useDispatchChain: false,
      ),
    );

    notifyListeners();
  }

  List<ProviderAgent> eligibleProvidersSortedByDistance(
    LatLng customerPosition, {
    String? requestId,
  }) {
    final current = requestId == null ? null : findRequest(requestId);
    final rejected = current?.rejectedProviderUids ?? const <String>[];
    final excluded = <String, int>{
      'offline': 0,
      'busy': 0,
      'active mission': 0,
      'not approved': 0,
      'missing location': 0,
      'rejected': 0,
      'too far': 0,
    };

    final eligible = providers.where((p) {
      final distanceKm = const Distance().as(
        LengthUnit.Kilometer,
        customerPosition,
        p.position,
      );
      var exclusionReason = 'eligible';
      if (!p.isOnline) {
        excluded['offline'] = excluded['offline']! + 1;
        exclusionReason = 'offline';
      } else if ((p.hasActiveMission || p.isBusy) &&
          _providerHasActiveMission(p.id)) {
        excluded['active mission'] = excluded['active mission']! + 1;
        exclusionReason = 'active mission';
      } else if (_needsProviderStateVerification(p)) {
        unawaited(_repairStaleBusyIfSafe(p));
      } else if (!p.isVerified) {
        excluded['not approved'] = excluded['not approved']! + 1;
        exclusionReason = 'not approved';
      } else if (!p.hasValidLocation || !_isValidDispatchPosition(p.position)) {
        excluded['missing location'] = excluded['missing location']! + 1;
        exclusionReason = 'missing location';
      } else if (rejected.contains(p.id)) {
        excluded['rejected'] = excluded['rejected']! + 1;
        exclusionReason = 'rejected';
      }

      if (kDebugMode) {
        debugPrint(
          '[Dispatch] provider uid=${p.id} totalProviders=${providers.length} '
          'isOnline=${p.isOnline} isApproved=${p.isVerified} '
          'isBusy=${p.isBusy} hasActiveMission=${p.hasActiveMission || _providerHasActiveMission(p.id)} '
          'hasLocation=${p.hasValidLocation && _isValidDispatchPosition(p.position)} '
          'distanceKm=${distanceKm.toStringAsFixed(2)} '
          'exclusionReason=$exclusionReason',
        );
      }
      return exclusionReason == 'eligible';
    }).toList();

    _debugDispatchDiagnostics(
      requestId: requestId,
      eligibleCount: eligible.length,
      rejectedCount: rejected.length,
      excluded: excluded,
    );

    const distance = Distance();

    eligible.sort((a, b) {
      final da = distance.as(
        LengthUnit.Kilometer,
        customerPosition,
        a.position,
      );
      final db = distance.as(
        LengthUnit.Kilometer,
        customerPosition,
        b.position,
      );
      return da.compareTo(db);
    });

    return eligible;
  }

  Future<List<ProviderAgent>> _eligibleProvidersSortedByDistanceForDispatch(
    LatLng customerPosition, {
    String? requestId,
  }) async {
    final repaired = <String>{};
    for (final provider in providers) {
      if (!_needsProviderStateVerification(provider)) continue;
      if (await _repairStaleBusyIfSafe(provider)) {
        repaired.add(provider.id);
      }
    }

    var waitTicks = 0;
    while (_staleBusyRepairsInFlight.isNotEmpty && waitTicks < 10) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      waitTicks++;
    }

    final items = eligibleProvidersSortedByDistance(
      customerPosition,
      requestId: requestId,
    );
    if (repaired.isEmpty) return items;

    _debugDispatch(
      'stale busy repaired before dispatch: providers=${repaired.join(',')}',
    );
    return items;
  }

  final Map<String, int> _arrivalHitCounts = {};

  Future<void> _maybeAutoAdvanceTracking(String requestId) async {
    final request = findRequest(requestId);
    if (request == null) return;

    final providerPos = providerCurrentPosition ?? request.providerPosition;
    if (providerPos == null) return;

    final distanceMeters = const Distance().as(
      LengthUnit.Meter,
      providerPos,
      request.customerPosition,
    );

    if (request.status == RequestStatus.accepted && distanceMeters > 120) {
      await requestRepository.updateRequest(
        requestId,
        request.copyWith(status: RequestStatus.onTheWay),
      );

      _pushLifecycleNotification(
        title: 'Mission en route',
        body: '${request.providerName ?? 'Le provider'} est en route',
        type: 'on_the_way',
      );
      return;
    }

    if (request.status == RequestStatus.onTheWay) {
      if (distanceMeters <= 45) {
        final hits = (_arrivalHitCounts[requestId] ?? 0) + 1;
        _arrivalHitCounts[requestId] = hits;

        if (hits >= 2) {
          _arrivalHitCounts.remove(requestId);

          await requestRepository.updateRequest(
            requestId,
            request.copyWith(status: RequestStatus.arrived),
          );

          _pushLifecycleNotification(
            title: 'Provider arrive',
            body: '${request.providerName ?? 'Le provider'} est arrive',
            type: 'arrived',
          );
        }
      } else {
        _arrivalHitCounts.remove(requestId);
      }
    }
  }

  void _refreshSearchingDispatches() {
    if (!_providersLoaded) {
      _debugDispatch('providersLoaded=false; waiting before dispatch refresh');
      return;
    }

    for (final request in _requests) {
      if (request.status != RequestStatus.searching) continue;
      if (noProviderPopupVisible && noProviderRequestId == request.id) {
        continue;
      }

      final offeredUid = request.offeredProviderUid;
      if (offeredUid == null || offeredUid.isEmpty) {
        _dispatchTimers[request.id]?.cancel();
        _dispatchTimers.remove(request.id);
        unawaited(
          _attemptFallbackDispatch(
            request.id,
            customerPosition: request.customerPosition,
            delay: Duration.zero,
          ),
        );
        continue;
      }

      final offeredProvider = findProviderById(offeredUid);
      final stillEligible = offeredProvider != null &&
          offeredProvider.isOnline &&
          !offeredProvider.isBusy &&
          !offeredProvider.hasActiveMission &&
          !_providerHasActiveMission(offeredProvider.id) &&
          offeredProvider.isVerified &&
          offeredProvider.hasValidLocation;

      if (!stillEligible) {
        _dispatchTimers[request.id]?.cancel();
        _dispatchTimers.remove(request.id);
        unawaited(_recoverStaleOfferAndRedispatch(request.id, offeredUid));
      } else if (request.offerExpiresAt != null) {
        _scheduleOfferTimeout(
          request.id,
          offeredUid,
          request.offerExpiresAt!,
          request.customerPosition,
        );
      }
    }
  }

  Future<void> _attemptFallbackDispatch(
    String requestId, {
    LatLng? customerPosition,
    Duration delay = Duration.zero,
    bool useDispatchChain = true,
  }) async {
    if (_dispatchFallbackInFlight.contains(requestId)) return;
    _dispatchFallbackInFlight.add(requestId);

    try {
      if (!_providersLoaded) {
        _debugDispatch('providersLoaded=false; dispatch deferred');
        return;
      }

      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      if (noProviderPopupVisible && noProviderRequestId == requestId) return;

      final latest = findRequest(requestId);
      final currentStatus = latest?.status ?? RequestStatus.searching;
      final alreadyAssigned = latest != null &&
          (currentStatus != RequestStatus.searching ||
              (latest.providerUid?.trim().isNotEmpty ?? false));

      if (alreadyAssigned) return;

      final targetPosition = latest?.customerPosition ?? customerPosition;
      if (targetPosition == null) return;

      // ✅ Build dispatch chain if not exists or if not using chain
      if (!useDispatchChain || !_dispatchChains.containsKey(requestId)) {
        final allProviders =
            await _eligibleProvidersSortedByDistanceForDispatch(
          targetPosition,
          requestId: requestId,
        );
        _dispatchChains[requestId] = allProviders.map((p) => p.id).toList();
        _dispatchChainIndex[requestId] = 0;
        _scannedProviderCounts[requestId] = allProviders.length;
        _currentDispatchAttempts[requestId] = 0;
        _debugDispatch(
          'chain built: totalProviders=${providers.length} '
          'eligibleProviders=${allProviders.length}',
        );
      }

      // ✅ Find next available provider in chain
      String? nextProviderId;
      final chain = _dispatchChains[requestId] ?? [];
      final startIndex = _dispatchChainIndex[requestId] ?? 0;

      for (int i = startIndex; i < chain.length; i++) {
        final providerId = chain[i];
        final provider = findProviderById(providerId);
        if (provider != null &&
            provider.isOnline &&
            !provider.isBusy &&
            !provider.hasActiveMission &&
            !_providerHasActiveMission(provider.id) &&
            provider.isVerified &&
            provider.hasValidLocation) {
          nextProviderId = providerId;
          _dispatchChainIndex[requestId] = i;
          _currentDispatchAttempts[requestId] = i + 1;
          break;
        }
      }

      _debugDispatch(
        'next provider exists: ${nextProviderId != null ? 'yes' : 'no'}',
      );

      // ✅ No more providers in chain - wait for current offer timeout first
      if (nextProviderId == null) {
        if (_staleBusyRepairsInFlight.isNotEmpty) {
          _debugDispatch(
              'provider state repair in flight; delaying no-provider');
          Timer(const Duration(seconds: 1), () {
            final retryRequest = findRequest(requestId);
            if (retryRequest == null ||
                retryRequest.status != RequestStatus.searching ||
                noProviderPopupVisible) {
              return;
            }
            unawaited(_attemptFallbackDispatch(
              requestId,
              customerPosition: retryRequest.customerPosition,
              delay: Duration.zero,
              useDispatchChain: false,
            ));
          });
          return;
        }

        // Check if there's still an active pending offer before showing no provider message
        final currentRequest = findRequest(requestId);
        if (currentRequest?.offerExpiresAt != null &&
            currentRequest!.offerExpiresAt!.isAfter(DateTime.now())) {
          // There is still an active offer pending, do NOT show no provider message yet
          _dispatchFallbackInFlight.remove(requestId);
          return;
        }

        final mutedUntil = _noProviderPopupMutedUntil[requestId];
        if (mutedUntil != null && mutedUntil.isAfter(DateTime.now())) {
          final retryDelay = mutedUntil.difference(DateTime.now());
          _dispatchChains.remove(requestId);
          _dispatchChainIndex.remove(requestId);
          _currentOfferedProviderIds.remove(requestId);
          Timer(retryDelay, () {
            final retryRequest = findRequest(requestId);
            if (retryRequest == null ||
                retryRequest.status != RequestStatus.searching ||
                noProviderPopupVisible) {
              return;
            }
            unawaited(_attemptFallbackDispatch(
              requestId,
              customerPosition: retryRequest.customerPosition,
              delay: Duration.zero,
              useDispatchChain: false,
            ));
          });
          notifyListeners();
          return;
        }

        final loadedAt = _providersLoadedAt;
        final justLoaded = loadedAt != null &&
            DateTime.now().difference(loadedAt) < const Duration(seconds: 2);
        if (providers.isEmpty && justLoaded) {
          _debugDispatch(
            'provider snapshot just loaded empty; delaying no-provider popup',
          );
          Timer(const Duration(seconds: 2), () {
            final retryRequest = findRequest(requestId);
            if (retryRequest == null ||
                retryRequest.status != RequestStatus.searching ||
                noProviderPopupVisible) {
              return;
            }
            unawaited(_attemptFallbackDispatch(
              requestId,
              customerPosition: retryRequest.customerPosition,
              delay: Duration.zero,
              useDispatchChain: false,
            ));
          });
          return;
        }

        // Only when all offers have expired and really no providers are left:
        _dispatchChains.remove(requestId);
        _dispatchChainIndex.remove(requestId);
        _currentOfferedProviderIds.remove(requestId);
        _currentDispatchAttempts[requestId] =
            _scannedProviderCounts[requestId] ?? chain.length;

        await Future<void>.delayed(const Duration(seconds: 2));

        // Double check one last time if someone accepted in the meantime
        final finalCheckRequest = findRequest(requestId);
        if (finalCheckRequest == null ||
            finalCheckRequest.status != RequestStatus.searching ||
            finalCheckRequest.providerUid?.isNotEmpty == true) {
          return;
        }

        // ✅ NOW notify customer that no providers are available
        noProviderRequestId = requestId;
        noProviderPopupVisible = true;

        _pushLifecycleNotification(
          title: 'Aucun provider disponible',
          body:
              'Aucun provider n a accepte la mission. Vous pouvez annuler ou continuer a attendre.',
          type: 'no_providers_available',
        );
        notifyListeners();
        return;
      }

      // ✅ Store current offered provider for animation tracking
      _currentOfferedProviderIds[requestId] = nextProviderId;

      final now = DateTime.now();
      final offerExpiresAt = now.add(const Duration(seconds: 20));
      final offerSuccess = await requestRepository.offerRequestToProvider(
        requestId: requestId,
        providerUid: nextProviderId,
        offeredAt: now,
        offerExpiresAt: offerExpiresAt,
      );

      if (offerSuccess) {
        _scheduleOfferTimeout(
          requestId,
          nextProviderId,
          offerExpiresAt,
          targetPosition,
        );

        // ✅ Notify customer that mission was sent to a provider
        final provider = findProviderById(nextProviderId);
        if (provider != null) {
          _pushLifecycleNotification(
            title: 'Mission proposee',
            body: 'Mission proposee a ${provider.name}',
            type: 'mission_offered',
          );
        }
      } else {
        final currentIndex = _dispatchChainIndex[requestId] ?? 0;
        _dispatchChainIndex[requestId] = currentIndex + 1;
        _currentOfferedProviderIds.remove(requestId);
        Timer(const Duration(milliseconds: 300), () {
          unawaited(_attemptFallbackDispatch(
            requestId,
            customerPosition: targetPosition,
            delay: Duration.zero,
          ));
        });
      }

      notifyListeners();
    } finally {
      _dispatchFallbackInFlight.remove(requestId);
    }
  }

  void _scheduleOfferTimeout(
    String requestId,
    String providerUid,
    DateTime offerExpiresAt,
    LatLng customerPosition,
  ) {
    _dispatchTimers[requestId]?.cancel();

    final remaining = offerExpiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(
        _expireOfferAndDispatchNext(
          requestId,
          providerUid,
          customerPosition,
        ),
      );
      return;
    }

    _dispatchTimers[requestId] = Timer(
      remaining + const Duration(milliseconds: 250),
      () {
        _dispatchTimers.remove(requestId);
        unawaited(
          _expireOfferAndDispatchNext(
            requestId,
            providerUid,
            customerPosition,
          ),
        );
      },
    );
  }

  Future<void> _expireOfferAndDispatchNext(
    String requestId,
    String providerUid,
    LatLng customerPosition,
  ) async {
    final current = findRequest(requestId);
    if (current == null ||
        current.status != RequestStatus.searching ||
        current.offeredProviderUid != providerUid) {
      return;
    }

    if (_dispatchChains.containsKey(requestId)) {
      final currentIndex = _dispatchChainIndex[requestId] ?? 0;
      _dispatchChainIndex[requestId] = currentIndex + 1;
    }
    _currentOfferedProviderIds.remove(requestId);

    final rejected = await requestRepository.rejectOfferedRequest(
      requestId: requestId,
      providerUid: providerUid,
    );
    if (!rejected) return;

    await _repairProviderSessionStateIfSafe(providerUid);

    await _attemptFallbackDispatch(
      requestId,
      customerPosition: customerPosition,
      delay: Duration.zero,
    );
  }

  Future<void> _recoverStaleOfferAndRedispatch(
    String requestId,
    String providerUid,
  ) async {
    final latest = findRequest(requestId);
    if (latest == null || latest.status != RequestStatus.searching) return;

    // ✅ Advance chain index to skip this provider
    if (_dispatchChains.containsKey(requestId)) {
      final currentIndex = _dispatchChainIndex[requestId] ?? 0;
      _dispatchChainIndex[requestId] = currentIndex + 1;
    }

    await requestRepository.rejectOfferedRequest(
      requestId: requestId,
      providerUid: providerUid,
    );

    // ✅ Immediately try next provider in chain
    await _attemptFallbackDispatch(
      requestId,
      customerPosition: latest.customerPosition,
      delay: const Duration(milliseconds: 300),
    );
  }

  Future<void> updateProviderOnlineStatus(
    String providerId,
    bool isOnline,
  ) async {
    final effectiveProviderId =
        providerId.trim().isNotEmpty && providerId != 'temp'
            ? providerId
            : currentProviderUid;
    if (effectiveProviderId == null || effectiveProviderId.isEmpty) return;

    if (isOnline) {
      await presenceService.goOnline(effectiveProviderId);
      await _repairProviderSessionStateIfSafe(effectiveProviderId);
    } else {
      await presenceService.goOffline(effectiveProviderId);
    }

    final index = providers.indexWhere((p) => p.id == effectiveProviderId);
    if (index != -1) {
      providers[index] = providers[index].copyWith(isOnline: isOnline);
    }
    if (selectedProviderId.isEmpty) {
      selectedProviderId = effectiveProviderId;
    }

    notifyListeners();
  }

  Future<void> updateProviderBusyStatus(
    String providerId,
    bool isBusy, {
    String? activeRequestId,
  }) async {
    await firestore.collection('providers').doc(providerId).set({
      'isBusy': isBusy,
      'busy': isBusy,
      'hasActiveMission': isBusy,
      'activeMission': isBusy,
      'onActiveMission': isBusy,
      'activeMissionId': isBusy ? activeRequestId : null,
      'activeRequestId': isBusy ? activeRequestId : null,
      'currentRequestId': isBusy ? activeRequestId : null,
      'assignedRequestId': isBusy ? activeRequestId : null,
      'offeredRequestId': null,
      'updatedAtIso': DateTime.now().toIso8601String(),
      'busyStatusUpdatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final index = providers.indexWhere((p) => p.id == providerId);
    if (index != -1) {
      providers[index] = providers[index].copyWith(
        isBusy: isBusy,
        hasActiveMission: isBusy,
      );
    }
  }

  Future<void> updateProviderPosition(
    String providerId,
    LatLng position,
  ) async {
    await firestore.collection('providers').doc(providerId).set({
      'position': {
        'lat': position.latitude,
        'lng': position.longitude,
      },
      'updatedAtIso': DateTime.now().toIso8601String(),
      'positionUpdatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (selectedProviderId == providerId) {
      providerCurrentPosition = position;
      notifyListeners();
    }
  }

  Future<void> startLiveTracking(String requestId) async {
    final request = findRequest(requestId);
    if (request == null) return;

    final stillActive = request.status == RequestStatus.accepted ||
        request.status == RequestStatus.onTheWay ||
        request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService;

    if (!stillActive) return;

    if (_liveTrackingSubs.containsKey(requestId)) {
      return;
    }

    final serviceEnabled = kIsWeb
        ? true
        : await Geolocator.isLocationServiceEnabled().catchError((_) => false);
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Location permission not granted');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    final sub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        try {
          final latest = findRequest(requestId);
          if (latest == null) {
            stopLiveTracking(requestId);
            return;
          }

          final stillActiveNow = latest.status == RequestStatus.accepted ||
              latest.status == RequestStatus.onTheWay ||
              latest.status == RequestStatus.arrived ||
              latest.status == RequestStatus.inService;

          if (!stillActiveNow) {
            stopLiveTracking(requestId);
            return;
          }

          final providerLatLng = LatLng(position.latitude, position.longitude);

          final nextStatus = latest.status == RequestStatus.accepted
              ? RequestStatus.onTheWay
              : latest.status;

          final updatedRequest = latest.copyWith(
            status: nextStatus,
            providerPosition: providerLatLng,
          );

          await requestRepository.updateRequest(requestId, updatedRequest);

          await trackingRepository.setTracking(
            TrackingSnapshot(
              requestId: requestId,
              customerPosition: updatedRequest.customerPosition,
              providerPosition: providerLatLng,
            ),
          );

          await _maybeAutoAdvanceTracking(requestId);

          if ((updatedRequest.providerUid ?? '').isNotEmpty) {
            await updateProviderPosition(
              updatedRequest.providerUid!,
              providerLatLng,
            );
          }

          final distanceMeters = Geolocator.distanceBetween(
            providerLatLng.latitude,
            providerLatLng.longitude,
            updatedRequest.customerPosition.latitude,
            updatedRequest.customerPosition.longitude,
          );

          if (distanceMeters <= 50 &&
              updatedRequest.status == RequestStatus.onTheWay) {
            var arrivedRequest = updatedRequest.copyWith(
              status: RequestStatus.arrived,
            );

            // Auto-geocode destination if not set
            if (arrivedRequest.destinationPosition == null &&
                arrivedRequest.destination.trim().isNotEmpty) {
              try {
                final places = await geocodingService
                    .searchPlaces(arrivedRequest.destination);
                if (places.isNotEmpty) {
                  arrivedRequest = arrivedRequest.copyWith(
                    destinationPosition: places.first.position,
                  );
                }
              } catch (e) {
                debugPrint('Failed to geocode destination: $e');
              }
            }

            await requestRepository.updateRequest(requestId, arrivedRequest);

            await trackingRepository.setTracking(
              TrackingSnapshot(
                requestId: requestId,
                customerPosition: arrivedRequest.customerPosition,
                providerPosition: providerLatLng,
              ),
            );
          }

          notifyListeners();
        } catch (e) {
          debugPrint('Live tracking error for $requestId: $e');
        }
      },
      onError: (error) {
        debugPrint('Position stream error for $requestId: $error');
      },
    );

    _liveTrackingSubs[requestId] = sub;
  }

  Future<void> stopLiveTracking(String requestId) async {
    await _liveTrackingSubs[requestId]?.cancel();
    _liveTrackingSubs.remove(requestId);
  }

  ProviderAgent? findNearestAvailableProvider(
    LatLng customerPosition, {
    String? requestId,
  }) {
    final current = requestId == null ? null : findRequest(requestId);
    final rejected = current?.rejectedProviderUids ?? const <String>[];

    final available = providers.where((p) {
      return p.isOnline &&
          !_providerHasActiveMission(p.id) &&
          (!p.hasActiveMission || _needsProviderStateVerification(p)) &&
          (!p.isBusy || _needsProviderStateVerification(p)) &&
          p.isVerified &&
          p.hasValidLocation &&
          !rejected.contains(p.id);
    }).toList();

    if (available.isEmpty) return null;

    const distance = Distance();

    available.sort((a, b) {
      final da = distance.as(
        LengthUnit.Kilometer,
        a.position,
        customerPosition,
      );
      final db = distance.as(
        LengthUnit.Kilometer,
        b.position,
        customerPosition,
      );
      return da.compareTo(db);
    });

    return available.first;
  }

  TrackingSnapshot? trackingFor(String requestId) {
    return trackingRepository.currentTracking(requestId);
  }

  Stream<TrackingSnapshot?> watchTracking(String requestId) {
    return trackingRepository.watchTracking(requestId);
  }

  Future<void> devSetProviderTrackingPosition(
    String requestId,
    LatLng providerPosition,
  ) async {
    final request = findRequest(requestId);
    if (request == null) return;

    await trackingRepository.setTracking(
      TrackingSnapshot(
        requestId: requestId,
        customerPosition: request.customerPosition,
        providerPosition: providerPosition,
      ),
    );

    await requestRepository.updateRequest(
      requestId,
      request.copyWith(providerPosition: providerPosition),
    );

    final providerUid = request.providerUid;
    if (providerUid != null && providerUid.trim().isNotEmpty) {
      await updateProviderPosition(providerUid, providerPosition);
    } else {
      providerCurrentPosition = providerPosition;
      notifyListeners();
    }
  }

  Future<void> requestCustomerLocation() async {
    customerLocationLoading = true;
    notifyListeners();

    final result = await locationService.getCurrentPosition(
      fallback: const LatLng(36.7538, 3.0588),
      successMessage: 'Position GPS active',
      deniedMessage: 'Permission de localisation refusee',
      disabledMessage: 'Service de localisation desactive',
      errorMessage: 'GPS indisponible, position demo utilisee',
    );

    customerCurrentPosition = result.position;
    customerLocationMessage = result.message;
    customerLocationLoading = false;
    notifyListeners();
  }

  Future<void> requestProviderLocation() async {
    providerLocationLoading = true;
    notifyListeners();

    final fallback =
        selectedProviderOrNull?.position ?? const LatLng(36.7538, 3.0588);

    final result = await locationService.getCurrentPosition(
      fallback: fallback,
      successMessage: 'Position GPS provider active',
      deniedMessage: 'Permission provider refusee',
      disabledMessage: 'Service provider desactive',
      errorMessage: 'GPS provider indisponible, position demo utilisee',
    );

    providerCurrentPosition = result.position;
    providerLocationMessage = result.message;
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      await updateProviderPosition(uid, result.position);
    }
    providerLocationLoading = false;
    notifyListeners();
  }

  void setRole(AppRole newRole) {
    role = newRole;
    notifyListeners();
  }

  void setCustomerTab(int index) {
    customerTab = index;
    notifyListeners();
  }

  void setProviderTab(int index) {
    providerTab = index;
    notifyListeners();
  }

  void markNotificationsRead() {
    unreadNotifications = 0;
    notifyListeners();
  }

  void _pushLifecycleNotification({
    String? id,
    required String title,
    required String body,
    required String type,
    String? imageUrl,
    String? popupMode,
    bool playSound = false,
  }) {
    notifications.insert(0, '$title - $body');
    unreadNotifications += 1;
    notificationService.push(
      id: id,
      title: title,
      body: body,
      type: type,
      imageUrl: imageUrl,
      popupMode: popupMode,
      playSound: playSound,
    );
    notifyListeners();
  }

  void pushExternalNotification({
    required String title,
    required String body,
    required String type,
  }) {
    notifications.insert(0, '$title - $body');
    unreadNotifications += 1;
    notificationService.push(title: title, body: body, type: type);
    notifyListeners();
  }

  bool _isNotificationInSchedule(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final now = DateTime.now();
    final startsAt = parseDate(map['startsAtIso']);
    final endsAt = parseDate(map['endsAtIso']);

    if (startsAt != null && now.isBefore(startsAt)) return false;
    if (endsAt != null && now.isAfter(endsAt)) return false;
    return true;
  }

  double estimateDistanceKm({
    required LatLng from,
    required LatLng to,
  }) {
    final km = const Distance().as(
      LengthUnit.Kilometer,
      from,
      to,
    );
    if (!km.isFinite || km.isNaN) return 0;
    return double.parse(km.toStringAsFixed(1));
  }

  int estimateDurationMinutes({
    required double distanceKm,
    required ServiceType service,
  }) {
    final label = service.toString().toLowerCase();
    double speedKmH;

    if (label.contains('remorquage')) {
      speedKmH = 28.0;
    } else if (label.contains('batterie')) {
      speedKmH = 36.0;
    } else if (label.contains('pneu')) {
      speedKmH = 32.0;
    } else {
      speedKmH = 30.0;
    }

    final minutes = ((distanceKm / speedKmH) * 60).round();
    return minutes.clamp(8, 180);
  }

  int estimateApproachDurationMinutes(double distanceKm) {
    final minutes = ((distanceKm / 38) * 60).round();
    return minutes.clamp(4, 180);
  }

  double estimatePrice({
    required ServiceType service,
    required double distanceKm,
    required bool hasDestination,
    required String urgency,
  }) {
    final label = service.toString().toLowerCase();

    double base = pricingBasePrice;
    double perKm = pricingPerKm;

    if (label.contains('batterie')) {
      base = pricingBasePrice * 0.65;
      perKm = pricingPerKm * 0.35;
    } else if (label.contains('pneu')) {
      base = pricingBasePrice * 0.75;
      perKm = pricingPerKm * 0.45;
    } else if (label.contains('remorquage')) {
      base = pricingBasePrice;
      perKm = pricingPerKm;
    } else {
      base = pricingBasePrice * 0.85;
      perKm = pricingPerKm * 0.55;
    }

    double urgencyFee = 0;
    final lowerUrgency = urgency.toLowerCase();
    if (lowerUrgency.contains('urgent')) {
      urgencyFee = pricingUrgentFee;
    } else if (lowerUrgency.contains('crit')) {
      urgencyFee = pricingUrgentFee * 1.8;
    }

    final tripPart =
        hasDestination ? distanceKm * perKm : distanceKm * (perKm * 0.4);
    final total = base + tripPart + urgencyFee;
    return double.parse(total.toStringAsFixed(0));
  }

  double estimateProviderApproachFee(double distanceKm) {
    if (distanceKm <= 3) return 0;
    final fee = 300 + ((distanceKm - 3) * 28);
    return double.parse(fee.toStringAsFixed(0));
  }

  double estimateCommissionAmount(double requestPrice) {
    final amount = requestPrice * (pricingCommissionPercent / 100);
    return double.parse(amount.toStringAsFixed(0));
  }

  Future<Map<String, dynamic>> _readCurrentUserProfile() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Utilisateur non connecte.');
    }

    if (_currentUserUid == uid && _currentUserProfile.isNotEmpty) {
      return _currentUserProfile;
    }

    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw Exception('Profil utilisateur introuvable.');
    }

    _currentUserUid = uid;
    _currentUserProfile = data;
    return data;
  }

  List<ProviderAgent> nearbyProvidersForCustomer(
    LatLng customerPosition, {
    String? requestId,
    int limit = 5,
  }) {
    final items = eligibleProvidersSortedByDistance(
      customerPosition,
      requestId: requestId,
    );
    final targetedProviderId =
        requestId == null ? null : findRequest(requestId)?.offeredProviderUid;

    final deduped = <ProviderAgent>[];
    for (final provider in items) {
      final duplicateIndex = deduped.indexWhere((existing) {
        final sameId = existing.id == provider.id;
        final closeDistance = const Distance().as(
              LengthUnit.Meter,
              existing.position,
              provider.position,
            ) <
            18;
        return sameId || closeDistance;
      });

      if (duplicateIndex == -1) {
        deduped.add(provider);
        continue;
      }

      final existing = deduped[duplicateIndex];
      final shouldReplace = provider.id == targetedProviderId &&
          existing.id != targetedProviderId;
      if (shouldReplace) {
        deduped[duplicateIndex] = provider;
      }
    }

    if (deduped.length <= limit) return deduped;
    return deduped.take(limit).toList();
  }

  Future<String> createRequest({
    required ServiceType service,
    required LatLng customerPosition,
    required String pickupLabel,
    required String pickupSubtitle,
    required String vehicleType,
    required String brandModel,
    required String payment,
    required String landmark,
    required String issueDescription,
    required String urgency,
    required String destination,
    required LatLng destinationPosition,
    required String photoHint,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('Vous devez etre connecte.');
    }

    if (activeCustomerRequests.isNotEmpty) {
      throw Exception(
        'Vous avez deja une mission en cours. Annulez la demande actuelle avant d en creer une nouvelle.',
      );
    }

    final profile = await _readCurrentUserProfile();
    final resolvedPickupLabel = _fastPickupLabel(
      pickupLabel: pickupLabel,
      customerPosition: customerPosition,
    );

    final cleanedDestination = destination.trim();
    if (cleanedDestination.isEmpty) {
      throw Exception('La destination est obligatoire.');
    }

    final distanceKm = estimateDistanceKm(
      from: customerPosition,
      to: destinationPosition,
    );

    final durationMinutes = estimateDurationMinutes(
      distanceKm: distanceKm,
      service: service,
    );

    final estimatedPrice = estimatePrice(
      service: service,
      distanceKm: distanceKm,
      hasDestination: cleanedDestination.isNotEmpty,
      urgency: urgency,
    );

    final request = AppRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      customerUid: currentUser.uid,
      service: service,
      customerName: (profile['fullName'] ?? '').toString(),
      customerPhone: (profile['phone'] ?? '').toString(),
      pickupLabel: resolvedPickupLabel,
      pickupSubtitle: pickupSubtitle,
      customerPosition: customerPosition,
      vehicleType: vehicleType,
      brandModel: brandModel,
      payment: payment,
      landmark: landmark,
      issueDescription: issueDescription,
      urgency: urgency,
      destination: cleanedDestination,
      destinationPosition: destinationPosition,
      photoHint: photoHint,
      status: RequestStatus.searching,
      offeredProviderUid: null,
      rejectedProviderUids: const [],
      estimatedDistanceKm: distanceKm,
      estimatedDurationMinutes: durationMinutes,
      estimatedPrice: estimatedPrice,
    );

    await requestRepository.addRequest(request);

    // ✅ Dispatch immediately - no delay!
    // This ensures providers receive notification with full 20s offer duration
    unawaited(
      _attemptFallbackDispatch(
        request.id,
        customerPosition: customerPosition,
        delay: Duration.zero, // No delay - dispatch immediately
      ),
    );

    customerTab = 1;
    _pushLifecycleNotification(
      title: 'Demande envoyee',
      body: 'Recherche du provider le plus proche',
      type: 'request_created',
    );

    notifyListeners();
    return request.id;
  }

  String _fastPickupLabel({
    required String pickupLabel,
    required LatLng customerPosition,
  }) {
    final cleaned = pickupLabel.trim();
    final generic = cleaned.isEmpty ||
        cleaned.toLowerCase() == 'ma position actuelle' ||
        cleaned.toLowerCase().contains('destination carte');

    if (!generic) return cleaned;

    return cleaned.isNotEmpty
        ? cleaned
        : 'Position proche (${customerPosition.latitude.toStringAsFixed(5)}, ${customerPosition.longitude.toStringAsFixed(5)})';
  }

  Future<void> acceptRequest(String requestId) async {
    final current = findRequest(requestId);
    if (current == null) return;

    final providerId = auth.currentUser?.uid;
    if (providerId == null) return;

    final offeredId = current.offeredProviderUid;
    if (offeredId != null && offeredId != providerId) {
      _pushLifecycleNotification(
        title: 'Mission indisponible',
        body: 'Cette mission est proposee a un autre provider',
        type: 'wrong_provider',
      );
      notifyListeners();
      return;
    }

    final provider = findProviderById(providerId);
    if (provider == null) return;

    // ✅ Check if provider already has an active mission
    final activeMissions = providerAssignedRequests;
    if (activeMissions.isNotEmpty) {
      _pushLifecycleNotification(
        title: 'Mission indisponible',
        body:
            'Vous avez deja une mission en cours. Terminez-la avant d\'en accepter une nouvelle.',
        type: 'provider_busy',
      );
      notifyListeners();
      return;
    }

    _dispatchTimers[requestId]?.cancel();
    _dispatchTimers.remove(requestId);
    _scannedProviderCounts.remove(requestId);
    _currentDispatchAttempts.remove(requestId);
    _noProviderPopupMutedUntil.remove(requestId);
    if (noProviderRequestId == requestId) {
      noProviderRequestId = null;
      noProviderPopupVisible = false;
    }

    final providerStart = provider.position;
    final approachDistanceKm = estimateDistanceKm(
      from: providerStart,
      to: current.customerPosition,
    );
    final approachDurationMinutes =
        estimateApproachDurationMinutes(approachDistanceKm);
    final approachFee = estimateProviderApproachFee(approachDistanceKm);

    final accepted = await requestRepository.acceptOfferedRequest(
      requestId: requestId,
      providerUid: provider.id,
      providerName: provider.name,
      providerPhone: provider.phone,
      providerVehicle: provider.vehicleType,
      providerPlate: provider.plate,
      providerPosition: providerStart,
    );

    if (!accepted) {
      _pushLifecycleNotification(
        title: 'Mission indisponible',
        body: 'Cette mission a deja ete prise ou n est plus disponible',
        type: 'request_locked',
      );
      notifyListeners();
      return;
    }

    await updateProviderBusyStatus(
      provider.id,
      true,
      activeRequestId: requestId,
    );

    final acceptedRequest = current.copyWith(
      status: RequestStatus.accepted,
      providerUid: provider.id,
      providerName: provider.name,
      providerPhone: provider.phone,
      providerVehicle: provider.vehicleType,
      providerPlate: provider.plate,
      providerPosition: providerStart,
      offeredProviderUid: null,
      offeredAt: null,
      offerExpiresAt: null,
      providerApproachDistanceKm: approachDistanceKm,
      providerApproachDurationMinutes: approachDurationMinutes,
      providerApproachFee: approachFee,
      estimatedPrice: (current.estimatedPrice ?? 0) + approachFee,
    );
    await requestRepository.updateRequest(requestId, acceptedRequest);
    await _stampRequestMetadata(
      requestId,
      {
        'acceptedAtIso': DateTime.now().toIso8601String(),
        'statusChangedAtIso': DateTime.now().toIso8601String(),
      },
    );

    await trackingRepository.setTracking(
      TrackingSnapshot(
        requestId: requestId,
        customerPosition: current.customerPosition,
        providerPosition: providerStart,
      ),
    );

    providerTab = 1;
    _pushLifecycleNotification(
      title: 'Mission acceptee',
      body: '${provider.name} a accepte la mission',
      type: 'accepted',
    );

    await startLiveTracking(requestId);
    notifyListeners();
  }

  Future<void> rejectRequestForCurrentProvider(String requestId) async {
    final current = findRequest(requestId);
    if (current == null) return;

    final providerId = auth.currentUser?.uid;
    if (providerId == null) return;

    final offeredId = current.offeredProviderUid;
    if (offeredId != null && offeredId != providerId) {
      _pushLifecycleNotification(
        title: 'Mission indisponible',
        body: 'Cette mission est proposee a un autre provider',
        type: 'wrong_provider',
      );
      notifyListeners();
      return;
    }

    await rejectRequestForProvider(requestId, providerId);
  }

  Future<void> rejectRequestForProvider(
    String requestId,
    String providerId, {
    bool fromTimeout = false,
  }) async {
    final current = findRequest(requestId);
    if (current == null) return;

    final provider = findProviderById(providerId);
    if (provider == null) return;

    await updateProviderBusyStatus(provider.id, false);

    _dispatchTimers[requestId]?.cancel();
    _dispatchTimers.remove(requestId);

    stopLiveTracking(requestId);
    await trackingRepository.clearTracking(requestId);

    final rejectedOk = await requestRepository.rejectOfferedRequest(
      requestId: requestId,
      providerUid: provider.id,
    );

    if (!rejectedOk) {
      notifyListeners();
      return;
    }

    // ✅ Advance dispatch chain to next provider
    if (_dispatchChains.containsKey(requestId)) {
      final currentIndex = _dispatchChainIndex[requestId] ?? 0;
      _dispatchChainIndex[requestId] = currentIndex + 1;
    }
    _currentOfferedProviderIds.remove(requestId);

    _pushLifecycleNotification(
      title: fromTimeout ? 'Temps expire' : 'Mission retiree',
      body: fromTimeout
          ? 'Le delai a expire. Nouvelle attribution en cours.'
          : 'La mission a ete retiree de votre liste.',
      type: fromTimeout ? 'timeout' : 'rejected',
    );

    // ✅ Automatically dispatch to next provider in chain
    if (current.status == RequestStatus.searching) {
      unawaited(_attemptFallbackDispatch(
        requestId,
        customerPosition: current.customerPosition,
        delay: const Duration(milliseconds: 500),
      ));
    }

    notifyListeners();
  }

  Future<void> advanceMission(String requestId) async {
    final current = findRequest(requestId);
    if (current == null) return;

    switch (current.status) {
      case RequestStatus.accepted:
        await requestRepository.updateRequest(
          requestId,
          current.copyWith(status: RequestStatus.onTheWay),
        );
        await _stampRequestMetadata(
          requestId,
          {
            'onTheWayAtIso': DateTime.now().toIso8601String(),
            'statusChangedAtIso': DateTime.now().toIso8601String(),
          },
        );
        _pushLifecycleNotification(
          title: 'Mission en route',
          body: '${current.providerName ?? 'Le provider'} est en route',
          type: 'on_the_way',
        );
        break;

      case RequestStatus.onTheWay:
        _arrivalHitCounts.remove(requestId);
        await requestRepository.updateRequest(
          requestId,
          current.copyWith(status: RequestStatus.arrived),
        );
        await _stampRequestMetadata(
          requestId,
          {
            'arrivedAtIso': DateTime.now().toIso8601String(),
            'statusChangedAtIso': DateTime.now().toIso8601String(),
          },
        );
        _pushLifecycleNotification(
          title: 'Provider arrive',
          body: '${current.providerName ?? 'Le provider'} est arrive',
          type: 'arrived',
        );
        break;

      case RequestStatus.arrived:
        await requestRepository.updateRequest(
          requestId,
          current.copyWith(status: RequestStatus.inService),
        );
        await _stampRequestMetadata(
          requestId,
          {
            'inServiceAtIso': DateTime.now().toIso8601String(),
            'statusChangedAtIso': DateTime.now().toIso8601String(),
          },
        );
        _pushLifecycleNotification(
          title: 'Service commence',
          body: 'Votre depannage est en cours',
          type: 'in_service',
        );
        break;

      case RequestStatus.inService:
        _arrivalHitCounts.remove(requestId);
        await requestRepository.updateRequest(
          requestId,
          current.copyWith(
            status: RequestStatus.completed,
            completedAt: DateTime.now(),
          ),
        );
        await _stampRequestMetadata(
          requestId,
          {
            'completedAtIso': DateTime.now().toIso8601String(),
            'statusChangedAtIso': DateTime.now().toIso8601String(),
          },
        );

        lastCompletedRequestId = requestId;

        final provider = findProviderById(current.providerUid ?? '');
        if (provider != null) {
          await updateProviderBusyStatus(provider.id, false);
          await firestore.collection('providers').doc(provider.id).set({
            'missionsCompleted': provider.missionsCompleted + 1,
          }, SetOptions(merge: true));
        }

        _dispatchTimers[requestId]?.cancel();
        _dispatchTimers.remove(requestId);

        stopLiveTracking(requestId);
        await trackingRepository.clearTracking(requestId);

        _pushLifecycleNotification(
          title: 'Mission terminee',
          body: 'Votre mission a ete completee avec succes',
          type: 'completed',
        );
        break;

      default:
        break;
    }
    notifyListeners();
  }

  Future<void> cancelRequest(String requestId) async {
    final current = findRequest(requestId);
    if (current == null) return;

    _arrivalHitCounts.remove(requestId);

    _dispatchTimers[requestId]?.cancel();
    _dispatchTimers.remove(requestId);
    _dispatchChains.remove(requestId);
    _dispatchChainIndex.remove(requestId);
    _currentOfferedProviderIds.remove(requestId);
    _scannedProviderCounts.remove(requestId);
    _currentDispatchAttempts.remove(requestId);
    _noProviderPopupMutedUntil.remove(requestId);
    if (noProviderRequestId == requestId) {
      noProviderRequestId = null;
      noProviderPopupVisible = false;
    }

    stopLiveTracking(requestId);

    await requestRepository.updateRequest(
      requestId,
      current.copyWith(
        status: RequestStatus.cancelled,
        offeredProviderUid: null,
        offeredAt: null,
        offerExpiresAt: null,
      ),
    );
    await _stampRequestMetadata(
      requestId,
      {
        'cancelledAtIso': DateTime.now().toIso8601String(),
        'statusChangedAtIso': DateTime.now().toIso8601String(),
      },
    );

    await trackingRepository.clearTracking(requestId);

    final provider = findProviderById(current.providerUid ?? '');
    if (provider != null) {
      await updateProviderBusyStatus(provider.id, false);
    }
    final offeredProviderId = current.offeredProviderUid;
    if (offeredProviderId != null && offeredProviderId.trim().isNotEmpty) {
      await _repairProviderSessionStateIfSafe(offeredProviderId);
    }

    _pushLifecycleNotification(
      title: 'Mission annulee',
      body: 'La mission a ete annulee',
      type: 'cancelled',
    );
    notifyListeners();
  }

  Future<void> submitClientRating({
    required String requestId,
    required double rating,
    required String review,
  }) async {
    final current = findRequest(requestId);
    if (current == null) return;

    await requestRepository.updateRequest(
      requestId,
      current.copyWith(
        clientRatingForProvider: rating,
        clientReviewForProvider: review.trim().isEmpty ? null : review.trim(),
        isClientRated: true,
      ),
    );
    await _stampRequestMetadata(
      requestId,
      {
        'clientRatedAtIso': DateTime.now().toIso8601String(),
      },
    );

    final provider = findProviderById(current.providerUid ?? '');
    if (provider != null) {
      final newCount = provider.ratingCount + 1;
      final newRating =
          ((provider.rating * provider.ratingCount) + rating) / newCount;

      await firestore.collection('providers').doc(provider.id).set({
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'ratingCount': newCount,
      }, SetOptions(merge: true));
    }

    _pushLifecycleNotification(
      title: 'Evaluation envoyee',
      body: 'Merci pour votre avis sur le provider',
      type: 'client_rating',
    );
    notifyListeners();
  }

  Future<void> submitProviderRating({
    required String requestId,
    required double rating,
    required String review,
  }) async {
    final current = findRequest(requestId);
    if (current == null) return;

    await requestRepository.updateRequest(
      requestId,
      current.copyWith(
        providerRatingForClient: rating,
        providerReviewForClient: review.trim().isEmpty ? null : review.trim(),
        isProviderRated: true,
      ),
    );
    await _stampRequestMetadata(
      requestId,
      {
        'providerRatedAtIso': DateTime.now().toIso8601String(),
      },
    );

    _pushLifecycleNotification(
      title: 'Evaluation client envoyee',
      body: 'Le provider a note le client',
      type: 'provider_rating',
    );
    notifyListeners();
  }

  Future<void> _stampRequestMetadata(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    await firestore.collection('requests').doc(requestId).set({
      ...data,
      'updatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    _providersSub?.cancel();
    _pricingSub?.cancel();
    _authSub?.cancel();
    _adminNotificationsSub?.cancel();

    for (final timer in _dispatchTimers.values) {
      timer.cancel();
    }
    _dispatchTimers.clear();

    for (final sub in _liveTrackingSubs.values) {
      sub.cancel();
    }
    _liveTrackingSubs.clear();

    presenceService.dispose();

    super.dispose();
  }
}
