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
    required this.photoHint,
    required this.status,
    this.providerUid,
    this.providerName,
    this.providerPhone,
    this.providerVehicle,
    this.providerPlate,
    this.providerPosition,
    this.offeredProviderUid,
    this.rejectedProviderUids = const [],
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    this.estimatedPrice,
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
  final String photoHint;

  final RequestStatus status;

  final String? providerUid;
  final String? providerName;
  final String? providerPhone;
  final String? providerVehicle;
  final String? providerPlate;
  final LatLng? providerPosition;

  final String? offeredProviderUid;
  final List<String> rejectedProviderUids;

  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final double? estimatedPrice;

  final double? clientRatingForProvider;
  final String? clientReviewForProvider;

  final double? providerRatingForClient;
  final String? providerReviewForClient;

  final bool isClientRated;
  final bool isProviderRated;

  final DateTime? completedAt;

  bool get hasEstimatedTrip =>
      estimatedDistanceKm != null ||
      estimatedDurationMinutes != null ||
      estimatedPrice != null;

  bool get canClientRate =>
      status == RequestStatus.completed && !isClientRated;

  bool get canProviderRate =>
      status == RequestStatus.completed && !isProviderRated;

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
    String? photoHint,
    RequestStatus? status,
    Object? providerUid = _sentinel,
    Object? providerName = _sentinel,
    Object? providerPhone = _sentinel,
    Object? providerVehicle = _sentinel,
    Object? providerPlate = _sentinel,
    Object? providerPosition = _sentinel,
    Object? offeredProviderUid = _sentinel,
    List<String>? rejectedProviderUids,
    Object? estimatedDistanceKm = _sentinel,
    Object? estimatedDurationMinutes = _sentinel,
    Object? estimatedPrice = _sentinel,
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
      'rejectedProviderUids': rejectedProviderUids,
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedPrice': estimatedPrice,
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

    DateTime? parseDateNullable(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

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
      rejectedProviderUids: (map['rejectedProviderUids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      estimatedDistanceKm: parseDouble(map['estimatedDistanceKm']),
      estimatedDurationMinutes: parseInt(map['estimatedDurationMinutes']),
      estimatedPrice: parseDouble(map['estimatedPrice']),
      clientRatingForProvider: parseDouble(map['clientRatingForProvider']),
      clientReviewForProvider: map['clientReviewForProvider']?.toString(),
      providerRatingForClient: parseDouble(map['providerRatingForClient']),
      providerReviewForClient: map['providerReviewForClient']?.toString(),
      isClientRated: map['isClientRated'] == true,
      isProviderRated: map['isProviderRated'] == true,
      completedAt: parseDateNullable(map['completedAt']),
    );
  }
}

const Object _sentinel = Object();