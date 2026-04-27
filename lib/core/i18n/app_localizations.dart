import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  fr,
  en,
  ar,
}

extension AppLanguageDetails on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.fr:
        return const Locale('fr');
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.ar:
        return const Locale('ar');
    }
  }

  String get code => locale.languageCode;

  String get nativeName {
    switch (this) {
      case AppLanguage.fr:
        return 'Francais';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.ar:
        return 'العربية';
    }
  }

  String get shortLabel {
    switch (this) {
      case AppLanguage.fr:
        return 'FR';
      case AppLanguage.en:
        return 'EN';
      case AppLanguage.ar:
        return 'AR';
    }
  }

  TextDirection get textDirection {
    return this == AppLanguage.ar ? TextDirection.rtl : TextDirection.ltr;
  }

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'en':
        return AppLanguage.en;
      case 'ar':
        return AppLanguage.ar;
      case 'fr':
      default:
        return AppLanguage.fr;
    }
  }
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._(this._language);

  static const _storageKey = 'app_language_code';

  AppLanguage _language;

  AppLanguage get language => _language;

  Locale get locale => _language.locale;

  TextDirection get textDirection => _language.textDirection;

  static Future<AppLanguageController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    return AppLanguageController._(AppLanguageDetails.fromCode(code));
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, language.code);
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  AppLanguage get language => AppLanguageDetails.fromCode(locale.languageCode);

  String t(String key) {
    final table =
        _localizedValues[language] ?? _localizedValues[AppLanguage.fr]!;
    return table[key] ?? _localizedValues[AppLanguage.fr]![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _localizedValues = {
  AppLanguage.fr: {
    'language': 'Langue',
    'chooseLanguage': 'Choisir la langue',
    'chooseLanguageHint':
        'La preference sera gardee pour les prochaines ouvertures.',
    'skip': 'Passer',
    'next': 'Suivant',
    'enterApp': 'Entrer dans l app',
    'permissionTitle': 'Avant de commencer',
    'permissionIntro':
        'Depaniny fonctionne mieux si l application peut utiliser votre position et vous envoyer les alertes mission en temps reel.',
    'permissionAutoTrying': 'Demande automatique en cours...',
    'permissionAutoDone': 'Autorisations verifiees.',
    'permissionAutoBlocked':
        'Si Chrome ne montre pas la fenetre, utilisez le bouton ci-dessous.',
    'locationTitle': 'Position GPS',
    'notificationsTitle': 'Notifications',
    'gpsDisabled': 'Le GPS du telephone ou du navigateur est desactive.',
    'locationAlways': 'Acces permanent active.',
    'locationWhileInUse': 'Acces autorise pendant l utilisation.',
    'permissionDeniedForever': 'Permission refusee definitivement.',
    'permissionPending': 'Permission en attente.',
    'notificationsUnsupported':
        'Notifications non disponibles sur cet environnement.',
    'notificationsAuthorized': 'Notifications autorisees.',
    'notificationsProvisional': 'Notifications provisoires activees.',
    'notificationsDenied': 'Notifications refusees.',
    'permissionWhy':
        'Ces autorisations permettent au customer de partager sa position, au provider de suivre la route correctement, et a l app de vous avertir sans retard.',
    'enableGps': 'Activer GPS',
    'allow': 'Autoriser',
    'allowAll': 'Autoriser tout',
    'checking': 'Verification...',
    'continue': 'Continuer',
    'continueAnyway': 'Continuer quand meme',
    'onboardingTitle1': 'Demandez une assistance rapidement',
    'onboardingText1':
        'Choisissez votre service, ajoutez votre destination et obtenez une estimation claire.',
    'onboardingTitle2': 'Suivez la mission en direct',
    'onboardingText2':
        'Consultez la progression du provider, son arrivee et l etat de votre mission.',
    'onboardingTitle3': 'Une plateforme complete',
    'onboardingText3':
        'Customer, provider et admin travaillent ensemble dans une experience moderne et professionnelle.',
    'onboardingHint1': 'Demande rapide avec estimation immediate',
    'onboardingHint2': 'Suivi clair du provider et de la mission',
    'onboardingHint3': 'Acces structure pour customer, provider et admin',
    'loginTitle': 'Connexion',
    'adminLoginTitle': 'Connexion admin',
    'loginSubtitle': 'Depannage routier simple, rapide et local',
    'adminLoginSubtitle': 'Acces reserve a l administration',
    'publicHelper':
        'Clients et providers utilisent cette entree. Les providers restent soumis a la validation admin.',
    'adminHelper':
        'Entrez votre compte admin. Les clients et providers utilisent l entree publique.',
    'identifierLabel': 'Email ou numero de telephone',
    'identifierShort': 'Email ou numero',
    'password': 'Mot de passe',
    'signIn': 'Se connecter',
    'signingIn': 'Connexion...',
    'createAccount': 'Creer un compte',
    'backPublic': 'Retour a l entree publique',
    'checkInfo': 'Verifiez vos informations.',
    'enterIdentifier': 'Entrez votre email ou numero',
    'enterPassword': 'Entrez votre mot de passe',
    'minPassword': 'Minimum 6 caracteres',
    'forgotPassword': 'Mot de passe oublie ?',
    'resetPasswordTitle': 'Reinitialiser le mot de passe',
    'resetPasswordBody':
        'Entrez l email de votre compte. Nous allons vous envoyer un lien securise pour choisir un nouveau mot de passe.',
    'resetPasswordEmail': 'Email du compte',
    'resetPasswordInvalidEmail': 'Entrez un email valide.',
    'resetPasswordSend': 'Envoyer le lien',
    'resetPasswordSending': 'Envoi...',
    'resetPasswordSent':
        'Lien de reinitialisation envoye. Verifiez votre boite email.',
    'cancel': 'Annuler',
  },
  AppLanguage.en: {
    'language': 'Language',
    'chooseLanguage': 'Choose language',
    'chooseLanguageHint': 'Your choice will be saved for next time.',
    'skip': 'Skip',
    'next': 'Next',
    'enterApp': 'Enter the app',
    'permissionTitle': 'Before you start',
    'permissionIntro':
        'Depaniny works better when it can use your location and send real-time mission alerts.',
    'permissionAutoTrying': 'Requesting permissions automatically...',
    'permissionAutoDone': 'Permissions checked.',
    'permissionAutoBlocked':
        'If Chrome does not show the prompt, use the button below.',
    'locationTitle': 'GPS location',
    'notificationsTitle': 'Notifications',
    'gpsDisabled': 'Phone or browser GPS is disabled.',
    'locationAlways': 'Always access enabled.',
    'locationWhileInUse': 'Access allowed while using the app.',
    'permissionDeniedForever': 'Permission permanently denied.',
    'permissionPending': 'Permission pending.',
    'notificationsUnsupported':
        'Notifications are not available in this environment.',
    'notificationsAuthorized': 'Notifications allowed.',
    'notificationsProvisional': 'Provisional notifications enabled.',
    'notificationsDenied': 'Notifications denied.',
    'permissionWhy':
        'These permissions let customers share their position, help providers follow the route, and allow the app to alert you without delay.',
    'enableGps': 'Enable GPS',
    'allow': 'Allow',
    'allowAll': 'Allow all',
    'checking': 'Checking...',
    'continue': 'Continue',
    'continueAnyway': 'Continue anyway',
    'onboardingTitle1': 'Request help quickly',
    'onboardingText1':
        'Choose your service, add your destination, and get a clear estimate.',
    'onboardingTitle2': 'Track the mission live',
    'onboardingText2':
        'Follow the provider progress, arrival, and mission status.',
    'onboardingTitle3': 'A complete platform',
    'onboardingText3':
        'Customers, providers, and admins work together in a modern professional experience.',
    'onboardingHint1': 'Fast request with instant estimate',
    'onboardingHint2': 'Clear provider and mission tracking',
    'onboardingHint3': 'Structured access for customers, providers, and admins',
    'loginTitle': 'Login',
    'adminLoginTitle': 'Admin login',
    'loginSubtitle': 'Simple, fast, local roadside assistance',
    'adminLoginSubtitle': 'Reserved for administration',
    'publicHelper':
        'Customers and providers use this entry. Providers still require admin approval.',
    'adminHelper':
        'Enter your admin account. Customers and providers use the public entry.',
    'identifierLabel': 'Email or phone number',
    'identifierShort': 'Email or phone',
    'password': 'Password',
    'signIn': 'Sign in',
    'signingIn': 'Signing in...',
    'createAccount': 'Create account',
    'backPublic': 'Back to public entry',
    'checkInfo': 'Check your information.',
    'enterIdentifier': 'Enter your email or phone',
    'enterPassword': 'Enter your password',
    'minPassword': 'Minimum 6 characters',
    'forgotPassword': 'Forgot password?',
    'resetPasswordTitle': 'Reset password',
    'resetPasswordBody':
        'Enter your account email. We will send you a secure link to choose a new password.',
    'resetPasswordEmail': 'Account email',
    'resetPasswordInvalidEmail': 'Enter a valid email.',
    'resetPasswordSend': 'Send link',
    'resetPasswordSending': 'Sending...',
    'resetPasswordSent': 'Reset link sent. Check your email inbox.',
    'cancel': 'Cancel',
  },
  AppLanguage.ar: {
    'language': 'اللغة',
    'chooseLanguage': 'اختيار اللغة',
    'chooseLanguageHint': 'سيتم حفظ اختيارك للمرات القادمة.',
    'skip': 'تخطي',
    'next': 'التالي',
    'enterApp': 'الدخول إلى التطبيق',
    'permissionTitle': 'قبل أن تبدأ',
    'permissionIntro':
        'يعمل Depaniny بشكل أفضل عند السماح باستخدام موقعك وإرسال تنبيهات المهام في الوقت الحقيقي.',
    'permissionAutoTrying': 'جاري طلب الصلاحيات تلقائيا...',
    'permissionAutoDone': 'تم فحص الصلاحيات.',
    'permissionAutoBlocked':
        'إذا لم يظهر Chrome نافذة السماح، استخدم الزر في الأسفل.',
    'locationTitle': 'موقع GPS',
    'notificationsTitle': 'الإشعارات',
    'gpsDisabled': 'خدمة الموقع في الهاتف أو المتصفح غير مفعلة.',
    'locationAlways': 'الوصول الدائم مفعل.',
    'locationWhileInUse': 'الوصول مسموح أثناء استخدام التطبيق.',
    'permissionDeniedForever': 'تم رفض الصلاحية نهائيا.',
    'permissionPending': 'الصلاحية في انتظار الموافقة.',
    'notificationsUnsupported': 'الإشعارات غير متوفرة في هذه البيئة.',
    'notificationsAuthorized': 'الإشعارات مسموحة.',
    'notificationsProvisional': 'الإشعارات المؤقتة مفعلة.',
    'notificationsDenied': 'تم رفض الإشعارات.',
    'permissionWhy':
        'هذه الصلاحيات تسمح للعميل بمشاركة موقعه، وتساعد المزود على تتبع الطريق، وتسمح للتطبيق بتنبيهك بدون تأخير.',
    'enableGps': 'تفعيل GPS',
    'allow': 'السماح',
    'allowAll': 'السماح للجميع',
    'checking': 'جاري التحقق...',
    'continue': 'متابعة',
    'continueAnyway': 'متابعة على أي حال',
    'onboardingTitle1': 'اطلب المساعدة بسرعة',
    'onboardingText1': 'اختر الخدمة، أضف وجهتك، واحصل على تقدير واضح.',
    'onboardingTitle2': 'تابع المهمة مباشرة',
    'onboardingText2': 'تابع تقدم المزود ووصوله وحالة المهمة.',
    'onboardingTitle3': 'منصة متكاملة',
    'onboardingText3':
        'العملاء والمزودون والإدارة يعملون معا داخل تجربة حديثة واحترافية.',
    'onboardingHint1': 'طلب سريع مع تقدير فوري',
    'onboardingHint2': 'تتبع واضح للمزود والمهمة',
    'onboardingHint3': 'دخول منظم للعملاء والمزودين والإدارة',
    'loginTitle': 'تسجيل الدخول',
    'adminLoginTitle': 'دخول الإدارة',
    'loginSubtitle': 'مساعدة طريق بسيطة وسريعة ومحلية',
    'adminLoginSubtitle': 'مخصص للإدارة فقط',
    'publicHelper':
        'العملاء والمزودون يستخدمون هذا المدخل. يبقى المزودون بحاجة إلى موافقة الإدارة.',
    'adminHelper':
        'أدخل حساب الإدارة. العملاء والمزودون يستخدمون المدخل العام.',
    'identifierLabel': 'البريد الإلكتروني أو رقم الهاتف',
    'identifierShort': 'البريد أو الهاتف',
    'password': 'كلمة المرور',
    'signIn': 'تسجيل الدخول',
    'signingIn': 'جاري الدخول...',
    'createAccount': 'إنشاء حساب',
    'backPublic': 'العودة إلى المدخل العام',
    'checkInfo': 'تحقق من معلوماتك.',
    'enterIdentifier': 'أدخل بريدك الإلكتروني أو رقمك',
    'enterPassword': 'أدخل كلمة المرور',
    'minPassword': 'الحد الأدنى 6 أحرف',
    'forgotPassword': 'نسيت كلمة المرور؟',
    'resetPasswordTitle': 'إعادة تعيين كلمة المرور',
    'resetPasswordBody':
        'أدخل بريد حسابك الإلكتروني. سنرسل لك رابطا آمنا لاختيار كلمة مرور جديدة.',
    'resetPasswordEmail': 'بريد الحساب',
    'resetPasswordInvalidEmail': 'أدخل بريدا إلكترونيا صحيحا.',
    'resetPasswordSend': 'إرسال الرابط',
    'resetPasswordSending': 'جاري الإرسال...',
    'resetPasswordSent':
        'تم إرسال رابط إعادة التعيين. تحقق من بريدك الإلكتروني.',
    'cancel': 'إلغاء',
  },
};
