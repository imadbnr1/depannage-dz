import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../models/support_config.dart';
import '../../shared/pages/legal_page.dart';

class ProviderSupportPage extends StatelessWidget {
  const ProviderSupportPage({super.key});

  Future<SupportConfig> _loadConfig() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('support')
        .get();

    return SupportConfig.fromMap(doc.data());
  }

  Future<void> _openPhone(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    await launchUrl(Uri.parse('tel:$cleaned'));
  }

  Future<void> _openWhatsapp(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    final normalized = cleaned.replaceAll('+', '').replaceAll(' ', '');
    await launchUrl(
      Uri.parse('https://wa.me/$normalized'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _openEmail(String email) async {
    final cleaned = email.trim();
    if (cleaned.isEmpty) return;
    await launchUrl(Uri.parse('mailto:$cleaned'));
  }

  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalPage(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<SupportConfig>(
      future: _loadConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ??
            const SupportConfig(
              phone: '',
              whatsapp: '',
              email: '',
              address: '',
              hours: '',
            );

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFCF8),
                      Color(0xFFF7F0E5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8E1D5)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent,
                      size: 56,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.t('support_provider_title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('support_provider_subtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SupportTile(
                icon: Icons.call_outlined,
                title: strings.t('telephone'),
                value: config.phone.isEmpty
                    ? strings.t('not_filled')
                    : config.phone,
                onTap: config.phone.isEmpty
                    ? null
                    : () => _openPhone(config.phone),
              ),
              _SupportTile(
                icon: Icons.message_outlined,
                title: strings.t('whatsapp'),
                value: config.whatsapp.isEmpty
                    ? strings.t('not_filled')
                    : config.whatsapp,
                onTap: config.whatsapp.isEmpty
                    ? null
                    : () => _openWhatsapp(config.whatsapp),
              ),
              _SupportTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: config.email.isEmpty
                    ? strings.t('not_filled')
                    : config.email,
                onTap: config.email.isEmpty
                    ? null
                    : () => _openEmail(config.email),
              ),
              _SupportTile(
                icon: Icons.location_on_outlined,
                title: strings.t('adresse'),
                value: config.address.isEmpty
                    ? strings.t('not_filled_f')
                    : config.address,
              ),
              _SupportTile(
                icon: Icons.schedule_outlined,
                title: strings.t('horaires'),
                value: config.hours.isEmpty
                    ? strings.t('not_filled_p')
                    : config.hours,
              ),
              _SupportTile(
                icon: Icons.privacy_tip_outlined,
                title: strings.t('confidentialite'),
                value: strings.t('privacy_support_value'),
                onTap: () => _openLegal(context, LegalDocument.privacy),
              ),
              _SupportTile(
                icon: Icons.description_outlined,
                title: strings.t('conditions'),
                value: strings.t('terms_support_value'),
                onTap: () => _openLegal(context, LegalDocument.terms),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFECFDF5),
          child: Icon(icon, color: const Color(0xFF059669)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(value),
        trailing: onTap != null
            ? const Icon(Icons.open_in_new_outlined, size: 18)
            : null,
      ),
    );
  }
}
