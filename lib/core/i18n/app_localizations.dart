// lib/core/i18n/app_localizations.dart
// ✅ FULL LOCALIZATION — FR / EN / AR with all required keys

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['fr']?[key] ??
        key;
  }

  String t(String key) => translate(key);

  static const Map<String, Map<String, String>> _translations = {
    // ══════════════════════════════════════════════════════
    // FRANÇAIS
    // ══════════════════════════════════════════════════════
    'fr': {
      // ---- General ----
      'app_name': 'Auto Rescue',
      'app_subtitle': 'Assistance routière rapide en Algérie',
      'close': 'Fermer',
      'skip': 'Passer',
      'next': 'Suivant',
      'enterApp': 'Entrer',
      'continue_btn': 'Continuer',
      'confirm': 'Confirmer',
      'cancel': 'Annuler',
      'ok': 'OK',
      'search': 'Rechercher',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'today': "Aujourd'hui",

      // ---- Onboarding ----
      'onboardingTitle1': 'Assistance rapide',
      'onboardingText1': 'Trouvez un prestataire en quelques secondes',
      'onboardingHint1': 'Localisation GPS précise',
      'onboardingTitle2': 'Suivi en temps réel',
      'onboardingText2': 'Suivez votre prestataire en direct sur la carte',
      'onboardingHint2': 'Mise à jour en temps réel',
      'onboardingTitle3': 'Service fiable',
      'onboardingText3':
          'Des prestataires vérifiés à votre service 24h/24',
      'onboardingHint3': 'Professionnels certifiés',

      // ---- Admin Dashboard ----
      'cmd_center': 'Command Center',
      'mission_ctrl': 'Mission Control',
      'provider_ops': 'Provider Ops',
      'customer_ops': 'Customer Ops',
      'pricing_lab': 'Pricing Lab',
      'revenue_pulse': 'Revenue Pulse',
      'broadcast_studio': 'Broadcast Studio',
      'support_control': 'Support Control',
      'activity_log': 'Activity Log',
      'cmd_label': 'Command',
      'missions_label': 'Demandes',
      'providers_label': 'Providers',
      'clients_label': 'Clients',
      'tarifs_label': 'Tarifs',
      'analytics_label': 'Analytics',
      'notif_label': 'Notif',
      'support_label': 'Support',
      'logs_label': 'Logs',
      'admin_banner_subtitle':
          'Pilotage en temps réel, opérations plus rapides, contrôles admin renforcés.',
      'admin_logout': 'Déconnexion',

      // Overview KPIs
      'overview_searching': 'Recherche',
      'overview_searching_sub': 'Missions sans provider',
      'overview_active': 'Actives',
      'overview_active_sub': 'Suivis en direct',
      'overview_completed': 'Terminées',
      'overview_completed_sub': 'Missions bouclées',
      'overview_urgent': 'Urgentes',
      'overview_urgent_sub': 'À surveiller maintenant',
      'overview_providers_on': 'Providers ON',
      'overview_providers_on_sub': '{busy} occupés',
      'overview_approved': 'Approuvés',
      'overview_approved_sub': '{blocked} bloqués',
      'overview_clients': 'Clients',
      'overview_clients_sub': 'Base utilisateur',
      'overview_provider_users': 'Providers',
      'overview_provider_users_sub': 'Comptes métier',

      // Insights
      'insight_mission_load': 'Charge mission',
      'insight_free_providers': 'Providers libres',
      'insight_cancellations': 'Annulations',
      'insight_critical_demands': 'Demandes critiques',
      'insight_pending_approval': 'Approval en attente',
      'mission_load_low': 'Faible',
      'mission_load_normal': 'Normale',
      'mission_load_high': 'Élevée',
      'mission_load_critical': 'Critique',

      // Quick actions
      'quick_launch_promo': 'Lancer une promo',
      'quick_launch_promo_sub':
          'Envoyer une offre live avec image et popup.',
      'quick_verify_providers': 'Vérifier les providers',
      'quick_verify_providers_sub':
          'Valider, bloquer ou filtrer les comptes actifs.',
      'quick_adjust_prices': 'Ajuster les prix',
      'quick_adjust_prices_sub':
          'Réagir vite à la demande ou à la distance.',
      'quick_support_channels': 'Support & canaux',
      'quick_support_channels_sub':
          'Mettre à jour l’aide visible partout dans l’app.',

      // Finance panel
      'finance_live': 'Finance live',
      'finance_live_sub':
          'Lecture directe du revenu missions et du rendement plateforme.',
      'avg_ticket': 'Ticket moyen',
      'ca_completed': 'CA terminé',
      'completion_rate': 'Taux completion',
      'missions_completed': 'Missions terminées',
      'missions_cancelled': 'Missions annulées',

      // Provider control
      'provider_control': 'Provider control',
      'provider_control_sub':
          'Surveillez les validations et les comptes à traiter en priorité.',
      'no_pending_providers': 'Aucun provider en attente',
      'no_pending_providers_sub':
          'Tous les comptes sont traités pour le moment.',
      'open_provider_ops': 'Ouvrir Provider Ops',
      'open_provider_ops_sub':
          'Vérifier les comptes, approvals et blocages.',
      'treat_approval': 'Traiter {count} approval(s)',
      'treat_approval_sub':
          'Accéder directement au centre de vérification.',

      // Mission radar
      'mission_radar': 'Mission radar',
      'mission_radar_sub':
          'Les dernières missions pour voir ce qui se passe maintenant.',
      'no_recent_mission': 'Aucune mission récente',
      'no_recent_mission_sub':
          'Les nouvelles missions apparaîtront ici en direct.',
      'pick_up': 'Pick up',
      'destination_label': 'Destination',

      // Status labels
      'status_accepted': 'Acceptée',
      'status_on_the_way': 'En route',
      'status_arrived': 'Arrivée',
      'status_in_service': 'En service',
      'status_completed': 'Terminée',
      'status_cancelled': 'Annulée',
      'status_searching': 'Recherche',

      // Providers page
      'provider_ops_title': 'Provider ops',
      'provider_ops_subtitle':
          'Filtrer rapidement, approuver plus vite, couper les comptes à risque.',
      'search_providers': 'Rechercher nom, email, téléphone, plaque...',
      'filter_all': 'Tous',
      'filter_approved': 'Approuvés',
      'filter_pending': 'En attente',
      'filter_online': 'En ligne',
      'filter_busy': 'Occupés',
      'filter_blocked': 'Bloqués',
      'result_count': 'Résultats',
      'online_count': 'Online',
      'blocked_count': 'Bloqués',
      'status_approved': 'Approuvé',
      'status_pending': 'En attente',
      'status_online': 'En ligne',
      'status_offline': 'Hors ligne',
      'status_busy': 'Occupé',
      'status_free': 'Libre',
      'status_blocked': 'Bloqué',
      'phone_label': 'Téléphone',
      'vehicle_label': 'Véhicule',
      'performance_label': 'Performance',
      'missions_count': '{count} missions',
      'rating_label': 'rating {rating}',
      'image_unavailable': 'Image véhicule indisponible',
      'retirer_approval': 'Retirer approval',
      'approuver': 'Approuver',
      'block': 'Bloquer',
      'unblock': 'Débloquer',

      // Customers page
      'customer_ops_title': 'Customer Ops',
      'customer_ops_subtitle':
          'Gardez la main sur la base client, les blocages et les comptes sensibles.',
      'search_customers': 'Rechercher nom, téléphone ou email...',
      'filter_active': 'Actifs',
      'customers_clients': 'Clients',
      'customers_blocked': 'Bloqués',
      'no_customer': 'Aucun client',
      'no_customer_sub':
          'Ajustez les filtres ou attendez de nouvelles inscriptions.',
      'uid_label': 'UID',
      'created_label': 'Créé',
      'block_client': 'Bloquer client',
      'unblock_client': 'Débloquer client',
      'block_account': 'Bloquer',
      'unblock_account': 'Débloquer',

      // Admin error
      'admin_error_default': 'Aucun détail supplémentaire disponible.',

      // Permission gate
      'permissionTitle': 'Autorisations',
      'permissionIntro':
          'Pour vous offrir le meilleur service, nous avons besoin de quelques autorisations.',
      'permissionWhy':
          'La localisation permet de trouver les providers proches et de suivre les missions. Les notifications vous alertent en temps réel.',
      'locationTitle': 'Localisation',
      'gpsDisabled': 'Service de localisation désactivé',
      'locationAlways': 'Toujours autorisée',
      'locationWhileInUse': 'Autorisée en cours d’utilisation',
      'permissionDeniedForever': 'Refusée définitivement',
      'permissionPending': 'En attente',
      'notificationsTitle': 'Notifications',
      'notificationsUnsupported': 'Non supportées',
      'notificationsAuthorized': 'Autorisées',
      'notificationsProvisional': 'Provisoires',
      'notificationsDenied': 'Refusées',
      'permissionAutoDone': 'Tout est prêt !',
      'permissionAutoTrying': 'Vérification automatique...',
      'permissionAutoBlocked':
          'Certaines autorisations manquent. Vous pouvez les activer manuellement.',
      'enableGps': 'Activer GPS',
      'allow': 'Autoriser',
      'allowAll': 'Tout autoriser',
      'continueAnyway': 'Continuer sans autoriser',
      'checking': 'Vérification...',

      // ---- Auth / Login ----
      'loginTitle': 'Connexion',
      'loginSubtitle': 'Connectez-vous à votre compte',
      'adminLoginTitle': 'Connexion Admin',
      'adminLoginSubtitle': 'Accès réservé aux administrateurs',
      'adminHelper': 'Connectez-vous avec vos identifiants administrateur.',
      'publicHelper': 'Connectez-vous avec votre email ou numéro de téléphone.',
      'identifierShort': 'Identifiant',
      'enterIdentifier': 'Entrez votre identifiant',
      'password': 'Mot de passe',
      'minPassword': 'Minimum 6 caractères',
      'signIn': 'Se connecter',
      'signingIn': 'Connexion...',
      'forgot_password': 'Mot de passe oublié ?',
      'create_account': 'Créer un compte',
      'back_to_public': "Retour à l'entrée publique",
      'privacy_short': 'Confidentialité',
      'terms_short': 'Conditions',
      'blocked_account_title': 'Compte bloqué',
      'no_internet_title': 'Connexion indisponible',
      'access_denied_title': 'Accès refusé',
      'understood': 'Compris',
      'password_login': 'Mot de passe',
      'email_otp_login': 'Email OTP',
      'enter_valid_email': 'Entrez un email valide',
      'otp_sent': 'Code OTP envoyé',
      'your_6_digit_code': 'Votre code de vérification à 6 chiffres',
      'copy_paste_code':
          'Copiez ce code et collez-le dans le champ ci-dessous',
      'enter_password_to_login':
          'Entrez votre mot de passe pour vous connecter',
      'verify_and_login': 'Vérifier et se connecter',
      'change_email': "Changer d'email",
      'send_otp_code': 'Envoyer le code OTP',
      'enter_otp_code': 'Code OTP (6 chiffres)',
      'code_must_be_6_digits': 'Le code doit avoir 6 chiffres',
      'not_available': 'NON DISPONIBLE',
      'email': 'Email',
      'phone': 'Téléphone',
      'full_name': 'Nom complet',
      'resetPasswordTitle': 'Mot de passe oublié',
      'resetPasswordBody':
          'Entrez votre email pour recevoir un lien de réinitialisation.',
      'resetPasswordEmail': 'Votre email',
      'resetPasswordSend': 'Envoyer',
      'resetPasswordSending': 'Envoi...',
      'resetPasswordInvalidEmail': 'Email invalide',
      'resetPasswordSent': 'Lien envoyé. Vérifiez votre boîte mail.',

      // ---- Signup ----
      'signupTitle': 'Créer un compte',
      'signupSubtitle':
          'Choisissez votre profil puis remplissez le strict minimum.',
      'signupCustomer': 'Client',
      'signupCustomerDesc':
          'Commander un dépannage et suivre la mission.',
      'signupProvider': 'Provider',
      'signupProviderDesc':
          'Recevoir les missions et intervenir sur le terrain.',
      'enterFullName': 'Entrez votre nom',
      'nameTooShort': 'Nom trop court',
      'enterPhone': 'Entrez votre numéro',
      'phoneInvalid': 'Numéro invalide',
      'enterEmail': 'Entrez votre email',
      'invalidEmail': 'Email invalide',
      'enterPassword': 'Entrez un mot de passe',
      'passwordTooShort': 'Minimum 6 caractères',
      'confirmPassword': 'Confirmer le mot de passe',
      'passwordsMismatch': 'Les mots de passe ne correspondent pas',
      'providerNote':
          'Les comptes provider restent soumis à la validation admin avant de recevoir des missions.',
      'customerNote':
          'Inscription directe : vous pourrez commander votre première mission juste après.',
      'sendOTP': 'Envoyer le code OTP',
      'verifyAndCreate': 'Vérifier et créer le compte',
      'alreadyAccount': "J'ai déjà un compte",
      'providerCreated':
          'Compte provider créé. Validation admin en attente.',
      'accountCreated': 'Compte créé avec succès!',
      'checkInfo': 'Vérifiez vos informations.',
      'passwordMismatch': 'Les mots de passe ne correspondent pas.',
      'enter6DigitCode': 'Veuillez entrer le code à 6 chiffres.',
      'enterOTPCode': 'Entrez le code OTP',
    },

    // ══════════════════════════════════════════════════════
    // ENGLISH
    // ══════════════════════════════════════════════════════
    'en': {
      'app_name': 'Auto Rescue',
      'app_subtitle': 'Fast roadside assistance in Algeria',
      'close': 'Close',
      'skip': 'Skip',
      'next': 'Next',
      'enterApp': 'Enter',
      'continue_btn': 'Continue',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'ok': 'OK',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'today': 'Today',

      'onboardingTitle1': 'Fast Assistance',
      'onboardingText1': 'Find a provider in seconds',
      'onboardingHint1': 'Precise GPS location',
      'onboardingTitle2': 'Live Tracking',
      'onboardingText2': 'Track your provider live on the map',
      'onboardingHint2': 'Real‑time updates',
      'onboardingTitle3': 'Reliable Service',
      'onboardingText3': 'Verified providers at your service 24/7',
      'onboardingHint3': 'Certified professionals',

      'cmd_center': 'Command Center',
      'mission_ctrl': 'Mission Control',
      'provider_ops': 'Provider Ops',
      'customer_ops': 'Customer Ops',
      'pricing_lab': 'Pricing Lab',
      'revenue_pulse': 'Revenue Pulse',
      'broadcast_studio': 'Broadcast Studio',
      'support_control': 'Support Control',
      'activity_log': 'Activity Log',
      'cmd_label': 'Command',
      'missions_label': 'Requests',
      'providers_label': 'Providers',
      'clients_label': 'Clients',
      'tarifs_label': 'Pricing',
      'analytics_label': 'Analytics',
      'notif_label': 'Notif',
      'support_label': 'Support',
      'logs_label': 'Logs',
      'admin_banner_subtitle':
          'Real‑time piloting, faster operations, enhanced admin controls.',
      'admin_logout': 'Logout',

      'overview_searching': 'Searching',
      'overview_searching_sub': 'Missions without provider',
      'overview_active': 'Active',
      'overview_active_sub': 'Live tracking',
      'overview_completed': 'Completed',
      'overview_completed_sub': 'Closed missions',
      'overview_urgent': 'Urgent',
      'overview_urgent_sub': 'Watch now',
      'overview_providers_on': 'Providers ON',
      'overview_providers_on_sub': '{busy} busy',
      'overview_approved': 'Approved',
      'overview_approved_sub': '{blocked} blocked',
      'overview_clients': 'Clients',
      'overview_clients_sub': 'User base',
      'overview_provider_users': 'Providers',
      'overview_provider_users_sub': 'Business accounts',

      'insight_mission_load': 'Mission load',
      'insight_free_providers': 'Free providers',
      'insight_cancellations': 'Cancellations',
      'insight_critical_demands': 'Critical demands',
      'insight_pending_approval': 'Pending approval',
      'mission_load_low': 'Low',
      'mission_load_normal': 'Normal',
      'mission_load_high': 'High',
      'mission_load_critical': 'Critical',

      'quick_launch_promo': 'Launch a promo',
      'quick_launch_promo_sub':
          'Send a live offer with image and popup.',
      'quick_verify_providers': 'Review providers',
      'quick_verify_providers_sub':
          'Approve, block or filter active accounts.',
      'quick_adjust_prices': 'Adjust prices',
      'quick_adjust_prices_sub':
          'React quickly to demand or distance.',
      'quick_support_channels': 'Support & channels',
      'quick_support_channels_sub':
          'Update help visible everywhere in the app.',

      'finance_live': 'Live Finance',
      'finance_live_sub':
          'Direct view of mission revenue and platform performance.',
      'avg_ticket': 'Average ticket',
      'ca_completed': 'Completed rev.',
      'completion_rate': 'Completion rate',
      'missions_completed': 'Completed missions',
      'missions_cancelled': 'Cancelled missions',

      'provider_control': 'Provider control',
      'provider_control_sub':
          'Monitor validations and priority accounts.',
      'no_pending_providers': 'No pending providers',
      'no_pending_providers_sub':
          'All accounts are handled for now.',
      'open_provider_ops': 'Open Provider Ops',
      'open_provider_ops_sub':
          'Check accounts, approvals and blocks.',
      'treat_approval': 'Process {count} approval(s)',
      'treat_approval_sub':
          'Go directly to the verification center.',

      'mission_radar': 'Mission radar',
      'mission_radar_sub':
          'Latest missions to see what’s happening right now.',
      'no_recent_mission': 'No recent missions',
      'no_recent_mission_sub':
          'New missions will appear here live.',
      'pick_up': 'Pick up',
      'destination_label': 'Destination',

      'status_accepted': 'Accepted',
      'status_on_the_way': 'On the way',
      'status_arrived': 'Arrived',
      'status_in_service': 'In service',
      'status_completed': 'Completed',
      'status_cancelled': 'Cancelled',
      'status_searching': 'Searching',

      'provider_ops_title': 'Provider ops',
      'provider_ops_subtitle':
          'Filter quickly, approve faster, cut risky accounts.',
      'search_providers': 'Search name, email, phone, plate...',
      'filter_all': 'All',
      'filter_approved': 'Approved',
      'filter_pending': 'Pending',
      'filter_online': 'Online',
      'filter_busy': 'Busy',
      'filter_blocked': 'Blocked',
      'result_count': 'Results',
      'online_count': 'Online',
      'blocked_count': 'Blocked',
      'status_approved': 'Approved',
      'status_pending': 'Pending',
      'status_online': 'Online',
      'status_offline': 'Offline',
      'status_busy': 'Busy',
      'status_free': 'Free',
      'status_blocked': 'Blocked',
      'phone_label': 'Phone',
      'vehicle_label': 'Vehicle',
      'performance_label': 'Performance',
      'missions_count': '{count} missions',
      'rating_label': 'rating {rating}',
      'image_unavailable': 'Vehicle image unavailable',
      'retirer_approval': 'Remove approval',
      'approuver': 'Approve',
      'block': 'Block',
      'unblock': 'Unblock',

      'customer_ops_title': 'Customer Ops',
      'customer_ops_subtitle':
          'Keep control on client base, blocks and sensitive accounts.',
      'search_customers': 'Search name, phone or email...',
      'filter_active': 'Active',
      'customers_clients': 'Clients',
      'customers_blocked': 'Blocked',
      'no_customer': 'No customers',
      'no_customer_sub':
          'Adjust filters or wait for new registrations.',
      'uid_label': 'UID',
      'created_label': 'Created',
      'block_client': 'Block client',
      'unblock_client': 'Unblock client',
      'block_account': 'Block',
      'unblock_account': 'Unblock',

      'admin_error_default': 'No additional details available.',

      'permissionTitle': 'Permissions',
      'permissionIntro':
          'To give you the best service, we need a few permissions.',
      'permissionWhy':
          'Location helps find nearby providers and track missions. Notifications alert you in real time.',
      'locationTitle': 'Location',
      'gpsDisabled': 'Location service disabled',
      'locationAlways': 'Always allowed',
      'locationWhileInUse': 'Allowed while in use',
      'permissionDeniedForever': 'Permanently denied',
      'permissionPending': 'Pending',
      'notificationsTitle': 'Notifications',
      'notificationsUnsupported': 'Unsupported',
      'notificationsAuthorized': 'Authorized',
      'notificationsProvisional': 'Provisional',
      'notificationsDenied': 'Denied',
      'permissionAutoDone': 'All set!',
      'permissionAutoTrying': 'Auto‑checking...',
      'permissionAutoBlocked':
          'Some permissions are missing. You can enable them manually.',
      'enableGps': 'Enable GPS',
      'allow': 'Allow',
      'allowAll': 'Allow all',
      'continueAnyway': 'Continue anyway',
      'checking': 'Checking...',

      // Auth / Login
      'loginTitle': 'Login',
      'loginSubtitle': 'Sign in to your account',
      'adminLoginTitle': 'Admin Login',
      'adminLoginSubtitle': 'Admin access only',
      'adminHelper': 'Sign in with your admin credentials.',
      'publicHelper': 'Sign in with your email or phone number.',
      'identifierShort': 'Identifier',
      'enterIdentifier': 'Enter your identifier',
      'password': 'Password',
      'minPassword': 'Minimum 6 characters',
      'signIn': 'Sign in',
      'signingIn': 'Signing in...',
      'forgot_password': 'Forgot password?',
      'create_account': 'Create an account',
      'back_to_public': 'Back to public entry',
      'privacy_short': 'Privacy',
      'terms_short': 'Terms',
      'blocked_account_title': 'Account blocked',
      'no_internet_title': 'No connection',
      'access_denied_title': 'Access denied',
      'understood': 'Understood',
      'password_login': 'Password',
      'email_otp_login': 'Email OTP',
      'enter_valid_email': 'Enter a valid email',
      'otp_sent': 'OTP code sent',
      'your_6_digit_code': 'Your 6-digit verification code',
      'copy_paste_code': 'Copy this code and paste it below',
      'enter_password_to_login': 'Enter your password to login',
      'verify_and_login': 'Verify and login',
      'change_email': 'Change email',
      'send_otp_code': 'Send OTP code',
      'enter_otp_code': 'OTP code (6 digits)',
      'code_must_be_6_digits': 'Code must be 6 digits',
      'not_available': 'NOT AVAILABLE',
      'email': 'Email',
      'phone': 'Phone',
      'full_name': 'Full name',
      'resetPasswordTitle': 'Forgot password',
      'resetPasswordBody': 'Enter your email to receive a reset link.',
      'resetPasswordEmail': 'Your email',
      'resetPasswordSend': 'Send',
      'resetPasswordSending': 'Sending...',
      'resetPasswordInvalidEmail': 'Invalid email',
      'resetPasswordSent': 'Link sent. Check your mailbox.',

      // Signup
      'signupTitle': 'Create account',
      'signupSubtitle': 'Choose your profile and fill in the essentials.',
      'signupCustomer': 'Customer',
      'signupCustomerDesc': 'Order a repair and track the mission.',
      'signupProvider': 'Provider',
      'signupProviderDesc':
          'Receive missions and intervene on the field.',
      'enterFullName': 'Enter your name',
      'nameTooShort': 'Name too short',
      'enterPhone': 'Enter your number',
      'phoneInvalid': 'Invalid number',
      'enterEmail': 'Enter your email',
      'invalidEmail': 'Invalid email',
      'enterPassword': 'Enter a password',
      'passwordTooShort': 'Minimum 6 characters',
      'confirmPassword': 'Confirm password',
      'passwordsMismatch': 'Passwords do not match',
      'providerNote':
          'Provider accounts remain subject to admin validation before receiving missions.',
      'customerNote':
          'Direct registration: you’ll be able to order your first mission right after.',
      'sendOTP': 'Send OTP code',
      'verifyAndCreate': 'Verify and create account',
      'alreadyAccount': 'I already have an account',
      'providerCreated':
          'Provider account created. Pending admin validation.',
      'accountCreated': 'Account created successfully!',
      'checkInfo': 'Check your information.',
      'passwordMismatch': 'Passwords do not match.',
      'enter6DigitCode': 'Please enter the 6-digit code.',
      'enterOTPCode': 'Enter the OTP code',
    },

    // ══════════════════════════════════════════════════════
    // عربي — ARABIC
    // ══════════════════════════════════════════════════════
    'ar': {
      'app_name': 'أوتو ريسكيو',
      'app_subtitle': 'مساعدة طرق سريعة في الجزائر',
      'close': 'إغلاق',
      'skip': 'تخطي',
      'next': 'التالي',
      'enterApp': 'دخول',
      'continue_btn': 'متابعة',
      'confirm': 'تأكيد',
      'cancel': 'إلغاء',
      'ok': 'موافق',
      'search': 'بحث',
      'loading': 'جارٍ التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'today': 'اليوم',

      'onboardingTitle1': 'مساعدة سريعة',
      'onboardingText1': 'اعثر على مزود خدمة في ثوانٍ',
      'onboardingHint1': 'موقع GPS دقيق',
      'onboardingTitle2': 'تتبع مباشر',
      'onboardingText2': 'تابع مزود الخدمة مباشرة على الخريطة',
      'onboardingHint2': 'تحديثات فورية',
      'onboardingTitle3': 'خدمة موثوقة',
      'onboardingText3': 'مزودون معتمدون في خدمتك على مدار الساعة',
      'onboardingHint3': 'محترفون معتمدون',

      'cmd_center': 'مركز القيادة',
      'mission_ctrl': 'مركز المهمات',
      'provider_ops': 'عمليات المزودين',
      'customer_ops': 'عمليات الزبائن',
      'pricing_lab': 'مختبر الأسعار',
      'revenue_pulse': 'نبض الإيرادات',
      'broadcast_studio': 'استوديو البث',
      'support_control': 'مركز الدعم',
      'activity_log': 'سجل النشاط',
      'cmd_label': 'القيادة',
      'missions_label': 'المهمات',
      'providers_label': 'المزودون',
      'clients_label': 'الزبائن',
      'tarifs_label': 'الأسعار',
      'analytics_label': 'تحليلات',
      'notif_label': 'إشعارات',
      'support_label': 'دعم',
      'logs_label': 'سجلات',
      'admin_banner_subtitle':
          'قيادة فورية، عمليات أسرع، تحكم إداري معزز.',
      'admin_logout': 'تسجيل الخروج',

      'overview_searching': 'قيد البحث',
      'overview_searching_sub': 'مهمات بدون مزود',
      'overview_active': 'نشطة',
      'overview_active_sub': 'متابعة مباشرة',
      'overview_completed': 'مكتملة',
      'overview_completed_sub': 'مهمات منتهية',
      'overview_urgent': 'عاجلة',
      'overview_urgent_sub': 'راقب الآن',
      'overview_providers_on': 'مزودون متصلون',
      'overview_providers_on_sub': '{busy} مشغول',
      'overview_approved': 'موافق عليهم',
      'overview_approved_sub': '{blocked} محظور',
      'overview_clients': 'الزبائن',
      'overview_clients_sub': 'قاعدة المستخدمين',
      'overview_provider_users': 'مزودو الخدمة',
      'overview_provider_users_sub': 'حسابات الأعمال',

      'insight_mission_load': 'حمل المهمات',
      'insight_free_providers': 'مزودون متاحون',
      'insight_cancellations': 'ملغاة',
      'insight_critical_demands': 'طلبات حرجة',
      'insight_pending_approval': 'بانتظار الموافقة',
      'mission_load_low': 'منخفض',
      'mission_load_normal': 'عادي',
      'mission_load_high': 'مرتفع',
      'mission_load_critical': 'حرج',

      'quick_launch_promo': 'إطلاق عرض',
      'quick_launch_promo_sub': 'إرسال عرض مباشر مع صورة ونافذة.',
      'quick_verify_providers': 'مراجعة المزودين',
      'quick_verify_providers_sub':
          'موافقة، حظر أو تصفية الحسابات النشطة.',
      'quick_adjust_prices': 'تعديل الأسعار',
      'quick_adjust_prices_sub': 'تفاعل سريع مع الطلب أو المسافة.',
      'quick_support_channels': 'الدعم والقنوات',
      'quick_support_channels_sub':
          'تحديث المساعدة المرئية في التطبيق.',

      'finance_live': 'المالية المباشرة',
      'finance_live_sub':
          'عرض مباشر لإيرادات المهمات وأداء المنصة.',
      'avg_ticket': 'معدل التذكرة',
      'ca_completed': 'الإيراد المكتمل',
      'completion_rate': 'نسبة الإكتمال',
      'missions_completed': 'مهمات مكتملة',
      'missions_cancelled': 'مهمات ملغاة',

      'provider_control': 'مراقبة المزودين',
      'provider_control_sub':
          'مراقبة عمليات التحقق والحسابات ذات الأولوية.',
      'no_pending_providers': 'لا يوجد مزودون في الانتظار',
      'no_pending_providers_sub': 'جميع الحسابات معالجة حاليًا.',
      'open_provider_ops': 'فتح عمليات المزودين',
      'open_provider_ops_sub': 'تفقد الحسابات والموافقات والحظر.',
      'treat_approval': 'معالجة {count} موافقة',
      'treat_approval_sub': 'اذهب مباشرة إلى مركز التحقق.',

      'mission_radar': 'رادار المهمات',
      'mission_radar_sub': 'آخر المهمات لمعرفة ما يحدث الآن.',
      'no_recent_mission': 'لا توجد مهمات حديثة',
      'no_recent_mission_sub': 'ستظهر المهمات الجديدة هنا مباشرة.',
      'pick_up': 'الاستلام',
      'destination_label': 'الوجهة',

      'status_accepted': 'مقبولة',
      'status_on_the_way': 'في الطريق',
      'status_arrived': 'وصلت',
      'status_in_service': 'في الخدمة',
      'status_completed': 'مكتملة',
      'status_cancelled': 'ملغاة',
      'status_searching': 'بحث',

      'provider_ops_title': 'عمليات المزودين',
      'provider_ops_subtitle':
          'تصفية سريعة، موافقة أسرع، عزل الحسابات الخطرة.',
      'search_providers': 'بحث بالاسم، البريد، الهاتف، اللوحة...',
      'filter_all': 'الكل',
      'filter_approved': 'موافق عليهم',
      'filter_pending': 'في الانتظار',
      'filter_online': 'متصل',
      'filter_busy': 'مشغول',
      'filter_blocked': 'محظور',
      'result_count': 'النتائج',
      'online_count': 'متصل',
      'blocked_count': 'محظور',
      'status_approved': 'موافق عليه',
      'status_pending': 'في الانتظار',
      'status_online': 'متصل',
      'status_offline': 'غير متصل',
      'status_busy': 'مشغول',
      'status_free': 'متاح',
      'status_blocked': 'محظور',
      'phone_label': 'الهاتف',
      'vehicle_label': 'المركبة',
      'performance_label': 'الأداء',
      'missions_count': '{count} مهمة',
      'rating_label': 'تقييم {rating}',
      'image_unavailable': 'صورة المركبة غير متاحة',
      'retirer_approval': 'سحب الموافقة',
      'approuver': 'موافقة',
      'block': 'حظر',
      'unblock': 'رفع الحظر',

      'customer_ops_title': 'عمليات الزبائن',
      'customer_ops_subtitle':
          'حافظ على السيطرة على قاعدة الزبائن والحسابات الحساسة.',
      'search_customers': 'بحث بالاسم، الهاتف أو البريد...',
      'filter_active': 'نشط',
      'customers_clients': 'الزبائن',
      'customers_blocked': 'محظورون',
      'no_customer': 'لا يوجد زبائن',
      'no_customer_sub': 'عدّل الفلاتر أو انتظر تسجيلات جديدة.',
      'uid_label': 'UID',
      'created_label': 'أنشئ',
      'block_client': 'حظر الزبون',
      'unblock_client': 'رفع الحظر عن الزبون',
      'block_account': 'حظر',
      'unblock_account': 'رفع الحظر',

      'admin_error_default': 'لا توجد تفاصيل إضافية.',

      'permissionTitle': 'الصلاحيات',
      'permissionIntro': 'لتقديم أفضل خدمة، نحتاج بعض الصلاحيات.',
      'permissionWhy':
          'الموقع يساعد في العثور على مزودين قريبين وتتبع المهمات. التنبيهات تخبرك في الوقت الحقيقي.',
      'locationTitle': 'الموقع',
      'gpsDisabled': 'خدمة الموقع معطلة',
      'locationAlways': 'مسموح دائمًا',
      'locationWhileInUse': 'مسموح أثناء الاستخدام',
      'permissionDeniedForever': 'مرفوض نهائيًا',
      'permissionPending': 'قيد الانتظار',
      'notificationsTitle': 'الإشعارات',
      'notificationsUnsupported': 'غير مدعومة',
      'notificationsAuthorized': 'مصرح بها',
      'notificationsProvisional': 'مؤقتة',
      'notificationsDenied': 'مرفوضة',
      'permissionAutoDone': 'جاهز!',
      'permissionAutoTrying': 'فحص تلقائي...',
      'permissionAutoBlocked':
          'بعض الصلاحيات ناقصة. يمكنك تفعيلها يدويًا.',
      'enableGps': 'تفعيل GPS',
      'allow': 'سماح',
      'allowAll': 'السماح للكل',
      'continueAnyway': 'المتابعة بدون',
      'checking': 'جارٍ الفحص...',

      // Auth / Login
      'loginTitle': 'تسجيل الدخول',
      'loginSubtitle': 'سجل الدخول إلى حسابك',
      'adminLoginTitle': 'دخول المشرف',
      'adminLoginSubtitle': 'وصول المشرف فقط',
      'adminHelper': 'سجل الدخول باستخدام بيانات المشرف.',
      'publicHelper': 'سجل الدخول باستخدام البريد الإلكتروني أو رقم الهاتف.',
      'identifierShort': 'المعرف',
      'enterIdentifier': 'أدخل المعرف الخاص بك',
      'password': 'كلمة المرور',
      'minPassword': 'الحد الأدنى 6 أحرف',
      'signIn': 'تسجيل الدخول',
      'signingIn': 'جارٍ تسجيل الدخول...',
      'forgot_password': 'نسيت كلمة المرور؟',
      'create_account': 'إنشاء حساب',
      'back_to_public': 'العودة للدخول العام',
      'privacy_short': 'الخصوصية',
      'terms_short': 'الشروط',
      'blocked_account_title': 'الحساب محظور',
      'no_internet_title': 'لا يوجد اتصال',
      'access_denied_title': 'تم رفض الوصول',
      'understood': 'فهمت',
      'password_login': 'كلمة المرور',
      'email_otp_login': 'بريد OTP',
      'enter_valid_email': 'أدخل بريدًا إلكترونيًا صالحًا',
      'otp_sent': 'تم إرسال رمز OTP',
      'your_6_digit_code': 'رمز التحقق المكون من 6 أرقام',
      'copy_paste_code': 'انسخ هذا الرمز والصقه أدناه',
      'enter_password_to_login':
          'أدخل كلمة المرور لتسجيل الدخول',
      'verify_and_login': 'تحقق وتسجيل الدخول',
      'change_email': 'تغيير البريد الإلكتروني',
      'send_otp_code': 'إرسال رمز OTP',
      'enter_otp_code': 'رمز OTP (6 أرقام)',
      'code_must_be_6_digits': 'يجب أن يتكون الرمز من 6 أرقام',
      'not_available': 'غير متوفر',
      'email': 'البريد الإلكتروني',
      'phone': 'الهاتف',
      'full_name': 'الاسم الكامل',
      'resetPasswordTitle': 'نسيت كلمة المرور',
      'resetPasswordBody':
          'أدخل بريدك الإلكتروني لاستلام رابط إعادة التعيين.',
      'resetPasswordEmail': 'بريدك الإلكتروني',
      'resetPasswordSend': 'إرسال',
      'resetPasswordSending': 'جارٍ الإرسال...',
      'resetPasswordInvalidEmail': 'بريد إلكتروني غير صالح',
      'resetPasswordSent': 'تم إرسال الرابط. تحقق من صندوق الوارد.',

      // Signup
      'signupTitle': 'إنشاء حساب',
      'signupSubtitle': 'اختر ملفك الشخصي واملأ الأساسيات.',
      'signupCustomer': 'زبون',
      'signupCustomerDesc': 'اطلب إصلاحًا وتابع المهمة.',
      'signupProvider': 'مزود خدمة',
      'signupProviderDesc': 'استلم المهمات وتدخل في الميدان.',
      'enterFullName': 'أدخل اسمك',
      'nameTooShort': 'الاسم قصير جدًا',
      'enterPhone': 'أدخل رقمك',
      'phoneInvalid': 'رقم غير صالح',
      'enterEmail': 'أدخل بريدك الإلكتروني',
      'invalidEmail': 'بريد إلكتروني غير صالح',
      'enterPassword': 'أدخل كلمة مرور',
      'passwordTooShort': 'الحد الأدنى 6 أحرف',
      'confirmPassword': 'تأكيد كلمة المرور',
      'passwordsMismatch': 'كلمتا المرور غير متطابقتين',
      'providerNote':
          'حسابات المزودين تبقى خاضعة لموافقة الإدارة قبل استلام المهمات.',
      'customerNote':
          'تسجيل مباشر: ستتمكن من طلب مهمتك الأولى بعد ذلك مباشرة.',
      'sendOTP': 'إرسال رمز OTP',
      'verifyAndCreate': 'تحقق وإنشاء الحساب',
      'alreadyAccount': 'لدي حساب بالفعل',
      'providerCreated':
          'تم إنشاء حساب المزود. في انتظار موافقة الإدارة.',
      'accountCreated': 'تم إنشاء الحساب بنجاح!',
      'checkInfo': 'تحقق من معلوماتك.',
      'passwordMismatch': 'كلمتا المرور غير متطابقتين.',
      'enter6DigitCode': 'يرجى إدخال الرمز المكون من 6 أرقام.',
      'enterOTPCode': 'أدخل رمز OTP',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}