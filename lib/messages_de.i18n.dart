// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:i18n/i18n.dart' as i18n;
import 'messages.i18n.dart';

String get _languageCode => 'de';
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

class MessagesDe extends Messages {
  const MessagesDe();
  String get locale => "de";
  String get languageCode => "de";
  CommonMessagesDe get common => CommonMessagesDe(this);
  LoginMessagesDe get login => LoginMessagesDe(this);
  HomeMessagesDe get home => HomeMessagesDe(this);
  NavMessagesDe get nav => NavMessagesDe(this);
  OnboardingMessagesDe get onboarding => OnboardingMessagesDe(this);
  NotificationsIntroMessagesDe get notificationsIntro =>
      NotificationsIntroMessagesDe(this);
  AboutMessagesDe get about => AboutMessagesDe(this);
  SettingsMessagesDe get settings => SettingsMessagesDe(this);
  NotificationsMessagesDe get notifications => NotificationsMessagesDe(this);
  CategoriesMessagesDe get categories => CategoriesMessagesDe(this);
  ChecklistsMessagesDe get checklists => ChecklistsMessagesDe(this);
  NotesWallMessagesDe get notesWall => NotesWallMessagesDe(this);
  PhotoBoardMessagesDe get photoBoard => PhotoBoardMessagesDe(this);
  ShareMessagesDe get share => ShareMessagesDe(this);
  RecurrenceMessagesDe get recurrence => RecurrenceMessagesDe(this);
}

class CommonMessagesDe extends CommonMessages {
  final MessagesDe _parent;
  const CommonMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "Abbrechen"
  /// ```
  String get cancel => """Abbrechen""";

  /// ```dart
  /// "Löschen"
  /// ```
  String get delete => """Löschen""";

  /// ```dart
  /// "Speichern"
  /// ```
  String get save => """Speichern""";

  /// ```dart
  /// "Erneut versuchen"
  /// ```
  String get retry => """Erneut versuchen""";

  /// ```dart
  /// "Aktualisieren"
  /// ```
  String get refresh => """Aktualisieren""";

  /// ```dart
  /// "Abmelden"
  /// ```
  String get logout => """Abmelden""";

  /// ```dart
  /// "Laden..."
  /// ```
  String get loading => """Laden...""";

  /// ```dart
  /// "Fehler"
  /// ```
  String get error => """Fehler""";
}

class LoginMessagesDe extends LoginMessages {
  final MessagesDe _parent;
  const LoginMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Mit deiner Nextcloud-Instanz verbinden"
  /// ```
  String get connectToNextcloud => """Mit deiner Nextcloud-Instanz verbinden""";

  /// ```dart
  /// "Server-URL"
  /// ```
  String get serverUrl => """Server-URL""";

  /// ```dart
  /// "cloud.example.com"
  /// ```
  String get serverUrlHint => """cloud.example.com""";

  /// ```dart
  /// "Verbinden"
  /// ```
  String get connect => """Verbinden""";

  /// ```dart
  /// """
  /// Warte auf Authentifizierung...
  /// Bitte melde dich in deinem Browser an.
  /// """
  /// ```
  String get waitingForAuth => """Warte auf Authentifizierung...
Bitte melde dich in deinem Browser an.""";

  /// ```dart
  /// "Verbindung zum Server fehlgeschlagen. Bitte überprüfe die URL."
  /// ```
  String get couldNotConnect =>
      """Verbindung zum Server fehlgeschlagen. Bitte überprüfe die URL.""";

  /// ```dart
  /// "Anmeldung fehlgeschlagen. Bitte versuche es erneut."
  /// ```
  String get loginFailed =>
      """Anmeldung fehlgeschlagen. Bitte versuche es erneut.""";
}

class HomeMessagesDe extends HomeMessages {
  final MessagesDe _parent;
  const HomeMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Noch keine Häuser."
  /// ```
  String get noHouses => """Noch keine Häuser.""";

  /// ```dart
  /// "Häuser sind gemeinsame Bereiche für deinen Haushalt. Erstelle dein erstes Haus, um Checklisten, Fotos und Notizen hinzuzufügen."
  /// ```
  String get noHousesBody =>
      """Häuser sind gemeinsame Bereiche für deinen Haushalt. Erstelle dein erstes Haus, um Checklisten, Fotos und Notizen hinzuzufügen.""";

  /// ```dart
  /// "Haus erstellen"
  /// ```
  String get createHouse => """Haus erstellen""";

  /// ```dart
  /// "Hausname"
  /// ```
  String get houseName => """Hausname""";

  /// ```dart
  /// "Beschreibung (optional)"
  /// ```
  String get houseDescription => """Beschreibung (optional)""";

  /// ```dart
  /// "Haus konnte nicht erstellt werden."
  /// ```
  String get createHouseFailed => """Haus konnte nicht erstellt werden.""";

  /// ```dart
  /// "Häuser konnten nicht geladen werden."
  /// ```
  String get failedToLoadHouses => """Häuser konnten nicht geladen werden.""";

  /// ```dart
  /// "Pantry ist nicht installiert"
  /// ```
  String get serverAppMissingTitle => """Pantry ist nicht installiert""";

  /// ```dart
  /// "Diese App ist ein Client für die Pantry-App auf Nextcloud. Es scheint, dass Pantry noch nicht auf deinem Server installiert ist. Bitte deinen Administrator, es aus dem Nextcloud App Store zu installieren, oder installiere es selbst, wenn du Administratorzugang hast."
  /// ```
  String get serverAppMissingBody =>
      """Diese App ist ein Client für die Pantry-App auf Nextcloud. Es scheint, dass Pantry noch nicht auf deinem Server installiert ist. Bitte deinen Administrator, es aus dem Nextcloud App Store zu installieren, oder installiere es selbst, wenn du Administratorzugang hast.""";

  /// ```dart
  /// "Nextcloud-Apps öffnen"
  /// ```
  String get openAppStore => """Nextcloud-Apps öffnen""";

  /// ```dart
  /// "Mehr erfahren"
  /// ```
  String get learnMore => """Mehr erfahren""";
}

class NavMessagesDe extends NavMessages {
  final MessagesDe _parent;
  const NavMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Checklisten"
  /// ```
  String get checklists => """Checklisten""";

  /// ```dart
  /// "Fotowand"
  /// ```
  String get photoBoard => """Fotowand""";

  /// ```dart
  /// "Notizwand"
  /// ```
  String get notesWall => """Notizwand""";
}

class OnboardingMessagesDe extends OnboardingMessages {
  final MessagesDe _parent;
  const OnboardingMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Weiter"
  /// ```
  String get next => """Weiter""";

  /// ```dart
  /// "Zurück"
  /// ```
  String get back => """Zurück""";

  /// ```dart
  /// "Überspringen"
  /// ```
  String get skip => """Überspringen""";

  /// ```dart
  /// "Loslegen"
  /// ```
  String get done => """Loslegen""";

  /// ```dart
  /// "Schritt ${current} von ${total}"
  /// ```
  String stepLabel(int current, int total) =>
      """Schritt ${current} von ${total}""";

  /// ```dart
  /// "Willkommen bei Pantry"
  /// ```
  String get welcomeNewTitle => """Willkommen bei Pantry""";

  /// ```dart
  /// "Lass uns kurz durchgehen, wie Pantry funktioniert, damit du das Beste herausholst."
  /// ```
  String get welcomeNewBody =>
      """Lass uns kurz durchgehen, wie Pantry funktioniert, damit du das Beste herausholst.""";

  /// ```dart
  /// "Was ist neu"
  /// ```
  String get welcomeUpdateTitle => """Was ist neu""";

  /// ```dart
  /// "Seit deinem letzten Besuch hat Pantry ein paar neue Tricks gelernt. Hier ein kurzer Überblick."
  /// ```
  String get welcomeUpdateBody =>
      """Seit deinem letzten Besuch hat Pantry ein paar neue Tricks gelernt. Hier ein kurzer Überblick.""";

  /// ```dart
  /// "Checklisten im neuen Look"
  /// ```
  String get checklistsRedesignTitle => """Checklisten im neuen Look""";

  /// ```dart
  /// "Die Checklisten-Seite wurde von Grund auf neu gebaut — übersichtlicheres Layout, schnelleres Hinzufügen und Schnellaktionen für jede Zeile. Die nächsten Seiten zeigen dir, was neu ist."
  /// ```
  String get checklistsRedesignBody =>
      """Die Checklisten-Seite wurde von Grund auf neu gebaut — übersichtlicheres Layout, schnelleres Hinzufügen und Schnellaktionen für jede Zeile. Die nächsten Seiten zeigen dir, was neu ist.""";

  /// ```dart
  /// "Listen oben wechseln"
  /// ```
  String get checklistSelectorTitle => """Listen oben wechseln""";

  /// ```dart
  /// "Tippe auf den Listennamen oder das Symbol oben, um zwischen Listen zu wechseln oder eine neue zu erstellen."
  /// ```
  String get checklistSelectorBody =>
      """Tippe auf den Listennamen oder das Symbol oben, um zwischen Listen zu wechseln oder eine neue zu erstellen.""";

  /// ```dart
  /// "Tippen zum Wechseln"
  /// ```
  String get checklistSelectorHint => """Tippen zum Wechseln""";

  /// ```dart
  /// "Lebensmittel"
  /// ```
  String get mockListGroceries => """Lebensmittel""";

  /// ```dart
  /// "Baumarkt"
  /// ```
  String get mockListHardware => """Baumarkt""";

  /// ```dart
  /// "Wochenendtrip"
  /// ```
  String get mockListWeekend => """Wochenendtrip""";

  /// ```dart
  /// "${count} Einträge"
  /// ```
  String mockItemCountSummary(int count) => """${count} Einträge""";

  /// ```dart
  /// "Neue Liste"
  /// ```
  String get newListLabel => """Neue Liste""";

  /// ```dart
  /// "Einträge durch Wischen verwalten"
  /// ```
  String get swipeActionsTitle => """Einträge durch Wischen verwalten""";

  /// ```dart
  /// "Wische einen Listeneintrag von rechts nach links, um schnelle Aktionen zum Bearbeiten, Verschieben oder Löschen einzublenden."
  /// ```
  String get swipeActionsBody =>
      """Wische einen Listeneintrag von rechts nach links, um schnelle Aktionen zum Bearbeiten, Verschieben oder Löschen einzublenden.""";

  /// ```dart
  /// "Nach links wischen"
  /// ```
  String get swipeActionsHint => """Nach links wischen""";

  /// ```dart
  /// "Nach rechts wischen"
  /// ```
  String get swipeActionsHintBack => """Nach rechts wischen""";

  /// ```dart
  /// "Einträge schneller hinzufügen"
  /// ```
  String get addItemsTitle => """Einträge schneller hinzufügen""";

  /// ```dart
  /// "Tippe auf das Feld unten, um einen neuen Eintrag einzugeben, und versieh ihn dann über die Chips darüber mit Kategorie, Menge, Typ oder Foto."
  /// ```
  String get addItemsBody =>
      """Tippe auf das Feld unten, um einen neuen Eintrag einzugeben, und versieh ihn dann über die Chips darüber mit Kategorie, Menge, Typ oder Foto.""";

  /// ```dart
  /// "Lebensmittel"
  /// ```
  String get mockComposeListName => """Lebensmittel""";

  /// ```dart
  /// "Fortschrittskarte ausblenden"
  /// ```
  String get progressHeroTitle => """Fortschrittskarte ausblenden""";

  /// ```dart
  /// "Brauchst du den Fortschrittsring oben nicht? Wisch ihn einfach weg."
  /// ```
  String get progressHeroBody =>
      """Brauchst du den Fortschrittsring oben nicht? Wisch ihn einfach weg.""";

  /// ```dart
  /// "Du holst ihn später unter ${settings} → ${interface} → ${toggle} zurück."
  /// ```
  String progressHeroBringBack(
    String settings,
    String interface,
    String toggle,
  ) =>
      """Du holst ihn später unter ${settings} → ${interface} → ${toggle} zurück.""";

  /// ```dart
  /// "Zum Ausblenden wischen"
  /// ```
  String get progressHeroHint => """Zum Ausblenden wischen""";

  /// ```dart
  /// "Tomaten"
  /// ```
  String get mockItemName => """Tomaten""";

  /// ```dart
  /// "x2"
  /// ```
  String get mockItemQuantity => """x2""";

  /// ```dart
  /// "Gemüse"
  /// ```
  String get mockItemCategory => """Gemüse""";
  DevOnboardingMessagesDe get dev => DevOnboardingMessagesDe(this);
}

class DevOnboardingMessagesDe extends DevOnboardingMessages {
  final OnboardingMessagesDe _parent;
  const DevOnboardingMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Onboarding anzeigen"
  /// ```
  String get showOnboarding => """Onboarding anzeigen""";

  /// ```dart
  /// "Zuletzt gesehene Version simulieren"
  /// ```
  String get pickLastSeenTitle => """Zuletzt gesehene Version simulieren""";

  /// ```dart
  /// "Wähle, welche Version das Gerät zuletzt gesehen haben soll, dann wird das Onboarding von dort gestartet."
  /// ```
  String get pickLastSeenBody =>
      """Wähle, welche Version das Gerät zuletzt gesehen haben soll, dann wird das Onboarding von dort gestartet.""";

  /// ```dart
  /// "Noch nie gesehen (neuer Benutzer)"
  /// ```
  String get neverSeen => """Noch nie gesehen (neuer Benutzer)""";
}

class NotificationsIntroMessagesDe extends NotificationsIntroMessages {
  final MessagesDe _parent;
  const NotificationsIntroMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Bleib auf dem Laufenden"
  /// ```
  String get title => """Bleib auf dem Laufenden""";

  /// ```dart
  /// "Pantry kann dich benachrichtigen, wenn Haushaltsmitglieder Einträge zu Checklisten hinzufügen, Fotos hochladen oder Notizen hinterlassen. Benachrichtigungen werden direkt von deinem Nextcloud-Server abgerufen — nichts geht über Google oder Drittanbieter."
  /// ```
  String get body =>
      """Pantry kann dich benachrichtigen, wenn Haushaltsmitglieder Einträge zu Checklisten hinzufügen, Fotos hochladen oder Notizen hinterlassen. Benachrichtigungen werden direkt von deinem Nextcloud-Server abgerufen — nichts geht über Google oder Drittanbieter.""";

  /// ```dart
  /// "Benachrichtigungen über Haushaltsaktivitäten"
  /// ```
  String get bullet1 => """Benachrichtigungen über Haushaltsaktivitäten""";

  /// ```dart
  /// "Direkt von deinem Server abgerufen"
  /// ```
  String get bullet2 => """Direkt von deinem Server abgerufen""";

  /// ```dart
  /// "Funktioniert auch bei geschlossener App"
  /// ```
  String get bullet3 => """Funktioniert auch bei geschlossener App""";

  /// ```dart
  /// "Benachrichtigungen aktivieren"
  /// ```
  String get enableButton => """Benachrichtigungen aktivieren""";

  /// ```dart
  /// "Nicht jetzt"
  /// ```
  String get skipButton => """Nicht jetzt""";

  /// ```dart
  /// "Berechtigung verweigert"
  /// ```
  String get permissionDeniedTitle => """Berechtigung verweigert""";

  /// ```dart
  /// "Du kannst Benachrichtigungen später in den App-Einstellungen aktivieren. Wenn dein Gerät sie blockiert, musst du sie zuerst in den Systemeinstellungen erlauben."
  /// ```
  String get permissionDeniedBody =>
      """Du kannst Benachrichtigungen später in den App-Einstellungen aktivieren. Wenn dein Gerät sie blockiert, musst du sie zuerst in den Systemeinstellungen erlauben.""";

  /// ```dart
  /// "OK"
  /// ```
  String get ok => """OK""";
}

class AboutMessagesDe extends AboutMessages {
  final MessagesDe _parent;
  const AboutMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Über"
  /// ```
  String get title => """Über""";

  /// ```dart
  /// "Entwickler"
  /// ```
  String get developer => """Entwickler""";

  /// ```dart
  /// "E-Mail"
  /// ```
  String get email => """E-Mail""";

  /// ```dart
  /// "Quellcode"
  /// ```
  String get repository => """Quellcode""";

  /// ```dart
  /// "Nextcloud-App"
  /// ```
  String get nextcloudApp => """Nextcloud-App""";

  /// ```dart
  /// "Datenschutzerklärung"
  /// ```
  String get privacyPolicy => """Datenschutzerklärung""";

  /// ```dart
  /// "Feedback & Probleme"
  /// ```
  String get feedback => """Feedback & Probleme""";

  /// ```dart
  /// "Nextcloud-Server"
  /// ```
  String get serverVersion => """Nextcloud-Server""";

  /// ```dart
  /// "Pantry auf Server"
  /// ```
  String get pantryServerVersion => """Pantry auf Server""";

  /// ```dart
  /// "Unbekannt"
  /// ```
  String get versionUnknown => """Unbekannt""";
}

class SettingsMessagesDe extends SettingsMessages {
  final MessagesDe _parent;
  const SettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "App-Einstellungen"
  /// ```
  String get title => """App-Einstellungen""";

  /// ```dart
  /// "Allgemein"
  /// ```
  String get generalSection => """Allgemein""";

  /// ```dart
  /// "Oberfläche"
  /// ```
  String get interfaceSection => """Oberfläche""";

  /// ```dart
  /// "Eintrag durch Tippen der Zeile abhaken"
  /// ```
  String get tapRowToComplete => """Eintrag durch Tippen der Zeile abhaken""";

  /// ```dart
  /// "Wenn aus, werden Einträge nur durch Tippen auf das Kontrollkästchen abgehakt."
  /// ```
  String get tapRowToCompleteBody =>
      """Wenn aus, werden Einträge nur durch Tippen auf das Kontrollkästchen abgehakt.""";

  /// ```dart
  /// "Fortschrittskarte in jeder Liste anzeigen"
  /// ```
  String get showProgressHero =>
      """Fortschrittskarte in jeder Liste anzeigen""";

  /// ```dart
  /// "Die Karte mit dem kreisförmigen Fortschrittsring und der Zusammenfassung der verbleibenden Einträge oben in jeder Liste. Wische die Karte weg, um sie auszublenden."
  /// ```
  String get showProgressHeroBody =>
      """Die Karte mit dem kreisförmigen Fortschrittsring und der Zusammenfassung der verbleibenden Einträge oben in jeder Liste. Wische die Karte weg, um sie auszublenden.""";

  /// ```dart
  /// "Abstand zwischen Kategorien in Listeneinträgen anzeigen"
  /// ```
  String get categorySpacing =>
      """Abstand zwischen Kategorien in Listeneinträgen anzeigen""";

  /// ```dart
  /// "Nur sichtbar bei Sortierung nach Kategorie"
  /// ```
  String get categorySpacingBody =>
      """Nur sichtbar bei Sortierung nach Kategorie""";
  CategorySpacingNamesSettingsMessagesDe get categorySpacingNames =>
      CategorySpacingNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Sprache"
  /// ```
  String get language => """Sprache""";
  LanguageNamesSettingsMessagesDe get languageNames =>
      LanguageNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Design"
  /// ```
  String get theme => """Design""";
  ThemeNamesSettingsMessagesDe get themeNames =>
      ThemeNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Benachrichtigungen"
  /// ```
  String get notificationsSection => """Benachrichtigungen""";

  /// ```dart
  /// "Benachrichtigungen aktivieren"
  /// ```
  String get enableNotifications => """Benachrichtigungen aktivieren""";

  /// ```dart
  /// "Zeige Benachrichtigungen, wenn Haushaltsmitglieder Inhalte hinzufugen oder aktualisieren."
  /// ```
  String get enableNotificationsBody =>
      """Zeige Benachrichtigungen, wenn Haushaltsmitglieder Inhalte hinzufugen oder aktualisieren.""";

  /// ```dart
  /// "Auf neue Aktivität prüfen"
  /// ```
  String get pollInterval => """Auf neue Aktivität prüfen""";

  /// ```dart
  /// "Alle 15 Minuten"
  /// ```
  String get pollInterval15m => """Alle 15 Minuten""";

  /// ```dart
  /// "Alle 30 Minuten"
  /// ```
  String get pollInterval30m => """Alle 30 Minuten""";

  /// ```dart
  /// "Stündlich"
  /// ```
  String get pollInterval1h => """Stündlich""";

  /// ```dart
  /// "Alle 2 Stunden"
  /// ```
  String get pollInterval2h => """Alle 2 Stunden""";

  /// ```dart
  /// "Alle 6 Stunden"
  /// ```
  String get pollInterval6h => """Alle 6 Stunden""";

  /// ```dart
  /// "Benachrichtigungsberechtigung wurde verweigert. Aktiviere sie in den Systemeinstellungen."
  /// ```
  String get permissionDenied =>
      """Benachrichtigungsberechtigung wurde verweigert. Aktiviere sie in den Systemeinstellungen.""";
}

class CategorySpacingNamesSettingsMessagesDe
    extends CategorySpacingNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const CategorySpacingNamesSettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Deaktiviert"
  /// ```
  String get disabled => """Deaktiviert""";

  /// ```dart
  /// "Abstand"
  /// ```
  String get space => """Abstand""";

  /// ```dart
  /// "Trennlinie"
  /// ```
  String get divider => """Trennlinie""";
}

class LanguageNamesSettingsMessagesDe extends LanguageNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const LanguageNamesSettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Systemstandard"
  /// ```
  String get system => """Systemstandard""";

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

class ThemeNamesSettingsMessagesDe extends ThemeNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const ThemeNamesSettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Systemstandard"
  /// ```
  String get system => """Systemstandard""";

  /// ```dart
  /// "Hell"
  /// ```
  String get light => """Hell""";

  /// ```dart
  /// "Dunkel"
  /// ```
  String get dark => """Dunkel""";
}

class NotificationsMessagesDe extends NotificationsMessages {
  final MessagesDe _parent;
  const NotificationsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Benachrichtigungen"
  /// ```
  String get title => """Benachrichtigungen""";

  /// ```dart
  /// "Keine neuen Benachrichtigungen."
  /// ```
  String get empty => """Keine neuen Benachrichtigungen.""";

  /// ```dart
  /// "Benachrichtigungen konnten nicht geladen werden."
  /// ```
  String get failedToLoad =>
      """Benachrichtigungen konnten nicht geladen werden.""";

  /// ```dart
  /// "Alle verwerfen"
  /// ```
  String get dismissAll => """Alle verwerfen""";

  /// ```dart
  /// "gerade eben"
  /// ```
  String get justNow => """gerade eben""";

  /// ```dart
  /// "vor ${count} Min."
  /// ```
  String minutesAgo(int count) => """vor ${count} Min.""";

  /// ```dart
  /// "vor ${count} Std."
  /// ```
  String hoursAgo(int count) => """vor ${count} Std.""";

  /// ```dart
  /// "vor ${count} T."
  /// ```
  String daysAgo(int count) => """vor ${count} T.""";
}

class CategoriesMessagesDe extends CategoriesMessages {
  final MessagesDe _parent;
  const CategoriesMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Kategorien verwalten"
  /// ```
  String get manageTitle => """Kategorien verwalten""";

  /// ```dart
  /// "Noch keine Kategorien."
  /// ```
  String get noCategories => """Noch keine Kategorien.""";

  /// ```dart
  /// "Kategorie bearbeiten"
  /// ```
  String get editTitle => """Kategorie bearbeiten""";

  /// ```dart
  /// "Neue Kategorie"
  /// ```
  String get addTitle => """Neue Kategorie""";

  /// ```dart
  /// "Name"
  /// ```
  String get name => """Name""";

  /// ```dart
  /// "Symbol"
  /// ```
  String get icon => """Symbol""";

  /// ```dart
  /// "Farbe"
  /// ```
  String get color => """Farbe""";

  /// ```dart
  /// "Kategorie konnte nicht gespeichert werden."
  /// ```
  String get saveFailed => """Kategorie konnte nicht gespeichert werden.""";

  /// ```dart
  /// "Kategorie konnte nicht gelöscht werden."
  /// ```
  String get deleteFailed => """Kategorie konnte nicht gelöscht werden.""";

  /// ```dart
  /// "Diese Kategorie löschen?"
  /// ```
  String get deleteConfirm => """Diese Kategorie löschen?""";

  /// ```dart
  /// "Einträge in dieser Kategorie werden unkategorisiert. Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get deleteConfirmBody =>
      """Einträge in dieser Kategorie werden unkategorisiert. Dies kann nicht rückgängig gemacht werden.""";
  SortCategoriesMessagesDe get sort => SortCategoriesMessagesDe(this);
}

class SortCategoriesMessagesDe extends SortCategoriesMessages {
  final CategoriesMessagesDe _parent;
  const SortCategoriesMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Name A–Z"
  /// ```
  String get nameAZ => """Name A–Z""";

  /// ```dart
  /// "Name Z–A"
  /// ```
  String get nameZA => """Name Z–A""";

  /// ```dart
  /// "Benutzerdefiniert"
  /// ```
  String get custom => """Benutzerdefiniert""";
}

class ChecklistsMessagesDe extends ChecklistsMessages {
  final MessagesDe _parent;
  const ChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Kategorien"
  /// ```
  String get categories => """Kategorien""";

  /// ```dart
  /// "Noch keine Checklisten."
  /// ```
  String get noChecklists => """Noch keine Checklisten.""";

  /// ```dart
  /// "Keine Einträge in dieser Liste."
  /// ```
  String get noItems => """Keine Einträge in dieser Liste.""";

  /// ```dart
  /// "Keine Einträge entsprechen Ihrer Suche."
  /// ```
  String get noSearchResults => """Keine Einträge entsprechen Ihrer Suche.""";

  /// ```dart
  /// "Zum Filtern tippen..."
  /// ```
  String get searchHint => """Zum Filtern tippen...""";

  /// ```dart
  /// "Alle"
  /// ```
  String get allCategories => """Alle""";

  /// ```dart
  /// "Checklisten konnten nicht geladen werden."
  /// ```
  String get failedToLoad => """Checklisten konnten nicht geladen werden.""";

  /// ```dart
  /// "Einträge konnten nicht geladen werden."
  /// ```
  String get failedToLoadItems => """Einträge konnten nicht geladen werden.""";

  /// ```dart
  /// "Erledigt ($count)"
  /// ```
  String completedCount(int count) => """Erledigt ($count)""";

  /// ```dart
  /// "Eintrag bearbeiten"
  /// ```
  String get editItem => """Eintrag bearbeiten""";

  /// ```dart
  /// "Eintrag entfernen"
  /// ```
  String get removeItem => """Eintrag entfernen""";

  /// ```dart
  /// "In Liste verschieben"
  /// ```
  String get moveItem => """In Liste verschieben""";

  /// ```dart
  /// "Eintrag konnte nicht verschoben werden."
  /// ```
  String get moveFailed => """Eintrag konnte nicht verschoben werden.""";

  /// ```dart
  /// "Eintrag als erledigt markiert"
  /// ```
  String get itemMarkedDone => """Eintrag als erledigt markiert""";

  /// ```dart
  /// "Eintrag entfernt"
  /// ```
  String get itemRemoved => """Eintrag entfernt""";

  /// ```dart
  /// "Rückgängig"
  /// ```
  String get undo => """Rückgängig""";

  /// ```dart
  /// "Papierkorb anzeigen"
  /// ```
  String get viewTrash => """Papierkorb anzeigen""";

  /// ```dart
  /// "Papierkorb verlassen"
  /// ```
  String get exitTrash => """Papierkorb verlassen""";

  /// ```dart
  /// "Anzeigen, wer Einträge hinzugefügt hat"
  /// ```
  String get showAddedBy => """Anzeigen, wer Einträge hinzugefügt hat""";

  /// ```dart
  /// "Hinzugefügt von $name"
  /// ```
  String addedBy(String name) => """Hinzugefügt von $name""";

  /// ```dart
  /// "Papierkorb"
  /// ```
  String get trashTitle => """Papierkorb""";

  /// ```dart
  /// "Der Papierkorb ist leer."
  /// ```
  String get noTrashedItems => """Der Papierkorb ist leer.""";

  /// ```dart
  /// "Papierkorb leeren"
  /// ```
  String get emptyTrash => """Papierkorb leeren""";

  /// ```dart
  /// "Papierkorb leeren?"
  /// ```
  String get emptyTrashConfirm => """Papierkorb leeren?""";

  /// ```dart
  /// "Alle Einträge im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get emptyTrashConfirmBody =>
      """Alle Einträge im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""";

  /// ```dart
  /// "Papierkorb konnte nicht geleert werden."
  /// ```
  String get emptyTrashFailed => """Papierkorb konnte nicht geleert werden.""";

  /// ```dart
  /// "Wiederherstellen"
  /// ```
  String get restoreItem => """Wiederherstellen""";

  /// ```dart
  /// "Endgültig löschen"
  /// ```
  String get permanentlyDeleteItem => """Endgültig löschen""";

  /// ```dart
  /// "Diesen Eintrag endgültig löschen?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """Diesen Eintrag endgültig löschen?""";

  /// ```dart
  /// "Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Dies kann nicht rückgängig gemacht werden.""";

  /// ```dart
  /// "Eintrag konnte nicht wiederhergestellt werden."
  /// ```
  String get restoreFailed =>
      """Eintrag konnte nicht wiederhergestellt werden.""";

  /// ```dart
  /// "Eintrag konnte nicht gelöscht werden."
  /// ```
  String get permanentlyDeleteFailed =>
      """Eintrag konnte nicht gelöscht werden.""";

  /// ```dart
  /// "Eintrag wiederhergestellt"
  /// ```
  String get itemRestored => """Eintrag wiederhergestellt""";

  /// ```dart
  /// "Neue Liste"
  /// ```
  String get createList => """Neue Liste""";

  /// ```dart
  /// "Listenname"
  /// ```
  String get listName => """Listenname""";

  /// ```dart
  /// "Beschreibung (optional)"
  /// ```
  String get listDescription => """Beschreibung (optional)""";

  /// ```dart
  /// "Symbol"
  /// ```
  String get listIcon => """Symbol""";

  /// ```dart
  /// "Liste konnte nicht erstellt werden."
  /// ```
  String get createListFailed => """Liste konnte nicht erstellt werden.""";
  ViewItemChecklistsMessagesDe get viewItem =>
      ViewItemChecklistsMessagesDe(this);
  ItemFormChecklistsMessagesDe get itemForm =>
      ItemFormChecklistsMessagesDe(this);
  SortChecklistsMessagesDe get sort => SortChecklistsMessagesDe(this);

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag übrig', many: '$count Einträge übrig')}"
  /// ```
  String itemsLeft(int count) =>
      """${_plural(count, one: '1 Eintrag übrig', many: '$count Einträge übrig')}""";

  /// ```dart
  /// "Alles erledigt 🎉"
  /// ```
  String get allDone => """Alles erledigt 🎉""";

  /// ```dart
  /// "$done von $total erledigt"
  /// ```
  String listProgress(int done, int total) => """$done von $total erledigt""";

  /// ```dart
  /// "Erledigt · $count"
  /// ```
  String doneCount(int count) => """Erledigt · $count""";

  /// ```dart
  /// "Zu $name hinzufügen…"
  /// ```
  String addToList(String name) => """Zu $name hinzufügen…""";

  /// ```dart
  /// "Füge deinen ersten Eintrag hinzu…"
  /// ```
  String get addFirstItem => """Füge deinen ersten Eintrag hinzu…""";

  /// ```dart
  /// "Noch nichts auf dieser Liste"
  /// ```
  String get noItemsTitle => """Noch nichts auf dieser Liste""";

  /// ```dart
  /// "Füge deinen ersten Eintrag über die Leiste unten hinzu — setze Kategorie, Menge oder Zeitplan über die Chips."
  /// ```
  String get noItemsBody =>
      """Füge deinen ersten Eintrag über die Leiste unten hinzu — setze Kategorie, Menge oder Zeitplan über die Chips.""";

  /// ```dart
  /// "Noch keine Listen"
  /// ```
  String get noListsTitle => """Noch keine Listen""";

  /// ```dart
  /// "Erstelle deine erste Liste, um Einkäufe, Besorgungen, Aufgaben oder alles, was dein Haushalt im Blick behalten muss, zu verfolgen."
  /// ```
  String get noListsBody =>
      """Erstelle deine erste Liste, um Einkäufe, Besorgungen, Aufgaben oder alles, was dein Haushalt im Blick behalten muss, zu verfolgen.""";

  /// ```dart
  /// "Erste Liste erstellen"
  /// ```
  String get createFirstList => """Erste Liste erstellen""";

  /// ```dart
  /// "Deine Listen"
  /// ```
  String get yourChecklists => """Deine Listen""";

  /// ```dart
  /// "${_plural(count, one: '1 Liste', many: '$count Listen')}"
  /// ```
  String listsCount(int count) =>
      """${_plural(count, one: '1 Liste', many: '$count Listen')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag', many: '$count Einträge')}"
  /// ```
  String itemsSummary(int count) =>
      """${_plural(count, one: '1 Eintrag', many: '$count Einträge')}""";

  /// ```dart
  /// "Alles erledigt · 0 übrig"
  /// ```
  String get allDoneSummary => """Alles erledigt · 0 übrig""";

  /// ```dart
  /// "Neue Liste"
  /// ```
  String get newChecklist => """Neue Liste""";

  /// ```dart
  /// "Liste erstellen"
  /// ```
  String get createListButton => """Liste erstellen""";

  /// ```dart
  /// "Anzeigen"
  /// ```
  String get view => """Anzeigen""";

  /// ```dart
  /// "Anzeigen"
  /// ```
  String get swipeView => """Anzeigen""";

  /// ```dart
  /// "Bearbeiten"
  /// ```
  String get swipeEdit => """Bearbeiten""";

  /// ```dart
  /// "Verschieben"
  /// ```
  String get swipeMove => """Verschieben""";

  /// ```dart
  /// "Löschen"
  /// ```
  String get swipeDelete => """Löschen""";

  /// ```dart
  /// "Listenansicht"
  /// ```
  String get viewList => """Listenansicht""";

  /// ```dart
  /// "Kartenansicht"
  /// ```
  String get viewCards => """Kartenansicht""";

  /// ```dart
  /// "Farbe"
  /// ```
  String get listColor => """Farbe""";
  ItemTypesChecklistsMessagesDe get itemTypes =>
      ItemTypesChecklistsMessagesDe(this);
  ComposeChecklistsMessagesDe get compose => ComposeChecklistsMessagesDe(this);
}

class ViewItemChecklistsMessagesDe extends ViewItemChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const ViewItemChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Menge:"
  /// ```
  String get quantity => """Menge:""";

  /// ```dart
  /// "Kategorie:"
  /// ```
  String get category => """Kategorie:""";

  /// ```dart
  /// "Wiederholung:"
  /// ```
  String get recurrence => """Wiederholung:""";

  /// ```dart
  /// "Nächstes Fälligkeitsdatum:"
  /// ```
  String get nextDue => """Nächstes Fälligkeitsdatum:""";

  /// ```dart
  /// "Nächstes Fälligkeitsdatum (ab Erledigung):"
  /// ```
  String get nextDueFromCompletion =>
      """Nächstes Fälligkeitsdatum (ab Erledigung):""";

  /// ```dart
  /// "Überfällig"
  /// ```
  String get overdue => """Überfällig""";
}

class ItemFormChecklistsMessagesDe extends ItemFormChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const ItemFormChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Eintrag hinzufügen"
  /// ```
  String get addTitle => """Eintrag hinzufügen""";

  /// ```dart
  /// "Eintrag bearbeiten"
  /// ```
  String get editTitle => """Eintrag bearbeiten""";

  /// ```dart
  /// "Eintragsname"
  /// ```
  String get name => """Eintragsname""";

  /// ```dart
  /// "Beschreibung"
  /// ```
  String get description => """Beschreibung""";

  /// ```dart
  /// "Menge"
  /// ```
  String get quantity => """Menge""";

  /// ```dart
  /// "Kategorie"
  /// ```
  String get category => """Kategorie""";

  /// ```dart
  /// "Keine"
  /// ```
  String get noCategory => """Keine""";

  /// ```dart
  /// "Keine Kategorien verfügbar."
  /// ```
  String get noCategories => """Keine Kategorien verfügbar.""";

  /// ```dart
  /// "Neue Kategorie"
  /// ```
  String get createCategory => """Neue Kategorie""";

  /// ```dart
  /// "Name"
  /// ```
  String get categoryName => """Name""";

  /// ```dart
  /// "Symbol"
  /// ```
  String get categoryIcon => """Symbol""";

  /// ```dart
  /// "Farbe"
  /// ```
  String get categoryColor => """Farbe""";

  /// ```dart
  /// "Kategorie erstellt."
  /// ```
  String get categoryCreated => """Kategorie erstellt.""";

  /// ```dart
  /// "Kategorie konnte nicht erstellt werden."
  /// ```
  String get categoryCreateFailed =>
      """Kategorie konnte nicht erstellt werden.""";

  /// ```dart
  /// "Wiederholen"
  /// ```
  String get repeat => """Wiederholen""";

  /// ```dart
  /// "Einmalig"
  /// ```
  String get once => """Einmalig""";

  /// ```dart
  /// "Diesen Eintrag löschen, sobald er als erledigt markiert ist."
  /// ```
  String get onceDescription =>
      """Diesen Eintrag löschen, sobald er als erledigt markiert ist.""";

  /// ```dart
  /// "Bild"
  /// ```
  String get image => """Bild""";

  /// ```dart
  /// "Bild hinzufügen"
  /// ```
  String get addImage => """Bild hinzufügen""";

  /// ```dart
  /// "Ersetzen"
  /// ```
  String get replaceImage => """Ersetzen""";

  /// ```dart
  /// "Entfernen"
  /// ```
  String get removeImage => """Entfernen""";

  /// ```dart
  /// "Eintrag konnte nicht gespeichert werden."
  /// ```
  String get saveFailed => """Eintrag konnte nicht gespeichert werden.""";

  /// ```dart
  /// "Eintrag konnte nicht gelöscht werden."
  /// ```
  String get deleteFailed => """Eintrag konnte nicht gelöscht werden.""";

  /// ```dart
  /// "Diesen Eintrag löschen?"
  /// ```
  String get deleteConfirm => """Diesen Eintrag löschen?""";

  /// ```dart
  /// "Änderungen speichern"
  /// ```
  String get save => """Änderungen speichern""";

  /// ```dart
  /// "Beschreibung hinzufügen (optional)"
  /// ```
  String get descHint => """Beschreibung hinzufügen (optional)""";

  /// ```dart
  /// "Ändern"
  /// ```
  String get categoryChange => """Ändern""";

  /// ```dart
  /// "Auswählen"
  /// ```
  String get categoryPick => """Auswählen""";

  /// ```dart
  /// "Unbenannter Eintrag"
  /// ```
  String get untitledItem => """Unbenannter Eintrag""";

  /// ```dart
  /// "Standardeintrag"
  /// ```
  String get typeStaple => """Standardeintrag""";

  /// ```dart
  /// "Einmaliger Eintrag"
  /// ```
  String get typeOnce => """Einmaliger Eintrag""";

  /// ```dart
  /// "Wiederkehrend"
  /// ```
  String get typeRecurring => """Wiederkehrend""";
}

class SortChecklistsMessagesDe extends SortChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const SortChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Neueste zuerst"
  /// ```
  String get newestFirst => """Neueste zuerst""";

  /// ```dart
  /// "Älteste zuerst"
  /// ```
  String get oldestFirst => """Älteste zuerst""";

  /// ```dart
  /// "Name A–Z"
  /// ```
  String get nameAZ => """Name A–Z""";

  /// ```dart
  /// "Name Z–A"
  /// ```
  String get nameZA => """Name Z–A""";

  /// ```dart
  /// "Nach Kategorie"
  /// ```
  String get category => """Nach Kategorie""";

  /// ```dart
  /// "Benutzerdefiniert"
  /// ```
  String get custom => """Benutzerdefiniert""";
}

class ItemTypesChecklistsMessagesDe extends ItemTypesChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const ItemTypesChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Eintragstyp"
  /// ```
  String get label => """Eintragstyp""";

  /// ```dart
  /// "Standard"
  /// ```
  String get staple => """Standard""";

  /// ```dart
  /// "Bleibt auf der Liste, nachdem du ihn erledigt hast"
  /// ```
  String get stapleBody =>
      """Bleibt auf der Liste, nachdem du ihn erledigt hast""";

  /// ```dart
  /// "Einmalig"
  /// ```
  String get onceTime => """Einmalig""";

  /// ```dart
  /// "Wird entfernt, sobald du ihn erledigt hast"
  /// ```
  String get onceTimeBody => """Wird entfernt, sobald du ihn erledigt hast""";

  /// ```dart
  /// "Wiederkehrend"
  /// ```
  String get recurring => """Wiederkehrend""";

  /// ```dart
  /// "Kommt nach Zeitplan zurück"
  /// ```
  String get recurringBody => """Kommt nach Zeitplan zurück""";

  /// ```dart
  /// "Wöchentlich"
  /// ```
  String get weekly => """Wöchentlich""";

  /// ```dart
  /// "Alle $n Wochen"
  /// ```
  String everyNWeeks(int n) => """Alle $n Wochen""";
}

class ComposeChecklistsMessagesDe extends ComposeChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const ComposeChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Kategorie"
  /// ```
  String get chipCategory => """Kategorie""";

  /// ```dart
  /// "Menge"
  /// ```
  String get chipQuantity => """Menge""";

  /// ```dart
  /// "Eintragstyp"
  /// ```
  String get chipType => """Eintragstyp""";

  /// ```dart
  /// "Bild"
  /// ```
  String get chipImage => """Bild""";

  /// ```dart
  /// "Beschreibung"
  /// ```
  String get chipDescription => """Beschreibung""";

  /// ```dart
  /// "Notizen, Hinweise, Links…"
  /// ```
  String get descHint => """Notizen, Hinweise, Links…""";

  /// ```dart
  /// "z. B. 2 L, 500 g"
  /// ```
  String get qtyHint => """z. B. 2 L, 500 g""";

  /// ```dart
  /// "＋ / − ändern die Zahl und behalten die Einheit."
  /// ```
  String get qtyStepperHelp =>
      """＋ / − ändern die Zahl und behalten die Einheit.""";

  /// ```dart
  /// "Keine"
  /// ```
  String get none => """Keine""";

  /// ```dart
  /// "Alle"
  /// ```
  String get every => """Alle""";

  /// ```dart
  /// "Woche"
  /// ```
  String get week => """Woche""";

  /// ```dart
  /// "Wochen"
  /// ```
  String get weeks => """Wochen""";
}

class NotesWallMessagesDe extends NotesWallMessages {
  final MessagesDe _parent;
  const NotesWallMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Noch keine Notizen."
  /// ```
  String get noNotes => """Noch keine Notizen.""";

  /// ```dart
  /// "Notizen konnten nicht geladen werden."
  /// ```
  String get failedToLoad => """Notizen konnten nicht geladen werden.""";

  /// ```dart
  /// "Notiz konnte nicht gespeichert werden."
  /// ```
  String get saveFailed => """Notiz konnte nicht gespeichert werden.""";

  /// ```dart
  /// "Notiz konnte nicht gelöscht werden."
  /// ```
  String get deleteFailed => """Notiz konnte nicht gelöscht werden.""";

  /// ```dart
  /// "Diese Notiz löschen?"
  /// ```
  String get deleteConfirm => """Diese Notiz löschen?""";

  /// ```dart
  /// "${_plural(count, one: 'Diese Notiz', many: '$count Notizen')} löschen?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """${_plural(count, one: 'Diese Notiz', many: '$count Notizen')} löschen?""";

  /// ```dart
  /// "${_plural(count, one: 'Notiz gelöscht', many: '$count Notizen gelöscht')}"
  /// ```
  String noteRemoved(int count) =>
      """${_plural(count, one: 'Notiz gelöscht', many: '$count Notizen gelöscht')}""";

  /// ```dart
  /// "Neue Notiz"
  /// ```
  String get newNote => """Neue Notiz""";

  /// ```dart
  /// "Notiz bearbeiten"
  /// ```
  String get editNote => """Notiz bearbeiten""";

  /// ```dart
  /// "Titel"
  /// ```
  String get title => """Titel""";

  /// ```dart
  /// "Inhalt"
  /// ```
  String get content => """Inhalt""";

  /// ```dart
  /// "Farbe"
  /// ```
  String get color => """Farbe""";
  SortNotesWallMessagesDe get sort => SortNotesWallMessagesDe(this);
}

class SortNotesWallMessagesDe extends SortNotesWallMessages {
  final NotesWallMessagesDe _parent;
  const SortNotesWallMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Neueste zuerst"
  /// ```
  String get newestFirst => """Neueste zuerst""";

  /// ```dart
  /// "Älteste zuerst"
  /// ```
  String get oldestFirst => """Älteste zuerst""";

  /// ```dart
  /// "Titel A–Z"
  /// ```
  String get titleAZ => """Titel A–Z""";

  /// ```dart
  /// "Titel Z–A"
  /// ```
  String get titleZA => """Titel Z–A""";

  /// ```dart
  /// "Benutzerdefiniert"
  /// ```
  String get custom => """Benutzerdefiniert""";
}

class PhotoBoardMessagesDe extends PhotoBoardMessages {
  final MessagesDe _parent;
  const PhotoBoardMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Noch keine Fotos."
  /// ```
  String get noPhotos => """Noch keine Fotos.""";

  /// ```dart
  /// "Fotos konnten nicht geladen werden."
  /// ```
  String get failedToLoad => """Fotos konnten nicht geladen werden.""";

  /// ```dart
  /// "Foto konnte nicht hochgeladen werden."
  /// ```
  String get uploadFailed => """Foto konnte nicht hochgeladen werden.""";

  /// ```dart
  /// "Foto konnte nicht gelöscht werden."
  /// ```
  String get deleteFailed => """Foto konnte nicht gelöscht werden.""";

  /// ```dart
  /// "Dieses Foto löschen?"
  /// ```
  String get deleteConfirm => """Dieses Foto löschen?""";

  /// ```dart
  /// "${_plural(count, one: 'Dieses Foto', many: '$count Fotos')} löschen?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """${_plural(count, one: 'Dieses Foto', many: '$count Fotos')} löschen?""";

  /// ```dart
  /// "${_plural(count, one: 'Foto gelöscht', many: '$count Fotos gelöscht')}"
  /// ```
  String photoRemoved(int count) =>
      """${_plural(count, one: 'Foto gelöscht', many: '$count Fotos gelöscht')}""";

  /// ```dart
  /// "Ordner löschen"
  /// ```
  String get deleteFolder => """Ordner löschen""";

  /// ```dart
  /// "Diesen Ordner löschen?"
  /// ```
  String get deleteFolderConfirm => """Diesen Ordner löschen?""";

  /// ```dart
  /// "Fotos ins Stammverzeichnis verschieben"
  /// ```
  String get deleteFolderKeepPhotos =>
      """Fotos ins Stammverzeichnis verschieben""";

  /// ```dart
  /// "Ordner und Fotos löschen"
  /// ```
  String get deleteFolderDeleteAll => """Ordner und Fotos löschen""";

  /// ```dart
  /// "Neuer Ordner"
  /// ```
  String get newFolder => """Neuer Ordner""";

  /// ```dart
  /// "Ordnername"
  /// ```
  String get folderName => """Ordnername""";

  /// ```dart
  /// "Ordner umbenennen"
  /// ```
  String get renameFolder => """Ordner umbenennen""";

  /// ```dart
  /// "Beschriftung"
  /// ```
  String get caption => """Beschriftung""";

  /// ```dart
  /// "$count"
  /// ```
  String photoCount(int count) => """$count""";
  AddMenuPhotoBoardMessagesDe get addMenu => AddMenuPhotoBoardMessagesDe(this);
  SortPhotoBoardMessagesDe get sort => SortPhotoBoardMessagesDe(this);
}

class AddMenuPhotoBoardMessagesDe extends AddMenuPhotoBoardMessages {
  final PhotoBoardMessagesDe _parent;
  const AddMenuPhotoBoardMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Fotos hochladen"
  /// ```
  String get upload => """Fotos hochladen""";

  /// ```dart
  /// "Foto aufnehmen"
  /// ```
  String get camera => """Foto aufnehmen""";

  /// ```dart
  /// "Neuer Ordner"
  /// ```
  String get newFolder => """Neuer Ordner""";
}

class SortPhotoBoardMessagesDe extends SortPhotoBoardMessages {
  final PhotoBoardMessagesDe _parent;
  const SortPhotoBoardMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Ordner zuerst"
  /// ```
  String get foldersFirst => """Ordner zuerst""";

  /// ```dart
  /// "Neueste zuerst"
  /// ```
  String get newestFirst => """Neueste zuerst""";

  /// ```dart
  /// "Älteste zuerst"
  /// ```
  String get oldestFirst => """Älteste zuerst""";

  /// ```dart
  /// "Beschriftung A–Z"
  /// ```
  String get captionAZ => """Beschriftung A–Z""";

  /// ```dart
  /// "Beschriftung Z–A"
  /// ```
  String get captionZA => """Beschriftung Z–A""";

  /// ```dart
  /// "Benutzerdefiniert"
  /// ```
  String get custom => """Benutzerdefiniert""";
}

class ShareMessagesDe extends ShareMessages {
  final MessagesDe _parent;
  const ShareMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "An Pantry senden"
  /// ```
  String get title => """An Pantry senden""";

  /// ```dart
  /// "Haus auswählen"
  /// ```
  String get chooseHouse => """Haus auswählen""";

  /// ```dart
  /// "Hochladen nach"
  /// ```
  String get choosePhotoDestination => """Hochladen nach""";

  /// ```dart
  /// "Fotowand"
  /// ```
  String get photoBoardRoot => """Fotowand""";

  /// ```dart
  /// "Neuer Ordner"
  /// ```
  String get newFolder => """Neuer Ordner""";

  /// ```dart
  /// "Ordnername"
  /// ```
  String get newFolderName => """Ordnername""";

  /// ```dart
  /// "Ordner konnte nicht erstellt werden."
  /// ```
  String get failedToCreateFolder => """Ordner konnte nicht erstellt werden.""";

  /// ```dart
  /// "Der geteilte Inhalt konnte nicht geöffnet werden."
  /// ```
  String get failedToOpenShare =>
      """Der geteilte Inhalt konnte nicht geöffnet werden.""";

  /// ```dart
  /// "Keine Häuser verfügbar. Erstelle zuerst ein Haus."
  /// ```
  String get noHouses =>
      """Keine Häuser verfügbar. Erstelle zuerst ein Haus.""";
}

class RecurrenceMessagesDe extends RecurrenceMessages {
  final MessagesDe _parent;
  const RecurrenceMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Wiederholung"
  /// ```
  String get title => """Wiederholung""";

  /// ```dart
  /// "Voreinstellungen"
  /// ```
  String get presets => """Voreinstellungen""";

  /// ```dart
  /// "Täglich"
  /// ```
  String get daily => """Täglich""";

  /// ```dart
  /// "Wöchentlich"
  /// ```
  String get weekly => """Wöchentlich""";

  /// ```dart
  /// "Monatlich"
  /// ```
  String get monthly => """Monatlich""";

  /// ```dart
  /// "Alle"
  /// ```
  String get everyLabel => """Alle""";

  /// ```dart
  /// "Einheit"
  /// ```
  String get unit => """Einheit""";

  /// ```dart
  /// "Tage"
  /// ```
  String get unitDays => """Tage""";

  /// ```dart
  /// "Wochen"
  /// ```
  String get unitWeeks => """Wochen""";

  /// ```dart
  /// "Monate"
  /// ```
  String get unitMonths => """Monate""";

  /// ```dart
  /// "Jahre"
  /// ```
  String get unitYears => """Jahre""";

  /// ```dart
  /// "Wiederholen am"
  /// ```
  String get repeatOn => """Wiederholen am""";

  /// ```dart
  /// "Endet"
  /// ```
  String get ends => """Endet""";

  /// ```dart
  /// "Nie"
  /// ```
  String get never => """Nie""";

  /// ```dart
  /// "Nach"
  /// ```
  String get after => """Nach""";

  /// ```dart
  /// "Wiederholungen"
  /// ```
  String get occurrences => """Wiederholungen""";

  /// ```dart
  /// "Am Datum"
  /// ```
  String get onDate => """Am Datum""";

  /// ```dart
  /// "Intervall ab dem Zeitpunkt der Erledigung berechnen"
  /// ```
  String get countFromCompletion =>
      """Intervall ab dem Zeitpunkt der Erledigung berechnen""";

  /// ```dart
  /// "Der Zeitplan ist fest: Der Eintrag erscheint zum nächsten geplanten Zeitpunkt wieder, unabhängig davon, wann du ihn abhakst."
  /// ```
  String get countFromCompletionHintOff =>
      """Der Zeitplan ist fest: Der Eintrag erscheint zum nächsten geplanten Zeitpunkt wieder, unabhängig davon, wann du ihn abhakst.""";

  /// ```dart
  /// "Der nächste Zeitpunkt wird ab dem Moment berechnet, in dem du den Eintrag abhakst, sodass er immer ein volles Intervall nach der Erledigung zurückkehrt."
  /// ```
  String get countFromCompletionHintOn =>
      """Der nächste Zeitpunkt wird ab dem Moment berechnet, in dem du den Eintrag abhakst, sodass er immer ein volles Intervall nach der Erledigung zurückkehrt.""";

  /// ```dart
  /// "Zusammenfassung"
  /// ```
  String get summary => """Zusammenfassung""";

  /// ```dart
  /// "nicht gesetzt"
  /// ```
  String get notSet => """nicht gesetzt""";

  /// ```dart
  /// "gesetzt"
  /// ```
  String get set => """gesetzt""";

  /// ```dart
  /// "alle $unit"
  /// ```
  String every(String unit) => """alle $unit""";

  /// ```dart
  /// "Alle $unit"
  /// ```
  String everyButton(String unit) => """Alle $unit""";

  /// ```dart
  /// "am $days"
  /// ```
  String onDays(String days) => """am $days""";

  /// ```dart
  /// "${_plural(count, one: 'Tag', many: '$count Tage')}"
  /// ```
  String day(int count) =>
      """${_plural(count, one: 'Tag', many: '$count Tage')}""";

  /// ```dart
  /// "${_plural(count, one: 'Woche', many: '$count Wochen')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'Woche', many: '$count Wochen')}""";

  /// ```dart
  /// "${_plural(count, one: 'Monat', many: '$count Monate')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'Monat', many: '$count Monate')}""";

  /// ```dart
  /// "${_plural(count, one: 'Jahr', many: '$count Jahre')}"
  /// ```
  String year(int count) =>
      """${_plural(count, one: 'Jahr', many: '$count Jahre')}""";
  DayNamesRecurrenceMessagesDe get dayNames =>
      DayNamesRecurrenceMessagesDe(this);
  DayAbbrRecurrenceMessagesDe get dayAbbr => DayAbbrRecurrenceMessagesDe(this);
}

class DayNamesRecurrenceMessagesDe extends DayNamesRecurrenceMessages {
  final RecurrenceMessagesDe _parent;
  const DayNamesRecurrenceMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Montag"
  /// ```
  String get monday => """Montag""";

  /// ```dart
  /// "Dienstag"
  /// ```
  String get tuesday => """Dienstag""";

  /// ```dart
  /// "Mittwoch"
  /// ```
  String get wednesday => """Mittwoch""";

  /// ```dart
  /// "Donnerstag"
  /// ```
  String get thursday => """Donnerstag""";

  /// ```dart
  /// "Freitag"
  /// ```
  String get friday => """Freitag""";

  /// ```dart
  /// "Samstag"
  /// ```
  String get saturday => """Samstag""";

  /// ```dart
  /// "Sonntag"
  /// ```
  String get sunday => """Sonntag""";
}

class DayAbbrRecurrenceMessagesDe extends DayAbbrRecurrenceMessages {
  final RecurrenceMessagesDe _parent;
  const DayAbbrRecurrenceMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Mo"
  /// ```
  String get mo => """Mo""";

  /// ```dart
  /// "Di"
  /// ```
  String get tu => """Di""";

  /// ```dart
  /// "Mi"
  /// ```
  String get we => """Mi""";

  /// ```dart
  /// "Do"
  /// ```
  String get th => """Do""";

  /// ```dart
  /// "Fr"
  /// ```
  String get fr => """Fr""";

  /// ```dart
  /// "Sa"
  /// ```
  String get sa => """Sa""";

  /// ```dart
  /// "So"
  /// ```
  String get su => """So""";
}

Map<String, String> get messagesDeMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Abbrechen""",
  """common.delete""": """Löschen""",
  """common.save""": """Speichern""",
  """common.retry""": """Erneut versuchen""",
  """common.refresh""": """Aktualisieren""",
  """common.logout""": """Abmelden""",
  """common.loading""": """Laden...""",
  """common.error""": """Fehler""",
  """login.connectToNextcloud""": """Mit deiner Nextcloud-Instanz verbinden""",
  """login.serverUrl""": """Server-URL""",
  """login.serverUrlHint""": """cloud.example.com""",
  """login.connect""": """Verbinden""",
  """login.waitingForAuth""": """Warte auf Authentifizierung...
Bitte melde dich in deinem Browser an.""",
  """login.couldNotConnect""":
      """Verbindung zum Server fehlgeschlagen. Bitte überprüfe die URL.""",
  """login.loginFailed""":
      """Anmeldung fehlgeschlagen. Bitte versuche es erneut.""",
  """home.noHouses""": """Noch keine Häuser.""",
  """home.noHousesBody""":
      """Häuser sind gemeinsame Bereiche für deinen Haushalt. Erstelle dein erstes Haus, um Checklisten, Fotos und Notizen hinzuzufügen.""",
  """home.createHouse""": """Haus erstellen""",
  """home.houseName""": """Hausname""",
  """home.houseDescription""": """Beschreibung (optional)""",
  """home.createHouseFailed""": """Haus konnte nicht erstellt werden.""",
  """home.failedToLoadHouses""": """Häuser konnten nicht geladen werden.""",
  """home.serverAppMissingTitle""": """Pantry ist nicht installiert""",
  """home.serverAppMissingBody""":
      """Diese App ist ein Client für die Pantry-App auf Nextcloud. Es scheint, dass Pantry noch nicht auf deinem Server installiert ist. Bitte deinen Administrator, es aus dem Nextcloud App Store zu installieren, oder installiere es selbst, wenn du Administratorzugang hast.""",
  """home.openAppStore""": """Nextcloud-Apps öffnen""",
  """home.learnMore""": """Mehr erfahren""",
  """nav.checklists""": """Checklisten""",
  """nav.photoBoard""": """Fotowand""",
  """nav.notesWall""": """Notizwand""",
  """onboarding.next""": """Weiter""",
  """onboarding.back""": """Zurück""",
  """onboarding.skip""": """Überspringen""",
  """onboarding.done""": """Loslegen""",
  """onboarding.welcomeNewTitle""": """Willkommen bei Pantry""",
  """onboarding.welcomeNewBody""":
      """Lass uns kurz durchgehen, wie Pantry funktioniert, damit du das Beste herausholst.""",
  """onboarding.welcomeUpdateTitle""": """Was ist neu""",
  """onboarding.welcomeUpdateBody""":
      """Seit deinem letzten Besuch hat Pantry ein paar neue Tricks gelernt. Hier ein kurzer Überblick.""",
  """onboarding.checklistsRedesignTitle""": """Checklisten im neuen Look""",
  """onboarding.checklistsRedesignBody""":
      """Die Checklisten-Seite wurde von Grund auf neu gebaut — übersichtlicheres Layout, schnelleres Hinzufügen und Schnellaktionen für jede Zeile. Die nächsten Seiten zeigen dir, was neu ist.""",
  """onboarding.checklistSelectorTitle""": """Listen oben wechseln""",
  """onboarding.checklistSelectorBody""":
      """Tippe auf den Listennamen oder das Symbol oben, um zwischen Listen zu wechseln oder eine neue zu erstellen.""",
  """onboarding.checklistSelectorHint""": """Tippen zum Wechseln""",
  """onboarding.mockListGroceries""": """Lebensmittel""",
  """onboarding.mockListHardware""": """Baumarkt""",
  """onboarding.mockListWeekend""": """Wochenendtrip""",
  """onboarding.newListLabel""": """Neue Liste""",
  """onboarding.swipeActionsTitle""": """Einträge durch Wischen verwalten""",
  """onboarding.swipeActionsBody""":
      """Wische einen Listeneintrag von rechts nach links, um schnelle Aktionen zum Bearbeiten, Verschieben oder Löschen einzublenden.""",
  """onboarding.swipeActionsHint""": """Nach links wischen""",
  """onboarding.swipeActionsHintBack""": """Nach rechts wischen""",
  """onboarding.addItemsTitle""": """Einträge schneller hinzufügen""",
  """onboarding.addItemsBody""":
      """Tippe auf das Feld unten, um einen neuen Eintrag einzugeben, und versieh ihn dann über die Chips darüber mit Kategorie, Menge, Typ oder Foto.""",
  """onboarding.mockComposeListName""": """Lebensmittel""",
  """onboarding.progressHeroTitle""": """Fortschrittskarte ausblenden""",
  """onboarding.progressHeroBody""":
      """Brauchst du den Fortschrittsring oben nicht? Wisch ihn einfach weg.""",
  """onboarding.progressHeroHint""": """Zum Ausblenden wischen""",
  """onboarding.mockItemName""": """Tomaten""",
  """onboarding.mockItemQuantity""": """x2""",
  """onboarding.mockItemCategory""": """Gemüse""",
  """onboarding.dev.showOnboarding""": """Onboarding anzeigen""",
  """onboarding.dev.pickLastSeenTitle""":
      """Zuletzt gesehene Version simulieren""",
  """onboarding.dev.pickLastSeenBody""":
      """Wähle, welche Version das Gerät zuletzt gesehen haben soll, dann wird das Onboarding von dort gestartet.""",
  """onboarding.dev.neverSeen""": """Noch nie gesehen (neuer Benutzer)""",
  """notificationsIntro.title""": """Bleib auf dem Laufenden""",
  """notificationsIntro.body""":
      """Pantry kann dich benachrichtigen, wenn Haushaltsmitglieder Einträge zu Checklisten hinzufügen, Fotos hochladen oder Notizen hinterlassen. Benachrichtigungen werden direkt von deinem Nextcloud-Server abgerufen — nichts geht über Google oder Drittanbieter.""",
  """notificationsIntro.bullet1""":
      """Benachrichtigungen über Haushaltsaktivitäten""",
  """notificationsIntro.bullet2""": """Direkt von deinem Server abgerufen""",
  """notificationsIntro.bullet3""":
      """Funktioniert auch bei geschlossener App""",
  """notificationsIntro.enableButton""": """Benachrichtigungen aktivieren""",
  """notificationsIntro.skipButton""": """Nicht jetzt""",
  """notificationsIntro.permissionDeniedTitle""": """Berechtigung verweigert""",
  """notificationsIntro.permissionDeniedBody""":
      """Du kannst Benachrichtigungen später in den App-Einstellungen aktivieren. Wenn dein Gerät sie blockiert, musst du sie zuerst in den Systemeinstellungen erlauben.""",
  """notificationsIntro.ok""": """OK""",
  """about.title""": """Über""",
  """about.developer""": """Entwickler""",
  """about.email""": """E-Mail""",
  """about.repository""": """Quellcode""",
  """about.nextcloudApp""": """Nextcloud-App""",
  """about.privacyPolicy""": """Datenschutzerklärung""",
  """about.feedback""": """Feedback & Probleme""",
  """about.serverVersion""": """Nextcloud-Server""",
  """about.pantryServerVersion""": """Pantry auf Server""",
  """about.versionUnknown""": """Unbekannt""",
  """settings.title""": """App-Einstellungen""",
  """settings.generalSection""": """Allgemein""",
  """settings.interfaceSection""": """Oberfläche""",
  """settings.tapRowToComplete""": """Eintrag durch Tippen der Zeile abhaken""",
  """settings.tapRowToCompleteBody""":
      """Wenn aus, werden Einträge nur durch Tippen auf das Kontrollkästchen abgehakt.""",
  """settings.showProgressHero""":
      """Fortschrittskarte in jeder Liste anzeigen""",
  """settings.showProgressHeroBody""":
      """Die Karte mit dem kreisförmigen Fortschrittsring und der Zusammenfassung der verbleibenden Einträge oben in jeder Liste. Wische die Karte weg, um sie auszublenden.""",
  """settings.categorySpacing""":
      """Abstand zwischen Kategorien in Listeneinträgen anzeigen""",
  """settings.categorySpacingBody""":
      """Nur sichtbar bei Sortierung nach Kategorie""",
  """settings.categorySpacingNames.disabled""": """Deaktiviert""",
  """settings.categorySpacingNames.space""": """Abstand""",
  """settings.categorySpacingNames.divider""": """Trennlinie""",
  """settings.language""": """Sprache""",
  """settings.languageNames.system""": """Systemstandard""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
  """settings.theme""": """Design""",
  """settings.themeNames.system""": """Systemstandard""",
  """settings.themeNames.light""": """Hell""",
  """settings.themeNames.dark""": """Dunkel""",
  """settings.notificationsSection""": """Benachrichtigungen""",
  """settings.enableNotifications""": """Benachrichtigungen aktivieren""",
  """settings.enableNotificationsBody""":
      """Zeige Benachrichtigungen, wenn Haushaltsmitglieder Inhalte hinzufugen oder aktualisieren.""",
  """settings.pollInterval""": """Auf neue Aktivität prüfen""",
  """settings.pollInterval15m""": """Alle 15 Minuten""",
  """settings.pollInterval30m""": """Alle 30 Minuten""",
  """settings.pollInterval1h""": """Stündlich""",
  """settings.pollInterval2h""": """Alle 2 Stunden""",
  """settings.pollInterval6h""": """Alle 6 Stunden""",
  """settings.permissionDenied""":
      """Benachrichtigungsberechtigung wurde verweigert. Aktiviere sie in den Systemeinstellungen.""",
  """notifications.title""": """Benachrichtigungen""",
  """notifications.empty""": """Keine neuen Benachrichtigungen.""",
  """notifications.failedToLoad""":
      """Benachrichtigungen konnten nicht geladen werden.""",
  """notifications.dismissAll""": """Alle verwerfen""",
  """notifications.justNow""": """gerade eben""",
  """categories.manageTitle""": """Kategorien verwalten""",
  """categories.noCategories""": """Noch keine Kategorien.""",
  """categories.editTitle""": """Kategorie bearbeiten""",
  """categories.addTitle""": """Neue Kategorie""",
  """categories.name""": """Name""",
  """categories.icon""": """Symbol""",
  """categories.color""": """Farbe""",
  """categories.saveFailed""": """Kategorie konnte nicht gespeichert werden.""",
  """categories.deleteFailed""": """Kategorie konnte nicht gelöscht werden.""",
  """categories.deleteConfirm""": """Diese Kategorie löschen?""",
  """categories.deleteConfirmBody""":
      """Einträge in dieser Kategorie werden unkategorisiert. Dies kann nicht rückgängig gemacht werden.""",
  """categories.sort.nameAZ""": """Name A–Z""",
  """categories.sort.nameZA""": """Name Z–A""",
  """categories.sort.custom""": """Benutzerdefiniert""",
  """checklists.categories""": """Kategorien""",
  """checklists.noChecklists""": """Noch keine Checklisten.""",
  """checklists.noItems""": """Keine Einträge in dieser Liste.""",
  """checklists.noSearchResults""":
      """Keine Einträge entsprechen Ihrer Suche.""",
  """checklists.searchHint""": """Zum Filtern tippen...""",
  """checklists.allCategories""": """Alle""",
  """checklists.failedToLoad""":
      """Checklisten konnten nicht geladen werden.""",
  """checklists.failedToLoadItems""":
      """Einträge konnten nicht geladen werden.""",
  """checklists.editItem""": """Eintrag bearbeiten""",
  """checklists.removeItem""": """Eintrag entfernen""",
  """checklists.moveItem""": """In Liste verschieben""",
  """checklists.moveFailed""": """Eintrag konnte nicht verschoben werden.""",
  """checklists.itemMarkedDone""": """Eintrag als erledigt markiert""",
  """checklists.itemRemoved""": """Eintrag entfernt""",
  """checklists.undo""": """Rückgängig""",
  """checklists.viewTrash""": """Papierkorb anzeigen""",
  """checklists.exitTrash""": """Papierkorb verlassen""",
  """checklists.showAddedBy""": """Anzeigen, wer Einträge hinzugefügt hat""",
  """checklists.trashTitle""": """Papierkorb""",
  """checklists.noTrashedItems""": """Der Papierkorb ist leer.""",
  """checklists.emptyTrash""": """Papierkorb leeren""",
  """checklists.emptyTrashConfirm""": """Papierkorb leeren?""",
  """checklists.emptyTrashConfirmBody""":
      """Alle Einträge im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""",
  """checklists.emptyTrashFailed""":
      """Papierkorb konnte nicht geleert werden.""",
  """checklists.restoreItem""": """Wiederherstellen""",
  """checklists.permanentlyDeleteItem""": """Endgültig löschen""",
  """checklists.permanentlyDeleteConfirm""":
      """Diesen Eintrag endgültig löschen?""",
  """checklists.permanentlyDeleteConfirmBody""":
      """Dies kann nicht rückgängig gemacht werden.""",
  """checklists.restoreFailed""":
      """Eintrag konnte nicht wiederhergestellt werden.""",
  """checklists.permanentlyDeleteFailed""":
      """Eintrag konnte nicht gelöscht werden.""",
  """checklists.itemRestored""": """Eintrag wiederhergestellt""",
  """checklists.createList""": """Neue Liste""",
  """checklists.listName""": """Listenname""",
  """checklists.listDescription""": """Beschreibung (optional)""",
  """checklists.listIcon""": """Symbol""",
  """checklists.createListFailed""": """Liste konnte nicht erstellt werden.""",
  """checklists.viewItem.quantity""": """Menge:""",
  """checklists.viewItem.category""": """Kategorie:""",
  """checklists.viewItem.recurrence""": """Wiederholung:""",
  """checklists.viewItem.nextDue""": """Nächstes Fälligkeitsdatum:""",
  """checklists.viewItem.nextDueFromCompletion""":
      """Nächstes Fälligkeitsdatum (ab Erledigung):""",
  """checklists.viewItem.overdue""": """Überfällig""",
  """checklists.itemForm.addTitle""": """Eintrag hinzufügen""",
  """checklists.itemForm.editTitle""": """Eintrag bearbeiten""",
  """checklists.itemForm.name""": """Eintragsname""",
  """checklists.itemForm.description""": """Beschreibung""",
  """checklists.itemForm.quantity""": """Menge""",
  """checklists.itemForm.category""": """Kategorie""",
  """checklists.itemForm.noCategory""": """Keine""",
  """checklists.itemForm.noCategories""": """Keine Kategorien verfügbar.""",
  """checklists.itemForm.createCategory""": """Neue Kategorie""",
  """checklists.itemForm.categoryName""": """Name""",
  """checklists.itemForm.categoryIcon""": """Symbol""",
  """checklists.itemForm.categoryColor""": """Farbe""",
  """checklists.itemForm.categoryCreated""": """Kategorie erstellt.""",
  """checklists.itemForm.categoryCreateFailed""":
      """Kategorie konnte nicht erstellt werden.""",
  """checklists.itemForm.repeat""": """Wiederholen""",
  """checklists.itemForm.once""": """Einmalig""",
  """checklists.itemForm.onceDescription""":
      """Diesen Eintrag löschen, sobald er als erledigt markiert ist.""",
  """checklists.itemForm.image""": """Bild""",
  """checklists.itemForm.addImage""": """Bild hinzufügen""",
  """checklists.itemForm.replaceImage""": """Ersetzen""",
  """checklists.itemForm.removeImage""": """Entfernen""",
  """checklists.itemForm.saveFailed""":
      """Eintrag konnte nicht gespeichert werden.""",
  """checklists.itemForm.deleteFailed""":
      """Eintrag konnte nicht gelöscht werden.""",
  """checklists.itemForm.deleteConfirm""": """Diesen Eintrag löschen?""",
  """checklists.itemForm.save""": """Änderungen speichern""",
  """checklists.itemForm.descHint""": """Beschreibung hinzufügen (optional)""",
  """checklists.itemForm.categoryChange""": """Ändern""",
  """checklists.itemForm.categoryPick""": """Auswählen""",
  """checklists.itemForm.untitledItem""": """Unbenannter Eintrag""",
  """checklists.itemForm.typeStaple""": """Standardeintrag""",
  """checklists.itemForm.typeOnce""": """Einmaliger Eintrag""",
  """checklists.itemForm.typeRecurring""": """Wiederkehrend""",
  """checklists.sort.newestFirst""": """Neueste zuerst""",
  """checklists.sort.oldestFirst""": """Älteste zuerst""",
  """checklists.sort.nameAZ""": """Name A–Z""",
  """checklists.sort.nameZA""": """Name Z–A""",
  """checklists.sort.category""": """Nach Kategorie""",
  """checklists.sort.custom""": """Benutzerdefiniert""",
  """checklists.allDone""": """Alles erledigt 🎉""",
  """checklists.addFirstItem""": """Füge deinen ersten Eintrag hinzu…""",
  """checklists.noItemsTitle""": """Noch nichts auf dieser Liste""",
  """checklists.noItemsBody""":
      """Füge deinen ersten Eintrag über die Leiste unten hinzu — setze Kategorie, Menge oder Zeitplan über die Chips.""",
  """checklists.noListsTitle""": """Noch keine Listen""",
  """checklists.noListsBody""":
      """Erstelle deine erste Liste, um Einkäufe, Besorgungen, Aufgaben oder alles, was dein Haushalt im Blick behalten muss, zu verfolgen.""",
  """checklists.createFirstList""": """Erste Liste erstellen""",
  """checklists.yourChecklists""": """Deine Listen""",
  """checklists.allDoneSummary""": """Alles erledigt · 0 übrig""",
  """checklists.newChecklist""": """Neue Liste""",
  """checklists.createListButton""": """Liste erstellen""",
  """checklists.view""": """Anzeigen""",
  """checklists.swipeView""": """Anzeigen""",
  """checklists.swipeEdit""": """Bearbeiten""",
  """checklists.swipeMove""": """Verschieben""",
  """checklists.swipeDelete""": """Löschen""",
  """checklists.viewList""": """Listenansicht""",
  """checklists.viewCards""": """Kartenansicht""",
  """checklists.listColor""": """Farbe""",
  """checklists.itemTypes.label""": """Eintragstyp""",
  """checklists.itemTypes.staple""": """Standard""",
  """checklists.itemTypes.stapleBody""":
      """Bleibt auf der Liste, nachdem du ihn erledigt hast""",
  """checklists.itemTypes.onceTime""": """Einmalig""",
  """checklists.itemTypes.onceTimeBody""":
      """Wird entfernt, sobald du ihn erledigt hast""",
  """checklists.itemTypes.recurring""": """Wiederkehrend""",
  """checklists.itemTypes.recurringBody""": """Kommt nach Zeitplan zurück""",
  """checklists.itemTypes.weekly""": """Wöchentlich""",
  """checklists.compose.chipCategory""": """Kategorie""",
  """checklists.compose.chipQuantity""": """Menge""",
  """checklists.compose.chipType""": """Eintragstyp""",
  """checklists.compose.chipImage""": """Bild""",
  """checklists.compose.chipDescription""": """Beschreibung""",
  """checklists.compose.descHint""": """Notizen, Hinweise, Links…""",
  """checklists.compose.qtyHint""": """z. B. 2 L, 500 g""",
  """checklists.compose.qtyStepperHelp""":
      """＋ / − ändern die Zahl und behalten die Einheit.""",
  """checklists.compose.none""": """Keine""",
  """checklists.compose.every""": """Alle""",
  """checklists.compose.week""": """Woche""",
  """checklists.compose.weeks""": """Wochen""",
  """notesWall.noNotes""": """Noch keine Notizen.""",
  """notesWall.failedToLoad""": """Notizen konnten nicht geladen werden.""",
  """notesWall.saveFailed""": """Notiz konnte nicht gespeichert werden.""",
  """notesWall.deleteFailed""": """Notiz konnte nicht gelöscht werden.""",
  """notesWall.deleteConfirm""": """Diese Notiz löschen?""",
  """notesWall.newNote""": """Neue Notiz""",
  """notesWall.editNote""": """Notiz bearbeiten""",
  """notesWall.title""": """Titel""",
  """notesWall.content""": """Inhalt""",
  """notesWall.color""": """Farbe""",
  """notesWall.sort.newestFirst""": """Neueste zuerst""",
  """notesWall.sort.oldestFirst""": """Älteste zuerst""",
  """notesWall.sort.titleAZ""": """Titel A–Z""",
  """notesWall.sort.titleZA""": """Titel Z–A""",
  """notesWall.sort.custom""": """Benutzerdefiniert""",
  """photoBoard.noPhotos""": """Noch keine Fotos.""",
  """photoBoard.failedToLoad""": """Fotos konnten nicht geladen werden.""",
  """photoBoard.uploadFailed""": """Foto konnte nicht hochgeladen werden.""",
  """photoBoard.deleteFailed""": """Foto konnte nicht gelöscht werden.""",
  """photoBoard.deleteConfirm""": """Dieses Foto löschen?""",
  """photoBoard.deleteFolder""": """Ordner löschen""",
  """photoBoard.deleteFolderConfirm""": """Diesen Ordner löschen?""",
  """photoBoard.deleteFolderKeepPhotos""":
      """Fotos ins Stammverzeichnis verschieben""",
  """photoBoard.deleteFolderDeleteAll""": """Ordner und Fotos löschen""",
  """photoBoard.newFolder""": """Neuer Ordner""",
  """photoBoard.folderName""": """Ordnername""",
  """photoBoard.renameFolder""": """Ordner umbenennen""",
  """photoBoard.caption""": """Beschriftung""",
  """photoBoard.addMenu.upload""": """Fotos hochladen""",
  """photoBoard.addMenu.camera""": """Foto aufnehmen""",
  """photoBoard.addMenu.newFolder""": """Neuer Ordner""",
  """photoBoard.sort.foldersFirst""": """Ordner zuerst""",
  """photoBoard.sort.newestFirst""": """Neueste zuerst""",
  """photoBoard.sort.oldestFirst""": """Älteste zuerst""",
  """photoBoard.sort.captionAZ""": """Beschriftung A–Z""",
  """photoBoard.sort.captionZA""": """Beschriftung Z–A""",
  """photoBoard.sort.custom""": """Benutzerdefiniert""",
  """share.title""": """An Pantry senden""",
  """share.chooseHouse""": """Haus auswählen""",
  """share.choosePhotoDestination""": """Hochladen nach""",
  """share.photoBoardRoot""": """Fotowand""",
  """share.newFolder""": """Neuer Ordner""",
  """share.newFolderName""": """Ordnername""",
  """share.failedToCreateFolder""": """Ordner konnte nicht erstellt werden.""",
  """share.failedToOpenShare""":
      """Der geteilte Inhalt konnte nicht geöffnet werden.""",
  """share.noHouses""": """Keine Häuser verfügbar. Erstelle zuerst ein Haus.""",
  """recurrence.title""": """Wiederholung""",
  """recurrence.presets""": """Voreinstellungen""",
  """recurrence.daily""": """Täglich""",
  """recurrence.weekly""": """Wöchentlich""",
  """recurrence.monthly""": """Monatlich""",
  """recurrence.everyLabel""": """Alle""",
  """recurrence.unit""": """Einheit""",
  """recurrence.unitDays""": """Tage""",
  """recurrence.unitWeeks""": """Wochen""",
  """recurrence.unitMonths""": """Monate""",
  """recurrence.unitYears""": """Jahre""",
  """recurrence.repeatOn""": """Wiederholen am""",
  """recurrence.ends""": """Endet""",
  """recurrence.never""": """Nie""",
  """recurrence.after""": """Nach""",
  """recurrence.occurrences""": """Wiederholungen""",
  """recurrence.onDate""": """Am Datum""",
  """recurrence.countFromCompletion""":
      """Intervall ab dem Zeitpunkt der Erledigung berechnen""",
  """recurrence.countFromCompletionHintOff""":
      """Der Zeitplan ist fest: Der Eintrag erscheint zum nächsten geplanten Zeitpunkt wieder, unabhängig davon, wann du ihn abhakst.""",
  """recurrence.countFromCompletionHintOn""":
      """Der nächste Zeitpunkt wird ab dem Moment berechnet, in dem du den Eintrag abhakst, sodass er immer ein volles Intervall nach der Erledigung zurückkehrt.""",
  """recurrence.summary""": """Zusammenfassung""",
  """recurrence.notSet""": """nicht gesetzt""",
  """recurrence.set""": """gesetzt""",
  """recurrence.dayNames.monday""": """Montag""",
  """recurrence.dayNames.tuesday""": """Dienstag""",
  """recurrence.dayNames.wednesday""": """Mittwoch""",
  """recurrence.dayNames.thursday""": """Donnerstag""",
  """recurrence.dayNames.friday""": """Freitag""",
  """recurrence.dayNames.saturday""": """Samstag""",
  """recurrence.dayNames.sunday""": """Sonntag""",
  """recurrence.dayAbbr.mo""": """Mo""",
  """recurrence.dayAbbr.tu""": """Di""",
  """recurrence.dayAbbr.we""": """Mi""",
  """recurrence.dayAbbr.th""": """Do""",
  """recurrence.dayAbbr.fr""": """Fr""",
  """recurrence.dayAbbr.sa""": """Sa""",
  """recurrence.dayAbbr.su""": """So""",
};
