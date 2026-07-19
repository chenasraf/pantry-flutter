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
  SyncMessagesDe get sync => SyncMessagesDe(this);
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

  /// ```dart
  /// "Kopieren"
  /// ```
  String get copy => """Kopieren""";

  /// ```dart
  /// "Kopiert"
  /// ```
  String get copied => """Kopiert""";

  /// ```dart
  /// "Fertig"
  /// ```
  String get closeDialog => """Fertig""";

  /// ```dart
  /// "Entfernen"
  /// ```
  String get remove => """Entfernen""";

  /// ```dart
  /// "Dazu hast du keine Berechtigung"
  /// ```
  String get permissionDenied => """Dazu hast du keine Berechtigung""";

  /// ```dart
  /// "Kein Zugriff"
  /// ```
  String get noAccessTitle => """Kein Zugriff""";

  /// ```dart
  /// "Du hast noch keinen Zugriff auf Inhalte in diesem Haushalt. Eine Administratorin oder ein Administrator kann dir in der Pantry-Web-App Berechtigungen erteilen."
  /// ```
  String get noAccessBody =>
      """Du hast noch keinen Zugriff auf Inhalte in diesem Haushalt. Eine Administratorin oder ein Administrator kann dir in der Pantry-Web-App Berechtigungen erteilen.""";
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

  /// ```dart
  /// "Details anzeigen"
  /// ```
  String get seeDetails => """Details anzeigen""";

  /// ```dart
  /// "Fehlerdetails"
  /// ```
  String get errorDetailsTitle => """Fehlerdetails""";

  /// ```dart
  /// "Nicht vertrauenswürdiges Zertifikat"
  /// ```
  String get untrustedCertTitle => """Nicht vertrauenswürdiges Zertifikat""";

  /// ```dart
  /// "${host} verwendet ein Zertifikat, dem dein Gerät nicht vertraut — meist weil es selbst signiert ist. Vergleiche den Fingerabdruck mit dem, den dir dein Server-Admin gegeben hat, bevor du ihm vertraust."
  /// ```
  String untrustedCertBody(String host) =>
      """${host} verwendet ein Zertifikat, dem dein Gerät nicht vertraut — meist weil es selbst signiert ist. Vergleiche den Fingerabdruck mit dem, den dir dein Server-Admin gegeben hat, bevor du ihm vertraust.""";

  /// ```dart
  /// "Vertraue diesem Zertifikat nur, wenn du den Fingerabdruck wiedererkennst. Einem unerwarteten Zertifikat zu vertrauen kann es einem Angreifer ermöglichen, deinen Datenverkehr mitzulesen."
  /// ```
  String get untrustedCertWarning =>
      """Vertraue diesem Zertifikat nur, wenn du den Fingerabdruck wiedererkennst. Einem unerwarteten Zertifikat zu vertrauen kann es einem Angreifer ermöglichen, deinen Datenverkehr mitzulesen.""";

  /// ```dart
  /// "Zertifikat vertrauen"
  /// ```
  String get trustCertificate => """Zertifikat vertrauen""";

  /// ```dart
  /// "SHA-256-Fingerabdruck"
  /// ```
  String get certFingerprint => """SHA-256-Fingerabdruck""";

  /// ```dart
  /// "Inhaber"
  /// ```
  String get certSubject => """Inhaber""";

  /// ```dart
  /// "Aussteller"
  /// ```
  String get certIssuer => """Aussteller""";

  /// ```dart
  /// "Gültig"
  /// ```
  String get certValidity => """Gültig""";

  /// ```dart
  /// "Stattdessen mit App-Passwort anmelden"
  /// ```
  String get useAppPassword => """Stattdessen mit App-Passwort anmelden""";

  /// ```dart
  /// "Stattdessen im Browser anmelden"
  /// ```
  String get useBrowserLogin => """Stattdessen im Browser anmelden""";

  /// ```dart
  /// "Benutzername"
  /// ```
  String get username => """Benutzername""";

  /// ```dart
  /// "App-Passwort"
  /// ```
  String get appPassword => """App-Passwort""";

  /// ```dart
  /// "Erstelle ein App-Passwort in Nextcloud unter Einstellungen → Sicherheit → Geräte & Sitzungen. Nutze dies, wenn die Browser-Anmeldung nicht startet oder dein Server ein selbstsigniertes Zertifikat verwendet."
  /// ```
  String get appPasswordHelp =>
      """Erstelle ein App-Passwort in Nextcloud unter Einstellungen → Sicherheit → Geräte & Sitzungen. Nutze dies, wenn die Browser-Anmeldung nicht startet oder dein Server ein selbstsigniertes Zertifikat verwendet.""";

  /// ```dart
  /// "Bitte gib deinen Benutzernamen und dein App-Passwort ein."
  /// ```
  String get appPasswordMissing =>
      """Bitte gib deinen Benutzernamen und dein App-Passwort ein.""";

  /// ```dart
  /// "Anmelden"
  /// ```
  String get signIn => """Anmelden""";

  /// ```dart
  /// "Server nicht erreichbar. Prüfe die Adresse sowie deine Netzwerk- oder VPN-Verbindung."
  /// ```
  String get couldNotReachServer =>
      """Server nicht erreichbar. Prüfe die Adresse sowie deine Netzwerk- oder VPN-Verbindung.""";

  /// ```dart
  /// "Der Server hat zu lange nicht geantwortet. Prüfe deine Netzwerk- oder VPN-Verbindung und versuche es erneut."
  /// ```
  String get connectionTimeout =>
      """Der Server hat zu lange nicht geantwortet. Prüfe deine Netzwerk- oder VPN-Verbindung und versuche es erneut.""";

  /// ```dart
  /// "Das Zertifikat des Servers konnte nicht zur Überprüfung gelesen werden. Die Verbindung ist möglicherweise instabil oder der Server nicht erreichbar."
  /// ```
  String get certProbeFailed =>
      """Das Zertifikat des Servers konnte nicht zur Überprüfung gelesen werden. Die Verbindung ist möglicherweise instabil oder der Server nicht erreichbar.""";
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
  /// "Schnellaktionen für jeden Eintrag"
  /// ```
  String get quickActionsTitle => """Schnellaktionen für jeden Eintrag""";

  /// ```dart
  /// "Jeder Eintrag zeigt am Ende Aktions-Buttons – klicke darauf, um den Eintrag zu bearbeiten, zu verschieben oder zu löschen, ohne ihn zu öffnen."
  /// ```
  String get quickActionsBody =>
      """Jeder Eintrag zeigt am Ende Aktions-Buttons – klicke darauf, um den Eintrag zu bearbeiten, zu verschieben oder zu löschen, ohne ihn zu öffnen.""";

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
  /// "Du holst sie jederzeit über das Listenmenü → ${toggle} zurück."
  /// ```
  String progressHeroBringBack(String toggle) =>
      """Du holst sie jederzeit über das Listenmenü → ${toggle} zurück.""";

  /// ```dart
  /// "Zum Ausblenden wischen"
  /// ```
  String get progressHeroHint => """Zum Ausblenden wischen""";

  /// ```dart
  /// "Fortschrittskarte ausblenden"
  /// ```
  String get progressHeroDismissTitle => """Fortschrittskarte ausblenden""";

  /// ```dart
  /// "Brauchst du den Fortschrittsring oben nicht? Klicke auf das X auf der Karte, um sie auszublenden."
  /// ```
  String get progressHeroDismissBody =>
      """Brauchst du den Fortschrittsring oben nicht? Klicke auf das X auf der Karte, um sie auszublenden.""";

  /// ```dart
  /// "Listen auf dem Startbildschirm anheften"
  /// ```
  String get pinnedListsTitle => """Listen auf dem Startbildschirm anheften""";

  /// ```dart
  /// "Füge das Pantry-Widget zu deinem Startbildschirm hinzu, um auf einen Blick zu sehen, wie viele Einträge auf deinen Lieblingslisten noch offen sind — ohne die App zu öffnen."
  /// ```
  String get pinnedListsBody =>
      """Füge das Pantry-Widget zu deinem Startbildschirm hinzu, um auf einen Blick zu sehen, wie viele Einträge auf deinen Lieblingslisten noch offen sind — ohne die App zu öffnen.""";

  /// ```dart
  /// "Öffne eine Liste, tippe oben rechts auf ${menu} und wähle ${action}. Angeheftete Listen erscheinen im Widget; löse die Anheftung, um sie auszublenden."
  /// ```
  String pinnedListsHow(String menu, String action) =>
      """Öffne eine Liste, tippe oben rechts auf ${menu} und wähle ${action}. Angeheftete Listen erscheinen im Widget; löse die Anheftung, um sie auszublenden.""";

  /// ```dart
  /// "das Menü"
  /// ```
  String get pinnedListsMenuLabel => """das Menü""";

  /// ```dart
  /// "Liste anheften"
  /// ```
  String get pinnedListsActionLabel => """Liste anheften""";

  /// ```dart
  /// "Pantry"
  /// ```
  String get pinnedListsWidgetTitle => """Pantry""";

  /// ```dart
  /// "${_plural(count, one: '1 offen', many: '${count} offen')}"
  /// ```
  String pinnedListsWidgetItemsLeft(int count) =>
      """${_plural(count, one: '1 offen', many: '${count} offen')}""";

  /// ```dart
  /// "Alles erledigt"
  /// ```
  String get pinnedListsWidgetEmpty => """Alles erledigt""";

  /// ```dart
  /// "Wichtige Notizen oben halten"
  /// ```
  String get pinnedNotesTitle => """Wichtige Notizen oben halten""";

  /// ```dart
  /// "Hefte eine Notiz über das Überlaufmenü an, damit sie oben an deiner Notizwand bleibt — über neueren Notizen sichtbar."
  /// ```
  String get pinnedNotesBody =>
      """Hefte eine Notiz über das Überlaufmenü an, damit sie oben an deiner Notizwand bleibt — über neueren Notizen sichtbar.""";

  /// ```dart
  /// "WLAN-Passwort"
  /// ```
  String get mockPinnedNoteTitle => """WLAN-Passwort""";

  /// ```dart
  /// """
  /// Netzwerk: Zuhause
  /// Passwort: pantry-rocks
  /// """
  /// ```
  String get mockPinnedNoteContent => """Netzwerk: Zuhause
Passwort: pantry-rocks""";

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

  /// ```dart
  /// "Glühbirnen"
  /// ```
  String get mockHardwareItemName => """Glühbirnen""";

  /// ```dart
  /// "Milch"
  /// ```
  String get mockBulkItemThird => """Milch""";

  /// ```dart
  /// "Brot"
  /// ```
  String get mockBulkItemFourth => """Brot""";

  /// ```dart
  /// "Alles in einer Ansicht"
  /// ```
  String get allListsTitle => """Alles in einer Ansicht""";

  /// ```dart
  /// "Öffne die Ansicht Alle Listen über den Listenwechsler, um Einträge aus allen Listen gemeinsam zu sehen. Wenn du dort einen Eintrag hinzufügst, fragt das Formular über den Listen-Chip, in welche Liste er gehören soll."
  /// ```
  String get allListsBody =>
      """Öffne die Ansicht Alle Listen über den Listenwechsler, um Einträge aus allen Listen gemeinsam zu sehen. Wenn du dort einen Eintrag hinzufügst, fragt das Formular über den Listen-Chip, in welche Liste er gehören soll.""";

  /// ```dart
  /// "Viele Einträge auf einmal hinzufügen"
  /// ```
  String get bulkAddTitle => """Viele Einträge auf einmal hinzufügen""";

  /// ```dart
  /// "Aktiviere den Mehrfach-Schalter, und das Eingabefeld wird zu einem mehrzeiligen Feld — jede Zeile wird zu einem eigenen Eintrag. Praktisch, wenn du eine Liste einfügst oder einen ganzen Einkauf auf einmal notierst."
  /// ```
  String get bulkAddBody =>
      """Aktiviere den Mehrfach-Schalter, und das Eingabefeld wird zu einem mehrzeiligen Feld — jede Zeile wird zu einem eigenen Eintrag. Praktisch, wenn du eine Liste einfügst oder einen ganzen Einkauf auf einmal notierst.""";

  /// ```dart
  /// "Mehrere Einträge auf einmal bearbeiten"
  /// ```
  String get bulkSelectTitle => """Mehrere Einträge auf einmal bearbeiten""";

  /// ```dart
  /// "Halte einen Eintrag gedrückt – oder tippe im Menü auf „Auswählen“ – um mehrere zu markieren, und verschiebe, kopiere, kategorisiere oder lösche sie dann alle auf einmal."
  /// ```
  String get bulkSelectBody =>
      """Halte einen Eintrag gedrückt – oder tippe im Menü auf „Auswählen“ – um mehrere zu markieren, und verschiebe, kopiere, kategorisiere oder lösche sie dann alle auf einmal.""";
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
  /// "Neuigkeiten ansehen"
  /// ```
  String get pickLastSeenTitle => """Neuigkeiten ansehen""";

  /// ```dart
  /// "Wähle die Version, deren Neuigkeiten du sehen möchtest – so, wie sie ein Nutzer beim Upgrade auf diese Version sähe."
  /// ```
  String get pickLastSeenBody =>
      """Wähle die Version, deren Neuigkeiten du sehen möchtest – so, wie sie ein Nutzer beim Upgrade auf diese Version sähe.""";

  /// ```dart
  /// "Noch nie gesehen (neuer Benutzer)"
  /// ```
  String get neverSeen => """Noch nie gesehen (neuer Benutzer)""";

  /// ```dart
  /// "Alle Funktionen erzwingen"
  /// ```
  String get forceAllFeatures => """Alle Funktionen erzwingen""";

  /// ```dart
  /// "Testbenachrichtigung senden"
  /// ```
  String get sendTestNotification => """Testbenachrichtigung senden""";
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

  /// ```dart
  /// "Spendier mir einen Kaffee"
  /// ```
  String get buyMeACoffee => """Spendier mir einen Kaffee""";
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
  /// "Standardaktion beim Tippen"
  /// ```
  String get defaultItemTapAction => """Standardaktion beim Tippen""";

  /// ```dart
  /// "Was passiert, wenn du eine Eintragszeile antippst."
  /// ```
  String get defaultItemTapActionBody =>
      """Was passiert, wenn du eine Eintragszeile antippst.""";
  ItemTapActionNamesSettingsMessagesDe get itemTapActionNames =>
      ItemTapActionNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Position des Kontrollkästchens"
  /// ```
  String get checkboxPosition => """Position des Kontrollkästchens""";

  /// ```dart
  /// "Auf welcher Seite der Zeile das Kontrollkästchen erscheint."
  /// ```
  String get checkboxPositionBody =>
      """Auf welcher Seite der Zeile das Kontrollkästchen erscheint.""";
  CheckboxPositionNamesSettingsMessagesDe get checkboxPositionNames =>
      CheckboxPositionNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Listendichte"
  /// ```
  String get density => """Listendichte""";

  /// ```dart
  /// "Wie viel Platz jeder Eintrag in deinen Listen einnimmt."
  /// ```
  String get densityBody =>
      """Wie viel Platz jeder Eintrag in deinen Listen einnimmt.""";
  DensityNamesSettingsMessagesDe get densityNames =>
      DensityNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Vorhandene Einträge beim Hinzufügen wiederverwenden"
  /// ```
  String get reuseExistingItems =>
      """Vorhandene Einträge beim Hinzufügen wiederverwenden""";

  /// ```dart
  /// "Wenn du einen Eintrag hinzufügst, der bereits in der Liste vorhanden ist, wird dieser Eintrag wiederverwendet."
  /// ```
  String get reuseExistingItemsBody =>
      """Wenn du einen Eintrag hinzufügst, der bereits in der Liste vorhanden ist, wird dieser Eintrag wiederverwendet.""";
  ReuseExistingItemsNamesSettingsMessagesDe get reuseExistingItemsNames =>
      ReuseExistingItemsNamesSettingsMessagesDe(this);

  /// ```dart
  /// "Navigationsreihenfolge"
  /// ```
  String get navOrderTitle => """Navigationsreihenfolge""";

  /// ```dart
  /// "Reihenfolge der Navigationsleiste anpassen. Der erste Eintrag wird beim Start geöffnet."
  /// ```
  String get navOrderSubtitle =>
      """Reihenfolge der Navigationsleiste anpassen. Der erste Eintrag wird beim Start geöffnet.""";

  /// ```dart
  /// "Zum Neuanordnen ziehen. Der erste Eintrag wird beim Start der App geöffnet."
  /// ```
  String get navOrderBody =>
      """Zum Neuanordnen ziehen. Der erste Eintrag wird beim Start der App geöffnet.""";

  /// ```dart
  /// "Öffnet sich beim Start"
  /// ```
  String get navOrderDefaultHint => """Öffnet sich beim Start""";

  /// ```dart
  /// "Zurücksetzen"
  /// ```
  String get navOrderReset => """Zurücksetzen""";

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

class ItemTapActionNamesSettingsMessagesDe
    extends ItemTapActionNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const ItemTapActionNamesSettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Als erledigt markieren"
  /// ```
  String get done => """Als erledigt markieren""";

  /// ```dart
  /// "Anzeigen"
  /// ```
  String get view => """Anzeigen""";

  /// ```dart
  /// "Bearbeiten"
  /// ```
  String get edit => """Bearbeiten""";

  /// ```dart
  /// "Keine"
  /// ```
  String get none => """Keine""";
}

class CheckboxPositionNamesSettingsMessagesDe
    extends CheckboxPositionNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const CheckboxPositionNamesSettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Anfang"
  /// ```
  String get start => """Anfang""";

  /// ```dart
  /// "Ende"
  /// ```
  String get end => """Ende""";
}

class DensityNamesSettingsMessagesDe extends DensityNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const DensityNamesSettingsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Normal"
  /// ```
  String get normal => """Normal""";

  /// ```dart
  /// "Kompakt"
  /// ```
  String get dense => """Kompakt""";
}

class ReuseExistingItemsNamesSettingsMessagesDe
    extends ReuseExistingItemsNamesSettingsMessages {
  final SettingsMessagesDe _parent;
  const ReuseExistingItemsNamesSettingsMessagesDe(this._parent)
    : super(_parent);

  /// ```dart
  /// "Immer fragen"
  /// ```
  String get ask => """Immer fragen""";

  /// ```dart
  /// "Immer wiederverwenden"
  /// ```
  String get reuse => """Immer wiederverwenden""";

  /// ```dart
  /// "Nie wiederverwenden"
  /// ```
  String get never => """Nie wiederverwenden""";
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
  /// "Alle"
  /// ```
  String get allListsChip => """Alle""";

  /// ```dart
  /// "Nach Liste filtern"
  /// ```
  String get filterByList => """Nach Liste filtern""";

  /// ```dart
  /// "Nach Kategorie filtern"
  /// ```
  String get filterByCategory => """Nach Kategorie filtern""";

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
  /// "In Liste kopieren"
  /// ```
  String get copyItem => """In Liste kopieren""";

  /// ```dart
  /// "Eintrag konnte nicht kopiert werden."
  /// ```
  String get copyFailed => """Eintrag konnte nicht kopiert werden.""";

  /// ```dart
  /// "Eintrag kopiert"
  /// ```
  String get itemCopied => """Eintrag kopiert""";

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
  /// "Auswählen"
  /// ```
  String get selectItems => """Auswählen""";
  BatchChecklistsMessagesDe get batch => BatchChecklistsMessagesDe(this);

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
  /// "Fortschrittskarte in dieser Liste anzeigen"
  /// ```
  String get showProgressHero =>
      """Fortschrittskarte in dieser Liste anzeigen""";

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
  /// "Löschen"
  /// ```
  String get permanentlyDeleteItem => """Löschen""";

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
  /// "Archiv anzeigen"
  /// ```
  String get viewArchive => """Archiv anzeigen""";

  /// ```dart
  /// "Archiv verlassen"
  /// ```
  String get exitArchive => """Archiv verlassen""";

  /// ```dart
  /// "Archiv"
  /// ```
  String get archiveTitle => """Archiv""";

  /// ```dart
  /// "Keine Kategorie"
  /// ```
  String get noCategory => """Keine Kategorie""";

  /// ```dart
  /// "Das Archiv ist leer."
  /// ```
  String get noArchivedItems => """Das Archiv ist leer.""";

  /// ```dart
  /// "Archivieren"
  /// ```
  String get archiveItem => """Archivieren""";

  /// ```dart
  /// "Dearchivieren"
  /// ```
  String get unarchiveItem => """Dearchivieren""";

  /// ```dart
  /// "Eintrag konnte nicht archiviert werden."
  /// ```
  String get archiveFailed => """Eintrag konnte nicht archiviert werden.""";

  /// ```dart
  /// "Eintrag konnte nicht dearchiviert werden."
  /// ```
  String get unarchiveFailed => """Eintrag konnte nicht dearchiviert werden.""";

  /// ```dart
  /// "Eintrag archiviert"
  /// ```
  String get itemArchived => """Eintrag archiviert""";

  /// ```dart
  /// "Eintrag dearchiviert"
  /// ```
  String get itemUnarchived => """Eintrag dearchiviert""";

  /// ```dart
  /// "Archiv konnte nicht geladen werden."
  /// ```
  String get failedToLoadArchive => """Archiv konnte nicht geladen werden.""";

  /// ```dart
  /// "Gelöschte Listen"
  /// ```
  String get viewListsTrash => """Gelöschte Listen""";

  /// ```dart
  /// "Gelöschte Listen"
  /// ```
  String get listsTrashTitle => """Gelöschte Listen""";

  /// ```dart
  /// "Papierkorb konnte nicht geladen werden."
  /// ```
  String get failedToLoadTrash => """Papierkorb konnte nicht geladen werden.""";

  /// ```dart
  /// "Keine gelöschten Listen."
  /// ```
  String get listTrashEmpty => """Keine gelöschten Listen.""";

  /// ```dart
  /// "Liste anheften"
  /// ```
  String get pinList => """Liste anheften""";

  /// ```dart
  /// "Liste lösen"
  /// ```
  String get unpinList => """Liste lösen""";

  /// ```dart
  /// "Liste entfernen"
  /// ```
  String get removeList => """Liste entfernen""";

  /// ```dart
  /// "Liste bearbeiten"
  /// ```
  String get editList => """Liste bearbeiten""";

  /// ```dart
  /// "Liste bearbeiten"
  /// ```
  String get editListTitle => """Liste bearbeiten""";

  /// ```dart
  /// "Änderungen speichern"
  /// ```
  String get saveListButton => """Änderungen speichern""";

  /// ```dart
  /// "Liste konnte nicht aktualisiert werden."
  /// ```
  String get updateListFailed => """Liste konnte nicht aktualisiert werden.""";

  /// ```dart
  /// "Liste entfernen?"
  /// ```
  String get removeListConfirm => """Liste entfernen?""";

  /// ```dart
  /// "Liste "$name" entfernen? Du kannst sie aus dem Papierkorb wiederherstellen."
  /// ```
  String removeListConfirmBody(String name) =>
      """Liste "$name" entfernen? Du kannst sie aus dem Papierkorb wiederherstellen.""";

  /// ```dart
  /// "Liste konnte nicht entfernt werden."
  /// ```
  String get removeListFailed => """Liste konnte nicht entfernt werden.""";

  /// ```dart
  /// "Liste wiederherstellen"
  /// ```
  String get restoreList => """Liste wiederherstellen""";

  /// ```dart
  /// "Endgültig löschen"
  /// ```
  String get permanentlyDeleteList => """Endgültig löschen""";

  /// ```dart
  /// "Liste entfernt"
  /// ```
  String get listRemoved => """Liste entfernt""";

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
  /// "Fortschrittskarte ausblenden"
  /// ```
  String get hideProgressHero => """Fortschrittskarte ausblenden""";

  /// ```dart
  /// "Sortieren"
  /// ```
  String get sortTooltip => """Sortieren""";

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
  /// "Kopieren"
  /// ```
  String get swipeCopy => """Kopieren""";

  /// ```dart
  /// "Entfernen"
  /// ```
  String get swipeDelete => """Entfernen""";

  /// ```dart
  /// "Archivieren"
  /// ```
  String get swipeArchive => """Archivieren""";

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
  ReuseChecklistsMessagesDe get reuse => ReuseChecklistsMessagesDe(this);

  /// ```dart
  /// "Alle Listen"
  /// ```
  String get allLists => """Alle Listen""";

  /// ```dart
  /// "Einträge aus allen Listen"
  /// ```
  String get allListsSubtitle => """Einträge aus allen Listen""";

  /// ```dart
  /// "Eintrag hinzufügen…"
  /// ```
  String get addToAnyList => """Eintrag hinzufügen…""";

  /// ```dart
  /// "Zu welcher Liste hinzufügen?"
  /// ```
  String get pickListTitle => """Zu welcher Liste hinzufügen?""";
  MarkdownChecklistsMessagesDe get markdown =>
      MarkdownChecklistsMessagesDe(this);
}

class BatchChecklistsMessagesDe extends BatchChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const BatchChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "${_plural(count, one: '1 ausgewählt', many: '$count ausgewählt')}"
  /// ```
  String selected(int count) =>
      """${_plural(count, one: '1 ausgewählt', many: '$count ausgewählt')}""";

  /// ```dart
  /// "Einträge verschieben nach"
  /// ```
  String get moveTitle => """Einträge verschieben nach""";

  /// ```dart
  /// "Einträge kopieren nach"
  /// ```
  String get copyTitle => """Einträge kopieren nach""";

  /// ```dart
  /// "Kategorie festlegen"
  /// ```
  String get categoryTitle => """Kategorie festlegen""";

  /// ```dart
  /// "Keine Kategorie"
  /// ```
  String get clearCategory => """Keine Kategorie""";

  /// ```dart
  /// "Verschieben"
  /// ```
  String get move => """Verschieben""";

  /// ```dart
  /// "Kopieren"
  /// ```
  String get copy => """Kopieren""";

  /// ```dart
  /// "Kategorie"
  /// ```
  String get category => """Kategorie""";

  /// ```dart
  /// "Löschen"
  /// ```
  String get delete => """Löschen""";

  /// ```dart
  /// "Archivieren"
  /// ```
  String get archive => """Archivieren""";

  /// ```dart
  /// "Dearchivieren"
  /// ```
  String get unarchive => """Dearchivieren""";

  /// ```dart
  /// "Einträge löschen?"
  /// ```
  String get deleteConfirmTitle => """Einträge löschen?""";

  /// ```dart
  /// "${_plural(count, one: '1 ausgewählten Eintrag löschen? Du kannst ihn aus dem Papierkorb wiederherstellen.', many: '$count ausgewählte Einträge löschen? Du kannst sie aus dem Papierkorb wiederherstellen.')}"
  /// ```
  String deleteConfirmBody(int count) =>
      """${_plural(count, one: '1 ausgewählten Eintrag löschen? Du kannst ihn aus dem Papierkorb wiederherstellen.', many: '$count ausgewählte Einträge löschen? Du kannst sie aus dem Papierkorb wiederherstellen.')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag verschoben', many: '$count Einträge verschoben')}"
  /// ```
  String moved(int count) =>
      """${_plural(count, one: '1 Eintrag verschoben', many: '$count Einträge verschoben')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag kopiert', many: '$count Einträge kopiert')}"
  /// ```
  String copied(int count) =>
      """${_plural(count, one: '1 Eintrag kopiert', many: '$count Einträge kopiert')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag gelöscht', many: '$count Einträge gelöscht')}"
  /// ```
  String deleted(int count) =>
      """${_plural(count, one: '1 Eintrag gelöscht', many: '$count Einträge gelöscht')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag wiederhergestellt', many: '$count Einträge wiederhergestellt')}"
  /// ```
  String restored(int count) =>
      """${_plural(count, one: '1 Eintrag wiederhergestellt', many: '$count Einträge wiederhergestellt')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag archiviert', many: '$count Einträge archiviert')}"
  /// ```
  String archived(int count) =>
      """${_plural(count, one: '1 Eintrag archiviert', many: '$count Einträge archiviert')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag dearchiviert', many: '$count Einträge dearchiviert')}"
  /// ```
  String unarchived(int count) =>
      """${_plural(count, one: '1 Eintrag dearchiviert', many: '$count Einträge dearchiviert')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag aktualisiert', many: '$count Einträge aktualisiert')}"
  /// ```
  String categorySet(int count) =>
      """${_plural(count, one: '1 Eintrag aktualisiert', many: '$count Einträge aktualisiert')}""";

  /// ```dart
  /// "${_plural(count, one: '1 übersprungen', many: '$count übersprungen')}"
  /// ```
  String skipped(int count) =>
      """${_plural(count, one: '1 übersprungen', many: '$count übersprungen')}""";

  /// ```dart
  /// "Etwas ist schiefgelaufen. Bitte versuche es erneut."
  /// ```
  String get failed =>
      """Etwas ist schiefgelaufen. Bitte versuche es erneut.""";
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

  /// ```dart
  /// "Menge"
  /// ```
  String get quantityLabel => """Menge""";

  /// ```dart
  /// "Typ"
  /// ```
  String get typeLabel => """Typ""";

  /// ```dart
  /// "Beschreibung"
  /// ```
  String get descriptionLabel => """Beschreibung""";

  /// ```dart
  /// "Keine Beschreibung hinzugefügt."
  /// ```
  String get noDescription => """Keine Beschreibung hinzugefügt.""";

  /// ```dart
  /// "Hinzugefügt von $name · $time"
  /// ```
  String addedByMeta(String name, String time) =>
      """Hinzugefügt von $name · $time""";

  /// ```dart
  /// "Hinzugefügt von dir · $time"
  /// ```
  String addedByYouMeta(String time) => """Hinzugefügt von dir · $time""";

  /// ```dart
  /// "Hinzugefügt $time"
  /// ```
  String addedMeta(String time) => """Hinzugefügt $time""";

  /// ```dart
  /// "gerade eben"
  /// ```
  String get relJustNow => """gerade eben""";

  /// ```dart
  /// "heute"
  /// ```
  String get relToday => """heute""";

  /// ```dart
  /// "gestern"
  /// ```
  String get relYesterday => """gestern""";

  /// ```dart
  /// "vor $n Tagen"
  /// ```
  String relDaysAgo(int n) => """vor $n Tagen""";

  /// ```dart
  /// "${_plural(n, one: 'vor 1 Woche', many: 'vor $n Wochen')}"
  /// ```
  String relWeeksAgo(int n) =>
      """${_plural(n, one: 'vor 1 Woche', many: 'vor $n Wochen')}""";

  /// ```dart
  /// "${_plural(n, one: 'vor 1 Monat', many: 'vor $n Monaten')}"
  /// ```
  String relMonthsAgo(int n) =>
      """${_plural(n, one: 'vor 1 Monat', many: 'vor $n Monaten')}""";

  /// ```dart
  /// "${_plural(n, one: 'vor 1 Jahr', many: 'vor $n Jahren')}"
  /// ```
  String relYearsAgo(int n) =>
      """${_plural(n, one: 'vor 1 Jahr', many: 'vor $n Jahren')}""";
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
  /// "Foto aufnehmen"
  /// ```
  String get takePhoto => """Foto aufnehmen""";

  /// ```dart
  /// "Bild auswählen"
  /// ```
  String get chooseImage => """Bild auswählen""";

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

  /// ```dart
  /// "Liste"
  /// ```
  String get chipTargetList => """Liste""";

  /// ```dart
  /// "Liste wählen"
  /// ```
  String get pickTargetList => """Liste wählen""";

  /// ```dart
  /// "Mehrere"
  /// ```
  String get multiple => """Mehrere""";

  /// ```dart
  /// "Einträge durch Zeilenumbrüche trennen"
  /// ```
  String get multipleHint => """Einträge durch Zeilenumbrüche trennen""";
}

class ReuseChecklistsMessagesDe extends ReuseChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const ReuseChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Eintrag existiert bereits"
  /// ```
  String get dialogTitle => """Eintrag existiert bereits""";

  /// ```dart
  /// "Ein Eintrag namens "$name" existiert bereits in dieser Liste. Wiederverwenden, statt einen neuen hinzuzufügen?"
  /// ```
  String dialogBody(String name) =>
      """Ein Eintrag namens "$name" existiert bereits in dieser Liste. Wiederverwenden, statt einen neuen hinzuzufügen?""";

  /// ```dart
  /// "Vorhandenen wiederverwenden"
  /// ```
  String get reuseExisting => """Vorhandenen wiederverwenden""";

  /// ```dart
  /// "Trotzdem hinzufügen"
  /// ```
  String get addAnyway => """Trotzdem hinzufügen""";

  /// ```dart
  /// "Vorhandener Eintrag "$name" wiederverwendet"
  /// ```
  String reusedSnack(String name) =>
      """Vorhandener Eintrag "$name" wiederverwendet""";
}

class MarkdownChecklistsMessagesDe extends MarkdownChecklistsMessages {
  final ChecklistsMessagesDe _parent;
  const MarkdownChecklistsMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Exportiert am $date"
  /// ```
  String exported(String date) => """Exportiert am $date""";

  /// ```dart
  /// "Ohne Kategorie"
  /// ```
  String get uncategorized => """Ohne Kategorie""";

  /// ```dart
  /// "Als Markdown exportieren"
  /// ```
  String get exportTitle => """Als Markdown exportieren""";

  /// ```dart
  /// "Aus Markdown importieren"
  /// ```
  String get importTitle => """Aus Markdown importieren""";

  /// ```dart
  /// "Erledigte Einträge einschließen"
  /// ```
  String get includeCompleted => """Erledigte Einträge einschließen""";

  /// ```dart
  /// "Bearbeite den Text unten, um die exportierte Liste anzupassen"
  /// ```
  String get editHint =>
      """Bearbeite den Text unten, um die exportierte Liste anzupassen""";

  /// ```dart
  /// "Kopieren"
  /// ```
  String get copy => """Kopieren""";

  /// ```dart
  /// ".md herunterladen"
  /// ```
  String get download => """.md herunterladen""";

  /// ```dart
  /// "In die Zwischenablage kopiert"
  /// ```
  String get copied => """In die Zwischenablage kopiert""";

  /// ```dart
  /// "Konnte nicht in die Zwischenablage kopieren"
  /// ```
  String get copyFailed => """Konnte nicht in die Zwischenablage kopieren""";

  /// ```dart
  /// "Schließen"
  /// ```
  String get close => """Schließen""";

  /// ```dart
  /// "Datei konnte nicht exportiert werden"
  /// ```
  String get shareFailed => """Datei konnte nicht exportiert werden""";

  /// ```dart
  /// ".md-Datei hochladen"
  /// ```
  String get uploadFile => """.md-Datei hochladen""";

  /// ```dart
  /// "Markdown einfügen"
  /// ```
  String get pasteLabel => """Markdown einfügen""";

  /// ```dart
  /// "Füge hier eine Markdown-Liste ein…"
  /// ```
  String get pastePlaceholder => """Füge hier eine Markdown-Liste ein…""";

  /// ```dart
  /// "Keine Listeneinträge im Text gefunden."
  /// ```
  String get noneFound => """Keine Listeneinträge im Text gefunden.""";

  /// ```dart
  /// "Alle auswählen"
  /// ```
  String get selectAll => """Alle auswählen""";

  /// ```dart
  /// "Alle abwählen"
  /// ```
  String get deselectAll => """Alle abwählen""";

  /// ```dart
  /// "Vorhandene Einträge wiederverwenden statt Duplikate hinzuzufügen"
  /// ```
  String get reuseExisting =>
      """Vorhandene Einträge wiederverwenden statt Duplikate hinzuzufügen""";

  /// ```dart
  /// "Standardwerte für jeden importierten Eintrag"
  /// ```
  String get defaultFields =>
      """Standardwerte für jeden importierten Eintrag""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag gefunden', many: '$count Einträge gefunden')}"
  /// ```
  String itemsFound(int count) =>
      """${_plural(count, one: '1 Eintrag gefunden', many: '$count Einträge gefunden')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag hinzufügen', many: '$count Einträge hinzufügen')}"
  /// ```
  String addItems(int count) =>
      """${_plural(count, one: '1 Eintrag hinzufügen', many: '$count Einträge hinzufügen')}""";

  /// ```dart
  /// "${_plural(count, one: '1 Eintrag importiert', many: '$count Einträge importiert')}"
  /// ```
  String imported(int count) =>
      """${_plural(count, one: '1 Eintrag importiert', many: '$count Einträge importiert')}""";
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
  /// "Papierkorb anzeigen"
  /// ```
  String get viewTrash => """Papierkorb anzeigen""";

  /// ```dart
  /// "Papierkorb verlassen"
  /// ```
  String get exitTrash => """Papierkorb verlassen""";

  /// ```dart
  /// "Papierkorb"
  /// ```
  String get trashTitle => """Papierkorb""";

  /// ```dart
  /// "Der Papierkorb ist leer."
  /// ```
  String get trashEmpty => """Der Papierkorb ist leer.""";

  /// ```dart
  /// "Papierkorb leeren"
  /// ```
  String get emptyTrash => """Papierkorb leeren""";

  /// ```dart
  /// "Papierkorb leeren?"
  /// ```
  String get emptyTrashConfirm => """Papierkorb leeren?""";

  /// ```dart
  /// "Alle Notizen im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get emptyTrashConfirmBody =>
      """Alle Notizen im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""";

  /// ```dart
  /// "Papierkorb konnte nicht geleert werden."
  /// ```
  String get emptyTrashFailed => """Papierkorb konnte nicht geleert werden.""";

  /// ```dart
  /// "Papierkorb konnte nicht geladen werden."
  /// ```
  String get failedToLoadTrash => """Papierkorb konnte nicht geladen werden.""";

  /// ```dart
  /// "Wiederherstellen"
  /// ```
  String get restore => """Wiederherstellen""";

  /// ```dart
  /// "Notiz konnte nicht wiederhergestellt werden."
  /// ```
  String get restoreFailed =>
      """Notiz konnte nicht wiederhergestellt werden.""";

  /// ```dart
  /// "Endgültig löschen"
  /// ```
  String get permanentlyDelete => """Endgültig löschen""";

  /// ```dart
  /// "Diese Notiz endgültig löschen?"
  /// ```
  String get permanentlyDeleteConfirm => """Diese Notiz endgültig löschen?""";

  /// ```dart
  /// "Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Dies kann nicht rückgängig gemacht werden.""";

  /// ```dart
  /// "Neue Notiz"
  /// ```
  String get newNote => """Neue Notiz""";

  /// ```dart
  /// "Notiz bearbeiten"
  /// ```
  String get editNote => """Notiz bearbeiten""";

  /// ```dart
  /// "Nicht gespeicherte Änderungen"
  /// ```
  String get unsavedChanges => """Nicht gespeicherte Änderungen""";

  /// ```dart
  /// "Du hast nicht gespeicherte Änderungen. Möchtest du sie speichern?"
  /// ```
  String get unsavedChangesBody =>
      """Du hast nicht gespeicherte Änderungen. Möchtest du sie speichern?""";

  /// ```dart
  /// "Verwerfen"
  /// ```
  String get discard => """Verwerfen""";

  /// ```dart
  /// "Weiter bearbeiten"
  /// ```
  String get keepEditing => """Weiter bearbeiten""";

  /// ```dart
  /// "Notiz anheften"
  /// ```
  String get pinNote => """Notiz anheften""";

  /// ```dart
  /// "Notiz lösen"
  /// ```
  String get unpinNote => """Notiz lösen""";

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
  /// "Papierkorb anzeigen"
  /// ```
  String get viewTrash => """Papierkorb anzeigen""";

  /// ```dart
  /// "Papierkorb verlassen"
  /// ```
  String get exitTrash => """Papierkorb verlassen""";

  /// ```dart
  /// "Papierkorb"
  /// ```
  String get trashTitle => """Papierkorb""";

  /// ```dart
  /// "Der Papierkorb ist leer."
  /// ```
  String get trashEmpty => """Der Papierkorb ist leer.""";

  /// ```dart
  /// "Papierkorb leeren"
  /// ```
  String get emptyTrash => """Papierkorb leeren""";

  /// ```dart
  /// "Papierkorb leeren?"
  /// ```
  String get emptyTrashConfirm => """Papierkorb leeren?""";

  /// ```dart
  /// "Alle Fotos im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get emptyTrashConfirmBody =>
      """Alle Fotos im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""";

  /// ```dart
  /// "Papierkorb konnte nicht geleert werden."
  /// ```
  String get emptyTrashFailed => """Papierkorb konnte nicht geleert werden.""";

  /// ```dart
  /// "Papierkorb konnte nicht geladen werden."
  /// ```
  String get failedToLoadTrash => """Papierkorb konnte nicht geladen werden.""";

  /// ```dart
  /// "Wiederherstellen"
  /// ```
  String get restore => """Wiederherstellen""";

  /// ```dart
  /// "Foto konnte nicht wiederhergestellt werden."
  /// ```
  String get restoreFailed => """Foto konnte nicht wiederhergestellt werden.""";

  /// ```dart
  /// "Endgültig löschen"
  /// ```
  String get permanentlyDelete => """Endgültig löschen""";

  /// ```dart
  /// "Dieses Foto endgültig löschen?"
  /// ```
  String get permanentlyDeleteConfirm => """Dieses Foto endgültig löschen?""";

  /// ```dart
  /// "Dies kann nicht rückgängig gemacht werden."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Dies kann nicht rückgängig gemacht werden.""";

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

class SyncMessagesDe extends SyncMessages {
  final MessagesDe _parent;
  const SyncMessagesDe(this._parent) : super(_parent);

  /// ```dart
  /// "Offline"
  /// ```
  String get offline => """Offline""";

  /// ```dart
  /// "Änderungen werden synchronisiert…"
  /// ```
  String get syncing => """Änderungen werden synchronisiert…""";

  /// ```dart
  /// "${_plural(count, one: '1 Änderung wartet auf Synchronisierung', many: '${count} Änderungen warten auf Synchronisierung')}"
  /// ```
  String pendingChanges(int count) =>
      """${_plural(count, one: '1 Änderung wartet auf Synchronisierung', many: '${count} Änderungen warten auf Synchronisierung')}""";

  /// ```dart
  /// "Synchronisierung fehlgeschlagen"
  /// ```
  String get syncError => """Synchronisierung fehlgeschlagen""";

  /// ```dart
  /// "Erneut versuchen"
  /// ```
  String get retry => """Erneut versuchen""";
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
  """common.copy""": """Kopieren""",
  """common.copied""": """Kopiert""",
  """common.closeDialog""": """Fertig""",
  """common.remove""": """Entfernen""",
  """common.permissionDenied""": """Dazu hast du keine Berechtigung""",
  """common.noAccessTitle""": """Kein Zugriff""",
  """common.noAccessBody""":
      """Du hast noch keinen Zugriff auf Inhalte in diesem Haushalt. Eine Administratorin oder ein Administrator kann dir in der Pantry-Web-App Berechtigungen erteilen.""",
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
  """login.seeDetails""": """Details anzeigen""",
  """login.errorDetailsTitle""": """Fehlerdetails""",
  """login.untrustedCertTitle""": """Nicht vertrauenswürdiges Zertifikat""",
  """login.untrustedCertWarning""":
      """Vertraue diesem Zertifikat nur, wenn du den Fingerabdruck wiedererkennst. Einem unerwarteten Zertifikat zu vertrauen kann es einem Angreifer ermöglichen, deinen Datenverkehr mitzulesen.""",
  """login.trustCertificate""": """Zertifikat vertrauen""",
  """login.certFingerprint""": """SHA-256-Fingerabdruck""",
  """login.certSubject""": """Inhaber""",
  """login.certIssuer""": """Aussteller""",
  """login.certValidity""": """Gültig""",
  """login.useAppPassword""": """Stattdessen mit App-Passwort anmelden""",
  """login.useBrowserLogin""": """Stattdessen im Browser anmelden""",
  """login.username""": """Benutzername""",
  """login.appPassword""": """App-Passwort""",
  """login.appPasswordHelp""":
      """Erstelle ein App-Passwort in Nextcloud unter Einstellungen → Sicherheit → Geräte & Sitzungen. Nutze dies, wenn die Browser-Anmeldung nicht startet oder dein Server ein selbstsigniertes Zertifikat verwendet.""",
  """login.appPasswordMissing""":
      """Bitte gib deinen Benutzernamen und dein App-Passwort ein.""",
  """login.signIn""": """Anmelden""",
  """login.couldNotReachServer""":
      """Server nicht erreichbar. Prüfe die Adresse sowie deine Netzwerk- oder VPN-Verbindung.""",
  """login.connectionTimeout""":
      """Der Server hat zu lange nicht geantwortet. Prüfe deine Netzwerk- oder VPN-Verbindung und versuche es erneut.""",
  """login.certProbeFailed""":
      """Das Zertifikat des Servers konnte nicht zur Überprüfung gelesen werden. Die Verbindung ist möglicherweise instabil oder der Server nicht erreichbar.""",
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
  """onboarding.quickActionsTitle""": """Schnellaktionen für jeden Eintrag""",
  """onboarding.quickActionsBody""":
      """Jeder Eintrag zeigt am Ende Aktions-Buttons – klicke darauf, um den Eintrag zu bearbeiten, zu verschieben oder zu löschen, ohne ihn zu öffnen.""",
  """onboarding.addItemsTitle""": """Einträge schneller hinzufügen""",
  """onboarding.addItemsBody""":
      """Tippe auf das Feld unten, um einen neuen Eintrag einzugeben, und versieh ihn dann über die Chips darüber mit Kategorie, Menge, Typ oder Foto.""",
  """onboarding.mockComposeListName""": """Lebensmittel""",
  """onboarding.progressHeroTitle""": """Fortschrittskarte ausblenden""",
  """onboarding.progressHeroBody""":
      """Brauchst du den Fortschrittsring oben nicht? Wisch ihn einfach weg.""",
  """onboarding.progressHeroHint""": """Zum Ausblenden wischen""",
  """onboarding.progressHeroDismissTitle""": """Fortschrittskarte ausblenden""",
  """onboarding.progressHeroDismissBody""":
      """Brauchst du den Fortschrittsring oben nicht? Klicke auf das X auf der Karte, um sie auszublenden.""",
  """onboarding.pinnedListsTitle""":
      """Listen auf dem Startbildschirm anheften""",
  """onboarding.pinnedListsBody""":
      """Füge das Pantry-Widget zu deinem Startbildschirm hinzu, um auf einen Blick zu sehen, wie viele Einträge auf deinen Lieblingslisten noch offen sind — ohne die App zu öffnen.""",
  """onboarding.pinnedListsMenuLabel""": """das Menü""",
  """onboarding.pinnedListsActionLabel""": """Liste anheften""",
  """onboarding.pinnedListsWidgetTitle""": """Pantry""",
  """onboarding.pinnedListsWidgetEmpty""": """Alles erledigt""",
  """onboarding.pinnedNotesTitle""": """Wichtige Notizen oben halten""",
  """onboarding.pinnedNotesBody""":
      """Hefte eine Notiz über das Überlaufmenü an, damit sie oben an deiner Notizwand bleibt — über neueren Notizen sichtbar.""",
  """onboarding.mockPinnedNoteTitle""": """WLAN-Passwort""",
  """onboarding.mockPinnedNoteContent""": """Netzwerk: Zuhause
Passwort: pantry-rocks""",
  """onboarding.mockItemName""": """Tomaten""",
  """onboarding.mockItemQuantity""": """x2""",
  """onboarding.mockItemCategory""": """Gemüse""",
  """onboarding.mockHardwareItemName""": """Glühbirnen""",
  """onboarding.mockBulkItemThird""": """Milch""",
  """onboarding.mockBulkItemFourth""": """Brot""",
  """onboarding.allListsTitle""": """Alles in einer Ansicht""",
  """onboarding.allListsBody""":
      """Öffne die Ansicht Alle Listen über den Listenwechsler, um Einträge aus allen Listen gemeinsam zu sehen. Wenn du dort einen Eintrag hinzufügst, fragt das Formular über den Listen-Chip, in welche Liste er gehören soll.""",
  """onboarding.bulkAddTitle""": """Viele Einträge auf einmal hinzufügen""",
  """onboarding.bulkAddBody""":
      """Aktiviere den Mehrfach-Schalter, und das Eingabefeld wird zu einem mehrzeiligen Feld — jede Zeile wird zu einem eigenen Eintrag. Praktisch, wenn du eine Liste einfügst oder einen ganzen Einkauf auf einmal notierst.""",
  """onboarding.bulkSelectTitle""":
      """Mehrere Einträge auf einmal bearbeiten""",
  """onboarding.bulkSelectBody""":
      """Halte einen Eintrag gedrückt – oder tippe im Menü auf „Auswählen“ – um mehrere zu markieren, und verschiebe, kopiere, kategorisiere oder lösche sie dann alle auf einmal.""",
  """onboarding.dev.showOnboarding""": """Onboarding anzeigen""",
  """onboarding.dev.pickLastSeenTitle""": """Neuigkeiten ansehen""",
  """onboarding.dev.pickLastSeenBody""":
      """Wähle die Version, deren Neuigkeiten du sehen möchtest – so, wie sie ein Nutzer beim Upgrade auf diese Version sähe.""",
  """onboarding.dev.neverSeen""": """Noch nie gesehen (neuer Benutzer)""",
  """onboarding.dev.forceAllFeatures""": """Alle Funktionen erzwingen""",
  """onboarding.dev.sendTestNotification""": """Testbenachrichtigung senden""",
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
  """about.buyMeACoffee""": """Spendier mir einen Kaffee""",
  """settings.title""": """App-Einstellungen""",
  """settings.generalSection""": """Allgemein""",
  """settings.interfaceSection""": """Oberfläche""",
  """settings.defaultItemTapAction""": """Standardaktion beim Tippen""",
  """settings.defaultItemTapActionBody""":
      """Was passiert, wenn du eine Eintragszeile antippst.""",
  """settings.itemTapActionNames.done""": """Als erledigt markieren""",
  """settings.itemTapActionNames.view""": """Anzeigen""",
  """settings.itemTapActionNames.edit""": """Bearbeiten""",
  """settings.itemTapActionNames.none""": """Keine""",
  """settings.checkboxPosition""": """Position des Kontrollkästchens""",
  """settings.checkboxPositionBody""":
      """Auf welcher Seite der Zeile das Kontrollkästchen erscheint.""",
  """settings.checkboxPositionNames.start""": """Anfang""",
  """settings.checkboxPositionNames.end""": """Ende""",
  """settings.density""": """Listendichte""",
  """settings.densityBody""":
      """Wie viel Platz jeder Eintrag in deinen Listen einnimmt.""",
  """settings.densityNames.normal""": """Normal""",
  """settings.densityNames.dense""": """Kompakt""",
  """settings.reuseExistingItems""":
      """Vorhandene Einträge beim Hinzufügen wiederverwenden""",
  """settings.reuseExistingItemsBody""":
      """Wenn du einen Eintrag hinzufügst, der bereits in der Liste vorhanden ist, wird dieser Eintrag wiederverwendet.""",
  """settings.reuseExistingItemsNames.ask""": """Immer fragen""",
  """settings.reuseExistingItemsNames.reuse""": """Immer wiederverwenden""",
  """settings.reuseExistingItemsNames.never""": """Nie wiederverwenden""",
  """settings.navOrderTitle""": """Navigationsreihenfolge""",
  """settings.navOrderSubtitle""":
      """Reihenfolge der Navigationsleiste anpassen. Der erste Eintrag wird beim Start geöffnet.""",
  """settings.navOrderBody""":
      """Zum Neuanordnen ziehen. Der erste Eintrag wird beim Start der App geöffnet.""",
  """settings.navOrderDefaultHint""": """Öffnet sich beim Start""",
  """settings.navOrderReset""": """Zurücksetzen""",
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
  """checklists.allListsChip""": """Alle""",
  """checklists.filterByList""": """Nach Liste filtern""",
  """checklists.filterByCategory""": """Nach Kategorie filtern""",
  """checklists.failedToLoad""":
      """Checklisten konnten nicht geladen werden.""",
  """checklists.failedToLoadItems""":
      """Einträge konnten nicht geladen werden.""",
  """checklists.editItem""": """Eintrag bearbeiten""",
  """checklists.removeItem""": """Eintrag entfernen""",
  """checklists.moveItem""": """In Liste verschieben""",
  """checklists.moveFailed""": """Eintrag konnte nicht verschoben werden.""",
  """checklists.copyItem""": """In Liste kopieren""",
  """checklists.copyFailed""": """Eintrag konnte nicht kopiert werden.""",
  """checklists.itemCopied""": """Eintrag kopiert""",
  """checklists.itemMarkedDone""": """Eintrag als erledigt markiert""",
  """checklists.itemRemoved""": """Eintrag entfernt""",
  """checklists.undo""": """Rückgängig""",
  """checklists.selectItems""": """Auswählen""",
  """checklists.batch.moveTitle""": """Einträge verschieben nach""",
  """checklists.batch.copyTitle""": """Einträge kopieren nach""",
  """checklists.batch.categoryTitle""": """Kategorie festlegen""",
  """checklists.batch.clearCategory""": """Keine Kategorie""",
  """checklists.batch.move""": """Verschieben""",
  """checklists.batch.copy""": """Kopieren""",
  """checklists.batch.category""": """Kategorie""",
  """checklists.batch.delete""": """Löschen""",
  """checklists.batch.archive""": """Archivieren""",
  """checklists.batch.unarchive""": """Dearchivieren""",
  """checklists.batch.deleteConfirmTitle""": """Einträge löschen?""",
  """checklists.batch.failed""":
      """Etwas ist schiefgelaufen. Bitte versuche es erneut.""",
  """checklists.viewTrash""": """Papierkorb anzeigen""",
  """checklists.exitTrash""": """Papierkorb verlassen""",
  """checklists.showAddedBy""": """Anzeigen, wer Einträge hinzugefügt hat""",
  """checklists.showProgressHero""":
      """Fortschrittskarte in dieser Liste anzeigen""",
  """checklists.trashTitle""": """Papierkorb""",
  """checklists.noTrashedItems""": """Der Papierkorb ist leer.""",
  """checklists.emptyTrash""": """Papierkorb leeren""",
  """checklists.emptyTrashConfirm""": """Papierkorb leeren?""",
  """checklists.emptyTrashConfirmBody""":
      """Alle Einträge im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""",
  """checklists.emptyTrashFailed""":
      """Papierkorb konnte nicht geleert werden.""",
  """checklists.restoreItem""": """Wiederherstellen""",
  """checklists.permanentlyDeleteItem""": """Löschen""",
  """checklists.permanentlyDeleteConfirm""":
      """Diesen Eintrag endgültig löschen?""",
  """checklists.permanentlyDeleteConfirmBody""":
      """Dies kann nicht rückgängig gemacht werden.""",
  """checklists.restoreFailed""":
      """Eintrag konnte nicht wiederhergestellt werden.""",
  """checklists.permanentlyDeleteFailed""":
      """Eintrag konnte nicht gelöscht werden.""",
  """checklists.itemRestored""": """Eintrag wiederhergestellt""",
  """checklists.viewArchive""": """Archiv anzeigen""",
  """checklists.exitArchive""": """Archiv verlassen""",
  """checklists.archiveTitle""": """Archiv""",
  """checklists.noCategory""": """Keine Kategorie""",
  """checklists.noArchivedItems""": """Das Archiv ist leer.""",
  """checklists.archiveItem""": """Archivieren""",
  """checklists.unarchiveItem""": """Dearchivieren""",
  """checklists.archiveFailed""": """Eintrag konnte nicht archiviert werden.""",
  """checklists.unarchiveFailed""":
      """Eintrag konnte nicht dearchiviert werden.""",
  """checklists.itemArchived""": """Eintrag archiviert""",
  """checklists.itemUnarchived""": """Eintrag dearchiviert""",
  """checklists.failedToLoadArchive""":
      """Archiv konnte nicht geladen werden.""",
  """checklists.viewListsTrash""": """Gelöschte Listen""",
  """checklists.listsTrashTitle""": """Gelöschte Listen""",
  """checklists.failedToLoadTrash""":
      """Papierkorb konnte nicht geladen werden.""",
  """checklists.listTrashEmpty""": """Keine gelöschten Listen.""",
  """checklists.pinList""": """Liste anheften""",
  """checklists.unpinList""": """Liste lösen""",
  """checklists.removeList""": """Liste entfernen""",
  """checklists.editList""": """Liste bearbeiten""",
  """checklists.editListTitle""": """Liste bearbeiten""",
  """checklists.saveListButton""": """Änderungen speichern""",
  """checklists.updateListFailed""":
      """Liste konnte nicht aktualisiert werden.""",
  """checklists.removeListConfirm""": """Liste entfernen?""",
  """checklists.removeListFailed""": """Liste konnte nicht entfernt werden.""",
  """checklists.restoreList""": """Liste wiederherstellen""",
  """checklists.permanentlyDeleteList""": """Endgültig löschen""",
  """checklists.listRemoved""": """Liste entfernt""",
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
  """checklists.viewItem.quantityLabel""": """Menge""",
  """checklists.viewItem.typeLabel""": """Typ""",
  """checklists.viewItem.descriptionLabel""": """Beschreibung""",
  """checklists.viewItem.noDescription""":
      """Keine Beschreibung hinzugefügt.""",
  """checklists.viewItem.relJustNow""": """gerade eben""",
  """checklists.viewItem.relToday""": """heute""",
  """checklists.viewItem.relYesterday""": """gestern""",
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
  """checklists.itemForm.takePhoto""": """Foto aufnehmen""",
  """checklists.itemForm.chooseImage""": """Bild auswählen""",
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
  """checklists.hideProgressHero""": """Fortschrittskarte ausblenden""",
  """checklists.sortTooltip""": """Sortieren""",
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
  """checklists.swipeCopy""": """Kopieren""",
  """checklists.swipeDelete""": """Entfernen""",
  """checklists.swipeArchive""": """Archivieren""",
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
  """checklists.compose.chipTargetList""": """Liste""",
  """checklists.compose.pickTargetList""": """Liste wählen""",
  """checklists.compose.multiple""": """Mehrere""",
  """checklists.compose.multipleHint""":
      """Einträge durch Zeilenumbrüche trennen""",
  """checklists.reuse.dialogTitle""": """Eintrag existiert bereits""",
  """checklists.reuse.reuseExisting""": """Vorhandenen wiederverwenden""",
  """checklists.reuse.addAnyway""": """Trotzdem hinzufügen""",
  """checklists.allLists""": """Alle Listen""",
  """checklists.allListsSubtitle""": """Einträge aus allen Listen""",
  """checklists.addToAnyList""": """Eintrag hinzufügen…""",
  """checklists.pickListTitle""": """Zu welcher Liste hinzufügen?""",
  """checklists.markdown.uncategorized""": """Ohne Kategorie""",
  """checklists.markdown.exportTitle""": """Als Markdown exportieren""",
  """checklists.markdown.importTitle""": """Aus Markdown importieren""",
  """checklists.markdown.includeCompleted""":
      """Erledigte Einträge einschließen""",
  """checklists.markdown.editHint""":
      """Bearbeite den Text unten, um die exportierte Liste anzupassen""",
  """checklists.markdown.copy""": """Kopieren""",
  """checklists.markdown.download""": """.md herunterladen""",
  """checklists.markdown.copied""": """In die Zwischenablage kopiert""",
  """checklists.markdown.copyFailed""":
      """Konnte nicht in die Zwischenablage kopieren""",
  """checklists.markdown.close""": """Schließen""",
  """checklists.markdown.shareFailed""":
      """Datei konnte nicht exportiert werden""",
  """checklists.markdown.uploadFile""": """.md-Datei hochladen""",
  """checklists.markdown.pasteLabel""": """Markdown einfügen""",
  """checklists.markdown.pastePlaceholder""":
      """Füge hier eine Markdown-Liste ein…""",
  """checklists.markdown.noneFound""":
      """Keine Listeneinträge im Text gefunden.""",
  """checklists.markdown.selectAll""": """Alle auswählen""",
  """checklists.markdown.deselectAll""": """Alle abwählen""",
  """checklists.markdown.reuseExisting""":
      """Vorhandene Einträge wiederverwenden statt Duplikate hinzuzufügen""",
  """checklists.markdown.defaultFields""":
      """Standardwerte für jeden importierten Eintrag""",
  """notesWall.noNotes""": """Noch keine Notizen.""",
  """notesWall.failedToLoad""": """Notizen konnten nicht geladen werden.""",
  """notesWall.saveFailed""": """Notiz konnte nicht gespeichert werden.""",
  """notesWall.deleteFailed""": """Notiz konnte nicht gelöscht werden.""",
  """notesWall.deleteConfirm""": """Diese Notiz löschen?""",
  """notesWall.viewTrash""": """Papierkorb anzeigen""",
  """notesWall.exitTrash""": """Papierkorb verlassen""",
  """notesWall.trashTitle""": """Papierkorb""",
  """notesWall.trashEmpty""": """Der Papierkorb ist leer.""",
  """notesWall.emptyTrash""": """Papierkorb leeren""",
  """notesWall.emptyTrashConfirm""": """Papierkorb leeren?""",
  """notesWall.emptyTrashConfirmBody""":
      """Alle Notizen im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""",
  """notesWall.emptyTrashFailed""":
      """Papierkorb konnte nicht geleert werden.""",
  """notesWall.failedToLoadTrash""":
      """Papierkorb konnte nicht geladen werden.""",
  """notesWall.restore""": """Wiederherstellen""",
  """notesWall.restoreFailed""":
      """Notiz konnte nicht wiederhergestellt werden.""",
  """notesWall.permanentlyDelete""": """Endgültig löschen""",
  """notesWall.permanentlyDeleteConfirm""":
      """Diese Notiz endgültig löschen?""",
  """notesWall.permanentlyDeleteConfirmBody""":
      """Dies kann nicht rückgängig gemacht werden.""",
  """notesWall.newNote""": """Neue Notiz""",
  """notesWall.editNote""": """Notiz bearbeiten""",
  """notesWall.unsavedChanges""": """Nicht gespeicherte Änderungen""",
  """notesWall.unsavedChangesBody""":
      """Du hast nicht gespeicherte Änderungen. Möchtest du sie speichern?""",
  """notesWall.discard""": """Verwerfen""",
  """notesWall.keepEditing""": """Weiter bearbeiten""",
  """notesWall.pinNote""": """Notiz anheften""",
  """notesWall.unpinNote""": """Notiz lösen""",
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
  """photoBoard.viewTrash""": """Papierkorb anzeigen""",
  """photoBoard.exitTrash""": """Papierkorb verlassen""",
  """photoBoard.trashTitle""": """Papierkorb""",
  """photoBoard.trashEmpty""": """Der Papierkorb ist leer.""",
  """photoBoard.emptyTrash""": """Papierkorb leeren""",
  """photoBoard.emptyTrashConfirm""": """Papierkorb leeren?""",
  """photoBoard.emptyTrashConfirmBody""":
      """Alle Fotos im Papierkorb werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.""",
  """photoBoard.emptyTrashFailed""":
      """Papierkorb konnte nicht geleert werden.""",
  """photoBoard.failedToLoadTrash""":
      """Papierkorb konnte nicht geladen werden.""",
  """photoBoard.restore""": """Wiederherstellen""",
  """photoBoard.restoreFailed""":
      """Foto konnte nicht wiederhergestellt werden.""",
  """photoBoard.permanentlyDelete""": """Endgültig löschen""",
  """photoBoard.permanentlyDeleteConfirm""":
      """Dieses Foto endgültig löschen?""",
  """photoBoard.permanentlyDeleteConfirmBody""":
      """Dies kann nicht rückgängig gemacht werden.""",
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
  """sync.offline""": """Offline""",
  """sync.syncing""": """Änderungen werden synchronisiert…""",
  """sync.syncError""": """Synchronisierung fehlgeschlagen""",
  """sync.retry""": """Erneut versuchen""",
};
