import 'package:flutter/material.dart';

import '../core/i18n/app_localizations.dart';

enum RequestStatus {
  searching,
  accepted,
  onTheWay,
  arrived,
  inService,
  completed,
  cancelled,
}

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.searching:
        return 'Recherche';
      case RequestStatus.accepted:
        return 'Acceptee';
      case RequestStatus.onTheWay:
        return 'En route';
      case RequestStatus.arrived:
        return 'Arrive';
      case RequestStatus.inService:
        return 'En service';
      case RequestStatus.completed:
        return 'Terminee';
      case RequestStatus.cancelled:
        return 'Annulee';
    }
  }

  String get labelKey {
    switch (this) {
      case RequestStatus.searching:
        return 'status_searching';
      case RequestStatus.accepted:
        return 'status_accepted';
      case RequestStatus.onTheWay:
        return 'status_on_the_way';
      case RequestStatus.arrived:
        return 'status_arrived';
      case RequestStatus.inService:
        return 'status_in_service';
      case RequestStatus.completed:
        return 'status_completed';
      case RequestStatus.cancelled:
        return 'status_cancelled';
    }
  }

  String localizedLabel(BuildContext context) =>
      AppLocalizations.of(context).t(labelKey);

  Color get color {
    switch (this) {
      case RequestStatus.searching:
        return const Color(0xFF2563EB);
      case RequestStatus.accepted:
        return const Color(0xFF0F766E);
      case RequestStatus.onTheWay:
        return const Color(0xFFD97706);
      case RequestStatus.arrived:
        return const Color(0xFF0284C7);
      case RequestStatus.inService:
        return const Color(0xFF7C3AED);
      case RequestStatus.completed:
        return const Color(0xFF16A34A);
      case RequestStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }
}
