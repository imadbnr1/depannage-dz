import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    const pages = [
      _AdminOverviewPage(),
      AdminRequestsPage(),
      _AdminProvidersPage(),
      AdminPricingPage(),
      AdminAnalyticsPage(),
      AdminNotificationsPage(),
      AdminSupportConfigPage(),
    ];

    const titles = [
      'Admin Overview',
      'Demandes',
      'Providers',
      'Tarification',
      'Analytics',
      'Notifications',
      'Support',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Deconnexion',
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Demandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Providers',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Prix',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Notif',
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

class _AdminOverviewPage extends StatelessWidget {
  const _AdminOverviewPage();

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
                if (requestsSnapshot.connectionState == ConnectionState.waiting ||
                    providersSnapshot.connectionState == ConnectionState.waiting ||
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
                  final s = (d.data()['status'] ?? '').toString();
                  return s == 'accepted' ||
                      s == 'onTheWay' ||
                      s == 'arrived' ||
                      s == 'inService';
                }).length;

                final completed = requests
                    .where((d) => (d.data()['status'] ?? '') == 'completed')
                    .length;

                final cancelled = requests
                    .where((d) => (d.data()['status'] ?? '') == 'cancelled')
                    .length;

                final onlineProviders = providers
                    .where((d) => d.data()['isOnline'] == true)
                    .length;

                final busyProviders = providers
                    .where((d) => d.data()['isBusy'] == true)
                    .length;

                final approvedProviders = providers
                    .where((d) => d.data()['isApproved'] == true)
                    .length;

                final pendingProviders = providers
                    .where((d) => d.data()['isApproved'] != true)
                    .length;

                final customers = users
                    .where((d) => (d.data()['role'] ?? '') == 'customer')
                    .length;

                final providerUsers = users
                    .where((d) => (d.data()['role'] ?? '') == 'provider')
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Vue globale',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                      children: [
                        _StatCard(
                          title: 'Demandes recherche',
                          value: '$searching',
                          icon: Icons.search,
                        ),
                        _StatCard(
                          title: 'Demandes actives',
                          value: '$active',
                          icon: Icons.local_shipping_outlined,
                        ),
                        _StatCard(
                          title: 'Demandes terminees',
                          value: '$completed',
                          icon: Icons.check_circle_outline,
                        ),
                        _StatCard(
                          title: 'Demandes annulees',
                          value: '$cancelled',
                          icon: Icons.cancel_outlined,
                        ),
                        _StatCard(
                          title: 'Providers en ligne',
                          value: '$onlineProviders',
                          icon: Icons.wifi_tethering,
                        ),
                        _StatCard(
                          title: 'Providers occupes',
                          value: '$busyProviders',
                          icon: Icons.engineering_outlined,
                        ),
                        _StatCard(
                          title: 'Providers approuves',
                          value: '$approvedProviders',
                          icon: Icons.verified_outlined,
                        ),
                        _StatCard(
                          title: 'Providers en attente',
                          value: '$pendingProviders',
                          icon: Icons.hourglass_top_outlined,
                        ),
                        _StatCard(
                          title: 'Clients',
                          value: '$customers',
                          icon: Icons.people_outline,
                        ),
                        _StatCard(
                          title: 'Comptes provider',
                          value: '$providerUsers',
                          icon: Icons.manage_accounts_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lecture rapide',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _QuickInfoRow(
                            label: 'Charge active',
                            value: active == 0
                                ? 'Faible'
                                : active < 20
                                    ? 'Normale'
                                    : active < 50
                                        ? 'Elevee'
                                        : 'Tres elevee',
                          ),
                          _QuickInfoRow(
                            label: 'Disponibilite providers',
                            value: onlineProviders == 0
                                ? 'Aucun provider en ligne'
                                : '${onlineProviders - busyProviders < 0 ? 0 : onlineProviders - busyProviders} libres',
                          ),
                          _QuickInfoRow(
                            label: 'Validation providers',
                            value: '$pendingProviders en attente',
                          ),
                          _QuickInfoRow(
                            label: 'Suivi support',
                            value: 'Gerable depuis l onglet Support',
                          ),
                        ],
                      ),
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
  String _filter = 'all';

  Future<void> _setApproval(String uid, bool value) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('providers').doc(uid).set({
      'isApproved': value,
    }, SetOptions(merge: true));

    await firestore.collection('users').doc(uid).set({
      'isApproved': value,
    }, SetOptions(merge: true));
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final approved = data['isApproved'] == true;
    final online = data['isOnline'] == true;
    final busy = data['isBusy'] == true;

    switch (_filter) {
      case 'approved':
        return approved;
      case 'pending':
        return !approved;
      case 'online':
        return online;
      case 'busy':
        return busy;
      default:
        return true;
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final fullName = (data['fullName'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();
    final phone = (data['phone'] ?? '').toString().toLowerCase();
    final plate = (data['plate'] ?? '').toString().toLowerCase();

    return fullName.contains(q) ||
        email.contains(q) ||
        phone.contains(q) ||
        plate.contains(q);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filter = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher provider, email, telephone, plaque...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
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
                _filterChip('all', 'Tous'),
                _filterChip('approved', 'Approuves'),
                _filterChip('pending', 'En attente'),
                _filterChip('online', 'En ligne'),
                _filterChip('busy', 'Occupes'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${filtered.length} provider(s)',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Aucun provider pour ce filtre'),
                ),
              ),
            ...filtered.map((doc) {
              final data = doc.data();
              final uid = (data['uid'] ?? doc.id).toString();
              final approved = data['isApproved'] == true;
              final online = data['isOnline'] == true;
              final busy = data['isBusy'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (data['fullName'] ?? 'Provider').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Switch(
                          value: approved,
                          onChanged: (value) => _setApproval(uid, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          label: approved ? 'Approuve' : 'En attente',
                          color: approved
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                        ),
                        _StatusChip(
                          label: online ? 'En ligne' : 'Hors ligne',
                          color: online
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFF3F4F6),
                        ),
                        _StatusChip(
                          label: busy ? 'Occupe' : 'Libre',
                          color: busy
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFECFDF5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (data['email'] ?? '--').toString(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (data['phone'] ?? '--').toString(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vehicule: ${(data['vehicleType'] ?? '--')} · ${(data['plate'] ?? '--')}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Missions: ${(data['missionsCompleted'] ?? 0)} · Rating: ${(data['rating'] ?? 5.0)}',
                      style: const TextStyle(color: Colors.black54),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
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

class _QuickInfoRow extends StatelessWidget {
  const _QuickInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}