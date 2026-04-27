import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/admin_audit_service.dart';
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

  static const _destinations = [
    _AdminDestination(
      label: 'Command',
      title: 'Command Center',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    _AdminDestination(
      label: 'Demandes',
      title: 'Mission Control',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _AdminDestination(
      label: 'Providers',
      title: 'Provider Ops',
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
    ),
    _AdminDestination(
      label: 'Clients',
      title: 'Customer Ops',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    _AdminDestination(
      label: 'Tarifs',
      title: 'Pricing Lab',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
    _AdminDestination(
      label: 'Analytics',
      title: 'Revenue Pulse',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
    ),
    _AdminDestination(
      label: 'Notif',
      title: 'Broadcast Studio',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    _AdminDestination(
      label: 'Support',
      title: 'Support Control',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
    ),
    _AdminDestination(
      label: 'Logs',
      title: 'Activity Log',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
    final current = _destinations[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;

            return Row(
              children: [
                if (wide) _AdminSidebar(index: _index, onSelect: _onSelect),
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
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
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
                                          : (constraints.maxWidth - 110).clamp(
                                              220.0,
                                              620.0,
                                            ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            current.title,
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pilotage en temps reel, operations plus rapides, controles admin renforces.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF8FAFC),
                                        foregroundColor:
                                            const Color(0xFF0F172A),
                                      ),
                                      onPressed: () async {
                                        await AuthService().signOut();
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Deconnexion'),
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
                                      itemCount: _destinations.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        final item = _destinations[index];
                                        final selected = index == _index;
                                        return ChoiceChip(
                                          label: Text(item.label),
                                          selected: selected,
                                          onSelected: (_) => _onSelect(index),
                                          avatar: Icon(
                                            selected
                                                ? item.selectedIcon
                                                : item.icon,
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
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.08),
                                          selectedColor:
                                              const Color(0xFFF8FAFC),
                                          side: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
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
              destinations: _destinations
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

class _AdminOverviewPage extends StatelessWidget {
  const _AdminOverviewPage({
    required this.onNavigate,
  });

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

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptee';
      case 'onTheWay':
        return 'En route';
      case 'arrived':
        return 'Arrivee';
      case 'inService':
        return 'En service';
      case 'completed':
        return 'Terminee';
      case 'cancelled':
        return 'Annulee';
      default:
        return 'Recherche';
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

  String _formatMoney(double value) => '${value.toStringAsFixed(0)} DA';

  String _formatWhen(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) {
      return 'Aujourd hui $hh:$mm';
    }
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd/$mo $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
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
                    title: 'Dashboard indisponible',
                    subtitle:
                        'Les donnees admin n ont pas pu charger. Verifiez les regles Firestore, les index ou la connexion.',
                    details: [
                      requestsSnapshot.error,
                      providersSnapshot.error,
                      usersSnapshot.error,
                    ].whereType<Object>().join('\n'),
                  );
                }

                if (requestsSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    providersSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    usersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = requestsSnapshot.data?.docs ?? [];
                final providers = providersSnapshot.data?.docs ?? [];
                final users = usersSnapshot.data?.docs ?? [];

                final searching = requests
                    .where((d) => (d.data()['status'] ?? '') == 'searching')
                    .length;
                final active = requests.where((d) {
                  final status = (d.data()['status'] ?? '').toString();
                  return status == 'accepted' ||
                      status == 'onTheWay' ||
                      status == 'arrived' ||
                      status == 'inService';
                }).length;
                final completed = requests
                    .where((d) => (d.data()['status'] ?? '') == 'completed')
                    .length;
                final cancelled = requests
                    .where((d) => (d.data()['status'] ?? '') == 'cancelled')
                    .length;
                final urgent = requests.where((d) {
                  final urgency =
                      (d.data()['urgency'] ?? '').toString().toLowerCase();
                  return urgency.contains('urgent') || urgency.contains('crit');
                }).length;

                final onlineProviders =
                    providers.where((d) => d.data()['isOnline'] == true).length;
                final busyProviders =
                    providers.where((d) => d.data()['isBusy'] == true).length;
                final approvedProviders = providers
                    .where((d) => d.data()['isApproved'] == true)
                    .length;
                final pendingProviders = providers.where((d) {
                  final data = d.data();
                  return data['isApproved'] != true &&
                      data['isBlocked'] != true;
                }).toList();
                final blockedProviders = providers
                    .where((d) => d.data()['isBlocked'] == true)
                    .length;

                final customers = users
                    .where((d) => (d.data()['role'] ?? '') == 'customer')
                    .length;
                final providerUsers = users
                    .where((d) => (d.data()['role'] ?? '') == 'provider')
                    .length;
                final freeProviders = onlineProviders - busyProviders < 0
                    ? 0
                    : onlineProviders - busyProviders;
                final completedRevenue = requests
                    .where((d) => (d.data()['status'] ?? '') == 'completed')
                    .fold<double>(
                      0,
                      (total, doc) =>
                          total + _toDouble(doc.data()['estimatedPrice']),
                    );
                final averageTicket =
                    completed == 0 ? 0.0 : completedRevenue / completed;
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
                final spotlightRequests =
                    recentRequests.take(4).toList(growable: false);
                final providerSpotlight =
                    pendingProviders.take(3).toList(growable: false);
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
                          title: 'Recherche',
                          value: '$searching',
                          subtitle: 'Missions sans provider',
                          accent: const Color(0xFFEA580C),
                          icon: Icons.radar_outlined,
                          onTap: () => onNavigate(1),
                        ),
                        _KpiCard(
                          title: 'Actives',
                          value: '$active',
                          subtitle: 'Suivis en direct',
                          accent: const Color(0xFF2563EB),
                          icon: Icons.route_outlined,
                          onTap: () => onNavigate(1),
                        ),
                        _KpiCard(
                          title: 'Terminees',
                          value: '$completed',
                          subtitle: 'Missions bouclees',
                          accent: const Color(0xFF16A34A),
                          icon: Icons.verified_outlined,
                          onTap: () => onNavigate(5),
                        ),
                        _KpiCard(
                          title: 'Urgentes',
                          value: '$urgent',
                          subtitle: 'A surveiller maintenant',
                          accent: const Color(0xFFDC2626),
                          icon: Icons.priority_high_outlined,
                          onTap: () => onNavigate(1),
                        ),
                        _KpiCard(
                          title: 'Providers ON',
                          value: '$onlineProviders',
                          subtitle: '$busyProviders occupes',
                          accent: const Color(0xFF0EA5E9),
                          icon: Icons.wifi_tethering_outlined,
                          onTap: () => onNavigate(2),
                        ),
                        _KpiCard(
                          title: 'Approuves',
                          value: '$approvedProviders',
                          subtitle: '$blockedProviders bloques',
                          accent: const Color(0xFF7C3AED),
                          icon: Icons.verified_user_outlined,
                          onTap: () => onNavigate(2),
                        ),
                        _KpiCard(
                          title: 'Clients',
                          value: '$customers',
                          subtitle: 'Base utilisateur',
                          accent: const Color(0xFF0891B2),
                          icon: Icons.people_alt_outlined,
                          onTap: () => onNavigate(3),
                        ),
                        _KpiCard(
                          title: 'Providers',
                          value: '$providerUsers',
                          subtitle: 'Comptes metier',
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
                            title: 'Lecture rapide',
                            subtitle:
                                'Signal instantane sur la sante des operations.',
                            child: Column(
                              children: [
                                _InsightRow(
                                  label: 'Charge mission',
                                  value: active == 0
                                      ? 'Faible'
                                      : active < 20
                                          ? 'Normale'
                                          : active < 50
                                              ? 'Elevee'
                                              : 'Critique',
                                ),
                                _InsightRow(
                                  label: 'Providers libres',
                                  value: '$freeProviders',
                                ),
                                _InsightRow(
                                  label: 'Annulations',
                                  value: '$cancelled',
                                ),
                                _InsightRow(
                                  label: 'Demandes critiques',
                                  value: '$urgent',
                                ),
                                _InsightRow(
                                  label: 'Approval en attente',
                                  value: '${pendingProviders.length}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AdminPanel(
                            title: 'Actions rapides',
                            subtitle:
                                'Pilotage plus direct pour les cas chauds.',
                            child: Column(
                              children: [
                                _QuickActionTile(
                                  icon: Icons.campaign_outlined,
                                  title: 'Lancer une promo',
                                  subtitle:
                                      'Envoyer une offre live avec image et popup.',
                                  onTap: () => onNavigate(6),
                                ),
                                const SizedBox(height: 10),
                                _QuickActionTile(
                                  icon: Icons.local_shipping_outlined,
                                  title: 'Verifier les providers',
                                  subtitle:
                                      'Valider, bloquer ou filtrer les comptes actifs.',
                                  onTap: () => onNavigate(2),
                                ),
                                const SizedBox(height: 10),
                                _QuickActionTile(
                                  icon: Icons.payments_outlined,
                                  title: 'Ajuster les prix',
                                  subtitle:
                                      'Reagir vite a la demande ou a la distance.',
                                  onTap: () => onNavigate(4),
                                ),
                                const SizedBox(height: 10),
                                _QuickActionTile(
                                  icon: Icons.support_agent_outlined,
                                  title: 'Support & canaux',
                                  subtitle:
                                      'Mettre a jour l aide visible partout dans l app.',
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
                              title: 'Lecture rapide',
                              subtitle:
                                  'Signal instantane sur la sante des operations.',
                              child: Column(
                                children: [
                                  _InsightRow(
                                    label: 'Charge mission',
                                    value: active == 0
                                        ? 'Faible'
                                        : active < 20
                                            ? 'Normale'
                                            : active < 50
                                                ? 'Elevee'
                                                : 'Critique',
                                  ),
                                  _InsightRow(
                                    label: 'Providers libres',
                                    value: '$freeProviders',
                                  ),
                                  _InsightRow(
                                    label: 'Annulations',
                                    value: '$cancelled',
                                  ),
                                  _InsightRow(
                                    label: 'Demandes critiques',
                                    value: '$urgent',
                                  ),
                                  _InsightRow(
                                    label: 'Approval en attente',
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
                              title: 'Actions rapides',
                              subtitle:
                                  'Pilotage plus direct pour les cas chauds.',
                              child: Column(
                                children: [
                                  _QuickActionTile(
                                    icon: Icons.campaign_outlined,
                                    title: 'Lancer une promo',
                                    subtitle:
                                        'Envoyer une offre live avec image et popup.',
                                    onTap: () => onNavigate(6),
                                  ),
                                  const SizedBox(height: 10),
                                  _QuickActionTile(
                                    icon: Icons.local_shipping_outlined,
                                    title: 'Verifier les providers',
                                    subtitle:
                                        'Valider, bloquer ou filtrer les comptes actifs.',
                                    onTap: () => onNavigate(2),
                                  ),
                                  const SizedBox(height: 10),
                                  _QuickActionTile(
                                    icon: Icons.payments_outlined,
                                    title: 'Ajuster les prix',
                                    subtitle:
                                        'Reagir vite a la demande ou a la distance.',
                                    onTap: () => onNavigate(4),
                                  ),
                                  const SizedBox(height: 10),
                                  _QuickActionTile(
                                    icon: Icons.support_agent_outlined,
                                    title: 'Support & canaux',
                                    subtitle:
                                        'Mettre a jour l aide visible partout dans l app.',
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
                        final columns = width >= 1180
                            ? 3
                            : width >= 760
                                ? 2
                                : 1;
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
                                title: 'Finance live',
                                subtitle:
                                    'Lecture directe du revenu missions et du rendement plateforme.',
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MiniStat(
                                            label: 'Ticket moyen',
                                            value: _formatMoney(averageTicket),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _MiniStat(
                                            label: 'CA termine',
                                            value:
                                                _formatMoney(completedRevenue),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _InsightRow(
                                      label: 'Taux completion',
                                      value:
                                          '${completionRate.toStringAsFixed(0)}%',
                                    ),
                                    _InsightRow(
                                      label: 'Missions terminees',
                                      value: '$completed',
                                    ),
                                    _InsightRow(
                                      label: 'Missions annulees',
                                      value: '$cancelled',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _AdminPanel(
                                title: 'Provider control',
                                subtitle:
                                    'Surveillez les validations et les comptes a traiter en priorite.',
                                child: providerSpotlight.isEmpty
                                    ? Column(
                                        children: [
                                          const _EmptyStateLine(
                                            title: 'Aucun provider en attente',
                                            subtitle:
                                                'Tous les comptes sont traites pour le moment.',
                                          ),
                                          const SizedBox(height: 12),
                                          _QuickActionTile(
                                            icon: Icons.local_shipping_outlined,
                                            title: 'Ouvrir Provider Ops',
                                            subtitle:
                                                'Verifier les comptes, approvals et blocages.',
                                            onTap: () => onNavigate(2),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          ...providerSpotlight
                                              .map((providerDoc) {
                                            final data = providerDoc.data();
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: _ProviderApprovalPreview(
                                                name:
                                                    (data['name'] ?? 'Provider')
                                                        .toString(),
                                                phone: (data['phone'] ?? '--')
                                                    .toString(),
                                                vehicle:
                                                    '${data['vehicleType'] ?? '--'} · ${data['plate'] ?? '--'}',
                                              ),
                                            );
                                          }),
                                          _QuickActionTile(
                                            icon: Icons.verified_user_outlined,
                                            title:
                                                'Traiter ${pendingProviders.length} approval(s)',
                                            subtitle:
                                                'Acceder directement au centre de verification.',
                                            onTap: () => onNavigate(2),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _AdminPanel(
                                title: 'Mission radar',
                                subtitle:
                                    'Les dernieres missions pour voir ce qui se passe maintenant.',
                                child: spotlightRequests.isEmpty
                                    ? const _EmptyStateLine(
                                        title: 'Aucune mission recente',
                                        subtitle:
                                            'Les nouvelles missions apparaitront ici en direct.',
                                      )
                                    : Column(
                                        children: spotlightRequests.map((doc) {
                                          final data = doc.data();
                                          final status =
                                              (data['status'] ?? 'searching')
                                                  .toString();
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: _MissionRadarTile(
                                              title: (data['customerName'] ??
                                                      'Client')
                                                  .toString(),
                                              pickup: (data['pickupLabel'] ??
                                                      'Point de depart')
                                                  .toString(),
                                              destination:
                                                  (data['destination'] ?? '--')
                                                      .toString(),
                                              when: _formatWhen(
                                                _toDate(data['updatedAt']) ??
                                                    _toDate(data['createdAt']),
                                              ),
                                              price: _formatMoney(
                                                _toDouble(
                                                  data['estimatedPrice'],
                                                ),
                                              ),
                                              status: _statusLabel(status),
                                              statusColor: _statusColor(status),
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
      metadata: {
        'isApproved': value,
      },
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
      metadata: {
        'isBlocked': value,
      },
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorPanel(
            title: 'Providers indisponibles',
            subtitle:
                'La liste providers n a pas pu etre chargee. Verifiez les permissions admin et la connexion.',
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

        final onlineCount =
            docs.where((doc) => doc.data()['isOnline'] == true).length;
        final blockedCount =
            docs.where((doc) => doc.data()['isBlocked'] == true).length;
        final compactStats = MediaQuery.of(context).size.width < 720;

        return ListView(
          children: [
            _AdminPanel(
              title: 'Provider ops',
              subtitle:
                  'Filtrer rapidement, approuver plus vite, couper les comptes a risque.',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Rechercher nom, email, telephone, plaque...',
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
                        label: 'Tous',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _FilterChip(
                        label: 'Approuves',
                        selected: _filter == 'approved',
                        onTap: () => setState(() => _filter = 'approved'),
                      ),
                      _FilterChip(
                        label: 'En attente',
                        selected: _filter == 'pending',
                        onTap: () => setState(() => _filter = 'pending'),
                      ),
                      _FilterChip(
                        label: 'En ligne',
                        selected: _filter == 'online',
                        onTap: () => setState(() => _filter = 'online'),
                      ),
                      _FilterChip(
                        label: 'Occupes',
                        selected: _filter == 'busy',
                        onTap: () => setState(() => _filter = 'busy'),
                      ),
                      _FilterChip(
                        label: 'Bloques',
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
                            label: 'Resultats',
                            value: '${filtered.length}',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: 'Online',
                            value: '$onlineCount',
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _MiniStat(
                            label: 'Bloques',
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
                            label: 'Resultats',
                            value: '${filtered.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: 'Online',
                            value: '$onlineCount',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            label: 'Bloques',
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
              final vehicleImageUrl =
                  (data['vehicleImageUrl'] ?? '').toString().trim();

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
                          onChanged: blocked
                              ? null
                              : (value) => _setApproval(uid, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: approved ? 'Approuve' : 'En attente',
                          background: approved
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                        ),
                        _StatusPill(
                          label: online ? 'En ligne' : 'Hors ligne',
                          background: online
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFF1F5F9),
                        ),
                        _StatusPill(
                          label: busy ? 'Occupe' : 'Libre',
                          background: busy
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFECFDF5),
                        ),
                        if (blocked)
                          const _StatusPill(
                            label: 'Bloque',
                            background: Color(0xFFFECACA),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(
                      title: 'Telephone',
                      value: (data['phone'] ?? '--').toString(),
                    ),
                    _InfoLine(
                      title: 'Vehicule',
                      value:
                          '${data['vehicleType'] ?? '--'} · ${data['plate'] ?? '--'}',
                    ),
                    _InfoLine(
                      title: 'Performance',
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
                              child: const Text(
                                'Image vehicule indisponible',
                                style: TextStyle(color: Colors.black54),
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
                              approved
                                  ? Icons.remove_circle_outline
                                  : Icons.verified_outlined,
                            ),
                            label: Text(
                              approved ? 'Retirer approval' : 'Approuver',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  blocked ? Colors.green : Colors.red,
                            ),
                            onPressed: () => _setBlocked(uid, !blocked),
                            icon: Icon(
                              blocked
                                  ? Icons.lock_open_outlined
                                  : Icons.block_outlined,
                            ),
                            label: Text(blocked ? 'Debloquer' : 'Bloquer'),
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
      metadata: {
        'role': 'customer',
        'isBlocked': value,
      },
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorPanel(
            title: 'Customers indisponibles',
            subtitle:
                'La vue clients n a pas pu etre chargee. Verifiez les permissions admin et la connexion.',
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
              title: 'Customer Ops',
              subtitle:
                  'Gardez la main sur la base client, les blocages et les comptes sensibles.',
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher nom, telephone ou email...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _FilterChip(
                        label: 'Actifs',
                        selected: _filter == 'active',
                        onTap: () => setState(() => _filter = 'active'),
                      ),
                      _FilterChip(
                        label: 'Bloques',
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
                          label: 'Clients',
                          value: '${allCustomers.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Bloques',
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
              const _AdminPanel(
                title: 'Aucun client',
                subtitle:
                    'Ajustez les filtres ou attendez de nouvelles inscriptions.',
                child: SizedBox.shrink(),
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
                          backgroundColor: blocked
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDBEAFE),
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
                          label: blocked ? 'Bloque' : 'Actif',
                          background: blocked
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFDCFCE7),
                        ),
                        _StatusPill(
                          label: (data['phone'] ?? '--').toString(),
                          background: const Color(0xFFF1F5F9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(
                      title: 'UID',
                      value: uid,
                    ),
                    _InfoLine(
                      title: 'Cree',
                      value: (data['createdAtIso'] ?? '--').toString(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: blocked
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _setBlocked(uid, !blocked),
                        icon: Icon(
                          blocked
                              ? Icons.lock_open_outlined
                              : Icons.block_outlined,
                        ),
                        label: Text(
                            blocked ? 'Debloquer client' : 'Bloquer client'),
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

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.index,
    required this.onSelect,
  });

  final int index;
  final ValueChanged<int> onSelect;

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
                        'Depaniny',
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
              itemCount: _AdminDashboardPageState._destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, itemIndex) {
                final item = _AdminDashboardPageState._destinations[itemIndex];
                final selected = itemIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onSelect(itemIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
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
                          color:
                              selected ? const Color(0xFF0F172A) : Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
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
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.35,
            ),
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
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
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
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF64748B),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateLine extends StatelessWidget {
  const _EmptyStateLine({
    required this.title,
    required this.subtitle,
  });

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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.35,
            ),
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
            child: const Icon(
              Icons.person_search_outlined,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
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
  });

  final String title;
  final String pickup;
  final String destination;
  final String when;
  final String price;
  final String status;
  final Color statusColor;

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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pick up: $pickup',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Destination: $destination',
            style: const TextStyle(color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  when,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
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
          (details == null || details!.trim().isEmpty)
              ? 'Aucun detail supplementaire disponible.'
              : details!,
          style: const TextStyle(
            color: Color(0xFF991B1B),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
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
  const _MiniStat({
    required this.label,
    required this.value,
  });

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
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
  });

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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
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
