// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:i18n/i18n.dart' as i18n;
import 'messages.i18n.dart';

String get _languageCode => 'fr';
String _plural(
  int count, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) => i18n.plural(
  count,
  _languageCode,
  zero: zero,
  one: one,
  two: two,
  few: few,
  many: many,
  other: other,
);
String _ordinal(
  int count, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) => i18n.ordinal(
  count,
  _languageCode,
  zero: zero,
  one: one,
  two: two,
  few: few,
  many: many,
  other: other,
);
String _cardinal(
  int count, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) => i18n.cardinal(
  count,
  _languageCode,
  zero: zero,
  one: one,
  two: two,
  few: few,
  many: many,
  other: other,
);

class MessagesFr extends Messages {
  const MessagesFr();
  String get locale => "fr";
  String get languageCode => "fr";
  CommonMessagesFr get common => CommonMessagesFr(this);
  LoginMessagesFr get login => LoginMessagesFr(this);
  HomeMessagesFr get home => HomeMessagesFr(this);
  NavMessagesFr get nav => NavMessagesFr(this);
  OnboardingMessagesFr get onboarding => OnboardingMessagesFr(this);
  NotificationsIntroMessagesFr get notificationsIntro =>
      NotificationsIntroMessagesFr(this);
  AboutMessagesFr get about => AboutMessagesFr(this);
  SettingsMessagesFr get settings => SettingsMessagesFr(this);
  NotificationsMessagesFr get notifications => NotificationsMessagesFr(this);
  CategoriesMessagesFr get categories => CategoriesMessagesFr(this);
  StoresMessagesFr get stores => StoresMessagesFr(this);
  ChecklistsMessagesFr get checklists => ChecklistsMessagesFr(this);
  NotesWallMessagesFr get notesWall => NotesWallMessagesFr(this);
  PhotoBoardMessagesFr get photoBoard => PhotoBoardMessagesFr(this);
  ShoppingMessagesFr get shopping => ShoppingMessagesFr(this);
  ShareMessagesFr get share => ShareMessagesFr(this);
  RecurrenceMessagesFr get recurrence => RecurrenceMessagesFr(this);
  SyncMessagesFr get sync => SyncMessagesFr(this);
  MarkdownEditorMessagesFr get markdownEditor => MarkdownEditorMessagesFr(this);
}

class CommonMessagesFr extends CommonMessages {
  final MessagesFr _parent;
  const CommonMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "Annuler"
  /// ```
  String get cancel => """Annuler""";

  /// ```dart
  /// "Supprimer"
  /// ```
  String get delete => """Supprimer""";

  /// ```dart
  /// "Enregistrer"
  /// ```
  String get save => """Enregistrer""";

  /// ```dart
  /// "Réessayer"
  /// ```
  String get retry => """Réessayer""";

  /// ```dart
  /// "Actualiser"
  /// ```
  String get refresh => """Actualiser""";

  /// ```dart
  /// "Déconnexion"
  /// ```
  String get logout => """Déconnexion""";

  /// ```dart
  /// "Chargement..."
  /// ```
  String get loading => """Chargement...""";

  /// ```dart
  /// "Erreur"
  /// ```
  String get error => """Erreur""";

  /// ```dart
  /// "Copier"
  /// ```
  String get copy => """Copier""";

  /// ```dart
  /// "Copié"
  /// ```
  String get copied => """Copié""";

  /// ```dart
  /// "Terminé"
  /// ```
  String get closeDialog => """Terminé""";

  /// ```dart
  /// "Retirer"
  /// ```
  String get remove => """Retirer""";

  /// ```dart
  /// "Effacer"
  /// ```
  String get clear => """Effacer""";

  /// ```dart
  /// "Vous n'avez pas la permission de faire cela"
  /// ```
  String get permissionDenied =>
      """Vous n'avez pas la permission de faire cela""";

  /// ```dart
  /// "Aucun accès"
  /// ```
  String get noAccessTitle => """Aucun accès""";

  /// ```dart
  /// "Vous n'avez encore accès à rien dans ce foyer. Un administrateur peut vous accorder des autorisations dans l'application web Pantry."
  /// ```
  String get noAccessBody =>
      """Vous n'avez encore accès à rien dans ce foyer. Un administrateur peut vous accorder des autorisations dans l'application web Pantry.""";
}

class LoginMessagesFr extends LoginMessages {
  final MessagesFr _parent;
  const LoginMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Connectez-vous à votre instance Nextcloud"
  /// ```
  String get connectToNextcloud =>
      """Connectez-vous à votre instance Nextcloud""";

  /// ```dart
  /// "URL du serveur"
  /// ```
  String get serverUrl => """URL du serveur""";

  /// ```dart
  /// "cloud.example.com"
  /// ```
  String get serverUrlHint => """cloud.example.com""";

  /// ```dart
  /// "Connexion"
  /// ```
  String get connect => """Connexion""";

  /// ```dart
  /// """
  /// En attente d'authentification...
  /// Veuillez terminer la connexion dans votre navigateur.
  /// """
  /// ```
  String get waitingForAuth => """En attente d'authentification...
Veuillez terminer la connexion dans votre navigateur.""";

  /// ```dart
  /// "Impossible de se connecter au serveur. Veuillez vérifier l'URL."
  /// ```
  String get couldNotConnect =>
      """Impossible de se connecter au serveur. Veuillez vérifier l'URL.""";

  /// ```dart
  /// "Échec de la connexion. Veuillez réessayer."
  /// ```
  String get loginFailed => """Échec de la connexion. Veuillez réessayer.""";

  /// ```dart
  /// "Voir les détails"
  /// ```
  String get seeDetails => """Voir les détails""";

  /// ```dart
  /// "Détails de l'erreur"
  /// ```
  String get errorDetailsTitle => """Détails de l'erreur""";

  /// ```dart
  /// "Certificat non approuvé"
  /// ```
  String get untrustedCertTitle => """Certificat non approuvé""";

  /// ```dart
  /// "${host} utilise un certificat que votre appareil ne reconnaît pas — généralement parce qu'il est auto-signé. Vérifiez que l'empreinte correspond à celle fournie par votre administrateur avant de l'approuver."
  /// ```
  String untrustedCertBody(String host) =>
      """${host} utilise un certificat que votre appareil ne reconnaît pas — généralement parce qu'il est auto-signé. Vérifiez que l'empreinte correspond à celle fournie par votre administrateur avant de l'approuver.""";

  /// ```dart
  /// "N'approuvez ce certificat que si vous reconnaissez l'empreinte. Approuver un certificat inattendu peut permettre à un attaquant de lire votre trafic."
  /// ```
  String get untrustedCertWarning =>
      """N'approuvez ce certificat que si vous reconnaissez l'empreinte. Approuver un certificat inattendu peut permettre à un attaquant de lire votre trafic.""";

  /// ```dart
  /// "Approuver le certificat"
  /// ```
  String get trustCertificate => """Approuver le certificat""";

  /// ```dart
  /// "Empreinte SHA-256"
  /// ```
  String get certFingerprint => """Empreinte SHA-256""";

  /// ```dart
  /// "Sujet"
  /// ```
  String get certSubject => """Sujet""";

  /// ```dart
  /// "Émetteur"
  /// ```
  String get certIssuer => """Émetteur""";

  /// ```dart
  /// "Validité"
  /// ```
  String get certValidity => """Validité""";

  /// ```dart
  /// "Se connecter avec un mot de passe d'application"
  /// ```
  String get useAppPassword =>
      """Se connecter avec un mot de passe d'application""";

  /// ```dart
  /// "Se connecter avec le navigateur"
  /// ```
  String get useBrowserLogin => """Se connecter avec le navigateur""";

  /// ```dart
  /// "Nom d'utilisateur"
  /// ```
  String get username => """Nom d'utilisateur""";

  /// ```dart
  /// "Mot de passe d'application"
  /// ```
  String get appPassword => """Mot de passe d'application""";

  /// ```dart
  /// "Créez un mot de passe d'application dans Nextcloud sous Paramètres → Sécurité → Appareils et sessions. Utilisez-le si la connexion par navigateur ne s'ouvre pas ou si votre serveur utilise un certificat auto-signé."
  /// ```
  String get appPasswordHelp =>
      """Créez un mot de passe d'application dans Nextcloud sous Paramètres → Sécurité → Appareils et sessions. Utilisez-le si la connexion par navigateur ne s'ouvre pas ou si votre serveur utilise un certificat auto-signé.""";

  /// ```dart
  /// "Veuillez saisir votre nom d'utilisateur et votre mot de passe d'application."
  /// ```
  String get appPasswordMissing =>
      """Veuillez saisir votre nom d'utilisateur et votre mot de passe d'application.""";

  /// ```dart
  /// "Se connecter"
  /// ```
  String get signIn => """Se connecter""";

  /// ```dart
  /// "Impossible de joindre le serveur. Vérifiez l'adresse ainsi que votre connexion réseau ou VPN."
  /// ```
  String get couldNotReachServer =>
      """Impossible de joindre le serveur. Vérifiez l'adresse ainsi que votre connexion réseau ou VPN.""";

  /// ```dart
  /// "Le serveur a mis trop de temps à répondre. Vérifiez votre connexion réseau ou VPN et réessayez."
  /// ```
  String get connectionTimeout =>
      """Le serveur a mis trop de temps à répondre. Vérifiez votre connexion réseau ou VPN et réessayez.""";

  /// ```dart
  /// "Impossible de lire le certificat du serveur pour le vérifier. La connexion est peut-être instable ou le serveur injoignable."
  /// ```
  String get certProbeFailed =>
      """Impossible de lire le certificat du serveur pour le vérifier. La connexion est peut-être instable ou le serveur injoignable.""";
}

class HomeMessagesFr extends HomeMessages {
  final MessagesFr _parent;
  const HomeMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Aucune maison pour le moment."
  /// ```
  String get noHouses => """Aucune maison pour le moment.""";

  /// ```dart
  /// "Les maisons sont des espaces partagés pour votre foyer. Créez votre première maison pour commencer à ajouter des listes, des photos et des notes."
  /// ```
  String get noHousesBody =>
      """Les maisons sont des espaces partagés pour votre foyer. Créez votre première maison pour commencer à ajouter des listes, des photos et des notes.""";

  /// ```dart
  /// "Créer une maison"
  /// ```
  String get createHouse => """Créer une maison""";

  /// ```dart
  /// "Nom de la maison"
  /// ```
  String get houseName => """Nom de la maison""";

  /// ```dart
  /// "Description (facultatif)"
  /// ```
  String get houseDescription => """Description (facultatif)""";

  /// ```dart
  /// "Impossible de créer la maison."
  /// ```
  String get createHouseFailed => """Impossible de créer la maison.""";

  /// ```dart
  /// "Impossible de charger les maisons."
  /// ```
  String get failedToLoadHouses => """Impossible de charger les maisons.""";

  /// ```dart
  /// "Pantry n'est pas installé"
  /// ```
  String get serverAppMissingTitle => """Pantry n'est pas installé""";

  /// ```dart
  /// "Cette application est un client pour l'application Pantry sur Nextcloud. Il semble que Pantry ne soit pas encore installé sur votre serveur. Demandez à votre administrateur de l'installer depuis le magasin d'applications Nextcloud, ou installez-le vous-même si vous avez un accès administrateur."
  /// ```
  String get serverAppMissingBody =>
      """Cette application est un client pour l'application Pantry sur Nextcloud. Il semble que Pantry ne soit pas encore installé sur votre serveur. Demandez à votre administrateur de l'installer depuis le magasin d'applications Nextcloud, ou installez-le vous-même si vous avez un accès administrateur.""";

  /// ```dart
  /// "Ouvrir les apps Nextcloud"
  /// ```
  String get openAppStore => """Ouvrir les apps Nextcloud""";

  /// ```dart
  /// "En savoir plus"
  /// ```
  String get learnMore => """En savoir plus""";
}

class NavMessagesFr extends NavMessages {
  final MessagesFr _parent;
  const NavMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Listes"
  /// ```
  String get checklists => """Listes""";

  /// ```dart
  /// "Tableau photos"
  /// ```
  String get photoBoard => """Tableau photos""";

  /// ```dart
  /// "Mur de notes"
  /// ```
  String get notesWall => """Mur de notes""";
}

class OnboardingMessagesFr extends OnboardingMessages {
  final MessagesFr _parent;
  const OnboardingMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Suivant"
  /// ```
  String get next => """Suivant""";

  /// ```dart
  /// "Retour"
  /// ```
  String get back => """Retour""";

  /// ```dart
  /// "Ignorer"
  /// ```
  String get skip => """Ignorer""";

  /// ```dart
  /// "C'est parti"
  /// ```
  String get done => """C'est parti""";

  /// ```dart
  /// "Étape ${current} sur ${total}"
  /// ```
  String stepLabel(int current, int total) =>
      """Étape ${current} sur ${total}""";

  /// ```dart
  /// "Bienvenue dans Pantry"
  /// ```
  String get welcomeNewTitle => """Bienvenue dans Pantry""";

  /// ```dart
  /// "Faisons un tour rapide du fonctionnement de Pantry pour que tu en profites au maximum."
  /// ```
  String get welcomeNewBody =>
      """Faisons un tour rapide du fonctionnement de Pantry pour que tu en profites au maximum.""";

  /// ```dart
  /// "Nouveautés"
  /// ```
  String get welcomeUpdateTitle => """Nouveautés""";

  /// ```dart
  /// "Pantry a appris quelques nouveaux tours depuis ta dernière visite. Voici un aperçu rapide."
  /// ```
  String get welcomeUpdateBody =>
      """Pantry a appris quelques nouveaux tours depuis ta dernière visite. Voici un aperçu rapide.""";

  /// ```dart
  /// "Les listes ont une nouvelle allure"
  /// ```
  String get checklistsRedesignTitle =>
      """Les listes ont une nouvelle allure""";

  /// ```dart
  /// "La page des listes a été reconstruite de zéro : mise en page plus claire, ajout d'éléments plus rapide et actions rapides sur chaque ligne. Les prochaines pages te présentent les nouveautés."
  /// ```
  String get checklistsRedesignBody =>
      """La page des listes a été reconstruite de zéro : mise en page plus claire, ajout d'éléments plus rapide et actions rapides sur chaque ligne. Les prochaines pages te présentent les nouveautés.""";

  /// ```dart
  /// "Changer de liste depuis le haut"
  /// ```
  String get checklistSelectorTitle => """Changer de liste depuis le haut""";

  /// ```dart
  /// "Touche le nom de la liste ou son icône en haut pour passer d'une liste à l'autre ou en créer une nouvelle."
  /// ```
  String get checklistSelectorBody =>
      """Touche le nom de la liste ou son icône en haut pour passer d'une liste à l'autre ou en créer une nouvelle.""";

  /// ```dart
  /// "Touche pour changer de liste"
  /// ```
  String get checklistSelectorHint => """Touche pour changer de liste""";

  /// ```dart
  /// "Courses"
  /// ```
  String get mockListGroceries => """Courses""";

  /// ```dart
  /// "Bricolage"
  /// ```
  String get mockListHardware => """Bricolage""";

  /// ```dart
  /// "Week-end"
  /// ```
  String get mockListWeekend => """Week-end""";

  /// ```dart
  /// "${count} éléments"
  /// ```
  String mockItemCountSummary(int count) => """${count} éléments""";

  /// ```dart
  /// "Nouvelle liste"
  /// ```
  String get newListLabel => """Nouvelle liste""";

  /// ```dart
  /// "Balaie les éléments pour les gérer"
  /// ```
  String get swipeActionsTitle => """Balaie les éléments pour les gérer""";

  /// ```dart
  /// "Balaie un élément de droite à gauche pour faire apparaître des actions rapides : éditer, déplacer ou supprimer."
  /// ```
  String get swipeActionsBody =>
      """Balaie un élément de droite à gauche pour faire apparaître des actions rapides : éditer, déplacer ou supprimer.""";

  /// ```dart
  /// "Balaie vers la gauche"
  /// ```
  String get swipeActionsHint => """Balaie vers la gauche""";

  /// ```dart
  /// "Balaie vers la droite"
  /// ```
  String get swipeActionsHintBack => """Balaie vers la droite""";

  /// ```dart
  /// "Actions rapides sur chaque élément"
  /// ```
  String get quickActionsTitle => """Actions rapides sur chaque élément""";

  /// ```dart
  /// "Chaque élément affiche des boutons d'action à son extrémité — clique dessus pour modifier, déplacer ou supprimer l'élément sans l'ouvrir."
  /// ```
  String get quickActionsBody =>
      """Chaque élément affiche des boutons d'action à son extrémité — clique dessus pour modifier, déplacer ou supprimer l'élément sans l'ouvrir.""";

  /// ```dart
  /// "Une façon plus rapide d'ajouter"
  /// ```
  String get addItemsTitle => """Une façon plus rapide d'ajouter""";

  /// ```dart
  /// "Touche le champ en bas pour saisir un nouvel élément, puis associe-lui une catégorie, une quantité, un type ou une photo via les chips au-dessus."
  /// ```
  String get addItemsBody =>
      """Touche le champ en bas pour saisir un nouvel élément, puis associe-lui une catégorie, une quantité, un type ou une photo via les chips au-dessus.""";

  /// ```dart
  /// "Courses"
  /// ```
  String get mockComposeListName => """Courses""";

  /// ```dart
  /// "Masquer la carte de progression"
  /// ```
  String get progressHeroTitle => """Masquer la carte de progression""";

  /// ```dart
  /// "Pas besoin de l'anneau de progression en haut ? Balaie-le pour le retirer."
  /// ```
  String get progressHeroBody =>
      """Pas besoin de l'anneau de progression en haut ? Balaie-le pour le retirer.""";

  /// ```dart
  /// "Tu peux la réafficher à tout moment depuis le menu de la liste → ${toggle}."
  /// ```
  String progressHeroBringBack(String toggle) =>
      """Tu peux la réafficher à tout moment depuis le menu de la liste → ${toggle}.""";

  /// ```dart
  /// "Balaie pour masquer"
  /// ```
  String get progressHeroHint => """Balaie pour masquer""";

  /// ```dart
  /// "Masque la carte de progression"
  /// ```
  String get progressHeroDismissTitle => """Masque la carte de progression""";

  /// ```dart
  /// "Tu n'as pas besoin de l'anneau de progression en haut ? Clique sur le X de la carte pour la masquer."
  /// ```
  String get progressHeroDismissBody =>
      """Tu n'as pas besoin de l'anneau de progression en haut ? Clique sur le X de la carte pour la masquer.""";

  /// ```dart
  /// "Épingle des listes à ton écran d'accueil"
  /// ```
  String get pinnedListsTitle => """Épingle des listes à ton écran d'accueil""";

  /// ```dart
  /// "Ajoute le widget Pantry à ton écran d'accueil pour voir d'un coup d'œil combien d'articles restent sur tes listes préférées — sans ouvrir l'app."
  /// ```
  String get pinnedListsBody =>
      """Ajoute le widget Pantry à ton écran d'accueil pour voir d'un coup d'œil combien d'articles restent sur tes listes préférées — sans ouvrir l'app.""";

  /// ```dart
  /// "Ouvre une liste, touche ${menu} en haut à droite, puis choisis ${action}. Les listes épinglées apparaissent dans le widget ; désépingle-les pour les masquer."
  /// ```
  String pinnedListsHow(String menu, String action) =>
      """Ouvre une liste, touche ${menu} en haut à droite, puis choisis ${action}. Les listes épinglées apparaissent dans le widget ; désépingle-les pour les masquer.""";

  /// ```dart
  /// "le menu"
  /// ```
  String get pinnedListsMenuLabel => """le menu""";

  /// ```dart
  /// "Épingler la liste"
  /// ```
  String get pinnedListsActionLabel => """Épingler la liste""";

  /// ```dart
  /// "Pantry"
  /// ```
  String get pinnedListsWidgetTitle => """Pantry""";

  /// ```dart
  /// "${_plural(count, one: '1 restant', many: '${count} restants')}"
  /// ```
  String pinnedListsWidgetItemsLeft(int count) =>
      """${_plural(count, one: '1 restant', many: '${count} restants')}""";

  /// ```dart
  /// "Tout est fait"
  /// ```
  String get pinnedListsWidgetEmpty => """Tout est fait""";

  /// ```dart
  /// "Garde les notes importantes en haut"
  /// ```
  String get pinnedNotesTitle => """Garde les notes importantes en haut""";

  /// ```dart
  /// "Épingle une note depuis son menu de débordement pour la fixer en haut de ton mur de notes, au-dessus des notes plus récentes."
  /// ```
  String get pinnedNotesBody =>
      """Épingle une note depuis son menu de débordement pour la fixer en haut de ton mur de notes, au-dessus des notes plus récentes.""";

  /// ```dart
  /// "Mot de passe Wi-Fi"
  /// ```
  String get mockPinnedNoteTitle => """Mot de passe Wi-Fi""";

  /// ```dart
  /// """
  /// Réseau : Maison
  /// Mot de passe : pantry-rocks
  /// """
  /// ```
  String get mockPinnedNoteContent => """Réseau : Maison
Mot de passe : pantry-rocks""";

  /// ```dart
  /// "Tomates"
  /// ```
  String get mockItemName => """Tomates""";

  /// ```dart
  /// "x2"
  /// ```
  String get mockItemQuantity => """x2""";

  /// ```dart
  /// "Légumes"
  /// ```
  String get mockItemCategory => """Légumes""";

  /// ```dart
  /// "Ampoules"
  /// ```
  String get mockHardwareItemName => """Ampoules""";

  /// ```dart
  /// "Lait"
  /// ```
  String get mockBulkItemThird => """Lait""";

  /// ```dart
  /// "Pain"
  /// ```
  String get mockBulkItemFourth => """Pain""";

  /// ```dart
  /// "Tout dans une seule vue"
  /// ```
  String get allListsTitle => """Tout dans une seule vue""";

  /// ```dart
  /// "Ouvre la vue Toutes les listes depuis le sélecteur pour voir les éléments de toutes tes listes ensemble. Quand tu ajoutes un élément depuis ici, le formulaire te demande dans quelle liste le placer — choisis-la dans le chip Liste."
  /// ```
  String get allListsBody =>
      """Ouvre la vue Toutes les listes depuis le sélecteur pour voir les éléments de toutes tes listes ensemble. Quand tu ajoutes un élément depuis ici, le formulaire te demande dans quelle liste le placer — choisis-la dans le chip Liste.""";

  /// ```dart
  /// "Ajoute plusieurs éléments d'un coup"
  /// ```
  String get bulkAddTitle => """Ajoute plusieurs éléments d'un coup""";

  /// ```dart
  /// "Active le bouton Multiple et le champ devient une zone multi-ligne — chaque ligne devient un élément distinct. Pratique quand tu colles une liste ou que tu notes toutes tes courses d'un seul coup."
  /// ```
  String get bulkAddBody =>
      """Active le bouton Multiple et le champ devient une zone multi-ligne — chaque ligne devient un élément distinct. Pratique quand tu colles une liste ou que tu notes toutes tes courses d'un seul coup.""";

  /// ```dart
  /// "Agissez sur plusieurs articles à la fois"
  /// ```
  String get bulkSelectTitle => """Agissez sur plusieurs articles à la fois""";

  /// ```dart
  /// "Appuyez longuement sur un article — ou touchez Sélectionner dans le menu — pour commencer la sélection, puis déplacez, copiez, catégorisez ou supprimez tout ce que vous avez choisi en une seule fois."
  /// ```
  String get bulkSelectBody =>
      """Appuyez longuement sur un article — ou touchez Sélectionner dans le menu — pour commencer la sélection, puis déplacez, copiez, catégorisez ou supprimez tout ce que vous avez choisi en une seule fois.""";

  /// ```dart
  /// "Scannez un code-barres pour ajouter des articles"
  /// ```
  String get barcodeScanTitle =>
      """Scannez un code-barres pour ajouter des articles""";

  /// ```dart
  /// "Touchez le bouton de scan dans la barre d'ajout et dirigez la caméra vers le code-barres d'un produit. Pantry en trouve le nom, la catégorie et la photo et les remplit pour vous — ou saisissez le numéro à la main. Le premier scan d'un produit lance la recherche ; ensuite, c'est instantané pour toute votre maison."
  /// ```
  String get barcodeScanBody =>
      """Touchez le bouton de scan dans la barre d'ajout et dirigez la caméra vers le code-barres d'un produit. Pantry en trouve le nom, la catégorie et la photo et les remplit pour vous — ou saisissez le numéro à la main. Le premier scan d'un produit lance la recherche ; ensuite, c'est instantané pour toute votre maison.""";

  /// ```dart
  /// "Coca-Cola Zero"
  /// ```
  String get barcodeScanMockName => """Coca-Cola Zero""";

  /// ```dart
  /// "Boissons"
  /// ```
  String get barcodeScanMockCategory => """Boissons""";

  /// ```dart
  /// "Ajoutez des prix à vos articles"
  /// ```
  String get priceTitle => """Ajoutez des prix à vos articles""";

  /// ```dart
  /// "Donnez à un article un prix — un montant unique ou une fourchette — dans la devise de votre choix. Il apparaît sous forme d'étiquette sur l'article, et vous pouvez filtrer votre liste par prix pour respecter votre budget."
  /// ```
  String get priceBody =>
      """Donnez à un article un prix — un montant unique ou une fourchette — dans la devise de votre choix. Il apparaît sous forme d'étiquette sur l'article, et vous pouvez filtrer votre liste par prix pour respecter votre budget.""";

  /// ```dart
  /// "Huile d'olive"
  /// ```
  String get priceMockName => """Huile d'olive""";

  /// ```dart
  /// "Fais tes courses magasin par magasin"
  /// ```
  String get shoppingIntroTitle => """Fais tes courses magasin par magasin""";

  /// ```dart
  /// "Lance une virée à partir de tes listes, parcours chaque magasin dans l'ordre et coche les articles au fur et à mesure — avec un total des prix en direct."
  /// ```
  String get shoppingIntroBody =>
      """Lance une virée à partir de tes listes, parcours chaque magasin dans l'ordre et coche les articles au fur et à mesure — avec un total des prix en direct.""";

  /// ```dart
  /// "Supermarché"
  /// ```
  String get shoppingMockStoreActive => """Supermarché""";

  /// ```dart
  /// "Pharmacie"
  /// ```
  String get shoppingMockStoreNext => """Pharmacie""";

  /// ```dart
  /// "* Nécessite Pantry pour Nextcloud v${version}+"
  /// ```
  String serverRequirementNote(String version) =>
      """* Nécessite Pantry pour Nextcloud v${version}+""";
  DevOnboardingMessagesFr get dev => DevOnboardingMessagesFr(this);
}

class DevOnboardingMessagesFr extends DevOnboardingMessages {
  final OnboardingMessagesFr _parent;
  const DevOnboardingMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Afficher l'intro"
  /// ```
  String get showOnboarding => """Afficher l'intro""";

  /// ```dart
  /// "Aperçu des nouveautés"
  /// ```
  String get pickLastSeenTitle => """Aperçu des nouveautés""";

  /// ```dart
  /// "Choisis la version dont tu veux voir les nouveautés, telles qu'un utilisateur les verrait en passant à cette version."
  /// ```
  String get pickLastSeenBody =>
      """Choisis la version dont tu veux voir les nouveautés, telles qu'un utilisateur les verrait en passant à cette version.""";

  /// ```dart
  /// "Jamais vue (nouvel utilisateur)"
  /// ```
  String get neverSeen => """Jamais vue (nouvel utilisateur)""";

  /// ```dart
  /// "Forcer toutes les fonctionnalités"
  /// ```
  String get forceAllFeatures => """Forcer toutes les fonctionnalités""";

  /// ```dart
  /// "Envoyer une notification de test"
  /// ```
  String get sendTestNotification => """Envoyer une notification de test""";
}

class NotificationsIntroMessagesFr extends NotificationsIntroMessages {
  final MessagesFr _parent;
  const NotificationsIntroMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Restez informé"
  /// ```
  String get title => """Restez informé""";

  /// ```dart
  /// "Pantry peut vous notifier lorsque les membres du foyer ajoutent des articles aux listes, téléchargent des photos ou laissent des notes. Les notifications sont récupérées depuis votre propre serveur Nextcloud — rien ne passe par Google ou des tiers."
  /// ```
  String get body =>
      """Pantry peut vous notifier lorsque les membres du foyer ajoutent des articles aux listes, téléchargent des photos ou laissent des notes. Les notifications sont récupérées depuis votre propre serveur Nextcloud — rien ne passe par Google ou des tiers.""";

  /// ```dart
  /// "Alertes d'activité du foyer"
  /// ```
  String get bullet1 => """Alertes d'activité du foyer""";

  /// ```dart
  /// "Récupérées directement depuis votre serveur"
  /// ```
  String get bullet2 => """Récupérées directement depuis votre serveur""";

  /// ```dart
  /// "Fonctionne même lorsque l'app est fermée"
  /// ```
  String get bullet3 => """Fonctionne même lorsque l'app est fermée""";

  /// ```dart
  /// "Activer les notifications"
  /// ```
  String get enableButton => """Activer les notifications""";

  /// ```dart
  /// "Pas maintenant"
  /// ```
  String get skipButton => """Pas maintenant""";

  /// ```dart
  /// "Permission refusée"
  /// ```
  String get permissionDeniedTitle => """Permission refusée""";

  /// ```dart
  /// "Vous pourrez activer les notifications plus tard dans les réglages de l'app. Si votre appareil les bloque, vous devrez d'abord les autoriser dans les réglages système."
  /// ```
  String get permissionDeniedBody =>
      """Vous pourrez activer les notifications plus tard dans les réglages de l'app. Si votre appareil les bloque, vous devrez d'abord les autoriser dans les réglages système.""";

  /// ```dart
  /// "OK"
  /// ```
  String get ok => """OK""";
}

class AboutMessagesFr extends AboutMessages {
  final MessagesFr _parent;
  const AboutMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "À propos"
  /// ```
  String get title => """À propos""";

  /// ```dart
  /// "Développeur"
  /// ```
  String get developer => """Développeur""";

  /// ```dart
  /// "E-mail"
  /// ```
  String get email => """E-mail""";

  /// ```dart
  /// "Code source"
  /// ```
  String get repository => """Code source""";

  /// ```dart
  /// "App Nextcloud"
  /// ```
  String get nextcloudApp => """App Nextcloud""";

  /// ```dart
  /// "Politique de confidentialité"
  /// ```
  String get privacyPolicy => """Politique de confidentialité""";

  /// ```dart
  /// "Commentaires & problèmes"
  /// ```
  String get feedback => """Commentaires & problèmes""";

  /// ```dart
  /// "Serveur Nextcloud"
  /// ```
  String get serverVersion => """Serveur Nextcloud""";

  /// ```dart
  /// "Pantry sur le serveur"
  /// ```
  String get pantryServerVersion => """Pantry sur le serveur""";

  /// ```dart
  /// "Inconnu"
  /// ```
  String get versionUnknown => """Inconnu""";

  /// ```dart
  /// "Offrez-moi un café"
  /// ```
  String get buyMeACoffee => """Offrez-moi un café""";
}

class SettingsMessagesFr extends SettingsMessages {
  final MessagesFr _parent;
  const SettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Réglages de l'app"
  /// ```
  String get title => """Réglages de l'app""";

  /// ```dart
  /// "Général"
  /// ```
  String get generalSection => """Général""";

  /// ```dart
  /// "Interface"
  /// ```
  String get interfaceSection => """Interface""";

  /// ```dart
  /// "Action par défaut au toucher"
  /// ```
  String get defaultItemTapAction => """Action par défaut au toucher""";

  /// ```dart
  /// "Ce qui se passe quand vous touchez la ligne d'un élément."
  /// ```
  String get defaultItemTapActionBody =>
      """Ce qui se passe quand vous touchez la ligne d'un élément.""";
  ItemTapActionNamesSettingsMessagesFr get itemTapActionNames =>
      ItemTapActionNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Action par défaut à l'appui long"
  /// ```
  String get defaultItemLongPressAction =>
      """Action par défaut à l'appui long""";

  /// ```dart
  /// "Ce qui se passe quand vous appuyez longuement sur la ligne d'un élément."
  /// ```
  String get defaultItemLongPressActionBody =>
      """Ce qui se passe quand vous appuyez longuement sur la ligne d'un élément.""";
  ItemLongPressActionNamesSettingsMessagesFr get itemLongPressActionNames =>
      ItemLongPressActionNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Position de la case à cocher"
  /// ```
  String get checkboxPosition => """Position de la case à cocher""";

  /// ```dart
  /// "De quel côté de la ligne la case à cocher apparaît."
  /// ```
  String get checkboxPositionBody =>
      """De quel côté de la ligne la case à cocher apparaît.""";
  CheckboxPositionNamesSettingsMessagesFr get checkboxPositionNames =>
      CheckboxPositionNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Densité de la liste"
  /// ```
  String get density => """Densité de la liste""";

  /// ```dart
  /// "L'espace occupé par chaque article dans vos listes."
  /// ```
  String get densityBody =>
      """L'espace occupé par chaque article dans vos listes.""";
  DensityNamesSettingsMessagesFr get densityNames =>
      DensityNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Actions par balayage"
  /// ```
  String get swipeActions => """Actions par balayage""";

  /// ```dart
  /// "Balayez les éléments vers la gauche pour afficher des actions rapides. Désactivé, les actions passent dans un menu sur chaque élément."
  /// ```
  String get swipeActionsBody =>
      """Balayez les éléments vers la gauche pour afficher des actions rapides. Désactivé, les actions passent dans un menu sur chaque élément.""";

  /// ```dart
  /// "Actions des éléments"
  /// ```
  String get itemActions => """Actions des éléments""";

  /// ```dart
  /// "Affiche des actions rapides sur chaque élément. Désactivé, les actions passent dans un menu sur chaque élément."
  /// ```
  String get itemActionsBody =>
      """Affiche des actions rapides sur chaque élément. Désactivé, les actions passent dans un menu sur chaque élément.""";

  /// ```dart
  /// "Réutiliser les articles existants lors de l'ajout"
  /// ```
  String get reuseExistingItems =>
      """Réutiliser les articles existants lors de l'ajout""";

  /// ```dart
  /// "Lorsque vous ajoutez un article qui existe déjà dans la liste, réutiliser cet article."
  /// ```
  String get reuseExistingItemsBody =>
      """Lorsque vous ajoutez un article qui existe déjà dans la liste, réutiliser cet article.""";
  ReuseExistingItemsNamesSettingsMessagesFr get reuseExistingItemsNames =>
      ReuseExistingItemsNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Ordre de navigation"
  /// ```
  String get navOrderTitle => """Ordre de navigation""";

  /// ```dart
  /// "Réorganisez les onglets de la barre de navigation. Le premier élément s'ouvre au démarrage."
  /// ```
  String get navOrderSubtitle =>
      """Réorganisez les onglets de la barre de navigation. Le premier élément s'ouvre au démarrage.""";

  /// ```dart
  /// "Faites glisser pour réorganiser les onglets. La première section visible s'ouvre au démarrage de l'application. Désactivez les sections que vous n'utilisez pas pour masquer leur onglet ; au moins une doit rester activée."
  /// ```
  String get navOrderBody =>
      """Faites glisser pour réorganiser les onglets. La première section visible s'ouvre au démarrage de l'application. Désactivez les sections que vous n'utilisez pas pour masquer leur onglet ; au moins une doit rester activée.""";

  /// ```dart
  /// "S'ouvre au démarrage"
  /// ```
  String get navOrderDefaultHint => """S'ouvre au démarrage""";

  /// ```dart
  /// "Réinitialiser"
  /// ```
  String get navOrderReset => """Réinitialiser""";

  /// ```dart
  /// "Détails de l'article"
  /// ```
  String get visibleChipsTitle => """Détails de l'article""";

  /// ```dart
  /// "Choisissez les détails affichés sur chaque article."
  /// ```
  String get visibleChipsSubtitle =>
      """Choisissez les détails affichés sur chaque article.""";

  /// ```dart
  /// "Désactivez les détails que vous ne voulez pas voir affichés sur les lignes d'articles."
  /// ```
  String get visibleChipsBody =>
      """Désactivez les détails que vous ne voulez pas voir affichés sur les lignes d'articles.""";

  /// ```dart
  /// "Réinitialiser"
  /// ```
  String get visibleChipsReset => """Réinitialiser""";
  ChipNamesSettingsMessagesFr get chipNames =>
      ChipNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Langue"
  /// ```
  String get language => """Langue""";

  /// ```dart
  /// "Par défaut du système"
  /// ```
  String get systemLanguage => """Par défaut du système""";

  /// ```dart
  /// "Thème"
  /// ```
  String get theme => """Thème""";
  ThemeNamesSettingsMessagesFr get themeNames =>
      ThemeNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Utiliser la couleur du thème Nextcloud"
  /// ```
  String get useServerThemeColor =>
      """Utiliser la couleur du thème Nextcloud""";

  /// ```dart
  /// "Teinte l'application avec la couleur du thème de votre utilisateur Nextcloud. Désactivez pour utiliser les couleurs propres à l'application."
  /// ```
  String get useServerThemeColorBody =>
      """Teinte l'application avec la couleur du thème de votre utilisateur Nextcloud. Désactivez pour utiliser les couleurs propres à l'application.""";

  /// ```dart
  /// "Notifications"
  /// ```
  String get notificationsSection => """Notifications""";

  /// ```dart
  /// "Activer les notifications"
  /// ```
  String get enableNotifications => """Activer les notifications""";

  /// ```dart
  /// "Afficher des alertes lorsque les membres du foyer ajoutent ou modifient du contenu."
  /// ```
  String get enableNotificationsBody =>
      """Afficher des alertes lorsque les membres du foyer ajoutent ou modifient du contenu.""";

  /// ```dart
  /// "Vérifier les nouvelles activités"
  /// ```
  String get pollInterval => """Vérifier les nouvelles activités""";

  /// ```dart
  /// "Toutes les 15 minutes"
  /// ```
  String get pollInterval15m => """Toutes les 15 minutes""";

  /// ```dart
  /// "Toutes les 30 minutes"
  /// ```
  String get pollInterval30m => """Toutes les 30 minutes""";

  /// ```dart
  /// "Toutes les heures"
  /// ```
  String get pollInterval1h => """Toutes les heures""";

  /// ```dart
  /// "Toutes les 2 heures"
  /// ```
  String get pollInterval2h => """Toutes les 2 heures""";

  /// ```dart
  /// "Toutes les 6 heures"
  /// ```
  String get pollInterval6h => """Toutes les 6 heures""";

  /// ```dart
  /// "La permission de notification a été refusée. Activez-la dans les réglages système."
  /// ```
  String get permissionDenied =>
      """La permission de notification a été refusée. Activez-la dans les réglages système.""";

  /// ```dart
  /// "Actualisation automatique"
  /// ```
  String get refreshSection => """Actualisation automatique""";

  /// ```dart
  /// "À quelle fréquence chaque écran vérifie les changements sur le serveur pendant que vous le consultez. Vous pouvez toujours tirer vers le bas pour actualiser manuellement."
  /// ```
  String get refreshSectionBody =>
      """À quelle fréquence chaque écran vérifie les changements sur le serveur pendant que vous le consultez. Vous pouvez toujours tirer vers le bas pour actualiser manuellement.""";

  /// ```dart
  /// "Listes"
  /// ```
  String get checklistRefresh => """Listes""";

  /// ```dart
  /// "Notes"
  /// ```
  String get notesRefresh => """Notes""";

  /// ```dart
  /// "Photos"
  /// ```
  String get photosRefresh => """Photos""";

  /// ```dart
  /// "Mode courses"
  /// ```
  String get shoppingRefresh => """Mode courses""";

  /// ```dart
  /// "Désactivé"
  /// ```
  String get refreshOff => """Désactivé""";

  /// ```dart
  /// "Comme les listes"
  /// ```
  String get refreshInherit => """Comme les listes""";

  /// ```dart
  /// "Toutes les 15 secondes"
  /// ```
  String get refresh15s => """Toutes les 15 secondes""";

  /// ```dart
  /// "Toutes les 30 secondes"
  /// ```
  String get refresh30s => """Toutes les 30 secondes""";

  /// ```dart
  /// "Chaque minute"
  /// ```
  String get refresh1m => """Chaque minute""";

  /// ```dart
  /// "Toutes les 2 minutes"
  /// ```
  String get refresh2m => """Toutes les 2 minutes""";

  /// ```dart
  /// "Toutes les 5 minutes"
  /// ```
  String get refresh5m => """Toutes les 5 minutes""";
}

class ItemTapActionNamesSettingsMessagesFr
    extends ItemTapActionNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ItemTapActionNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Marquer comme fait"
  /// ```
  String get done => """Marquer comme fait""";

  /// ```dart
  /// "Voir"
  /// ```
  String get view => """Voir""";

  /// ```dart
  /// "Modifier"
  /// ```
  String get edit => """Modifier""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get none => """Aucune""";
}

class ItemLongPressActionNamesSettingsMessagesFr
    extends ItemLongPressActionNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ItemLongPressActionNamesSettingsMessagesFr(this._parent)
    : super(_parent);

  /// ```dart
  /// "Sélection multiple/Réorganiser"
  /// ```
  String get multiselect => """Sélection multiple/Réorganiser""";

  /// ```dart
  /// "Marquer comme fait"
  /// ```
  String get done => """Marquer comme fait""";

  /// ```dart
  /// "Voir"
  /// ```
  String get view => """Voir""";

  /// ```dart
  /// "Modifier"
  /// ```
  String get edit => """Modifier""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get none => """Aucune""";
}

class CheckboxPositionNamesSettingsMessagesFr
    extends CheckboxPositionNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const CheckboxPositionNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Début"
  /// ```
  String get start => """Début""";

  /// ```dart
  /// "Fin"
  /// ```
  String get end => """Fin""";
}

class DensityNamesSettingsMessagesFr extends DensityNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const DensityNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Normale"
  /// ```
  String get normal => """Normale""";

  /// ```dart
  /// "Compacte"
  /// ```
  String get dense => """Compacte""";

  /// ```dart
  /// "Très compacte"
  /// ```
  String get compact => """Très compacte""";
}

class ReuseExistingItemsNamesSettingsMessagesFr
    extends ReuseExistingItemsNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ReuseExistingItemsNamesSettingsMessagesFr(this._parent)
    : super(_parent);

  /// ```dart
  /// "Toujours demander"
  /// ```
  String get ask => """Toujours demander""";

  /// ```dart
  /// "Toujours réutiliser"
  /// ```
  String get reuse => """Toujours réutiliser""";

  /// ```dart
  /// "Ne jamais réutiliser"
  /// ```
  String get never => """Ne jamais réutiliser""";
}

class ChipNamesSettingsMessagesFr extends ChipNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ChipNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Catégorie"
  /// ```
  String get category => """Catégorie""";

  /// ```dart
  /// "Magasin"
  /// ```
  String get store => """Magasin""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get quantity => """Quantité""";

  /// ```dart
  /// "Prix"
  /// ```
  String get price => """Prix""";

  /// ```dart
  /// "Note"
  /// ```
  String get note => """Note""";

  /// ```dart
  /// "Unique"
  /// ```
  String get oneTime => """Unique""";

  /// ```dart
  /// "Récurrent"
  /// ```
  String get recurring => """Récurrent""";

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";
}

class ThemeNamesSettingsMessagesFr extends ThemeNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ThemeNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Par défaut du système"
  /// ```
  String get system => """Par défaut du système""";

  /// ```dart
  /// "Clair"
  /// ```
  String get light => """Clair""";

  /// ```dart
  /// "Sombre"
  /// ```
  String get dark => """Sombre""";
}

class NotificationsMessagesFr extends NotificationsMessages {
  final MessagesFr _parent;
  const NotificationsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Notifications"
  /// ```
  String get title => """Notifications""";

  /// ```dart
  /// "Aucune nouvelle notification."
  /// ```
  String get empty => """Aucune nouvelle notification.""";

  /// ```dart
  /// "Impossible de charger les notifications."
  /// ```
  String get failedToLoad => """Impossible de charger les notifications.""";

  /// ```dart
  /// "Tout ignorer"
  /// ```
  String get dismissAll => """Tout ignorer""";

  /// ```dart
  /// "à l'instant"
  /// ```
  String get justNow => """à l'instant""";

  /// ```dart
  /// "il y a ${count} min"
  /// ```
  String minutesAgo(int count) => """il y a ${count} min""";

  /// ```dart
  /// "il y a ${count} h"
  /// ```
  String hoursAgo(int count) => """il y a ${count} h""";

  /// ```dart
  /// "il y a ${count} j"
  /// ```
  String daysAgo(int count) => """il y a ${count} j""";
}

class CategoriesMessagesFr extends CategoriesMessages {
  final MessagesFr _parent;
  const CategoriesMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Gérer les catégories"
  /// ```
  String get manageTitle => """Gérer les catégories""";

  /// ```dart
  /// "Aucune catégorie pour le moment."
  /// ```
  String get noCategories => """Aucune catégorie pour le moment.""";

  /// ```dart
  /// "Modifier la catégorie"
  /// ```
  String get editTitle => """Modifier la catégorie""";

  /// ```dart
  /// "Nouvelle catégorie"
  /// ```
  String get addTitle => """Nouvelle catégorie""";

  /// ```dart
  /// "Nom"
  /// ```
  String get name => """Nom""";

  /// ```dart
  /// "Icône"
  /// ```
  String get icon => """Icône""";

  /// ```dart
  /// "Couleur"
  /// ```
  String get color => """Couleur""";

  /// ```dart
  /// "Impossible d'enregistrer la catégorie."
  /// ```
  String get saveFailed => """Impossible d'enregistrer la catégorie.""";

  /// ```dart
  /// "Impossible de supprimer la catégorie."
  /// ```
  String get deleteFailed => """Impossible de supprimer la catégorie.""";

  /// ```dart
  /// "Supprimer cette catégorie ?"
  /// ```
  String get deleteConfirm => """Supprimer cette catégorie ?""";

  /// ```dart
  /// "Les articles de cette catégorie seront non catégorisés. Cette action est irréversible."
  /// ```
  String get deleteConfirmBody =>
      """Les articles de cette catégorie seront non catégorisés. Cette action est irréversible.""";
  SortCategoriesMessagesFr get sort => SortCategoriesMessagesFr(this);
}

class SortCategoriesMessagesFr extends SortCategoriesMessages {
  final CategoriesMessagesFr _parent;
  const SortCategoriesMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Nom A–Z"
  /// ```
  String get nameAZ => """Nom A–Z""";

  /// ```dart
  /// "Nom Z–A"
  /// ```
  String get nameZA => """Nom Z–A""";

  /// ```dart
  /// "Personnalisé"
  /// ```
  String get custom => """Personnalisé""";
}

class StoresMessagesFr extends StoresMessages {
  final MessagesFr _parent;
  const StoresMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Gérer les magasins"
  /// ```
  String get manageTitle => """Gérer les magasins""";

  /// ```dart
  /// "Aucun magasin pour le moment."
  /// ```
  String get noStores => """Aucun magasin pour le moment.""";

  /// ```dart
  /// "Modifier le magasin"
  /// ```
  String get editTitle => """Modifier le magasin""";

  /// ```dart
  /// "Nouveau magasin"
  /// ```
  String get addTitle => """Nouveau magasin""";

  /// ```dart
  /// "Nom"
  /// ```
  String get name => """Nom""";

  /// ```dart
  /// "Icône"
  /// ```
  String get icon => """Icône""";

  /// ```dart
  /// "Couleur"
  /// ```
  String get color => """Couleur""";

  /// ```dart
  /// "Impossible d'enregistrer le magasin."
  /// ```
  String get saveFailed => """Impossible d'enregistrer le magasin.""";

  /// ```dart
  /// "Impossible de supprimer le magasin."
  /// ```
  String get deleteFailed => """Impossible de supprimer le magasin.""";

  /// ```dart
  /// "Supprimer ce magasin ?"
  /// ```
  String get deleteConfirm => """Supprimer ce magasin ?""";

  /// ```dart
  /// "Ce magasin sera retiré de tous les articles. Cette action est irréversible."
  /// ```
  String get deleteConfirmBody =>
      """Ce magasin sera retiré de tous les articles. Cette action est irréversible.""";

  /// ```dart
  /// "Marque/chaîne"
  /// ```
  String get brand => """Marque/chaîne""";

  /// ```dart
  /// "p. ex. Walmart, IKEA"
  /// ```
  String get brandHint => """p. ex. Walmart, IKEA""";

  /// ```dart
  /// "Emplacement"
  /// ```
  String get location => """Emplacement""";

  /// ```dart
  /// "p. ex. 12 rue Principale"
  /// ```
  String get locationHint => """p. ex. 12 rue Principale""";

  /// ```dart
  /// "Horaires d'ouverture"
  /// ```
  String get openingHours => """Horaires d'ouverture""";

  /// ```dart
  /// "Ajouter des horaires"
  /// ```
  String get addOpeningHours => """Ajouter des horaires""";

  /// ```dart
  /// "Début"
  /// ```
  String get openingHoursStart => """Début""";

  /// ```dart
  /// "Fin"
  /// ```
  String get openingHoursEnd => """Fin""";

  /// ```dart
  /// "Ajouter"
  /// ```
  String get openingHoursAdd => """Ajouter""";

  /// ```dart
  /// "Contact"
  /// ```
  String get contact => """Contact""";

  /// ```dart
  /// "p. ex. téléphone, site web, réseaux sociaux"
  /// ```
  String get contactHint => """p. ex. téléphone, site web, réseaux sociaux""";

  /// ```dart
  /// "Responsable"
  /// ```
  String get responsible => """Responsable""";

  /// ```dart
  /// "p. ex. gérant du magasin"
  /// ```
  String get responsibleHint => """p. ex. gérant du magasin""";

  /// ```dart
  /// "Notes"
  /// ```
  String get notes => """Notes""";

  /// ```dart
  /// "Toute autre chose à retenir"
  /// ```
  String get notesHint => """Toute autre chose à retenir""";

  /// ```dart
  /// "Aucun détail ajouté pour le moment."
  /// ```
  String get noDetails => """Aucun détail ajouté pour le moment.""";

  /// ```dart
  /// "Modifier"
  /// ```
  String get editAction => """Modifier""";
  SortStoresMessagesFr get sort => SortStoresMessagesFr(this);
}

class SortStoresMessagesFr extends SortStoresMessages {
  final StoresMessagesFr _parent;
  const SortStoresMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Nom A–Z"
  /// ```
  String get nameAZ => """Nom A–Z""";

  /// ```dart
  /// "Nom Z–A"
  /// ```
  String get nameZA => """Nom Z–A""";

  /// ```dart
  /// "Personnalisé"
  /// ```
  String get custom => """Personnalisé""";
}

class ChecklistsMessagesFr extends ChecklistsMessages {
  final MessagesFr _parent;
  const ChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Catégories"
  /// ```
  String get categories => """Catégories""";

  /// ```dart
  /// "Aucune liste pour le moment."
  /// ```
  String get noChecklists => """Aucune liste pour le moment.""";

  /// ```dart
  /// "Aucun article dans cette liste."
  /// ```
  String get noItems => """Aucun article dans cette liste.""";

  /// ```dart
  /// "Aucun article ne correspond à votre recherche."
  /// ```
  String get noSearchResults =>
      """Aucun article ne correspond à votre recherche.""";

  /// ```dart
  /// "Filtrer..."
  /// ```
  String get searchHint => """Filtrer...""";
  BarcodeChecklistsMessagesFr get barcode => BarcodeChecklistsMessagesFr(this);

  /// ```dart
  /// "Tout"
  /// ```
  String get allCategories => """Tout""";

  /// ```dart
  /// "Tout"
  /// ```
  String get allListsChip => """Tout""";

  /// ```dart
  /// "Filtrer par liste"
  /// ```
  String get filterByList => """Filtrer par liste""";

  /// ```dart
  /// "Filtrer par catégorie"
  /// ```
  String get filterByCategory => """Filtrer par catégorie""";
  FiltersChecklistsMessagesFr get filters => FiltersChecklistsMessagesFr(this);

  /// ```dart
  /// "Impossible de charger les listes."
  /// ```
  String get failedToLoad => """Impossible de charger les listes.""";

  /// ```dart
  /// "Impossible de charger les articles."
  /// ```
  String get failedToLoadItems => """Impossible de charger les articles.""";

  /// ```dart
  /// "Terminés ($count)"
  /// ```
  String completedCount(int count) => """Terminés ($count)""";

  /// ```dart
  /// "Modifier l'article"
  /// ```
  String get editItem => """Modifier l'article""";

  /// ```dart
  /// "Supprimer l'article"
  /// ```
  String get removeItem => """Supprimer l'article""";

  /// ```dart
  /// "Déplacer vers une liste"
  /// ```
  String get moveItem => """Déplacer vers une liste""";

  /// ```dart
  /// "Impossible de déplacer l'article."
  /// ```
  String get moveFailed => """Impossible de déplacer l'article.""";

  /// ```dart
  /// "Copier vers une liste"
  /// ```
  String get copyItem => """Copier vers une liste""";

  /// ```dart
  /// "Impossible de copier l'article."
  /// ```
  String get copyFailed => """Impossible de copier l'article.""";

  /// ```dart
  /// "Article copié"
  /// ```
  String get itemCopied => """Article copié""";

  /// ```dart
  /// "Article marqué comme fait"
  /// ```
  String get itemMarkedDone => """Article marqué comme fait""";

  /// ```dart
  /// "Article supprimé"
  /// ```
  String get itemRemoved => """Article supprimé""";

  /// ```dart
  /// "Annuler"
  /// ```
  String get undo => """Annuler""";

  /// ```dart
  /// "Sélectionner"
  /// ```
  String get selectItems => """Sélectionner""";
  BatchChecklistsMessagesFr get batch => BatchChecklistsMessagesFr(this);

  /// ```dart
  /// "Afficher la corbeille"
  /// ```
  String get viewTrash => """Afficher la corbeille""";

  /// ```dart
  /// "Quitter la corbeille"
  /// ```
  String get exitTrash => """Quitter la corbeille""";

  /// ```dart
  /// "Afficher qui a ajouté chaque article"
  /// ```
  String get showAddedBy => """Afficher qui a ajouté chaque article""";

  /// ```dart
  /// "Afficher la carte de progression sur cette liste"
  /// ```
  String get showProgressHero =>
      """Afficher la carte de progression sur cette liste""";

  /// ```dart
  /// "Ajouté par $name"
  /// ```
  String addedBy(String name) => """Ajouté par $name""";

  /// ```dart
  /// "Corbeille"
  /// ```
  String get trashTitle => """Corbeille""";

  /// ```dart
  /// "La corbeille est vide."
  /// ```
  String get noTrashedItems => """La corbeille est vide.""";

  /// ```dart
  /// "Vider la corbeille"
  /// ```
  String get emptyTrash => """Vider la corbeille""";

  /// ```dart
  /// "Vider la corbeille ?"
  /// ```
  String get emptyTrashConfirm => """Vider la corbeille ?""";

  /// ```dart
  /// "Tous les articles de la corbeille seront supprimés définitivement. Cette action est irréversible."
  /// ```
  String get emptyTrashConfirmBody =>
      """Tous les articles de la corbeille seront supprimés définitivement. Cette action est irréversible.""";

  /// ```dart
  /// "Impossible de vider la corbeille."
  /// ```
  String get emptyTrashFailed => """Impossible de vider la corbeille.""";

  /// ```dart
  /// "Restaurer"
  /// ```
  String get restoreItem => """Restaurer""";

  /// ```dart
  /// "Supprimer"
  /// ```
  String get permanentlyDeleteItem => """Supprimer""";

  /// ```dart
  /// "Supprimer définitivement cet article ?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """Supprimer définitivement cet article ?""";

  /// ```dart
  /// "Cette action est irréversible."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Cette action est irréversible.""";

  /// ```dart
  /// "Impossible de restaurer l'article."
  /// ```
  String get restoreFailed => """Impossible de restaurer l'article.""";

  /// ```dart
  /// "Impossible de supprimer l'article."
  /// ```
  String get permanentlyDeleteFailed =>
      """Impossible de supprimer l'article.""";

  /// ```dart
  /// "Article restauré"
  /// ```
  String get itemRestored => """Article restauré""";

  /// ```dart
  /// "Voir les archives"
  /// ```
  String get viewArchive => """Voir les archives""";

  /// ```dart
  /// "Quitter les archives"
  /// ```
  String get exitArchive => """Quitter les archives""";

  /// ```dart
  /// "Archives"
  /// ```
  String get archiveTitle => """Archives""";

  /// ```dart
  /// "Sans catégorie"
  /// ```
  String get noCategory => """Sans catégorie""";

  /// ```dart
  /// "Sans magasin"
  /// ```
  String get noStore => """Sans magasin""";

  /// ```dart
  /// "Les archives sont vides."
  /// ```
  String get noArchivedItems => """Les archives sont vides.""";

  /// ```dart
  /// "Archiver"
  /// ```
  String get archiveItem => """Archiver""";

  /// ```dart
  /// "Désarchiver"
  /// ```
  String get unarchiveItem => """Désarchiver""";

  /// ```dart
  /// "Échec de l'archivage de l'article."
  /// ```
  String get archiveFailed => """Échec de l'archivage de l'article.""";

  /// ```dart
  /// "Échec du désarchivage de l'article."
  /// ```
  String get unarchiveFailed => """Échec du désarchivage de l'article.""";

  /// ```dart
  /// "Article archivé"
  /// ```
  String get itemArchived => """Article archivé""";

  /// ```dart
  /// "Article désarchivé"
  /// ```
  String get itemUnarchived => """Article désarchivé""";

  /// ```dart
  /// "Échec du chargement des archives."
  /// ```
  String get failedToLoadArchive => """Échec du chargement des archives.""";

  /// ```dart
  /// "Listes supprimées"
  /// ```
  String get viewListsTrash => """Listes supprimées""";

  /// ```dart
  /// "Listes supprimées"
  /// ```
  String get listsTrashTitle => """Listes supprimées""";

  /// ```dart
  /// "Impossible de charger la corbeille."
  /// ```
  String get failedToLoadTrash => """Impossible de charger la corbeille.""";

  /// ```dart
  /// "Aucune liste supprimée."
  /// ```
  String get listTrashEmpty => """Aucune liste supprimée.""";

  /// ```dart
  /// "Épingler la liste"
  /// ```
  String get pinList => """Épingler la liste""";

  /// ```dart
  /// "Détacher la liste"
  /// ```
  String get unpinList => """Détacher la liste""";

  /// ```dart
  /// "Retirer la liste"
  /// ```
  String get removeList => """Retirer la liste""";

  /// ```dart
  /// "Modifier la liste"
  /// ```
  String get editList => """Modifier la liste""";

  /// ```dart
  /// "Modifier la liste"
  /// ```
  String get editListTitle => """Modifier la liste""";

  /// ```dart
  /// "Enregistrer les modifications"
  /// ```
  String get saveListButton => """Enregistrer les modifications""";

  /// ```dart
  /// "Impossible de mettre à jour la liste."
  /// ```
  String get updateListFailed => """Impossible de mettre à jour la liste.""";

  /// ```dart
  /// "Retirer la liste ?"
  /// ```
  String get removeListConfirm => """Retirer la liste ?""";

  /// ```dart
  /// "Retirer la liste "$name" ? Vous pouvez la restaurer depuis la corbeille."
  /// ```
  String removeListConfirmBody(String name) =>
      """Retirer la liste "$name" ? Vous pouvez la restaurer depuis la corbeille.""";

  /// ```dart
  /// "Impossible de retirer la liste."
  /// ```
  String get removeListFailed => """Impossible de retirer la liste.""";

  /// ```dart
  /// "Restaurer la liste"
  /// ```
  String get restoreList => """Restaurer la liste""";

  /// ```dart
  /// "Supprimer définitivement"
  /// ```
  String get permanentlyDeleteList => """Supprimer définitivement""";

  /// ```dart
  /// "Liste retirée"
  /// ```
  String get listRemoved => """Liste retirée""";

  /// ```dart
  /// "Nouvelle liste"
  /// ```
  String get createList => """Nouvelle liste""";

  /// ```dart
  /// "Nom de la liste"
  /// ```
  String get listName => """Nom de la liste""";

  /// ```dart
  /// "Description (facultatif)"
  /// ```
  String get listDescription => """Description (facultatif)""";

  /// ```dart
  /// "Icône"
  /// ```
  String get listIcon => """Icône""";

  /// ```dart
  /// "Impossible de créer la liste."
  /// ```
  String get createListFailed => """Impossible de créer la liste.""";
  ViewItemChecklistsMessagesFr get viewItem =>
      ViewItemChecklistsMessagesFr(this);
  ItemFormChecklistsMessagesFr get itemForm =>
      ItemFormChecklistsMessagesFr(this);
  SortChecklistsMessagesFr get sort => SortChecklistsMessagesFr(this);

  /// ```dart
  /// "${_plural(count, one: '1 article restant', many: '$count articles restants')}"
  /// ```
  String itemsLeft(int count) =>
      """${_plural(count, one: '1 article restant', many: '$count articles restants')}""";

  /// ```dart
  /// "Tout est fait 🎉"
  /// ```
  String get allDone => """Tout est fait 🎉""";

  /// ```dart
  /// "$done sur $total faits"
  /// ```
  String listProgress(int done, int total) => """$done sur $total faits""";

  /// ```dart
  /// "Masquer la carte de progression"
  /// ```
  String get hideProgressHero => """Masquer la carte de progression""";

  /// ```dart
  /// "Trier"
  /// ```
  String get sortTooltip => """Trier""";

  /// ```dart
  /// "Faits · $count"
  /// ```
  String doneCount(int count) => """Faits · $count""";

  /// ```dart
  /// "Tout décocher"
  /// ```
  String get uncheckAll => """Tout décocher""";

  /// ```dart
  /// "Décocher tous les articles ?"
  /// ```
  String get uncheckAllConfirm => """Décocher tous les articles ?""";

  /// ```dart
  /// "Chaque article coché de cette liste sera renvoyé vers la liste active."
  /// ```
  String get uncheckAllConfirmBody =>
      """Chaque article coché de cette liste sera renvoyé vers la liste active.""";

  /// ```dart
  /// "${_plural(count, one: '1 article décoché', many: '$count articles décochés')}"
  /// ```
  String uncheckedCount(int count) =>
      """${_plural(count, one: '1 article décoché', many: '$count articles décochés')}""";
  ResetOrderChecklistsMessagesFr get resetOrder =>
      ResetOrderChecklistsMessagesFr(this);

  /// ```dart
  /// "Ajouter à $name…"
  /// ```
  String addToList(String name) => """Ajouter à $name…""";

  /// ```dart
  /// "Ajoutez votre premier article…"
  /// ```
  String get addFirstItem => """Ajoutez votre premier article…""";

  /// ```dart
  /// "Rien dans cette liste pour le moment"
  /// ```
  String get noItemsTitle => """Rien dans cette liste pour le moment""";

  /// ```dart
  /// "Ajoutez votre premier article avec la barre en bas — définissez une catégorie, une quantité ou un horaire avec les chips."
  /// ```
  String get noItemsBody =>
      """Ajoutez votre premier article avec la barre en bas — définissez une catégorie, une quantité ou un horaire avec les chips.""";

  /// ```dart
  /// "Aucune liste pour le moment"
  /// ```
  String get noListsTitle => """Aucune liste pour le moment""";

  /// ```dart
  /// "Créez votre première liste pour commencer à suivre courses, courses à faire, tâches ou tout ce que votre foyer doit garder à l'œil."
  /// ```
  String get noListsBody =>
      """Créez votre première liste pour commencer à suivre courses, courses à faire, tâches ou tout ce que votre foyer doit garder à l'œil.""";

  /// ```dart
  /// "Créer votre première liste"
  /// ```
  String get createFirstList => """Créer votre première liste""";

  /// ```dart
  /// "Vos listes"
  /// ```
  String get yourChecklists => """Vos listes""";

  /// ```dart
  /// "${_plural(count, one: '1 liste', many: '$count listes')}"
  /// ```
  String listsCount(int count) =>
      """${_plural(count, one: '1 liste', many: '$count listes')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article', many: '$count articles')}"
  /// ```
  String itemsSummary(int count) =>
      """${_plural(count, one: '1 article', many: '$count articles')}""";

  /// ```dart
  /// "Tout est fait · 0 restant"
  /// ```
  String get allDoneSummary => """Tout est fait · 0 restant""";

  /// ```dart
  /// "Nouvelle liste"
  /// ```
  String get newChecklist => """Nouvelle liste""";

  /// ```dart
  /// "Créer la liste"
  /// ```
  String get createListButton => """Créer la liste""";

  /// ```dart
  /// "Voir"
  /// ```
  String get view => """Voir""";

  /// ```dart
  /// "Voir"
  /// ```
  String get swipeView => """Voir""";

  /// ```dart
  /// "Modifier"
  /// ```
  String get swipeEdit => """Modifier""";

  /// ```dart
  /// "Déplacer"
  /// ```
  String get swipeMove => """Déplacer""";

  /// ```dart
  /// "Copier"
  /// ```
  String get swipeCopy => """Copier""";

  /// ```dart
  /// "Retirer"
  /// ```
  String get swipeDelete => """Retirer""";

  /// ```dart
  /// "Archiver"
  /// ```
  String get swipeArchive => """Archiver""";

  /// ```dart
  /// "Plus d'actions"
  /// ```
  String get moreActions => """Plus d'actions""";

  /// ```dart
  /// "Vue liste"
  /// ```
  String get viewList => """Vue liste""";

  /// ```dart
  /// "Vue cartes"
  /// ```
  String get viewCards => """Vue cartes""";

  /// ```dart
  /// "Couleur"
  /// ```
  String get listColor => """Couleur""";
  ItemTypesChecklistsMessagesFr get itemTypes =>
      ItemTypesChecklistsMessagesFr(this);
  ComposeChecklistsMessagesFr get compose => ComposeChecklistsMessagesFr(this);
  PriceChecklistsMessagesFr get price => PriceChecklistsMessagesFr(this);
  ReuseChecklistsMessagesFr get reuse => ReuseChecklistsMessagesFr(this);

  /// ```dart
  /// "Toutes les listes"
  /// ```
  String get allLists => """Toutes les listes""";

  /// ```dart
  /// "Éléments de toutes les listes"
  /// ```
  String get allListsSubtitle => """Éléments de toutes les listes""";

  /// ```dart
  /// "Ajouter un élément…"
  /// ```
  String get addToAnyList => """Ajouter un élément…""";

  /// ```dart
  /// "Ajouter à quelle liste ?"
  /// ```
  String get pickListTitle => """Ajouter à quelle liste ?""";
  MarkdownChecklistsMessagesFr get markdown =>
      MarkdownChecklistsMessagesFr(this);
}

class BarcodeChecklistsMessagesFr extends BarcodeChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const BarcodeChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Scanner le code-barres"
  /// ```
  String get scan => """Scanner le code-barres""";

  /// ```dart
  /// "Scanner le code-barres"
  /// ```
  String get scanTitle => """Scanner le code-barres""";

  /// ```dart
  /// "Dirigez la caméra vers un code-barres de produit"
  /// ```
  String get scanInstructions =>
      """Dirigez la caméra vers un code-barres de produit""";

  /// ```dart
  /// "Saisir manuellement"
  /// ```
  String get enterManually => """Saisir manuellement""";

  /// ```dart
  /// "Saisir le code-barres"
  /// ```
  String get manualTitle => """Saisir le code-barres""";

  /// ```dart
  /// "Numéro de code-barres"
  /// ```
  String get manualHint => """Numéro de code-barres""";

  /// ```dart
  /// "Cela ne ressemble pas à un code-barres valide"
  /// ```
  String get invalidBarcode =>
      """Cela ne ressemble pas à un code-barres valide""";

  /// ```dart
  /// "Aucune info produit trouvée pour ce code-barres"
  /// ```
  String get notFound => """Aucune info produit trouvée pour ce code-barres""";

  /// ```dart
  /// "Produits fournis par ${linkStart}Open Food Facts${linkEnd}, une base de données communautaire externe que Pantry ne possède ni ne contrôle."
  /// ```
  String disclaimer(String linkStart, String linkEnd) =>
      """Produits fournis par ${linkStart}Open Food Facts${linkEnd}, une base de données communautaire externe que Pantry ne possède ni ne contrôle.""";
}

class FiltersChecklistsMessagesFr extends FiltersChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const FiltersChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Listes"
  /// ```
  String get lists => """Listes""";

  /// ```dart
  /// "Catégories"
  /// ```
  String get categories => """Catégories""";

  /// ```dart
  /// "Magasins"
  /// ```
  String get stores => """Magasins""";

  /// ```dart
  /// "Toutes les listes"
  /// ```
  String get allLists => """Toutes les listes""";

  /// ```dart
  /// "Toutes les catégories"
  /// ```
  String get allCategories => """Toutes les catégories""";

  /// ```dart
  /// "Tous les magasins"
  /// ```
  String get allStores => """Tous les magasins""";

  /// ```dart
  /// "Sans catégorie"
  /// ```
  String get noCategory => """Sans catégorie""";

  /// ```dart
  /// "Sans magasin"
  /// ```
  String get noStores => """Sans magasin""";

  /// ```dart
  /// "Prix"
  /// ```
  String get price => """Prix""";

  /// ```dart
  /// "N'importe quelle devise"
  /// ```
  String get anyCurrency => """N'importe quelle devise""";
}

class BatchChecklistsMessagesFr extends BatchChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const BatchChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "${_plural(count, one: '1 sélectionné', many: '$count sélectionnés')}"
  /// ```
  String selected(int count) =>
      """${_plural(count, one: '1 sélectionné', many: '$count sélectionnés')}""";

  /// ```dart
  /// "Déplacer les articles vers"
  /// ```
  String get moveTitle => """Déplacer les articles vers""";

  /// ```dart
  /// "Copier les articles vers"
  /// ```
  String get copyTitle => """Copier les articles vers""";

  /// ```dart
  /// "Définir la catégorie"
  /// ```
  String get categoryTitle => """Définir la catégorie""";

  /// ```dart
  /// "Définir les magasins"
  /// ```
  String get storesTitle => """Définir les magasins""";

  /// ```dart
  /// "Aucune catégorie"
  /// ```
  String get clearCategory => """Aucune catégorie""";

  /// ```dart
  /// "Déplacer"
  /// ```
  String get move => """Déplacer""";

  /// ```dart
  /// "Copier"
  /// ```
  String get copy => """Copier""";

  /// ```dart
  /// "Catégorie"
  /// ```
  String get category => """Catégorie""";

  /// ```dart
  /// "Magasins"
  /// ```
  String get stores => """Magasins""";

  /// ```dart
  /// "Supprimer"
  /// ```
  String get delete => """Supprimer""";

  /// ```dart
  /// "Archiver"
  /// ```
  String get archive => """Archiver""";

  /// ```dart
  /// "Désarchiver"
  /// ```
  String get unarchive => """Désarchiver""";

  /// ```dart
  /// "Supprimer les articles ?"
  /// ```
  String get deleteConfirmTitle => """Supprimer les articles ?""";

  /// ```dart
  /// "${_plural(count, one: 'Supprimer 1 article sélectionné ? Vous pouvez le restaurer depuis la corbeille.', many: 'Supprimer $count articles sélectionnés ? Vous pouvez les restaurer depuis la corbeille.')}"
  /// ```
  String deleteConfirmBody(int count) =>
      """${_plural(count, one: 'Supprimer 1 article sélectionné ? Vous pouvez le restaurer depuis la corbeille.', many: 'Supprimer $count articles sélectionnés ? Vous pouvez les restaurer depuis la corbeille.')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article déplacé', many: '$count articles déplacés')}"
  /// ```
  String moved(int count) =>
      """${_plural(count, one: '1 article déplacé', many: '$count articles déplacés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article copié', many: '$count articles copiés')}"
  /// ```
  String copied(int count) =>
      """${_plural(count, one: '1 article copié', many: '$count articles copiés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article supprimé', many: '$count articles supprimés')}"
  /// ```
  String deleted(int count) =>
      """${_plural(count, one: '1 article supprimé', many: '$count articles supprimés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article restauré', many: '$count articles restaurés')}"
  /// ```
  String restored(int count) =>
      """${_plural(count, one: '1 article restauré', many: '$count articles restaurés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article archivé', many: '$count articles archivés')}"
  /// ```
  String archived(int count) =>
      """${_plural(count, one: '1 article archivé', many: '$count articles archivés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article désarchivé', many: '$count articles désarchivés')}"
  /// ```
  String unarchived(int count) =>
      """${_plural(count, one: '1 article désarchivé', many: '$count articles désarchivés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article mis à jour', many: '$count articles mis à jour')}"
  /// ```
  String categorySet(int count) =>
      """${_plural(count, one: '1 article mis à jour', many: '$count articles mis à jour')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article mis à jour', many: '$count articles mis à jour')}"
  /// ```
  String storesSet(int count) =>
      """${_plural(count, one: '1 article mis à jour', many: '$count articles mis à jour')}""";

  /// ```dart
  /// "${_plural(count, one: '1 ignoré', many: '$count ignorés')}"
  /// ```
  String skipped(int count) =>
      """${_plural(count, one: '1 ignoré', many: '$count ignorés')}""";

  /// ```dart
  /// "Une erreur s'est produite. Veuillez réessayer."
  /// ```
  String get failed => """Une erreur s'est produite. Veuillez réessayer.""";
}

class ViewItemChecklistsMessagesFr extends ViewItemChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ViewItemChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Quantité :"
  /// ```
  String get quantity => """Quantité :""";

  /// ```dart
  /// "Catégorie :"
  /// ```
  String get category => """Catégorie :""";

  /// ```dart
  /// "Récurrence :"
  /// ```
  String get recurrence => """Récurrence :""";

  /// ```dart
  /// "Prochaine échéance :"
  /// ```
  String get nextDue => """Prochaine échéance :""";

  /// ```dart
  /// "Prochaine échéance (à partir de la complétion) :"
  /// ```
  String get nextDueFromCompletion =>
      """Prochaine échéance (à partir de la complétion) :""";

  /// ```dart
  /// "En retard"
  /// ```
  String get overdue => """En retard""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get quantityLabel => """Quantité""";

  /// ```dart
  /// "Type"
  /// ```
  String get typeLabel => """Type""";

  /// ```dart
  /// "Prix"
  /// ```
  String get priceLabel => """Prix""";

  /// ```dart
  /// "Description"
  /// ```
  String get descriptionLabel => """Description""";

  /// ```dart
  /// "Aucune description ajoutée."
  /// ```
  String get noDescription => """Aucune description ajoutée.""";

  /// ```dart
  /// "Ajouté par $name · $time"
  /// ```
  String addedByMeta(String name, String time) =>
      """Ajouté par $name · $time""";

  /// ```dart
  /// "Ajouté par vous · $time"
  /// ```
  String addedByYouMeta(String time) => """Ajouté par vous · $time""";

  /// ```dart
  /// "Ajouté $time"
  /// ```
  String addedMeta(String time) => """Ajouté $time""";

  /// ```dart
  /// "à l'instant"
  /// ```
  String get relJustNow => """à l'instant""";

  /// ```dart
  /// "aujourd'hui"
  /// ```
  String get relToday => """aujourd'hui""";

  /// ```dart
  /// "hier"
  /// ```
  String get relYesterday => """hier""";

  /// ```dart
  /// "il y a $n jours"
  /// ```
  String relDaysAgo(int n) => """il y a $n jours""";

  /// ```dart
  /// "${_plural(n, one: 'il y a 1 semaine', many: 'il y a $n semaines')}"
  /// ```
  String relWeeksAgo(int n) =>
      """${_plural(n, one: 'il y a 1 semaine', many: 'il y a $n semaines')}""";

  /// ```dart
  /// "${_plural(n, one: 'il y a 1 mois', many: 'il y a $n mois')}"
  /// ```
  String relMonthsAgo(int n) =>
      """${_plural(n, one: 'il y a 1 mois', many: 'il y a $n mois')}""";

  /// ```dart
  /// "${_plural(n, one: 'il y a 1 an', many: 'il y a $n ans')}"
  /// ```
  String relYearsAgo(int n) =>
      """${_plural(n, one: 'il y a 1 an', many: 'il y a $n ans')}""";
}

class ItemFormChecklistsMessagesFr extends ItemFormChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ItemFormChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Ajouter un article"
  /// ```
  String get addTitle => """Ajouter un article""";

  /// ```dart
  /// "Modifier l'article"
  /// ```
  String get editTitle => """Modifier l'article""";

  /// ```dart
  /// "Nom de l'article"
  /// ```
  String get name => """Nom de l'article""";

  /// ```dart
  /// "Description"
  /// ```
  String get description => """Description""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get quantity => """Quantité""";

  /// ```dart
  /// "Catégorie"
  /// ```
  String get category => """Catégorie""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get noCategory => """Aucune""";

  /// ```dart
  /// "Aucune catégorie disponible."
  /// ```
  String get noCategories => """Aucune catégorie disponible.""";

  /// ```dart
  /// "Nouvelle catégorie"
  /// ```
  String get createCategory => """Nouvelle catégorie""";

  /// ```dart
  /// "Nom"
  /// ```
  String get categoryName => """Nom""";

  /// ```dart
  /// "Icône"
  /// ```
  String get categoryIcon => """Icône""";

  /// ```dart
  /// "Couleur"
  /// ```
  String get categoryColor => """Couleur""";

  /// ```dart
  /// "Catégorie créée."
  /// ```
  String get categoryCreated => """Catégorie créée.""";

  /// ```dart
  /// "Impossible de créer la catégorie."
  /// ```
  String get categoryCreateFailed => """Impossible de créer la catégorie.""";

  /// ```dart
  /// "Magasins"
  /// ```
  String get stores => """Magasins""";

  /// ```dart
  /// "Aucun"
  /// ```
  String get noStores => """Aucun""";

  /// ```dart
  /// "Nouveau magasin"
  /// ```
  String get createStore => """Nouveau magasin""";

  /// ```dart
  /// "Modifier"
  /// ```
  String get storesChange => """Modifier""";

  /// ```dart
  /// "Choisir"
  /// ```
  String get storesPick => """Choisir""";

  /// ```dart
  /// "Répéter"
  /// ```
  String get repeat => """Répéter""";

  /// ```dart
  /// "Une fois"
  /// ```
  String get once => """Une fois""";

  /// ```dart
  /// "Supprimer cet article une fois qu'il est marqué comme fait."
  /// ```
  String get onceDescription =>
      """Supprimer cet article une fois qu'il est marqué comme fait.""";

  /// ```dart
  /// "Image"
  /// ```
  String get image => """Image""";

  /// ```dart
  /// "Ajouter une image"
  /// ```
  String get addImage => """Ajouter une image""";

  /// ```dart
  /// "Prendre une photo"
  /// ```
  String get takePhoto => """Prendre une photo""";

  /// ```dart
  /// "Choisir une image"
  /// ```
  String get chooseImage => """Choisir une image""";

  /// ```dart
  /// "Remplacer"
  /// ```
  String get replaceImage => """Remplacer""";

  /// ```dart
  /// "Supprimer"
  /// ```
  String get removeImage => """Supprimer""";

  /// ```dart
  /// "Impossible d'enregistrer l'article."
  /// ```
  String get saveFailed => """Impossible d'enregistrer l'article.""";

  /// ```dart
  /// "Impossible de supprimer l'article."
  /// ```
  String get deleteFailed => """Impossible de supprimer l'article.""";

  /// ```dart
  /// "Supprimer cet article ?"
  /// ```
  String get deleteConfirm => """Supprimer cet article ?""";

  /// ```dart
  /// "Enregistrer"
  /// ```
  String get save => """Enregistrer""";

  /// ```dart
  /// "Ajouter une description (facultatif)"
  /// ```
  String get descHint => """Ajouter une description (facultatif)""";

  /// ```dart
  /// "Changer"
  /// ```
  String get categoryChange => """Changer""";

  /// ```dart
  /// "Choisissez"
  /// ```
  String get categoryPick => """Choisissez""";

  /// ```dart
  /// "Article sans titre"
  /// ```
  String get untitledItem => """Article sans titre""";

  /// ```dart
  /// "Article récurrent"
  /// ```
  String get typeStaple => """Article récurrent""";

  /// ```dart
  /// "Article unique"
  /// ```
  String get typeOnce => """Article unique""";

  /// ```dart
  /// "Récurrent"
  /// ```
  String get typeRecurring => """Récurrent""";
}

class SortChecklistsMessagesFr extends SortChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const SortChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Plus récents"
  /// ```
  String get newestFirst => """Plus récents""";

  /// ```dart
  /// "Plus anciens"
  /// ```
  String get oldestFirst => """Plus anciens""";

  /// ```dart
  /// "Nom A–Z"
  /// ```
  String get nameAZ => """Nom A–Z""";

  /// ```dart
  /// "Nom Z–A"
  /// ```
  String get nameZA => """Nom Z–A""";

  /// ```dart
  /// "Par catégorie"
  /// ```
  String get category => """Par catégorie""";

  /// ```dart
  /// "Par magasin"
  /// ```
  String get store => """Par magasin""";

  /// ```dart
  /// "Personnalisé"
  /// ```
  String get custom => """Personnalisé""";
}

class ResetOrderChecklistsMessagesFr extends ResetOrderChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ResetOrderChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Réinitialiser l'ordre personnalisé…"
  /// ```
  String get menuLabel => """Réinitialiser l'ordre personnalisé…""";

  /// ```dart
  /// "Réinitialiser l'ordre personnalisé sur…"
  /// ```
  String get pickTitle => """Réinitialiser l'ordre personnalisé sur…""";

  /// ```dart
  /// "Réinitialiser l'ordre personnalisé ?"
  /// ```
  String get confirmTitle => """Réinitialiser l'ordre personnalisé ?""";

  /// ```dart
  /// "Cela remplace l'ordre personnalisé actuel de cette liste. Vous pourrez réorganiser les articles ensuite."
  /// ```
  String get confirmBody =>
      """Cela remplace l'ordre personnalisé actuel de cette liste. Vous pourrez réorganiser les articles ensuite.""";

  /// ```dart
  /// "Réinitialiser l'ordre"
  /// ```
  String get action => """Réinitialiser l'ordre""";

  /// ```dart
  /// "Ordre personnalisé réinitialisé"
  /// ```
  String get success => """Ordre personnalisé réinitialisé""";

  /// ```dart
  /// "Date d'ajout"
  /// ```
  String get basisDateAdded => """Date d'ajout""";

  /// ```dart
  /// "Nom A–Z"
  /// ```
  String get basisNameAsc => """Nom A–Z""";

  /// ```dart
  /// "Nom Z–A"
  /// ```
  String get basisNameDesc => """Nom Z–A""";
}

class ItemTypesChecklistsMessagesFr extends ItemTypesChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ItemTypesChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Type d'article"
  /// ```
  String get label => """Type d'article""";

  /// ```dart
  /// "Habituel"
  /// ```
  String get staple => """Habituel""";

  /// ```dart
  /// "Reste sur la liste après que vous l'avez complété"
  /// ```
  String get stapleBody =>
      """Reste sur la liste après que vous l'avez complété""";

  /// ```dart
  /// "Unique"
  /// ```
  String get onceTime => """Unique""";

  /// ```dart
  /// "Supprimé lorsque vous le complétez"
  /// ```
  String get onceTimeBody => """Supprimé lorsque vous le complétez""";

  /// ```dart
  /// "Récurrent"
  /// ```
  String get recurring => """Récurrent""";

  /// ```dart
  /// "Revient selon un horaire"
  /// ```
  String get recurringBody => """Revient selon un horaire""";

  /// ```dart
  /// "Hebdomadaire"
  /// ```
  String get weekly => """Hebdomadaire""";

  /// ```dart
  /// "Toutes les $n sem"
  /// ```
  String everyNWeeks(int n) => """Toutes les $n sem""";
}

class ComposeChecklistsMessagesFr extends ComposeChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ComposeChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Catégorie"
  /// ```
  String get chipCategory => """Catégorie""";

  /// ```dart
  /// "Magasins"
  /// ```
  String get chipStore => """Magasins""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get chipQuantity => """Quantité""";

  /// ```dart
  /// "Type"
  /// ```
  String get chipType => """Type""";

  /// ```dart
  /// "Image"
  /// ```
  String get chipImage => """Image""";

  /// ```dart
  /// "Description"
  /// ```
  String get chipDescription => """Description""";

  /// ```dart
  /// "Notes, instructions, liens…"
  /// ```
  String get descHint => """Notes, instructions, liens…""";

  /// ```dart
  /// "ex. 2 L, 500 g"
  /// ```
  String get qtyHint => """ex. 2 L, 500 g""";

  /// ```dart
  /// "＋ / − changent le nombre et gardent l'unité."
  /// ```
  String get qtyStepperHelp =>
      """＋ / − changent le nombre et gardent l'unité.""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get none => """Aucune""";

  /// ```dart
  /// "Toutes les"
  /// ```
  String get every => """Toutes les""";

  /// ```dart
  /// "semaine"
  /// ```
  String get week => """semaine""";

  /// ```dart
  /// "semaines"
  /// ```
  String get weeks => """semaines""";

  /// ```dart
  /// "Liste"
  /// ```
  String get chipTargetList => """Liste""";

  /// ```dart
  /// "Choisir une liste"
  /// ```
  String get pickTargetList => """Choisir une liste""";

  /// ```dart
  /// "Plusieurs"
  /// ```
  String get multiple => """Plusieurs""";

  /// ```dart
  /// "Séparer les éléments par des retours à la ligne"
  /// ```
  String get multipleHint =>
      """Séparer les éléments par des retours à la ligne""";
}

class PriceChecklistsMessagesFr extends PriceChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const PriceChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Prix"
  /// ```
  String get label => """Prix""";

  /// ```dart
  /// "Fixe"
  /// ```
  String get set => """Fixe""";

  /// ```dart
  /// "Plage"
  /// ```
  String get range => """Plage""";

  /// ```dart
  /// "Montant"
  /// ```
  String get amount => """Montant""";

  /// ```dart
  /// "Min"
  /// ```
  String get min => """Min""";

  /// ```dart
  /// "Max"
  /// ```
  String get max => """Max""";

  /// ```dart
  /// "Devise"
  /// ```
  String get currency => """Devise""";

  /// ```dart
  /// "Effacer le prix"
  /// ```
  String get clear => """Effacer le prix""";
}

class ReuseChecklistsMessagesFr extends ReuseChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ReuseChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "L'article existe déjà"
  /// ```
  String get dialogTitle => """L'article existe déjà""";

  /// ```dart
  /// "Un article nommé "$name" existe déjà dans cette liste. Le réutiliser au lieu d'en ajouter un nouveau ?"
  /// ```
  String dialogBody(String name) =>
      """Un article nommé "$name" existe déjà dans cette liste. Le réutiliser au lieu d'en ajouter un nouveau ?""";

  /// ```dart
  /// "Réutiliser l'existant"
  /// ```
  String get reuseExisting => """Réutiliser l'existant""";

  /// ```dart
  /// "Ajouter quand même"
  /// ```
  String get addAnyway => """Ajouter quand même""";

  /// ```dart
  /// "Article existant "$name" réutilisé"
  /// ```
  String reusedSnack(String name) => """Article existant "$name" réutilisé""";

  /// ```dart
  /// "Déjà dans cette liste"
  /// ```
  String get suggestionsHeader => """Déjà dans cette liste""";
}

class MarkdownChecklistsMessagesFr extends MarkdownChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const MarkdownChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Exporté le $date"
  /// ```
  String exported(String date) => """Exporté le $date""";

  /// ```dart
  /// "Sans catégorie"
  /// ```
  String get uncategorized => """Sans catégorie""";

  /// ```dart
  /// "Exporter en Markdown"
  /// ```
  String get exportTitle => """Exporter en Markdown""";

  /// ```dart
  /// "Importer depuis Markdown"
  /// ```
  String get importTitle => """Importer depuis Markdown""";

  /// ```dart
  /// "Inclure les éléments terminés"
  /// ```
  String get includeCompleted => """Inclure les éléments terminés""";

  /// ```dart
  /// "Modifiez le texte ci-dessous pour ajuster la liste exportée"
  /// ```
  String get editHint =>
      """Modifiez le texte ci-dessous pour ajuster la liste exportée""";

  /// ```dart
  /// "Copier"
  /// ```
  String get copy => """Copier""";

  /// ```dart
  /// "Télécharger le .md"
  /// ```
  String get download => """Télécharger le .md""";

  /// ```dart
  /// "Copié dans le presse-papiers"
  /// ```
  String get copied => """Copié dans le presse-papiers""";

  /// ```dart
  /// "Impossible de copier dans le presse-papiers"
  /// ```
  String get copyFailed => """Impossible de copier dans le presse-papiers""";

  /// ```dart
  /// "Fermer"
  /// ```
  String get close => """Fermer""";

  /// ```dart
  /// "Impossible d'exporter le fichier"
  /// ```
  String get shareFailed => """Impossible d'exporter le fichier""";

  /// ```dart
  /// "Téléverser un fichier .md"
  /// ```
  String get uploadFile => """Téléverser un fichier .md""";

  /// ```dart
  /// "Coller du Markdown"
  /// ```
  String get pasteLabel => """Coller du Markdown""";

  /// ```dart
  /// "Collez une liste Markdown ici…"
  /// ```
  String get pastePlaceholder => """Collez une liste Markdown ici…""";

  /// ```dart
  /// "Aucun élément de liste trouvé dans le texte."
  /// ```
  String get noneFound => """Aucun élément de liste trouvé dans le texte.""";

  /// ```dart
  /// "Tout sélectionner"
  /// ```
  String get selectAll => """Tout sélectionner""";

  /// ```dart
  /// "Tout désélectionner"
  /// ```
  String get deselectAll => """Tout désélectionner""";

  /// ```dart
  /// "Réutiliser les éléments existants au lieu d'ajouter des doublons"
  /// ```
  String get reuseExisting =>
      """Réutiliser les éléments existants au lieu d'ajouter des doublons""";

  /// ```dart
  /// "Valeurs appliquées à chaque élément importé"
  /// ```
  String get defaultFields => """Valeurs appliquées à chaque élément importé""";

  /// ```dart
  /// "${_plural(count, one: '1 élément trouvé', many: '$count éléments trouvés')}"
  /// ```
  String itemsFound(int count) =>
      """${_plural(count, one: '1 élément trouvé', many: '$count éléments trouvés')}""";

  /// ```dart
  /// "${_plural(count, one: 'Ajouter 1 élément', many: 'Ajouter $count éléments')}"
  /// ```
  String addItems(int count) =>
      """${_plural(count, one: 'Ajouter 1 élément', many: 'Ajouter $count éléments')}""";

  /// ```dart
  /// "${_plural(count, one: '1 élément importé', many: '$count éléments importés')}"
  /// ```
  String imported(int count) =>
      """${_plural(count, one: '1 élément importé', many: '$count éléments importés')}""";
}

class NotesWallMessagesFr extends NotesWallMessages {
  final MessagesFr _parent;
  const NotesWallMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Aucune note pour le moment."
  /// ```
  String get noNotes => """Aucune note pour le moment.""";

  /// ```dart
  /// "Impossible de charger les notes."
  /// ```
  String get failedToLoad => """Impossible de charger les notes.""";

  /// ```dart
  /// "Impossible d'enregistrer la note."
  /// ```
  String get saveFailed => """Impossible d'enregistrer la note.""";

  /// ```dart
  /// "Impossible de supprimer la note."
  /// ```
  String get deleteFailed => """Impossible de supprimer la note.""";

  /// ```dart
  /// "Supprimer cette note ?"
  /// ```
  String get deleteConfirm => """Supprimer cette note ?""";

  /// ```dart
  /// "Supprimer ${_plural(count, one: 'cette note', many: '$count notes')} ?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """Supprimer ${_plural(count, one: 'cette note', many: '$count notes')} ?""";

  /// ```dart
  /// "${_plural(count, one: 'Note supprimée', many: '$count notes supprimées')}"
  /// ```
  String noteRemoved(int count) =>
      """${_plural(count, one: 'Note supprimée', many: '$count notes supprimées')}""";

  /// ```dart
  /// "Voir la corbeille"
  /// ```
  String get viewTrash => """Voir la corbeille""";

  /// ```dart
  /// "Quitter la corbeille"
  /// ```
  String get exitTrash => """Quitter la corbeille""";

  /// ```dart
  /// "Corbeille"
  /// ```
  String get trashTitle => """Corbeille""";

  /// ```dart
  /// "La corbeille est vide."
  /// ```
  String get trashEmpty => """La corbeille est vide.""";

  /// ```dart
  /// "Vider la corbeille"
  /// ```
  String get emptyTrash => """Vider la corbeille""";

  /// ```dart
  /// "Vider la corbeille ?"
  /// ```
  String get emptyTrashConfirm => """Vider la corbeille ?""";

  /// ```dart
  /// "Toutes les notes dans la corbeille seront supprimées définitivement. Cette action est irréversible."
  /// ```
  String get emptyTrashConfirmBody =>
      """Toutes les notes dans la corbeille seront supprimées définitivement. Cette action est irréversible.""";

  /// ```dart
  /// "Impossible de vider la corbeille."
  /// ```
  String get emptyTrashFailed => """Impossible de vider la corbeille.""";

  /// ```dart
  /// "Impossible de charger la corbeille."
  /// ```
  String get failedToLoadTrash => """Impossible de charger la corbeille.""";

  /// ```dart
  /// "Restaurer"
  /// ```
  String get restore => """Restaurer""";

  /// ```dart
  /// "Impossible de restaurer la note."
  /// ```
  String get restoreFailed => """Impossible de restaurer la note.""";

  /// ```dart
  /// "Supprimer définitivement"
  /// ```
  String get permanentlyDelete => """Supprimer définitivement""";

  /// ```dart
  /// "Supprimer cette note définitivement ?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """Supprimer cette note définitivement ?""";

  /// ```dart
  /// "Cette action est irréversible."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Cette action est irréversible.""";

  /// ```dart
  /// "Nouvelle note"
  /// ```
  String get newNote => """Nouvelle note""";

  /// ```dart
  /// "Modifier la note"
  /// ```
  String get editNote => """Modifier la note""";

  /// ```dart
  /// "Modifications non enregistrées"
  /// ```
  String get unsavedChanges => """Modifications non enregistrées""";

  /// ```dart
  /// "Vous avez des modifications non enregistrées. Voulez-vous les enregistrer ?"
  /// ```
  String get unsavedChangesBody =>
      """Vous avez des modifications non enregistrées. Voulez-vous les enregistrer ?""";

  /// ```dart
  /// "Abandonner"
  /// ```
  String get discard => """Abandonner""";

  /// ```dart
  /// "Continuer la modification"
  /// ```
  String get keepEditing => """Continuer la modification""";

  /// ```dart
  /// "Épingler la note"
  /// ```
  String get pinNote => """Épingler la note""";

  /// ```dart
  /// "Désépingler la note"
  /// ```
  String get unpinNote => """Désépingler la note""";

  /// ```dart
  /// "Titre"
  /// ```
  String get title => """Titre""";

  /// ```dart
  /// "Contenu"
  /// ```
  String get content => """Contenu""";

  /// ```dart
  /// "Couleur"
  /// ```
  String get color => """Couleur""";
  SortNotesWallMessagesFr get sort => SortNotesWallMessagesFr(this);
}

class SortNotesWallMessagesFr extends SortNotesWallMessages {
  final NotesWallMessagesFr _parent;
  const SortNotesWallMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Plus récents"
  /// ```
  String get newestFirst => """Plus récents""";

  /// ```dart
  /// "Plus anciens"
  /// ```
  String get oldestFirst => """Plus anciens""";

  /// ```dart
  /// "Titre A–Z"
  /// ```
  String get titleAZ => """Titre A–Z""";

  /// ```dart
  /// "Titre Z–A"
  /// ```
  String get titleZA => """Titre Z–A""";

  /// ```dart
  /// "Personnalisé"
  /// ```
  String get custom => """Personnalisé""";
}

class PhotoBoardMessagesFr extends PhotoBoardMessages {
  final MessagesFr _parent;
  const PhotoBoardMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Aucune photo pour le moment."
  /// ```
  String get noPhotos => """Aucune photo pour le moment.""";

  /// ```dart
  /// "Impossible de charger les photos."
  /// ```
  String get failedToLoad => """Impossible de charger les photos.""";

  /// ```dart
  /// "Impossible de télécharger la photo."
  /// ```
  String get uploadFailed => """Impossible de télécharger la photo.""";

  /// ```dart
  /// "Impossible de supprimer la photo."
  /// ```
  String get deleteFailed => """Impossible de supprimer la photo.""";

  /// ```dart
  /// "Supprimer cette photo ?"
  /// ```
  String get deleteConfirm => """Supprimer cette photo ?""";

  /// ```dart
  /// "Supprimer ${_plural(count, one: 'cette photo', many: '$count photos')} ?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """Supprimer ${_plural(count, one: 'cette photo', many: '$count photos')} ?""";

  /// ```dart
  /// "${_plural(count, one: 'Photo supprimée', many: '$count photos supprimées')}"
  /// ```
  String photoRemoved(int count) =>
      """${_plural(count, one: 'Photo supprimée', many: '$count photos supprimées')}""";

  /// ```dart
  /// "Voir la corbeille"
  /// ```
  String get viewTrash => """Voir la corbeille""";

  /// ```dart
  /// "Quitter la corbeille"
  /// ```
  String get exitTrash => """Quitter la corbeille""";

  /// ```dart
  /// "Corbeille"
  /// ```
  String get trashTitle => """Corbeille""";

  /// ```dart
  /// "La corbeille est vide."
  /// ```
  String get trashEmpty => """La corbeille est vide.""";

  /// ```dart
  /// "Vider la corbeille"
  /// ```
  String get emptyTrash => """Vider la corbeille""";

  /// ```dart
  /// "Vider la corbeille ?"
  /// ```
  String get emptyTrashConfirm => """Vider la corbeille ?""";

  /// ```dart
  /// "Toutes les photos dans la corbeille seront supprimées définitivement. Cette action est irréversible."
  /// ```
  String get emptyTrashConfirmBody =>
      """Toutes les photos dans la corbeille seront supprimées définitivement. Cette action est irréversible.""";

  /// ```dart
  /// "Impossible de vider la corbeille."
  /// ```
  String get emptyTrashFailed => """Impossible de vider la corbeille.""";

  /// ```dart
  /// "Impossible de charger la corbeille."
  /// ```
  String get failedToLoadTrash => """Impossible de charger la corbeille.""";

  /// ```dart
  /// "Restaurer"
  /// ```
  String get restore => """Restaurer""";

  /// ```dart
  /// "Impossible de restaurer la photo."
  /// ```
  String get restoreFailed => """Impossible de restaurer la photo.""";

  /// ```dart
  /// "Supprimer définitivement"
  /// ```
  String get permanentlyDelete => """Supprimer définitivement""";

  /// ```dart
  /// "Supprimer cette photo définitivement ?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """Supprimer cette photo définitivement ?""";

  /// ```dart
  /// "Cette action est irréversible."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Cette action est irréversible.""";

  /// ```dart
  /// "Supprimer le dossier"
  /// ```
  String get deleteFolder => """Supprimer le dossier""";

  /// ```dart
  /// "Supprimer ce dossier ?"
  /// ```
  String get deleteFolderConfirm => """Supprimer ce dossier ?""";

  /// ```dart
  /// "Déplacer les photos à la racine"
  /// ```
  String get deleteFolderKeepPhotos => """Déplacer les photos à la racine""";

  /// ```dart
  /// "Supprimer le dossier et les photos"
  /// ```
  String get deleteFolderDeleteAll => """Supprimer le dossier et les photos""";

  /// ```dart
  /// "Nouveau dossier"
  /// ```
  String get newFolder => """Nouveau dossier""";

  /// ```dart
  /// "Nom du dossier"
  /// ```
  String get folderName => """Nom du dossier""";

  /// ```dart
  /// "Renommer le dossier"
  /// ```
  String get renameFolder => """Renommer le dossier""";

  /// ```dart
  /// "Légende"
  /// ```
  String get caption => """Légende""";

  /// ```dart
  /// "$count"
  /// ```
  String photoCount(int count) => """$count""";
  AddMenuPhotoBoardMessagesFr get addMenu => AddMenuPhotoBoardMessagesFr(this);
  SortPhotoBoardMessagesFr get sort => SortPhotoBoardMessagesFr(this);
}

class AddMenuPhotoBoardMessagesFr extends AddMenuPhotoBoardMessages {
  final PhotoBoardMessagesFr _parent;
  const AddMenuPhotoBoardMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Téléverser des photos"
  /// ```
  String get upload => """Téléverser des photos""";

  /// ```dart
  /// "Prendre une photo"
  /// ```
  String get camera => """Prendre une photo""";

  /// ```dart
  /// "Nouveau dossier"
  /// ```
  String get newFolder => """Nouveau dossier""";
}

class SortPhotoBoardMessagesFr extends SortPhotoBoardMessages {
  final PhotoBoardMessagesFr _parent;
  const SortPhotoBoardMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Dossiers en premier"
  /// ```
  String get foldersFirst => """Dossiers en premier""";

  /// ```dart
  /// "Plus récents"
  /// ```
  String get newestFirst => """Plus récents""";

  /// ```dart
  /// "Plus anciens"
  /// ```
  String get oldestFirst => """Plus anciens""";

  /// ```dart
  /// "Légende A–Z"
  /// ```
  String get captionAZ => """Légende A–Z""";

  /// ```dart
  /// "Légende Z–A"
  /// ```
  String get captionZA => """Légende Z–A""";

  /// ```dart
  /// "Personnalisé"
  /// ```
  String get custom => """Personnalisé""";
}

class ShoppingMessagesFr extends ShoppingMessages {
  final MessagesFr _parent;
  const ShoppingMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Commencer les courses"
  /// ```
  String get startShopping => """Commencer les courses""";

  /// ```dart
  /// "Reprendre les courses"
  /// ```
  String get resumeShopping => """Reprendre les courses""";

  /// ```dart
  /// "Historique des courses"
  /// ```
  String get shoppingHistory => """Historique des courses""";

  /// ```dart
  /// "Reprendre"
  /// ```
  String get resume => """Reprendre""";

  /// ```dart
  /// "Courses chez ${store}"
  /// ```
  String bannerShoppingAt(String store) => """Courses chez ${store}""";

  /// ```dart
  /// "Magasin $index/$total"
  /// ```
  String bannerStoreProgress(int index, int total) =>
      """Magasin $index/$total""";

  /// ```dart
  /// "Courses en cours"
  /// ```
  String get bannerShoppingNow => """Courses en cours""";

  /// ```dart
  /// "Commencer les courses"
  /// ```
  String get startTitle => """Commencer les courses""";

  /// ```dart
  /// "Listes à faire"
  /// ```
  String get listsToShop => """Listes à faire""";

  /// ```dart
  /// "Tout sélectionner"
  /// ```
  String get selectAll => """Tout sélectionner""";

  /// ```dart
  /// "Ne rien sélectionner"
  /// ```
  String get selectNone => """Ne rien sélectionner""";

  /// ```dart
  /// "Aucune liste à faire pour l'instant."
  /// ```
  String get noListsToShop => """Aucune liste à faire pour l'instant.""";

  /// ```dart
  /// "Magasins"
  /// ```
  String get storesTitle => """Magasins""";

  /// ```dart
  /// "Activez ou désactivez les magasins que vous visiterez, et glissez pour définir l'ordre."
  /// ```
  String get storesHint =>
      """Activez ou désactivez les magasins que vous visiterez, et glissez pour définir l'ordre.""";

  /// ```dart
  /// "Aucune des listes sélectionnées n'a d'articles assignés à un magasin."
  /// ```
  String get noStoresWithItems =>
      """Aucune des listes sélectionnées n'a d'articles assignés à un magasin.""";

  /// ```dart
  /// "Inclure les articles sans magasin"
  /// ```
  String get includeUnassigned => """Inclure les articles sans magasin""";

  /// ```dart
  /// "Commencer"
  /// ```
  String get start => """Commencer""";

  /// ```dart
  /// "Impossible de commencer les courses."
  /// ```
  String get startFailed => """Impossible de commencer les courses.""";

  /// ```dart
  /// "Vous avez déjà des courses en cours."
  /// ```
  String get tripInProgress => """Vous avez déjà des courses en cours.""";

  /// ```dart
  /// "Vous avez des courses en cours dans ${house}."
  /// ```
  String tripInProgressElsewhere(String house) =>
      """Vous avez des courses en cours dans ${house}.""";

  /// ```dart
  /// "Terminer les courses précédentes"
  /// ```
  String get endPreviousTrip => """Terminer les courses précédentes""";

  /// ```dart
  /// "Impossible de terminer les courses précédentes."
  /// ```
  String get endPreviousFailed =>
      """Impossible de terminer les courses précédentes.""";

  /// ```dart
  /// "$count dans le panier"
  /// ```
  String inCart(int count) => """$count dans le panier""";

  /// ```dart
  /// "Masquer les courses aux colocataires"
  /// ```
  String get makePrivate => """Masquer les courses aux colocataires""";

  /// ```dart
  /// "Montrer les courses aux colocataires"
  /// ```
  String get makePublic => """Montrer les courses aux colocataires""";

  /// ```dart
  /// "Privé"
  /// ```
  String get privateBadge => """Privé""";

  /// ```dart
  /// "Magasin suivant"
  /// ```
  String get nextStore => """Magasin suivant""";

  /// ```dart
  /// "Terminer"
  /// ```
  String get finish => """Terminer""";

  /// ```dart
  /// "Terminer les courses"
  /// ```
  String get finishTrip => """Terminer les courses""";

  /// ```dart
  /// "Tout est coché ici"
  /// ```
  String get allCheckedHere => """Tout est coché ici""";

  /// ```dart
  /// "Passez au magasin suivant."
  /// ```
  String get moveOnToNext => """Passez au magasin suivant.""";

  /// ```dart
  /// "Tout est fait"
  /// ```
  String get allDone => """Tout est fait""";

  /// ```dart
  /// "Tout est dans le panier."
  /// ```
  String get everythingInCart => """Tout est dans le panier.""";

  /// ```dart
  /// "Fait ($count)"
  /// ```
  String doneToday(int count) => """Fait ($count)""";

  /// ```dart
  /// "Rien à acheter ici."
  /// ```
  String get nothingToBuyHere => """Rien à acheter ici.""";

  /// ```dart
  /// "Impossible de mettre à jour l'article."
  /// ```
  String get checkFailed => """Impossible de mettre à jour l'article.""";

  /// ```dart
  /// "Impossible de charger les articles."
  /// ```
  String get loadItemsFailed => """Impossible de charger les articles.""";

  /// ```dart
  /// "Retirer de la sortie"
  /// ```
  String get removeFromTrip => """Retirer de la sortie""";

  /// ```dart
  /// "Retiré de cette sortie"
  /// ```
  String get removedFromTrip => """Retiré de cette sortie""";

  /// ```dart
  /// "Annuler"
  /// ```
  String get undo => """Annuler""";

  /// ```dart
  /// "Impossible d'annuler."
  /// ```
  String get undoRemoveFailed => """Impossible d'annuler.""";

  /// ```dart
  /// "Récapitulatif"
  /// ```
  String get reviewTitle => """Récapitulatif""";

  /// ```dart
  /// "Magasin suivant"
  /// ```
  String get advanceTitle => """Magasin suivant""";

  /// ```dart
  /// "Payé réel"
  /// ```
  String get actualPaid => """Payé réel""";

  /// ```dart
  /// "Total général"
  /// ```
  String get grandTotal => """Total général""";

  /// ```dart
  /// "${_plural(count, one: '1 article sans prix', many: '$count articles sans prix')}"
  /// ```
  String itemsWithoutPrice(int count) =>
      """${_plural(count, one: '1 article sans prix', many: '$count articles sans prix')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article non coché', many: '$count articles non cochés')}"
  /// ```
  String itemsStillUnchecked(int count) =>
      """${_plural(count, one: '1 article non coché', many: '$count articles non cochés')}""";

  /// ```dart
  /// "N'importe quel magasin"
  /// ```
  String get anyStore => """N'importe quel magasin""";

  /// ```dart
  /// "Impossible d'enregistrer le total."
  /// ```
  String get saveTotalFailed => """Impossible d'enregistrer le total.""";

  /// ```dart
  /// "Rappels"
  /// ```
  String get remindersTitle => """Rappels""";

  /// ```dart
  /// "Gérer les rappels"
  /// ```
  String get manageReminders => """Gérer les rappels""";

  /// ```dart
  /// "Au début"
  /// ```
  String get reminderGroupStart => """Au début""";

  /// ```dart
  /// "Entre les magasins"
  /// ```
  String get reminderGroupAdvance => """Entre les magasins""";

  /// ```dart
  /// "À la fin"
  /// ```
  String get reminderGroupEnd => """À la fin""";

  /// ```dart
  /// "Aucun rappel ici pour l'instant."
  /// ```
  String get noRemindersHere => """Aucun rappel ici pour l'instant.""";

  /// ```dart
  /// "Aucun rappel pour cette étape pour l'instant."
  /// ```
  String get noRemindersStep =>
      """Aucun rappel pour cette étape pour l'instant.""";

  /// ```dart
  /// "Ajouter des rappels"
  /// ```
  String get addReminders => """Ajouter des rappels""";

  /// ```dart
  /// "Ajouter un rappel"
  /// ```
  String get addReminderHint => """Ajouter un rappel""";

  /// ```dart
  /// "Quand l'afficher"
  /// ```
  String get reminderWhen => """Quand l'afficher""";

  /// ```dart
  /// "Au début"
  /// ```
  String get whenOnStart => """Au début""";

  /// ```dart
  /// "Entre les magasins"
  /// ```
  String get whenOnStoreAdvance => """Entre les magasins""";

  /// ```dart
  /// "À la fin"
  /// ```
  String get whenOnClose => """À la fin""";

  /// ```dart
  /// "Ajouter"
  /// ```
  String get add => """Ajouter""";

  /// ```dart
  /// "Impossible d'enregistrer le rappel."
  /// ```
  String get reminderSaveFailed => """Impossible d'enregistrer le rappel.""";

  /// ```dart
  /// "Impossible de supprimer le rappel."
  /// ```
  String get reminderDeleteFailed => """Impossible de supprimer le rappel.""";

  /// ```dart
  /// "Historique des courses"
  /// ```
  String get historyTitle => """Historique des courses""";

  /// ```dart
  /// "Les miennes"
  /// ```
  String get scopeMine => """Les miennes""";

  /// ```dart
  /// "Maison"
  /// ```
  String get scopeHouse => """Maison""";

  /// ```dart
  /// "Aucun magasin"
  /// ```
  String get noStorePath => """Aucun magasin""";

  /// ```dart
  /// "${_plural(count, one: '1 article', many: '$count articles')}"
  /// ```
  String itemsCount(int count) =>
      """${_plural(count, one: '1 article', many: '$count articles')}""";

  /// ```dart
  /// "Charger plus"
  /// ```
  String get loadMore => """Charger plus""";

  /// ```dart
  /// "Aucune course pour l'instant."
  /// ```
  String get noTripsYet => """Aucune course pour l'instant.""";

  /// ```dart
  /// "Aucune course dans cette maison pour l'instant."
  /// ```
  String get noHouseTripsYet =>
      """Aucune course dans cette maison pour l'instant.""";

  /// ```dart
  /// "Impossible de charger l'historique."
  /// ```
  String get loadHistoryFailed => """Impossible de charger l'historique.""";

  /// ```dart
  /// "Une erreur s'est produite. Veuillez réessayer."
  /// ```
  String get loadFailed => """Une erreur s'est produite. Veuillez réessayer.""";

  /// ```dart
  /// "Sans catégorie"
  /// ```
  String get uncategorized => """Sans catégorie""";
}

class ShareMessagesFr extends ShareMessages {
  final MessagesFr _parent;
  const ShareMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Partager vers Pantry"
  /// ```
  String get title => """Partager vers Pantry""";

  /// ```dart
  /// "Choisir une maison"
  /// ```
  String get chooseHouse => """Choisir une maison""";

  /// ```dart
  /// "Téléverser vers"
  /// ```
  String get choosePhotoDestination => """Téléverser vers""";

  /// ```dart
  /// "Tableau photos"
  /// ```
  String get photoBoardRoot => """Tableau photos""";

  /// ```dart
  /// "Nouveau dossier"
  /// ```
  String get newFolder => """Nouveau dossier""";

  /// ```dart
  /// "Nom du dossier"
  /// ```
  String get newFolderName => """Nom du dossier""";

  /// ```dart
  /// "Impossible de créer le dossier."
  /// ```
  String get failedToCreateFolder => """Impossible de créer le dossier.""";

  /// ```dart
  /// "Impossible d'ouvrir le contenu partagé."
  /// ```
  String get failedToOpenShare => """Impossible d'ouvrir le contenu partagé.""";

  /// ```dart
  /// "Aucune maison disponible. Créez d'abord une maison."
  /// ```
  String get noHouses =>
      """Aucune maison disponible. Créez d'abord une maison.""";
}

class RecurrenceMessagesFr extends RecurrenceMessages {
  final MessagesFr _parent;
  const RecurrenceMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Récurrence"
  /// ```
  String get title => """Récurrence""";

  /// ```dart
  /// "Préréglages"
  /// ```
  String get presets => """Préréglages""";

  /// ```dart
  /// "Quotidien"
  /// ```
  String get daily => """Quotidien""";

  /// ```dart
  /// "Hebdomadaire"
  /// ```
  String get weekly => """Hebdomadaire""";

  /// ```dart
  /// "Mensuel"
  /// ```
  String get monthly => """Mensuel""";

  /// ```dart
  /// "Tous les"
  /// ```
  String get everyLabel => """Tous les""";

  /// ```dart
  /// "Unité"
  /// ```
  String get unit => """Unité""";

  /// ```dart
  /// "jours"
  /// ```
  String get unitDays => """jours""";

  /// ```dart
  /// "semaines"
  /// ```
  String get unitWeeks => """semaines""";

  /// ```dart
  /// "mois"
  /// ```
  String get unitMonths => """mois""";

  /// ```dart
  /// "années"
  /// ```
  String get unitYears => """années""";

  /// ```dart
  /// "Répéter le"
  /// ```
  String get repeatOn => """Répéter le""";

  /// ```dart
  /// "Se termine"
  /// ```
  String get ends => """Se termine""";

  /// ```dart
  /// "Jamais"
  /// ```
  String get never => """Jamais""";

  /// ```dart
  /// "Après"
  /// ```
  String get after => """Après""";

  /// ```dart
  /// "répétitions"
  /// ```
  String get occurrences => """répétitions""";

  /// ```dart
  /// "À la date"
  /// ```
  String get onDate => """À la date""";

  /// ```dart
  /// "Compter l'intervalle à partir du moment où l'article est coché"
  /// ```
  String get countFromCompletion =>
      """Compter l'intervalle à partir du moment où l'article est coché""";

  /// ```dart
  /// "Le calendrier est fixe : l'article réapparaît à sa prochaine occurrence prévue, peu importe quand vous le cochez."
  /// ```
  String get countFromCompletionHintOff =>
      """Le calendrier est fixe : l'article réapparaît à sa prochaine occurrence prévue, peu importe quand vous le cochez.""";

  /// ```dart
  /// "La prochaine occurrence est comptée à partir du moment où vous cochez l'article, de sorte qu'il revient toujours un intervalle complet après son achèvement."
  /// ```
  String get countFromCompletionHintOn =>
      """La prochaine occurrence est comptée à partir du moment où vous cochez l'article, de sorte qu'il revient toujours un intervalle complet après son achèvement.""";

  /// ```dart
  /// "Résumé"
  /// ```
  String get summary => """Résumé""";

  /// ```dart
  /// "non défini"
  /// ```
  String get notSet => """non défini""";

  /// ```dart
  /// "défini"
  /// ```
  String get set => """défini""";

  /// ```dart
  /// "tous les $unit"
  /// ```
  String every(String unit) => """tous les $unit""";

  /// ```dart
  /// "Tous les $unit"
  /// ```
  String everyButton(String unit) => """Tous les $unit""";

  /// ```dart
  /// "le $days"
  /// ```
  String onDays(String days) => """le $days""";

  /// ```dart
  /// "${_plural(count, one: 'jour', many: '$count jours')}"
  /// ```
  String day(int count) =>
      """${_plural(count, one: 'jour', many: '$count jours')}""";

  /// ```dart
  /// "${_plural(count, one: 'semaine', many: '$count semaines')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'semaine', many: '$count semaines')}""";

  /// ```dart
  /// "${_plural(count, one: 'mois', many: '$count mois')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'mois', many: '$count mois')}""";

  /// ```dart
  /// "${_plural(count, one: 'an', many: '$count ans')}"
  /// ```
  String year(int count) =>
      """${_plural(count, one: 'an', many: '$count ans')}""";
  DayNamesRecurrenceMessagesFr get dayNames =>
      DayNamesRecurrenceMessagesFr(this);
  DayAbbrRecurrenceMessagesFr get dayAbbr => DayAbbrRecurrenceMessagesFr(this);
}

class DayNamesRecurrenceMessagesFr extends DayNamesRecurrenceMessages {
  final RecurrenceMessagesFr _parent;
  const DayNamesRecurrenceMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Lundi"
  /// ```
  String get monday => """Lundi""";

  /// ```dart
  /// "Mardi"
  /// ```
  String get tuesday => """Mardi""";

  /// ```dart
  /// "Mercredi"
  /// ```
  String get wednesday => """Mercredi""";

  /// ```dart
  /// "Jeudi"
  /// ```
  String get thursday => """Jeudi""";

  /// ```dart
  /// "Vendredi"
  /// ```
  String get friday => """Vendredi""";

  /// ```dart
  /// "Samedi"
  /// ```
  String get saturday => """Samedi""";

  /// ```dart
  /// "Dimanche"
  /// ```
  String get sunday => """Dimanche""";
}

class DayAbbrRecurrenceMessagesFr extends DayAbbrRecurrenceMessages {
  final RecurrenceMessagesFr _parent;
  const DayAbbrRecurrenceMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Lu"
  /// ```
  String get mo => """Lu""";

  /// ```dart
  /// "Ma"
  /// ```
  String get tu => """Ma""";

  /// ```dart
  /// "Me"
  /// ```
  String get we => """Me""";

  /// ```dart
  /// "Je"
  /// ```
  String get th => """Je""";

  /// ```dart
  /// "Ve"
  /// ```
  String get fr => """Ve""";

  /// ```dart
  /// "Sa"
  /// ```
  String get sa => """Sa""";

  /// ```dart
  /// "Di"
  /// ```
  String get su => """Di""";
}

class SyncMessagesFr extends SyncMessages {
  final MessagesFr _parent;
  const SyncMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Hors ligne"
  /// ```
  String get offline => """Hors ligne""";

  /// ```dart
  /// "Synchronisation des modifications…"
  /// ```
  String get syncing => """Synchronisation des modifications…""";

  /// ```dart
  /// "${_plural(count, one: '1 modification en attente de synchronisation', many: '${count} modifications en attente de synchronisation')}"
  /// ```
  String pendingChanges(int count) =>
      """${_plural(count, one: '1 modification en attente de synchronisation', many: '${count} modifications en attente de synchronisation')}""";

  /// ```dart
  /// "Impossible de synchroniser les modifications"
  /// ```
  String get syncError => """Impossible de synchroniser les modifications""";

  /// ```dart
  /// "Réessayer"
  /// ```
  String get retry => """Réessayer""";
}

class MarkdownEditorMessagesFr extends MarkdownEditorMessages {
  final MessagesFr _parent;
  const MarkdownEditorMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Markdown"
  /// ```
  String get editSource => """Markdown""";

  /// ```dart
  /// "Texte enrichi"
  /// ```
  String get editRich => """Texte enrichi""";
}

Map<String, String> get messagesFrMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Annuler""",
  """common.delete""": """Supprimer""",
  """common.save""": """Enregistrer""",
  """common.retry""": """Réessayer""",
  """common.refresh""": """Actualiser""",
  """common.logout""": """Déconnexion""",
  """common.loading""": """Chargement...""",
  """common.error""": """Erreur""",
  """common.copy""": """Copier""",
  """common.copied""": """Copié""",
  """common.closeDialog""": """Terminé""",
  """common.remove""": """Retirer""",
  """common.clear""": """Effacer""",
  """common.permissionDenied""":
      """Vous n'avez pas la permission de faire cela""",
  """common.noAccessTitle""": """Aucun accès""",
  """common.noAccessBody""":
      """Vous n'avez encore accès à rien dans ce foyer. Un administrateur peut vous accorder des autorisations dans l'application web Pantry.""",
  """login.connectToNextcloud""":
      """Connectez-vous à votre instance Nextcloud""",
  """login.serverUrl""": """URL du serveur""",
  """login.serverUrlHint""": """cloud.example.com""",
  """login.connect""": """Connexion""",
  """login.waitingForAuth""": """En attente d'authentification...
Veuillez terminer la connexion dans votre navigateur.""",
  """login.couldNotConnect""":
      """Impossible de se connecter au serveur. Veuillez vérifier l'URL.""",
  """login.loginFailed""": """Échec de la connexion. Veuillez réessayer.""",
  """login.seeDetails""": """Voir les détails""",
  """login.errorDetailsTitle""": """Détails de l'erreur""",
  """login.untrustedCertTitle""": """Certificat non approuvé""",
  """login.untrustedCertWarning""":
      """N'approuvez ce certificat que si vous reconnaissez l'empreinte. Approuver un certificat inattendu peut permettre à un attaquant de lire votre trafic.""",
  """login.trustCertificate""": """Approuver le certificat""",
  """login.certFingerprint""": """Empreinte SHA-256""",
  """login.certSubject""": """Sujet""",
  """login.certIssuer""": """Émetteur""",
  """login.certValidity""": """Validité""",
  """login.useAppPassword""":
      """Se connecter avec un mot de passe d'application""",
  """login.useBrowserLogin""": """Se connecter avec le navigateur""",
  """login.username""": """Nom d'utilisateur""",
  """login.appPassword""": """Mot de passe d'application""",
  """login.appPasswordHelp""":
      """Créez un mot de passe d'application dans Nextcloud sous Paramètres → Sécurité → Appareils et sessions. Utilisez-le si la connexion par navigateur ne s'ouvre pas ou si votre serveur utilise un certificat auto-signé.""",
  """login.appPasswordMissing""":
      """Veuillez saisir votre nom d'utilisateur et votre mot de passe d'application.""",
  """login.signIn""": """Se connecter""",
  """login.couldNotReachServer""":
      """Impossible de joindre le serveur. Vérifiez l'adresse ainsi que votre connexion réseau ou VPN.""",
  """login.connectionTimeout""":
      """Le serveur a mis trop de temps à répondre. Vérifiez votre connexion réseau ou VPN et réessayez.""",
  """login.certProbeFailed""":
      """Impossible de lire le certificat du serveur pour le vérifier. La connexion est peut-être instable ou le serveur injoignable.""",
  """home.noHouses""": """Aucune maison pour le moment.""",
  """home.noHousesBody""":
      """Les maisons sont des espaces partagés pour votre foyer. Créez votre première maison pour commencer à ajouter des listes, des photos et des notes.""",
  """home.createHouse""": """Créer une maison""",
  """home.houseName""": """Nom de la maison""",
  """home.houseDescription""": """Description (facultatif)""",
  """home.createHouseFailed""": """Impossible de créer la maison.""",
  """home.failedToLoadHouses""": """Impossible de charger les maisons.""",
  """home.serverAppMissingTitle""": """Pantry n'est pas installé""",
  """home.serverAppMissingBody""":
      """Cette application est un client pour l'application Pantry sur Nextcloud. Il semble que Pantry ne soit pas encore installé sur votre serveur. Demandez à votre administrateur de l'installer depuis le magasin d'applications Nextcloud, ou installez-le vous-même si vous avez un accès administrateur.""",
  """home.openAppStore""": """Ouvrir les apps Nextcloud""",
  """home.learnMore""": """En savoir plus""",
  """nav.checklists""": """Listes""",
  """nav.photoBoard""": """Tableau photos""",
  """nav.notesWall""": """Mur de notes""",
  """onboarding.next""": """Suivant""",
  """onboarding.back""": """Retour""",
  """onboarding.skip""": """Ignorer""",
  """onboarding.done""": """C'est parti""",
  """onboarding.welcomeNewTitle""": """Bienvenue dans Pantry""",
  """onboarding.welcomeNewBody""":
      """Faisons un tour rapide du fonctionnement de Pantry pour que tu en profites au maximum.""",
  """onboarding.welcomeUpdateTitle""": """Nouveautés""",
  """onboarding.welcomeUpdateBody""":
      """Pantry a appris quelques nouveaux tours depuis ta dernière visite. Voici un aperçu rapide.""",
  """onboarding.checklistsRedesignTitle""":
      """Les listes ont une nouvelle allure""",
  """onboarding.checklistsRedesignBody""":
      """La page des listes a été reconstruite de zéro : mise en page plus claire, ajout d'éléments plus rapide et actions rapides sur chaque ligne. Les prochaines pages te présentent les nouveautés.""",
  """onboarding.checklistSelectorTitle""":
      """Changer de liste depuis le haut""",
  """onboarding.checklistSelectorBody""":
      """Touche le nom de la liste ou son icône en haut pour passer d'une liste à l'autre ou en créer une nouvelle.""",
  """onboarding.checklistSelectorHint""": """Touche pour changer de liste""",
  """onboarding.mockListGroceries""": """Courses""",
  """onboarding.mockListHardware""": """Bricolage""",
  """onboarding.mockListWeekend""": """Week-end""",
  """onboarding.newListLabel""": """Nouvelle liste""",
  """onboarding.swipeActionsTitle""": """Balaie les éléments pour les gérer""",
  """onboarding.swipeActionsBody""":
      """Balaie un élément de droite à gauche pour faire apparaître des actions rapides : éditer, déplacer ou supprimer.""",
  """onboarding.swipeActionsHint""": """Balaie vers la gauche""",
  """onboarding.swipeActionsHintBack""": """Balaie vers la droite""",
  """onboarding.quickActionsTitle""": """Actions rapides sur chaque élément""",
  """onboarding.quickActionsBody""":
      """Chaque élément affiche des boutons d'action à son extrémité — clique dessus pour modifier, déplacer ou supprimer l'élément sans l'ouvrir.""",
  """onboarding.addItemsTitle""": """Une façon plus rapide d'ajouter""",
  """onboarding.addItemsBody""":
      """Touche le champ en bas pour saisir un nouvel élément, puis associe-lui une catégorie, une quantité, un type ou une photo via les chips au-dessus.""",
  """onboarding.mockComposeListName""": """Courses""",
  """onboarding.progressHeroTitle""": """Masquer la carte de progression""",
  """onboarding.progressHeroBody""":
      """Pas besoin de l'anneau de progression en haut ? Balaie-le pour le retirer.""",
  """onboarding.progressHeroHint""": """Balaie pour masquer""",
  """onboarding.progressHeroDismissTitle""":
      """Masque la carte de progression""",
  """onboarding.progressHeroDismissBody""":
      """Tu n'as pas besoin de l'anneau de progression en haut ? Clique sur le X de la carte pour la masquer.""",
  """onboarding.pinnedListsTitle""":
      """Épingle des listes à ton écran d'accueil""",
  """onboarding.pinnedListsBody""":
      """Ajoute le widget Pantry à ton écran d'accueil pour voir d'un coup d'œil combien d'articles restent sur tes listes préférées — sans ouvrir l'app.""",
  """onboarding.pinnedListsMenuLabel""": """le menu""",
  """onboarding.pinnedListsActionLabel""": """Épingler la liste""",
  """onboarding.pinnedListsWidgetTitle""": """Pantry""",
  """onboarding.pinnedListsWidgetEmpty""": """Tout est fait""",
  """onboarding.pinnedNotesTitle""": """Garde les notes importantes en haut""",
  """onboarding.pinnedNotesBody""":
      """Épingle une note depuis son menu de débordement pour la fixer en haut de ton mur de notes, au-dessus des notes plus récentes.""",
  """onboarding.mockPinnedNoteTitle""": """Mot de passe Wi-Fi""",
  """onboarding.mockPinnedNoteContent""": """Réseau : Maison
Mot de passe : pantry-rocks""",
  """onboarding.mockItemName""": """Tomates""",
  """onboarding.mockItemQuantity""": """x2""",
  """onboarding.mockItemCategory""": """Légumes""",
  """onboarding.mockHardwareItemName""": """Ampoules""",
  """onboarding.mockBulkItemThird""": """Lait""",
  """onboarding.mockBulkItemFourth""": """Pain""",
  """onboarding.allListsTitle""": """Tout dans une seule vue""",
  """onboarding.allListsBody""":
      """Ouvre la vue Toutes les listes depuis le sélecteur pour voir les éléments de toutes tes listes ensemble. Quand tu ajoutes un élément depuis ici, le formulaire te demande dans quelle liste le placer — choisis-la dans le chip Liste.""",
  """onboarding.bulkAddTitle""": """Ajoute plusieurs éléments d'un coup""",
  """onboarding.bulkAddBody""":
      """Active le bouton Multiple et le champ devient une zone multi-ligne — chaque ligne devient un élément distinct. Pratique quand tu colles une liste ou que tu notes toutes tes courses d'un seul coup.""",
  """onboarding.bulkSelectTitle""":
      """Agissez sur plusieurs articles à la fois""",
  """onboarding.bulkSelectBody""":
      """Appuyez longuement sur un article — ou touchez Sélectionner dans le menu — pour commencer la sélection, puis déplacez, copiez, catégorisez ou supprimez tout ce que vous avez choisi en une seule fois.""",
  """onboarding.barcodeScanTitle""":
      """Scannez un code-barres pour ajouter des articles""",
  """onboarding.barcodeScanBody""":
      """Touchez le bouton de scan dans la barre d'ajout et dirigez la caméra vers le code-barres d'un produit. Pantry en trouve le nom, la catégorie et la photo et les remplit pour vous — ou saisissez le numéro à la main. Le premier scan d'un produit lance la recherche ; ensuite, c'est instantané pour toute votre maison.""",
  """onboarding.barcodeScanMockName""": """Coca-Cola Zero""",
  """onboarding.barcodeScanMockCategory""": """Boissons""",
  """onboarding.priceTitle""": """Ajoutez des prix à vos articles""",
  """onboarding.priceBody""":
      """Donnez à un article un prix — un montant unique ou une fourchette — dans la devise de votre choix. Il apparaît sous forme d'étiquette sur l'article, et vous pouvez filtrer votre liste par prix pour respecter votre budget.""",
  """onboarding.priceMockName""": """Huile d'olive""",
  """onboarding.shoppingIntroTitle""":
      """Fais tes courses magasin par magasin""",
  """onboarding.shoppingIntroBody""":
      """Lance une virée à partir de tes listes, parcours chaque magasin dans l'ordre et coche les articles au fur et à mesure — avec un total des prix en direct.""",
  """onboarding.shoppingMockStoreActive""": """Supermarché""",
  """onboarding.shoppingMockStoreNext""": """Pharmacie""",
  """onboarding.dev.showOnboarding""": """Afficher l'intro""",
  """onboarding.dev.pickLastSeenTitle""": """Aperçu des nouveautés""",
  """onboarding.dev.pickLastSeenBody""":
      """Choisis la version dont tu veux voir les nouveautés, telles qu'un utilisateur les verrait en passant à cette version.""",
  """onboarding.dev.neverSeen""": """Jamais vue (nouvel utilisateur)""",
  """onboarding.dev.forceAllFeatures""":
      """Forcer toutes les fonctionnalités""",
  """onboarding.dev.sendTestNotification""":
      """Envoyer une notification de test""",
  """notificationsIntro.title""": """Restez informé""",
  """notificationsIntro.body""":
      """Pantry peut vous notifier lorsque les membres du foyer ajoutent des articles aux listes, téléchargent des photos ou laissent des notes. Les notifications sont récupérées depuis votre propre serveur Nextcloud — rien ne passe par Google ou des tiers.""",
  """notificationsIntro.bullet1""": """Alertes d'activité du foyer""",
  """notificationsIntro.bullet2""":
      """Récupérées directement depuis votre serveur""",
  """notificationsIntro.bullet3""":
      """Fonctionne même lorsque l'app est fermée""",
  """notificationsIntro.enableButton""": """Activer les notifications""",
  """notificationsIntro.skipButton""": """Pas maintenant""",
  """notificationsIntro.permissionDeniedTitle""": """Permission refusée""",
  """notificationsIntro.permissionDeniedBody""":
      """Vous pourrez activer les notifications plus tard dans les réglages de l'app. Si votre appareil les bloque, vous devrez d'abord les autoriser dans les réglages système.""",
  """notificationsIntro.ok""": """OK""",
  """about.title""": """À propos""",
  """about.developer""": """Développeur""",
  """about.email""": """E-mail""",
  """about.repository""": """Code source""",
  """about.nextcloudApp""": """App Nextcloud""",
  """about.privacyPolicy""": """Politique de confidentialité""",
  """about.feedback""": """Commentaires & problèmes""",
  """about.serverVersion""": """Serveur Nextcloud""",
  """about.pantryServerVersion""": """Pantry sur le serveur""",
  """about.versionUnknown""": """Inconnu""",
  """about.buyMeACoffee""": """Offrez-moi un café""",
  """settings.title""": """Réglages de l'app""",
  """settings.generalSection""": """Général""",
  """settings.interfaceSection""": """Interface""",
  """settings.defaultItemTapAction""": """Action par défaut au toucher""",
  """settings.defaultItemTapActionBody""":
      """Ce qui se passe quand vous touchez la ligne d'un élément.""",
  """settings.itemTapActionNames.done""": """Marquer comme fait""",
  """settings.itemTapActionNames.view""": """Voir""",
  """settings.itemTapActionNames.edit""": """Modifier""",
  """settings.itemTapActionNames.none""": """Aucune""",
  """settings.defaultItemLongPressAction""":
      """Action par défaut à l'appui long""",
  """settings.defaultItemLongPressActionBody""":
      """Ce qui se passe quand vous appuyez longuement sur la ligne d'un élément.""",
  """settings.itemLongPressActionNames.multiselect""":
      """Sélection multiple/Réorganiser""",
  """settings.itemLongPressActionNames.done""": """Marquer comme fait""",
  """settings.itemLongPressActionNames.view""": """Voir""",
  """settings.itemLongPressActionNames.edit""": """Modifier""",
  """settings.itemLongPressActionNames.none""": """Aucune""",
  """settings.checkboxPosition""": """Position de la case à cocher""",
  """settings.checkboxPositionBody""":
      """De quel côté de la ligne la case à cocher apparaît.""",
  """settings.checkboxPositionNames.start""": """Début""",
  """settings.checkboxPositionNames.end""": """Fin""",
  """settings.density""": """Densité de la liste""",
  """settings.densityBody""":
      """L'espace occupé par chaque article dans vos listes.""",
  """settings.densityNames.normal""": """Normale""",
  """settings.densityNames.dense""": """Compacte""",
  """settings.densityNames.compact""": """Très compacte""",
  """settings.swipeActions""": """Actions par balayage""",
  """settings.swipeActionsBody""":
      """Balayez les éléments vers la gauche pour afficher des actions rapides. Désactivé, les actions passent dans un menu sur chaque élément.""",
  """settings.itemActions""": """Actions des éléments""",
  """settings.itemActionsBody""":
      """Affiche des actions rapides sur chaque élément. Désactivé, les actions passent dans un menu sur chaque élément.""",
  """settings.reuseExistingItems""":
      """Réutiliser les articles existants lors de l'ajout""",
  """settings.reuseExistingItemsBody""":
      """Lorsque vous ajoutez un article qui existe déjà dans la liste, réutiliser cet article.""",
  """settings.reuseExistingItemsNames.ask""": """Toujours demander""",
  """settings.reuseExistingItemsNames.reuse""": """Toujours réutiliser""",
  """settings.reuseExistingItemsNames.never""": """Ne jamais réutiliser""",
  """settings.navOrderTitle""": """Ordre de navigation""",
  """settings.navOrderSubtitle""":
      """Réorganisez les onglets de la barre de navigation. Le premier élément s'ouvre au démarrage.""",
  """settings.navOrderBody""":
      """Faites glisser pour réorganiser les onglets. La première section visible s'ouvre au démarrage de l'application. Désactivez les sections que vous n'utilisez pas pour masquer leur onglet ; au moins une doit rester activée.""",
  """settings.navOrderDefaultHint""": """S'ouvre au démarrage""",
  """settings.navOrderReset""": """Réinitialiser""",
  """settings.visibleChipsTitle""": """Détails de l'article""",
  """settings.visibleChipsSubtitle""":
      """Choisissez les détails affichés sur chaque article.""",
  """settings.visibleChipsBody""":
      """Désactivez les détails que vous ne voulez pas voir affichés sur les lignes d'articles.""",
  """settings.visibleChipsReset""": """Réinitialiser""",
  """settings.chipNames.category""": """Catégorie""",
  """settings.chipNames.store""": """Magasin""",
  """settings.chipNames.quantity""": """Quantité""",
  """settings.chipNames.price""": """Prix""",
  """settings.chipNames.note""": """Note""",
  """settings.chipNames.oneTime""": """Unique""",
  """settings.chipNames.recurring""": """Récurrent""",
  """settings.chipNames.list""": """Liste""",
  """settings.language""": """Langue""",
  """settings.systemLanguage""": """Par défaut du système""",
  """settings.theme""": """Thème""",
  """settings.themeNames.system""": """Par défaut du système""",
  """settings.themeNames.light""": """Clair""",
  """settings.themeNames.dark""": """Sombre""",
  """settings.useServerThemeColor""":
      """Utiliser la couleur du thème Nextcloud""",
  """settings.useServerThemeColorBody""":
      """Teinte l'application avec la couleur du thème de votre utilisateur Nextcloud. Désactivez pour utiliser les couleurs propres à l'application.""",
  """settings.notificationsSection""": """Notifications""",
  """settings.enableNotifications""": """Activer les notifications""",
  """settings.enableNotificationsBody""":
      """Afficher des alertes lorsque les membres du foyer ajoutent ou modifient du contenu.""",
  """settings.pollInterval""": """Vérifier les nouvelles activités""",
  """settings.pollInterval15m""": """Toutes les 15 minutes""",
  """settings.pollInterval30m""": """Toutes les 30 minutes""",
  """settings.pollInterval1h""": """Toutes les heures""",
  """settings.pollInterval2h""": """Toutes les 2 heures""",
  """settings.pollInterval6h""": """Toutes les 6 heures""",
  """settings.permissionDenied""":
      """La permission de notification a été refusée. Activez-la dans les réglages système.""",
  """settings.refreshSection""": """Actualisation automatique""",
  """settings.refreshSectionBody""":
      """À quelle fréquence chaque écran vérifie les changements sur le serveur pendant que vous le consultez. Vous pouvez toujours tirer vers le bas pour actualiser manuellement.""",
  """settings.checklistRefresh""": """Listes""",
  """settings.notesRefresh""": """Notes""",
  """settings.photosRefresh""": """Photos""",
  """settings.shoppingRefresh""": """Mode courses""",
  """settings.refreshOff""": """Désactivé""",
  """settings.refreshInherit""": """Comme les listes""",
  """settings.refresh15s""": """Toutes les 15 secondes""",
  """settings.refresh30s""": """Toutes les 30 secondes""",
  """settings.refresh1m""": """Chaque minute""",
  """settings.refresh2m""": """Toutes les 2 minutes""",
  """settings.refresh5m""": """Toutes les 5 minutes""",
  """notifications.title""": """Notifications""",
  """notifications.empty""": """Aucune nouvelle notification.""",
  """notifications.failedToLoad""":
      """Impossible de charger les notifications.""",
  """notifications.dismissAll""": """Tout ignorer""",
  """notifications.justNow""": """à l'instant""",
  """categories.manageTitle""": """Gérer les catégories""",
  """categories.noCategories""": """Aucune catégorie pour le moment.""",
  """categories.editTitle""": """Modifier la catégorie""",
  """categories.addTitle""": """Nouvelle catégorie""",
  """categories.name""": """Nom""",
  """categories.icon""": """Icône""",
  """categories.color""": """Couleur""",
  """categories.saveFailed""": """Impossible d'enregistrer la catégorie.""",
  """categories.deleteFailed""": """Impossible de supprimer la catégorie.""",
  """categories.deleteConfirm""": """Supprimer cette catégorie ?""",
  """categories.deleteConfirmBody""":
      """Les articles de cette catégorie seront non catégorisés. Cette action est irréversible.""",
  """categories.sort.nameAZ""": """Nom A–Z""",
  """categories.sort.nameZA""": """Nom Z–A""",
  """categories.sort.custom""": """Personnalisé""",
  """stores.manageTitle""": """Gérer les magasins""",
  """stores.noStores""": """Aucun magasin pour le moment.""",
  """stores.editTitle""": """Modifier le magasin""",
  """stores.addTitle""": """Nouveau magasin""",
  """stores.name""": """Nom""",
  """stores.icon""": """Icône""",
  """stores.color""": """Couleur""",
  """stores.saveFailed""": """Impossible d'enregistrer le magasin.""",
  """stores.deleteFailed""": """Impossible de supprimer le magasin.""",
  """stores.deleteConfirm""": """Supprimer ce magasin ?""",
  """stores.deleteConfirmBody""":
      """Ce magasin sera retiré de tous les articles. Cette action est irréversible.""",
  """stores.brand""": """Marque/chaîne""",
  """stores.brandHint""": """p. ex. Walmart, IKEA""",
  """stores.location""": """Emplacement""",
  """stores.locationHint""": """p. ex. 12 rue Principale""",
  """stores.openingHours""": """Horaires d'ouverture""",
  """stores.addOpeningHours""": """Ajouter des horaires""",
  """stores.openingHoursStart""": """Début""",
  """stores.openingHoursEnd""": """Fin""",
  """stores.openingHoursAdd""": """Ajouter""",
  """stores.contact""": """Contact""",
  """stores.contactHint""": """p. ex. téléphone, site web, réseaux sociaux""",
  """stores.responsible""": """Responsable""",
  """stores.responsibleHint""": """p. ex. gérant du magasin""",
  """stores.notes""": """Notes""",
  """stores.notesHint""": """Toute autre chose à retenir""",
  """stores.noDetails""": """Aucun détail ajouté pour le moment.""",
  """stores.editAction""": """Modifier""",
  """stores.sort.nameAZ""": """Nom A–Z""",
  """stores.sort.nameZA""": """Nom Z–A""",
  """stores.sort.custom""": """Personnalisé""",
  """checklists.categories""": """Catégories""",
  """checklists.noChecklists""": """Aucune liste pour le moment.""",
  """checklists.noItems""": """Aucun article dans cette liste.""",
  """checklists.noSearchResults""":
      """Aucun article ne correspond à votre recherche.""",
  """checklists.searchHint""": """Filtrer...""",
  """checklists.barcode.scan""": """Scanner le code-barres""",
  """checklists.barcode.scanTitle""": """Scanner le code-barres""",
  """checklists.barcode.scanInstructions""":
      """Dirigez la caméra vers un code-barres de produit""",
  """checklists.barcode.enterManually""": """Saisir manuellement""",
  """checklists.barcode.manualTitle""": """Saisir le code-barres""",
  """checklists.barcode.manualHint""": """Numéro de code-barres""",
  """checklists.barcode.invalidBarcode""":
      """Cela ne ressemble pas à un code-barres valide""",
  """checklists.barcode.notFound""":
      """Aucune info produit trouvée pour ce code-barres""",
  """checklists.allCategories""": """Tout""",
  """checklists.allListsChip""": """Tout""",
  """checklists.filterByList""": """Filtrer par liste""",
  """checklists.filterByCategory""": """Filtrer par catégorie""",
  """checklists.filters.lists""": """Listes""",
  """checklists.filters.categories""": """Catégories""",
  """checklists.filters.stores""": """Magasins""",
  """checklists.filters.allLists""": """Toutes les listes""",
  """checklists.filters.allCategories""": """Toutes les catégories""",
  """checklists.filters.allStores""": """Tous les magasins""",
  """checklists.filters.noCategory""": """Sans catégorie""",
  """checklists.filters.noStores""": """Sans magasin""",
  """checklists.filters.price""": """Prix""",
  """checklists.filters.anyCurrency""": """N'importe quelle devise""",
  """checklists.failedToLoad""": """Impossible de charger les listes.""",
  """checklists.failedToLoadItems""": """Impossible de charger les articles.""",
  """checklists.editItem""": """Modifier l'article""",
  """checklists.removeItem""": """Supprimer l'article""",
  """checklists.moveItem""": """Déplacer vers une liste""",
  """checklists.moveFailed""": """Impossible de déplacer l'article.""",
  """checklists.copyItem""": """Copier vers une liste""",
  """checklists.copyFailed""": """Impossible de copier l'article.""",
  """checklists.itemCopied""": """Article copié""",
  """checklists.itemMarkedDone""": """Article marqué comme fait""",
  """checklists.itemRemoved""": """Article supprimé""",
  """checklists.undo""": """Annuler""",
  """checklists.selectItems""": """Sélectionner""",
  """checklists.batch.moveTitle""": """Déplacer les articles vers""",
  """checklists.batch.copyTitle""": """Copier les articles vers""",
  """checklists.batch.categoryTitle""": """Définir la catégorie""",
  """checklists.batch.storesTitle""": """Définir les magasins""",
  """checklists.batch.clearCategory""": """Aucune catégorie""",
  """checklists.batch.move""": """Déplacer""",
  """checklists.batch.copy""": """Copier""",
  """checklists.batch.category""": """Catégorie""",
  """checklists.batch.stores""": """Magasins""",
  """checklists.batch.delete""": """Supprimer""",
  """checklists.batch.archive""": """Archiver""",
  """checklists.batch.unarchive""": """Désarchiver""",
  """checklists.batch.deleteConfirmTitle""": """Supprimer les articles ?""",
  """checklists.batch.failed""":
      """Une erreur s'est produite. Veuillez réessayer.""",
  """checklists.viewTrash""": """Afficher la corbeille""",
  """checklists.exitTrash""": """Quitter la corbeille""",
  """checklists.showAddedBy""": """Afficher qui a ajouté chaque article""",
  """checklists.showProgressHero""":
      """Afficher la carte de progression sur cette liste""",
  """checklists.trashTitle""": """Corbeille""",
  """checklists.noTrashedItems""": """La corbeille est vide.""",
  """checklists.emptyTrash""": """Vider la corbeille""",
  """checklists.emptyTrashConfirm""": """Vider la corbeille ?""",
  """checklists.emptyTrashConfirmBody""":
      """Tous les articles de la corbeille seront supprimés définitivement. Cette action est irréversible.""",
  """checklists.emptyTrashFailed""": """Impossible de vider la corbeille.""",
  """checklists.restoreItem""": """Restaurer""",
  """checklists.permanentlyDeleteItem""": """Supprimer""",
  """checklists.permanentlyDeleteConfirm""":
      """Supprimer définitivement cet article ?""",
  """checklists.permanentlyDeleteConfirmBody""":
      """Cette action est irréversible.""",
  """checklists.restoreFailed""": """Impossible de restaurer l'article.""",
  """checklists.permanentlyDeleteFailed""":
      """Impossible de supprimer l'article.""",
  """checklists.itemRestored""": """Article restauré""",
  """checklists.viewArchive""": """Voir les archives""",
  """checklists.exitArchive""": """Quitter les archives""",
  """checklists.archiveTitle""": """Archives""",
  """checklists.noCategory""": """Sans catégorie""",
  """checklists.noStore""": """Sans magasin""",
  """checklists.noArchivedItems""": """Les archives sont vides.""",
  """checklists.archiveItem""": """Archiver""",
  """checklists.unarchiveItem""": """Désarchiver""",
  """checklists.archiveFailed""": """Échec de l'archivage de l'article.""",
  """checklists.unarchiveFailed""": """Échec du désarchivage de l'article.""",
  """checklists.itemArchived""": """Article archivé""",
  """checklists.itemUnarchived""": """Article désarchivé""",
  """checklists.failedToLoadArchive""": """Échec du chargement des archives.""",
  """checklists.viewListsTrash""": """Listes supprimées""",
  """checklists.listsTrashTitle""": """Listes supprimées""",
  """checklists.failedToLoadTrash""": """Impossible de charger la corbeille.""",
  """checklists.listTrashEmpty""": """Aucune liste supprimée.""",
  """checklists.pinList""": """Épingler la liste""",
  """checklists.unpinList""": """Détacher la liste""",
  """checklists.removeList""": """Retirer la liste""",
  """checklists.editList""": """Modifier la liste""",
  """checklists.editListTitle""": """Modifier la liste""",
  """checklists.saveListButton""": """Enregistrer les modifications""",
  """checklists.updateListFailed""":
      """Impossible de mettre à jour la liste.""",
  """checklists.removeListConfirm""": """Retirer la liste ?""",
  """checklists.removeListFailed""": """Impossible de retirer la liste.""",
  """checklists.restoreList""": """Restaurer la liste""",
  """checklists.permanentlyDeleteList""": """Supprimer définitivement""",
  """checklists.listRemoved""": """Liste retirée""",
  """checklists.createList""": """Nouvelle liste""",
  """checklists.listName""": """Nom de la liste""",
  """checklists.listDescription""": """Description (facultatif)""",
  """checklists.listIcon""": """Icône""",
  """checklists.createListFailed""": """Impossible de créer la liste.""",
  """checklists.viewItem.quantity""": """Quantité :""",
  """checklists.viewItem.category""": """Catégorie :""",
  """checklists.viewItem.recurrence""": """Récurrence :""",
  """checklists.viewItem.nextDue""": """Prochaine échéance :""",
  """checklists.viewItem.nextDueFromCompletion""":
      """Prochaine échéance (à partir de la complétion) :""",
  """checklists.viewItem.overdue""": """En retard""",
  """checklists.viewItem.quantityLabel""": """Quantité""",
  """checklists.viewItem.typeLabel""": """Type""",
  """checklists.viewItem.priceLabel""": """Prix""",
  """checklists.viewItem.descriptionLabel""": """Description""",
  """checklists.viewItem.noDescription""": """Aucune description ajoutée.""",
  """checklists.viewItem.relJustNow""": """à l'instant""",
  """checklists.viewItem.relToday""": """aujourd'hui""",
  """checklists.viewItem.relYesterday""": """hier""",
  """checklists.itemForm.addTitle""": """Ajouter un article""",
  """checklists.itemForm.editTitle""": """Modifier l'article""",
  """checklists.itemForm.name""": """Nom de l'article""",
  """checklists.itemForm.description""": """Description""",
  """checklists.itemForm.quantity""": """Quantité""",
  """checklists.itemForm.category""": """Catégorie""",
  """checklists.itemForm.noCategory""": """Aucune""",
  """checklists.itemForm.noCategories""": """Aucune catégorie disponible.""",
  """checklists.itemForm.createCategory""": """Nouvelle catégorie""",
  """checklists.itemForm.categoryName""": """Nom""",
  """checklists.itemForm.categoryIcon""": """Icône""",
  """checklists.itemForm.categoryColor""": """Couleur""",
  """checklists.itemForm.categoryCreated""": """Catégorie créée.""",
  """checklists.itemForm.categoryCreateFailed""":
      """Impossible de créer la catégorie.""",
  """checklists.itemForm.stores""": """Magasins""",
  """checklists.itemForm.noStores""": """Aucun""",
  """checklists.itemForm.createStore""": """Nouveau magasin""",
  """checklists.itemForm.storesChange""": """Modifier""",
  """checklists.itemForm.storesPick""": """Choisir""",
  """checklists.itemForm.repeat""": """Répéter""",
  """checklists.itemForm.once""": """Une fois""",
  """checklists.itemForm.onceDescription""":
      """Supprimer cet article une fois qu'il est marqué comme fait.""",
  """checklists.itemForm.image""": """Image""",
  """checklists.itemForm.addImage""": """Ajouter une image""",
  """checklists.itemForm.takePhoto""": """Prendre une photo""",
  """checklists.itemForm.chooseImage""": """Choisir une image""",
  """checklists.itemForm.replaceImage""": """Remplacer""",
  """checklists.itemForm.removeImage""": """Supprimer""",
  """checklists.itemForm.saveFailed""":
      """Impossible d'enregistrer l'article.""",
  """checklists.itemForm.deleteFailed""":
      """Impossible de supprimer l'article.""",
  """checklists.itemForm.deleteConfirm""": """Supprimer cet article ?""",
  """checklists.itemForm.save""": """Enregistrer""",
  """checklists.itemForm.descHint""":
      """Ajouter une description (facultatif)""",
  """checklists.itemForm.categoryChange""": """Changer""",
  """checklists.itemForm.categoryPick""": """Choisissez""",
  """checklists.itemForm.untitledItem""": """Article sans titre""",
  """checklists.itemForm.typeStaple""": """Article récurrent""",
  """checklists.itemForm.typeOnce""": """Article unique""",
  """checklists.itemForm.typeRecurring""": """Récurrent""",
  """checklists.sort.newestFirst""": """Plus récents""",
  """checklists.sort.oldestFirst""": """Plus anciens""",
  """checklists.sort.nameAZ""": """Nom A–Z""",
  """checklists.sort.nameZA""": """Nom Z–A""",
  """checklists.sort.category""": """Par catégorie""",
  """checklists.sort.store""": """Par magasin""",
  """checklists.sort.custom""": """Personnalisé""",
  """checklists.allDone""": """Tout est fait 🎉""",
  """checklists.hideProgressHero""": """Masquer la carte de progression""",
  """checklists.sortTooltip""": """Trier""",
  """checklists.uncheckAll""": """Tout décocher""",
  """checklists.uncheckAllConfirm""": """Décocher tous les articles ?""",
  """checklists.uncheckAllConfirmBody""":
      """Chaque article coché de cette liste sera renvoyé vers la liste active.""",
  """checklists.resetOrder.menuLabel""":
      """Réinitialiser l'ordre personnalisé…""",
  """checklists.resetOrder.pickTitle""":
      """Réinitialiser l'ordre personnalisé sur…""",
  """checklists.resetOrder.confirmTitle""":
      """Réinitialiser l'ordre personnalisé ?""",
  """checklists.resetOrder.confirmBody""":
      """Cela remplace l'ordre personnalisé actuel de cette liste. Vous pourrez réorganiser les articles ensuite.""",
  """checklists.resetOrder.action""": """Réinitialiser l'ordre""",
  """checklists.resetOrder.success""": """Ordre personnalisé réinitialisé""",
  """checklists.resetOrder.basisDateAdded""": """Date d'ajout""",
  """checklists.resetOrder.basisNameAsc""": """Nom A–Z""",
  """checklists.resetOrder.basisNameDesc""": """Nom Z–A""",
  """checklists.addFirstItem""": """Ajoutez votre premier article…""",
  """checklists.noItemsTitle""": """Rien dans cette liste pour le moment""",
  """checklists.noItemsBody""":
      """Ajoutez votre premier article avec la barre en bas — définissez une catégorie, une quantité ou un horaire avec les chips.""",
  """checklists.noListsTitle""": """Aucune liste pour le moment""",
  """checklists.noListsBody""":
      """Créez votre première liste pour commencer à suivre courses, courses à faire, tâches ou tout ce que votre foyer doit garder à l'œil.""",
  """checklists.createFirstList""": """Créer votre première liste""",
  """checklists.yourChecklists""": """Vos listes""",
  """checklists.allDoneSummary""": """Tout est fait · 0 restant""",
  """checklists.newChecklist""": """Nouvelle liste""",
  """checklists.createListButton""": """Créer la liste""",
  """checklists.view""": """Voir""",
  """checklists.swipeView""": """Voir""",
  """checklists.swipeEdit""": """Modifier""",
  """checklists.swipeMove""": """Déplacer""",
  """checklists.swipeCopy""": """Copier""",
  """checklists.swipeDelete""": """Retirer""",
  """checklists.swipeArchive""": """Archiver""",
  """checklists.moreActions""": """Plus d'actions""",
  """checklists.viewList""": """Vue liste""",
  """checklists.viewCards""": """Vue cartes""",
  """checklists.listColor""": """Couleur""",
  """checklists.itemTypes.label""": """Type d'article""",
  """checklists.itemTypes.staple""": """Habituel""",
  """checklists.itemTypes.stapleBody""":
      """Reste sur la liste après que vous l'avez complété""",
  """checklists.itemTypes.onceTime""": """Unique""",
  """checklists.itemTypes.onceTimeBody""":
      """Supprimé lorsque vous le complétez""",
  """checklists.itemTypes.recurring""": """Récurrent""",
  """checklists.itemTypes.recurringBody""": """Revient selon un horaire""",
  """checklists.itemTypes.weekly""": """Hebdomadaire""",
  """checklists.compose.chipCategory""": """Catégorie""",
  """checklists.compose.chipStore""": """Magasins""",
  """checklists.compose.chipQuantity""": """Quantité""",
  """checklists.compose.chipType""": """Type""",
  """checklists.compose.chipImage""": """Image""",
  """checklists.compose.chipDescription""": """Description""",
  """checklists.compose.descHint""": """Notes, instructions, liens…""",
  """checklists.compose.qtyHint""": """ex. 2 L, 500 g""",
  """checklists.compose.qtyStepperHelp""":
      """＋ / − changent le nombre et gardent l'unité.""",
  """checklists.compose.none""": """Aucune""",
  """checklists.compose.every""": """Toutes les""",
  """checklists.compose.week""": """semaine""",
  """checklists.compose.weeks""": """semaines""",
  """checklists.compose.chipTargetList""": """Liste""",
  """checklists.compose.pickTargetList""": """Choisir une liste""",
  """checklists.compose.multiple""": """Plusieurs""",
  """checklists.compose.multipleHint""":
      """Séparer les éléments par des retours à la ligne""",
  """checklists.price.label""": """Prix""",
  """checklists.price.set""": """Fixe""",
  """checklists.price.range""": """Plage""",
  """checklists.price.amount""": """Montant""",
  """checklists.price.min""": """Min""",
  """checklists.price.max""": """Max""",
  """checklists.price.currency""": """Devise""",
  """checklists.price.clear""": """Effacer le prix""",
  """checklists.reuse.dialogTitle""": """L'article existe déjà""",
  """checklists.reuse.reuseExisting""": """Réutiliser l'existant""",
  """checklists.reuse.addAnyway""": """Ajouter quand même""",
  """checklists.reuse.suggestionsHeader""": """Déjà dans cette liste""",
  """checklists.allLists""": """Toutes les listes""",
  """checklists.allListsSubtitle""": """Éléments de toutes les listes""",
  """checklists.addToAnyList""": """Ajouter un élément…""",
  """checklists.pickListTitle""": """Ajouter à quelle liste ?""",
  """checklists.markdown.uncategorized""": """Sans catégorie""",
  """checklists.markdown.exportTitle""": """Exporter en Markdown""",
  """checklists.markdown.importTitle""": """Importer depuis Markdown""",
  """checklists.markdown.includeCompleted""":
      """Inclure les éléments terminés""",
  """checklists.markdown.editHint""":
      """Modifiez le texte ci-dessous pour ajuster la liste exportée""",
  """checklists.markdown.copy""": """Copier""",
  """checklists.markdown.download""": """Télécharger le .md""",
  """checklists.markdown.copied""": """Copié dans le presse-papiers""",
  """checklists.markdown.copyFailed""":
      """Impossible de copier dans le presse-papiers""",
  """checklists.markdown.close""": """Fermer""",
  """checklists.markdown.shareFailed""": """Impossible d'exporter le fichier""",
  """checklists.markdown.uploadFile""": """Téléverser un fichier .md""",
  """checklists.markdown.pasteLabel""": """Coller du Markdown""",
  """checklists.markdown.pastePlaceholder""":
      """Collez une liste Markdown ici…""",
  """checklists.markdown.noneFound""":
      """Aucun élément de liste trouvé dans le texte.""",
  """checklists.markdown.selectAll""": """Tout sélectionner""",
  """checklists.markdown.deselectAll""": """Tout désélectionner""",
  """checklists.markdown.reuseExisting""":
      """Réutiliser les éléments existants au lieu d'ajouter des doublons""",
  """checklists.markdown.defaultFields""":
      """Valeurs appliquées à chaque élément importé""",
  """notesWall.noNotes""": """Aucune note pour le moment.""",
  """notesWall.failedToLoad""": """Impossible de charger les notes.""",
  """notesWall.saveFailed""": """Impossible d'enregistrer la note.""",
  """notesWall.deleteFailed""": """Impossible de supprimer la note.""",
  """notesWall.deleteConfirm""": """Supprimer cette note ?""",
  """notesWall.viewTrash""": """Voir la corbeille""",
  """notesWall.exitTrash""": """Quitter la corbeille""",
  """notesWall.trashTitle""": """Corbeille""",
  """notesWall.trashEmpty""": """La corbeille est vide.""",
  """notesWall.emptyTrash""": """Vider la corbeille""",
  """notesWall.emptyTrashConfirm""": """Vider la corbeille ?""",
  """notesWall.emptyTrashConfirmBody""":
      """Toutes les notes dans la corbeille seront supprimées définitivement. Cette action est irréversible.""",
  """notesWall.emptyTrashFailed""": """Impossible de vider la corbeille.""",
  """notesWall.failedToLoadTrash""": """Impossible de charger la corbeille.""",
  """notesWall.restore""": """Restaurer""",
  """notesWall.restoreFailed""": """Impossible de restaurer la note.""",
  """notesWall.permanentlyDelete""": """Supprimer définitivement""",
  """notesWall.permanentlyDeleteConfirm""":
      """Supprimer cette note définitivement ?""",
  """notesWall.permanentlyDeleteConfirmBody""":
      """Cette action est irréversible.""",
  """notesWall.newNote""": """Nouvelle note""",
  """notesWall.editNote""": """Modifier la note""",
  """notesWall.unsavedChanges""": """Modifications non enregistrées""",
  """notesWall.unsavedChangesBody""":
      """Vous avez des modifications non enregistrées. Voulez-vous les enregistrer ?""",
  """notesWall.discard""": """Abandonner""",
  """notesWall.keepEditing""": """Continuer la modification""",
  """notesWall.pinNote""": """Épingler la note""",
  """notesWall.unpinNote""": """Désépingler la note""",
  """notesWall.title""": """Titre""",
  """notesWall.content""": """Contenu""",
  """notesWall.color""": """Couleur""",
  """notesWall.sort.newestFirst""": """Plus récents""",
  """notesWall.sort.oldestFirst""": """Plus anciens""",
  """notesWall.sort.titleAZ""": """Titre A–Z""",
  """notesWall.sort.titleZA""": """Titre Z–A""",
  """notesWall.sort.custom""": """Personnalisé""",
  """photoBoard.noPhotos""": """Aucune photo pour le moment.""",
  """photoBoard.failedToLoad""": """Impossible de charger les photos.""",
  """photoBoard.uploadFailed""": """Impossible de télécharger la photo.""",
  """photoBoard.deleteFailed""": """Impossible de supprimer la photo.""",
  """photoBoard.deleteConfirm""": """Supprimer cette photo ?""",
  """photoBoard.viewTrash""": """Voir la corbeille""",
  """photoBoard.exitTrash""": """Quitter la corbeille""",
  """photoBoard.trashTitle""": """Corbeille""",
  """photoBoard.trashEmpty""": """La corbeille est vide.""",
  """photoBoard.emptyTrash""": """Vider la corbeille""",
  """photoBoard.emptyTrashConfirm""": """Vider la corbeille ?""",
  """photoBoard.emptyTrashConfirmBody""":
      """Toutes les photos dans la corbeille seront supprimées définitivement. Cette action est irréversible.""",
  """photoBoard.emptyTrashFailed""": """Impossible de vider la corbeille.""",
  """photoBoard.failedToLoadTrash""": """Impossible de charger la corbeille.""",
  """photoBoard.restore""": """Restaurer""",
  """photoBoard.restoreFailed""": """Impossible de restaurer la photo.""",
  """photoBoard.permanentlyDelete""": """Supprimer définitivement""",
  """photoBoard.permanentlyDeleteConfirm""":
      """Supprimer cette photo définitivement ?""",
  """photoBoard.permanentlyDeleteConfirmBody""":
      """Cette action est irréversible.""",
  """photoBoard.deleteFolder""": """Supprimer le dossier""",
  """photoBoard.deleteFolderConfirm""": """Supprimer ce dossier ?""",
  """photoBoard.deleteFolderKeepPhotos""":
      """Déplacer les photos à la racine""",
  """photoBoard.deleteFolderDeleteAll""":
      """Supprimer le dossier et les photos""",
  """photoBoard.newFolder""": """Nouveau dossier""",
  """photoBoard.folderName""": """Nom du dossier""",
  """photoBoard.renameFolder""": """Renommer le dossier""",
  """photoBoard.caption""": """Légende""",
  """photoBoard.addMenu.upload""": """Téléverser des photos""",
  """photoBoard.addMenu.camera""": """Prendre une photo""",
  """photoBoard.addMenu.newFolder""": """Nouveau dossier""",
  """photoBoard.sort.foldersFirst""": """Dossiers en premier""",
  """photoBoard.sort.newestFirst""": """Plus récents""",
  """photoBoard.sort.oldestFirst""": """Plus anciens""",
  """photoBoard.sort.captionAZ""": """Légende A–Z""",
  """photoBoard.sort.captionZA""": """Légende Z–A""",
  """photoBoard.sort.custom""": """Personnalisé""",
  """shopping.startShopping""": """Commencer les courses""",
  """shopping.resumeShopping""": """Reprendre les courses""",
  """shopping.shoppingHistory""": """Historique des courses""",
  """shopping.resume""": """Reprendre""",
  """shopping.bannerShoppingNow""": """Courses en cours""",
  """shopping.startTitle""": """Commencer les courses""",
  """shopping.listsToShop""": """Listes à faire""",
  """shopping.selectAll""": """Tout sélectionner""",
  """shopping.selectNone""": """Ne rien sélectionner""",
  """shopping.noListsToShop""": """Aucune liste à faire pour l'instant.""",
  """shopping.storesTitle""": """Magasins""",
  """shopping.storesHint""":
      """Activez ou désactivez les magasins que vous visiterez, et glissez pour définir l'ordre.""",
  """shopping.noStoresWithItems""":
      """Aucune des listes sélectionnées n'a d'articles assignés à un magasin.""",
  """shopping.includeUnassigned""": """Inclure les articles sans magasin""",
  """shopping.start""": """Commencer""",
  """shopping.startFailed""": """Impossible de commencer les courses.""",
  """shopping.tripInProgress""": """Vous avez déjà des courses en cours.""",
  """shopping.endPreviousTrip""": """Terminer les courses précédentes""",
  """shopping.endPreviousFailed""":
      """Impossible de terminer les courses précédentes.""",
  """shopping.makePrivate""": """Masquer les courses aux colocataires""",
  """shopping.makePublic""": """Montrer les courses aux colocataires""",
  """shopping.privateBadge""": """Privé""",
  """shopping.nextStore""": """Magasin suivant""",
  """shopping.finish""": """Terminer""",
  """shopping.finishTrip""": """Terminer les courses""",
  """shopping.allCheckedHere""": """Tout est coché ici""",
  """shopping.moveOnToNext""": """Passez au magasin suivant.""",
  """shopping.allDone""": """Tout est fait""",
  """shopping.everythingInCart""": """Tout est dans le panier.""",
  """shopping.nothingToBuyHere""": """Rien à acheter ici.""",
  """shopping.checkFailed""": """Impossible de mettre à jour l'article.""",
  """shopping.loadItemsFailed""": """Impossible de charger les articles.""",
  """shopping.removeFromTrip""": """Retirer de la sortie""",
  """shopping.removedFromTrip""": """Retiré de cette sortie""",
  """shopping.undo""": """Annuler""",
  """shopping.undoRemoveFailed""": """Impossible d'annuler.""",
  """shopping.reviewTitle""": """Récapitulatif""",
  """shopping.advanceTitle""": """Magasin suivant""",
  """shopping.actualPaid""": """Payé réel""",
  """shopping.grandTotal""": """Total général""",
  """shopping.anyStore""": """N'importe quel magasin""",
  """shopping.saveTotalFailed""": """Impossible d'enregistrer le total.""",
  """shopping.remindersTitle""": """Rappels""",
  """shopping.manageReminders""": """Gérer les rappels""",
  """shopping.reminderGroupStart""": """Au début""",
  """shopping.reminderGroupAdvance""": """Entre les magasins""",
  """shopping.reminderGroupEnd""": """À la fin""",
  """shopping.noRemindersHere""": """Aucun rappel ici pour l'instant.""",
  """shopping.noRemindersStep""":
      """Aucun rappel pour cette étape pour l'instant.""",
  """shopping.addReminders""": """Ajouter des rappels""",
  """shopping.addReminderHint""": """Ajouter un rappel""",
  """shopping.reminderWhen""": """Quand l'afficher""",
  """shopping.whenOnStart""": """Au début""",
  """shopping.whenOnStoreAdvance""": """Entre les magasins""",
  """shopping.whenOnClose""": """À la fin""",
  """shopping.add""": """Ajouter""",
  """shopping.reminderSaveFailed""": """Impossible d'enregistrer le rappel.""",
  """shopping.reminderDeleteFailed""": """Impossible de supprimer le rappel.""",
  """shopping.historyTitle""": """Historique des courses""",
  """shopping.scopeMine""": """Les miennes""",
  """shopping.scopeHouse""": """Maison""",
  """shopping.noStorePath""": """Aucun magasin""",
  """shopping.loadMore""": """Charger plus""",
  """shopping.noTripsYet""": """Aucune course pour l'instant.""",
  """shopping.noHouseTripsYet""":
      """Aucune course dans cette maison pour l'instant.""",
  """shopping.loadHistoryFailed""": """Impossible de charger l'historique.""",
  """shopping.loadFailed""":
      """Une erreur s'est produite. Veuillez réessayer.""",
  """shopping.uncategorized""": """Sans catégorie""",
  """share.title""": """Partager vers Pantry""",
  """share.chooseHouse""": """Choisir une maison""",
  """share.choosePhotoDestination""": """Téléverser vers""",
  """share.photoBoardRoot""": """Tableau photos""",
  """share.newFolder""": """Nouveau dossier""",
  """share.newFolderName""": """Nom du dossier""",
  """share.failedToCreateFolder""": """Impossible de créer le dossier.""",
  """share.failedToOpenShare""": """Impossible d'ouvrir le contenu partagé.""",
  """share.noHouses""":
      """Aucune maison disponible. Créez d'abord une maison.""",
  """recurrence.title""": """Récurrence""",
  """recurrence.presets""": """Préréglages""",
  """recurrence.daily""": """Quotidien""",
  """recurrence.weekly""": """Hebdomadaire""",
  """recurrence.monthly""": """Mensuel""",
  """recurrence.everyLabel""": """Tous les""",
  """recurrence.unit""": """Unité""",
  """recurrence.unitDays""": """jours""",
  """recurrence.unitWeeks""": """semaines""",
  """recurrence.unitMonths""": """mois""",
  """recurrence.unitYears""": """années""",
  """recurrence.repeatOn""": """Répéter le""",
  """recurrence.ends""": """Se termine""",
  """recurrence.never""": """Jamais""",
  """recurrence.after""": """Après""",
  """recurrence.occurrences""": """répétitions""",
  """recurrence.onDate""": """À la date""",
  """recurrence.countFromCompletion""":
      """Compter l'intervalle à partir du moment où l'article est coché""",
  """recurrence.countFromCompletionHintOff""":
      """Le calendrier est fixe : l'article réapparaît à sa prochaine occurrence prévue, peu importe quand vous le cochez.""",
  """recurrence.countFromCompletionHintOn""":
      """La prochaine occurrence est comptée à partir du moment où vous cochez l'article, de sorte qu'il revient toujours un intervalle complet après son achèvement.""",
  """recurrence.summary""": """Résumé""",
  """recurrence.notSet""": """non défini""",
  """recurrence.set""": """défini""",
  """recurrence.dayNames.monday""": """Lundi""",
  """recurrence.dayNames.tuesday""": """Mardi""",
  """recurrence.dayNames.wednesday""": """Mercredi""",
  """recurrence.dayNames.thursday""": """Jeudi""",
  """recurrence.dayNames.friday""": """Vendredi""",
  """recurrence.dayNames.saturday""": """Samedi""",
  """recurrence.dayNames.sunday""": """Dimanche""",
  """recurrence.dayAbbr.mo""": """Lu""",
  """recurrence.dayAbbr.tu""": """Ma""",
  """recurrence.dayAbbr.we""": """Me""",
  """recurrence.dayAbbr.th""": """Je""",
  """recurrence.dayAbbr.fr""": """Ve""",
  """recurrence.dayAbbr.sa""": """Sa""",
  """recurrence.dayAbbr.su""": """Di""",
  """sync.offline""": """Hors ligne""",
  """sync.syncing""": """Synchronisation des modifications…""",
  """sync.syncError""": """Impossible de synchroniser les modifications""",
  """sync.retry""": """Réessayer""",
  """markdownEditor.editSource""": """Markdown""",
  """markdownEditor.editRich""": """Texte enrichi""",
};
