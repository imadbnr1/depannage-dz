import 'package:auto_rescue/core/i18n/app_localizations.dart';
import 'package:flutter/material.dart';

enum LegalDocument {
  privacy,
  terms,
}

class LegalPage extends StatelessWidget {
  const LegalPage({
    super.key,
    required this.document,
  });

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == LegalDocument.privacy;
    final title = isPrivacy
        ? AppLocalizations.of(context).t('privacy_policy')
        : AppLocalizations.of(context).t('terms_of_use');
    final icon =
        isPrivacy ? Icons.privacy_tip_outlined : Icons.description_outlined;
    final sections = isPrivacy ? _privacySections : _termsSections;
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.t('graduation_project_legal_notice'),
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final section in sections)
              _LegalSection(
                title: strings.t(section.titleKey),
                body: strings.t(section.bodyKey),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalText {
  const _LegalText({
    required this.titleKey,
    required this.bodyKey,
  });

  final String titleKey;
  final String bodyKey;
}

const _privacySections = [
  _LegalText(
    titleKey: 'privacy_collect_title',
    bodyKey: 'privacy_collect_body',
  ),
  _LegalText(
    titleKey: 'privacy_use_title',
    bodyKey: 'privacy_use_body',
  ),
  _LegalText(
    titleKey: 'privacy_location_title',
    bodyKey: 'privacy_location_body',
  ),
  _LegalText(
    titleKey: 'privacy_security_title',
    bodyKey: 'privacy_security_body',
  ),
  _LegalText(
    titleKey: 'privacy_contact_title',
    bodyKey: 'privacy_contact_body',
  ),
];

const _termsSections = [
  _LegalText(
    titleKey: 'terms_service_title',
    bodyKey: 'terms_service_body',
  ),
  _LegalText(
    titleKey: 'terms_user_title',
    bodyKey: 'terms_user_body',
  ),
  _LegalText(
    titleKey: 'terms_providers_title',
    bodyKey: 'terms_providers_body',
  ),
  _LegalText(
    titleKey: 'terms_prices_title',
    bodyKey: 'terms_prices_body',
  ),
  _LegalText(
    titleKey: 'terms_limits_title',
    bodyKey: 'terms_limits_body',
  ),
];
