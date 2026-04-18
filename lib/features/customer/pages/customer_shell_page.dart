import 'package:flutter/material.dart';

import '../../../core/services/fcm_service.dart';
import '../../../state/app_store.dart';
import '../../shared/pages/chat_page.dart';
import 'customer_history_page.dart';
import 'customer_home_page.dart';
import 'customer_profile_page.dart';
import 'customer_requests_page.dart';
import 'customer_support_page.dart';

class CustomerShellPage extends StatefulWidget {
  const CustomerShellPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<CustomerShellPage> createState() => _CustomerShellPageState();
}

class _CustomerShellPageState extends State<CustomerShellPage> {
  int _index = 0;
  String? _lastFcmSignature;

  @override
  void initState() {
    super.initState();
    _index = widget.store.customerTab;
    widget.store.addListener(_onStoreChanged);
    FcmService.payloadNotifier.addListener(_onFcmPayload);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    FcmService.payloadNotifier.removeListener(_onFcmPayload);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    if (widget.store.customerTab != _index) {
      _index = widget.store.customerTab;
    }
    setState(() {});
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

      if (type == 'chat' && requestId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              requestId: requestId,
              title: 'Chat provider',
            ),
          ),
        );
      }

      FcmService.clearPayload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerHomePage(store: widget.store),
      CustomerRequestsPage(store: widget.store),
      CustomerHistoryPage(store: widget.store),
      const CustomerProfilePage(),
      const CustomerSupportPage(),
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
          widget.store.setCustomerTab(value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Demandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
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
