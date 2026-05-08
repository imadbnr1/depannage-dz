import re

# Hardcoded strings found in the codebase
hardcoded_strings = [
    # From various Text() widgets and parameters
    'Auto Rescue',
    'Journal indisponible',
    'Impossible de charger l audit admin.',
    'Admin Activity Log',
    'Rechercher action, admin, cible ou resume...',
    'Tout', 'Blocages', 'Approvals', 'Notifications', 'Annulations',
    'Aucune activite', 'Les actions admin apparaitront ici.',
    'Aujourd hui', 'Hier', '7 derniers jours', '30 derniers jours',
    'Toutes les donnees', 'Periode personnalisee',
    'Demandes filtrees', 'Actives', 'Terminees', 'Annulees', 'Chiffre filtre',
    'Commission plateforme', 'Basee sur $commissionPercent %',
    'Panier moyen', 'Moyenne par mission terminee',
    'Provider', 'Destination',
    'Montant', 'Debut', 'Fin',
    'Periode', 'En recherche', 'Taux completion', 'Commission',
    'Type popup',
    'Filtrer par titre, message ou type...',
    'Mission filters',
    'Recherche', 'En route',
    'Prix de base (DA)', 'Prix par km (DA)', 'Frais urgence (DA)', 'Commission (%)',
    'label',
    'Telephone', 'Type de vehicule', 'Plaque',
    'Ajouter un commentaire...',
    'Distance', 'ETA', 'Prix',
    'Vehicule', 'Depart', 'Destination', 'Provider', 'Repere',
    'Aucun historique', 'Aucune demande active',
    'Vous', 'Nom complet', 'Telephone',
    'Chat provider', 'Accueil', 'Demandes', 'Historique', 'Profil', 'Support',
    'Telephone', 'WhatsApp', 'Email', 'Adresse', 'Horaires', 'Confidentialite', 'Conditions',
    'Nouveau message',
    'Pick up', 'Client', 'Dest',
    'Ouvrir',
    'Net ${netEarning.toStringAsFixed(0)} DA',
    'Net',
    'DA',
    'Net',
    '${latest.estimatedPrice!.toStringAsFixed(0)} DA',
    'Net ${netEarning.toStringAsFixed(0)} DA',
    '${latest.estimatedDistanceKm!.toStringAsFixed(1)} km',
    '${latest.estimatedDurationMinutes} min',
    'Erreur chargement profil: $e',
    'Profil provider mis a jour',
    'Erreur sauvegarde: $e',
    'Nouveau message de $senderName',
    'Position: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}',
    'Titre et message obligatoires',
    'La date de fin doit etre apres la date de debut',
    'Notification envoyee',
    'Impossible de lire cette image.',
    'Image selectionnee. Elle sera envoyee avec la notification.',
    'Echec de l upload de l image',
    'Tarification mise a jour',
    'Choisissez un point de depart valide.',
    'Choisissez une destination valide.',
    'Mission introuvable',
    'Demande introuvable',
    'Ouvrir le suivi',
    'Annuler la demande',
    'Annuler la mission',
    'Fermer',
    'Ouvrir Maps',
    'Evaluer le provider',
    'Validation en attente',
    'Choisir destination',
    'Choisir sur la carte',
    'Compris',
    'Forcer annulation',
    'Plus recentes', 'Plus anciennes', 'Prix le plus eleve',
    'Sauvegarde...', 'Sauvegarder',
    'Envoi...', 'Envoyer',
    'Effacer la planification',
    'Annonce', 'Reduction', 'Offre',
    'Toujours a l ouverture', 'Une fois par session',
    'Providers', 'Customers', 'Tout le monde',
    'Retirer'
]

# Remove duplicates while preserving order
seen = set()
unique_strings = []
for s in hardcoded_strings:
    if s not in seen:
        seen.add(s)
        unique_strings.append(s)

# Create localization keys with translations
localization_entries = {}

for string in unique_strings:
    # Create a key based on the string content
    # Convert to lowercase and replace spaces with underscores
    key = string.lower().replace(' ', '_').replace('-', '_').replace('.', '_').replace(',', '_').replace(':', '_').replace('(', '_').replace(')', '_').replace('$', '_').replace('{', '_').replace('}', '_').replace('!', '_')
    # Remove special characters
    key = re.sub(r'[^a-zA-Z0-9_]', '', key)
    # Remove multiple underscores
    key = re.sub(r'_+', '_', key)
    # Remove leading/trailing underscores
    key = key.strip('_')
    
    # If the key is empty or too short, create a generic one
    if not key or len(key) < 2:
        key = f"string_{len(localization_entries)}"
    
    # Manual translations for common terms
    translations = {
        'auto_rescue': {
            'french': 'Auto Rescue',
            'english': 'Auto Rescue',
            'arabic': 'أوتو ريسكيو'
        },
        'journal_indisponible': {
            'french': 'Journal indisponible',
            'english': 'Activity log unavailable',
            'arabic': 'سجل النشاط غير متوفر'
        },
        'impossible_de_charger_l_audit_admin': {
            'french': 'Impossible de charger l audit admin.',
            'english': 'Unable to load admin audit.',
            'arabic': 'غير قادر على تحميل تدقيق المشرف'
        },
        'admin_activity_log': {
            'french': 'Admin Activity Log',
            'english': 'Admin Activity Log',
            'arabic': 'سجل نشاط المشرف'
        },
        'rechercher_action_admin_cible_ou_resume': {
            'french': 'Rechercher action, admin, cible ou resume...',
            'english': 'Search action, admin, target or summary...',
            'arabic': 'البحث عن إجراء، مشرف، هدف أو ملخص...'
        },
        'tout': {
            'french': 'Tout',
            'english': 'All',
            'arabic': 'الكل'
        },
        'blocages': {
            'french': 'Blocages',
            'english': 'Blocks',
            'arabic': 'المنع'
        },
        'approvals': {
            'french': 'Approvals',
            'english': 'Approvals',
            'arabic': 'الموافقات'
        },
        'notifications': {
            'french': 'Notifications',
            'english': 'Notifications',
            'arabic': 'الإشعارات'
        },
        'annulations': {
            'french': 'Annulations',
            'english': 'Cancellations',
            'arabic': 'الإلغاءات'
        },
        'aucune_activite': {
            'french': 'Aucune activite',
            'english': 'No activity',
            'arabic': 'لا يوجد نشاط'
        },
        'les_actions_admin_apparaitront_ici': {
            'french': 'Les actions admin apparaitront ici.',
            'english': 'Admin actions will appear here.',
            'arabic': 'ستظهر إجراءات المشرف هنا'
        },
        'aujourdhui': {
            'french': 'Aujourd hui',
            'english': 'Today',
            'arabic': 'اليوم'
        },
        'hier': {
            'french': 'Hier',
            'english': 'Yesterday',
            'arabic': 'أمس'
        },
        '7_derniers_jours': {
            'french': '7 derniers jours',
            'english': 'Last 7 days',
            'arabic': 'آخر 7 أيام'
        },
        '30_derniers_jours': {
            'french': '30 derniers jours',
            'english': 'Last 30 days',
            'arabic': 'آخر 30 يومًا'
        },
        'toutes_les_donnees': {
            'french': 'Toutes les donnees',
            'english': 'All data',
            'arabic': 'جميع البيانات'
        },
        'periode_personnalisee': {
            'french': 'Periode personnalisee',
            'english': 'Custom period',
            'arabic': 'فترة مخصصة'
        },
        'demandes_filtrees': {
            'french': 'Demandes filtrees',
            'english': 'Filtered requests',
            'arabic': 'الطلبات المفلترة'
        },
        'actives': {
            'french': 'Actives',
            'english': 'Active',
            'arabic': 'نشطة'
        },
        'terminees': {
            'french': 'Terminees',
            'english': 'Completed',
            'arabic': 'مكتملة'
        },
        'annulees': {
            'french': 'Annulees',
            'english': 'Cancelled',
            'arabic': 'ملغاة'
        },
        'chiffre_filtre': {
            'french': 'Chiffre filtre',
            'english': 'Filtered figure',
            'arabic': 'ال chiffre المفلتر'
        },
        'commission_plateforme': {
            'french': 'Commission plateforme',
            'english': 'Platform commission',
            'arabic': 'عمولة المنصة'
        },
        'basee_sur_commission_percent': {
            'french': 'Basee sur $commissionPercent %',
            'english': 'Based on $commissionPercent %',
            'arabic': 'بناءً على $commissionPercent %'
        },
        'panier_moyen': {
            'french': 'Panier moyen',
            'english': 'Average basket',
            'arabic': 'متوسط السلة'
        },
        'moyenne_par_mission_terminee': {
            'french': 'Moyenne par mission terminee',
            'english': 'Average per completed mission',
            'arabic': 'المتوسط لكل مهمة مكتملة'
        },
        'provider': {
            'french': 'Provider',
            'english': 'Provider',
            'arabic': 'مزود الخدمة'
        },
        'destination': {
            'french': 'Destination',
            'english': 'Destination',
            'arabic': 'الوجهة'
        },
        'montant': {
            'french': 'Montant',
            'english': 'Amount',
            'arabic': 'المبلغ'
        },
        'debut': {
            'french': 'Debut',
            'english': 'Start',
            'arabic': 'البداية'
        },
        'fin': {
            'french': 'Fin',
            'english': 'End',
            'arabic': 'النهاية'
        },
        'periode': {
            'french': 'Periode',
            'english': 'Period',
            'arabic': 'الفترة'
        },
        'en_recherche': {
            'french': 'En recherche',
            'english': 'Searching',
            'arabic': 'قيد البحث'
        },
        'taux_completion': {
            'french': 'Taux completion',
            'english': 'Completion rate',
            'arabic': 'معدل الإنجاز'
        },
        'commission': {
            'french': 'Commission',
            'english': 'Commission',
            'arabic': 'العمولة'
        },
        'type_popup': {
            'french': 'Type popup',
            'english': 'Popup type',
            'arabic': 'نوع النافذة المنبثقة'
        },
        'filtrer_par_titre_message_ou_type': {
            'french': 'Filtrer par titre, message ou type...',
            'english': 'Filter by title, message or type...',
            'arabic': 'تصفية حسب العنوان أو الرسالة أو النوع...'
        },
        'mission_filters': {
            'french': 'Mission filters',
            'english': 'Mission filters',
            'arabic': 'مرشحات المهمة'
        },
        'recherche': {
            'french': 'Recherche',
            'english': 'Search',
            'arabic': 'بحث'
        },
        'en_route': {
            'french': 'En route',
            'english': 'On the way',
            'arabic': 'في الطريق'
        },
        'prix_de_base_da': {
            'french': 'Prix de base (DA)',
            'english': 'Base price (DA)',
            'arabic': 'السعر الأساسي (DA)'
        },
        'prix_par_km_da': {
            'french': 'Prix par km (DA)',
            'english': 'Price per km (DA)',
            'arabic': 'السعر لكل كيلومتر (DA)'
        },
        'frais_urgence_da': {
            'french': 'Frais urgence (DA)',
            'english': 'Urgency fee (DA)',
            'arabic': 'رسوم الطوارئ (DA)'
        },
        'commission_percent': {
            'french': 'Commission (%)',
            'english': 'Commission (%)',
            'arabic': 'العمولة (%)'
        },
        'label': {
            'french': 'label',
            'english': 'label',
            'arabic': 'التسمية'
        },
        'telephone': {
            'french': 'Telephone',
            'english': 'Phone',
            'arabic': 'الهاتف'
        },
        'type_de_vehicule': {
            'french': 'Type de vehicule',
            'english': 'Vehicle type',
            'arabic': 'نوع المركبة'
        },
        'plaque': {
            'french': 'Plaque',
            'english': 'Plate',
            'arabic': 'اللوحة'
        },
        'ajouter_un_commentaire': {
            'french': 'Ajouter un commentaire...',
            'english': 'Add a comment...',
            'arabic': 'أضف تعليقًا...'
        },
        'distance': {
            'french': 'Distance',
            'english': 'Distance',
            'arabic': 'المسافة'
        },
        'eta': {
            'french': 'ETA',
            'english': 'ETA',
            'arabic': 'الوقت المتوقع للوصول'
        },
        'prix': {
            'french': 'Prix',
            'english': 'Price',
            'arabic': 'السعر'
        },
        'vehicule': {
            'french': 'Vehicule',
            'english': 'Vehicle',
            'arabic': 'المركبة'
        },
        'depart': {
            'french': 'Depart',
            'english': 'Departure',
            'arabic': 'المغادرة'
        },
        'repere': {
            'french': 'Repere',
            'english': 'Landmark',
            'arabic': 'علامة مميزة'
        },
        'aucun_historique': {
            'french': 'Aucun historique',
            'english': 'No history',
            'arabic': 'لا يوجد تاريخ'
        },
        'aucune_demande_active': {
            'french': 'Aucune demande active',
            'english': 'No active request',
            'arabic': 'لا يوجد طلب نشط'
        },
        'vous': {
            'french': 'Vous',
            'english': 'You',
            'arabic': 'أنت'
        },
        'nom_complet': {
            'french': 'Nom complet',
            'english': 'Full name',
            'arabic': 'الاسم الكامل'
        },
        'chat_provider': {
            'french': 'Chat provider',
            'english': 'Provider chat',
            'arabic': 'دردشة المزود'
        },
        'accueil': {
            'french': 'Accueil',
            'english': 'Home',
            'arabic': 'الرئيسية'
        },
        'demandes': {
            'french': 'Demandes',
            'english': 'Requests',
            'arabic': 'الطلبات'
        },
        'historique': {
            'french': 'Historique',
            'english': 'History',
            'arabic': 'التاريخ'
        },
        'profil': {
            'french': 'Profil',
            'english': 'Profile',
            'arabic': 'الملف الشخصي'
        },
        'support': {
            'french': 'Support',
            'english': 'Support',
            'arabic': 'الدعم'
        },
        'whatsapp': {
            'french': 'WhatsApp',
            'english': 'WhatsApp',
            'arabic': 'واتساب'
        },
        'email': {
            'french': 'Email',
            'english': 'Email',
            'arabic': 'البريد الإلكتروني'
        },
        'adresse': {
            'french': 'Adresse',
            'english': 'Address',
            'arabic': 'العنوان'
        },
        'horaires': {
            'french': 'Horaires',
            'english': 'Hours',
            'arabic': 'الساعات'
        },
        'confidentialite': {
            'french': 'Confidentialite',
            'english': 'Privacy',
            'arabic': 'الخصوصية'
        },
        'conditions': {
            'french': 'Conditions',
            'english': 'Terms',
            'arabic': 'الشروط'
        },
        'nouveau_message': {
            'french': 'Nouveau message',
            'english': 'New message',
            'arabic': 'رسالة جديدة'
        },
        'pick_up': {
            'french': 'Pick up',
            'english': 'Pick up',
            'arabic': 'الاستلام'
        },
        'client': {
            'french': 'Client',
            'english': 'Client',
            'arabic': 'العميل'
        },
        'dest': {
            'french': 'Dest',
            'english': 'Dest',
            'arabic': 'الوجهة'
        },
        'ouvrir': {
            'french': 'Ouvrir',
            'english': 'Open',
            'arabic': 'فتح'
        },
        'net_da': {
            'french': 'Net ${netEarning.toStringAsFixed(0)} DA',
            'english': 'Net ${netEarning.toStringAsFixed(0)} DA',
            'arabic': 'الصافي ${netEarning.toStringAsFixed(0)} DA'
        },
        'da': {
            'french': 'DA',
            'english': 'DA',
            'arabic': 'DA'
        },
        'net': {
            'french': 'Net',
            'english': 'Net',
            'arabic': 'الصافي'
        },
        'da_2': {
            'french': '${latest.estimatedPrice!.toStringAsFixed(0)} DA',
            'english': '${latest.estimatedPrice!.toStringAsFixed(0)} DA',
            'arabic': '${latest.estimatedPrice!.toStringAsFixed(0)} DA'
        },
        'net_da_2': {
            'french': 'Net ${netEarning.toStringAsFixed(0)} DA',
            'english': 'Net ${netEarning.toStringAsFixed(0)} DA',
            'arabic': 'الصافي ${netEarning.toStringAsFixed(0)} DA'
        },
        'km': {
            'french': '${latest.estimatedDistanceKm!.toStringAsFixed(1)} km',
            'english': '${latest.estimatedDistanceKm!.toStringAsFixed(1)} km',
            'arabic': '${latest.estimatedDistanceKm!.toStringAsFixed(1)} km'
        },
        'min': {
            'french': '${latest.estimatedDurationMinutes} min',
            'english': '${latest.estimatedDurationMinutes} min',
            'arabic': '${latest.estimatedDurationMinutes} دقيقة'
        },
        'erreur_chargement_profil': {
            'french': 'Erreur chargement profil: $e',
            'english': 'Profile loading error: $e',
            'arabic': 'خطأ في تحميل الملف الشخصي: $e'
        },
        'profil_provider_mis_a_jour': {
            'french': 'Profil provider mis a jour',
            'english': 'Provider profile updated',
            'arabic': 'تم تحديث ملف المزود'
        },
        'erreur_sauvegarde': {
            'french': 'Erreur sauvegarde: $e',
            'english': 'Save error: $e',
            'arabic': 'خطأ في الحفظ: $e'
        },
        'nouveau_message_de_sendername': {
            'french': 'Nouveau message de $senderName',
            'english': 'New message from $senderName',
            'arabic': 'رسالة جديدة من $senderName'
        },
        'position': {
            'french': 'Position: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}',
            'english': 'Position: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}',
            'arabic': 'الموقع: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}'
        },
        'titre_et_message_obligatoires': {
            'french': 'Titre et message obligatoires',
            'english': 'Title and message required',
            'arabic': 'العنوان والرسالة إلزاميان'
        },
        'la_date_de_fin_doit_etre_apres_la_date_de_debut': {
            'french': 'La date de fin doit etre apres la date de debut',
            'english': 'End date must be after start date',
            'arabic': 'يجب أن يكون تاريخ الانتهاء بعد تاريخ البدء'
        },
        'notification_envoyee': {
            'french': 'Notification envoyee',
            'english': 'Notification sent',
            'arabic': 'تم إرسال الإشعار'
        },
        'impossible_de_lire_cette_image': {
            'french': 'Impossible de lire cette image.',
            'english': 'Unable to read this image.',
            'arabic': 'غير قادر على قراءة هذه الصورة.'
        },
        'image_selectionnee_elle_sera_envoyee_avec_la_notification': {
            'french': 'Image selectionnee. Elle sera envoyee avec la notification.',
            'english': 'Image selected. It will be sent with the notification.',
            'arabic': 'تم اختيار الصورة. سيتم إرسالها مع الإشعار.'
        },
        'echec_de_l_upload_de_l_image': {
            'french': 'Echec de l upload de l image',
            'english': 'Image upload failed',
            'arabic': 'فشل تحميل الصورة'
        },
        'tarification_mise_a_jour': {
            'french': 'Tarification mise a jour',
            'english': 'Pricing updated',
            'arabic': 'تم تحديث التسعير'
        },
        'choisissez_un_point_de_depart_valide': {
            'french': 'Choisissez un point de depart valide.',
            'english': 'Choose a valid departure point.',
            'arabic': 'اختر نقطة انطلاق صالحة.'
        },
        'choisissez_une_destination_valide': {
            'french': 'Choisissez une destination valide.',
            'english': 'Choose a valid destination.',
            'arabic': 'اختر وجهة صالحة.'
        },
        'mission_introuvable': {
            'french': 'Mission introuvable',
            'english': 'Mission not found',
            'arabic': 'المهمة غير موجودة'
        },
        'demande_introuvable': {
            'french': 'Demande introuvable',
            'english': 'Request not found',
            'arabic': 'الطلب غير موجود'
        },
        'ouvrir_le_suivi': {
            'french': 'Ouvrir le suivi',
            'english': 'Open tracking',
            'arabic': 'فتح التتبع'
        },
        'annuler_la_demande': {
            'french': 'Annuler la demande',
            'english': 'Cancel request',
            'arabic': 'إلغاء الطلب'
        },
        'annuler_la_mission': {
            'french': 'Annuler la mission',
            'english': 'Cancel mission',
            'arabic': 'إلغاء المهمة'
        },
        'fermer': {
            'french': 'Fermer',
            'english': 'Close',
            'arabic': 'إغلاق'
        },
        'ouvrir_maps': {
            'french': 'Ouvrir Maps',
            'english': 'Open Maps',
            'arabic': 'فتح الخرائط'
        },
        'evaluer_le_provider': {
            'french': 'Evaluer le provider',
            'english': 'Rate the provider',
            'arabic': 'تقييم المزود'
        },
        'validation_en_attente': {
            'french': 'Validation en attente',
            'english': 'Pending validation',
            'arabic': 'في انتظار التحقق'
        },
        'choisir_destination': {
            'french': 'Choisir destination',
            'english': 'Choose destination',
            'arabic': 'اختر الوجهة'
        },
        'choisir_sur_la_carte': {
            'french': 'Choisir sur la carte',
            'english': 'Choose on map',
            'arabic': 'اختر على الخريطة'
        },
        'compris': {
            'french': 'Compris',
            'english': 'Understood',
            'arabic': 'مفهوم'
        },
        'forcer_annulation': {
            'french': 'Forcer annulation',
            'english': 'Force cancellation',
            'arabic': 'فرض الإلغاء'
        },
        'plus_recentes': {
            'french': 'Plus recentes',
            'english': 'Most recent',
            'arabic': 'الأحدث'
        },
        'plus_anciennes': {
            'french': 'Plus anciennes',
            'english': 'Oldest',
            'arabic': 'الأقدم'
        },
        'prix_le_plus_eleve': {
            'french': 'Prix le plus eleve',
            'english': 'Highest price',
            'arabic': 'أعلى سعر'
        },
        'sauvegarde': {
            'french': 'Sauvegarde...',
            'english': 'Saving...',
            'arabic': 'جارٍ الحفظ...'
        },
        'sauvegarder': {
            'french': 'Sauvegarder',
            'english': 'Save',
            'arabic': 'حفظ'
        },
        'envoi': {
            'french': 'Envoi...',
            'english': 'Sending...',
            'arabic': 'جارٍ الإرسال...'
        },
        'envoyer': {
            'french': 'Envoyer',
            'english': 'Send',
            'arabic': 'إرسال'
        },
        'effacer_la_planification': {
            'french': 'Effacer la planification',
            'english': 'Clear schedule',
            'arabic': 'مسح الجدول'
        },
        'annonce': {
            'french': 'Annonce',
            'english': 'Announcement',
            'arabic': 'إعلان'
        },
        'reduction': {
            'french': 'Reduction',
            'english': 'Discount',
            'arabic': 'خصم'
        },
        'offre': {
            'french': 'Offre',
            'english': 'Offer',
            'arabic': 'عرض'
        },
        'toujours_a_l_ouverture': {
            'french': 'Toujours a l ouverture',
            'english': 'Always on opening',
            'arabic': 'دائماً عند الفتح'
        },
        'une_fois_par_session': {
            'french': 'Une fois par session',
            'english': 'Once per session',
            'arabic': 'مرة واحدة لكل جلسة'
        },
        'providers': {
            'french': 'Providers',
            'english': 'Providers',
            'arabic': 'المزودون'
        },
        'customers': {
            'french': 'Customers',
            'english': 'Customers',
            'arabic': 'العملاء'
        },
        'tout_le_monde': {
            'french': 'Tout le monde',
            'english': 'Everyone',
            'arabic': 'الجميع'
        },
        'retirer': {
            'french': 'Retirer',
            'english': 'Remove',
            'arabic': 'إزالة'
        }
    }
    
    # Use manual translation if available, otherwise generate automatically
    if key in translations:
        localization_entries[key] = translations[key]
    else:
        localization_entries[key] = {
            'french': string,
            'english': string,  # Will need to be translated
            'arabic': string    # Will need to be translated
        }

# Generate the Dart code for the localization file
print("// New localization entries to add to _translations map:")
print()
print("// French entries:")
for key, translations in localization_entries.items():
    print(f"      '{key}': '{translations['french']}',")
    
print()
print("// English entries:")
for key, translations in localization_entries.items():
    print(f"      '{key}': '{translations['english']}',")
    
print()
print("// Arabic entries:")
for key, translations in localization_entries.items():
    print(f"      '{key}': '{translations['arabic']}',")

# Print summary
print(f"\n// Total entries: {len(localization_entries)}")