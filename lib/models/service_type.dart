import 'package:flutter/material.dart';

import '../core/i18n/app_localizations.dart';

enum ServiceType {
  towing,
  battery,
  tire,
  repair,
}

extension ServiceTypeX on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.towing:
        return 'Remorquage';
      case ServiceType.battery:
        return 'Batterie';
      case ServiceType.tire:
        return 'Pneu';
      case ServiceType.repair:
        return 'Depannage';
    }
  }

  String get labelKey {
    switch (this) {
      case ServiceType.towing:
        return 'service_towing';
      case ServiceType.battery:
        return 'service_battery';
      case ServiceType.tire:
        return 'service_tire';
      case ServiceType.repair:
        return 'service_repair';
    }
  }

  String localizedLabel(BuildContext context) =>
      AppLocalizations.of(context).t(labelKey);

  String get description {
    switch (this) {
      case ServiceType.towing:
        return 'Transport du vehicule vers une destination';
      case ServiceType.battery:
        return 'Demarrage / assistance batterie';
      case ServiceType.tire:
        return 'Crevaison, roue, gonflage';
      case ServiceType.repair:
        return 'Panne generale ou mecanique';
    }
  }

  String get descriptionKey {
    switch (this) {
      case ServiceType.towing:
        return 'service_towing_desc';
      case ServiceType.battery:
        return 'service_battery_desc';
      case ServiceType.tire:
        return 'service_tire_desc';
      case ServiceType.repair:
        return 'service_repair_desc';
    }
  }

  String localizedDescription(BuildContext context) =>
      AppLocalizations.of(context).t(descriptionKey);

  IconData get icon {
    switch (this) {
      case ServiceType.towing:
        return Icons.car_repair_outlined;
      case ServiceType.battery:
        return Icons.battery_charging_full_outlined;
      case ServiceType.tire:
        return Icons.tire_repair_outlined;
      case ServiceType.repair:
        return Icons.build_circle_outlined;
    }
  }

  int get basePriceDzd {
    switch (this) {
      case ServiceType.towing:
        return 1800;
      case ServiceType.battery:
        return 900;
      case ServiceType.tire:
        return 1000;
      case ServiceType.repair:
        return 1400;
    }
  }

  double get pricePerKmDzd {
    switch (this) {
      case ServiceType.towing:
        return 65;
      case ServiceType.battery:
        return 12;
      case ServiceType.tire:
        return 15;
      case ServiceType.repair:
        return 18;
    }
  }

  int get baseEtaMinutes {
    switch (this) {
      case ServiceType.towing:
        return 18;
      case ServiceType.battery:
        return 12;
      case ServiceType.tire:
        return 14;
      case ServiceType.repair:
        return 16;
    }
  }

  bool get requiresDestination {
    return this == ServiceType.towing;
  }

  String get etaLabel => '~$baseEtaMinutes min';

  String get priceLabel => '$basePriceDzd DZD+';
}
