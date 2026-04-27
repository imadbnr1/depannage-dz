import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/services/startup_permission_service.dart';
import '../../../widgets/language_selector.dart';

class PermissionGatePage extends StatefulWidget {
  const PermissionGatePage({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  State<PermissionGatePage> createState() => _PermissionGatePageState();
}

class _PermissionGatePageState extends State<PermissionGatePage> {
  final StartupPermissionService _permissionService =
      const StartupPermissionService();

  StartupPermissionSnapshot? _snapshot;
  bool _loading = true;
  bool _requestingAll = false;
  bool _autoPrompting = false;
  bool _autoPromptAttempted = false;

  @override
  void initState() {
    super.initState();
    _refresh(allowAutoPrompt: true);
  }

  Future<void> _refresh({bool allowAutoPrompt = false}) async {
    final snapshot = await _permissionService.assess();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
    if (allowAutoPrompt) {
      _scheduleAutoPrompt(snapshot);
    }
  }

  void _scheduleAutoPrompt(StartupPermissionSnapshot snapshot) {
    if (_autoPromptAttempted || snapshot.allGranted) return;
    _autoPromptAttempted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      await _requestAll(auto: true);
    });
  }

  Future<void> _requestAll({bool auto = false}) async {
    if (_requestingAll) return;
    setState(() {
      _requestingAll = true;
      _autoPrompting = auto;
    });

    final snapshot = await _permissionService.requestAll();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _requestingAll = false;
      _autoPrompting = false;
    });
    if (snapshot.allGranted) {
      widget.onContinue();
    }
  }

  String _locationStatus(
    BuildContext context,
    StartupPermissionSnapshot snapshot,
  ) {
    final strings = AppLocalizations.of(context);
    if (!snapshot.locationServiceEnabled) {
      return strings.t('gpsDisabled');
    }
    switch (snapshot.locationPermission) {
      case LocationPermission.always:
        return strings.t('locationAlways');
      case LocationPermission.whileInUse:
        return strings.t('locationWhileInUse');
      case LocationPermission.deniedForever:
        return strings.t('permissionDeniedForever');
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return strings.t('permissionPending');
    }
  }

  String _notificationStatus(
    BuildContext context,
    StartupPermissionSnapshot snapshot,
  ) {
    final strings = AppLocalizations.of(context);
    if (!snapshot.notificationsSupported) {
      return strings.t('notificationsUnsupported');
    }
    switch (snapshot.notificationStatus) {
      case AuthorizationStatus.authorized:
        return strings.t('notificationsAuthorized');
      case AuthorizationStatus.provisional:
        return strings.t('notificationsProvisional');
      case AuthorizationStatus.denied:
        return strings.t('notificationsDenied');
      case AuthorizationStatus.notDetermined:
      case null:
        return strings.t('permissionPending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final snapshot = _snapshot;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1A2637),
              Color(0xFFE89A1E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 22 : 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFCF7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x260F172A),
                              blurRadius: 28,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: _loading || snapshot == null
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(46),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: LanguageSelector(
                                      compact: compact,
                                      backgroundColor: const Color(0xFFF8F1E6),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _PermissionHeader(compact: compact),
                                  const SizedBox(height: 20),
                                  _AutoPromptBanner(
                                    autoPrompting: _autoPrompting,
                                    allGranted: snapshot.allGranted,
                                  ),
                                  const SizedBox(height: 16),
                                  _PermissionTile(
                                    compact: compact,
                                    icon: Icons.location_on_outlined,
                                    title: strings.t('locationTitle'),
                                    subtitle: _locationStatus(
                                      context,
                                      snapshot,
                                    ),
                                    granted: snapshot.locationServiceEnabled &&
                                        snapshot.locationGranted,
                                    actionLabel:
                                        !snapshot.locationServiceEnabled
                                            ? strings.t('enableGps')
                                            : strings.t('allow'),
                                    onAction: () async {
                                      if (!snapshot.locationServiceEnabled) {
                                        await _permissionService
                                            .openLocationSettings();
                                      } else {
                                        await _permissionService
                                            .requestLocationPermission();
                                      }
                                      await _refresh();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _PermissionTile(
                                    compact: compact,
                                    icon: Icons.notifications_active_outlined,
                                    title: strings.t('notificationsTitle'),
                                    subtitle: _notificationStatus(
                                      context,
                                      snapshot,
                                    ),
                                    granted: snapshot.notificationsGranted,
                                    actionLabel: strings.t('allow'),
                                    onAction: snapshot.notificationsSupported
                                        ? () async {
                                            await _permissionService
                                                .requestNotificationPermission();
                                            await _refresh();
                                          }
                                        : null,
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F0E3),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      strings.t('permissionWhy'),
                                      style: const TextStyle(
                                        color: Color(0xFF4B5563),
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _requestingAll
                                          ? null
                                          : () => _requestAll(),
                                      icon: _requestingAll
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.security_update_good,
                                            ),
                                      label: Text(
                                        _requestingAll
                                            ? strings.t('checking')
                                            : strings.t('allowAll'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: widget.onContinue,
                                      child: Text(
                                        snapshot.allGranted
                                            ? strings.t('continue')
                                            : strings.t('continueAnyway'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PermissionHeader extends StatelessWidget {
  const _PermissionHeader({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final icon = Container(
      width: compact ? 60 : 72,
      height: compact ? 60 : 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE3AE),
            Color(0xFFE89A1E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.verified_user_outlined,
        color: const Color(0xFF3B2500),
        size: compact ? 30 : 34,
      ),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t('permissionTitle'),
          style: TextStyle(
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
            height: 1.06,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.t('permissionIntro'),
          style: const TextStyle(
            color: Color(0xFF6B7280),
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 16),
          text,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 18),
        Expanded(child: text),
      ],
    );
  }
}

class _AutoPromptBanner extends StatelessWidget {
  const _AutoPromptBanner({
    required this.autoPrompting,
    required this.allGranted,
  });

  final bool autoPrompting;
  final bool allGranted;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final color = allGranted
        ? const Color(0xFF0E8D7B)
        : autoPrompting
            ? const Color(0xFFE89A1E)
            : const Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          if (autoPrompting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              allGranted ? Icons.check_circle_outline : Icons.info_outline,
              color: color,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allGranted
                  ? strings.t('permissionAutoDone')
                  : autoPrompting
                      ? strings.t('permissionAutoTrying')
                      : strings.t('permissionAutoBlocked'),
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.compact,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.actionLabel,
    this.onAction,
  });

  final bool compact;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final content = _PermissionTileContent(
      icon: icon,
      title: title,
      subtitle: subtitle,
      granted: granted,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: granted ? const Color(0xFFD1FAE5) : const Color(0xFFE5E7EB),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 12),
                _PermissionTileAction(
                  granted: granted,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 12),
                _PermissionTileAction(
                  granted: granted,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              ],
            ),
    );
  }
}

class _PermissionTileAction extends StatelessWidget {
  const _PermissionTileAction({
    required this.granted,
    required this.actionLabel,
    this.onAction,
  });

  final bool granted;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (onAction == null) {
      return Icon(
        granted ? Icons.check_circle : Icons.info_outline,
        color: granted ? const Color(0xFF0E8D7B) : const Color(0xFF9CA3AF),
      );
    }

    return SizedBox(
      width: 148,
      child: OutlinedButton(
        onPressed: onAction,
        child: Text(actionLabel),
      ),
    );
  }
}

class _PermissionTileContent extends StatelessWidget {
  const _PermissionTileContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: granted ? const Color(0xFFECFDF5) : const Color(0xFFFFF4DE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: granted ? const Color(0xFF0E8D7B) : const Color(0xFFE89A1E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
