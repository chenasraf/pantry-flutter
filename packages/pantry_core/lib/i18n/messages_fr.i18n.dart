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
  WidgetMessagesFr get widget => WidgetMessagesFr(this);
  OnboardingMessagesFr get onboarding => OnboardingMessagesFr(this);
  NotificationsIntroMessagesFr get notificationsIntro =>
      NotificationsIntroMessagesFr(this);
  AboutMessagesFr get about => AboutMessagesFr(this);
  SettingsMessagesFr get settings => SettingsMessagesFr(this);
  NotificationsMessagesFr get notifications => NotificationsMessagesFr(this);
  CategoriesMessagesFr get categories => CategoriesMessagesFr(this);
  CustomFieldsMessagesFr get customFields => CustomFieldsMessagesFr(this);
  StoresMessagesFr get stores => StoresMessagesFr(this);
  LabelsMessagesFr get labels => LabelsMessagesFr(this);
  ChecklistsMessagesFr get checklists => ChecklistsMessagesFr(this);
  ListKindsMessagesFr get listKinds => ListKindsMessagesFr(this);
  TemplatesMessagesFr get templates => TemplatesMessagesFr(this);
  StockMessagesFr get stock => StockMessagesFr(this);
  NotesWallMessagesFr get notesWall => NotesWallMessagesFr(this);
  PhotoBoardMessagesFr get photoBoard => PhotoBoardMessagesFr(this);
  ShoppingMessagesFr get shopping => ShoppingMessagesFr(this);
  ShareMessagesFr get share => ShareMessagesFr(this);
  RecurrenceMessagesFr get recurrence => RecurrenceMessagesFr(this);
  SyncMessagesFr get sync => SyncMessagesFr(this);
  MarkdownEditorMessagesFr get markdownEditor => MarkdownEditorMessagesFr(this);
  WearMessagesFr get wear => WearMessagesFr(this);
  WatchMessagesFr get watch => WatchMessagesFr(this);
  WatchTipsMessagesFr get watchTips => WatchTipsMessagesFr(this);
}

class CommonMessagesFr extends CommonMessages {
  final MessagesFr _parent;
  const CommonMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "Ajouter"
  /// ```
  String get add => """Ajouter""";

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
  /// "Masquer"
  /// ```
  String get dismiss => """Masquer""";

  /// ```dart
  /// "Retirer"
  /// ```
  String get remove => """Retirer""";

  /// ```dart
  /// "Effacer"
  /// ```
  String get clear => """Effacer""";

  /// ```dart
  /// "Plus"
  /// ```
  String get more => """Plus""";

  /// ```dart
  /// "Trier"
  /// ```
  String get sort => """Trier""";

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

  /// ```dart
  /// "Connexion expirée"
  /// ```
  String get sessionExpiredTitle => """Connexion expirée""";

  /// ```dart
  /// "Le serveur n'accepte plus votre connexion. Vos données sont toujours là, et toute modification attendra que vous vous reconnectiez."
  /// ```
  String get sessionExpiredBody =>
      """Le serveur n'accepte plus votre connexion. Vos données sont toujours là, et toute modification attendra que vous vous reconnectiez.""";

  /// ```dart
  /// "Se reconnecter"
  /// ```
  String get signInAgain => """Se reconnecter""";

  /// ```dart
  /// "L'adresse du serveur a changé"
  /// ```
  String get serverMovedTitle => """L'adresse du serveur a changé""";

  /// ```dart
  /// "Votre serveur répond désormais à ${address}. Vos modifications attendent ici jusqu'à ce que l'app utilise la nouvelle adresse."
  /// ```
  String serverMovedBody(String address) =>
      """Votre serveur répond désormais à ${address}. Vos modifications attendent ici jusqu'à ce que l'app utilise la nouvelle adresse.""";

  /// ```dart
  /// "Votre serveur redirige les modifications vers une autre adresse, elles ne peuvent donc pas être enregistrées. Elles attendent ici jusqu'à ce que vous vous reconnectiez avec l'adresse actuelle du serveur."
  /// ```
  String get serverMovedUnknownBody =>
      """Votre serveur redirige les modifications vers une autre adresse, elles ne peuvent donc pas être enregistrées. Elles attendent ici jusqu'à ce que vous vous reconnectiez avec l'adresse actuelle du serveur.""";

  /// ```dart
  /// "Utiliser la nouvelle adresse"
  /// ```
  String get useNewAddress => """Utiliser la nouvelle adresse""";
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
  /// "Liste"
  /// ```
  String get checklist => """Liste""";

  /// ```dart
  /// "Listes"
  /// ```
  String get lists => """Listes""";

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";

  /// ```dart
  /// "Tableau photos"
  /// ```
  String get photoBoard => """Tableau photos""";

  /// ```dart
  /// "Mur de notes"
  /// ```
  String get notesWall => """Mur de notes""";
}

class WidgetMessagesFr extends WidgetMessages {
  final MessagesFr _parent;
  const WidgetMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Choisir les listes"
  /// ```
  String get chooseListsTitle => """Choisir les listes""";

  /// ```dart
  /// "Choisis les listes affichées par ce widget."
  /// ```
  String get chooseListsSubtitle =>
      """Choisis les listes affichées par ce widget.""";

  /// ```dart
  /// "Choisir une liste"
  /// ```
  String get chooseListTitle => """Choisir une liste""";

  /// ```dart
  /// "Choisis la liste affichée par ce widget."
  /// ```
  String get chooseListSubtitle =>
      """Choisis la liste affichée par ce widget.""";

  /// ```dart
  /// "Aucune liste disponible."
  /// ```
  String get noLists => """Aucune liste disponible.""";

  /// ```dart
  /// "Masquer les cases à cocher"
  /// ```
  String get hideCheckbox => """Masquer les cases à cocher""";

  /// ```dart
  /// "Touche un élément pour le cocher. Touche l'emplacement de la case pour ouvrir l'élément."
  /// ```
  String get hideCheckboxBody =>
      """Touche un élément pour le cocher. Touche l'emplacement de la case pour ouvrir l'élément.""";
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
  /// "Touche le champ en bas pour saisir un nouvel élément, puis associe-lui une catégorie, une quantité, une récurrence ou une photo via les chips au-dessus."
  /// ```
  String get addItemsBody =>
      """Touche le champ en bas pour saisir un nouvel élément, puis associe-lui une catégorie, une quantité, une récurrence ou une photo via les chips au-dessus.""";

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
  /// "Choisis les listes de ton widget"
  /// ```
  String get widgetListsTitle => """Choisis les listes de ton widget""";

  /// ```dart
  /// "Ajoute le widget Pantry à ton écran d'accueil pour voir d'un coup d'œil combien d'articles restent sur chaque liste — sans ouvrir l'app."
  /// ```
  String get widgetListsBody =>
      """Ajoute le widget Pantry à ton écran d'accueil pour voir d'un coup d'œil combien d'articles restent sur chaque liste — sans ouvrir l'app.""";

  /// ```dart
  /// "En ajoutant un widget, tu choisis ses listes tout de suite. Touche ${action} sur un widget pour les changer plus tard, et ajoute autant de widgets que tu veux — chacun avec ses propres listes."
  /// ```
  String widgetListsHow(String action) =>
      """En ajoutant un widget, tu choisis ses listes tout de suite. Touche ${action} sur un widget pour les changer plus tard, et ajoute autant de widgets que tu veux — chacun avec ses propres listes.""";

  /// ```dart
  /// "Choisir les listes"
  /// ```
  String get widgetListsActionLabel => """Choisir les listes""";

  /// ```dart
  /// "Pantry"
  /// ```
  String get widgetListsWidgetTitle => """Pantry""";

  /// ```dart
  /// "${_plural(count, one: '1 restant', many: '${count} restants')}"
  /// ```
  String widgetListsWidgetItemsLeft(int count) =>
      """${_plural(count, one: '1 restant', many: '${count} restants')}""";

  /// ```dart
  /// "Tout est fait"
  /// ```
  String get widgetListsWidgetEmpty => """Tout est fait""";

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
  /// "Des catégories par liste"
  /// ```
  String get categoryScopeTitle => """Des catégories par liste""";

  /// ```dart
  /// "Gardez une catégorie sur une seule liste, ou rendez-la globale pour qu'elle apparaisse sur toutes les listes. Les nouvelles catégories restent globales sauf si vous choisissez une liste."
  /// ```
  String get categoryScopeBody =>
      """Gardez une catégorie sur une seule liste, ou rendez-la globale pour qu'elle apparaisse sur toutes les listes. Les nouvelles catégories restent globales sauf si vous choisissez une liste.""";

  /// ```dart
  /// "Apparaît sur toutes les listes"
  /// ```
  String get categoryScopeGlobalCaption => """Apparaît sur toutes les listes""";

  /// ```dart
  /// "Apparaît sur cette liste uniquement"
  /// ```
  String get categoryScopeScopedCaption =>
      """Apparaît sur cette liste uniquement""";

  /// ```dart
  /// "Vos propres champs"
  /// ```
  String get customFieldsTitle => """Vos propres champs""";

  /// ```dart
  /// "Notez les détails qui comptent pour vous : une date de péremption, un rayon, une taille. Créez un champ une fois pour toute la maison ou pour une seule liste, et il apparaît sur chaque article."
  /// ```
  String get customFieldsBody =>
      """Notez les détails qui comptent pour vous : une date de péremption, un rayon, une taille. Créez un champ une fois pour toute la maison ou pour une seule liste, et il apparaît sur chaque article.""";

  /// ```dart
  /// "Péremption"
  /// ```
  String get customFieldsMockExpiry => """Péremption""";

  /// ```dart
  /// "12 sept."
  /// ```
  String get customFieldsMockExpiryValue => """12 sept.""";

  /// ```dart
  /// "Rayon"
  /// ```
  String get customFieldsMockAisle => """Rayon""";

  /// ```dart
  /// "Produits laitiers"
  /// ```
  String get customFieldsMockAisleValue => """Produits laitiers""";

  /// ```dart
  /// "Choisissez le type qui correspond à ce que vous notez."
  /// ```
  String get customFieldsTypesCaption =>
      """Choisissez le type qui correspond à ce que vous notez.""";

  /// ```dart
  /// "* Nécessite Pantry pour Nextcloud v${version}+"
  /// ```
  String serverRequirementNote(String version) =>
      """* Nécessite Pantry pour Nextcloud v${version}+""";

  /// ```dart
  /// "Pantry à votre poignet"
  /// ```
  String get watchTitle => """Pantry à votre poignet""";

  /// ```dart
  /// "Il existe une app Wear OS. Vos listes, vos notes et le tableau photo sur la montre, sans le moindre réseau — et des courses que vous pouvez faire avec le téléphone dans la poche."
  /// ```
  String get watchBody =>
      """Il existe une app Wear OS. Vos listes, vos notes et le tableau photo sur la montre, sans le moindre réseau — et des courses que vous pouvez faire avec le téléphone dans la poche.""";

  /// ```dart
  /// "Ouvrez Pantry sur votre montre et elle se connecte depuis ce téléphone. Les astuces pour l'utiliser sont dans ${settings} → ${watch}."
  /// ```
  String watchHowTo(String settings, String watch) =>
      """Ouvrez Pantry sur votre montre et elle se connecte depuis ce téléphone. Les astuces pour l'utiliser sont dans ${settings} → ${watch}.""";

  /// ```dart
  /// "Faites les courses ensemble"
  /// ```
  String get joinTripTitle => """Faites les courses ensemble""";

  /// ```dart
  /// "Quand quelqu'un de votre foyer est en train de faire les courses, une bannière vous propose ses courses plutôt qu'une seconde liste à vous. Vous les faites ensemble : ce que l'un coche disparaît pour l'autre."
  /// ```
  String get joinTripBody =>
      """Quand quelqu'un de votre foyer est en train de faire les courses, une bannière vous propose ses courses plutôt qu'une seconde liste à vous. Vous les faites ensemble : ce que l'un coche disparaît pour l'autre.""";

  /// ```dart
  /// "Dana"
  /// ```
  String get joinTripMockHousemate => """Dana""";

  /// ```dart
  /// "Déjà en courses ? Rejoindre enregistre d'abord les vôtres dans votre historique. Si vous quittez des courses que vous avez rejointes, elles continuent pour ceux qui y restent."
  /// ```
  String get joinTripHow =>
      """Déjà en courses ? Rejoindre enregistre d'abord les vôtres dans votre historique. Si vous quittez des courses que vous avez rejointes, elles continuent pour ceux qui y restent.""";
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
  /// "Langue, thème et couleurs"
  /// ```
  String get generalSectionBody => """Langue, thème et couleurs""";

  /// ```dart
  /// "Interface"
  /// ```
  String get interfaceSection => """Interface""";

  /// ```dart
  /// "Navigation, listes et actions sur les éléments"
  /// ```
  String get interfaceSectionBody =>
      """Navigation, listes et actions sur les éléments""";

  /// ```dart
  /// "Navigation"
  /// ```
  String get interfaceNavigationSection => """Navigation""";

  /// ```dart
  /// "Listes"
  /// ```
  String get interfaceListsSection => """Listes""";

  /// ```dart
  /// "Actions sur les éléments"
  /// ```
  String get interfaceItemActionsSection => """Actions sur les éléments""";

  /// ```dart
  /// "Ajout d'éléments"
  /// ```
  String get interfaceAddingSection => """Ajout d'éléments""";

  /// ```dart
  /// "Lecture de codes-barres"
  /// ```
  String get interfaceBarcodeSection => """Lecture de codes-barres""";

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
  /// "Position de la barre d'ajout"
  /// ```
  String get composeBarPosition => """Position de la barre d'ajout""";

  /// ```dart
  /// "Sur quel bord de la liste se place la barre d'ajout d'articles."
  /// ```
  String get composeBarPositionBody =>
      """Sur quel bord de la liste se place la barre d'ajout d'articles.""";
  ComposeBarPositionNamesSettingsMessagesFr get composeBarPositionNames =>
      ComposeBarPositionNamesSettingsMessagesFr(this);

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
  /// "Bouton « Commencer les courses »"
  /// ```
  String get startShoppingButton => """Bouton « Commencer les courses »""";

  /// ```dart
  /// "Affiche le bouton flottant « Commencer les courses » sur l'écran des listes. Désactivé, il passe dans le menu."
  /// ```
  String get startShoppingButtonBody =>
      """Affiche le bouton flottant « Commencer les courses » sur l'écran des listes. Désactivé, il passe dans le menu.""";

  /// ```dart
  /// "Style du menu de liste"
  /// ```
  String get listMenuStyle => """Style du menu de liste""";

  /// ```dart
  /// "Comment le menu de liste présente ses actions : une grille de catégories, ou une seule liste avec toutes les actions."
  /// ```
  String get listMenuStyleBody =>
      """Comment le menu de liste présente ses actions : une grille de catégories, ou une seule liste avec toutes les actions.""";
  ListMenuStyleNamesSettingsMessagesFr get listMenuStyleNames =>
      ListMenuStyleNamesSettingsMessagesFr(this);

  /// ```dart
  /// "Tronquer les noms d'articles longs"
  /// ```
  String get truncateItemNames => """Tronquer les noms d'articles longs""";

  /// ```dart
  /// "Garde chaque nom d'article sur une seule ligne, se terminant par des points de suspension. Désactivé, les noms longs passent sur plusieurs lignes."
  /// ```
  String get truncateItemNamesBody =>
      """Garde chaque nom d'article sur une seule ligne, se terminant par des points de suspension. Désactivé, les noms longs passent sur plusieurs lignes.""";

  /// ```dart
  /// "Description sur les articles"
  /// ```
  String get itemDescription => """Description sur les articles""";

  /// ```dart
  /// "Où la description d'un article apparaît sur sa ligne. Une description trop longue se termine par des points de suspension dans les deux cas."
  /// ```
  String get itemDescriptionBody =>
      """Où la description d'un article apparaît sur sa ligne. Une description trop longue se termine par des points de suspension dans les deux cas.""";
  ItemDescriptionNamesSettingsMessagesFr get itemDescriptionNames =>
      ItemDescriptionNamesSettingsMessagesFr(this);

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
  /// "Suggérer les articles archivés"
  /// ```
  String get suggestArchivedItems => """Suggérer les articles archivés""";

  /// ```dart
  /// "Lors de l'ajout d'un article, rechercher aussi des suggestions de réutilisation parmi les articles archivés. Réutiliser un article archivé le désarchive."
  /// ```
  String get suggestArchivedItemsBody =>
      """Lors de l'ajout d'un article, rechercher aussi des suggestions de réutilisation parmi les articles archivés. Réutiliser un article archivé le désarchive.""";

  /// ```dart
  /// "Remplir le nom"
  /// ```
  String get barcodeFillName => """Remplir le nom""";

  /// ```dart
  /// "Utiliser le nom du produit d'un code-barres scanné comme nom de l'article."
  /// ```
  String get barcodeFillNameBody =>
      """Utiliser le nom du produit d'un code-barres scanné comme nom de l'article.""";

  /// ```dart
  /// "Remplir la catégorie"
  /// ```
  String get barcodeFillCategory => """Remplir la catégorie""";

  /// ```dart
  /// "Choisir la catégorie la plus proche pour un produit scanné."
  /// ```
  String get barcodeFillCategoryBody =>
      """Choisir la catégorie la plus proche pour un produit scanné.""";

  /// ```dart
  /// "Remplir l'image"
  /// ```
  String get barcodeFillImage => """Remplir l'image""";

  /// ```dart
  /// "Joindre à l'article la photo du produit d'un code-barres scanné."
  /// ```
  String get barcodeFillImageBody =>
      """Joindre à l'article la photo du produit d'un code-barres scanné.""";

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
  /// "Synchroniser la maison ouverte"
  /// ```
  String get syncLastHouse => """Synchroniser la maison ouverte""";

  /// ```dart
  /// "Ouvre la maison que vous avez utilisée en dernier sur n'importe quel appareil, et laisse l'application web et vos autres appareils suivre celui-ci. Désactivez pour garder ici une maison qui vous est propre."
  /// ```
  String get syncLastHouseBody =>
      """Ouvre la maison que vous avez utilisée en dernier sur n'importe quel appareil, et laisse l'application web et vos autres appareils suivre celui-ci. Désactivez pour garder ici une maison qui vous est propre.""";

  /// ```dart
  /// "Notifications"
  /// ```
  String get notificationsSection => """Notifications""";

  /// ```dart
  /// "Alertes et fréquence de vérification de l'activité"
  /// ```
  String get notificationsSectionBody =>
      """Alertes et fréquence de vérification de l'activité""";

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
  /// "Distribution"
  /// ```
  String get delivery => """Distribution""";

  /// ```dart
  /// "Vérifications périodiques"
  /// ```
  String get deliveryPolling => """Vérifications périodiques""";

  /// ```dart
  /// "UnifiedPush"
  /// ```
  String get deliveryUnifiedPush => """UnifiedPush""";

  /// ```dart
  /// "Pantry vérifie régulièrement la nouvelle activité sur votre serveur."
  /// ```
  String get deliveryPollingBody =>
      """Pantry vérifie régulièrement la nouvelle activité sur votre serveur.""";

  /// ```dart
  /// "Connexion via ${distributor}…"
  /// ```
  String deliveryConnecting(String distributor) =>
      """Connexion via ${distributor}…""";

  /// ```dart
  /// "Les notifications arrivent instantanément via ${distributor}."
  /// ```
  String deliveryActive(String distributor) =>
      """Les notifications arrivent instantanément via ${distributor}.""";

  /// ```dart
  /// "Aucun distributeur UnifiedPush n'est disponible. Pantry vérifie régulièrement en attendant qu'un distributeur soit configuré."
  /// ```
  String get deliveryNoDistributor =>
      """Aucun distributeur UnifiedPush n'est disponible. Pantry vérifie régulièrement en attendant qu'un distributeur soit configuré.""";

  /// ```dart
  /// "Votre serveur n'accepte pas le web push. Pantry vérifie régulièrement à la place."
  /// ```
  String get deliveryServerUnsupported =>
      """Votre serveur n'accepte pas le web push. Pantry vérifie régulièrement à la place.""";

  /// ```dart
  /// "Impossible de s'abonner aux notifications push. Pantry vérifie régulièrement à la place."
  /// ```
  String get deliveryFailed =>
      """Impossible de s'abonner aux notifications push. Pantry vérifie régulièrement à la place.""";

  /// ```dart
  /// "Installez un distributeur"
  /// ```
  String get noDistributorTitle => """Installez un distributeur""";

  /// ```dart
  /// "UnifiedPush distribue les notifications via une application distributrice distincte, comme ntfy, NextPush ou Sunup. Installez-en une, puis choisissez à nouveau UnifiedPush."
  /// ```
  String get noDistributorBody =>
      """UnifiedPush distribue les notifications via une application distributrice distincte, comme ntfy, NextPush ou Sunup. Installez-en une, puis choisissez à nouveau UnifiedPush.""";

  /// ```dart
  /// "Choisissez un distributeur"
  /// ```
  String get chooseDistributor => """Choisissez un distributeur""";

  /// ```dart
  /// "En savoir plus"
  /// ```
  String get learnMore => """En savoir plus""";

  /// ```dart
  /// "Votre serveur n'accepte pas le web push. Il faut Nextcloud 34 ou plus récent, avec le web push autorisé dans Paramètres d'administration → Notifications."
  /// ```
  String get serverNoWebPush =>
      """Votre serveur n'accepte pas le web push. Il faut Nextcloud 34 ou plus récent, avec le web push autorisé dans Paramètres d'administration → Notifications.""";

  /// ```dart
  /// "Cela prend plus de temps que d'habitude. Vérifiez que ${distributor} est lancé et connecté à son serveur."
  /// ```
  String connectingSlow(String distributor) =>
      """Cela prend plus de temps que d'habitude. Vérifiez que ${distributor} est lancé et connecté à son serveur.""";

  /// ```dart
  /// "Les notifications instantanées sont activées."
  /// ```
  String get deliveryEnabled =>
      """Les notifications instantanées sont activées.""";

  /// ```dart
  /// "Configurer UnifiedPush"
  /// ```
  String get pushSetup => """Configurer UnifiedPush""";

  /// ```dart
  /// "Ce dont les notifications instantanées ont besoin"
  /// ```
  String get pushSetupSubtitle =>
      """Ce dont les notifications instantanées ont besoin""";

  /// ```dart
  /// "Installez une application distributrice UnifiedPush, comme ntfy, NextPush ou Sunup."
  /// ```
  String get pushSetupStep1 =>
      """Installez une application distributrice UnifiedPush, comme ntfy, NextPush ou Sunup.""";

  /// ```dart
  /// "Votre serveur doit utiliser Nextcloud 34 ou plus récent, avec le web push autorisé par un administrateur dans Paramètres d'administration → Notifications."
  /// ```
  String get pushSetupStep2 =>
      """Votre serveur doit utiliser Nextcloud 34 ou plus récent, avec le web push autorisé par un administrateur dans Paramètres d'administration → Notifications.""";

  /// ```dart
  /// "Choisissez UnifiedPush sous Distribution, puis votre distributeur."
  /// ```
  String get pushSetupStep3 =>
      """Choisissez UnifiedPush sous Distribution, puis votre distributeur.""";

  /// ```dart
  /// "Pantry continue de vérifier selon le planning jusqu'à ce que votre serveur confirme l'abonnement."
  /// ```
  String get pushSetupNote =>
      """Pantry continue de vérifier selon le planning jusqu'à ce que votre serveur confirme l'abonnement.""";

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
  /// "À quelle fréquence chaque écran vérifie les changements"
  /// ```
  String get refreshSectionSubtitle =>
      """À quelle fréquence chaque écran vérifie les changements""";

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

  /// ```dart
  /// "Montre"
  /// ```
  String get watchSection => """Montre""";

  /// ```dart
  /// "Associer une montre Wear OS et la connecter"
  /// ```
  String get watchSubtitle => """Associer une montre Wear OS et la connecter""";
  DiagnosticsSettingsMessagesFr get diagnostics =>
      DiagnosticsSettingsMessagesFr(this);
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

class ComposeBarPositionNamesSettingsMessagesFr
    extends ComposeBarPositionNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ComposeBarPositionNamesSettingsMessagesFr(this._parent)
    : super(_parent);

  /// ```dart
  /// "Bas"
  /// ```
  String get bottom => """Bas""";

  /// ```dart
  /// "Haut"
  /// ```
  String get top => """Haut""";
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

class ListMenuStyleNamesSettingsMessagesFr
    extends ListMenuStyleNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ListMenuStyleNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Grille"
  /// ```
  String get grid => """Grille""";

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";
}

class ItemDescriptionNamesSettingsMessagesFr
    extends ItemDescriptionNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const ItemDescriptionNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Icône de note seule"
  /// ```
  String get off => """Icône de note seule""";

  /// ```dart
  /// "Sur sa propre ligne"
  /// ```
  String get line => """Sur sa propre ligne""";

  /// ```dart
  /// "Dans l'étiquette de note"
  /// ```
  String get chip => """Dans l'étiquette de note""";
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
  /// "Étiquette"
  /// ```
  String get label => """Étiquette""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get quantity => """Quantité""";

  /// ```dart
  /// "Prix"
  /// ```
  String get price => """Prix""";

  /// ```dart
  /// "Description"
  /// ```
  String get note => """Description""";

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

class DiagnosticsSettingsMessagesFr extends DiagnosticsSettingsMessages {
  final SettingsMessagesFr _parent;
  const DiagnosticsSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Journaux de diagnostic"
  /// ```
  String get title => """Journaux de diagnostic""";

  /// ```dart
  /// "Consulter et partager un journal anonymisé pour signaler un bug"
  /// ```
  String get subtitle =>
      """Consulter et partager un journal anonymisé pour signaler un bug""";

  /// ```dart
  /// "Pantry conserve sur cet appareil un court journal de ses requêtes, synchronisations et erreurs. Les adresses du serveur, noms d'utilisateur, mots de passe et jetons sont masqués, et le contenu de vos listes, articles et notes n'est jamais enregistré. Partagez-le lorsque vous signalez un problème."
  /// ```
  String get body =>
      """Pantry conserve sur cet appareil un court journal de ses requêtes, synchronisations et erreurs. Les adresses du serveur, noms d'utilisateur, mots de passe et jetons sont masqués, et le contenu de vos listes, articles et notes n'est jamais enregistré. Partagez-le lorsque vous signalez un problème.""";

  /// ```dart
  /// "Cet appareil"
  /// ```
  String get thisDevice => """Cet appareil""";

  /// ```dart
  /// "Montre"
  /// ```
  String get watch => """Montre""";

  /// ```dart
  /// "Problèmes uniquement"
  /// ```
  String get problemsOnly => """Problèmes uniquement""";

  /// ```dart
  /// "Rien n'a encore été enregistré"
  /// ```
  String get empty => """Rien n'a encore été enregistré""";

  /// ```dart
  /// "Journal copié"
  /// ```
  String get copied => """Journal copié""";

  /// ```dart
  /// "Partager"
  /// ```
  String get share => """Partager""";

  /// ```dart
  /// "Impossible de partager le journal"
  /// ```
  String get shareFailed => """Impossible de partager le journal""";

  /// ```dart
  /// "Effacer le journal ?"
  /// ```
  String get clearTitle => """Effacer le journal ?""";

  /// ```dart
  /// "Cela supprime tout ce qui a été enregistré sur cet appareil jusqu'à présent."
  /// ```
  String get clearBody =>
      """Cela supprime tout ce qui a été enregistré sur cet appareil jusqu'à présent.""";

  /// ```dart
  /// "Interrogation de votre montre…"
  /// ```
  String get watchLoading => """Interrogation de votre montre…""";

  /// ```dart
  /// "Impossible de joindre votre montre. Ouvrez Pantry sur la montre et réessayez."
  /// ```
  String get watchUnavailable =>
      """Impossible de joindre votre montre. Ouvrez Pantry sur la montre et réessayez.""";
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

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";

  /// ```dart
  /// "Toutes les listes (global)"
  /// ```
  String get globalList => """Toutes les listes (global)""";
  SortCategoriesMessagesFr get sort => SortCategoriesMessagesFr(this);
  StoreOrderCategoriesMessagesFr get storeOrder =>
      StoreOrderCategoriesMessagesFr(this);
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

class StoreOrderCategoriesMessagesFr extends StoreOrderCategoriesMessages {
  final CategoriesMessagesFr _parent;
  const StoreOrderCategoriesMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Ordre par magasin"
  /// ```
  String get title => """Ordre par magasin""";

  /// ```dart
  /// "Classez les catégories dans l'ordre où vous parcourez ce magasin. Le mode courses suit cet ordre pendant que vous y êtes."
  /// ```
  String get hint =>
      """Classez les catégories dans l'ordre où vous parcourez ce magasin. Le mode courses suit cet ordre pendant que vous y êtes.""";

  /// ```dart
  /// "Magasin"
  /// ```
  String get store => """Magasin""";

  /// ```dart
  /// "Aucun magasin pour le moment. Ajoutez-en un pour lui donner son propre ordre."
  /// ```
  String get noStores =>
      """Aucun magasin pour le moment. Ajoutez-en un pour lui donner son propre ordre.""";

  /// ```dart
  /// "Glisser pour réorganiser"
  /// ```
  String get dragHandle => """Glisser pour réorganiser""";

  /// ```dart
  /// "Utiliser l'ordre partagé"
  /// ```
  String get useSharedOrder => """Utiliser l'ordre partagé""";

  /// ```dart
  /// "Impossible de charger l'ordre de ce magasin."
  /// ```
  String get loadFailed => """Impossible de charger l'ordre de ce magasin.""";
}

class CustomFieldsMessagesFr extends CustomFieldsMessages {
  final MessagesFr _parent;
  const CustomFieldsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Champs personnalisés"
  /// ```
  String get manageTitle => """Champs personnalisés""";

  /// ```dart
  /// "Aucun champ personnalisé pour le moment. Ajoutez-en un pour attacher des informations supplémentaires aux articles."
  /// ```
  String get empty =>
      """Aucun champ personnalisé pour le moment. Ajoutez-en un pour attacher des informations supplémentaires aux articles.""";

  /// ```dart
  /// "Ajouter un champ"
  /// ```
  String get addField => """Ajouter un champ""";

  /// ```dart
  /// "Toutes les listes"
  /// ```
  String get allLists => """Toutes les listes""";

  /// ```dart
  /// "Supprimer le champ"
  /// ```
  String get deleteTitle => """Supprimer le champ""";

  /// ```dart
  /// "Supprimer ce champ ? Les valeurs déjà définies sur les articles sont conservées mais masquées."
  /// ```
  String get deleteConfirm =>
      """Supprimer ce champ ? Les valeurs déjà définies sur les articles sont conservées mais masquées.""";

  /// ```dart
  /// "Impossible de supprimer l'option."
  /// ```
  String get optionDeleteFailed => """Impossible de supprimer l'option.""";
  TypesCustomFieldsMessagesFr get types => TypesCustomFieldsMessagesFr(this);

  /// ```dart
  /// "Nom"
  /// ```
  String get name => """Nom""";

  /// ```dart
  /// "p. ex. Péremption, Rayon"
  /// ```
  String get namePlaceholder => """p. ex. Péremption, Rayon""";

  /// ```dart
  /// "Type"
  /// ```
  String get type => """Type""";

  /// ```dart
  /// "Le type ne peut pas être modifié après la création du champ."
  /// ```
  String get typeLocked =>
      """Le type ne peut pas être modifié après la création du champ.""";

  /// ```dart
  /// "Portée"
  /// ```
  String get scope => """Portée""";

  /// ```dart
  /// "Texte d'aide"
  /// ```
  String get hint => """Texte d'aide""";

  /// ```dart
  /// "Affiché comme texte indicatif de la valeur"
  /// ```
  String get hintPlaceholder =>
      """Affiché comme texte indicatif de la valeur""";

  /// ```dart
  /// "Zone de texte multiligne"
  /// ```
  String get multiline => """Zone de texte multiligne""";

  /// ```dart
  /// "Options"
  /// ```
  String get options => """Options""";

  /// ```dart
  /// "Libellé de l'option"
  /// ```
  String get optionPlaceholder => """Libellé de l'option""";

  /// ```dart
  /// "Ajouter une option"
  /// ```
  String get addOption => """Ajouter une option""";

  /// ```dart
  /// "Retirer l'option"
  /// ```
  String get removeOption => """Retirer l'option""";

  /// ```dart
  /// "Saisie de la date"
  /// ```
  String get entryMode => """Saisie de la date""";

  /// ```dart
  /// "Absolue"
  /// ```
  String get dateAbsolute => """Absolue""";

  /// ```dart
  /// "Relative"
  /// ```
  String get dateRelative => """Relative""";

  /// ```dart
  /// "Décalage par défaut (jours)"
  /// ```
  String get defaultOffset => """Décalage par défaut (jours)""";

  /// ```dart
  /// "p. ex. 7"
  /// ```
  String get defaultOffsetPlaceholder => """p. ex. 7""";

  /// ```dart
  /// "Rappeler par défaut"
  /// ```
  String get notifyDefault => """Rappeler par défaut""";

  /// ```dart
  /// "Rappeler"
  /// ```
  String get leadTime => """Rappeler""";

  /// ```dart
  /// "Le jour même"
  /// ```
  String get leadOnDay => """Le jour même""";

  /// ```dart
  /// "1 jour avant"
  /// ```
  String get leadDay1 => """1 jour avant""";

  /// ```dart
  /// "2 jours avant"
  /// ```
  String get leadDay2 => """2 jours avant""";

  /// ```dart
  /// "3 jours avant"
  /// ```
  String get leadDay3 => """3 jours avant""";

  /// ```dart
  /// "1 semaine avant"
  /// ```
  String get leadWeek1 => """1 semaine avant""";

  /// ```dart
  /// "Remplacement du rappel"
  /// ```
  String get overridePolicy => """Remplacement du rappel""";

  /// ```dart
  /// "Même rappel pour chaque article"
  /// ```
  String get overrideFieldOnly => """Même rappel pour chaque article""";

  /// ```dart
  /// "Chaque article définit son propre rappel"
  /// ```
  String get overrideItem => """Chaque article définit son propre rappel""";

  /// ```dart
  /// "Arrêter de rappeler une fois l'article terminé"
  /// ```
  String get stopWhenDone =>
      """Arrêter de rappeler une fois l'article terminé""";

  /// ```dart
  /// "Valeur par défaut"
  /// ```
  String get defaultValue => """Valeur par défaut""";

  /// ```dart
  /// "Activé par défaut"
  /// ```
  String get defaultChecked => """Activé par défaut""";

  /// ```dart
  /// "Aucune valeur par défaut"
  /// ```
  String get noDefault => """Aucune valeur par défaut""";

  /// ```dart
  /// "Aucune valeur"
  /// ```
  String get noValue => """Aucune valeur""";

  /// ```dart
  /// "Jours à partir d'aujourd'hui"
  /// ```
  String get daysFromToday => """Jours à partir d'aujourd'hui""";

  /// ```dart
  /// "Échéance le ${date}"
  /// ```
  String due(String date) => """Échéance le ${date}""";

  /// ```dart
  /// "Réancrer la date"
  /// ```
  String get reanchor => """Réancrer la date""";

  /// ```dart
  /// "Me rappeler"
  /// ```
  String get remindMe => """Me rappeler""";

  /// ```dart
  /// "Rappel personnalisé pour cet article"
  /// ```
  String get customReminder => """Rappel personnalisé pour cet article""";

  /// ```dart
  /// "Utiliser la valeur par défaut du champ"
  /// ```
  String get useFieldDefault => """Utiliser la valeur par défaut du champ""";

  /// ```dart
  /// "Terminé"
  /// ```
  String get done => """Terminé""";

  /// ```dart
  /// "Option utilisée"
  /// ```
  String get remapTitle => """Option utilisée""";

  /// ```dart
  /// "La retirer de ces articles"
  /// ```
  String get remapClear => """La retirer de ces articles""";

  /// ```dart
  /// "La déplacer vers ${label}"
  /// ```
  String remapMoveTo(String label) => """La déplacer vers ${label}""";

  /// ```dart
  /// "${_plural(count, one: '${label} est utilisée par 1 article. Que faut-il en faire ?', many: '${label} est utilisée par ${count} articles. Que faut-il en faire ?')}"
  /// ```
  String remapPrompt(int count, String label) =>
      """${_plural(count, one: '${label} est utilisée par 1 article. Que faut-il en faire ?', many: '${label} est utilisée par ${count} articles. Que faut-il en faire ?')}""";
}

class TypesCustomFieldsMessagesFr extends TypesCustomFieldsMessages {
  final CustomFieldsMessagesFr _parent;
  const TypesCustomFieldsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Texte"
  /// ```
  String get text => """Texte""";

  /// ```dart
  /// "Nombre"
  /// ```
  String get number => """Nombre""";

  /// ```dart
  /// "Case à cocher"
  /// ```
  String get checkbox => """Case à cocher""";

  /// ```dart
  /// "Date"
  /// ```
  String get date => """Date""";

  /// ```dart
  /// "Sélection"
  /// ```
  String get select => """Sélection""";
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

class LabelsMessagesFr extends LabelsMessages {
  final MessagesFr _parent;
  const LabelsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Gérer les étiquettes"
  /// ```
  String get manageTitle => """Gérer les étiquettes""";

  /// ```dart
  /// "Aucune étiquette pour le moment."
  /// ```
  String get noLabels => """Aucune étiquette pour le moment.""";

  /// ```dart
  /// "Modifier l'étiquette"
  /// ```
  String get editTitle => """Modifier l'étiquette""";

  /// ```dart
  /// "Nouvelle étiquette"
  /// ```
  String get addTitle => """Nouvelle étiquette""";

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
  /// "Impossible d'enregistrer l'étiquette."
  /// ```
  String get saveFailed => """Impossible d'enregistrer l'étiquette.""";

  /// ```dart
  /// "Impossible de supprimer l'étiquette."
  /// ```
  String get deleteFailed => """Impossible de supprimer l'étiquette.""";

  /// ```dart
  /// "Supprimer cette étiquette ?"
  /// ```
  String get deleteConfirm => """Supprimer cette étiquette ?""";

  /// ```dart
  /// "Cette étiquette sera retirée de tous les articles. Cette action est irréversible."
  /// ```
  String get deleteConfirmBody =>
      """Cette étiquette sera retirée de tous les articles. Cette action est irréversible.""";

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";

  /// ```dart
  /// "Toutes les listes (global)"
  /// ```
  String get globalList => """Toutes les listes (global)""";
  SortLabelsMessagesFr get sort => SortLabelsMessagesFr(this);
}

class SortLabelsMessagesFr extends SortLabelsMessages {
  final LabelsMessagesFr _parent;
  const SortLabelsMessagesFr(this._parent) : super(_parent);

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
  MenuChecklistsMessagesFr get menu => MenuChecklistsMessagesFr(this);
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
  /// "Copier le lien"
  /// ```
  String get copyLink => """Copier le lien""";

  /// ```dart
  /// "Ajouter à l'écran d'accueil"
  /// ```
  String get addToHomeScreen => """Ajouter à l'écran d'accueil""";

  /// ```dart
  /// "Impossible d'ajouter le raccourci."
  /// ```
  String get addToHomeScreenFailed => """Impossible d'ajouter le raccourci.""";

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
  /// "Listes archivées"
  /// ```
  String get archivedLists => """Listes archivées""";

  /// ```dart
  /// "Listes archivées"
  /// ```
  String get archivedListsTitle => """Listes archivées""";

  /// ```dart
  /// "Les listes archivées apparaîtront ici."
  /// ```
  String get archivedListsEmpty => """Les listes archivées apparaîtront ici.""";

  /// ```dart
  /// "Impossible de charger les listes archivées."
  /// ```
  String get failedToLoadArchivedLists =>
      """Impossible de charger les listes archivées.""";

  /// ```dart
  /// "Archiver"
  /// ```
  String get archiveList => """Archiver""";

  /// ```dart
  /// "Désarchiver"
  /// ```
  String get unarchiveList => """Désarchiver""";

  /// ```dart
  /// "Liste archivée"
  /// ```
  String get listArchived => """Liste archivée""";

  /// ```dart
  /// "Impossible d'archiver la liste."
  /// ```
  String get archiveListFailed => """Impossible d'archiver la liste.""";

  /// ```dart
  /// "Impossible de désarchiver la liste."
  /// ```
  String get unarchiveListFailed => """Impossible de désarchiver la liste.""";

  /// ```dart
  /// "Dupliquer"
  /// ```
  String get duplicateList => """Dupliquer""";

  /// ```dart
  /// "Dupliquer la liste"
  /// ```
  String get duplicateListTitle => """Dupliquer la liste""";

  /// ```dart
  /// "Copie de $name"
  /// ```
  String duplicateListName(String name) => """Copie de $name""";

  /// ```dart
  /// "Marquer tous les articles comme non faits"
  /// ```
  String get duplicateListResetDone =>
      """Marquer tous les articles comme non faits""";

  /// ```dart
  /// "Impossible de dupliquer la liste."
  /// ```
  String get duplicateListFailed => """Impossible de dupliquer la liste.""";

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
  /// "Terminée · $when"
  /// ```
  String completedAt(String when) => """Terminée · $when""";

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

  /// ```dart
  /// "Tout supprimer"
  /// ```
  String get removeAll => """Tout supprimer""";

  /// ```dart
  /// "Supprimer tous les articles cochés ?"
  /// ```
  String get removeAllConfirm => """Supprimer tous les articles cochés ?""";

  /// ```dart
  /// "Chaque article coché de cette liste sera déplacé vers la corbeille. Vous pourrez les restaurer ensuite."
  /// ```
  String get removeAllConfirmBody =>
      """Chaque article coché de cette liste sera déplacé vers la corbeille. Vous pourrez les restaurer ensuite.""";

  /// ```dart
  /// "${_plural(count, one: '1 article supprimé', many: '$count articles supprimés')}"
  /// ```
  String removedCount(int count) =>
      """${_plural(count, one: '1 article supprimé', many: '$count articles supprimés')}""";

  /// ```dart
  /// "Tout archiver"
  /// ```
  String get archiveAll => """Tout archiver""";

  /// ```dart
  /// "Archiver tous les articles cochés ?"
  /// ```
  String get archiveAllConfirm => """Archiver tous les articles cochés ?""";

  /// ```dart
  /// "Chaque article coché de cette liste sera déplacé vers les archives. Vous pourrez les désarchiver ensuite."
  /// ```
  String get archiveAllConfirmBody =>
      """Chaque article coché de cette liste sera déplacé vers les archives. Vous pourrez les désarchiver ensuite.""";
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
  /// "Tout est fait · $when"
  /// ```
  String allDoneSummaryAt(String when) => """Tout est fait · $when""";

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
  ListRecurrenceChecklistsMessagesFr get listRecurrence =>
      ListRecurrenceChecklistsMessagesFr(this);
  ItemDefaultsChecklistsMessagesFr get itemDefaults =>
      ItemDefaultsChecklistsMessagesFr(this);
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
  /// "Activer le flash"
  /// ```
  String get torch => """Activer le flash""";

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
  /// "Étiquettes"
  /// ```
  String get labels => """Étiquettes""";

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
  /// "Toutes les étiquettes"
  /// ```
  String get allLabels => """Toutes les étiquettes""";

  /// ```dart
  /// "Sans catégorie"
  /// ```
  String get noCategory => """Sans catégorie""";

  /// ```dart
  /// "Sans magasin"
  /// ```
  String get noStores => """Sans magasin""";

  /// ```dart
  /// "Sans étiquette"
  /// ```
  String get noLabels => """Sans étiquette""";

  /// ```dart
  /// "Prix"
  /// ```
  String get price => """Prix""";

  /// ```dart
  /// "N'importe quelle devise"
  /// ```
  String get anyCurrency => """N'importe quelle devise""";
}

class MenuChecklistsMessagesFr extends MenuChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const MenuChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Tri et affichage"
  /// ```
  String get sortAndView => """Tri et affichage""";

  /// ```dart
  /// "Gérer"
  /// ```
  String get manage => """Gérer""";

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";

  /// ```dart
  /// "Courses"
  /// ```
  String get shopping => """Courses""";

  /// ```dart
  /// "Développeur"
  /// ```
  String get developer => """Développeur""";
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
  /// "Définir les étiquettes"
  /// ```
  String get labelsTitle => """Définir les étiquettes""";

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
  /// "Étiquettes"
  /// ```
  String get labels => """Étiquettes""";

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
  /// "${_plural(count, one: '1 article mis à jour', many: '$count articles mis à jour')}"
  /// ```
  String labelsSet(int count) =>
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
  /// "Récurrence"
  /// ```
  String get typeLabel => """Récurrence""";

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
  /// "Terminé par $name · $time"
  /// ```
  String doneByMeta(String name, String time) =>
      """Terminé par $name · $time""";

  /// ```dart
  /// "Terminé par vous · $time"
  /// ```
  String doneByYouMeta(String time) => """Terminé par vous · $time""";

  /// ```dart
  /// "Terminé $time"
  /// ```
  String doneMeta(String time) => """Terminé $time""";

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
  /// "Étiquettes"
  /// ```
  String get labels => """Étiquettes""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get noLabels => """Aucune""";

  /// ```dart
  /// "Nouvelle étiquette"
  /// ```
  String get createLabel => """Nouvelle étiquette""";

  /// ```dart
  /// "Modifier"
  /// ```
  String get labelsChange => """Modifier""";

  /// ```dart
  /// "Choisir"
  /// ```
  String get labelsPick => """Choisir""";

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
  /// "Pas de connexion — l'image sera jointe dès votre retour en ligne."
  /// ```
  String get imageQueuedOffline =>
      """Pas de connexion — l'image sera jointe dès votre retour en ligne.""";

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

class ListRecurrenceChecklistsMessagesFr
    extends ListRecurrenceChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ListRecurrenceChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Récurrence par défaut"
  /// ```
  String get label => """Récurrence par défaut""";

  /// ```dart
  /// "Mémoriser la dernière"
  /// ```
  String get remember => """Mémoriser la dernière""";

  /// ```dart
  /// "Les nouveaux articles démarrent avec la même récurrence que le dernier article ajouté à cette liste."
  /// ```
  String get rememberHint =>
      """Les nouveaux articles démarrent avec la même récurrence que le dernier article ajouté à cette liste.""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get none => """Aucune""";

  /// ```dart
  /// "Les nouveaux articles restent sur la liste après avoir été complétés."
  /// ```
  String get noneHint =>
      """Les nouveaux articles restent sur la liste après avoir été complétés.""";

  /// ```dart
  /// "Unique"
  /// ```
  String get once => """Unique""";

  /// ```dart
  /// "Les nouveaux articles sont supprimés de la liste une fois complétés."
  /// ```
  String get onceHint =>
      """Les nouveaux articles sont supprimés de la liste une fois complétés.""";

  /// ```dart
  /// "Récurrent"
  /// ```
  String get recurring => """Récurrent""";

  /// ```dart
  /// "Les nouveaux articles reviennent selon l'horaire ci-dessous."
  /// ```
  String get recurringHint =>
      """Les nouveaux articles reviennent selon l'horaire ci-dessous.""";
}

class ItemDefaultsChecklistsMessagesFr extends ItemDefaultsChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ItemDefaultsChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Valeurs par défaut des articles"
  /// ```
  String get title => """Valeurs par défaut des articles""";

  /// ```dart
  /// "Les nouveaux articles de cette liste démarrent avec ces valeurs."
  /// ```
  String get intro =>
      """Les nouveaux articles de cette liste démarrent avec ces valeurs.""";

  /// ```dart
  /// "Seules les personnes qui peuvent modifier cette liste peuvent changer ses valeurs par défaut."
  /// ```
  String get readOnly =>
      """Seules les personnes qui peuvent modifier cette liste peuvent changer ses valeurs par défaut.""";

  /// ```dart
  /// "Modifier les valeurs par défaut"
  /// ```
  String get edit => """Modifier les valeurs par défaut""";

  /// ```dart
  /// "Non défini"
  /// ```
  String get modeNone => """Non défini""";

  /// ```dart
  /// "Fixe"
  /// ```
  String get modeFixed => """Fixe""";

  /// ```dart
  /// "Mémoriser le dernier"
  /// ```
  String get modeRemember => """Mémoriser le dernier""";

  /// ```dart
  /// "Valeur par défaut du champ"
  /// ```
  String get modeFieldDefault => """Valeur par défaut du champ""";

  /// ```dart
  /// "Les nouveaux articles démarrent sans valeur."
  /// ```
  String get noneHint => """Les nouveaux articles démarrent sans valeur.""";

  /// ```dart
  /// "Les nouveaux articles démarrent toujours avec la valeur ci-dessous."
  /// ```
  String get fixedHint =>
      """Les nouveaux articles démarrent toujours avec la valeur ci-dessous.""";

  /// ```dart
  /// "Les nouveaux articles démarrent avec la valeur du dernier article ajouté à cette liste."
  /// ```
  String get rememberHint =>
      """Les nouveaux articles démarrent avec la valeur du dernier article ajouté à cette liste.""";

  /// ```dart
  /// "${field} : dernier utilisé"
  /// ```
  String lastUsed(String field) => """${field} : dernier utilisé""";

  /// ```dart
  /// "Utilise la valeur par défaut du champ : ${value}"
  /// ```
  String inheritValue(String value) =>
      """Utilise la valeur par défaut du champ : ${value}""";

  /// ```dart
  /// "Utilise la valeur par défaut du champ, qui est vide."
  /// ```
  String get inheritEmpty =>
      """Utilise la valeur par défaut du champ, qui est vide.""";

  /// ```dart
  /// "${_plural(count, one: 'Dans 1 jour', many: 'Dans ${count} jours')}"
  /// ```
  String inDays(int count) =>
      """${_plural(count, one: 'Dans 1 jour', many: 'Dans ${count} jours')}""";

  /// ```dart
  /// "${_plural(count, one: '1 champ défini', many: '${count} champs définis')}"
  /// ```
  String fieldsSet(int count) =>
      """${_plural(count, one: '1 champ défini', many: '${count} champs définis')}""";

  /// ```dart
  /// "Coché"
  /// ```
  String get checked => """Coché""";
}

class ItemTypesChecklistsMessagesFr extends ItemTypesChecklistsMessages {
  final ChecklistsMessagesFr _parent;
  const ItemTypesChecklistsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Récurrence"
  /// ```
  String get label => """Récurrence""";

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
  /// "Étiquettes"
  /// ```
  String get chipLabel => """Étiquettes""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get chipQuantity => """Quantité""";

  /// ```dart
  /// "Récurrence"
  /// ```
  String get chipType => """Récurrence""";

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

  /// ```dart
  /// "N'importe quel magasin"
  /// ```
  String get anyStore => """N'importe quel magasin""";

  /// ```dart
  /// "Magasin"
  /// ```
  String get store => """Magasin""";

  /// ```dart
  /// "Ajouter un prix"
  /// ```
  String get addPrice => """Ajouter un prix""";

  /// ```dart
  /// "Supprimer le prix"
  /// ```
  String get removePrice => """Supprimer le prix""";
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

  /// ```dart
  /// "Archivé"
  /// ```
  String get archivedBadge => """Archivé""";

  /// ```dart
  /// "Un article archivé nommé "$name" existe déjà. Le réutiliser au lieu d'en ajouter un nouveau ? Il sera désarchivé."
  /// ```
  String archivedDialogBody(String name) =>
      """Un article archivé nommé "$name" existe déjà. Le réutiliser au lieu d'en ajouter un nouveau ? Il sera désarchivé.""";

  /// ```dart
  /// "Article archivé "$name" réutilisé"
  /// ```
  String reusedArchivedSnack(String name) =>
      """Article archivé "$name" réutilisé""";
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
  /// "Importer vers"
  /// ```
  String get importToLabel => """Importer vers""";

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

class ListKindsMessagesFr extends ListKindsMessages {
  final MessagesFr _parent;
  const ListKindsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Dupliquer en tant que :"
  /// ```
  String get duplicateAs => """Dupliquer en tant que :""";

  /// ```dart
  /// "${_plural(count, one: '1 article a été ignoré, car vous n’êtes pas autorisé à le modifier.', many: '$count articles ont été ignorés, car vous n’êtes pas autorisé à les modifier.')}"
  /// ```
  String itemsSkippedNoEdit(int count) =>
      """${_plural(count, one: '1 article a été ignoré, car vous n’êtes pas autorisé à le modifier.', many: '$count articles ont été ignorés, car vous n’êtes pas autorisé à les modifier.')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article n’a pas pu être décoché.', many: '$count articles n’ont pas pu être décochés.')}"
  /// ```
  String itemsSkippedUncheck(int count) =>
      """${_plural(count, one: '1 article n’a pas pu être décoché.', many: '$count articles n’ont pas pu être décochés.')}""";
  ChecklistListKindsMessagesFr get checklist =>
      ChecklistListKindsMessagesFr(this);
  InventoryListKindsMessagesFr get inventory =>
      InventoryListKindsMessagesFr(this);
  TemplateListKindsMessagesFr get template => TemplateListKindsMessagesFr(this);
}

class ChecklistListKindsMessagesFr extends ChecklistListKindsMessages {
  final ListKindsMessagesFr _parent;
  const ChecklistListKindsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Listes de contrôle"
  /// ```
  String get title => """Listes de contrôle""";

  /// ```dart
  /// "Liste de contrôle"
  /// ```
  String get name => """Liste de contrôle""";

  /// ```dart
  /// "Nouvelle liste de contrôle"
  /// ```
  String get newList => """Nouvelle liste de contrôle""";

  /// ```dart
  /// "Créer une liste de contrôle"
  /// ```
  String get createTitle => """Créer une liste de contrôle""";

  /// ```dart
  /// "Modifier la liste de contrôle"
  /// ```
  String get editTitle => """Modifier la liste de contrôle""";

  /// ```dart
  /// "Dupliquer la liste de contrôle"
  /// ```
  String get duplicateTitle => """Dupliquer la liste de contrôle""";

  /// ```dart
  /// "Impossible de dupliquer la liste de contrôle"
  /// ```
  String get duplicateFailed =>
      """Impossible de dupliquer la liste de contrôle""";

  /// ```dart
  /// "Actions de la liste de contrôle"
  /// ```
  String get listMenu => """Actions de la liste de contrôle""";

  /// ```dart
  /// "Supprimer la liste de contrôle"
  /// ```
  String get deleteDialogTitle => """Supprimer la liste de contrôle""";

  /// ```dart
  /// "Aucune liste de contrôle pour le moment"
  /// ```
  String get emptyTitle => """Aucune liste de contrôle pour le moment""";

  /// ```dart
  /// "Créez votre première liste de contrôle pour commencer à ajouter des articles."
  /// ```
  String get emptyBody =>
      """Créez votre première liste de contrôle pour commencer à ajouter des articles.""";

  /// ```dart
  /// "Corbeille des listes de contrôle"
  /// ```
  String get trashTitle => """Corbeille des listes de contrôle""";

  /// ```dart
  /// "Les listes de contrôle supprimées apparaîtront ici."
  /// ```
  String get trashEmptyBody =>
      """Les listes de contrôle supprimées apparaîtront ici.""";

  /// ```dart
  /// "Listes de contrôle archivées"
  /// ```
  String get archiveTitle => """Listes de contrôle archivées""";

  /// ```dart
  /// "Aucune liste de contrôle archivée"
  /// ```
  String get archiveEmptyTitle => """Aucune liste de contrôle archivée""";

  /// ```dart
  /// "Les listes de contrôle archivées apparaîtront ici."
  /// ```
  String get archiveEmptyBody =>
      """Les listes de contrôle archivées apparaîtront ici.""";

  /// ```dart
  /// "Toutes les listes de contrôle présentes dans la corbeille, ainsi que leurs articles, seront définitivement supprimées. Cette action est irréversible."
  /// ```
  String get emptyTrashBody =>
      """Toutes les listes de contrôle présentes dans la corbeille, ainsi que leurs articles, seront définitivement supprimées. Cette action est irréversible.""";

  /// ```dart
  /// "Liste de contrôle restaurée"
  /// ```
  String get listRestored => """Liste de contrôle restaurée""";

  /// ```dart
  /// "Liste de contrôle déplacée vers la corbeille"
  /// ```
  String get listMovedToTrash =>
      """Liste de contrôle déplacée vers la corbeille""";

  /// ```dart
  /// "Liste de contrôle archivée"
  /// ```
  String get listArchived => """Liste de contrôle archivée""";

  /// ```dart
  /// "Liste de contrôle désarchivée"
  /// ```
  String get listUnarchived => """Liste de contrôle désarchivée""";
}

class InventoryListKindsMessagesFr extends InventoryListKindsMessages {
  final ListKindsMessagesFr _parent;
  const InventoryListKindsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Inventaires"
  /// ```
  String get title => """Inventaires""";

  /// ```dart
  /// "Inventaire"
  /// ```
  String get name => """Inventaire""";

  /// ```dart
  /// "Nouvel inventaire"
  /// ```
  String get newList => """Nouvel inventaire""";

  /// ```dart
  /// "Créer un inventaire"
  /// ```
  String get createTitle => """Créer un inventaire""";

  /// ```dart
  /// "Modifier l'inventaire"
  /// ```
  String get editTitle => """Modifier l'inventaire""";

  /// ```dart
  /// "Dupliquer l'inventaire"
  /// ```
  String get duplicateTitle => """Dupliquer l'inventaire""";

  /// ```dart
  /// "Impossible de dupliquer l'inventaire"
  /// ```
  String get duplicateFailed => """Impossible de dupliquer l'inventaire""";

  /// ```dart
  /// "Actions de l'inventaire"
  /// ```
  String get listMenu => """Actions de l'inventaire""";

  /// ```dart
  /// "Supprimer l'inventaire"
  /// ```
  String get deleteDialogTitle => """Supprimer l'inventaire""";

  /// ```dart
  /// "Aucun inventaire pour le moment"
  /// ```
  String get emptyTitle => """Aucun inventaire pour le moment""";

  /// ```dart
  /// "Créez votre premier inventaire pour commencer à ajouter des articles."
  /// ```
  String get emptyBody =>
      """Créez votre premier inventaire pour commencer à ajouter des articles.""";

  /// ```dart
  /// "Corbeille des inventaires"
  /// ```
  String get trashTitle => """Corbeille des inventaires""";

  /// ```dart
  /// "Les inventaires supprimés apparaîtront ici."
  /// ```
  String get trashEmptyBody =>
      """Les inventaires supprimés apparaîtront ici.""";

  /// ```dart
  /// "Inventaires archivés"
  /// ```
  String get archiveTitle => """Inventaires archivés""";

  /// ```dart
  /// "Aucun inventaire archivé"
  /// ```
  String get archiveEmptyTitle => """Aucun inventaire archivé""";

  /// ```dart
  /// "Les inventaires archivés apparaîtront ici."
  /// ```
  String get archiveEmptyBody =>
      """Les inventaires archivés apparaîtront ici.""";

  /// ```dart
  /// "Tous les inventaires présents dans la corbeille, ainsi que leurs articles, seront définitivement supprimés. Cette action est irréversible."
  /// ```
  String get emptyTrashBody =>
      """Tous les inventaires présents dans la corbeille, ainsi que leurs articles, seront définitivement supprimés. Cette action est irréversible.""";

  /// ```dart
  /// "Inventaire restauré"
  /// ```
  String get listRestored => """Inventaire restauré""";

  /// ```dart
  /// "Inventaire déplacé vers la corbeille"
  /// ```
  String get listMovedToTrash => """Inventaire déplacé vers la corbeille""";

  /// ```dart
  /// "Inventaire archivé"
  /// ```
  String get listArchived => """Inventaire archivé""";

  /// ```dart
  /// "Inventaire désarchivé"
  /// ```
  String get listUnarchived => """Inventaire désarchivé""";
}

class TemplateListKindsMessagesFr extends TemplateListKindsMessages {
  final ListKindsMessagesFr _parent;
  const TemplateListKindsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Modèles"
  /// ```
  String get title => """Modèles""";

  /// ```dart
  /// "Modèle"
  /// ```
  String get name => """Modèle""";

  /// ```dart
  /// "Nouveau modèle"
  /// ```
  String get newList => """Nouveau modèle""";

  /// ```dart
  /// "Créer un modèle"
  /// ```
  String get createTitle => """Créer un modèle""";

  /// ```dart
  /// "Modifier le modèle"
  /// ```
  String get editTitle => """Modifier le modèle""";

  /// ```dart
  /// "Dupliquer le modèle"
  /// ```
  String get duplicateTitle => """Dupliquer le modèle""";

  /// ```dart
  /// "Impossible de dupliquer le modèle"
  /// ```
  String get duplicateFailed => """Impossible de dupliquer le modèle""";

  /// ```dart
  /// "Actions du modèle"
  /// ```
  String get listMenu => """Actions du modèle""";

  /// ```dart
  /// "Supprimer le modèle"
  /// ```
  String get deleteDialogTitle => """Supprimer le modèle""";

  /// ```dart
  /// "Aucun modèle pour le moment"
  /// ```
  String get emptyTitle => """Aucun modèle pour le moment""";

  /// ```dart
  /// "Créez votre premier modèle pour commencer à ajouter des articles."
  /// ```
  String get emptyBody =>
      """Créez votre premier modèle pour commencer à ajouter des articles.""";

  /// ```dart
  /// "Corbeille des modèles"
  /// ```
  String get trashTitle => """Corbeille des modèles""";

  /// ```dart
  /// "Les modèles supprimés apparaîtront ici."
  /// ```
  String get trashEmptyBody => """Les modèles supprimés apparaîtront ici.""";

  /// ```dart
  /// "Modèles archivés"
  /// ```
  String get archiveTitle => """Modèles archivés""";

  /// ```dart
  /// "Aucun modèle archivé"
  /// ```
  String get archiveEmptyTitle => """Aucun modèle archivé""";

  /// ```dart
  /// "Les modèles archivés apparaîtront ici."
  /// ```
  String get archiveEmptyBody => """Les modèles archivés apparaîtront ici.""";

  /// ```dart
  /// "Tous les modèles présents dans la corbeille, ainsi que leurs articles, seront définitivement supprimés. Cette action est irréversible."
  /// ```
  String get emptyTrashBody =>
      """Tous les modèles présents dans la corbeille, ainsi que leurs articles, seront définitivement supprimés. Cette action est irréversible.""";

  /// ```dart
  /// "Modèle restauré"
  /// ```
  String get listRestored => """Modèle restauré""";

  /// ```dart
  /// "Modèle déplacé vers la corbeille"
  /// ```
  String get listMovedToTrash => """Modèle déplacé vers la corbeille""";

  /// ```dart
  /// "Modèle archivé"
  /// ```
  String get listArchived => """Modèle archivé""";

  /// ```dart
  /// "Modèle désarchivé"
  /// ```
  String get listUnarchived => """Modèle désarchivé""";
}

class TemplatesMessagesFr extends TemplatesMessages {
  final MessagesFr _parent;
  const TemplatesMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Suggestions"
  /// ```
  String get suggestionsHeader => """Suggestions""";

  /// ```dart
  /// "Depuis les modèles : $names"
  /// ```
  String fromTemplates(String names) => """Depuis les modèles : $names""";

  /// ```dart
  /// ""$name" ajouté depuis un modèle"
  /// ```
  String addedFromTemplate(String name) =>
      """"$name" ajouté depuis un modèle""";

  /// ```dart
  /// "Impossible d'ajouter l'article depuis le modèle"
  /// ```
  String get drawFailed =>
      """Impossible d'ajouter l'article depuis le modèle""";

  /// ```dart
  /// "Modèles :"
  /// ```
  String get attachedLabel => """Modèles :""";

  /// ```dart
  /// "Aucun modèle"
  /// ```
  String get attachedPlaceholder => """Aucun modèle""";

  /// ```dart
  /// "La saisie d'un nouvel article suggère les articles correspondants de ces modèles."
  /// ```
  String get attachedHint =>
      """La saisie d'un nouvel article suggère les articles correspondants de ces modèles.""";

  /// ```dart
  /// "La saisie d'un nouvel article suggère les articles correspondants de ces modèles, ainsi que de $names, utilisés par toutes les listes."
  /// ```
  String attachedEveryListHint(String names) =>
      """La saisie d'un nouvel article suggère les articles correspondants de ces modèles, ainsi que de $names, utilisés par toutes les listes.""";

  /// ```dart
  /// "Suggérer dans :"
  /// ```
  String get suggestInLabel => """Suggérer dans :""";

  /// ```dart
  /// "Toutes les listes"
  /// ```
  String get everyList => """Toutes les listes""";

  /// ```dart
  /// "Aucune liste"
  /// ```
  String get suggestInPlaceholder => """Aucune liste""";

  /// ```dart
  /// "La saisie d'un nouvel article dans ces listes suggère les articles correspondants de ce modèle. Sélectionner « Toutes les listes » inclut aussi les listes créées par la suite."
  /// ```
  String get suggestInHint =>
      """La saisie d'un nouvel article dans ces listes suggère les articles correspondants de ce modèle. Sélectionner « Toutes les listes » inclut aussi les listes créées par la suite.""";

  /// ```dart
  /// "$list ($kind)"
  /// ```
  String listWithKind(String list, String kind) => """$list ($kind)""";

  /// ```dart
  /// "Impossible d'enregistrer les modèles associés"
  /// ```
  String get attachFailed =>
      """Impossible d'enregistrer les modèles associés""";

  /// ```dart
  /// "Remplir les articles de modèle avec ces valeurs"
  /// ```
  String get fillLabel => """Remplir les articles de modèle avec ces valeurs""";

  /// ```dart
  /// "Lorsqu'un article est ajouté depuis un modèle, les détails qu'il laisse vides démarrent avec les valeurs ci-dessus. Chaque personne peut modifier ce comportement dans ses paramètres personnels."
  /// ```
  String get fillHint =>
      """Lorsqu'un article est ajouté depuis un modèle, les détails qu'il laisse vides démarrent avec les valeurs ci-dessus. Chaque personne peut modifier ce comportement dans ses paramètres personnels.""";

  /// ```dart
  /// "Remplir les articles de modèle avec les valeurs par défaut"
  /// ```
  String get fillPrefLabel =>
      """Remplir les articles de modèle avec les valeurs par défaut""";

  /// ```dart
  /// "Lorsque vous ajoutez un article depuis un modèle, les détails qu'il laisse vides sont remplis avec les valeurs par défaut des articles de la liste. Chaque liste peut désactiver ce comportement dans ses valeurs par défaut."
  /// ```
  String get fillPrefHint =>
      """Lorsque vous ajoutez un article depuis un modèle, les détails qu'il laisse vides sont remplis avec les valeurs par défaut des articles de la liste. Chaque liste peut désactiver ce comportement dans ses valeurs par défaut.""";
  FillPrefNamesTemplatesMessagesFr get fillPrefNames =>
      FillPrefNamesTemplatesMessagesFr(this);

  /// ```dart
  /// "Impossible d'enregistrer le paramètre"
  /// ```
  String get fillPrefFailed => """Impossible d'enregistrer le paramètre""";

  /// ```dart
  /// "Appliquer à une liste"
  /// ```
  String get applyToList => """Appliquer à une liste""";

  /// ```dart
  /// "Appliquer le modèle"
  /// ```
  String get applyTemplate => """Appliquer le modèle""";

  /// ```dart
  /// "Associés à cette liste"
  /// ```
  String get attachedTemplates => """Associés à cette liste""";

  /// ```dart
  /// "Autres modèles"
  /// ```
  String get otherTemplates => """Autres modèles""";

  /// ```dart
  /// "Aucune liste de contrôle ni aucun inventaire auquel appliquer ce modèle."
  /// ```
  String get noTargets =>
      """Aucune liste de contrôle ni aucun inventaire auquel appliquer ce modèle.""";

  /// ```dart
  /// "Ce modèle ne contient aucun article."
  /// ```
  String get noItems => """Ce modèle ne contient aucun article.""";

  /// ```dart
  /// "Déjà dans la liste"
  /// ```
  String get alreadyOnList => """Déjà dans la liste""";

  /// ```dart
  /// "Copier les articles cochés de $template dans $list."
  /// ```
  String reviewSummary(String template, String list) =>
      """Copier les articles cochés de $template dans $list.""";

  /// ```dart
  /// "${_plural(count, one: 'Appliquer 1 article', many: 'Appliquer $count articles')}"
  /// ```
  String applyItems(int count) =>
      """${_plural(count, one: 'Appliquer 1 article', many: 'Appliquer $count articles')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article ajouté à $list', many: '$count articles ajoutés à $list')}"
  /// ```
  String appliedAdded(int count, String list) =>
      """${_plural(count, one: '1 article ajouté à $list', many: '$count articles ajoutés à $list')}""";

  /// ```dart
  /// "${_plural(count, one: '1 article était déjà dans $list et a été rétabli', many: '$count articles étaient déjà dans $list et ont été rétablis')}"
  /// ```
  String appliedReused(int count, String list) =>
      """${_plural(count, one: '1 article était déjà dans $list et a été rétabli', many: '$count articles étaient déjà dans $list et ont été rétablis')}""";

  /// ```dart
  /// "$list : $added ajoutés, $reused rétablis"
  /// ```
  String appliedMixed(String list, int added, int reused) =>
      """$list : $added ajoutés, $reused rétablis""";

  /// ```dart
  /// "Impossible d'appliquer le modèle"
  /// ```
  String get applyFailed => """Impossible d'appliquer le modèle""";

  /// ```dart
  /// "Impossible de charger les modèles"
  /// ```
  String get loadFailed => """Impossible de charger les modèles""";

  /// ```dart
  /// "Retour"
  /// ```
  String get back => """Retour""";
}

class FillPrefNamesTemplatesMessagesFr extends FillPrefNamesTemplatesMessages {
  final TemplatesMessagesFr _parent;
  const FillPrefNamesTemplatesMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Selon chaque liste"
  /// ```
  String get list => """Selon chaque liste""";

  /// ```dart
  /// "Toujours remplir"
  /// ```
  String get always => """Toujours remplir""";

  /// ```dart
  /// "Ne jamais remplir"
  /// ```
  String get never => """Ne jamais remplir""";
}

class StockMessagesFr extends StockMessages {
  final MessagesFr _parent;
  const StockMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "En stock"
  /// ```
  String get inStock => """En stock""";

  /// ```dart
  /// "Plein"
  /// ```
  String get full => """Plein""";

  /// ```dart
  /// "Bas"
  /// ```
  String get low => """Bas""";

  /// ```dart
  /// "Épuisé"
  /// ```
  String get out => """Épuisé""";

  /// ```dart
  /// "Bas · acheter $amount"
  /// ```
  String lowBuy(String amount) => """Bas · acheter $amount""";

  /// ```dart
  /// "Épuisé · acheter $amount"
  /// ```
  String outBuy(String amount) => """Épuisé · acheter $amount""";

  /// ```dart
  /// "Non compté"
  /// ```
  String get notCounted => """Non compté""";

  /// ```dart
  /// "Périmé le $date"
  /// ```
  String expiredOn(String date) => """Périmé le $date""";

  /// ```dart
  /// "Périmé le $date · acheter $amount"
  /// ```
  String expiredOnBuy(String date, String amount) =>
      """Périmé le $date · acheter $amount""";

  /// ```dart
  /// "Périme aujourd’hui"
  /// ```
  String get expiresToday => """Périme aujourd’hui""";

  /// ```dart
  /// "Périme aujourd’hui · acheter $amount"
  /// ```
  String expiresTodayBuy(String amount) =>
      """Périme aujourd’hui · acheter $amount""";

  /// ```dart
  /// "Périme demain"
  /// ```
  String get expiresTomorrow => """Périme demain""";

  /// ```dart
  /// "Périme demain · acheter $amount"
  /// ```
  String expiresTomorrowBuy(String amount) =>
      """Périme demain · acheter $amount""";

  /// ```dart
  /// "${_plural(count, one: 'Périme dans 1 jour', many: 'Périme dans $count jours')}"
  /// ```
  String expiresInDays(int count) =>
      """${_plural(count, one: 'Périme dans 1 jour', many: 'Périme dans $count jours')}""";

  /// ```dart
  /// "${_plural(count, one: 'Périme dans 1 jour · acheter $amount', many: 'Périme dans $count jours · acheter $amount')}"
  /// ```
  String expiresInDaysBuy(int count, String amount) =>
      """${_plural(count, one: 'Périme dans 1 jour · acheter $amount', many: 'Périme dans $count jours · acheter $amount')}""";

  /// ```dart
  /// "Bon jusqu’au $date"
  /// ```
  String goodUntil(String date) => """Bon jusqu’au $date""";

  /// ```dart
  /// "$onHand / $target"
  /// ```
  String amount(String onHand, String target) => """$onHand / $target""";

  /// ```dart
  /// "Diminuer la quantité disponible"
  /// ```
  String get decrease => """Diminuer la quantité disponible""";

  /// ```dart
  /// "Augmenter la quantité disponible"
  /// ```
  String get increase => """Augmenter la quantité disponible""";

  /// ```dart
  /// "Quantité disponible"
  /// ```
  String get onHandEdit => """Quantité disponible""";

  /// ```dart
  /// "Niveau de stock : $level"
  /// ```
  String levelButton(String level) => """Niveau de stock : $level""";

  /// ```dart
  /// "${_plural(count, one: '1 article à réapprovisionner', many: '$count articles à réapprovisionner')}"
  /// ```
  String needsRestockCount(int count) =>
      """${_plural(count, one: '1 article à réapprovisionner', many: '$count articles à réapprovisionner')}""";

  /// ```dart
  /// "Stock"
  /// ```
  String get filter => """Stock""";

  /// ```dart
  /// "Tous les articles"
  /// ```
  String get filterAll => """Tous les articles""";

  /// ```dart
  /// "À réapprovisionner"
  /// ```
  String get filterNeedsRestock => """À réapprovisionner""";

  /// ```dart
  /// "En stock"
  /// ```
  String get filterInStock => """En stock""";

  /// ```dart
  /// "Impossible d’enregistrer la modification du stock. L’inventaire affiche maintenant les données du serveur."
  /// ```
  String get writeRefused =>
      """Impossible d’enregistrer la modification du stock. L’inventaire affiche maintenant les données du serveur.""";
  SettingsStockMessagesFr get settings => SettingsStockMessagesFr(this);
  CardStockMessagesFr get card => CardStockMessagesFr(this);
  ExpiryStockMessagesFr get expiry => ExpiryStockMessagesFr(this);
  ComposeStockMessagesFr get compose => ComposeStockMessagesFr(this);
}

class SettingsStockMessagesFr extends SettingsStockMessages {
  final StockMessagesFr _parent;
  const SettingsStockMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Paramètres de l’inventaire"
  /// ```
  String get action => """Paramètres de l’inventaire""";

  /// ```dart
  /// "Paramètres de l’inventaire"
  /// ```
  String get title => """Paramètres de l’inventaire""";

  /// ```dart
  /// "Nom"
  /// ```
  String get name => """Nom""";

  /// ```dart
  /// "L’icône, la couleur et le partage fonctionnent comme pour les listes de contrôle."
  /// ```
  String get nameHint =>
      """L’icône, la couleur et le partage fonctionnent comme pour les listes de contrôle.""";

  /// ```dart
  /// "Alerte de péremption"
  /// ```
  String get expiryWarning => """Alerte de péremption""";

  /// ```dart
  /// "Avertir $days jours avant la péremption"
  /// ```
  String warnBefore(String days) =>
      """Avertir $days jours avant la péremption""";

  /// ```dart
  /// "Jours avant la péremption"
  /// ```
  String get daysBefore => """Jours avant la péremption""";

  /// ```dart
  /// "Indiquez 0 pour être averti le jour même de la péremption."
  /// ```
  String get warnHint =>
      """Indiquez 0 pour être averti le jour même de la péremption.""";

  /// ```dart
  /// "Annuler"
  /// ```
  String get cancel => """Annuler""";

  /// ```dart
  /// "Enregistrer"
  /// ```
  String get save => """Enregistrer""";
}

class CardStockMessagesFr extends CardStockMessages {
  final StockMessagesFr _parent;
  const CardStockMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Stock"
  /// ```
  String get title => """Stock""";

  /// ```dart
  /// "Mode de stock"
  /// ```
  String get mode => """Mode de stock""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get count => """Quantité""";

  /// ```dart
  /// "Niveau"
  /// ```
  String get level => """Niveau""";

  /// ```dart
  /// "Suivez combien vous en avez, p. ex. 4 œufs sur 12."
  /// ```
  String get countHint =>
      """Suivez combien vous en avez, p. ex. 4 œufs sur 12.""";

  /// ```dart
  /// "Suivez-le en Plein, Bas ou Épuisé, p. ex. farine ou épices."
  /// ```
  String get levelHint =>
      """Suivez-le en Plein, Bas ou Épuisé, p. ex. farine ou épices.""";

  /// ```dart
  /// "Disponible"
  /// ```
  String get onHand => """Disponible""";

  /// ```dart
  /// "p. ex. 4"
  /// ```
  String get onHandPlaceholder => """p. ex. 4""";

  /// ```dart
  /// "Objectif"
  /// ```
  String get target => """Objectif""";

  /// ```dart
  /// "p. ex. 12 œufs"
  /// ```
  String get targetPlaceholder => """p. ex. 12 œufs""";

  /// ```dart
  /// "Seuil de réapprovisionnement"
  /// ```
  String get reorderPoint => """Seuil de réapprovisionnement""";

  /// ```dart
  /// "p. ex. 4"
  /// ```
  String get reorderPlaceholder => """p. ex. 4""";

  /// ```dart
  /// "Niveau de stock"
  /// ```
  String get stockLevel => """Niveau de stock""";

  /// ```dart
  /// "Quantité à racheter"
  /// ```
  String get restockAmount => """Quantité à racheter""";

  /// ```dart
  /// "p. ex. sachet de 1 kg"
  /// ```
  String get restockPlaceholder => """p. ex. sachet de 1 kg""";

  /// ```dart
  /// "Converti : niveau $level, quantité à racheter « $amount »."
  /// ```
  String convertedLevelAmount(String level, String amount) =>
      """Converti : niveau $level, quantité à racheter « $amount ».""";

  /// ```dart
  /// "Converti : niveau $level."
  /// ```
  String convertedLevel(String level) => """Converti : niveau $level.""";

  /// ```dart
  /// "Converti : disponible « $onHand », objectif « $target »."
  /// ```
  String convertedCount(String onHand, String target) =>
      """Converti : disponible « $onHand », objectif « $target ».""";

  /// ```dart
  /// "Converti : objectif « $target ». Saisissez la quantité disponible."
  /// ```
  String convertedTargetOnly(String target) =>
      """Converti : objectif « $target ». Saisissez la quantité disponible.""";

  /// ```dart
  /// "Converti en quantité. Saisissez la quantité disponible et un objectif."
  /// ```
  String get convertedBlank =>
      """Converti en quantité. Saisissez la quantité disponible et un objectif.""";

  /// ```dart
  /// "Périmé : acheter $amount."
  /// ```
  String statusExpiredBuy(String amount) => """Périmé : acheter $amount.""";

  /// ```dart
  /// "Périmé."
  /// ```
  String get statusExpired => """Périmé.""";

  /// ```dart
  /// "Bientôt périmé : acheter $amount."
  /// ```
  String statusExpiringBuy(String amount) =>
      """Bientôt périmé : acheter $amount.""";

  /// ```dart
  /// "Bientôt périmé."
  /// ```
  String get statusExpiring => """Bientôt périmé.""";

  /// ```dart
  /// "Bas : acheter $amount."
  /// ```
  String statusLowBuy(String amount) => """Bas : acheter $amount.""";

  /// ```dart
  /// "Bas."
  /// ```
  String get statusLow => """Bas.""";

  /// ```dart
  /// "Épuisé : acheter $amount."
  /// ```
  String statusOutBuy(String amount) => """Épuisé : acheter $amount.""";

  /// ```dart
  /// "Épuisé."
  /// ```
  String get statusOut => """Épuisé.""";

  /// ```dart
  /// "Non compté : l’objectif n’a pas de nombre, il n’est donc jamais bas."
  /// ```
  String get statusUncountedTarget =>
      """Non compté : l’objectif n’a pas de nombre, il n’est donc jamais bas.""";

  /// ```dart
  /// "Non compté : la quantité disponible n’a pas de nombre, il n’est donc jamais bas."
  /// ```
  String get statusUncountedOnHand =>
      """Non compté : la quantité disponible n’a pas de nombre, il n’est donc jamais bas.""";

  /// ```dart
  /// "En stock."
  /// ```
  String get statusInStock => """En stock.""";

  /// ```dart
  /// "Sans mode de stock choisi, il utilise celui de l’inventaire par défaut."
  /// ```
  String get templateDefaultMode =>
      """Sans mode de stock choisi, il utilise celui de l’inventaire par défaut.""";

  /// ```dart
  /// "Ajouté à un inventaire, il démarre plein avec $amount disponible."
  /// ```
  String templateStartsCount(String amount) =>
      """Ajouté à un inventaire, il démarre plein avec $amount disponible.""";

  /// ```dart
  /// "Ajouté à un inventaire, il démarre Plein et se réapprovisionne de $amount."
  /// ```
  String templateStartsLevelAmount(String amount) =>
      """Ajouté à un inventaire, il démarre Plein et se réapprovisionne de $amount.""";

  /// ```dart
  /// "Ajouté à un inventaire, il démarre Plein."
  /// ```
  String get templateStartsLevel =>
      """Ajouté à un inventaire, il démarre Plein.""";

  /// ```dart
  /// "Ajouté à un inventaire sans objectif, il n’est pas compté."
  /// ```
  String get templateUncounted =>
      """Ajouté à un inventaire sans objectif, il n’est pas compté.""";
}

class ExpiryStockMessagesFr extends ExpiryStockMessages {
  final StockMessagesFr _parent;
  const ExpiryStockMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Péremption"
  /// ```
  String get title => """Péremption""";

  /// ```dart
  /// "Comment l’article se périme"
  /// ```
  String get mode => """Comment l’article se périme""";

  /// ```dart
  /// "Aucune"
  /// ```
  String get none => """Aucune""";

  /// ```dart
  /// "Date"
  /// ```
  String get date => """Date""";

  /// ```dart
  /// "Se conserve N jours"
  /// ```
  String get keeps => """Se conserve N jours""";

  /// ```dart
  /// "Date de péremption"
  /// ```
  String get expiryDate => """Date de péremption""";

  /// ```dart
  /// "Jours de conservation"
  /// ```
  String get daysItKeeps => """Jours de conservation""";

  /// ```dart
  /// "Périmé le $date."
  /// ```
  String expiredSummary(String date) => """Périmé le $date.""";

  /// ```dart
  /// "Bon jusqu’au $date."
  /// ```
  String goodUntilSummary(String date) => """Bon jusqu’au $date.""";

  /// ```dart
  /// "${_plural(count, one: 'Chaque réapprovisionnement la repousse à 1 jour à partir de ce jour.', many: 'Chaque réapprovisionnement la repousse à $count jours à partir de ce jour.')}"
  /// ```
  String renews(int count) =>
      """${_plural(count, one: 'Chaque réapprovisionnement la repousse à 1 jour à partir de ce jour.', many: 'Chaque réapprovisionnement la repousse à $count jours à partir de ce jour.')}""";

  /// ```dart
  /// "${_plural(count, one: 'Ajouté à un inventaire, il périme 1 jour plus tard.', many: 'Ajouté à un inventaire, il périme $count jours plus tard.')}"
  /// ```
  String templateExpires(int count) =>
      """${_plural(count, one: 'Ajouté à un inventaire, il périme 1 jour plus tard.', many: 'Ajouté à un inventaire, il périme $count jours plus tard.')}""";

  /// ```dart
  /// "Péremption"
  /// ```
  String get chip => """Péremption""";

  /// ```dart
  /// "Périme le $date"
  /// ```
  String chipExpires(String date) => """Périme le $date""";

  /// ```dart
  /// "Périmé le $date"
  /// ```
  String chipExpired(String date) => """Périmé le $date""";

  /// ```dart
  /// "${_plural(count, one: 'Se conserve 1 jour', many: 'Se conserve $count jours')}"
  /// ```
  String chipKeeps(int count) =>
      """${_plural(count, one: 'Se conserve 1 jour', many: 'Se conserve $count jours')}""";
}

class ComposeStockMessagesFr extends ComposeStockMessages {
  final StockMessagesFr _parent;
  const ComposeStockMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Stock"
  /// ```
  String get chip => """Stock""";

  /// ```dart
  /// "Quantité"
  /// ```
  String get count => """Quantité""";

  /// ```dart
  /// "Niveau"
  /// ```
  String get level => """Niveau""";

  /// ```dart
  /// "Niveau · $amount"
  /// ```
  String levelAmount(String amount) => """Niveau · $amount""";

  /// ```dart
  /// "Objectif : $target"
  /// ```
  String targetValue(String target) => """Objectif : $target""";

  /// ```dart
  /// "Plein si vide"
  /// ```
  String get fullWhenEmpty => """Plein si vide""";
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
  /// "Sélectionner des notes"
  /// ```
  String get selectNotes => """Sélectionner des notes""";

  /// ```dart
  /// "${_plural(count, one: '1 sélectionnée', many: '$count sélectionnées')}"
  /// ```
  String selected(int count) =>
      """${_plural(count, one: '1 sélectionnée', many: '$count sélectionnées')}""";

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
  /// "Importer vers une liste"
  /// ```
  String get importToList => """Importer vers une liste""";

  /// ```dart
  /// "Aucune liste disponible pour l'importation."
  /// ```
  String get importNoLists => """Aucune liste disponible pour l'importation.""";

  /// ```dart
  /// "Synchronisée avec ${path}"
  /// ```
  String syncedToFile(String path) => """Synchronisée avec ${path}""";

  /// ```dart
  /// "Le fichier synchronisé est introuvable"
  /// ```
  String get syncedFileMissing => """Le fichier synchronisé est introuvable""";

  /// ```dart
  /// "Synchronisée ${when}"
  /// ```
  String syncedAt(String when) => """Synchronisée ${when}""";

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
  /// "${_plural(count, one: 'Pas de connexion — la photo sera envoyée dès votre retour en ligne.', many: 'Pas de connexion — $count photos seront envoyées dès votre retour en ligne.')}"
  /// ```
  String queuedOffline(int count) =>
      """${_plural(count, one: 'Pas de connexion — la photo sera envoyée dès votre retour en ligne.', many: 'Pas de connexion — $count photos seront envoyées dès votre retour en ligne.')}""";

  /// ```dart
  /// "En attente d'une connexion"
  /// ```
  String get waitingForConnection => """En attente d'une connexion""";

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
  /// "Sélectionner des photos"
  /// ```
  String get selectPhotos => """Sélectionner des photos""";

  /// ```dart
  /// "${_plural(count, one: '1 sélectionnée', many: '$count sélectionnées')}"
  /// ```
  String selected(int count) =>
      """${_plural(count, one: '1 sélectionnée', many: '$count sélectionnées')}""";

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
  /// "Rejoindre"
  /// ```
  String get join => """Rejoindre""";

  /// ```dart
  /// "${name} fait les courses"
  /// ```
  String bannerHousemateShopping(String name) => """${name} fait les courses""";

  /// ```dart
  /// "${name} fait les courses à ${store}"
  /// ```
  String bannerHousemateShoppingAt(String name, String store) =>
      """${name} fait les courses à ${store}""";

  /// ```dart
  /// "${_plural(count, one: '$name et 1 autre personne font les courses', many: '$name et $count autres personnes font les courses')}"
  /// ```
  String bannerHousematesShopping(String name, int count) =>
      """${_plural(count, one: '$name et 1 autre personne font les courses', many: '$name et $count autres personnes font les courses')}""";

  /// ```dart
  /// "Rejoindre ces courses ?"
  /// ```
  String get joinConfirmTitle => """Rejoindre ces courses ?""";

  /// ```dart
  /// "Vos courses en cours seront terminées et enregistrées dans votre historique, puis vous rejoindrez ${name}."
  /// ```
  String joinConfirmBody(String name) =>
      """Vos courses en cours seront terminées et enregistrées dans votre historique, puis vous rejoindrez ${name}.""";

  /// ```dart
  /// "Terminer les miennes et rejoindre"
  /// ```
  String get endMineAndJoin => """Terminer les miennes et rejoindre""";

  /// ```dart
  /// "Impossible de rejoindre les courses."
  /// ```
  String get joinFailed => """Impossible de rejoindre les courses.""";

  /// ```dart
  /// "Quitter les courses"
  /// ```
  String get leaveTrip => """Quitter les courses""";

  /// ```dart
  /// "Impossible de quitter les courses."
  /// ```
  String get leaveTripFailed => """Impossible de quitter les courses.""";

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
  /// "Tout acheter en une fois"
  /// ```
  String get shopAllStores => """Tout acheter en une fois""";

  /// ```dart
  /// "Cette option regroupe tous les magasins dans un seul onglet pour tout acheter d'un coup"
  /// ```
  String get shopAllStoresHint =>
      """Cette option regroupe tous les magasins dans un seul onglet pour tout acheter d'un coup""";

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
  /// "Activez ou désactivez les magasins pour lesquels vous faites les courses."
  /// ```
  String get storesHintAll =>
      """Activez ou désactivez les magasins pour lesquels vous faites les courses.""";

  /// ```dart
  /// "Tous les articles"
  /// ```
  String get allItems => """Tous les articles""";

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
  /// "Articles à acheter"
  /// ```
  String get itemsToShop => """Articles à acheter""";

  /// ```dart
  /// "${_plural(count, one: '1 article, tous', many: 'Les $count articles')}"
  /// ```
  String allItemsPicked(int count) =>
      """${_plural(count, one: '1 article, tous', many: 'Les $count articles')}""";

  /// ```dart
  /// "$picked article(s) sur $total"
  /// ```
  String someItemsPicked(int picked, int total) =>
      """$picked article(s) sur $total""";

  /// ```dart
  /// "Inverser"
  /// ```
  String get selectInvert => """Inverser""";

  /// ```dart
  /// "Les listes sélectionnées n'ont plus rien à acheter."
  /// ```
  String get noItemsToShop =>
      """Les listes sélectionnées n'ont plus rien à acheter.""";

  /// ```dart
  /// "Choisissez au moins un article à acheter."
  /// ```
  String get pickAtLeastOneItem =>
      """Choisissez au moins un article à acheter.""";

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
  /// "Vous faites les courses avec une autre personne du foyer."
  /// ```
  String get tripWithHousemate =>
      """Vous faites les courses avec une autre personne du foyer.""";

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
  /// "Ces courses ont été terminées."
  /// ```
  String get tripFinishedByHousemate => """Ces courses ont été terminées.""";

  /// ```dart
  /// "${_plural(count, one: 'Courses avec 1 personne', many: 'Courses avec $count personnes')}"
  /// ```
  String shoppingWith(int count) =>
      """${_plural(count, one: 'Courses avec 1 personne', many: 'Courses avec $count personnes')}""";

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
  /// "Retirés ($count)"
  /// ```
  String removedSection(int count) => """Retirés ($count)""";

  /// ```dart
  /// "Restaurer"
  /// ```
  String get restore => """Restaurer""";

  /// ```dart
  /// "Impossible de restaurer l'article."
  /// ```
  String get restoreFailed => """Impossible de restaurer l'article.""";

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
  /// "Modifier les totaux des courses"
  /// ```
  String get editTotalsTitle => """Modifier les totaux des courses""";

  /// ```dart
  /// "Modifier les totaux"
  /// ```
  String get editTotals => """Modifier les totaux""";

  /// ```dart
  /// "Terminé"
  /// ```
  String get doneEditing => """Terminé""";

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
  /// "Supprimer la course"
  /// ```
  String get deleteTrip => """Supprimer la course""";

  /// ```dart
  /// "Supprimer la course"
  /// ```
  String get deleteTripTitle => """Supprimer la course""";

  /// ```dart
  /// "Cette course et ses totaux seront définitivement supprimés de l'historique des courses. Cette action est irréversible."
  /// ```
  String get deleteTripBody =>
      """Cette course et ses totaux seront définitivement supprimés de l'historique des courses. Cette action est irréversible.""";

  /// ```dart
  /// "Impossible de supprimer la course."
  /// ```
  String get deleteTripFailed => """Impossible de supprimer la course.""";

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
  /// "Jours du mois"
  /// ```
  String get monthlyModeDays => """Jours du mois""";

  /// ```dart
  /// "Un jour de la semaine du mois"
  /// ```
  String get monthlyModeWeekday => """Un jour de la semaine du mois""";

  /// ```dart
  /// "Laissez vide pour répéter le même jour chaque mois"
  /// ```
  String get monthDaysHint =>
      """Laissez vide pour répéter le même jour chaque mois""";

  /// ```dart
  /// "Date"
  /// ```
  String get yearlyDate => """Date""";

  /// ```dart
  /// "Laissez vide pour répéter à la même date chaque année"
  /// ```
  String get yearlyDateHint =>
      """Laissez vide pour répéter à la même date chaque année""";

  /// ```dart
  /// "Choisir une date"
  /// ```
  String get pickDate => """Choisir une date""";

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
  /// "le $days"
  /// ```
  String onTheDays(String days) => """le $days""";

  /// ```dart
  /// "${_plural(count, one: 'le jour $days', many: 'les jours $days')}"
  /// ```
  String onMonthDays(int count, String days) =>
      """${_plural(count, one: 'le jour $days', many: 'les jours $days')}""";

  /// ```dart
  /// "le $date"
  /// ```
  String onYearlyDate(String date) => """le $date""";

  /// ```dart
  /// "$ordinal $day"
  /// ```
  String ordinalDay(String ordinal, String day) => """$ordinal $day""";

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
  OrdinalRecurrenceMessagesFr get ordinal => OrdinalRecurrenceMessagesFr(this);
  OrdinalInlineRecurrenceMessagesFr get ordinalInline =>
      OrdinalInlineRecurrenceMessagesFr(this);
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

class OrdinalRecurrenceMessagesFr extends OrdinalRecurrenceMessages {
  final RecurrenceMessagesFr _parent;
  const OrdinalRecurrenceMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Premier"
  /// ```
  String get first => """Premier""";

  /// ```dart
  /// "Deuxième"
  /// ```
  String get second => """Deuxième""";

  /// ```dart
  /// "Troisième"
  /// ```
  String get third => """Troisième""";

  /// ```dart
  /// "Quatrième"
  /// ```
  String get fourth => """Quatrième""";

  /// ```dart
  /// "Dernier"
  /// ```
  String get last => """Dernier""";
}

class OrdinalInlineRecurrenceMessagesFr
    extends OrdinalInlineRecurrenceMessages {
  final RecurrenceMessagesFr _parent;
  const OrdinalInlineRecurrenceMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "premier"
  /// ```
  String get first => """premier""";

  /// ```dart
  /// "deuxième"
  /// ```
  String get second => """deuxième""";

  /// ```dart
  /// "troisième"
  /// ```
  String get third => """troisième""";

  /// ```dart
  /// "quatrième"
  /// ```
  String get fourth => """quatrième""";

  /// ```dart
  /// "dernier"
  /// ```
  String get last => """dernier""";
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
  /// "Impossible d'enregistrer « ${name} » : le serveur a refusé la modification (${status})."
  /// ```
  String refusedNamed(String name, int status) =>
      """Impossible d'enregistrer « ${name} » : le serveur a refusé la modification (${status}).""";

  /// ```dart
  /// "Impossible d'enregistrer une modification : le serveur l'a refusée (${status})."
  /// ```
  String refusedOne(int status) =>
      """Impossible d'enregistrer une modification : le serveur l'a refusée (${status}).""";

  /// ```dart
  /// "Impossible d'enregistrer ${count} modifications : le serveur les a refusées (${status})."
  /// ```
  String refusedMany(int count, int status) =>
      """Impossible d'enregistrer ${count} modifications : le serveur les a refusées (${status}).""";

  /// ```dart
  /// "Impossible d'enregistrer « ${name} » : le serveur a échoué à plusieurs reprises."
  /// ```
  String failedNamed(String name) =>
      """Impossible d'enregistrer « ${name} » : le serveur a échoué à plusieurs reprises.""";

  /// ```dart
  /// "Impossible d'enregistrer une modification : le serveur a échoué à plusieurs reprises."
  /// ```
  String get failedOne =>
      """Impossible d'enregistrer une modification : le serveur a échoué à plusieurs reprises.""";

  /// ```dart
  /// "Impossible d'enregistrer ${count} modifications : le serveur a échoué à plusieurs reprises."
  /// ```
  String failedMany(int count) =>
      """Impossible d'enregistrer ${count} modifications : le serveur a échoué à plusieurs reprises.""";

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

  /// ```dart
  /// "Insérer un tableau"
  /// ```
  String get insertTable => """Insérer un tableau""";

  /// ```dart
  /// "Colonnes"
  /// ```
  String get tableColumns => """Colonnes""";

  /// ```dart
  /// "Lignes"
  /// ```
  String get tableRows => """Lignes""";

  /// ```dart
  /// "Colonne $n"
  /// ```
  String tableColumnHeader(int n) => """Colonne $n""";

  /// ```dart
  /// "Insérer"
  /// ```
  String get insert => """Insérer""";

  /// ```dart
  /// "Ajouter une ligne"
  /// ```
  String get addTableRow => """Ajouter une ligne""";

  /// ```dart
  /// "Ajouter une colonne"
  /// ```
  String get addTableColumn => """Ajouter une colonne""";

  /// ```dart
  /// "Supprimer la ligne"
  /// ```
  String get removeTableRow => """Supprimer la ligne""";

  /// ```dart
  /// "Supprimer la colonne"
  /// ```
  String get removeTableColumn => """Supprimer la colonne""";

  /// ```dart
  /// "Supprimer le tableau"
  /// ```
  String get deleteTable => """Supprimer le tableau""";

  /// ```dart
  /// "Modifier le tableau"
  /// ```
  String get editTable => """Modifier le tableau""";

  /// ```dart
  /// "Terminé"
  /// ```
  String get doneEditingTable => """Terminé""";
}

class WearMessagesFr extends WearMessages {
  final MessagesFr _parent;
  const WearMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Connecté en tant que ${name}"
  /// ```
  String signedInAs(String name) => """Connecté en tant que ${name}""";

  /// ```dart
  /// "Connectez-vous sur votre téléphone"
  /// ```
  String get notSignedIn => """Connectez-vous sur votre téléphone""";

  /// ```dart
  /// "Changer de liste"
  /// ```
  String get changeList => """Changer de liste""";

  /// ```dart
  /// "Parcours"
  /// ```
  String get progression => """Parcours""";

  /// ```dart
  /// "Fait"
  /// ```
  String get done => """Fait""";

  /// ```dart
  /// "Retirés"
  /// ```
  String get skipped => """Retirés""";

  /// ```dart
  /// "Compte"
  /// ```
  String get account => """Compte""";

  /// ```dart
  /// "Marquer comme fait"
  /// ```
  String get markDone => """Marquer comme fait""";

  /// ```dart
  /// "Marquer comme à faire"
  /// ```
  String get markUndone => """Marquer comme à faire""";

  /// ```dart
  /// "Récurrence"
  /// ```
  String get repeats => """Récurrence""";

  /// ```dart
  /// "Ouvrir sur le téléphone"
  /// ```
  String get openOnPhone => """Ouvrir sur le téléphone""";

  /// ```dart
  /// "Regardez votre téléphone"
  /// ```
  String get openedOnPhone => """Regardez votre téléphone""";

  /// ```dart
  /// "Téléphone injoignable"
  /// ```
  String get openOnPhoneFailed => """Téléphone injoignable""";

  /// ```dart
  /// "Ajouté par"
  /// ```
  String get addedBy => """Ajouté par""";

  /// ```dart
  /// "Ajouté"
  /// ```
  String get added => """Ajouté""";

  /// ```dart
  /// "Mis à jour"
  /// ```
  String get updated => """Mis à jour""";

  /// ```dart
  /// "Tâches"
  /// ```
  String get tasks => """Tâches""";

  /// ```dart
  /// "$count en attente"
  /// ```
  String queued(int count) => """$count en attente""";

  /// ```dart
  /// "Rien à cocher"
  /// ```
  String get nothingToCheckOff => """Rien à cocher""";

  /// ```dart
  /// "Rien de retiré"
  /// ```
  String get nothingRemoved => """Rien de retiré""";

  /// ```dart
  /// "$count restants"
  /// ```
  String tasksLeft(int count) => """$count restants""";

  /// ```dart
  /// "Tout est fait"
  /// ```
  String get allTasksDone => """Tout est fait""";

  /// ```dart
  /// "Cette note est vide"
  /// ```
  String get emptyNote => """Cette note est vide""";

  /// ```dart
  /// "Aucune liste ici pour l'instant"
  /// ```
  String get noLists => """Aucune liste ici pour l'instant""";

  /// ```dart
  /// "Configurer Pantry"
  /// ```
  String get setupTitle => """Configurer Pantry""";

  /// ```dart
  /// "Connectez-vous depuis votre téléphone — rien à saisir ici."
  /// ```
  String get setupBody =>
      """Connectez-vous depuis votre téléphone — rien à saisir ici.""";

  /// ```dart
  /// "Aucune liaison au téléphone"
  /// ```
  String get setupNoLink => """Aucune liaison au téléphone""";

  /// ```dart
  /// "Cette montre n'atteint aucun téléphone. Pantry en a besoin d'un pour se connecter."
  /// ```
  String get setupNoLinkBody =>
      """Cette montre n'atteint aucun téléphone. Pantry en a besoin d'un pour se connecter.""";

  /// ```dart
  /// "Connectez votre téléphone"
  /// ```
  String get setupNoPhone => """Connectez votre téléphone""";

  /// ```dart
  /// "Rapprochez votre téléphone et laissez cet écran ouvert."
  /// ```
  String get setupNoPhoneBody =>
      """Rapprochez votre téléphone et laissez cet écran ouvert.""";

  /// ```dart
  /// "Connectez-vous d'abord sur votre téléphone"
  /// ```
  String get setupPhoneSignedOut =>
      """Connectez-vous d'abord sur votre téléphone""";

  /// ```dart
  /// "Votre téléphone n'est pas encore connecté à Pantry."
  /// ```
  String get setupPhoneSignedOutBody =>
      """Votre téléphone n'est pas encore connecté à Pantry.""";

  /// ```dart
  /// "Récupération de vos listes"
  /// ```
  String get setupSyncing => """Récupération de vos listes""";

  /// ```dart
  /// "Presque terminé."
  /// ```
  String get setupSyncingBody => """Presque terminé.""";

  /// ```dart
  /// "$count non envoyé(s)"
  /// ```
  String signOutPending(int count) => """$count non envoyé(s)""";

  /// ```dart
  /// "Envoyer d'abord"
  /// ```
  String get signOutWait => """Envoyer d'abord""";

  /// ```dart
  /// "Envoi…"
  /// ```
  String get signOutSending => """Envoi…""";

  /// ```dart
  /// "Se déconnecter quand même"
  /// ```
  String get signOutAnyway => """Se déconnecter quand même""";

  /// ```dart
  /// "Se déconnecter ?"
  /// ```
  String get signOutTitle => """Se déconnecter ?""";

  /// ```dart
  /// "Cette montre oubliera votre maison. Votre téléphone reste connecté."
  /// ```
  String get signOutBody =>
      """Cette montre oubliera votre maison. Votre téléphone reste connecté.""";

  /// ```dart
  /// "Maison"
  /// ```
  String get house => """Maison""";

  /// ```dart
  /// "Aucune maison pour le moment"
  /// ```
  String get noHouses => """Aucune maison pour le moment""";

  /// ```dart
  /// "Affiche ${name}"
  /// ```
  String nowShowing(String name) => """Affiche ${name}""";

  /// ```dart
  /// "Réglages"
  /// ```
  String get settings => """Réglages""";

  /// ```dart
  /// "Actualiser"
  /// ```
  String get refreshInterval => """Actualiser""";

  /// ```dart
  /// "Désactivé"
  /// ```
  String get refreshOff => """Désactivé""";

  /// ```dart
  /// "$count secondes"
  /// ```
  String refreshSeconds(int count) => """$count secondes""";

  /// ```dart
  /// "$count minutes"
  /// ```
  String refreshMinutes(int count) => """$count minutes""";

  /// ```dart
  /// "Tout est enregistré"
  /// ```
  String get allSaved => """Tout est enregistré""";

  /// ```dart
  /// "synchronisé ${when}"
  /// ```
  String syncedAgo(String when) => """synchronisé ${when}""";

  /// ```dart
  /// "à l'instant"
  /// ```
  String get agoJustNow => """à l'instant""";

  /// ```dart
  /// "il y a $count min"
  /// ```
  String agoMinutes(int count) => """il y a $count min""";

  /// ```dart
  /// "il y a $count h"
  /// ```
  String agoHours(int count) => """il y a $count h""";

  /// ```dart
  /// "il y a $count j"
  /// ```
  String agoDays(int count) => """il y a $count j""";

  /// ```dart
  /// "Reconfigurer"
  /// ```
  String get setUpAgain => """Reconfigurer""";

  /// ```dart
  /// "Votre téléphone doit reconnecter cette montre."
  /// ```
  String get sessionExpiredShort =>
      """Votre téléphone doit reconnecter cette montre.""";

  /// ```dart
  /// "Sortie privée"
  /// ```
  String get privateTrip => """Sortie privée""";

  /// ```dart
  /// "Connexion nécessaire"
  /// ```
  String get needsConnection => """Connexion nécessaire""";

  /// ```dart
  /// "Wi-Fi requis pour le serveur"
  /// ```
  String get needsWifi => """Wi-Fi requis pour le serveur""";

  /// ```dart
  /// "Choisis d’abord une liste"
  /// ```
  String get pickAList => """Choisis d’abord une liste""";

  /// ```dart
  /// "$count sélectionnées"
  /// ```
  String nSelected(int count) => """$count sélectionnées""";

  /// ```dart
  /// "Pas encore de magasins"
  /// ```
  String get noStoresHere => """Pas encore de magasins""";

  /// ```dart
  /// "Ici"
  /// ```
  String get hereNow => """Ici""";

  /// ```dart
  /// "Ensuite : ${store}"
  /// ```
  String nextIs(String store) => """Ensuite : ${store}""";

  /// ```dart
  /// "Impossible de passer au suivant"
  /// ```
  String get advanceFailed => """Impossible de passer au suivant""";

  /// ```dart
  /// "Impossible de terminer la sortie"
  /// ```
  String get finishFailed => """Impossible de terminer la sortie""";

  /// ```dart
  /// "Lancer la mienne"
  /// ```
  String get startMyOwn => """Lancer la mienne""";

  /// ```dart
  /// "$name +$count"
  /// ```
  String plusOthers(String name, int count) => """$name +$count""";

  /// ```dart
  /// "Impossible de rejoindre"
  /// ```
  String get joinFailed => """Impossible de rejoindre""";

  /// ```dart
  /// "Sortie partagée"
  /// ```
  String get sharedTrip => """Sortie partagée""";

  /// ```dart
  /// "La sortie continue pour les autres."
  /// ```
  String get leaveTripBody => """La sortie continue pour les autres.""";

  /// ```dart
  /// "Impossible de quitter"
  /// ```
  String get leaveFailed => """Impossible de quitter""";

  /// ```dart
  /// "${_plural(count, one: '1 acheté', many: '$count achetés')}"
  /// ```
  String boughtTally(int count) =>
      """${_plural(count, one: '1 acheté', many: '$count achetés')}""";

  /// ```dart
  /// "${_plural(count, one: '1 magasin', many: '$count magasins')}"
  /// ```
  String storeTally(int count) =>
      """${_plural(count, one: '1 magasin', many: '$count magasins')}""";

  /// ```dart
  /// "Non renseigné"
  /// ```
  String get notBilled => """Non renseigné""";

  /// ```dart
  /// "Devise"
  /// ```
  String get currency => """Devise""";

  /// ```dart
  /// "Chiffres uniquement"
  /// ```
  String get notANumber => """Chiffres uniquement""";

  /// ```dart
  /// "Couronne"
  /// ```
  String get crown => """Couronne""";

  /// ```dart
  /// "Faire défiler la liste"
  /// ```
  String get crownScrollsList => """Faire défiler la liste""";

  /// ```dart
  /// "Changer de page"
  /// ```
  String get crownTurnsPages => """Changer de page""";

  /// ```dart
  /// "Annuler"
  /// ```
  String get undoWindow => """Annuler""";

  /// ```dart
  /// "Désactivé"
  /// ```
  String get undoOff => """Désactivé""";

  /// ```dart
  /// "${_plural(count, one: '1 seconde', many: '$count secondes')}"
  /// ```
  String undoSeconds(int count) =>
      """${_plural(count, one: '1 seconde', many: '$count secondes')}""";

  /// ```dart
  /// "Se connecter avec un QR"
  /// ```
  String get qrSignIn => """Se connecter avec un QR""";

  /// ```dart
  /// "Votre serveur"
  /// ```
  String get qrServer => """Votre serveur""";

  /// ```dart
  /// "cloud.example.com"
  /// ```
  String get qrServerHint => """cloud.example.com""";

  /// ```dart
  /// "Afficher le code"
  /// ```
  String get qrShowCode => """Afficher le code""";

  /// ```dart
  /// "Serveur injoignable"
  /// ```
  String get qrUnreachable => """Serveur injoignable""";

  /// ```dart
  /// "Le code a expiré"
  /// ```
  String get qrExpired => """Le code a expiré""";

  /// ```dart
  /// "Recommencer"
  /// ```
  String get qrStartOver => """Recommencer""";

  /// ```dart
  /// "${host} envoie un certificat que cette montre ne peut pas vérifier. Ne l'acceptez que si l'empreinte est celle attendue."
  /// ```
  String certUntrustedBody(String host) =>
      """${host} envoie un certificat que cette montre ne peut pas vérifier. Ne l'acceptez que si l'empreinte est celle attendue.""";

  /// ```dart
  /// "Serveur non vérifié"
  /// ```
  String get certUntrustedShort => """Serveur non vérifié""";

  /// ```dart
  /// "Adresse du serveur modifiée"
  /// ```
  String get serverMovedShort => """Adresse du serveur modifiée""";

  /// ```dart
  /// "Approuver le certificat"
  /// ```
  String get trustCertificate => """Approuver le certificat""";

  /// ```dart
  /// "Faire confiance"
  /// ```
  String get certTrust => """Faire confiance""";

  /// ```dart
  /// "Impossible de lire le certificat du serveur"
  /// ```
  String get certUnreadable =>
      """Impossible de lire le certificat du serveur""";

  /// ```dart
  /// "Notifications"
  /// ```
  String get notifications => """Notifications""";

  /// ```dart
  /// "Autorisées"
  /// ```
  String get notificationsAllowed => """Autorisées""";

  /// ```dart
  /// "Bloquées"
  /// ```
  String get notificationsBlocked => """Bloquées""";

  /// ```dart
  /// "Sortie courses"
  /// ```
  String get shoppingTripChip => """Sortie courses""";

  /// ```dart
  /// "Suivre le téléphone"
  /// ```
  String get followPhone => """Suivre le téléphone""";

  /// ```dart
  /// "Couleur d'accent"
  /// ```
  String get accent => """Couleur d'accent""";

  /// ```dart
  /// "Votre couleur Nextcloud"
  /// ```
  String get accentServer => """Votre couleur Nextcloud""";

  /// ```dart
  /// "Couleur de Pantry"
  /// ```
  String get accentApp => """Couleur de Pantry""";
}

class WatchMessagesFr extends WatchMessages {
  final MessagesFr _parent;
  const WatchMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Montre"
  /// ```
  String get title => """Montre""";

  /// ```dart
  /// "${name} veut se connecter"
  /// ```
  String requestTitle(String name) => """${name} veut se connecter""";

  /// ```dart
  /// "Elle utilisera votre compte ${account} sur ${server}."
  /// ```
  String requestBody(String account, String server) =>
      """Elle utilisera votre compte ${account} sur ${server}.""";

  /// ```dart
  /// "N'autorisez que si la montre est la vôtre. Elle obtient le même accès à votre foyer que ce téléphone."
  /// ```
  String get requestWarning =>
      """N'autorisez que si la montre est la vôtre. Elle obtient le même accès à votre foyer que ce téléphone.""";

  /// ```dart
  /// "Autoriser"
  /// ```
  String get allow => """Autoriser""";

  /// ```dart
  /// "Refuser"
  /// ```
  String get deny => """Refuser""";

  /// ```dart
  /// "Connexion de votre montre"
  /// ```
  String get transferring => """Connexion de votre montre""";

  /// ```dart
  /// "Laissez cet écran ouvert jusqu'à la fin."
  /// ```
  String get transferringBody => """Laissez cet écran ouvert jusqu'à la fin.""";

  /// ```dart
  /// "Votre montre est connectée"
  /// ```
  String get pairedSnack => """Votre montre est connectée""";

  /// ```dart
  /// "Montre injoignable"
  /// ```
  String get pairFailedSnack => """Montre injoignable""";

  /// ```dart
  /// "Ouvrez Pantry sur votre montre et touchez « Ouvrir sur le téléphone ». La demande apparaîtra ici."
  /// ```
  String get waitingBody =>
      """Ouvrez Pantry sur votre montre et touchez « Ouvrir sur le téléphone ». La demande apparaîtra ici.""";

  /// ```dart
  /// "Votre montre est connectée et reste au diapason de ce téléphone."
  /// ```
  String get pairedBody =>
      """Votre montre est connectée et reste au diapason de ce téléphone.""";

  /// ```dart
  /// "Connectée"
  /// ```
  String get pairedStatus => """Connectée""";

  /// ```dart
  /// "Votre montre"
  /// ```
  String get unnamedWatch => """Votre montre""";

  /// ```dart
  /// "Dissocier la montre"
  /// ```
  String get unpair => """Dissocier la montre""";

  /// ```dart
  /// "Déconnecter cette montre et cesser de synchroniser avec elle"
  /// ```
  String get unpairSubtitle =>
      """Déconnecter cette montre et cesser de synchroniser avec elle""";

  /// ```dart
  /// "Dissocier cette montre ?"
  /// ```
  String get unpairTitle => """Dissocier cette montre ?""";

  /// ```dart
  /// "La montre se déconnecte et oublie votre foyer. Vous pourrez la reconfigurer à tout moment."
  /// ```
  String get unpairBody =>
      """La montre se déconnecte et oublie votre foyer. Vous pourrez la reconfigurer à tout moment.""";
}

class WatchTipsMessagesFr extends WatchTipsMessages {
  final MessagesFr _parent;
  const WatchTipsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Astuces"
  /// ```
  String get section => """Astuces""";

  /// ```dart
  /// "De courtes explications sur le fonctionnement de l'app de la montre au poignet."
  /// ```
  String get sectionBody =>
      """De courtes explications sur le fonctionnement de l'app de la montre au poignet.""";

  /// ```dart
  /// "Étape par étape"
  /// ```
  String get stepsLabel => """Étape par étape""";

  /// ```dart
  /// "Configurer votre montre"
  /// ```
  String get pairTitle => """Configurer votre montre""";

  /// ```dart
  /// "Connecter la montre depuis ce téléphone"
  /// ```
  String get pairSubtitle => """Connecter la montre depuis ce téléphone""";

  /// ```dart
  /// "Une montre se prête mal à la saisie d'un mot de passe, elle emprunte donc la connexion de ce téléphone. Rien ne se tape au poignet."
  /// ```
  String get pairBody =>
      """Une montre se prête mal à la saisie d'un mot de passe, elle emprunte donc la connexion de ce téléphone. Rien ne se tape au poignet.""";

  /// ```dart
  /// "Ouvrez Pantry sur votre montre. Un écran de configuration apparaît."
  /// ```
  String get pairStep1 =>
      """Ouvrez Pantry sur votre montre. Un écran de configuration apparaît.""";

  /// ```dart
  /// "Touchez « Ouvrir sur le téléphone ». La montre demande à ce téléphone de prendre le relais."
  /// ```
  String get pairStep2 =>
      """Touchez « Ouvrir sur le téléphone ». La montre demande à ce téléphone de prendre le relais.""";

  /// ```dart
  /// "Déverrouillez ce téléphone et touchez « Autoriser » sur la demande qui s'affiche ici."
  /// ```
  String get pairStep3 =>
      """Déverrouillez ce téléphone et touchez « Autoriser » sur la demande qui s'affiche ici.""";

  /// ```dart
  /// "Laissez cet écran ouvert jusqu'à ce qu'il indique que la montre est connectée."
  /// ```
  String get pairStep4 =>
      """Laissez cet écran ouvert jusqu'à ce qu'il indique que la montre est connectée.""";

  /// ```dart
  /// "Pas de téléphone sous la main ? La montre peut afficher un QR code. Scannez-le avec n'importe quel appareil photo et terminez la connexion dans le navigateur qui s'ouvre."
  /// ```
  String get pairNote =>
      """Pas de téléphone sous la main ? La montre peut afficher un QR code. Scannez-le avec n'importe quel appareil photo et terminez la connexion dans le navigateur qui s'ouvre.""";

  /// ```dart
  /// "Cocher des articles"
  /// ```
  String get itemsTitle => """Cocher des articles""";

  /// ```dart
  /// "Toucher pour cocher, maintenir pour les détails"
  /// ```
  String get itemsSubtitle =>
      """Toucher pour cocher, maintenir pour les détails""";

  /// ```dart
  /// "La ligne au centre de l'écran est celle sur laquelle votre appui agit. Tout ce que vous pouvez faire à un article part de cette ligne."
  /// ```
  String get itemsBody =>
      """La ligne au centre de l'écran est celle sur laquelle votre appui agit. Tout ce que vous pouvez faire à un article part de cette ligne.""";

  /// ```dart
  /// "Touchez la ligne du centre pour la cocher. Touchez-la de nouveau pour la remettre."
  /// ```
  String get itemsStep1 =>
      """Touchez la ligne du centre pour la cocher. Touchez-la de nouveau pour la remettre.""";

  /// ```dart
  /// "Un anneau se vide autour de la ligne tant que le changement peut encore être repris. Touchez de nouveau pendant ce délai et rien n'est écrit."
  /// ```
  String get itemsStep2 =>
      """Un anneau se vide autour de la ligne tant que le changement peut encore être repris. Touchez de nouveau pendant ce délai et rien n'est écrit.""";

  /// ```dart
  /// "Maintenez une ligne pour l'ouvrir. Quantité, prix, catégorie et notes s'y trouvent, avec un bouton qui ouvre l'article sur ce téléphone."
  /// ```
  String get itemsStep3 =>
      """Maintenez une ligne pour l'ouvrir. Quantité, prix, catégorie et notes s'y trouvent, avec un bouton qui ouvre l'article sur ce téléphone.""";

  /// ```dart
  /// "Toucher une ligne qui n'est pas au centre l'y amène simplement. C'est l'appui suivant qui agit, une visée ratée ne coûte donc qu'un défilement."
  /// ```
  String get itemsNote =>
      """Toucher une ligne qui n'est pas au centre l'y amène simplement. C'est l'appui suivant qui agit, une visée ratée ne coûte donc qu'un défilement.""";

  /// ```dart
  /// "Se repérer"
  /// ```
  String get pagesTitle => """Se repérer""";

  /// ```dart
  /// "Balayer entre les pages, balayer pour ressortir"
  /// ```
  String get pagesSubtitle =>
      """Balayer entre les pages, balayer pour ressortir""";

  /// ```dart
  /// "L'app de la montre est une suite de pages plein écran sous un même titre. Il n'y a aucun menu à ouvrir."
  /// ```
  String get pagesBody =>
      """L'app de la montre est une suite de pages plein écran sous un même titre. Il n'y a aucun menu à ouvrir.""";

  /// ```dart
  /// "Balayez latéralement pour passer entre votre liste, le tableau photo, le mur de notes et la page du compte."
  /// ```
  String get pagesStep1 =>
      """Balayez latéralement pour passer entre votre liste, le tableau photo, le mur de notes et la page du compte.""";

  /// ```dart
  /// "Les barres sous le titre indiquent combien il y a de pages et sur laquelle vous êtes."
  /// ```
  String get pagesStep2 =>
      """Les barres sous le titre indiquent combien il y a de pages et sur laquelle vous êtes.""";

  /// ```dart
  /// "Balayez depuis le bord de l'écran pour ressortir de tout ce que vous avez ouvert."
  /// ```
  String get pagesStep3 =>
      """Balayez depuis le bord de l'écran pour ressortir de tout ce que vous avez ouvert.""";

  /// ```dart
  /// "Le titre nomme toujours la page où vous êtes, et la ligne en dessous nomme le groupe auquel appartient la ligne centrale."
  /// ```
  String get pagesNote =>
      """Le titre nomme toujours la page où vous êtes, et la ligne en dessous nomme le groupe auquel appartient la ligne centrale.""";

  /// ```dart
  /// "Changer de liste"
  /// ```
  String get listsTitle => """Changer de liste""";

  /// ```dart
  /// "Touchez le titre en haut"
  /// ```
  String get listsSubtitle => """Touchez le titre en haut""";

  /// ```dart
  /// "Le nom en haut de l'écran est un bouton. Le toucher ouvre les deux choses pour lesquelles on quitte une liste."
  /// ```
  String get listsBody =>
      """Le nom en haut de l'écran est un bouton. Le toucher ouvre les deux choses pour lesquelles on quitte une liste.""";

  /// ```dart
  /// "Touchez le nom de la liste en haut de l'écran."
  /// ```
  String get listsStep1 => """Touchez le nom de la liste en haut de l'écran.""";

  /// ```dart
  /// "Deux boutons se déplient en dessous, « Commencer les courses » et « Changer de liste »."
  /// ```
  String get listsStep2 =>
      """Deux boutons se déplient en dessous, « Commencer les courses » et « Changer de liste ».""";

  /// ```dart
  /// "Touchez « Changer de liste » et choisissez-en une autre, ou « Toutes les listes » pour tout voir d'un coup."
  /// ```
  String get listsStep3 =>
      """Touchez « Changer de liste » et choisissez-en une autre, ou « Toutes les listes » pour tout voir d'un coup.""";

  /// ```dart
  /// "Les boutons se replient d'eux-mêmes au bout de quelques secondes, toucher le titre par erreur ne coûte donc rien."
  /// ```
  String get listsNote =>
      """Les boutons se replient d'eux-mêmes au bout de quelques secondes, toucher le titre par erreur ne coûte donc rien.""";

  /// ```dart
  /// "Faire des courses"
  /// ```
  String get shoppingTitle => """Faire des courses""";

  /// ```dart
  /// "Parcourir les magasins, le téléphone dans la poche"
  /// ```
  String get shoppingSubtitle =>
      """Parcourir les magasins, le téléphone dans la poche""";

  /// ```dart
  /// "Une sortie transforme la montre en compagnon de courses. Les pages deviennent celles dont vous avez besoin dans un rayon, et le foyer peut suivre."
  /// ```
  String get shoppingBody =>
      """Une sortie transforme la montre en compagnon de courses. Les pages deviennent celles dont vous avez besoin dans un rayon, et le foyer peut suivre.""";

  /// ```dart
  /// "Touchez le titre, puis « Commencer les courses ». Choisissez les listes, les magasins, et si vos colocataires voient la sortie."
  /// ```
  String get shoppingStep1 =>
      """Touchez le titre, puis « Commencer les courses ». Choisissez les listes, les magasins, et si vos colocataires voient la sortie.""";

  /// ```dart
  /// "Les pages deviennent la sortie elle-même, une pour l'avancement, une pour la liste, une pour les achats et une pour les articles passés."
  /// ```
  String get shoppingStep2 =>
      """Les pages deviennent la sortie elle-même, une pour l'avancement, une pour la liste, une pour les achats et une pour les articles passés.""";

  /// ```dart
  /// "Cochez au fur et à mesure. Ce que vous passez arrive sur sa propre page et revient sur la liste d'un appui."
  /// ```
  String get shoppingStep3 =>
      """Cochez au fur et à mesure. Ce que vous passez arrive sur sa propre page et revient sur la liste d'un appui.""";

  /// ```dart
  /// "En quittant un magasin, la montre demande ce que la caisse a facturé puis vous emmène au suivant."
  /// ```
  String get shoppingStep4 =>
      """En quittant un magasin, la montre demande ce que la caisse a facturé puis vous emmène au suivant.""";

  /// ```dart
  /// "Après le dernier magasin, « Terminer les courses » affiche le total avant de rien clôturer."
  /// ```
  String get shoppingStep5 =>
      """Après le dernier magasin, « Terminer les courses » affiche le total avant de rien clôturer.""";

  /// ```dart
  /// "Toucher un magasin sur la page d'avancement y emmène la sortie directement, en arrière comme en avant, un détour est donc une correction et non un recommencement."
  /// ```
  String get shoppingNote =>
      """Toucher un magasin sur la page d'avancement y emmène la sortie directement, en arrière comme en avant, un détour est donc une correction et non un recommencement.""";

  /// ```dart
  /// "Tourner la couronne"
  /// ```
  String get crownTitle => """Tourner la couronne""";

  /// ```dart
  /// "Faire défiler la liste, ou tourner les pages"
  /// ```
  String get crownSubtitle =>
      """Faire défiler la liste, ou tourner les pages""";

  /// ```dart
  /// "Tourner la couronne ou la lunette rotative fait défiler la liste devant vous, ce qui garde votre doigt hors de ce que vous lisez."
  /// ```
  String get crownBody =>
      """Tourner la couronne ou la lunette rotative fait défiler la liste devant vous, ce qui garde votre doigt hors de ce que vous lisez.""";

  /// ```dart
  /// "Tournez la couronne pour parcourir la liste ligne par ligne. La ligne où elle s'arrête est celle sur laquelle un appui agit."
  /// ```
  String get crownStep1 =>
      """Tournez la couronne pour parcourir la liste ligne par ligne. La ligne où elle s'arrête est celle sur laquelle un appui agit.""";

  /// ```dart
  /// "Pour qu'un tour change de page à la place, ouvrez « Compte », puis « Réglages », puis « Couronne » sur la montre."
  /// ```
  String get crownStep2 =>
      """Pour qu'un tour change de page à la place, ouvrez « Compte », puis « Réglages », puis « Couronne » sur la montre.""";

  /// ```dart
  /// "Un tour ne fait qu'une chose à la fois. Confier la couronne aux pages veut dire que les listes défilent au doigt seulement."
  /// ```
  String get crownNote =>
      """Un tour ne fait qu'une chose à la fois. Confier la couronne aux pages veut dire que les listes défilent au doigt seulement.""";

  /// ```dart
  /// "Ça marche sans réseau"
  /// ```
  String get offlineTitle => """Ça marche sans réseau""";

  /// ```dart
  /// "Continuez à cocher au rayon frais"
  /// ```
  String get offlineSubtitle => """Continuez à cocher au rayon frais""";

  /// ```dart
  /// "La montre garde sa propre copie de votre foyer, elle s'ouvre et fonctionne donc sans rien à portée. Ni téléphone, ni Wi-Fi, ni forfait data sur la montre."
  /// ```
  String get offlineBody =>
      """La montre garde sa propre copie de votre foyer, elle s'ouvre et fonctionne donc sans rien à portée. Ni téléphone, ni Wi-Fi, ni forfait data sur la montre.""";

  /// ```dart
  /// "Un petit point en haut de l'écran signifie que tout ce que vous avez fait est enregistré."
  /// ```
  String get offlineStep1 =>
      """Un petit point en haut de l'écran signifie que tout ce que vous avez fait est enregistré.""";

  /// ```dart
  /// "Un nuage suivi d'un nombre signifie qu'autant de changements attendent une connexion."
  /// ```
  String get offlineStep2 =>
      """Un nuage suivi d'un nombre signifie qu'autant de changements attendent une connexion.""";

  /// ```dart
  /// "Ils partent tout seuls dès que la montre est de nouveau à portée. Il n'y a rien à appuyer."
  /// ```
  String get offlineStep3 =>
      """Ils partent tout seuls dès que la montre est de nouveau à portée. Il n'y a rien à appuyer.""";

  /// ```dart
  /// "Une liste à un balayage"
  /// ```
  String get tileTitle => """Une liste à un balayage""";

  /// ```dart
  /// "Ajouter la tuile Pantry"
  /// ```
  String get tileSubtitle => """Ajouter la tuile Pantry""";

  /// ```dart
  /// "Les tuiles sont les écrans à côté de votre cadran. Pantry en publie une qui nomme vos listes, pour qu'une liste soit à un balayage plutôt qu'à un lancement d'app."
  /// ```
  String get tileBody =>
      """Les tuiles sont les écrans à côté de votre cadran. Pantry en publie une qui nomme vos listes, pour qu'une liste soit à un balayage plutôt qu'à un lancement d'app.""";

  /// ```dart
  /// "Depuis le cadran, balayez latéralement jusqu'aux tuiles."
  /// ```
  String get tileStep1 =>
      """Depuis le cadran, balayez latéralement jusqu'aux tuiles.""";

  /// ```dart
  /// "Maintenez appuyé, touchez le plus, et choisissez Pantry dans la liste."
  /// ```
  String get tileStep2 =>
      """Maintenez appuyé, touchez le plus, et choisissez Pantry dans la liste.""";

  /// ```dart
  /// "Touchez une liste sur la tuile pour ouvrir l'app directement dessus."
  /// ```
  String get tileStep3 =>
      """Touchez une liste sur la tuile pour ouvrir l'app directement dessus.""";
}

Map<String, String> get messagesFrMap => {
  """common.appTitle""": """Pantry""",
  """common.add""": """Ajouter""",
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
  """common.dismiss""": """Masquer""",
  """common.remove""": """Retirer""",
  """common.clear""": """Effacer""",
  """common.more""": """Plus""",
  """common.sort""": """Trier""",
  """common.permissionDenied""":
      """Vous n'avez pas la permission de faire cela""",
  """common.noAccessTitle""": """Aucun accès""",
  """common.noAccessBody""":
      """Vous n'avez encore accès à rien dans ce foyer. Un administrateur peut vous accorder des autorisations dans l'application web Pantry.""",
  """common.sessionExpiredTitle""": """Connexion expirée""",
  """common.sessionExpiredBody""":
      """Le serveur n'accepte plus votre connexion. Vos données sont toujours là, et toute modification attendra que vous vous reconnectiez.""",
  """common.signInAgain""": """Se reconnecter""",
  """common.serverMovedTitle""": """L'adresse du serveur a changé""",
  """common.serverMovedUnknownBody""":
      """Votre serveur redirige les modifications vers une autre adresse, elles ne peuvent donc pas être enregistrées. Elles attendent ici jusqu'à ce que vous vous reconnectiez avec l'adresse actuelle du serveur.""",
  """common.useNewAddress""": """Utiliser la nouvelle adresse""",
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
  """nav.checklist""": """Liste""",
  """nav.lists""": """Listes""",
  """nav.list""": """Liste""",
  """nav.photoBoard""": """Tableau photos""",
  """nav.notesWall""": """Mur de notes""",
  """widget.chooseListsTitle""": """Choisir les listes""",
  """widget.chooseListsSubtitle""":
      """Choisis les listes affichées par ce widget.""",
  """widget.chooseListTitle""": """Choisir une liste""",
  """widget.chooseListSubtitle""":
      """Choisis la liste affichée par ce widget.""",
  """widget.noLists""": """Aucune liste disponible.""",
  """widget.hideCheckbox""": """Masquer les cases à cocher""",
  """widget.hideCheckboxBody""":
      """Touche un élément pour le cocher. Touche l'emplacement de la case pour ouvrir l'élément.""",
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
      """Touche le champ en bas pour saisir un nouvel élément, puis associe-lui une catégorie, une quantité, une récurrence ou une photo via les chips au-dessus.""",
  """onboarding.mockComposeListName""": """Courses""",
  """onboarding.progressHeroTitle""": """Masquer la carte de progression""",
  """onboarding.progressHeroBody""":
      """Pas besoin de l'anneau de progression en haut ? Balaie-le pour le retirer.""",
  """onboarding.progressHeroHint""": """Balaie pour masquer""",
  """onboarding.progressHeroDismissTitle""":
      """Masque la carte de progression""",
  """onboarding.progressHeroDismissBody""":
      """Tu n'as pas besoin de l'anneau de progression en haut ? Clique sur le X de la carte pour la masquer.""",
  """onboarding.widgetListsTitle""": """Choisis les listes de ton widget""",
  """onboarding.widgetListsBody""":
      """Ajoute le widget Pantry à ton écran d'accueil pour voir d'un coup d'œil combien d'articles restent sur chaque liste — sans ouvrir l'app.""",
  """onboarding.widgetListsActionLabel""": """Choisir les listes""",
  """onboarding.widgetListsWidgetTitle""": """Pantry""",
  """onboarding.widgetListsWidgetEmpty""": """Tout est fait""",
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
  """onboarding.categoryScopeTitle""": """Des catégories par liste""",
  """onboarding.categoryScopeBody""":
      """Gardez une catégorie sur une seule liste, ou rendez-la globale pour qu'elle apparaisse sur toutes les listes. Les nouvelles catégories restent globales sauf si vous choisissez une liste.""",
  """onboarding.categoryScopeGlobalCaption""":
      """Apparaît sur toutes les listes""",
  """onboarding.categoryScopeScopedCaption""":
      """Apparaît sur cette liste uniquement""",
  """onboarding.customFieldsTitle""": """Vos propres champs""",
  """onboarding.customFieldsBody""":
      """Notez les détails qui comptent pour vous : une date de péremption, un rayon, une taille. Créez un champ une fois pour toute la maison ou pour une seule liste, et il apparaît sur chaque article.""",
  """onboarding.customFieldsMockExpiry""": """Péremption""",
  """onboarding.customFieldsMockExpiryValue""": """12 sept.""",
  """onboarding.customFieldsMockAisle""": """Rayon""",
  """onboarding.customFieldsMockAisleValue""": """Produits laitiers""",
  """onboarding.customFieldsTypesCaption""":
      """Choisissez le type qui correspond à ce que vous notez.""",
  """onboarding.watchTitle""": """Pantry à votre poignet""",
  """onboarding.watchBody""":
      """Il existe une app Wear OS. Vos listes, vos notes et le tableau photo sur la montre, sans le moindre réseau — et des courses que vous pouvez faire avec le téléphone dans la poche.""",
  """onboarding.joinTripTitle""": """Faites les courses ensemble""",
  """onboarding.joinTripBody""":
      """Quand quelqu'un de votre foyer est en train de faire les courses, une bannière vous propose ses courses plutôt qu'une seconde liste à vous. Vous les faites ensemble : ce que l'un coche disparaît pour l'autre.""",
  """onboarding.joinTripMockHousemate""": """Dana""",
  """onboarding.joinTripHow""":
      """Déjà en courses ? Rejoindre enregistre d'abord les vôtres dans votre historique. Si vous quittez des courses que vous avez rejointes, elles continuent pour ceux qui y restent.""",
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
  """settings.generalSectionBody""": """Langue, thème et couleurs""",
  """settings.interfaceSection""": """Interface""",
  """settings.interfaceSectionBody""":
      """Navigation, listes et actions sur les éléments""",
  """settings.interfaceNavigationSection""": """Navigation""",
  """settings.interfaceListsSection""": """Listes""",
  """settings.interfaceItemActionsSection""": """Actions sur les éléments""",
  """settings.interfaceAddingSection""": """Ajout d'éléments""",
  """settings.interfaceBarcodeSection""": """Lecture de codes-barres""",
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
  """settings.composeBarPosition""": """Position de la barre d'ajout""",
  """settings.composeBarPositionBody""":
      """Sur quel bord de la liste se place la barre d'ajout d'articles.""",
  """settings.composeBarPositionNames.bottom""": """Bas""",
  """settings.composeBarPositionNames.top""": """Haut""",
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
  """settings.startShoppingButton""": """Bouton « Commencer les courses »""",
  """settings.startShoppingButtonBody""":
      """Affiche le bouton flottant « Commencer les courses » sur l'écran des listes. Désactivé, il passe dans le menu.""",
  """settings.listMenuStyle""": """Style du menu de liste""",
  """settings.listMenuStyleBody""":
      """Comment le menu de liste présente ses actions : une grille de catégories, ou une seule liste avec toutes les actions.""",
  """settings.listMenuStyleNames.grid""": """Grille""",
  """settings.listMenuStyleNames.list""": """Liste""",
  """settings.truncateItemNames""": """Tronquer les noms d'articles longs""",
  """settings.truncateItemNamesBody""":
      """Garde chaque nom d'article sur une seule ligne, se terminant par des points de suspension. Désactivé, les noms longs passent sur plusieurs lignes.""",
  """settings.itemDescription""": """Description sur les articles""",
  """settings.itemDescriptionBody""":
      """Où la description d'un article apparaît sur sa ligne. Une description trop longue se termine par des points de suspension dans les deux cas.""",
  """settings.itemDescriptionNames.off""": """Icône de note seule""",
  """settings.itemDescriptionNames.line""": """Sur sa propre ligne""",
  """settings.itemDescriptionNames.chip""": """Dans l'étiquette de note""",
  """settings.reuseExistingItems""":
      """Réutiliser les articles existants lors de l'ajout""",
  """settings.reuseExistingItemsBody""":
      """Lorsque vous ajoutez un article qui existe déjà dans la liste, réutiliser cet article.""",
  """settings.reuseExistingItemsNames.ask""": """Toujours demander""",
  """settings.reuseExistingItemsNames.reuse""": """Toujours réutiliser""",
  """settings.reuseExistingItemsNames.never""": """Ne jamais réutiliser""",
  """settings.suggestArchivedItems""": """Suggérer les articles archivés""",
  """settings.suggestArchivedItemsBody""":
      """Lors de l'ajout d'un article, rechercher aussi des suggestions de réutilisation parmi les articles archivés. Réutiliser un article archivé le désarchive.""",
  """settings.barcodeFillName""": """Remplir le nom""",
  """settings.barcodeFillNameBody""":
      """Utiliser le nom du produit d'un code-barres scanné comme nom de l'article.""",
  """settings.barcodeFillCategory""": """Remplir la catégorie""",
  """settings.barcodeFillCategoryBody""":
      """Choisir la catégorie la plus proche pour un produit scanné.""",
  """settings.barcodeFillImage""": """Remplir l'image""",
  """settings.barcodeFillImageBody""":
      """Joindre à l'article la photo du produit d'un code-barres scanné.""",
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
  """settings.chipNames.label""": """Étiquette""",
  """settings.chipNames.quantity""": """Quantité""",
  """settings.chipNames.price""": """Prix""",
  """settings.chipNames.note""": """Description""",
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
  """settings.syncLastHouse""": """Synchroniser la maison ouverte""",
  """settings.syncLastHouseBody""":
      """Ouvre la maison que vous avez utilisée en dernier sur n'importe quel appareil, et laisse l'application web et vos autres appareils suivre celui-ci. Désactivez pour garder ici une maison qui vous est propre.""",
  """settings.notificationsSection""": """Notifications""",
  """settings.notificationsSectionBody""":
      """Alertes et fréquence de vérification de l'activité""",
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
  """settings.delivery""": """Distribution""",
  """settings.deliveryPolling""": """Vérifications périodiques""",
  """settings.deliveryUnifiedPush""": """UnifiedPush""",
  """settings.deliveryPollingBody""":
      """Pantry vérifie régulièrement la nouvelle activité sur votre serveur.""",
  """settings.deliveryNoDistributor""":
      """Aucun distributeur UnifiedPush n'est disponible. Pantry vérifie régulièrement en attendant qu'un distributeur soit configuré.""",
  """settings.deliveryServerUnsupported""":
      """Votre serveur n'accepte pas le web push. Pantry vérifie régulièrement à la place.""",
  """settings.deliveryFailed""":
      """Impossible de s'abonner aux notifications push. Pantry vérifie régulièrement à la place.""",
  """settings.noDistributorTitle""": """Installez un distributeur""",
  """settings.noDistributorBody""":
      """UnifiedPush distribue les notifications via une application distributrice distincte, comme ntfy, NextPush ou Sunup. Installez-en une, puis choisissez à nouveau UnifiedPush.""",
  """settings.chooseDistributor""": """Choisissez un distributeur""",
  """settings.learnMore""": """En savoir plus""",
  """settings.serverNoWebPush""":
      """Votre serveur n'accepte pas le web push. Il faut Nextcloud 34 ou plus récent, avec le web push autorisé dans Paramètres d'administration → Notifications.""",
  """settings.deliveryEnabled""":
      """Les notifications instantanées sont activées.""",
  """settings.pushSetup""": """Configurer UnifiedPush""",
  """settings.pushSetupSubtitle""":
      """Ce dont les notifications instantanées ont besoin""",
  """settings.pushSetupStep1""":
      """Installez une application distributrice UnifiedPush, comme ntfy, NextPush ou Sunup.""",
  """settings.pushSetupStep2""":
      """Votre serveur doit utiliser Nextcloud 34 ou plus récent, avec le web push autorisé par un administrateur dans Paramètres d'administration → Notifications.""",
  """settings.pushSetupStep3""":
      """Choisissez UnifiedPush sous Distribution, puis votre distributeur.""",
  """settings.pushSetupNote""":
      """Pantry continue de vérifier selon le planning jusqu'à ce que votre serveur confirme l'abonnement.""",
  """settings.refreshSection""": """Actualisation automatique""",
  """settings.refreshSectionBody""":
      """À quelle fréquence chaque écran vérifie les changements sur le serveur pendant que vous le consultez. Vous pouvez toujours tirer vers le bas pour actualiser manuellement.""",
  """settings.refreshSectionSubtitle""":
      """À quelle fréquence chaque écran vérifie les changements""",
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
  """settings.watchSection""": """Montre""",
  """settings.watchSubtitle""":
      """Associer une montre Wear OS et la connecter""",
  """settings.diagnostics.title""": """Journaux de diagnostic""",
  """settings.diagnostics.subtitle""":
      """Consulter et partager un journal anonymisé pour signaler un bug""",
  """settings.diagnostics.body""":
      """Pantry conserve sur cet appareil un court journal de ses requêtes, synchronisations et erreurs. Les adresses du serveur, noms d'utilisateur, mots de passe et jetons sont masqués, et le contenu de vos listes, articles et notes n'est jamais enregistré. Partagez-le lorsque vous signalez un problème.""",
  """settings.diagnostics.thisDevice""": """Cet appareil""",
  """settings.diagnostics.watch""": """Montre""",
  """settings.diagnostics.problemsOnly""": """Problèmes uniquement""",
  """settings.diagnostics.empty""": """Rien n'a encore été enregistré""",
  """settings.diagnostics.copied""": """Journal copié""",
  """settings.diagnostics.share""": """Partager""",
  """settings.diagnostics.shareFailed""":
      """Impossible de partager le journal""",
  """settings.diagnostics.clearTitle""": """Effacer le journal ?""",
  """settings.diagnostics.clearBody""":
      """Cela supprime tout ce qui a été enregistré sur cet appareil jusqu'à présent.""",
  """settings.diagnostics.watchLoading""": """Interrogation de votre montre…""",
  """settings.diagnostics.watchUnavailable""":
      """Impossible de joindre votre montre. Ouvrez Pantry sur la montre et réessayez.""",
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
  """categories.list""": """Liste""",
  """categories.globalList""": """Toutes les listes (global)""",
  """categories.sort.nameAZ""": """Nom A–Z""",
  """categories.sort.nameZA""": """Nom Z–A""",
  """categories.sort.custom""": """Personnalisé""",
  """categories.storeOrder.title""": """Ordre par magasin""",
  """categories.storeOrder.hint""":
      """Classez les catégories dans l'ordre où vous parcourez ce magasin. Le mode courses suit cet ordre pendant que vous y êtes.""",
  """categories.storeOrder.store""": """Magasin""",
  """categories.storeOrder.noStores""":
      """Aucun magasin pour le moment. Ajoutez-en un pour lui donner son propre ordre.""",
  """categories.storeOrder.dragHandle""": """Glisser pour réorganiser""",
  """categories.storeOrder.useSharedOrder""": """Utiliser l'ordre partagé""",
  """categories.storeOrder.loadFailed""":
      """Impossible de charger l'ordre de ce magasin.""",
  """customFields.manageTitle""": """Champs personnalisés""",
  """customFields.empty""":
      """Aucun champ personnalisé pour le moment. Ajoutez-en un pour attacher des informations supplémentaires aux articles.""",
  """customFields.addField""": """Ajouter un champ""",
  """customFields.allLists""": """Toutes les listes""",
  """customFields.deleteTitle""": """Supprimer le champ""",
  """customFields.deleteConfirm""":
      """Supprimer ce champ ? Les valeurs déjà définies sur les articles sont conservées mais masquées.""",
  """customFields.optionDeleteFailed""":
      """Impossible de supprimer l'option.""",
  """customFields.types.text""": """Texte""",
  """customFields.types.number""": """Nombre""",
  """customFields.types.checkbox""": """Case à cocher""",
  """customFields.types.date""": """Date""",
  """customFields.types.select""": """Sélection""",
  """customFields.name""": """Nom""",
  """customFields.namePlaceholder""": """p. ex. Péremption, Rayon""",
  """customFields.type""": """Type""",
  """customFields.typeLocked""":
      """Le type ne peut pas être modifié après la création du champ.""",
  """customFields.scope""": """Portée""",
  """customFields.hint""": """Texte d'aide""",
  """customFields.hintPlaceholder""":
      """Affiché comme texte indicatif de la valeur""",
  """customFields.multiline""": """Zone de texte multiligne""",
  """customFields.options""": """Options""",
  """customFields.optionPlaceholder""": """Libellé de l'option""",
  """customFields.addOption""": """Ajouter une option""",
  """customFields.removeOption""": """Retirer l'option""",
  """customFields.entryMode""": """Saisie de la date""",
  """customFields.dateAbsolute""": """Absolue""",
  """customFields.dateRelative""": """Relative""",
  """customFields.defaultOffset""": """Décalage par défaut (jours)""",
  """customFields.defaultOffsetPlaceholder""": """p. ex. 7""",
  """customFields.notifyDefault""": """Rappeler par défaut""",
  """customFields.leadTime""": """Rappeler""",
  """customFields.leadOnDay""": """Le jour même""",
  """customFields.leadDay1""": """1 jour avant""",
  """customFields.leadDay2""": """2 jours avant""",
  """customFields.leadDay3""": """3 jours avant""",
  """customFields.leadWeek1""": """1 semaine avant""",
  """customFields.overridePolicy""": """Remplacement du rappel""",
  """customFields.overrideFieldOnly""": """Même rappel pour chaque article""",
  """customFields.overrideItem""":
      """Chaque article définit son propre rappel""",
  """customFields.stopWhenDone""":
      """Arrêter de rappeler une fois l'article terminé""",
  """customFields.defaultValue""": """Valeur par défaut""",
  """customFields.defaultChecked""": """Activé par défaut""",
  """customFields.noDefault""": """Aucune valeur par défaut""",
  """customFields.noValue""": """Aucune valeur""",
  """customFields.daysFromToday""": """Jours à partir d'aujourd'hui""",
  """customFields.reanchor""": """Réancrer la date""",
  """customFields.remindMe""": """Me rappeler""",
  """customFields.customReminder""": """Rappel personnalisé pour cet article""",
  """customFields.useFieldDefault""":
      """Utiliser la valeur par défaut du champ""",
  """customFields.done""": """Terminé""",
  """customFields.remapTitle""": """Option utilisée""",
  """customFields.remapClear""": """La retirer de ces articles""",
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
  """labels.manageTitle""": """Gérer les étiquettes""",
  """labels.noLabels""": """Aucune étiquette pour le moment.""",
  """labels.editTitle""": """Modifier l'étiquette""",
  """labels.addTitle""": """Nouvelle étiquette""",
  """labels.name""": """Nom""",
  """labels.icon""": """Icône""",
  """labels.color""": """Couleur""",
  """labels.saveFailed""": """Impossible d'enregistrer l'étiquette.""",
  """labels.deleteFailed""": """Impossible de supprimer l'étiquette.""",
  """labels.deleteConfirm""": """Supprimer cette étiquette ?""",
  """labels.deleteConfirmBody""":
      """Cette étiquette sera retirée de tous les articles. Cette action est irréversible.""",
  """labels.list""": """Liste""",
  """labels.globalList""": """Toutes les listes (global)""",
  """labels.sort.nameAZ""": """Nom A–Z""",
  """labels.sort.nameZA""": """Nom Z–A""",
  """labels.sort.custom""": """Personnalisé""",
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
  """checklists.barcode.torch""": """Activer le flash""",
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
  """checklists.filters.labels""": """Étiquettes""",
  """checklists.filters.allLists""": """Toutes les listes""",
  """checklists.filters.allCategories""": """Toutes les catégories""",
  """checklists.filters.allStores""": """Tous les magasins""",
  """checklists.filters.allLabels""": """Toutes les étiquettes""",
  """checklists.filters.noCategory""": """Sans catégorie""",
  """checklists.filters.noStores""": """Sans magasin""",
  """checklists.filters.noLabels""": """Sans étiquette""",
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
  """checklists.menu.sortAndView""": """Tri et affichage""",
  """checklists.menu.manage""": """Gérer""",
  """checklists.menu.list""": """Liste""",
  """checklists.menu.shopping""": """Courses""",
  """checklists.menu.developer""": """Développeur""",
  """checklists.batch.moveTitle""": """Déplacer les articles vers""",
  """checklists.batch.copyTitle""": """Copier les articles vers""",
  """checklists.batch.categoryTitle""": """Définir la catégorie""",
  """checklists.batch.storesTitle""": """Définir les magasins""",
  """checklists.batch.labelsTitle""": """Définir les étiquettes""",
  """checklists.batch.clearCategory""": """Aucune catégorie""",
  """checklists.batch.move""": """Déplacer""",
  """checklists.batch.copy""": """Copier""",
  """checklists.batch.category""": """Catégorie""",
  """checklists.batch.stores""": """Magasins""",
  """checklists.batch.labels""": """Étiquettes""",
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
  """checklists.copyLink""": """Copier le lien""",
  """checklists.addToHomeScreen""": """Ajouter à l'écran d'accueil""",
  """checklists.addToHomeScreenFailed""":
      """Impossible d'ajouter le raccourci.""",
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
  """checklists.archivedLists""": """Listes archivées""",
  """checklists.archivedListsTitle""": """Listes archivées""",
  """checklists.archivedListsEmpty""":
      """Les listes archivées apparaîtront ici.""",
  """checklists.failedToLoadArchivedLists""":
      """Impossible de charger les listes archivées.""",
  """checklists.archiveList""": """Archiver""",
  """checklists.unarchiveList""": """Désarchiver""",
  """checklists.listArchived""": """Liste archivée""",
  """checklists.archiveListFailed""": """Impossible d'archiver la liste.""",
  """checklists.unarchiveListFailed""":
      """Impossible de désarchiver la liste.""",
  """checklists.duplicateList""": """Dupliquer""",
  """checklists.duplicateListTitle""": """Dupliquer la liste""",
  """checklists.duplicateListResetDone""":
      """Marquer tous les articles comme non faits""",
  """checklists.duplicateListFailed""": """Impossible de dupliquer la liste.""",
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
  """checklists.viewItem.typeLabel""": """Récurrence""",
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
  """checklists.itemForm.labels""": """Étiquettes""",
  """checklists.itemForm.noLabels""": """Aucune""",
  """checklists.itemForm.createLabel""": """Nouvelle étiquette""",
  """checklists.itemForm.labelsChange""": """Modifier""",
  """checklists.itemForm.labelsPick""": """Choisir""",
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
  """checklists.itemForm.imageQueuedOffline""":
      """Pas de connexion — l'image sera jointe dès votre retour en ligne.""",
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
  """checklists.removeAll""": """Tout supprimer""",
  """checklists.removeAllConfirm""": """Supprimer tous les articles cochés ?""",
  """checklists.removeAllConfirmBody""":
      """Chaque article coché de cette liste sera déplacé vers la corbeille. Vous pourrez les restaurer ensuite.""",
  """checklists.archiveAll""": """Tout archiver""",
  """checklists.archiveAllConfirm""": """Archiver tous les articles cochés ?""",
  """checklists.archiveAllConfirmBody""":
      """Chaque article coché de cette liste sera déplacé vers les archives. Vous pourrez les désarchiver ensuite.""",
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
  """checklists.listRecurrence.label""": """Récurrence par défaut""",
  """checklists.listRecurrence.remember""": """Mémoriser la dernière""",
  """checklists.listRecurrence.rememberHint""":
      """Les nouveaux articles démarrent avec la même récurrence que le dernier article ajouté à cette liste.""",
  """checklists.listRecurrence.none""": """Aucune""",
  """checklists.listRecurrence.noneHint""":
      """Les nouveaux articles restent sur la liste après avoir été complétés.""",
  """checklists.listRecurrence.once""": """Unique""",
  """checklists.listRecurrence.onceHint""":
      """Les nouveaux articles sont supprimés de la liste une fois complétés.""",
  """checklists.listRecurrence.recurring""": """Récurrent""",
  """checklists.listRecurrence.recurringHint""":
      """Les nouveaux articles reviennent selon l'horaire ci-dessous.""",
  """checklists.itemDefaults.title""": """Valeurs par défaut des articles""",
  """checklists.itemDefaults.intro""":
      """Les nouveaux articles de cette liste démarrent avec ces valeurs.""",
  """checklists.itemDefaults.readOnly""":
      """Seules les personnes qui peuvent modifier cette liste peuvent changer ses valeurs par défaut.""",
  """checklists.itemDefaults.edit""": """Modifier les valeurs par défaut""",
  """checklists.itemDefaults.modeNone""": """Non défini""",
  """checklists.itemDefaults.modeFixed""": """Fixe""",
  """checklists.itemDefaults.modeRemember""": """Mémoriser le dernier""",
  """checklists.itemDefaults.modeFieldDefault""":
      """Valeur par défaut du champ""",
  """checklists.itemDefaults.noneHint""":
      """Les nouveaux articles démarrent sans valeur.""",
  """checklists.itemDefaults.fixedHint""":
      """Les nouveaux articles démarrent toujours avec la valeur ci-dessous.""",
  """checklists.itemDefaults.rememberHint""":
      """Les nouveaux articles démarrent avec la valeur du dernier article ajouté à cette liste.""",
  """checklists.itemDefaults.inheritEmpty""":
      """Utilise la valeur par défaut du champ, qui est vide.""",
  """checklists.itemDefaults.checked""": """Coché""",
  """checklists.itemTypes.label""": """Récurrence""",
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
  """checklists.compose.chipLabel""": """Étiquettes""",
  """checklists.compose.chipQuantity""": """Quantité""",
  """checklists.compose.chipType""": """Récurrence""",
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
  """checklists.price.anyStore""": """N'importe quel magasin""",
  """checklists.price.store""": """Magasin""",
  """checklists.price.addPrice""": """Ajouter un prix""",
  """checklists.price.removePrice""": """Supprimer le prix""",
  """checklists.reuse.dialogTitle""": """L'article existe déjà""",
  """checklists.reuse.reuseExisting""": """Réutiliser l'existant""",
  """checklists.reuse.addAnyway""": """Ajouter quand même""",
  """checklists.reuse.suggestionsHeader""": """Déjà dans cette liste""",
  """checklists.reuse.archivedBadge""": """Archivé""",
  """checklists.allLists""": """Toutes les listes""",
  """checklists.allListsSubtitle""": """Éléments de toutes les listes""",
  """checklists.addToAnyList""": """Ajouter un élément…""",
  """checklists.pickListTitle""": """Ajouter à quelle liste ?""",
  """checklists.markdown.uncategorized""": """Sans catégorie""",
  """checklists.markdown.exportTitle""": """Exporter en Markdown""",
  """checklists.markdown.importTitle""": """Importer depuis Markdown""",
  """checklists.markdown.importToLabel""": """Importer vers""",
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
  """listKinds.duplicateAs""": """Dupliquer en tant que :""",
  """listKinds.checklist.title""": """Listes de contrôle""",
  """listKinds.checklist.name""": """Liste de contrôle""",
  """listKinds.checklist.newList""": """Nouvelle liste de contrôle""",
  """listKinds.checklist.createTitle""": """Créer une liste de contrôle""",
  """listKinds.checklist.editTitle""": """Modifier la liste de contrôle""",
  """listKinds.checklist.duplicateTitle""":
      """Dupliquer la liste de contrôle""",
  """listKinds.checklist.duplicateFailed""":
      """Impossible de dupliquer la liste de contrôle""",
  """listKinds.checklist.listMenu""": """Actions de la liste de contrôle""",
  """listKinds.checklist.deleteDialogTitle""":
      """Supprimer la liste de contrôle""",
  """listKinds.checklist.emptyTitle""":
      """Aucune liste de contrôle pour le moment""",
  """listKinds.checklist.emptyBody""":
      """Créez votre première liste de contrôle pour commencer à ajouter des articles.""",
  """listKinds.checklist.trashTitle""": """Corbeille des listes de contrôle""",
  """listKinds.checklist.trashEmptyBody""":
      """Les listes de contrôle supprimées apparaîtront ici.""",
  """listKinds.checklist.archiveTitle""": """Listes de contrôle archivées""",
  """listKinds.checklist.archiveEmptyTitle""":
      """Aucune liste de contrôle archivée""",
  """listKinds.checklist.archiveEmptyBody""":
      """Les listes de contrôle archivées apparaîtront ici.""",
  """listKinds.checklist.emptyTrashBody""":
      """Toutes les listes de contrôle présentes dans la corbeille, ainsi que leurs articles, seront définitivement supprimées. Cette action est irréversible.""",
  """listKinds.checklist.listRestored""": """Liste de contrôle restaurée""",
  """listKinds.checklist.listMovedToTrash""":
      """Liste de contrôle déplacée vers la corbeille""",
  """listKinds.checklist.listArchived""": """Liste de contrôle archivée""",
  """listKinds.checklist.listUnarchived""": """Liste de contrôle désarchivée""",
  """listKinds.inventory.title""": """Inventaires""",
  """listKinds.inventory.name""": """Inventaire""",
  """listKinds.inventory.newList""": """Nouvel inventaire""",
  """listKinds.inventory.createTitle""": """Créer un inventaire""",
  """listKinds.inventory.editTitle""": """Modifier l'inventaire""",
  """listKinds.inventory.duplicateTitle""": """Dupliquer l'inventaire""",
  """listKinds.inventory.duplicateFailed""":
      """Impossible de dupliquer l'inventaire""",
  """listKinds.inventory.listMenu""": """Actions de l'inventaire""",
  """listKinds.inventory.deleteDialogTitle""": """Supprimer l'inventaire""",
  """listKinds.inventory.emptyTitle""": """Aucun inventaire pour le moment""",
  """listKinds.inventory.emptyBody""":
      """Créez votre premier inventaire pour commencer à ajouter des articles.""",
  """listKinds.inventory.trashTitle""": """Corbeille des inventaires""",
  """listKinds.inventory.trashEmptyBody""":
      """Les inventaires supprimés apparaîtront ici.""",
  """listKinds.inventory.archiveTitle""": """Inventaires archivés""",
  """listKinds.inventory.archiveEmptyTitle""": """Aucun inventaire archivé""",
  """listKinds.inventory.archiveEmptyBody""":
      """Les inventaires archivés apparaîtront ici.""",
  """listKinds.inventory.emptyTrashBody""":
      """Tous les inventaires présents dans la corbeille, ainsi que leurs articles, seront définitivement supprimés. Cette action est irréversible.""",
  """listKinds.inventory.listRestored""": """Inventaire restauré""",
  """listKinds.inventory.listMovedToTrash""":
      """Inventaire déplacé vers la corbeille""",
  """listKinds.inventory.listArchived""": """Inventaire archivé""",
  """listKinds.inventory.listUnarchived""": """Inventaire désarchivé""",
  """listKinds.template.title""": """Modèles""",
  """listKinds.template.name""": """Modèle""",
  """listKinds.template.newList""": """Nouveau modèle""",
  """listKinds.template.createTitle""": """Créer un modèle""",
  """listKinds.template.editTitle""": """Modifier le modèle""",
  """listKinds.template.duplicateTitle""": """Dupliquer le modèle""",
  """listKinds.template.duplicateFailed""":
      """Impossible de dupliquer le modèle""",
  """listKinds.template.listMenu""": """Actions du modèle""",
  """listKinds.template.deleteDialogTitle""": """Supprimer le modèle""",
  """listKinds.template.emptyTitle""": """Aucun modèle pour le moment""",
  """listKinds.template.emptyBody""":
      """Créez votre premier modèle pour commencer à ajouter des articles.""",
  """listKinds.template.trashTitle""": """Corbeille des modèles""",
  """listKinds.template.trashEmptyBody""":
      """Les modèles supprimés apparaîtront ici.""",
  """listKinds.template.archiveTitle""": """Modèles archivés""",
  """listKinds.template.archiveEmptyTitle""": """Aucun modèle archivé""",
  """listKinds.template.archiveEmptyBody""":
      """Les modèles archivés apparaîtront ici.""",
  """listKinds.template.emptyTrashBody""":
      """Tous les modèles présents dans la corbeille, ainsi que leurs articles, seront définitivement supprimés. Cette action est irréversible.""",
  """listKinds.template.listRestored""": """Modèle restauré""",
  """listKinds.template.listMovedToTrash""":
      """Modèle déplacé vers la corbeille""",
  """listKinds.template.listArchived""": """Modèle archivé""",
  """listKinds.template.listUnarchived""": """Modèle désarchivé""",
  """templates.suggestionsHeader""": """Suggestions""",
  """templates.drawFailed""":
      """Impossible d'ajouter l'article depuis le modèle""",
  """templates.attachedLabel""": """Modèles :""",
  """templates.attachedPlaceholder""": """Aucun modèle""",
  """templates.attachedHint""":
      """La saisie d'un nouvel article suggère les articles correspondants de ces modèles.""",
  """templates.suggestInLabel""": """Suggérer dans :""",
  """templates.everyList""": """Toutes les listes""",
  """templates.suggestInPlaceholder""": """Aucune liste""",
  """templates.suggestInHint""":
      """La saisie d'un nouvel article dans ces listes suggère les articles correspondants de ce modèle. Sélectionner « Toutes les listes » inclut aussi les listes créées par la suite.""",
  """templates.attachFailed""":
      """Impossible d'enregistrer les modèles associés""",
  """templates.fillLabel""":
      """Remplir les articles de modèle avec ces valeurs""",
  """templates.fillHint""":
      """Lorsqu'un article est ajouté depuis un modèle, les détails qu'il laisse vides démarrent avec les valeurs ci-dessus. Chaque personne peut modifier ce comportement dans ses paramètres personnels.""",
  """templates.fillPrefLabel""":
      """Remplir les articles de modèle avec les valeurs par défaut""",
  """templates.fillPrefHint""":
      """Lorsque vous ajoutez un article depuis un modèle, les détails qu'il laisse vides sont remplis avec les valeurs par défaut des articles de la liste. Chaque liste peut désactiver ce comportement dans ses valeurs par défaut.""",
  """templates.fillPrefNames.list""": """Selon chaque liste""",
  """templates.fillPrefNames.always""": """Toujours remplir""",
  """templates.fillPrefNames.never""": """Ne jamais remplir""",
  """templates.fillPrefFailed""": """Impossible d'enregistrer le paramètre""",
  """templates.applyToList""": """Appliquer à une liste""",
  """templates.applyTemplate""": """Appliquer le modèle""",
  """templates.attachedTemplates""": """Associés à cette liste""",
  """templates.otherTemplates""": """Autres modèles""",
  """templates.noTargets""":
      """Aucune liste de contrôle ni aucun inventaire auquel appliquer ce modèle.""",
  """templates.noItems""": """Ce modèle ne contient aucun article.""",
  """templates.alreadyOnList""": """Déjà dans la liste""",
  """templates.applyFailed""": """Impossible d'appliquer le modèle""",
  """templates.loadFailed""": """Impossible de charger les modèles""",
  """templates.back""": """Retour""",
  """stock.inStock""": """En stock""",
  """stock.full""": """Plein""",
  """stock.low""": """Bas""",
  """stock.out""": """Épuisé""",
  """stock.notCounted""": """Non compté""",
  """stock.expiresToday""": """Périme aujourd’hui""",
  """stock.expiresTomorrow""": """Périme demain""",
  """stock.decrease""": """Diminuer la quantité disponible""",
  """stock.increase""": """Augmenter la quantité disponible""",
  """stock.onHandEdit""": """Quantité disponible""",
  """stock.filter""": """Stock""",
  """stock.filterAll""": """Tous les articles""",
  """stock.filterNeedsRestock""": """À réapprovisionner""",
  """stock.filterInStock""": """En stock""",
  """stock.writeRefused""":
      """Impossible d’enregistrer la modification du stock. L’inventaire affiche maintenant les données du serveur.""",
  """stock.settings.action""": """Paramètres de l’inventaire""",
  """stock.settings.title""": """Paramètres de l’inventaire""",
  """stock.settings.name""": """Nom""",
  """stock.settings.nameHint""":
      """L’icône, la couleur et le partage fonctionnent comme pour les listes de contrôle.""",
  """stock.settings.expiryWarning""": """Alerte de péremption""",
  """stock.settings.daysBefore""": """Jours avant la péremption""",
  """stock.settings.warnHint""":
      """Indiquez 0 pour être averti le jour même de la péremption.""",
  """stock.settings.cancel""": """Annuler""",
  """stock.settings.save""": """Enregistrer""",
  """stock.card.title""": """Stock""",
  """stock.card.mode""": """Mode de stock""",
  """stock.card.count""": """Quantité""",
  """stock.card.level""": """Niveau""",
  """stock.card.countHint""":
      """Suivez combien vous en avez, p. ex. 4 œufs sur 12.""",
  """stock.card.levelHint""":
      """Suivez-le en Plein, Bas ou Épuisé, p. ex. farine ou épices.""",
  """stock.card.onHand""": """Disponible""",
  """stock.card.onHandPlaceholder""": """p. ex. 4""",
  """stock.card.target""": """Objectif""",
  """stock.card.targetPlaceholder""": """p. ex. 12 œufs""",
  """stock.card.reorderPoint""": """Seuil de réapprovisionnement""",
  """stock.card.reorderPlaceholder""": """p. ex. 4""",
  """stock.card.stockLevel""": """Niveau de stock""",
  """stock.card.restockAmount""": """Quantité à racheter""",
  """stock.card.restockPlaceholder""": """p. ex. sachet de 1 kg""",
  """stock.card.convertedBlank""":
      """Converti en quantité. Saisissez la quantité disponible et un objectif.""",
  """stock.card.statusExpired""": """Périmé.""",
  """stock.card.statusExpiring""": """Bientôt périmé.""",
  """stock.card.statusLow""": """Bas.""",
  """stock.card.statusOut""": """Épuisé.""",
  """stock.card.statusUncountedTarget""":
      """Non compté : l’objectif n’a pas de nombre, il n’est donc jamais bas.""",
  """stock.card.statusUncountedOnHand""":
      """Non compté : la quantité disponible n’a pas de nombre, il n’est donc jamais bas.""",
  """stock.card.statusInStock""": """En stock.""",
  """stock.card.templateDefaultMode""":
      """Sans mode de stock choisi, il utilise celui de l’inventaire par défaut.""",
  """stock.card.templateStartsLevel""":
      """Ajouté à un inventaire, il démarre Plein.""",
  """stock.card.templateUncounted""":
      """Ajouté à un inventaire sans objectif, il n’est pas compté.""",
  """stock.expiry.title""": """Péremption""",
  """stock.expiry.mode""": """Comment l’article se périme""",
  """stock.expiry.none""": """Aucune""",
  """stock.expiry.date""": """Date""",
  """stock.expiry.keeps""": """Se conserve N jours""",
  """stock.expiry.expiryDate""": """Date de péremption""",
  """stock.expiry.daysItKeeps""": """Jours de conservation""",
  """stock.expiry.chip""": """Péremption""",
  """stock.compose.chip""": """Stock""",
  """stock.compose.count""": """Quantité""",
  """stock.compose.level""": """Niveau""",
  """stock.compose.fullWhenEmpty""": """Plein si vide""",
  """notesWall.noNotes""": """Aucune note pour le moment.""",
  """notesWall.failedToLoad""": """Impossible de charger les notes.""",
  """notesWall.saveFailed""": """Impossible d'enregistrer la note.""",
  """notesWall.deleteFailed""": """Impossible de supprimer la note.""",
  """notesWall.deleteConfirm""": """Supprimer cette note ?""",
  """notesWall.selectNotes""": """Sélectionner des notes""",
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
  """notesWall.importToList""": """Importer vers une liste""",
  """notesWall.importNoLists""":
      """Aucune liste disponible pour l'importation.""",
  """notesWall.syncedFileMissing""":
      """Le fichier synchronisé est introuvable""",
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
  """photoBoard.waitingForConnection""": """En attente d'une connexion""",
  """photoBoard.deleteFailed""": """Impossible de supprimer la photo.""",
  """photoBoard.deleteConfirm""": """Supprimer cette photo ?""",
  """photoBoard.selectPhotos""": """Sélectionner des photos""",
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
  """shopping.join""": """Rejoindre""",
  """shopping.joinConfirmTitle""": """Rejoindre ces courses ?""",
  """shopping.endMineAndJoin""": """Terminer les miennes et rejoindre""",
  """shopping.joinFailed""": """Impossible de rejoindre les courses.""",
  """shopping.leaveTrip""": """Quitter les courses""",
  """shopping.leaveTripFailed""": """Impossible de quitter les courses.""",
  """shopping.startTitle""": """Commencer les courses""",
  """shopping.listsToShop""": """Listes à faire""",
  """shopping.selectAll""": """Tout sélectionner""",
  """shopping.selectNone""": """Ne rien sélectionner""",
  """shopping.noListsToShop""": """Aucune liste à faire pour l'instant.""",
  """shopping.shopAllStores""": """Tout acheter en une fois""",
  """shopping.shopAllStoresHint""":
      """Cette option regroupe tous les magasins dans un seul onglet pour tout acheter d'un coup""",
  """shopping.storesTitle""": """Magasins""",
  """shopping.storesHint""":
      """Activez ou désactivez les magasins que vous visiterez, et glissez pour définir l'ordre.""",
  """shopping.storesHintAll""":
      """Activez ou désactivez les magasins pour lesquels vous faites les courses.""",
  """shopping.allItems""": """Tous les articles""",
  """shopping.noStoresWithItems""":
      """Aucune des listes sélectionnées n'a d'articles assignés à un magasin.""",
  """shopping.includeUnassigned""": """Inclure les articles sans magasin""",
  """shopping.itemsToShop""": """Articles à acheter""",
  """shopping.selectInvert""": """Inverser""",
  """shopping.noItemsToShop""":
      """Les listes sélectionnées n'ont plus rien à acheter.""",
  """shopping.pickAtLeastOneItem""":
      """Choisissez au moins un article à acheter.""",
  """shopping.start""": """Commencer""",
  """shopping.startFailed""": """Impossible de commencer les courses.""",
  """shopping.tripInProgress""": """Vous avez déjà des courses en cours.""",
  """shopping.tripWithHousemate""":
      """Vous faites les courses avec une autre personne du foyer.""",
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
  """shopping.tripFinishedByHousemate""": """Ces courses ont été terminées.""",
  """shopping.removeFromTrip""": """Retirer de la sortie""",
  """shopping.removedFromTrip""": """Retiré de cette sortie""",
  """shopping.undo""": """Annuler""",
  """shopping.undoRemoveFailed""": """Impossible d'annuler.""",
  """shopping.restore""": """Restaurer""",
  """shopping.restoreFailed""": """Impossible de restaurer l'article.""",
  """shopping.reviewTitle""": """Récapitulatif""",
  """shopping.advanceTitle""": """Magasin suivant""",
  """shopping.actualPaid""": """Payé réel""",
  """shopping.grandTotal""": """Total général""",
  """shopping.anyStore""": """N'importe quel magasin""",
  """shopping.editTotalsTitle""": """Modifier les totaux des courses""",
  """shopping.editTotals""": """Modifier les totaux""",
  """shopping.doneEditing""": """Terminé""",
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
  """shopping.deleteTrip""": """Supprimer la course""",
  """shopping.deleteTripTitle""": """Supprimer la course""",
  """shopping.deleteTripBody""":
      """Cette course et ses totaux seront définitivement supprimés de l'historique des courses. Cette action est irréversible.""",
  """shopping.deleteTripFailed""": """Impossible de supprimer la course.""",
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
  """recurrence.monthlyModeDays""": """Jours du mois""",
  """recurrence.monthlyModeWeekday""": """Un jour de la semaine du mois""",
  """recurrence.monthDaysHint""":
      """Laissez vide pour répéter le même jour chaque mois""",
  """recurrence.yearlyDate""": """Date""",
  """recurrence.yearlyDateHint""":
      """Laissez vide pour répéter à la même date chaque année""",
  """recurrence.pickDate""": """Choisir une date""",
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
  """recurrence.ordinal.first""": """Premier""",
  """recurrence.ordinal.second""": """Deuxième""",
  """recurrence.ordinal.third""": """Troisième""",
  """recurrence.ordinal.fourth""": """Quatrième""",
  """recurrence.ordinal.last""": """Dernier""",
  """recurrence.ordinalInline.first""": """premier""",
  """recurrence.ordinalInline.second""": """deuxième""",
  """recurrence.ordinalInline.third""": """troisième""",
  """recurrence.ordinalInline.fourth""": """quatrième""",
  """recurrence.ordinalInline.last""": """dernier""",
  """sync.offline""": """Hors ligne""",
  """sync.syncing""": """Synchronisation des modifications…""",
  """sync.syncError""": """Impossible de synchroniser les modifications""",
  """sync.failedOne""":
      """Impossible d'enregistrer une modification : le serveur a échoué à plusieurs reprises.""",
  """sync.retry""": """Réessayer""",
  """markdownEditor.editSource""": """Markdown""",
  """markdownEditor.editRich""": """Texte enrichi""",
  """markdownEditor.insertTable""": """Insérer un tableau""",
  """markdownEditor.tableColumns""": """Colonnes""",
  """markdownEditor.tableRows""": """Lignes""",
  """markdownEditor.insert""": """Insérer""",
  """markdownEditor.addTableRow""": """Ajouter une ligne""",
  """markdownEditor.addTableColumn""": """Ajouter une colonne""",
  """markdownEditor.removeTableRow""": """Supprimer la ligne""",
  """markdownEditor.removeTableColumn""": """Supprimer la colonne""",
  """markdownEditor.deleteTable""": """Supprimer le tableau""",
  """markdownEditor.editTable""": """Modifier le tableau""",
  """markdownEditor.doneEditingTable""": """Terminé""",
  """wear.notSignedIn""": """Connectez-vous sur votre téléphone""",
  """wear.changeList""": """Changer de liste""",
  """wear.progression""": """Parcours""",
  """wear.done""": """Fait""",
  """wear.skipped""": """Retirés""",
  """wear.account""": """Compte""",
  """wear.markDone""": """Marquer comme fait""",
  """wear.markUndone""": """Marquer comme à faire""",
  """wear.repeats""": """Récurrence""",
  """wear.openOnPhone""": """Ouvrir sur le téléphone""",
  """wear.openedOnPhone""": """Regardez votre téléphone""",
  """wear.openOnPhoneFailed""": """Téléphone injoignable""",
  """wear.addedBy""": """Ajouté par""",
  """wear.added""": """Ajouté""",
  """wear.updated""": """Mis à jour""",
  """wear.tasks""": """Tâches""",
  """wear.nothingToCheckOff""": """Rien à cocher""",
  """wear.nothingRemoved""": """Rien de retiré""",
  """wear.allTasksDone""": """Tout est fait""",
  """wear.emptyNote""": """Cette note est vide""",
  """wear.noLists""": """Aucune liste ici pour l'instant""",
  """wear.setupTitle""": """Configurer Pantry""",
  """wear.setupBody""":
      """Connectez-vous depuis votre téléphone — rien à saisir ici.""",
  """wear.setupNoLink""": """Aucune liaison au téléphone""",
  """wear.setupNoLinkBody""":
      """Cette montre n'atteint aucun téléphone. Pantry en a besoin d'un pour se connecter.""",
  """wear.setupNoPhone""": """Connectez votre téléphone""",
  """wear.setupNoPhoneBody""":
      """Rapprochez votre téléphone et laissez cet écran ouvert.""",
  """wear.setupPhoneSignedOut""":
      """Connectez-vous d'abord sur votre téléphone""",
  """wear.setupPhoneSignedOutBody""":
      """Votre téléphone n'est pas encore connecté à Pantry.""",
  """wear.setupSyncing""": """Récupération de vos listes""",
  """wear.setupSyncingBody""": """Presque terminé.""",
  """wear.signOutWait""": """Envoyer d'abord""",
  """wear.signOutSending""": """Envoi…""",
  """wear.signOutAnyway""": """Se déconnecter quand même""",
  """wear.signOutTitle""": """Se déconnecter ?""",
  """wear.signOutBody""":
      """Cette montre oubliera votre maison. Votre téléphone reste connecté.""",
  """wear.house""": """Maison""",
  """wear.noHouses""": """Aucune maison pour le moment""",
  """wear.settings""": """Réglages""",
  """wear.refreshInterval""": """Actualiser""",
  """wear.refreshOff""": """Désactivé""",
  """wear.allSaved""": """Tout est enregistré""",
  """wear.agoJustNow""": """à l'instant""",
  """wear.setUpAgain""": """Reconfigurer""",
  """wear.sessionExpiredShort""":
      """Votre téléphone doit reconnecter cette montre.""",
  """wear.privateTrip""": """Sortie privée""",
  """wear.needsConnection""": """Connexion nécessaire""",
  """wear.needsWifi""": """Wi-Fi requis pour le serveur""",
  """wear.pickAList""": """Choisis d’abord une liste""",
  """wear.noStoresHere""": """Pas encore de magasins""",
  """wear.hereNow""": """Ici""",
  """wear.advanceFailed""": """Impossible de passer au suivant""",
  """wear.finishFailed""": """Impossible de terminer la sortie""",
  """wear.startMyOwn""": """Lancer la mienne""",
  """wear.joinFailed""": """Impossible de rejoindre""",
  """wear.sharedTrip""": """Sortie partagée""",
  """wear.leaveTripBody""": """La sortie continue pour les autres.""",
  """wear.leaveFailed""": """Impossible de quitter""",
  """wear.notBilled""": """Non renseigné""",
  """wear.currency""": """Devise""",
  """wear.notANumber""": """Chiffres uniquement""",
  """wear.crown""": """Couronne""",
  """wear.crownScrollsList""": """Faire défiler la liste""",
  """wear.crownTurnsPages""": """Changer de page""",
  """wear.undoWindow""": """Annuler""",
  """wear.undoOff""": """Désactivé""",
  """wear.qrSignIn""": """Se connecter avec un QR""",
  """wear.qrServer""": """Votre serveur""",
  """wear.qrServerHint""": """cloud.example.com""",
  """wear.qrShowCode""": """Afficher le code""",
  """wear.qrUnreachable""": """Serveur injoignable""",
  """wear.qrExpired""": """Le code a expiré""",
  """wear.qrStartOver""": """Recommencer""",
  """wear.certUntrustedShort""": """Serveur non vérifié""",
  """wear.serverMovedShort""": """Adresse du serveur modifiée""",
  """wear.trustCertificate""": """Approuver le certificat""",
  """wear.certTrust""": """Faire confiance""",
  """wear.certUnreadable""": """Impossible de lire le certificat du serveur""",
  """wear.notifications""": """Notifications""",
  """wear.notificationsAllowed""": """Autorisées""",
  """wear.notificationsBlocked""": """Bloquées""",
  """wear.shoppingTripChip""": """Sortie courses""",
  """wear.followPhone""": """Suivre le téléphone""",
  """wear.accent""": """Couleur d'accent""",
  """wear.accentServer""": """Votre couleur Nextcloud""",
  """wear.accentApp""": """Couleur de Pantry""",
  """watch.title""": """Montre""",
  """watch.requestWarning""":
      """N'autorisez que si la montre est la vôtre. Elle obtient le même accès à votre foyer que ce téléphone.""",
  """watch.allow""": """Autoriser""",
  """watch.deny""": """Refuser""",
  """watch.transferring""": """Connexion de votre montre""",
  """watch.transferringBody""": """Laissez cet écran ouvert jusqu'à la fin.""",
  """watch.pairedSnack""": """Votre montre est connectée""",
  """watch.pairFailedSnack""": """Montre injoignable""",
  """watch.waitingBody""":
      """Ouvrez Pantry sur votre montre et touchez « Ouvrir sur le téléphone ». La demande apparaîtra ici.""",
  """watch.pairedBody""":
      """Votre montre est connectée et reste au diapason de ce téléphone.""",
  """watch.pairedStatus""": """Connectée""",
  """watch.unnamedWatch""": """Votre montre""",
  """watch.unpair""": """Dissocier la montre""",
  """watch.unpairSubtitle""":
      """Déconnecter cette montre et cesser de synchroniser avec elle""",
  """watch.unpairTitle""": """Dissocier cette montre ?""",
  """watch.unpairBody""":
      """La montre se déconnecte et oublie votre foyer. Vous pourrez la reconfigurer à tout moment.""",
  """watchTips.section""": """Astuces""",
  """watchTips.sectionBody""":
      """De courtes explications sur le fonctionnement de l'app de la montre au poignet.""",
  """watchTips.stepsLabel""": """Étape par étape""",
  """watchTips.pairTitle""": """Configurer votre montre""",
  """watchTips.pairSubtitle""": """Connecter la montre depuis ce téléphone""",
  """watchTips.pairBody""":
      """Une montre se prête mal à la saisie d'un mot de passe, elle emprunte donc la connexion de ce téléphone. Rien ne se tape au poignet.""",
  """watchTips.pairStep1""":
      """Ouvrez Pantry sur votre montre. Un écran de configuration apparaît.""",
  """watchTips.pairStep2""":
      """Touchez « Ouvrir sur le téléphone ». La montre demande à ce téléphone de prendre le relais.""",
  """watchTips.pairStep3""":
      """Déverrouillez ce téléphone et touchez « Autoriser » sur la demande qui s'affiche ici.""",
  """watchTips.pairStep4""":
      """Laissez cet écran ouvert jusqu'à ce qu'il indique que la montre est connectée.""",
  """watchTips.pairNote""":
      """Pas de téléphone sous la main ? La montre peut afficher un QR code. Scannez-le avec n'importe quel appareil photo et terminez la connexion dans le navigateur qui s'ouvre.""",
  """watchTips.itemsTitle""": """Cocher des articles""",
  """watchTips.itemsSubtitle""":
      """Toucher pour cocher, maintenir pour les détails""",
  """watchTips.itemsBody""":
      """La ligne au centre de l'écran est celle sur laquelle votre appui agit. Tout ce que vous pouvez faire à un article part de cette ligne.""",
  """watchTips.itemsStep1""":
      """Touchez la ligne du centre pour la cocher. Touchez-la de nouveau pour la remettre.""",
  """watchTips.itemsStep2""":
      """Un anneau se vide autour de la ligne tant que le changement peut encore être repris. Touchez de nouveau pendant ce délai et rien n'est écrit.""",
  """watchTips.itemsStep3""":
      """Maintenez une ligne pour l'ouvrir. Quantité, prix, catégorie et notes s'y trouvent, avec un bouton qui ouvre l'article sur ce téléphone.""",
  """watchTips.itemsNote""":
      """Toucher une ligne qui n'est pas au centre l'y amène simplement. C'est l'appui suivant qui agit, une visée ratée ne coûte donc qu'un défilement.""",
  """watchTips.pagesTitle""": """Se repérer""",
  """watchTips.pagesSubtitle""":
      """Balayer entre les pages, balayer pour ressortir""",
  """watchTips.pagesBody""":
      """L'app de la montre est une suite de pages plein écran sous un même titre. Il n'y a aucun menu à ouvrir.""",
  """watchTips.pagesStep1""":
      """Balayez latéralement pour passer entre votre liste, le tableau photo, le mur de notes et la page du compte.""",
  """watchTips.pagesStep2""":
      """Les barres sous le titre indiquent combien il y a de pages et sur laquelle vous êtes.""",
  """watchTips.pagesStep3""":
      """Balayez depuis le bord de l'écran pour ressortir de tout ce que vous avez ouvert.""",
  """watchTips.pagesNote""":
      """Le titre nomme toujours la page où vous êtes, et la ligne en dessous nomme le groupe auquel appartient la ligne centrale.""",
  """watchTips.listsTitle""": """Changer de liste""",
  """watchTips.listsSubtitle""": """Touchez le titre en haut""",
  """watchTips.listsBody""":
      """Le nom en haut de l'écran est un bouton. Le toucher ouvre les deux choses pour lesquelles on quitte une liste.""",
  """watchTips.listsStep1""":
      """Touchez le nom de la liste en haut de l'écran.""",
  """watchTips.listsStep2""":
      """Deux boutons se déplient en dessous, « Commencer les courses » et « Changer de liste ».""",
  """watchTips.listsStep3""":
      """Touchez « Changer de liste » et choisissez-en une autre, ou « Toutes les listes » pour tout voir d'un coup.""",
  """watchTips.listsNote""":
      """Les boutons se replient d'eux-mêmes au bout de quelques secondes, toucher le titre par erreur ne coûte donc rien.""",
  """watchTips.shoppingTitle""": """Faire des courses""",
  """watchTips.shoppingSubtitle""":
      """Parcourir les magasins, le téléphone dans la poche""",
  """watchTips.shoppingBody""":
      """Une sortie transforme la montre en compagnon de courses. Les pages deviennent celles dont vous avez besoin dans un rayon, et le foyer peut suivre.""",
  """watchTips.shoppingStep1""":
      """Touchez le titre, puis « Commencer les courses ». Choisissez les listes, les magasins, et si vos colocataires voient la sortie.""",
  """watchTips.shoppingStep2""":
      """Les pages deviennent la sortie elle-même, une pour l'avancement, une pour la liste, une pour les achats et une pour les articles passés.""",
  """watchTips.shoppingStep3""":
      """Cochez au fur et à mesure. Ce que vous passez arrive sur sa propre page et revient sur la liste d'un appui.""",
  """watchTips.shoppingStep4""":
      """En quittant un magasin, la montre demande ce que la caisse a facturé puis vous emmène au suivant.""",
  """watchTips.shoppingStep5""":
      """Après le dernier magasin, « Terminer les courses » affiche le total avant de rien clôturer.""",
  """watchTips.shoppingNote""":
      """Toucher un magasin sur la page d'avancement y emmène la sortie directement, en arrière comme en avant, un détour est donc une correction et non un recommencement.""",
  """watchTips.crownTitle""": """Tourner la couronne""",
  """watchTips.crownSubtitle""":
      """Faire défiler la liste, ou tourner les pages""",
  """watchTips.crownBody""":
      """Tourner la couronne ou la lunette rotative fait défiler la liste devant vous, ce qui garde votre doigt hors de ce que vous lisez.""",
  """watchTips.crownStep1""":
      """Tournez la couronne pour parcourir la liste ligne par ligne. La ligne où elle s'arrête est celle sur laquelle un appui agit.""",
  """watchTips.crownStep2""":
      """Pour qu'un tour change de page à la place, ouvrez « Compte », puis « Réglages », puis « Couronne » sur la montre.""",
  """watchTips.crownNote""":
      """Un tour ne fait qu'une chose à la fois. Confier la couronne aux pages veut dire que les listes défilent au doigt seulement.""",
  """watchTips.offlineTitle""": """Ça marche sans réseau""",
  """watchTips.offlineSubtitle""": """Continuez à cocher au rayon frais""",
  """watchTips.offlineBody""":
      """La montre garde sa propre copie de votre foyer, elle s'ouvre et fonctionne donc sans rien à portée. Ni téléphone, ni Wi-Fi, ni forfait data sur la montre.""",
  """watchTips.offlineStep1""":
      """Un petit point en haut de l'écran signifie que tout ce que vous avez fait est enregistré.""",
  """watchTips.offlineStep2""":
      """Un nuage suivi d'un nombre signifie qu'autant de changements attendent une connexion.""",
  """watchTips.offlineStep3""":
      """Ils partent tout seuls dès que la montre est de nouveau à portée. Il n'y a rien à appuyer.""",
  """watchTips.tileTitle""": """Une liste à un balayage""",
  """watchTips.tileSubtitle""": """Ajouter la tuile Pantry""",
  """watchTips.tileBody""":
      """Les tuiles sont les écrans à côté de votre cadran. Pantry en publie une qui nomme vos listes, pour qu'une liste soit à un balayage plutôt qu'à un lancement d'app.""",
  """watchTips.tileStep1""":
      """Depuis le cadran, balayez latéralement jusqu'aux tuiles.""",
  """watchTips.tileStep2""":
      """Maintenez appuyé, touchez le plus, et choisissez Pantry dans la liste.""",
  """watchTips.tileStep3""":
      """Touchez une liste sur la tuile pour ouvrir l'app directement dessus.""",
};
