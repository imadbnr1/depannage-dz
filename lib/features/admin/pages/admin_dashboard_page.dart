// lib/features/admin/pages/admin_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/admin_audit_service.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../widgets/language_selector.dart';
import 'admin_activity_log_page.dart';
import 'admin_analytics_page.dart';
import 'admin_notifications_page.dart';
import 'admin_pricing_page.dart';
import 'admin_requests_page.dart';
import 'admin_support_config_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _index = 0;

  List<_AdminDestination> _destinations(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return [
      _AdminDestination(
        label: t('cmd_label'),
        title: t('cmd_center'),
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
      ),
      _AdminDestination(
        label: t('missions_label'),
        title: t('mission_ctrl'),
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
      _AdminDestination(
        label: t('providers_label'),
        title: t('provider_ops'),
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping,
      ),
      _AdminDestination(
        label: t('clients_label'),
        title: t('customer_ops'),
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
      ),
      _AdminDestination(
        label: t('tarifs_label'),
        title: t('pricing_lab'),
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune,
      ),
      _AdminDestination(
        label: t('analytics_label'),
        title: t('revenue_pulse'),
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
      ),
      _AdminDestination(
        label: t('notif_label'),
        title: t('broadcast_studio'),
        icon: Icons.campaign_outlined,
        selectedIcon: Icons.campaign,
      ),
      _AdminDestination(
        label: t('support_label'),
        title: t('support_control'),
        icon: Icons.support_agent_outlined,
        selectedIcon: Icons.support_agent,
      ),
      _AdminDestination(
        label: t('logs_label'),
        title: t('activity_log'),
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context);
    final pages = [
      _AdminOverviewPage(onNavigate: _onSelect),
      const AdminRequestsPage(),
      const _AdminProvidersPage(),
      const _AdminCustomersPage(),
      const AdminPricingPage(),
      const AdminAnalyticsPage(),
      const AdminNotificationsPage(),
      const AdminSupportConfigPage(),
      const AdminActivityLogPage(),
    ];

    final theme = Theme.of(context);
    final current = destinations[_index];
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;

            return Row(
              children: [
                if (wide)
                  _AdminSidebar(
                    index: _index,
                    onSelect: _onSelect,
                    destinations: destinations,
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1380),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F172A),
                                  Color(0xFF1E293B),
                                  Color(0xFF1D4ED8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x220F172A),
                                  blurRadius: 24,
                                  offset: Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        current.selectedIcon,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      width: wide
                                          ? 620
                                          : (constraints.maxWidth - 110).clamp(220.0, 620.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            current.title,
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t('admin_banner_subtitle'),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFF8FAFC),
                                        foregroundColor: const Color(0xFF0F172A),
                                      ),
                                      onPressed: () async {
                                        await AuthService().signOut();
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: Text(t('admin_logout')),
                                    ),
                                    const LanguageSelector(
                                      compact: true,
                                      backgroundColor: Color(0xFFF8FAFC),
                                    ),
                                  ],
                                ),
                                if (!wide) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 50,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: destinations.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        final item = destinations[index];
                                        final selected = index == _index;
                                        return ChoiceChip(
                                          label: Text(item.label),
                                          selected: selected,
                                          onSelected: (_) => _onSelect(index),
                                          avatar: Icon(
                                            selected ? item.selectedIcon : item.icon,
                                            size: 18,
                                            color: selected
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                          ),
                                          labelStyle: TextStyle(
                                            color: selected
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                                          selectedColor: const Color(0xFFF8FAFC),
                                          side: BorderSide(
                                            color: Colors.white.withValues(alpha: 0.1),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(20),
                              child: pages[_index],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width >= 1100
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _onSelect,
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _onSelect(int index) {
    setState(() => _index = index);
  }
}

// ═══════════════════════════════════════════════════════════════════
// _AdminOverviewPage — fully localized
// ═══════════════════════════════════════════════════════════════════
class _AdminOverviewPage extends StatelessWidget {
  const _AdminOverviewPage({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _statusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'accepted':
        return t.t('status_accepted');
      case 'onTheWay':
        return t.t('status_on_the_way');
      case 'arrived':
        return t.t('status_arrived');
      case 'inService':
        return t.t('status_in_service');
      case 'completed':
        return t.t('status_completed');
      case 'cancelled':
        return t.t('status_cancelled');
      default:
        return t.t('status_searching');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF2563EB);
      case 'onTheWay':
        return const Color(0xFFEA580C);
      case 'arrived':
        return const Color(0xFFD97706);
      case 'inService':
        return const Color(0xFF0E8D7B);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatMoney(double value, AppLocalizations t) => '${value.toStringAsFixed(0)} DA';

  String _formatWhen(DateTime? value, AppLocalizations t) {
    if (value == null) return '--';
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) {
      return '${t.t('today')} $hh:$mm';
    }
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd/$mo $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('requests').snapshots(),
      builder: (context, requestsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore.collection('providers').snapshots(),
          builder: (context, providersSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                if (requestsSnapshot.hasError ||
                    providersSnapshot.hasError ||
                    usersSnapshot.hasError) {
                  return _AdminErrorPanel(
                    title: t.t('error'),
                    subtitle: t.t('error'),
                    details: [
                      requestsSnapshot.error,
                      providersSnapshot.error,
                      usersSnapshot.error,
                    ].whereType<Object>().join('\n'),
                  );
                }

                if (requestsSnapshot.connectionState == ConnectionState.waiting ||
                    providersSnapshot.connectionState == ConnectionState.waiting ||
                    usersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = requestsSnapshot.data?.docs ?? [];
                final providers = providersSnapshot.data?.docs ?? [];
                final users = usersSnapshot.data?.docs ?? [];

                final searching =
                    requests.where((d) => (d.data()['status'] ?? '') == 'searching').length;
                final active = requests.where((d) {
                  final status = (d.data()['status'] ?? '').toString();
                  return status == 'accepted' ||
                      status == 'onTheWay' ||
                      status == 'arrived' ||
                      status == 'inService';
                }).length;
                final completed =
                    requests.where((d) => (d.data()['status'] ?? '') == 'completed').length;
                final cancelled =
                    requests.where((d) => (d.data()['status'] ?? '') == 'cancelled').length;
                final urgent = requests.where((d) {
                  final urgency = (d.data()['urgency'] ?? '').toString().toLowerCase();
                  return urgency.contains('urgent') || urgency.contains('crit');
                }).length;

                final onlineProviders =
                    providers.where((d) => d.data()['isOnline'] == true).length;
                final busyProviders =
                    providers.where((d) => d.data()['isBusy'] == true).length;
                final approvedProviders =
                    providers.where((d) => d.data()['isApproved'] == true).length;
                final pendingProviders = providers.where((d) {
                  final data = d.data();
                  return data['isApproved'] != true && data['isBlocked'] != true;
                }).toList();
                final blockedProviders =
                    providers.where((d) => d.data()['isBlocked'] == true).length;

                final customers =
                    users.where((d) => (d.data()['role'] ?? '') == 'customer').length;
                final providerUsers =
                    users.where((d) => (d.data()['role'] ?? '') == 'provider').length;
                final freeProviders = onlineProviders - busyProviders < 0
                    ? 0
                    : onlineProviders - busyProviders;
                final completedRevenue = requests
                    .where((d) => (d.data()['status'] ?? '') == 'completed')
                    .fold<double>(
                      0,
                      (total, doc) => total + _toDouble(doc.data()['estimatedPrice']),
                    );
                final averageTicket = completed == 0 ? 0.0 : completedRevenue / completed;
                final completionRate = requests.isEmpty
                    ? 0.0
                    : ((completed / requests.length) * 100).clamp(0, 100);
                final recentRequests = [...requests]..sort((a, b) {
                    final aDate = _toDate(a.data()['updatedAt']) ??
                        _toDate(a.data()['createdAt']) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bDate = _toDate(b.data()['updatedAt']) ??
                        _toDate(b.data()['createdAt']) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return bDate.compareTo(aDate);
                  });
                final spotlightRequests = recentRequests.take(4).toList(growable: false);
                final providerSpotlight = pendingProviders.take(3).toList(growable: false);
                final screenWidth = MediaQuery.of(context).size.width;
                final kpiColumns = screenWidth >= 1300
                    ? 4
                    : screenWidth >= 900
                        ? 3
                        : screenWidth >= 620
                            ? 2
                            : 1;
                final stackOverviewPanels = screenWidth < 900;

                return ListView(
                  children: [
                    GridView.count(
                      crossAxisCount: kpiColumns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.48,
                      children: [
                        _KpiCard(
                          title: t.t('overview_searching'),
                          value: '$searching',
                          subtitle: t.t('overview_searching_sub'),
                          accent: const Color(0xFFEA580C),
                          icon: Icons.radar_outlined,
                          onTap: () => onNavigate(1),
                        ),
                        _KpiCard(
                          title: t.t('overview_active'),
                          value: '$active',
                          subtitle: t.t('overview_active_sub'),
                          accent: const Color(0xFF2563EB),
                          icon: Icons.route_outlined,
                          onTap: () => onNavigate(1),
                        ),
                        _KpiCard(
                          title: t.t('overview_completed'),
                          value: '$completed',
                          subtitle: t.t('overview_completed_sub'),
                          accent: const Color(0xFF16A34A),
                          icon: Icons.verified_outlined,
                          onTap: () => onNavigate(5),
                        ),
                        _KpiCard(
                          title: t.t('overview_urgent'),
                          value: '$urgent',
                          subtitle: t.t('overview_urgent_sub'),
                          accent: const Color(0xFFDC2626),
                          icon: Icons.priority_high_outlined,
                          onTap: () => onNavigate(1),
                        ),
                        _KpiCard(
                          title: t.t('overview_providers_on'),
                          value: '$onlineProviders',
                          subtitle: t
                              .t('overview_providers_on_sub')
                              .replaceAll('{busy}', '$busyProviders'),
                          accent: const Color(0xFF0EA5E9),
                          icon: Icons.wifi_tethering_outlined,
                          onTap: () => onNavigate(2),
                        ),
                        _KpiCard(
                          title: t.t('overview_approved'),
                          value: '$approvedProviders',
                          subtitle: t
                              .t('overview_approved_sub')
                              .replaceAll('{blocked}', '$blockedProviders'),
                          accent: const Color(0xFF7C3AED),
                          icon: Icons.verified_user_outlined,
                          onTap: () => onNavigate(2),
                        ),
                        _KpiCard(
                          title: t.t('overview_clients'),
                          value: '$customers',
                          subtitle: t.t('overview_clients_sub'),
                          accent: const Color(0xFF0891B2),
                          icon: Icons.people_alt_outlined,
                          onTap: () => onNavigate(3),
                        ),
                        _KpiCard(
                          title: t.t('overview_provider_users'),
                          value: '$providerUsers',
                          subtitle: t.t('overview_provider_users_sub'),
                          accent: const Color(0xFF4F46E5),
                          icon: Icons.engineering_outlined,
                          onTap: () => onNavigate(2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (stackOverviewPanels)
                      Column(
                        children: [
                          _AdminPanel(
                            title: t.t('insight_mission_load'),
                            subtitle: t.t('insight_mission_load'),
                            child: Column(
                              children: [
                                _InsightRow(
                                  label: t.t('insight_mission_load'),
                                  value: active == 0
                                      ? t.t('mission_load_low')
                                      : active < 20
                                          ? t.t('mission_load_normal')
                                          : active < 50
                                              ? t.t('mission_load_high')
                                              : t.t('mission_load_critical'),
                                ),
                                _InsightRow(
                                  label: t.t('insight_free_providers'),
                                  value: '$freeProviders',
                                ),
                                _InsightRow(
                                  label: t.t('insight_cancellations'),
                                  value: '$cancelled',
                                ),
                                _InsightRow(
                                  label: t.t('insight_critical_demands'),
                                  value: '$urgent',
                                ),
                                _InsightRow(
                                  label: t.t('insight_pending_approval'),
                                  value: '${pendingProviders.length}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AdminPanel(
                            title: t.t('quick_launch_promo'),
                            subtitle: t.t('quick_launch_promo_sub'),
                            child: Column(
                              children: [
                                _QuickActionTile(
                                  icon: Icons.campaign_outlined,
                                  title: t.t('quick_launch_promo'),
                                  subtitle: t.t('quick_launch_promo_sub'),
                                  onTap: () => onNavigate(6),
                                ),
                                const SizedBox(height: 10),
                                _QuickActionTile(
                                  icon: Icons.local_shipping_outlined,
                                  title: t.t('quick_verify_providers'),
                                  subtitle: t.t('quick_verify_providers_sub'),
                                  onTap: () => onNavigate(2),
                                ),
                                const SizedBox(height: 10),
                                _QuickActionTile(
                                  icon: Icons.payments_outlined,
                                  title: t.t('quick_adjust_prices'),
                                  subtitle: t.t('quick_adjust_prices_sub'),
                                  onTap: () => onNavigate(4),
                                ),
                                const SizedBox(height: 10),
                                _QuickActionTile(
                                  icon: Icons.support_agent_outlined,
                                  title: t.t('quick_support_channels'),
                                  subtitle: t.t('quick_support_channels_sub'),
                                  onTap: () => onNavigate(7),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _AdminPanel(
                              title: t.t('insight_mission_load'),
                              subtitle: t.t('insight_mission_load'),
                              child: Column(
                                children: [
                                  _InsightRow(
                                    label: t.t('insight_mission_load'),
                                    value: active == 0
                                        ? t.t('mission_load_low')
                                        : active < 20
                                            ? t.t('mission_load_normal')
                                            : active < 50
                                                ? t.t('mission_load_high')
                                                : t.t('mission_load_critical'),
                                  ),
                                  _InsightRow(
                                    label: t.t('insight_free_providers'),
                                    value: '$freeProviders',
                                  ),
                                  _InsightRow(
                                    label: t.t('insight_cancellations'),
                                    value: '$cancelled',
                                  ),
                                  _InsightRow(
                                    label: t.t('insight_critical_demands'),
                                    value: '$urgent',
                                  ),
                                  _InsightRow(
                                    label: t.t('insight_pending_approval'),
                                    value: '${pendingProviders.length}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: _AdminPanel(
                              title: t.t('quick_launch_promo'),
                              subtitle: t.t('quick_launch_promo_sub'),
                              child: Column(
                                children: [
                                  _QuickActionTile(
                                    icon: Icons.campaign_outlined,
                                    title: t.t('quick_launch_promo'),
                                    subtitle: t.t('quick_launch_promo_sub'),
                                    onTap: () => onNavigate(6),
                                  ),
                                  const SizedBox(height: 10),
                                  _QuickActionTile(
                                    icon: Icons.local_shipping_outlined,
                                    title: t.t('quick_verify_providers'),
                                    subtitle: t.t('quick_verify_providers_sub'),
                                    onTap: () => onNavigate(2),
                                  ),
                                  const SizedBox(height: 10),
                                  _QuickActionTile(
                                    icon: Icons.payments_outlined,
                                    title: t.t('quick_adjust_prices'),
                                    subtitle: t.t('quick_adjust_prices_sub'),
                                    onTap: () => onNavigate(4),
                                  ),
                                  const SizedBox(height: 10),
                                  _QuickActionTile(
                                    icon: Icons.support_agent_outlined,
                                    title: t.t('quick_support_channels'),
                                    subtitle: t.t('quick_support_channels_sub'),
                                    onTap: () => onNavigate(7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, sectionConstraints) {
                        final width = sectionConstraints.maxWidth;
                        final columns =
                            width >= 1180 ? 3 : width >= 760 ? 2 : 1;
                        final itemWidth = columns == 1
                            ? width
                            : (width - ((columns - 1) * 14)) / columns;

                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _AdminPanel(
                                title: t.t('finance_live'),
                                subtitle: t.t('finance_live_sub'),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MiniStat(
                                            label: t.t('avg_ticket'),
                                            value: _formatMoney(averageTicket, t),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _MiniStat(
                                            label: t.t('ca_completed'),
                                            value: _formatMoney(completedRevenue, t),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _InsightRow(
                                      label: t.t('completion_rate'),
                                      value: '${completionRate.toStringAsFixed(0)}%',
                                    ),
                                    _InsightRow(
                                      label: t.t('missions_completed'),
                                      value: '$completed',
                                    ),
                                    _InsightRow(
                                      label: t.t('missions_cancelled'),
                                      value: '$cancelled',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _AdminPanel(
                                title: t.t('provider_control'),
                                subtitle: t.t('provider_control_sub'),
                                child: providerSpotlight.isEmpty
                                    ? Column(
                                        children: [
                                          const _EmptyStateLine(
                                            title: 'no_pending_providers',
                                            subtitle: 'no_pending_providers_sub',
                                          ),
                                          const SizedBox(height: 12),
                                          _QuickActionTile(
                                            icon: Icons.local_shipping_outlined,
                                            title: t.t('open_provider_ops'),
                                            subtitle: t.t('open_provider_ops_sub'),
                                            onTap: () => onNavigate(2),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          ...providerSpotlight.map((providerDoc) {
                                            final data = providerDoc.data();
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: _ProviderApprovalPreview(
                                                name: (data['name'] ?? 'Provider').toString(),
                                                phone: (data['phone'] ?? '--').toString(),
                                                vehicle:
                                                    '${data['vehicleType'] ?? '--'} · ${data['plate'] ?? '--'}',
                                              ),
                                            );
                                          }),
                                          _QuickActionTile(
                                            icon: Icons.verified_user_outlined,
                                            title: t
                                                .t('treat_approval')
                                                .replaceAll('{count}', '${pendingProviders.length}'),
                                            subtitle: t.t('treat_approval_sub'),
                                            onTap: () => onNavigate(2),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _AdminPanel(
                                title: t.t('mission_radar'),
                                subtitle: t.t('mission_radar_sub'),
                                child: spotlightRequests.isEmpty
                                    ? const _EmptyStateLine(
                                        title: 'no_recent_mission',
                                        subtitle: 'no_recent_mission_sub',
                                      )
                                    : Column(
                                        children: spotlightRequests.map((doc) {
                                          final data = doc.data();
                                          final status = (data['status'] ?? 'searching').toString();
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: _MissionRadarTile(
                                              title: (data['customerName'] ?? 'Client').toString(),
                                              pickup: (data['pickupLabel'] ?? 'Point de depart')
                                                  .toString(),
                                              destination: (data['destination'] ?? '--').toString(),
                                              when: _formatWhen(
                                                _toDate(data['updatedAt']) ??
                                                    _toDate(data['createdAt']),
                                                t,
                                              ),
                                              price: _formatMoney(
                                                _toDouble(data['estimatedPrice']),
                                                t,
                                              ),
                                              status: _statusLabel(status, t),
                                              statusColor: _statusColor(status),
                                              pickupLabel: t.t('pick_up'),
                                              destinationLabel: t.t('destination_label'),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _AdminProvidersPage — fully localized
// ═══════════════════════════════════════════════════════════════════
class _AdminProvidersPage extends StatefulWidget {
  const _AdminProvidersPage();

  @override
  State<_AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends State<_AdminProvidersPage> {
  final TextEditingController _searchController = TextEditingController();
  final AdminAuditService _auditService = AdminAuditService();
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setApproval(String uid, bool value) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now().toIso8601String();

    await firestore.collection('providers').doc(uid).set({
      'isApproved': value,
      'updatedAtIso': now,
      'approvalUpdatedAtIso': now,
      if (value) 'approvedAtIso': now,
    }, SetOptions(merge: true));

    await firestore.collection('users').doc(uid).set({
      'isApproved': value,
      'updatedAtIso': now,
      'approvalUpdatedAtIso': now,
      if (value) 'approvedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: value ? 'approve_provider' : 'revoke_provider_approval',
      targetCollection: 'providers',
      targetId: uid,
      summary: value ? 'Approval provider active' : 'Approval provider retiree',
      metadata: {'isApproved': value},
    );
  }

  Future<void> _setBlocked(String uid, bool value) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now().toIso8601String();

    await firestore.collection('providers').doc(uid).set({
      'isBlocked': value,
      if (value) 'isOnline': false,
      'updatedAtIso': now,
      'blockedUpdatedAtIso': now,
      if (value) 'blockedAtIso': now,
      if (!value) 'unblockedAtIso': now,
    }, SetOptions(merge: true));

    await firestore.collection('users').doc(uid).set({
      'isBlocked': value,
      'updatedAtIso': now,
      'blockedUpdatedAtIso': now,
      if (value) 'blockedAtIso': now,
      if (!value) 'unblockedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: value ? 'block_provider' : 'unblock_provider',
      targetCollection: 'providers',
      targetId: uid,
      summary: value ? 'Provider bloque' : 'Provider debloque',
      metadata: {'isBlocked': value},
    );
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final approved = data['isApproved'] == true;
    final online = data['isOnline'] == true;
    final busy = data['isBusy'] == true;
    final blocked = data['isBlocked'] == true;

    switch (_filter) {
      case 'approved':
        return approved;
      case 'pending':
        return !approved;
      case 'online':
        return online;
      case 'busy':
        return busy;
      case 'blocked':
        return blocked;
      default:
        return true;
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (data['fullName'] ?? '').toString().toLowerCase().contains(q) ||
        (data['email'] ?? '').toString().toLowerCase().contains(q) ||
        (data['phone'] ?? '').toString().toLowerCase().contains(q) ||
        (data['plate'] ?? '').toString().toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorPanel(
            title: t('error'),
            subtitle: t('error'),
            details: snapshot.error?.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data();
          return _matchesFilter(data) && _matchesSearch(data);
        }).toList()
          ..sort((a, b) {
            final aOnline = a.data()['isOnline'] == true ? 1 : 0;
            final bOnline = b.data()['isOnline'] == true ? 1 : 0;
            return bOnline.compareTo(aOnline);
          });

        final onlineCount = docs.where((doc) => doc.data()['isOnline'] == true).length;
        final blockedCount = docs.where((doc) => doc.data()['isBlocked'] == true).length;
        final compactStats = MediaQuery.of(context).size.width < 720;

        return ListView(
          children: [
            _AdminPanel(
              title: t('provider_ops_title'),
              subtitle: t('provider_ops_subtitle'),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: t('search_providers'),
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: t('filter_all'),
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _FilterChip(
                        label: t('filter_approved'),
                        selected: _filter == 'approved',
                        onTap: () => setState(() => _filter = 'approved'),
                      ),
                      _FilterChip(
                        label: t('filter_pending'),
                        selected: _filter == 'pending',
                        onTap: () => setState(() => _filter = 'pending'),
                      ),
                      _FilterChip(
                        label: t('filter_online'),
                        selected: _filter == 'online',
                        onTap: () => setState(() => _filter = 'online'),
                      ),
                      _FilterChip(
                        label: t('filter_busy'),
                        selected: _filter == 'busy',
                        onTap: () => setState(() => _filter = 'busy'),
                      ),
                      _FilterChip(
                        label: t('filter_blocked'),
                        selected: _filter == 'blocked',
                        onTap: () => setState(() => _filter = 'blocked'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (compactStats)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: t('result_count'),
                            value: '${filtered.length}',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: t('online_count'),
                            value: '$onlineCount',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: t('blocked_count'),
                            value: '$blockedCount',
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: t('result_count'),
                            value: '${filtered.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: t('online_count'),
                            value: '$onlineCount',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: t('blocked_count'),
                            value: '$blockedCount',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...filtered.map((doc) {
              final data = doc.data();
              final uid = (data['uid'] ?? doc.id).toString();
              final approved = data['isApproved'] == true;
              final online = data['isOnline'] == true;
              final busy = data['isBusy'] == true;
              final blocked = data['isBlocked'] == true;
              final vehicleImageUrl = (data['vehicleImageUrl'] ?? '').toString().trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['fullName'] ?? 'Provider').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (data['email'] ?? '--').toString(),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: approved,
                          onChanged: blocked ? null : (value) => _setApproval(uid, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: approved ? t('status_approved') : t('status_pending'),
                          background: approved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        ),
                        _StatusPill(
                          label: online ? t('status_online') : t('status_offline'),
                          background: online ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                        ),
                        _StatusPill(
                          label: busy ? t('status_busy') : t('status_free'),
                          background: busy ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                        ),
                        if (blocked)
                          _StatusPill(
                            label: t('status_blocked'),
                            background: const Color(0xFFFECACA),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(title: t('phone_label'), value: (data['phone'] ?? '--').toString()),
                    _InfoLine(
                      title: t('vehicle_label'),
                      value: '${data['vehicleType'] ?? '--'} · ${data['plate'] ?? '--'}',
                    ),
                    _InfoLine(
                      title: t('performance_label'),
                      value:
                          '${data['missionsCompleted'] ?? 0} missions · rating ${data['rating'] ?? 5.0}',
                    ),
                    if (vehicleImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          vehicleImageUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              height: 90,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                t('image_unavailable'),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _setApproval(uid, !approved),
                            icon: Icon(
                              approved ? Icons.remove_circle_outline : Icons.verified_outlined,
                            ),
                            label: Text(approved ? t('retirer_approval') : t('approuver')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: blocked ? Colors.green : Colors.red,
                            ),
                            onPressed: () => _setBlocked(uid, !blocked),
                            icon: Icon(blocked ? Icons.lock_open_outlined : Icons.block_outlined),
                            label: Text(blocked ? t('unblock') : t('block')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _AdminCustomersPage — fully localized
// ═══════════════════════════════════════════════════════════════════
class _AdminCustomersPage extends StatefulWidget {
  const _AdminCustomersPage();

  @override
  State<_AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<_AdminCustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  final AdminAuditService _auditService = AdminAuditService();
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setBlocked(String uid, bool value) async {
    final now = DateTime.now().toIso8601String();
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'isBlocked': value,
      'updatedAtIso': now,
      'blockedUpdatedAtIso': now,
      if (value) 'blockedAtIso': now,
      if (!value) 'unblockedAtIso': now,
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: value ? 'block_account' : 'unblock_account',
      targetCollection: 'users',
      targetId: uid,
      summary: value ? 'Client bloque' : 'Client debloque',
      metadata: {'role': 'customer', 'isBlocked': value},
    );
  }

  bool _matches(Map<String, dynamic> data) {
    if ((data['role'] ?? '').toString() != 'customer') return false;
    final blocked = data['isBlocked'] == true;
    switch (_filter) {
      case 'blocked':
        if (!blocked) return false;
        break;
      case 'active':
        if (blocked) return false;
        break;
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    return (data['fullName'] ?? '').toString().toLowerCase().contains(q) ||
        (data['phone'] ?? '').toString().toLowerCase().contains(q) ||
        (data['email'] ?? '').toString().toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorPanel(
            title: t('error'),
            subtitle: t('error'),
            details: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs
                .where((doc) => _matches(doc.data()))
                .toList(growable: false) ??
            [];
        final allCustomers = snapshot.data?.docs
                .where((doc) => (doc.data()['role'] ?? '') == 'customer')
                .toList(growable: false) ??
            [];
        final blockedCount =
            allCustomers.where((doc) => doc.data()['isBlocked'] == true).length;

        return ListView(
          children: [
            _AdminPanel(
              title: t('customer_ops_title'),
              subtitle: t('customer_ops_subtitle'),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: t('search_customers'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: t('filter_all'),
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _FilterChip(
                        label: t('filter_active'),
                        selected: _filter == 'active',
                        onTap: () => setState(() => _filter = 'active'),
                      ),
                      _FilterChip(
                        label: t('filter_blocked'),
                        selected: _filter == 'blocked',
                        onTap: () => setState(() => _filter = 'blocked'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: t('customers_clients'),
                          value: '${allCustomers.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: t('customers_blocked'),
                          value: '$blockedCount',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              _AdminPanel(
                title: t('no_customer'),
                subtitle: t('no_customer_sub'),
                child: const SizedBox.shrink(),
              ),
            ...docs.map((doc) {
              final data = doc.data();
              final uid = doc.id;
              final blocked = data['isBlocked'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: blocked ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
                          child: Text(
                            ((data['fullName'] ?? 'CL')
                                    .toString()
                                    .trim()
                                    .split(' ')
                                    .where((part) => part.isNotEmpty)
                                    .take(2)
                                    .map((part) => part[0].toUpperCase())
                                    .join())
                                .padRight(2, 'C')
                                .substring(0, 2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['fullName'] ?? 'Client').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (data['email'] ?? '--').toString(),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: !blocked,
                          onChanged: (value) => _setBlocked(uid, !value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: blocked ? t('status_blocked') : t('status_online'),
                          background: blocked ? const Color(0xFFFECACA) : const Color(0xFFDCFCE7),
                        ),
                        _StatusPill(
                          label: (data['phone'] ?? '--').toString(),
                          background: const Color(0xFFF1F5F9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(title: t('uid_label'), value: uid),
                    _InfoLine(
                      title: t('created_label'),
                      value: (data['createdAtIso'] ?? '--').toString(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: blocked ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _setBlocked(uid, !blocked),
                        icon: Icon(blocked ? Icons.lock_open_outlined : Icons.block_outlined),
                        label: Text(blocked ? t('unblock_client') : t('block_client')),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sidebar — receives destinations from outside
// ═══════════════════════════════════════════════════════════════════
class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.index,
    required this.onSelect,
    required this.destinations,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<_AdminDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF2563EB),
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Rescue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Premium Admin',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.separated(
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, itemIndex) {
                final item = destinations[itemIndex];
                final selected = itemIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onSelect(itemIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected ? const Color(0xFF0F172A) : Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: selected ? const Color(0xFF0F172A) : Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helper widgets (no changes needed — they receive localized strings)
// ═══════════════════════════════════════════════════════════════════

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateLine extends StatelessWidget {
  const _EmptyStateLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ProviderApprovalPreview extends StatelessWidget {
  const _ProviderApprovalPreview({
    required this.name,
    required this.phone,
    required this.vehicle,
  });

  final String name;
  final String phone;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_search_outlined, color: Color(0xFFEA580C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(phone, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  vehicle,
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionRadarTile extends StatelessWidget {
  const _MissionRadarTile({
    required this.title,
    required this.pickup,
    required this.destination,
    required this.when,
    required this.price,
    required this.status,
    required this.statusColor,
    required this.pickupLabel,
    required this.destinationLabel,
  });

  final String title;
  final String pickup;
  final String destination;
  final String when;
  final String price;
  final String status;
  final Color statusColor;
  final String pickupLabel;
  final String destinationLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$pickupLabel: $pickup',
            style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            '$destinationLabel: $destination',
            style: const TextStyle(color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(when, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminErrorPanel extends StatelessWidget {
  const _AdminErrorPanel({
    required this.title,
    required this.subtitle,
    this.details,
  });

  final String title;
  final String subtitle;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return _AdminPanel(
      title: title,
      subtitle: subtitle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          (details == null || details!.trim().isEmpty) ? t('admin_error_default') : details!,
          style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600, height: 1.35),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? Colors.white : const Color(0xFF0F172A),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: const Color(0xFF0F172A),
      side: BorderSide.none,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}