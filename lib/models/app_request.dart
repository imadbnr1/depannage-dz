import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'request_status.dart';
import 'service_type.dart';

class AppRequest {
  const AppRequest({
    required this.id,
    required this.createdAt,
    required this.customerUid,
    required this.service,
    required this.customerName,
    required this.customerPhone,
    required this.pickupLabel,
    required this.pickupSubtitle,
    required this.customerPosition,
    required this.vehicleType,
    required this.brandModel,
    required this.payment,
    required this.landmark,
    required this.issueDescription,
    required this.urgency,
    required this.destination,
    this.destinationPosition,
    required this.photoHint,
    required this.status,
    this.providerUid,
    this.providerName,
    this.providerPhone,
    this.providerVehicle,
    this.providerPlate,
    this.providerPosition,
    this.offeredProviderUid,
    this.offeredAt,
    this.offerExpiresAt,
    this.rejectedProviderUids = const [],
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    this.estimatedPrice,
    this.providerApproachDistanceKm,
    this.providerApproachDurationMinutes,
    this.providerApproachFee,
    this.clientRatingForProvider,
    this.clientReviewForProvider,
    this.providerRatingForClient,
    this.providerReviewForClient,
    this.isClientRated = false,
    this.isProviderRated = false,
    this.completedAt,
  });

  final String id;
  final DateTime createdAt;

  final String customerUid;
  final ServiceType service;

  final String customerName;
  final String customerPhone;

  final String pickupLabel;
  final String pickupSubtitle;
  final LatLng customerPosition;

  final String vehicleType;
  final String brandModel;
  final String payment;
  final String landmark;
  final String issueDescription;
  final String urgency;

  final String destination;
  final LatLng? destinationPosition;
  final String photoHint;

  final RequestStatus status;

  final String? providerUid;
  final String? providerName;
  final String? providerPhone;
  final String? providerVehicle;
  final String? providerPlate;
  final LatLng? providerPosition;

  final String? offeredProviderUid;
  final DateTime? offeredAt;
  final DateTime? offerExpiresAt;
  final List<String> rejectedProviderUids;

  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final double? estimatedPrice;
  final double? providerApproachDistanceKm;
  final int? providerApproachDurationMinutes;
  final double? providerApproachFee;

  final double? clientRatingForProvider;
  final String? clientReviewForProvider;

  final double? providerRatingForClient;
  final String? providerReviewForClient;

  final bool isClientRated;
  final bool isProviderRated;

  final DateTime? completedAt;

  bool get hasClientRating =>
      isClientRated ||
      clientRatingForProvider != null ||
      ((clientReviewForProvider ?? '').trim().isNotEmpty);

  bool get hasProviderRating =>
      isProviderRated ||
      providerRatingForClient != null ||
      ((providerReviewForClient ?? '').trim().isNotEmpty);

  bool get hasEstimatedTrip =>
      estimatedDistanceKm != null ||
      estimatedDurationMinutes != null ||
      estimatedPrice != null;

  bool get canClientRate =>
      status == RequestStatus.completed && !hasClientRating;

  bool get canProviderRate =>
      status == RequestStatus.completed && !hasProviderRating;

  AppRequest copyWith({
    String? id,
    DateTime? createdAt,
    String? customerUid,
    ServiceType? service,
    String? customerName,
    String? customerPhone,
    String? pickupLabel,
    String? pickupSubtitle,
    LatLng? customerPosition,
    String? vehicleType,
    String? brandModel,
    String? payment,
    String? landmark,
    String? issueDescription,
    String? urgency,
    String? destination,
    Object? destinationPosition = _sentinel,
    String? photoHint,
    RequestStatus? status,
    Object? providerUid = _sentinel,
    Object? providerName = _sentinel,
    Object? providerPhone = _sentinel,
    Object? providerVehicle = _sentinel,
    Object? providerPlate = _sentinel,
    Object? providerPosition = _sentinel,
    Object? offeredProviderUid = _sentinel,
    Object? offeredAt = _sentinel,
    Object? offerExpiresAt = _sentinel,
    List<String>? rejectedProviderUids,
    Object? estimatedDistanceKm = _sentinel,
    Object? estimatedDurationMinutes = _sentinel,
    Object? estimatedPrice = _sentinel,
    Object? providerApproachDistanceKm = _sentinel,
    Object? providerApproachDurationMinutes = _sentinel,
    Object? providerApproachFee = _sentinel,
    Object? clientRatingForProvider = _sentinel,
    Object? clientReviewForProvider = _sentinel,
    Object? providerRatingForClient = _sentinel,
    Object? providerReviewForClient = _sentinel,
    bool? isClientRated,
    bool? isProviderRated,
    Object? completedAt = _sentinel,
  }) {
    return AppRequest(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      customerUid: customerUid ?? this.customerUid,
      service: service ?? this.service,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      pickupSubtitle: pickupSubtitle ?? this.pickupSubtitle,
      customerPosition: customerPosition ?? this.customerPosition,
      vehicleType: vehicleType ?? this.vehicleType,
      brandModel: brandModel ?? this.brandModel,
      payment: payment ?? this.payment,
      landmark: landmark ?? this.landmark,
      issueDescription: issueDescription ?? this.issueDescription,
      urgency: urgency ?? this.urgency,
      destination: destination ?? this.destination,
      destinationPosition: destinationPosition == _sentinel
          ? this.destinationPosition
          : destinationPosition as LatLng?,
      photoHint: photoHint ?? this.photoHint,
      status: status ?? this.status,
      providerUid:
          providerUid == _sentinel ? this.providerUid : providerUid as String?,
      providerName: providerName == _sentinel
          ? this.providerName
          : providerName as String?,
      providerPhone: providerPhone == _sentinel
          ? this.providerPhone
          : providerPhone as String?,
      providerVehicle: providerVehicle == _sentinel
          ? this.providerVehicle
          : providerVehicle as String?,
      providerPlate: providerPlate == _sentinel
          ? this.providerPlate
          : providerPlate as String?,
      providerPosition: providerPosition == _sentinel
          ? this.providerPosition
          : providerPosition as LatLng?,
      offeredProviderUid: offeredProviderUid == _sentinel
          ? this.offeredProviderUid
          : offeredProviderUid as String?,
      offeredAt:
          offeredAt == _sentinel ? this.offeredAt : offeredAt as DateTime?,
      offerExpiresAt: offerExpiresAt == _sentinel
          ? this.offerExpiresAt
          : offerExpiresAt as DateTime?,
      rejectedProviderUids: rejectedProviderUids ?? this.rejectedProviderUids,
      estimatedDistanceKm: estimatedDistanceKm == _sentinel
          ? this.estimatedDistanceKm
          : estimatedDistanceKm as double?,
      estimatedDurationMinutes: estimatedDurationMinutes == _sentinel
          ? this.estimatedDurationMinutes
          : estimatedDurationMinutes as int?,
      estimatedPrice: estimatedPrice == _sentinel
          ? this.estimatedPrice
          : estimatedPrice as double?,
      providerApproachDistanceKm: providerApproachDistanceKm == _sentinel
          ? this.providerApproachDistanceKm
          : providerApproachDistanceKm as double?,
      providerApproachDurationMinutes:
          providerApproachDurationMinutes == _sentinel
              ? this.providerApproachDurationMinutes
              : providerApproachDurationMinutes as int?,
      providerApproachFee: providerApproachFee == _sentinel
          ? this.providerApproachFee
          : providerApproachFee as double?,
      clientRatingForProvider: clientRatingForProvider == _sentinel
          ? this.clientRatingForProvider
          : clientRatingForProvider as double?,
      clientReviewForProvider: clientReviewForProvider == _sentinel
          ? this.clientReviewForProvider
          : clientReviewForProvider as String?,
      providerRatingForClient: providerRatingForClient == _sentinel
          ? this.providerRatingForClient
          : providerRatingForClient as double?,
      providerReviewForClient: providerReviewForClient == _sentinel
          ? this.providerReviewForClient
          : providerReviewForClient as String?,
      isClientRated: isClientRated ?? this.isClientRated,
      isProviderRated: isProviderRated ?? this.isProviderRated,
      completedAt: completedAt == _sentinel
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerUid': customerUid,
      'service': service.toString().split('.').last,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupLabel': pickupLabel,
      'pickupSubtitle': pickupSubtitle,
      'customerPosition': {
        'lat': customerPosition.latitude,
        'lng': customerPosition.longitude,
      },
      'vehicleType': vehicleType,
      'brandModel': brandModel,
      'payment': payment,
      'landmark': landmark,
      'issueDescription': issueDescription,
      'urgency': urgency,
      'destination': destination,
      'destinationPosition': destinationPosition == null
          ? null
          : {
              'lat': destinationPosition!.latitude,
              'lng': destinationPosition!.longitude,
            },
      'photoHint': photoHint,
      'status': status.name,
      'providerUid': providerUid,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'providerVehicle': providerVehicle,
      'providerPlate': providerPlate,
      'providerPosition': providerPosition == null
          ? null
          : {
              'lat': providerPosition!.latitude,
              'lng': providerPosition!.longitude,
            },
      'offeredProviderUid': offeredProviderUid,
      'offeredAt': offeredAt?.toIso8601String(),
      'offerExpiresAt': offerExpiresAt?.toIso8601String(),
      'rejectedProviderUids': rejectedProviderUids,
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedPrice': estimatedPrice,
      'providerApproachDistanceKm': providerApproachDistanceKm,
      'providerApproachDurationMinutes': providerApproachDurationMinutes,
      'providerApproachFee': providerApproachFee,
      'clientRatingForProvider': clientRatingForProvider,
      'clientReviewForProvider': clientReviewForProvider,
      'providerRatingForClient': providerRatingForClient,
      'providerReviewForClient': providerReviewForClient,
      'isClientRated': isClientRated,
      'isProviderRated': isProviderRated,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory AppRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};

    LatLng parseLatLng(dynamic raw, {LatLng? fallback}) {
      if (raw is Map<String, dynamic>) {
        final lat = raw['lat'];
        final lng = raw['lng'];
        if (lat is num && lng is num) {
          return LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      return fallback ?? const LatLng(36.7538, 3.0588);
    }

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return null;
    }

    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return null;
    }

    bool? parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return null;
    }

    DateTime? parseDateNullable(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    LatLng? parseLatLngFromLabel(String? value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return null;

      final match = RegExp(r'\((-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\)')
          .firstMatch(text);
      if (match == null) return null;

      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    final clientRatingForProvider = parseDouble(map['clientRatingForProvider']);
    final clientReviewForProvider = map['clientReviewForProvider']?.toString();
    final providerRatingForClient = parseDouble(map['providerRatingForClient']);
    final providerReviewForClient = map['providerReviewForClient']?.toString();
    final normalizedIsClientRated =
        (parseBool(map['isClientRated']) ?? false) ||
            clientRatingForProvider != null ||
            ((clientReviewForProvider ?? '').trim().isNotEmpty);
    final normalizedIsProviderRated =
        (parseBool(map['isProviderRated']) ?? false) ||
            providerRatingForClient != null ||
            ((providerReviewForClient ?? '').trim().isNotEmpty);

    final serviceRaw = (map['service'] ?? '').toString().toLowerCase();
    final service = ServiceType.values.firstWhere(
      (s) => s.toString().toLowerCase().contains(serviceRaw),
      orElse: () => ServiceType.values.first,
    );

    final statusRaw = (map['status'] ?? 'searching').toString();
    final status = RequestStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => RequestStatus.searching,
    );

    return AppRequest(
      id: (map['id'] ?? doc.id).toString(),
      createdAt: parseDateNullable(map['createdAt']) ?? DateTime.now(),
      customerUid: (map['customerUid'] ?? '').toString(),
      service: service,
      customerName: (map['customerName'] ?? '').toString(),
      customerPhone: (map['customerPhone'] ?? '').toString(),
      pickupLabel: (map['pickupLabel'] ?? '').toString(),
      pickupSubtitle: (map['pickupSubtitle'] ?? '').toString(),
      customerPosition: parseLatLng(map['customerPosition']),
      vehicleType: (map['vehicleType'] ?? '').toString(),
      brandModel: (map['brandModel'] ?? '').toString(),
      payment: (map['payment'] ?? '').toString(),
      landmark: (map['landmark'] ?? '').toString(),
      issueDescription: (map['issueDescription'] ?? '').toString(),
      urgency: (map['urgency'] ?? '').toString(),
      destination: (map['destination'] ?? '').toString(),
      destinationPosition: map['destinationPosition'] == null
          ? parseLatLngFromLabel((map['destination'] ?? '').toString())
          : parseLatLng(map['destinationPosition']),
      photoHint: (map['photoHint'] ?? '').toString(),
      status: status,
      providerUid: map['providerUid']?.toString(),
      providerName: map['providerName']?.toString(),
      providerPhone: map['providerPhone']?.toString(),
      providerVehicle: map['providerVehicle']?.toString(),
      providerPlate: map['providerPlate']?.toString(),
      providerPosition: map['providerPosition'] == null
          ? null
          : parseLatLng(map['providerPosition']),
      offeredProviderUid: map['offeredProviderUid']?.toString(),
      offeredAt: parseDateNullable(map['offeredAt']),
      offerExpiresAt: parseDateNullable(map['offerExpiresAt']),
      rejectedProviderUids: (map['rejectedProviderUids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      estimatedDistanceKm: parseDouble(map['estimatedDistanceKm']),
      estimatedDurationMinutes: parseInt(map['estimatedDurationMinutes']),
      estimatedPrice: parseDouble(map['estimatedPrice']),
      providerApproachDistanceKm:
          parseDouble(map['providerApproachDistanceKm']),
      providerApproachDurationMinutes:
          parseInt(map['providerApproachDurationMinutes']),
      providerApproachFee: parseDouble(map['providerApproachFee']),
      clientRatingForProvider: clientRatingForProvider,
      clientReviewForProvider: clientReviewForProvider,
      providerRatingForClient: providerRatingForClient,
      providerReviewForClient: providerReviewForClient,
      isClientRated: normalizedIsClientRated,
      isProviderRated: normalizedIsProviderRated,
      completedAt: parseDateNullable(map['completedAt']),
    );
  }
}

const Object _sentinel = Object();
