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
    final title =
        isPrivacy ? 'Politique de confidentialite' : 'Conditions d utilisation';
    final icon =
        isPrivacy ? Icons.privacy_tip_outlined : Icons.description_outlined;
    final sections = isPrivacy ? _privacySections : _termsSections;

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
                        const Text(
                          'Version projet de graduation. A valider juridiquement avant une exploitation commerciale.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
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
                title: section.title,
                body: section.body,
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
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

const _privacySections = [
  _LegalText(
    title: 'Donnees collectees',
    body:
        'Depaniny peut collecter le nom, le telephone, l email, le role utilisateur, les informations de vehicule, la position GPS, les demandes de mission, les messages de support, les notes et les avis.',
  ),
  _LegalText(
    title: 'Utilisation des donnees',
    body:
        'Ces donnees servent a creer les comptes, proposer des missions, calculer les routes, suivre le provider en temps reel, envoyer des notifications, assurer le support et permettre le controle admin.',
  ),
  _LegalText(
    title: 'Position et notifications',
    body:
        'La position est utilisee pour trouver le client, afficher la route et suivre la mission. Les notifications servent aux alertes de mission, messages importants et annonces administrateur.',
  ),
  _LegalText(
    title: 'Securite',
    body:
        'Les acces sont separes entre customer, provider et admin. Les donnees doivent etre protegees par Firebase Authentication, Firestore Rules et des comptes admin controles.',
  ),
  _LegalText(
    title: 'Contact',
    body:
        'Pour toute demande liee aux donnees ou au support, utilisez la page Support de l application ou l email configure par l administrateur.',
  ),
];

const _termsSections = [
  _LegalText(
    title: 'Objet du service',
    body:
        'Depaniny met en relation des customers ayant besoin d assistance routiere avec des providers disponibles, sous supervision administrative.',
  ),
  _LegalText(
    title: 'Responsabilites utilisateur',
    body:
        'L utilisateur doit fournir des informations exactes, respecter les autres utilisateurs, utiliser l application legalement et ne pas tenter d acceder aux espaces reserves.',
  ),
  _LegalText(
    title: 'Providers',
    body:
        'Les providers doivent etre approuves par l administrateur, maintenir leurs informations a jour et respecter les missions acceptees.',
  ),
  _LegalText(
    title: 'Prix et frais',
    body:
        'Les prix peuvent inclure le service, la distance, les frais d acces du provider et les parametres definis par l administrateur.',
  ),
  _LegalText(
    title: 'Limites',
    body:
        'Cette version est preparee pour un projet de graduation. Avant un lancement commercial, il faut finaliser les validations legales, securite, assurance et conditions de paiement.',
  ),
];
