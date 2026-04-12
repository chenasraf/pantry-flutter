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
  NotificationsIntroMessagesFr get notificationsIntro =>
      NotificationsIntroMessagesFr(this);
  SettingsMessagesFr get settings => SettingsMessagesFr(this);
  NotificationsMessagesFr get notifications => NotificationsMessagesFr(this);
  CategoriesMessagesFr get categories => CategoriesMessagesFr(this);
  ChecklistsMessagesFr get checklists => ChecklistsMessagesFr(this);
  NotesWallMessagesFr get notesWall => NotesWallMessagesFr(this);
  PhotoBoardMessagesFr get photoBoard => PhotoBoardMessagesFr(this);
  RecurrenceMessagesFr get recurrence => RecurrenceMessagesFr(this);
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
  /// "Langue"
  /// ```
  String get language => """Langue""";
  LanguageNamesSettingsMessagesFr get languageNames =>
      LanguageNamesSettingsMessagesFr(this);

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
}

class LanguageNamesSettingsMessagesFr extends LanguageNamesSettingsMessages {
  final SettingsMessagesFr _parent;
  const LanguageNamesSettingsMessagesFr(this._parent) : super(_parent);

  /// ```dart
  /// "Par défaut du système"
  /// ```
  String get system => """Par défaut du système""";

  /// ```dart
  /// "English"
  /// ```
  String get english => """English""";

  /// ```dart
  /// "עברית"
  /// ```
  String get hebrew => """עברית""";

  /// ```dart
  /// "Deutsch"
  /// ```
  String get german => """Deutsch""";

  /// ```dart
  /// "Español"
  /// ```
  String get spanish => """Español""";

  /// ```dart
  /// "Français"
  /// ```
  String get french => """Français""";
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
  /// "Répéter"
  /// ```
  String get repeat => """Répéter""";

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
  /// "Personnalis\xE9"
  /// ```
  String get custom => """Personnalis\xE9""";
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
  /// "Nouvelle note"
  /// ```
  String get newNote => """Nouvelle note""";

  /// ```dart
  /// "Modifier la note"
  /// ```
  String get editNote => """Modifier la note""";

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
  SortPhotoBoardMessagesFr get sort => SortPhotoBoardMessagesFr(this);
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

Map<String, String> get messagesFrMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Annuler""",
  """common.delete""": """Supprimer""",
  """common.save""": """Enregistrer""",
  """common.retry""": """Réessayer""",
  """common.logout""": """Déconnexion""",
  """common.loading""": """Chargement...""",
  """common.error""": """Erreur""",
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
  """settings.title""": """Réglages de l'app""",
  """settings.generalSection""": """Général""",
  """settings.language""": """Langue""",
  """settings.languageNames.system""": """Par défaut du système""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
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
  """checklists.categories""": """Catégories""",
  """checklists.noChecklists""": """Aucune liste pour le moment.""",
  """checklists.noItems""": """Aucun article dans cette liste.""",
  """checklists.failedToLoad""": """Impossible de charger les listes.""",
  """checklists.failedToLoadItems""": """Impossible de charger les articles.""",
  """checklists.editItem""": """Modifier l'article""",
  """checklists.removeItem""": """Supprimer l'article""",
  """checklists.moveItem""": """Déplacer vers une liste""",
  """checklists.moveFailed""": """Impossible de déplacer l'article.""",
  """checklists.createList""": """Nouvelle liste""",
  """checklists.listName""": """Nom de la liste""",
  """checklists.listDescription""": """Description (facultatif)""",
  """checklists.listIcon""": """Icône""",
  """checklists.createListFailed""": """Impossible de créer la liste.""",
  """checklists.viewItem.quantity""": """Quantité :""",
  """checklists.viewItem.category""": """Catégorie :""",
  """checklists.viewItem.recurrence""": """Récurrence :""",
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
  """checklists.itemForm.repeat""": """Répéter""",
  """checklists.itemForm.saveFailed""":
      """Impossible d'enregistrer l'article.""",
  """checklists.itemForm.deleteFailed""":
      """Impossible de supprimer l'article.""",
  """checklists.itemForm.deleteConfirm""": """Supprimer cet article ?""",
  """checklists.sort.newestFirst""": """Plus récents""",
  """checklists.sort.oldestFirst""": """Plus anciens""",
  """checklists.sort.nameAZ""": """Nom A–Z""",
  """checklists.sort.nameZA""": """Nom Z–A""",
  """checklists.sort.category""": """Par catégorie""",
  """checklists.sort.custom""": """Personnalis\xE9""",
  """notesWall.noNotes""": """Aucune note pour le moment.""",
  """notesWall.failedToLoad""": """Impossible de charger les notes.""",
  """notesWall.saveFailed""": """Impossible d'enregistrer la note.""",
  """notesWall.deleteFailed""": """Impossible de supprimer la note.""",
  """notesWall.deleteConfirm""": """Supprimer cette note ?""",
  """notesWall.newNote""": """Nouvelle note""",
  """notesWall.editNote""": """Modifier la note""",
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
  """photoBoard.sort.foldersFirst""": """Dossiers en premier""",
  """photoBoard.sort.newestFirst""": """Plus récents""",
  """photoBoard.sort.oldestFirst""": """Plus anciens""",
  """photoBoard.sort.captionAZ""": """Légende A–Z""",
  """photoBoard.sort.captionZA""": """Légende Z–A""",
  """photoBoard.sort.custom""": """Personnalisé""",
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
};
