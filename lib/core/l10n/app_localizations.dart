import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('fr'), Locale('ar')];

  bool get isAr => locale.languageCode == 'ar';

  String _t(String fr, String ar) => isAr ? ar : fr;

  // ── App ──────────────────────────────────────────────────────────────────
  String get appName => 'wetaxi.station';

  // ── Navigation ───────────────────────────────────────────────────────────
  String get navHome => _t('Accueil', 'الرئيسية');

  String get navWallet => _t('Wallet', 'المحفظة');

  String get navOrders => _t('Commandes', 'الطلبات');

  // ── Login ────────────────────────────────────────────────────────────────
  String get login => _t('Connexion', 'تسجيل الدخول');

  String get loginSubtitle => _t(
      'Connectez-vous à votre compte courtier', 'سجّل دخولك إلى حساب الوسيط');

  String get phoneNumber => _t('Numéro de téléphone', 'رقم الهاتف');

  String get password => _t('Mot de passe', 'كلمة المرور');

  String get connect => _t('Se connecter', 'تسجيل الدخول');

  String get connectionError =>
      _t('Erreur de connexion au serveur', 'خطأ في الاتصال بالخادم');

  // ── Home ─────────────────────────────────────────────────────────────────
  String get activeLine => _t('Ligne active', 'الخط النشط');

  String get seatStatus => _t('État des places', 'حالة المقاعد');

  String get rechargeAccount => _t('Recharger un compte', 'إعادة شحن حساب');

  String get cannotChangeLineSeatsOccupied => _t(
        'Vous ne pouvez pas changer de ligne tant que des passagers sont à bord.',
        'لا يمكنك تغيير الخط طالما يوجد ركاب على متن السيارة.',
      );

  String get noLine => _t('Aucune ligne', 'لا يوجد خط');

  String get min => _t(' min', ' دقيقة');

  String get approximately => '~ ';

  // ── Wallet ───────────────────────────────────────────────────────────────
  String get wallet => _t('Wallet', 'المحفظة');

  String get availableBalance => _t('Solde disponible', 'الرصيد المتاح');

  String get withdraw => _t('Retrait', 'سحب');

  String get transfer => _t('Transfert', 'تحويل');

  String get recharge => _t('Recharger', 'شحن');

  String get lastTransactions => _t('Dernières transactions', 'آخر المعاملات');

  String get mad => ' MAD';

  String get topUp => _t('Recharger', 'شحن');

  String get tripBalance => _t('Solde courses', 'رصيد الرحلات');

  String get cashBalance => _t('Solde cash', 'الرصيد النقدي');

  String get txAll => _t('Tout', 'الكل');

  String get txTrips => _t('Courses', 'الرحلات');

  String get txCashOut => _t('Retraits', 'السحوبات');

  String get txTopUp => _t('Rechargements', 'الشحن');

  String get noTransactions => _t('Aucune transaction', 'لا توجد معاملات');

  String get noMoreTransactions => _t('Tout est affiché', 'تم عرض الكل');

  // ── Recharge ─────────────────────────────────────────────────────────────
  String get rechargeClient => _t('Recharger un compte', 'إعادة شحن حساب');

  String get nfcCard => _t('Carte NFC', 'بطاقة NFC');

  String get phoneMode => _t('Téléphone', 'الهاتف');

  String get nfcBadgeId => _t('Badge NFC (ID)', 'رقم شارة NFC');

  String get amountMad => _t('Montant (MAD)', 'المبلغ (درهم)');

  String get rechargeViaNfc => _t('Recharger via NFC', 'شحن عبر NFC');

  String get processing => _t('Traitement...', 'جاري المعالجة...');

  String get invalidAmount => _t('Montant invalide', 'مبلغ غير صالح');

  String get nfcIdRequired => _t('Identifiant NFC requis', 'رقم الشارة مطلوب');

  String get phoneRequired =>
      _t('Numéro de téléphone requis', 'رقم الهاتف مطلوب');

  // ── Orders ───────────────────────────────────────────────────────────────
  String get orders => _t('Commandes', 'الطلبات');

  String get accept => _t('Accepter', 'قبول');

  String get refuse => _t('Refuser', 'رفض');

  String get departure => _t('Départ', 'المغادرة');

  String get destination => _t('Destination', 'الوجهة');

  String get passengers => _t('passager(s)', 'راكب');

  String get activeOrders => _t('Commandes actives', 'الطلبات النشطة');

  String get history => _t('Historique', 'السجل');

  String get completeTrip => _t('Terminer la course', 'إنهاء الرحلة');

  String get retry => _t('Réessayer', 'إعادة المحاولة');

  String inMinutes(int n) => _t('Dans $n min', 'خلال $n دقيقة');

  // ── Profile ──────────────────────────────────────────────────────────────
  String get profile => _t('Profile', 'الملف الشخصي');

  String get information => _t('Informations', 'المعلومات');

  String get phone => _t('Téléphone', 'الهاتف');

  String get vehicle => _t('Véhicule', 'المركبة');

  String get stationLabel => _t('Station', 'المحطة');

  String get permit => _t('Permis', 'الرخصة');

  String get driverRole => _t('Chauffeur de Grand Taxi', 'سائق سيارة أجرة');

  String get settings => _t('Paramètres', 'الإعدادات');

  String get logout => _t('Déconnexion', 'تسجيل الخروج');

  String get confirmLogoutTitle => _t('Déconnexion', 'تسجيل الخروج');

  String get confirmLogoutMsg =>
      _t('Voulez-vous vraiment vous déconnecter ?', 'هل تريد تسجيل الخروج؟');

  String get cancel => _t('Annuler', 'إلغاء');

  String get disconnect => _t('Déconnecter', 'خروج');

  // ── Settings ─────────────────────────────────────────────────────────────
  String get language => _t('Langue', 'اللغة');

  String get selectLanguage => _t('Choisir la langue', 'اختر اللغة');

  String get french => 'Français';

  String get arabic => 'العربية';

  String get appearance => _t('Apparence', 'المظهر');

  String get theme       => _t('Thème', 'السمة');

  String get themeDay    => _t('Mode jour️', 'وضع النهار');

  String get themeNight  => _t('Mode nuit', 'وضع الليل');

  String get about => _t('À propos', 'حول');

  String get version => _t('Version', 'الإصدار');

  // ── Not in queue ─────────────────────────────────────────────────────────
  String get notInQueue =>
      _t('Pas dans la file d\'attente', 'لست في طابور الانتظار');

  String get notInQueueSubtitle => _t(
        'Vous n\'êtes pas encore dans la file. Rejoignez une ligne pour commencer.',
        'لم تنضم بعد إلى طابور. انضم إلى خط للبدء في العمل.',
      );

  String get joinQueue => _t('Rejoindre la file', 'الانضمام للطابور');

  // ── My Line (SSE live page) ───────────────────────────────────────────────
  String get myLine => _t('Ma ligne', 'خطي');

  String get live => _t('Direct', 'مباشر');

  String get connecting => _t('Connexion...', 'جاري الاتصال...');

  String get connectionLost => _t('Connexion perdue', 'انقطع الاتصال');

  String get myPosition => _t('Ma position', 'موضعي');

  String get pricePerSeat => _t('Prix/place', 'السعر/مقعد');

  String get queueTitle => _t('File d\'attente', 'الطابور');

  String get myLineTaxis => _t('Taxis', 'تاكسي');

  String get myLineSeats => _t('Places', 'مقاعد');

  String get myLineOccupied => _t('Occupées', 'مشغولة');

  String get myLineFree => _t('Libres', 'فارغة');

  String get taxiStatusQueued => _t('En attente', 'في الطابور');

  String get taxiStatusFilling => _t('En remplissage', 'يملأ');

  String get taxiStatusDeparted => _t('Parti', 'غادر');

  String get changeLine => _t('Changer de ligne', 'تغيير الخط');

  String get changeLineTitle => _t('Confirmer le changement', 'تأكيد التغيير');

  String get confirm => _t('Confirmer', 'تأكيد');

  // ── Wallet flows (Top-up / Withdraw / Transfer) ───────────────────────────
  String get continueBtn => _t('Continuer', 'متابعة');

  String get backToWallet => _t('Retour au wallet', 'العودة للمحفظة');

  String get modeLabel => _t('Mode', 'الطريقة');

  String get amountLabel => _t('Montant', 'المبلغ');

  String get otherAmount => _t('Autre montant...', 'مبلغ آخر...');

  String get free => _t('Gratuit', 'مجاني');

  String get fees => _t('Frais', 'الرسوم');

  String get beneficiaryName => _t('Nom du bénéficiaire', 'اسم المستفيد');

  String get rib => 'RIB';

  String get motif => _t('Motif (optionnel)', 'السبب (اختياري)');

  String get recipient => _t('Destinataire', 'المستلم');

  String get searchPlaceholder => _t('Rechercher...', 'بحث...');

  String get noResults => _t('Aucun résultat', 'لا توجد نتائج');

  // Top-up
  String get chooseTopUpMethod =>
      _t('Choisir le mode de rechargement', 'اختر طريقة الشحن');

  String get howToTopUp => _t('Comment souhaitez-vous recharger votre wallet ?',
      'كيف تريد شحن محفظتك؟');

  String get topUpAmountTitle => _t('Montant à recharger', 'مبلغ الشحن');

  String get modeSubLabel => _t('Mode: ', 'الطريقة: ');

  String get confirmTopUp => _t('Confirmer le rechargement', 'تأكيد الشحن');

  String get confirmTopUpBtn => _t('Confirmer le rechargement', 'تأكيد الشحن');

  String get topUpSentTitle => _t('Demande envoyée', 'تم إرسال الطلب');

  String get topUpSentSubtitle => _t(
      'Votre demande de rechargement par virement a été soumise avec succès.',
      'تم تقديم طلب شحن الحساب بنجاح.');

  String get qrTopUpTitle => _t('QR de rechargement', 'رمز QR للشحن');

  String get paymentLinkTitle => _t('Lien de paiement', 'رابط الدفع');

  String get qrTopUpSubtitle => _t(
      'Présentez ce lien au guichet pour procéder au rechargement.',
      'أبرز هذا الرمز في الشباك لإتمام الشحن.');

  String get cardLinkSubtitle => _t(
      'Utilisez ce lien pour finaliser votre paiement par carte.',
      'استخدم هذا الرابط لإتمام الدفع ببطاقتك.');

  // Top-up methods
  String get methodGuichet => _t('Guichet (QR)', 'شباك (QR)');

  String get methodGuichetSub =>
      _t('Rechargement via QR code', 'شحن عبر رمز QR');

  String get methodBank => _t('Virement bancaire', 'تحويل بنكي');

  String get methodBankSub =>
      _t('Transfert depuis votre banque', 'تحويل من حسابك البنكي');

  String get methodCmi => _t('CMI Card', 'بطاقة CMI');

  String get methodCmiSub =>
      _t('Paiement par carte bancaire', 'الدفع ببطاقة بنكية');

  // Withdraw
  String get withdrawMethod => _t('Mode de retrait', 'طريقة السحب');

  String get howToWithdraw =>
      _t('Comment souhaitez-vous retirer ?', 'كيف تريد السحب؟');

  String get withdrawAmountTitle => _t('Montant à retirer', 'مبلغ السحب');

  String get bankInfoTitle => _t('Informations bancaires', 'المعلومات البنكية');

  String get enterBankInfo =>
      _t('Entrez vos coordonnées bancaires', 'أدخل بياناتك البنكية');

  String get cashplusTitle => _t('Numéro Cashplus', 'رقم Cashplus');

  String get cashplusRecipient =>
      _t('Numéro du destinataire Cashplus', 'رقم مستلم Cashplus');

  String get cashplusPhoneLabel => _t('Numéro de téléphone', 'رقم الهاتف');

  String get confirmWithdrawTitle => _t('Confirmer le retrait', 'تأكيد السحب');

  String get confirmWithdrawBtn => _t('Confirmer le retrait', 'تأكيد السحب');

  String get withdrawDoneTitle => _t('Retrait demandé', 'تم طلب السحب');

  String get withdrawDoneSub => _t(
      'Votre demande de retrait a été soumise avec succès.',
      'تم تقديم طلب السحب بنجاح.');

  String get qrWithdrawTitle => _t('QR de retrait', 'رمز QR للسحب');

  String get qrWithdrawSubtitle => _t(
      'Présentez ce QR au guichet pour retirer votre argent.',
      'أبرز هذا الرمز في الشباك لسحب أموالك.');

  String get methodGuichetWithdrawSub =>
      _t('Retrait via code QR au guichet', 'سحب عبر رمز QR في الشباك');

  String get methodBankWithdrawSub =>
      _t('Transfert vers votre compte bancaire', 'تحويل إلى حسابك البنكي');

  String get methodCashplusSub =>
      _t('Transfert vers un numéro Cashplus', 'تحويل إلى رقم Cashplus');

  // Transfer
  String get transferAmountTitle => _t('Montant à transférer', 'مبلغ التحويل');

  String get howMuchTransfer =>
      _t('Combien souhaitez-vous transférer ?', 'كم تريد تحويل؟');

  String get chooseRecipient => _t('Choisir le destinataire', 'اختر المستلم');

  String get searchDriver => _t('Recherchez un chauffeur par nom ou numéro',
      'ابحث عن سائق بالاسم أو الرقم');

  String get freeTransferNote =>
      _t('Frais de transfert : Gratuit', 'رسوم التحويل: مجاني');

  String get confirmTransferTitle =>
      _t('Confirmer le transfert', 'تأكيد التحويل');

  String get confirmTransferBtn =>
      _t('Confirmer le transfert', 'تأكيد التحويل');

  String get transferDoneTitle => _t('Transfert effectué', 'تم التحويل');

  String transferDoneSub(String amount, String name) => _t(
      'Le transfert de $amount MAD vers $name a été effectué avec succès.',
      'تم تحويل $amount درهم إلى $name بنجاح.');

  // ── PIN / Password confirmation sheet ────────────────────────────────────
  String get topUpWalletTitle => _t('Recharger le wallet', 'شحن المحفظة');

  String get confirmOperation => _t('Confirmer l\'opération', 'تأكيد العملية');

  String get enterPinToValidate => _t(
      'Entrez votre code PIN à 6 chiffres', 'أدخل رمز PIN المكون من 6 أرقام');

  String get validateBtn => _t('Valider', 'تحقق');

  String get pinRequired =>
      _t('Veuillez entrer votre code PIN', 'الرجاء إدخال رمز PIN');

  String get pinIncorrect => _t('Code PIN incorrect', 'رمز PIN غير صحيح');

  String get linkCopied => _t('Lien copié !', 'تم نسخ الرابط!');

  String get taxiFull =>
      _t('Trip ready to start', 'الرحلة جاهزة للانطلاق');

  String get moveToNextTaxi => _t('Taxi is full, you can start your trip',
      'سيارة الأجرة ممتلئة، يمكنك بدء رحلتك');

  String get full => _t('FULL', 'ممتلئ');

  // ── Courtier profile ──────────────────────────────────────────────────────
  String get courtierRole => _t('Courtier de station', 'وسيط محطة');

  String get agentId => _t('Identifiant agent', 'رقم الوكيل');

  // ── Home queue tabs ───────────────────────────────────────────────────────
  String get tabWaiting => _t('EN ATTENTE', 'في الانتظار');

  String get tabActive => _t('EN COURS', 'قيد التنفيذ');

  String get tabCompleted => _t('COMPLET', 'مكتمل');

  String get noTaxi => _t('Aucun taxi', 'لا يوجد تاكسي');

  String get driverLabel => _t('Chauffeur', 'السائق');

  String get taxiNumberLabel => _t('Numéro de taxi', 'رقم التاكسي');

  String get seats => _t('Places', 'مقاعد');

  // ── NFC confirm ───────────────────────────────────────────────────────────
  String get nfcDetected => _t('Profil chauffeur', 'ملف تعريف السائق');

  String get addToQueue => _t('Ajouter à la file d\'attente', 'إضافة إلى الطابور');

  String get connectionErrorShort => _t('Erreur', 'خطأ');

  String get nfcIdentified => _t('Conducteur identifié', 'تم التعرف على السائق');

  String get seatsAvailable => _t('places disponibles', 'مقاعد متاحة');

  String get lineLabel    => _t('Ligne', 'الخط');

  String get allLines     => _t('Toutes les lignes', 'كل الخطوط');

  String get selectLine   => _t('Sélectionner la ligne', 'اختر الخط');

  String get lineRequired => _t('Veuillez sélectionner une ligne', 'يرجى اختيار الخط');

  String get alreadyInQueue => _t('Déjà dans la file d\'attente', 'موجود في الطابور');

  String get alreadyInQueueSub => _t('Ce chauffeur est déjà enregistré dans la file d\'attente', 'هذا السائق مسجل بالفعل في قائمة الانتظار');

  String get close => _t('Fermer', 'إغلاق');

  // ── Bottom nav ───────────────────────────────────────────────────────────
  String get navQueue   => _t('File', 'الطابور');
  String get navLinkNfc => _t('Lier NFC', 'ربط NFC');

  // ── Link NFC flow ────────────────────────────────────────────────────────
  String get linkNfcTitle        => _t('Lier un badge NFC', 'ربط شارة NFC');
  String get stepSearch          => _t('Chercher', 'بحث');
  String get stepScan            => _t('Scanner', 'مسح');
  String get stepOtp             => 'OTP';
  String get searchByPhone       => _t('Rechercher par téléphone', 'البحث برقم الهاتف');
  String get searchDriverPhone   => _t('Numéro de téléphone du chauffeur', 'رقم هاتف السائق');
  String get search              => _t('Rechercher', 'بحث');
  String get driverFound         => _t('Chauffeur trouvé', 'تم العثور على السائق');
  String get driverCode          => _t('Code agent', 'رمز الوكيل');
  String get plateNumber         => _t('Plaque', 'اللوحة');
  String get nfcLinkedBadge      => _t('NFC lié', 'NFC مربوط');
  String get nfcNotLinkedBadge   => _t('NFC non lié', 'NFC غير مربوط');
  String get scanNfcInstruction  => _t('Approchez le badge NFC du lecteur', 'قرّب شارة NFC من القارئ');
  String get scanNfcWaiting      => _t('En attente du badge...', 'في انتظار الشارة...');
  String get nfcTagDetected      => _t('Badge détecté', 'تم كشف الشارة');
  String get otpSentInfo         => _t('Code OTP envoyé au', 'تم إرسال رمز OTP إلى');
  String get enterOtp            => _t('Entrez le code OTP', 'أدخل رمز OTP');
  String get otpPlaceholder      => _t('Code à 4 chiffres', '4 أرقام');
  String get validateAndLink     => _t('Valider et lier', 'تحقق وربط');
  String get linkSuccess         => _t('Badge lié avec succès !', 'تم ربط الشارة بنجاح!');
  String get linkSuccessSubtitle => _t('Le badge NFC est maintenant associé au chauffeur.', 'تم ربط شارة NFC بالسائق.');
  String get linkAnotherDriver   => _t('Lier un autre chauffeur', 'ربط سائق آخر');
  String get driverNotFound      => _t('Chauffeur introuvable', 'السائق غير موجود');
  String get otpInvalid          => _t('Code OTP invalide ou expiré', 'رمز OTP غير صالح أو منتهي');
  String get nfcAlreadyLinked    => _t('Ce badge est déjà utilisé', 'هذه الشارة مستخدمة بالفعل');
  String get sendOtpBtn          => _t('Envoyer OTP', 'إرسال OTP');

  // ── Connectivity ─────────────────────────────────────────────────────────────
  String get noConnectionTitle =>
      _t('Pas de connexion internet', 'لا يوجد اتصال بالإنترنت');

  String get noConnectionBanner =>
      _t('Vérification de la connexion…', 'جارٍ التحقق من الاتصال…');

  String get connectionRestored => _t('Connexion rétablie', 'تم استعادة الاتصال');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}
