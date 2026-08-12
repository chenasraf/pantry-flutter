// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:i18n/i18n.dart' as i18n;
import 'messages.i18n.dart';

String get _languageCode => 'nn';
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

class MessagesNn extends Messages {
  const MessagesNn();
  String get locale => "nn";
  String get languageCode => "nn";
  CommonMessagesNn get common => CommonMessagesNn(this);
  LoginMessagesNn get login => LoginMessagesNn(this);
  HomeMessagesNn get home => HomeMessagesNn(this);
  NavMessagesNn get nav => NavMessagesNn(this);
  OnboardingMessagesNn get onboarding => OnboardingMessagesNn(this);
  NotificationsIntroMessagesNn get notificationsIntro =>
      NotificationsIntroMessagesNn(this);
  AboutMessagesNn get about => AboutMessagesNn(this);
  SettingsMessagesNn get settings => SettingsMessagesNn(this);
  NotificationsMessagesNn get notifications => NotificationsMessagesNn(this);
  CategoriesMessagesNn get categories => CategoriesMessagesNn(this);
  StoresMessagesNn get stores => StoresMessagesNn(this);
  ChecklistsMessagesNn get checklists => ChecklistsMessagesNn(this);
  NotesWallMessagesNn get notesWall => NotesWallMessagesNn(this);
  PhotoBoardMessagesNn get photoBoard => PhotoBoardMessagesNn(this);
  ShoppingMessagesNn get shopping => ShoppingMessagesNn(this);
  ShareMessagesNn get share => ShareMessagesNn(this);
  RecurrenceMessagesNn get recurrence => RecurrenceMessagesNn(this);
  SyncMessagesNn get sync => SyncMessagesNn(this);
  MarkdownEditorMessagesNn get markdownEditor => MarkdownEditorMessagesNn(this);
}

class CommonMessagesNn extends CommonMessages {
  final MessagesNn _parent;
  const CommonMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "Avbryt"
  /// ```
  String get cancel => """Avbryt""";

  /// ```dart
  /// "Slett"
  /// ```
  String get delete => """Slett""";

  /// ```dart
  /// "Lagre"
  /// ```
  String get save => """Lagre""";

  /// ```dart
  /// "Prøv på nytt"
  /// ```
  String get retry => """Prøv på nytt""";

  /// ```dart
  /// "Oppfrisk"
  /// ```
  String get refresh => """Oppfrisk""";

  /// ```dart
  /// "Logg ut"
  /// ```
  String get logout => """Logg ut""";

  /// ```dart
  /// "Lastar..."
  /// ```
  String get loading => """Lastar...""";

  /// ```dart
  /// "Feil"
  /// ```
  String get error => """Feil""";

  /// ```dart
  /// "Kopier"
  /// ```
  String get copy => """Kopier""";

  /// ```dart
  /// "Kopiert"
  /// ```
  String get copied => """Kopiert""";

  /// ```dart
  /// "Ferdig"
  /// ```
  String get closeDialog => """Ferdig""";

  /// ```dart
  /// "Fjern"
  /// ```
  String get remove => """Fjern""";

  /// ```dart
  /// "Tøm"
  /// ```
  String get clear => """Tøm""";

  /// ```dart
  /// "Du har ikkje tilgang til å gjere det"
  /// ```
  String get permissionDenied => """Du har ikkje tilgang til å gjere det""";

  /// ```dart
  /// "Ingen tilgang"
  /// ```
  String get noAccessTitle => """Ingen tilgang""";

  /// ```dart
  /// "Du har ikkje tilgang til noko i dette huset enno. Ein administrator kan gi deg tilgang gjennom Pantry-nettappen."
  /// ```
  String get noAccessBody =>
      """Du har ikkje tilgang til noko i dette huset enno. Ein administrator kan gi deg tilgang gjennom Pantry-nettappen.""";
}

class LoginMessagesNn extends LoginMessages {
  final MessagesNn _parent;
  const LoginMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Koble til Nextcloud-instansen din"
  /// ```
  String get connectToNextcloud => """Koble til Nextcloud-instansen din""";

  /// ```dart
  /// "Tenaradresse"
  /// ```
  String get serverUrl => """Tenaradresse""";

  /// ```dart
  /// "sky.example.com"
  /// ```
  String get serverUrlHint => """sky.example.com""";

  /// ```dart
  /// "Koble til"
  /// ```
  String get connect => """Koble til""";

  /// ```dart
  /// """
  /// Ventar på autentisering...
  /// Fullfør innlogginga i nettlesaren din.
  /// """
  /// ```
  String get waitingForAuth => """Ventar på autentisering...
Fullfør innlogginga i nettlesaren din.""";

  /// ```dart
  /// "Kunne ikkje koble til tenaren. Sjekk at adressa er korrekt."
  /// ```
  String get couldNotConnect =>
      """Kunne ikkje koble til tenaren. Sjekk at adressa er korrekt.""";

  /// ```dart
  /// "Innlogginga mislukkast. Prøv igjen."
  /// ```
  String get loginFailed => """Innlogginga mislukkast. Prøv igjen.""";

  /// ```dart
  /// "Sjå detaljar"
  /// ```
  String get seeDetails => """Sjå detaljar""";

  /// ```dart
  /// "Feildetaljar"
  /// ```
  String get errorDetailsTitle => """Feildetaljar""";

  /// ```dart
  /// "Sertifikat ikkje godkjent"
  /// ```
  String get untrustedCertTitle => """Sertifikat ikkje godkjent""";

  /// ```dart
  /// "${host} brukar eit sertifikat som ikkje er godkjent av eininga di - som oftast er dette fordi det ikkje er sjølvsignert. Bekreft at fingeravtrykket stemmar med det administratoren av tenaren ga til deg før du vel å stole på det."
  /// ```
  String untrustedCertBody(String host) =>
      """${host} brukar eit sertifikat som ikkje er godkjent av eininga di - som oftast er dette fordi det ikkje er sjølvsignert. Bekreft at fingeravtrykket stemmar med det administratoren av tenaren ga til deg før du vel å stole på det.""";

  /// ```dart
  /// "Berre stol på sertifikatet viss du kjennar att fingeravtrykket. Å stole på eit sertifikat frå nokon uvedkommande kan la ein angripar lese trafikken din."
  /// ```
  String get untrustedCertWarning =>
      """Berre stol på sertifikatet viss du kjennar att fingeravtrykket. Å stole på eit sertifikat frå nokon uvedkommande kan la ein angripar lese trafikken din.""";

  /// ```dart
  /// "Stol på sertifikat"
  /// ```
  String get trustCertificate => """Stol på sertifikat""";

  /// ```dart
  /// "SHA-256 fingeravtrykk"
  /// ```
  String get certFingerprint => """SHA-256 fingeravtrykk""";

  /// ```dart
  /// "Emne"
  /// ```
  String get certSubject => """Emne""";

  /// ```dart
  /// "Utstedt av"
  /// ```
  String get certIssuer => """Utstedt av""";

  /// ```dart
  /// "Gyldig"
  /// ```
  String get certValidity => """Gyldig""";

  /// ```dart
  /// "Logg inn med eit app-passord i stadenfor"
  /// ```
  String get useAppPassword => """Logg inn med eit app-passord i stadenfor""";

  /// ```dart
  /// "Logg inn med nettlesaren i stadenfor"
  /// ```
  String get useBrowserLogin => """Logg inn med nettlesaren i stadenfor""";

  /// ```dart
  /// "Brukarnamn"
  /// ```
  String get username => """Brukarnamn""";

  /// ```dart
  /// "App passord"
  /// ```
  String get appPassword => """App passord""";

  /// ```dart
  /// "Lag eit app passord i Nextcloud under Innstillingar → Sikkerheit → Einingar & sesjonar. Bruk dette viss nettlesaren ikkje vil opne eller tenaren brukar eit sjølvsignert sertifikat."
  /// ```
  String get appPasswordHelp =>
      """Lag eit app passord i Nextcloud under Innstillingar → Sikkerheit → Einingar & sesjonar. Bruk dette viss nettlesaren ikkje vil opne eller tenaren brukar eit sjølvsignert sertifikat.""";

  /// ```dart
  /// "Skriv inn brukarnamn og app passord."
  /// ```
  String get appPasswordMissing => """Skriv inn brukarnamn og app passord.""";

  /// ```dart
  /// "Logg inn"
  /// ```
  String get signIn => """Logg inn""";

  /// ```dart
  /// "Kunne ikkje kople til tenaren. Sjekk adressa og nettverk- eller VPN-tilkoblinga di."
  /// ```
  String get couldNotReachServer =>
      """Kunne ikkje kople til tenaren. Sjekk adressa og nettverk- eller VPN-tilkoblinga di.""";

  /// ```dart
  /// "Tenaren tok for lang tid til å svare. Sjekk adressa og nettverk- eller VPN-tilkoblinga di."
  /// ```
  String get connectionTimeout =>
      """Tenaren tok for lang tid til å svare. Sjekk adressa og nettverk- eller VPN-tilkoblinga di.""";

  /// ```dart
  /// "Klarte ikkje å lese sertifikatet til tenaren for å bekrefte det. Tilkoblinga kan vere ustabil, eller tenaren kan vere utilgjengeleg."
  /// ```
  String get certProbeFailed =>
      """Klarte ikkje å lese sertifikatet til tenaren for å bekrefte det. Tilkoblinga kan vere ustabil, eller tenaren kan vere utilgjengeleg.""";
}

class HomeMessagesNn extends HomeMessages {
  final MessagesNn _parent;
  const HomeMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Ingen hus enno."
  /// ```
  String get noHouses => """Ingen hus enno.""";

  /// ```dart
  /// "Hus er eit område for hushaldninga di. Opprett ditt fyrste hus for å kunne leggje til sjekklister, bilete og notat."
  /// ```
  String get noHousesBody =>
      """Hus er eit område for hushaldninga di. Opprett ditt fyrste hus for å kunne leggje til sjekklister, bilete og notat.""";

  /// ```dart
  /// "Opprett hus"
  /// ```
  String get createHouse => """Opprett hus""";

  /// ```dart
  /// "Namn på hus"
  /// ```
  String get houseName => """Namn på hus""";

  /// ```dart
  /// "Skildring (valfritt)"
  /// ```
  String get houseDescription => """Skildring (valfritt)""";

  /// ```dart
  /// "Klarte ikkje opprette hus"
  /// ```
  String get createHouseFailed => """Klarte ikkje opprette hus""";

  /// ```dart
  /// "Klarte ikkje laste hus"
  /// ```
  String get failedToLoadHouses => """Klarte ikkje laste hus""";

  /// ```dart
  /// "Pantry er ikkje installert"
  /// ```
  String get serverAppMissingTitle => """Pantry er ikkje installert""";

  /// ```dart
  /// "Denne appen er ein klient for Pantry-appen i Nextcloud. Det ser ut til at Pantry ikkje er installert på tenaren din enno. Spør administratoren om dei kan installere den frå Nextcloud app-butikken, eller installer den sjølv viss du har administratortilgang."
  /// ```
  String get serverAppMissingBody =>
      """Denne appen er ein klient for Pantry-appen i Nextcloud. Det ser ut til at Pantry ikkje er installert på tenaren din enno. Spør administratoren om dei kan installere den frå Nextcloud app-butikken, eller installer den sjølv viss du har administratortilgang.""";

  /// ```dart
  /// "Opne Nextcloud appar"
  /// ```
  String get openAppStore => """Opne Nextcloud appar""";

  /// ```dart
  /// "Lær meir"
  /// ```
  String get learnMore => """Lær meir""";
}

class NavMessagesNn extends NavMessages {
  final MessagesNn _parent;
  const NavMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Sjekkliste"
  /// ```
  String get checklists => """Sjekkliste""";

  /// ```dart
  /// "Fotovegg"
  /// ```
  String get photoBoard => """Fotovegg""";

  /// ```dart
  /// "Notatvegg"
  /// ```
  String get notesWall => """Notatvegg""";
}

class OnboardingMessagesNn extends OnboardingMessages {
  final MessagesNn _parent;
  const OnboardingMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Neste"
  /// ```
  String get next => """Neste""";

  /// ```dart
  /// "Tilbake"
  /// ```
  String get back => """Tilbake""";

  /// ```dart
  /// "Hopp over"
  /// ```
  String get skip => """Hopp over""";

  /// ```dart
  /// "Kom i gang"
  /// ```
  String get done => """Kom i gang""";

  /// ```dart
  /// "Steg ${current} av ${total}"
  /// ```
  String stepLabel(int current, int total) => """Steg ${current} av ${total}""";

  /// ```dart
  /// "Velkomen til Pantry"
  /// ```
  String get welcomeNewTitle => """Velkomen til Pantry""";

  /// ```dart
  /// "Få ein kort introduksjon til korleis Pantry fungerer og korleis du kan få mest mogleg ut av den."
  /// ```
  String get welcomeNewBody =>
      """Få ein kort introduksjon til korleis Pantry fungerer og korleis du kan få mest mogleg ut av den.""";

  /// ```dart
  /// "Kva er nytt"
  /// ```
  String get welcomeUpdateTitle => """Kva er nytt""";

  /// ```dart
  /// "Pantry har fått nokre nye funksjonar sidan du opna den sist. Her er ein kort gjennomgang av kva som er endra."
  /// ```
  String get welcomeUpdateBody =>
      """Pantry har fått nokre nye funksjonar sidan du opna den sist. Her er ein kort gjennomgang av kva som er endra.""";

  /// ```dart
  /// "Sjekklister har fått ein ny utsjånad"
  /// ```
  String get checklistsRedesignTitle =>
      """Sjekklister har fått ein ny utsjånad""";

  /// ```dart
  /// "Sjekklistesida har blit bygga opp på nytt med eit reinare oppsett, raskare måtar å leggje til oppføringar og hurtighandlingar på kvar rad. Dei neste sidene tek deg gjennom kva som er nytt."
  /// ```
  String get checklistsRedesignBody =>
      """Sjekklistesida har blit bygga opp på nytt med eit reinare oppsett, raskare måtar å leggje til oppføringar og hurtighandlingar på kvar rad. Dei neste sidene tek deg gjennom kva som er nytt.""";

  /// ```dart
  /// "Byt lister på toppen"
  /// ```
  String get checklistSelectorTitle => """Byt lister på toppen""";

  /// ```dart
  /// "Trykk på eit namnet eller ikonet til ei liste på toppen av skjermen for å byte mellom lister eller opprette ei ny liste."
  /// ```
  String get checklistSelectorBody =>
      """Trykk på eit namnet eller ikonet til ei liste på toppen av skjermen for å byte mellom lister eller opprette ei ny liste.""";

  /// ```dart
  /// "Trykk for å byte lister"
  /// ```
  String get checklistSelectorHint => """Trykk for å byte lister""";

  /// ```dart
  /// "Daglegvarer"
  /// ```
  String get mockListGroceries => """Daglegvarer""";

  /// ```dart
  /// "Jernvarebutikk"
  /// ```
  String get mockListHardware => """Jernvarebutikk""";

  /// ```dart
  /// "Helgetur"
  /// ```
  String get mockListWeekend => """Helgetur""";

  /// ```dart
  /// "${count} oppføringar"
  /// ```
  String mockItemCountSummary(int count) => """${count} oppføringar""";

  /// ```dart
  /// "Ny liste"
  /// ```
  String get newListLabel => """Ny liste""";

  /// ```dart
  /// "Svei på oppføringar for å handsame dei"
  /// ```
  String get swipeActionsTitle => """Svei på oppføringar for å handsame dei""";

  /// ```dart
  /// "Sveip frå høgre til venstre på ei oppføring for å vise hurtighandlingar for redigering, flytting og sletting."
  /// ```
  String get swipeActionsBody =>
      """Sveip frå høgre til venstre på ei oppføring for å vise hurtighandlingar for redigering, flytting og sletting.""";

  /// ```dart
  /// "Sveip mot venstre"
  /// ```
  String get swipeActionsHint => """Sveip mot venstre""";

  /// ```dart
  /// "Sveip mot høgre"
  /// ```
  String get swipeActionsHintBack => """Sveip mot høgre""";

  /// ```dart
  /// "Hurtighandlingar på kvar oppføring"
  /// ```
  String get quickActionsTitle => """Hurtighandlingar på kvar oppføring""";

  /// ```dart
  /// "Kvar oppføring viser handlingsknappar, trykk på ein av dei for å redigere, flytte eller slette ein oppføring utan å opne den."
  /// ```
  String get quickActionsBody =>
      """Kvar oppføring viser handlingsknappar, trykk på ein av dei for å redigere, flytte eller slette ein oppføring utan å opne den.""";

  /// ```dart
  /// "Ein raskare måte å leggje til oppføringar"
  /// ```
  String get addItemsTitle => """Ein raskare måte å leggje til oppføringar""";

  /// ```dart
  /// "Trykk på feltet ved bunnen for å skrive inn ei ny oppføring, merk det med ein kategori, mengd, type eller bilete ved å bruke brikkene over."
  /// ```
  String get addItemsBody =>
      """Trykk på feltet ved bunnen for å skrive inn ei ny oppføring, merk det med ein kategori, mengd, type eller bilete ved å bruke brikkene over.""";

  /// ```dart
  /// "Daglegvarer"
  /// ```
  String get mockComposeListName => """Daglegvarer""";

  /// ```dart
  /// "Skjul framgangskortet"
  /// ```
  String get progressHeroTitle => """Skjul framgangskortet""";

  /// ```dart
  /// "Treng du ikkje framdriftsringen på toppen? Sveip den bort."
  /// ```
  String get progressHeroBody =>
      """Treng du ikkje framdriftsringen på toppen? Sveip den bort.""";

  /// ```dart
  /// "Hent det tilbake når som helst frå listemenyen → ${toggle}."
  /// ```
  String progressHeroBringBack(String toggle) =>
      """Hent det tilbake når som helst frå listemenyen → ${toggle}.""";

  /// ```dart
  /// "Sveip for å avvise"
  /// ```
  String get progressHeroHint => """Sveip for å avvise""";

  /// ```dart
  /// "Skjul framgangskortet"
  /// ```
  String get progressHeroDismissTitle => """Skjul framgangskortet""";

  /// ```dart
  /// "Treng du ikkje framdriftsringen på toppen? Trykk på X-en på kortet for å skjule det."
  /// ```
  String get progressHeroDismissBody =>
      """Treng du ikkje framdriftsringen på toppen? Trykk på X-en på kortet for å skjule det.""";

  /// ```dart
  /// "Fest lister til heimskjermen"
  /// ```
  String get pinnedListsTitle => """Fest lister til heimskjermen""";

  /// ```dart
  /// "Legg skjermelementet til Pantry på heimskjermen for å sjå kor mange oppføringar som er igjen på favorittlistene dine utan å opne appen."
  /// ```
  String get pinnedListsBody =>
      """Legg skjermelementet til Pantry på heimskjermen for å sjå kor mange oppføringar som er igjen på favorittlistene dine utan å opne appen.""";

  /// ```dart
  /// "Opne ei liste, trykk på ${menu} øvst til høgre og vel ${action}. Festa lister blir vist på skjermelementet på heimskjermen. Fjern festinga for å skjule dei."
  /// ```
  String pinnedListsHow(String menu, String action) =>
      """Opne ei liste, trykk på ${menu} øvst til høgre og vel ${action}. Festa lister blir vist på skjermelementet på heimskjermen. Fjern festinga for å skjule dei.""";

  /// ```dart
  /// "kebab-menyen"
  /// ```
  String get pinnedListsMenuLabel => """kebab-menyen""";

  /// ```dart
  /// "Fest liste"
  /// ```
  String get pinnedListsActionLabel => """Fest liste""";

  /// ```dart
  /// "Pantry"
  /// ```
  String get pinnedListsWidgetTitle => """Pantry""";

  /// ```dart
  /// "${_plural(count, one: '1 igjen', many: '${count} igjen')}"
  /// ```
  String pinnedListsWidgetItemsLeft(int count) =>
      """${_plural(count, one: '1 igjen', many: '${count} igjen')}""";

  /// ```dart
  /// "Ferdig"
  /// ```
  String get pinnedListsWidgetEmpty => """Ferdig""";

  /// ```dart
  /// "Hald viktige notat på toppen"
  /// ```
  String get pinnedNotesTitle => """Hald viktige notat på toppen""";

  /// ```dart
  /// "Fest eit notat frå overflytsmenyen for å låse det til toppen av notatveggen, sånn at det alltid er synleg."
  /// ```
  String get pinnedNotesBody =>
      """Fest eit notat frå overflytsmenyen for å låse det til toppen av notatveggen, sånn at det alltid er synleg.""";

  /// ```dart
  /// "Wi-Fi passord"
  /// ```
  String get mockPinnedNoteTitle => """Wi-Fi passord""";

  /// ```dart
  /// """
  /// Nettverk: Heime
  /// Passord: pantry
  /// """
  /// ```
  String get mockPinnedNoteContent => """Nettverk: Heime
Passord: pantry""";

  /// ```dart
  /// "Tomat"
  /// ```
  String get mockItemName => """Tomat""";

  /// ```dart
  /// "x2"
  /// ```
  String get mockItemQuantity => """x2""";

  /// ```dart
  /// "Meieriprodukt"
  /// ```
  String get mockItemCategory => """Meieriprodukt""";

  /// ```dart
  /// "Lyspærer"
  /// ```
  String get mockHardwareItemName => """Lyspærer""";

  /// ```dart
  /// "Mjølk"
  /// ```
  String get mockBulkItemThird => """Mjølk""";

  /// ```dart
  /// "Brød"
  /// ```
  String get mockBulkItemFourth => """Brød""";

  /// ```dart
  /// "Alt i ei visning"
  /// ```
  String get allListsTitle => """Alt i ei visning""";

  /// ```dart
  /// "Opne «Alle lister»-visninga frå listebytaren for å sjå oppføringar frå alle listene dine samla. Når du legg til ein oppføring her vil du bli spurd om kva liste du vil putte det i, det kan du velje frå «Liste»-brikka."
  /// ```
  String get allListsBody =>
      """Opne «Alle lister»-visninga frå listebytaren for å sjå oppføringar frå alle listene dine samla. Når du legg til ein oppføring her vil du bli spurd om kva liste du vil putte det i, det kan du velje frå «Liste»-brikka.""";

  /// ```dart
  /// "Legg til mange oppføringar på ein gang"
  /// ```
  String get bulkAddTitle => """Legg til mange oppføringar på ein gang""";

  /// ```dart
  /// "Slå på «fleire» og tekstfeltet blir til eit felt med fleire linjer, og kvar linje blir sin eigen oppføring. Nyttig når du limar inn eller skriv ned ei heil handleliste."
  /// ```
  String get bulkAddBody =>
      """Slå på «fleire» og tekstfeltet blir til eit felt med fleire linjer, og kvar linje blir sin eigen oppføring. Nyttig når du limar inn eller skriv ned ei heil handleliste.""";

  /// ```dart
  /// "Utfør handlingar på fleire oppføringar om gangen"
  /// ```
  String get bulkSelectTitle =>
      """Utfør handlingar på fleire oppføringar om gangen""";

  /// ```dart
  /// "Trykk og hald nede på ei oppføring eller trykk på «Vel oppføringar» i menyen for å flytte, kopiere, endre kategori eller slette alle dei valde på ein gang."
  /// ```
  String get bulkSelectBody =>
      """Trykk og hald nede på ei oppføring eller trykk på «Vel oppføringar» i menyen for å flytte, kopiere, endre kategori eller slette alle dei valde på ein gang.""";

  /// ```dart
  /// "Skann ein strekkode for å legge til oppføringar"
  /// ```
  String get barcodeScanTitle =>
      """Skann ein strekkode for å legge til oppføringar""";

  /// ```dart
  /// "Trykk på skanneknappen i tilleggsfeltet og rett kameraet mot strekkoden på eit produkt. Pantry slår opp namn, kategori og bilete og fyller dei inn for deg - eller skriv nummeret inn for hand. Den første skanninga av eit produkt gjer oppslaget, etter det er det momentant for alle i huset ditt."
  /// ```
  String get barcodeScanBody =>
      """Trykk på skanneknappen i tilleggsfeltet og rett kameraet mot strekkoden på eit produkt. Pantry slår opp namn, kategori og bilete og fyller dei inn for deg - eller skriv nummeret inn for hand. Den første skanninga av eit produkt gjer oppslaget, etter det er det momentant for alle i huset ditt.""";

  /// ```dart
  /// "Coca-Cola Zero"
  /// ```
  String get barcodeScanMockName => """Coca-Cola Zero""";

  /// ```dart
  /// "Drikke"
  /// ```
  String get barcodeScanMockCategory => """Drikke""";

  /// ```dart
  /// "Legg til prisar på oppføringane dine"
  /// ```
  String get priceTitle => """Legg til prisar på oppføringane dine""";

  /// ```dart
  /// "Gje ei kvar oppføring ein pris – eit enkelt beløp eller eit område – i valutaen du vil. Han vert vist som ein brikke på oppføringa, og du kan filtrere lista etter pris for å halde deg innanfor budsjettet."
  /// ```
  String get priceBody =>
      """Gje ei kvar oppføring ein pris – eit enkelt beløp eller eit område – i valutaen du vil. Han vert vist som ein brikke på oppføringa, og du kan filtrere lista etter pris for å halde deg innanfor budsjettet.""";

  /// ```dart
  /// "Olivenolje"
  /// ```
  String get priceMockName => """Olivenolje""";

  /// ```dart
  /// "Handle butikk for butikk"
  /// ```
  String get shoppingIntroTitle => """Handle butikk for butikk""";

  /// ```dart
  /// "Start ein handletur over listene dine, gå gjennom kvar butikk i rekkjefølgje og kryss av varer undervegs — med ei løpande prissum."
  /// ```
  String get shoppingIntroBody =>
      """Start ein handletur over listene dine, gå gjennom kvar butikk i rekkjefølgje og kryss av varer undervegs — med ei løpande prissum.""";

  /// ```dart
  /// "Supermarknad"
  /// ```
  String get shoppingMockStoreActive => """Supermarknad""";

  /// ```dart
  /// "Apotek"
  /// ```
  String get shoppingMockStoreNext => """Apotek""";

  /// ```dart
  /// "* Krev Pantry for Nextcloud v${version}+"
  /// ```
  String serverRequirementNote(String version) =>
      """* Krev Pantry for Nextcloud v${version}+""";
  DevOnboardingMessagesNn get dev => DevOnboardingMessagesNn(this);
}

class DevOnboardingMessagesNn extends DevOnboardingMessages {
  final OnboardingMessagesNn _parent;
  const DevOnboardingMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Vis oppstartshjelp"
  /// ```
  String get showOnboarding => """Vis oppstartshjelp""";

  /// ```dart
  /// "Førehandsvis kva som er nytt"
  /// ```
  String get pickLastSeenTitle => """Førehandsvis kva som er nytt""";

  /// ```dart
  /// "Vel versjonen du vil sjå endringar sidan."
  /// ```
  String get pickLastSeenBody =>
      """Vel versjonen du vil sjå endringar sidan.""";

  /// ```dart
  /// "Aldri sett (ny brukar)"
  /// ```
  String get neverSeen => """Aldri sett (ny brukar)""";

  /// ```dart
  /// "Tving alle funksjonar på"
  /// ```
  String get forceAllFeatures => """Tving alle funksjonar på""";

  /// ```dart
  /// "Send ein testvarsling"
  /// ```
  String get sendTestNotification => """Send ein testvarsling""";
}

class NotificationsIntroMessagesNn extends NotificationsIntroMessages {
  final MessagesNn _parent;
  const NotificationsIntroMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Hald deg oppdatert"
  /// ```
  String get title => """Hald deg oppdatert""";

  /// ```dart
  /// "Pantry kan varsle deg når nokon legg oppføringar til på lister, lastar opp bilete eller legg igjen notat. Varslingar vert henta frå din Nextcloud-tenar - ingenting blir sendt via Google eller andre tredjepartar."
  /// ```
  String get body =>
      """Pantry kan varsle deg når nokon legg oppføringar til på lister, lastar opp bilete eller legg igjen notat. Varslingar vert henta frå din Nextcloud-tenar - ingenting blir sendt via Google eller andre tredjepartar.""";

  /// ```dart
  /// "Varslingar for hushaldningsaktivitet"
  /// ```
  String get bullet1 => """Varslingar for hushaldningsaktivitet""";

  /// ```dart
  /// "Henta direkte frå tenaren"
  /// ```
  String get bullet2 => """Henta direkte frå tenaren""";

  /// ```dart
  /// "Fungerer sjølv om appen er lukka"
  /// ```
  String get bullet3 => """Fungerer sjølv om appen er lukka""";

  /// ```dart
  /// "Slå på varslingar"
  /// ```
  String get enableButton => """Slå på varslingar""";

  /// ```dart
  /// "Ikkje no"
  /// ```
  String get skipButton => """Ikkje no""";

  /// ```dart
  /// "Tilgang nekta"
  /// ```
  String get permissionDeniedTitle => """Tilgang nekta""";

  /// ```dart
  /// "Du kan slå på varslingar seinare i innstillingane til appen. Om eininga di blokkerer varslingane må du endre det i innstillingane til eininga di."
  /// ```
  String get permissionDeniedBody =>
      """Du kan slå på varslingar seinare i innstillingane til appen. Om eininga di blokkerer varslingane må du endre det i innstillingane til eininga di.""";

  /// ```dart
  /// "Ok"
  /// ```
  String get ok => """Ok""";
}

class AboutMessagesNn extends AboutMessages {
  final MessagesNn _parent;
  const AboutMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Om"
  /// ```
  String get title => """Om""";

  /// ```dart
  /// "Utviklar"
  /// ```
  String get developer => """Utviklar""";

  /// ```dart
  /// "Epost"
  /// ```
  String get email => """Epost""";

  /// ```dart
  /// "Kjeldekode"
  /// ```
  String get repository => """Kjeldekode""";

  /// ```dart
  /// "Nextcloud-app"
  /// ```
  String get nextcloudApp => """Nextcloud-app""";

  /// ```dart
  /// "Personvern"
  /// ```
  String get privacyPolicy => """Personvern""";

  /// ```dart
  /// "Tilbakemelding og problemrapportar"
  /// ```
  String get feedback => """Tilbakemelding og problemrapportar""";

  /// ```dart
  /// "Nextcloud tenar"
  /// ```
  String get serverVersion => """Nextcloud tenar""";

  /// ```dart
  /// "Pantry på tenar"
  /// ```
  String get pantryServerVersion => """Pantry på tenar""";

  /// ```dart
  /// "Ukjend"
  /// ```
  String get versionUnknown => """Ukjend""";

  /// ```dart
  /// "Kjøp ein kaffi"
  /// ```
  String get buyMeACoffee => """Kjøp ein kaffi""";
}

class SettingsMessagesNn extends SettingsMessages {
  final MessagesNn _parent;
  const SettingsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Innstillingar"
  /// ```
  String get title => """Innstillingar""";

  /// ```dart
  /// "Generelt"
  /// ```
  String get generalSection => """Generelt""";

  /// ```dart
  /// "Brukargrensesnitt"
  /// ```
  String get interfaceSection => """Brukargrensesnitt""";

  /// ```dart
  /// "Standardhandling for rad"
  /// ```
  String get defaultItemTapAction => """Standardhandling for rad""";

  /// ```dart
  /// "Kva som skjer når du trykkar på ei rad."
  /// ```
  String get defaultItemTapActionBody =>
      """Kva som skjer når du trykkar på ei rad.""";
  ItemTapActionNamesSettingsMessagesNn get itemTapActionNames =>
      ItemTapActionNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Standardhandling for trykk-og-hald"
  /// ```
  String get defaultItemLongPressAction =>
      """Standardhandling for trykk-og-hald""";

  /// ```dart
  /// "Kva som skjer når du trykkar og hald nede på ei rad"
  /// ```
  String get defaultItemLongPressActionBody =>
      """Kva som skjer når du trykkar og hald nede på ei rad""";
  ItemLongPressActionNamesSettingsMessagesNn get itemLongPressActionNames =>
      ItemLongPressActionNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Posisjon for avkrysningsboks"
  /// ```
  String get checkboxPosition => """Posisjon for avkrysningsboks""";

  /// ```dart
  /// "Kva side av rada avkrysningsboksen kjem opp på"
  /// ```
  String get checkboxPositionBody =>
      """Kva side av rada avkrysningsboksen kjem opp på""";
  CheckboxPositionNamesSettingsMessagesNn get checkboxPositionNames =>
      CheckboxPositionNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Listetettleik"
  /// ```
  String get density => """Listetettleik""";

  /// ```dart
  /// "Kor mykje plass kvar oppføring får i listene."
  /// ```
  String get densityBody => """Kor mykje plass kvar oppføring får i listene.""";
  DensityNamesSettingsMessagesNn get densityNames =>
      DensityNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Sveiphandlingar"
  /// ```
  String get swipeActions => """Sveiphandlingar""";

  /// ```dart
  /// "Sveip på oppføringar for å vise hurtighandlingar. Når slått av vil desse handlingane bli flytta til ein menyknapp på kvar oppføring."
  /// ```
  String get swipeActionsBody =>
      """Sveip på oppføringar for å vise hurtighandlingar. Når slått av vil desse handlingane bli flytta til ein menyknapp på kvar oppføring.""";

  /// ```dart
  /// "Handlingar"
  /// ```
  String get itemActions => """Handlingar""";

  /// ```dart
  /// "Vis hurtighandlingar på kvar oppføring. Når slått av vil handlingane bli flytta til ein menyknapp på kvar oppføring."
  /// ```
  String get itemActionsBody =>
      """Vis hurtighandlingar på kvar oppføring. Når slått av vil handlingane bli flytta til ein menyknapp på kvar oppføring.""";

  /// ```dart
  /// "Bruk eksisterande oppføringar på nytt når du leggjer til nye"
  /// ```
  String get reuseExistingItems =>
      """Bruk eksisterande oppføringar på nytt når du leggjer til nye""";

  /// ```dart
  /// "Når du prøver å leggje til ei oppføring som allereie finst, bruk den eksisterande oppføringa på nytt i staden for å lage ei ny oppføring."
  /// ```
  String get reuseExistingItemsBody =>
      """Når du prøver å leggje til ei oppføring som allereie finst, bruk den eksisterande oppføringa på nytt i staden for å lage ei ny oppføring.""";
  ReuseExistingItemsNamesSettingsMessagesNn get reuseExistingItemsNames =>
      ReuseExistingItemsNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Navigasjonsrekkefylgje"
  /// ```
  String get navOrderTitle => """Navigasjonsrekkefylgje""";

  /// ```dart
  /// "Endre rekkefylgja på navigasjonsfanene. Den fyrste oppføringa er den som blir vist når du opnar appen."
  /// ```
  String get navOrderSubtitle =>
      """Endre rekkefylgja på navigasjonsfanene. Den fyrste oppføringa er den som blir vist når du opnar appen.""";

  /// ```dart
  /// "Dra for å endre rekkefylgja på fanene. Den fyrste synlege oppføringa blir vist når du opnar appen. Slå av delar du ikkje brukar for å skjula fana deira – minst éi må vera på."
  /// ```
  String get navOrderBody =>
      """Dra for å endre rekkefylgja på fanene. Den fyrste synlege oppføringa blir vist når du opnar appen. Slå av delar du ikkje brukar for å skjula fana deira – minst éi må vera på.""";

  /// ```dart
  /// "Blir vist når du opnar appen"
  /// ```
  String get navOrderDefaultHint => """Blir vist når du opnar appen""";

  /// ```dart
  /// "Nullstill"
  /// ```
  String get navOrderReset => """Nullstill""";

  /// ```dart
  /// "Varedetaljar"
  /// ```
  String get visibleChipsTitle => """Varedetaljar""";

  /// ```dart
  /// "Vel kva detaljar som blir viste på kvar vare."
  /// ```
  String get visibleChipsSubtitle =>
      """Vel kva detaljar som blir viste på kvar vare.""";

  /// ```dart
  /// "Slå av detaljar du ikkje vil ha viste som merkelapp på varelinjene."
  /// ```
  String get visibleChipsBody =>
      """Slå av detaljar du ikkje vil ha viste som merkelapp på varelinjene.""";

  /// ```dart
  /// "Nullstill"
  /// ```
  String get visibleChipsReset => """Nullstill""";
  ChipNamesSettingsMessagesNn get chipNames =>
      ChipNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Språk"
  /// ```
  String get language => """Språk""";

  /// ```dart
  /// "Systemstandard"
  /// ```
  String get systemLanguage => """Systemstandard""";

  /// ```dart
  /// "Drakt"
  /// ```
  String get theme => """Drakt""";
  ThemeNamesSettingsMessagesNn get themeNames =>
      ThemeNamesSettingsMessagesNn(this);

  /// ```dart
  /// "Bruk Nextcloud-temafarge"
  /// ```
  String get useServerThemeColor => """Bruk Nextcloud-temafarge""";

  /// ```dart
  /// "Fargelegg appen med temafargen til Nextcloud-brukaren din. Slå av for å bruke appen sine eigne fargar."
  /// ```
  String get useServerThemeColorBody =>
      """Fargelegg appen med temafargen til Nextcloud-brukaren din. Slå av for å bruke appen sine eigne fargar.""";

  /// ```dart
  /// "Varsel"
  /// ```
  String get notificationsSection => """Varsel""";

  /// ```dart
  /// "Slå på varsel"
  /// ```
  String get enableNotifications => """Slå på varsel""";

  /// ```dart
  /// "Vis varsel når nokon legg til eller opppdaterer innhald."
  /// ```
  String get enableNotificationsBody =>
      """Vis varsel når nokon legg til eller opppdaterer innhald.""";

  /// ```dart
  /// "Sjå etter ny aktivitet"
  /// ```
  String get pollInterval => """Sjå etter ny aktivitet""";

  /// ```dart
  /// "Kvart 15. minutt"
  /// ```
  String get pollInterval15m => """Kvart 15. minutt""";

  /// ```dart
  /// "Kvart 30. minutt"
  /// ```
  String get pollInterval30m => """Kvart 30. minutt""";

  /// ```dart
  /// "Kvar time"
  /// ```
  String get pollInterval1h => """Kvar time""";

  /// ```dart
  /// "Kvart 2. time"
  /// ```
  String get pollInterval2h => """Kvart 2. time""";

  /// ```dart
  /// "Kvart 6. time"
  /// ```
  String get pollInterval6h => """Kvart 6. time""";

  /// ```dart
  /// "Tilgang til å sende varslar vart ikkje gitt. Slå det på i systeminnstillingane."
  /// ```
  String get permissionDenied =>
      """Tilgang til å sende varslar vart ikkje gitt. Slå det på i systeminnstillingane.""";

  /// ```dart
  /// "Automatisk oppdatering"
  /// ```
  String get refreshSection => """Automatisk oppdatering""";

  /// ```dart
  /// "Kor ofte kvar skjerm ser etter endringar på tenaren medan du ser på han. Du kan alltid dra ned for å oppdatere manuelt."
  /// ```
  String get refreshSectionBody =>
      """Kor ofte kvar skjerm ser etter endringar på tenaren medan du ser på han. Du kan alltid dra ned for å oppdatere manuelt.""";

  /// ```dart
  /// "Lister"
  /// ```
  String get checklistRefresh => """Lister""";

  /// ```dart
  /// "Notat"
  /// ```
  String get notesRefresh => """Notat""";

  /// ```dart
  /// "Bilete"
  /// ```
  String get photosRefresh => """Bilete""";

  /// ```dart
  /// "Handlemodus"
  /// ```
  String get shoppingRefresh => """Handlemodus""";

  /// ```dart
  /// "Av"
  /// ```
  String get refreshOff => """Av""";

  /// ```dart
  /// "Som lister"
  /// ```
  String get refreshInherit => """Som lister""";

  /// ```dart
  /// "Kvart 15. sekund"
  /// ```
  String get refresh15s => """Kvart 15. sekund""";

  /// ```dart
  /// "Kvart 30. sekund"
  /// ```
  String get refresh30s => """Kvart 30. sekund""";

  /// ```dart
  /// "Kvart minutt"
  /// ```
  String get refresh1m => """Kvart minutt""";

  /// ```dart
  /// "Kvart 2. minutt"
  /// ```
  String get refresh2m => """Kvart 2. minutt""";

  /// ```dart
  /// "Kvart 5. minutt"
  /// ```
  String get refresh5m => """Kvart 5. minutt""";
}

class ItemTapActionNamesSettingsMessagesNn
    extends ItemTapActionNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const ItemTapActionNamesSettingsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Marker som ferdig"
  /// ```
  String get done => """Marker som ferdig""";

  /// ```dart
  /// "Vis"
  /// ```
  String get view => """Vis""";

  /// ```dart
  /// "Rediger"
  /// ```
  String get edit => """Rediger""";

  /// ```dart
  /// "Ingen"
  /// ```
  String get none => """Ingen""";
}

class ItemLongPressActionNamesSettingsMessagesNn
    extends ItemLongPressActionNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const ItemLongPressActionNamesSettingsMessagesNn(this._parent)
    : super(_parent);

  /// ```dart
  /// "Fleirval/Endre rekkefylgje"
  /// ```
  String get multiselect => """Fleirval/Endre rekkefylgje""";

  /// ```dart
  /// "Marker som ferdig"
  /// ```
  String get done => """Marker som ferdig""";

  /// ```dart
  /// "Vis"
  /// ```
  String get view => """Vis""";

  /// ```dart
  /// "Rediger"
  /// ```
  String get edit => """Rediger""";

  /// ```dart
  /// "Ingen"
  /// ```
  String get none => """Ingen""";
}

class CheckboxPositionNamesSettingsMessagesNn
    extends CheckboxPositionNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const CheckboxPositionNamesSettingsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Start"
  /// ```
  String get start => """Start""";

  /// ```dart
  /// "Slutt"
  /// ```
  String get end => """Slutt""";
}

class DensityNamesSettingsMessagesNn extends DensityNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const DensityNamesSettingsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Normal"
  /// ```
  String get normal => """Normal""";

  /// ```dart
  /// "Tett"
  /// ```
  String get dense => """Tett""";

  /// ```dart
  /// "Ekstra tett"
  /// ```
  String get compact => """Ekstra tett""";
}

class ReuseExistingItemsNamesSettingsMessagesNn
    extends ReuseExistingItemsNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const ReuseExistingItemsNamesSettingsMessagesNn(this._parent)
    : super(_parent);

  /// ```dart
  /// "Alltid spør"
  /// ```
  String get ask => """Alltid spør""";

  /// ```dart
  /// "Alltid bruk igjen"
  /// ```
  String get reuse => """Alltid bruk igjen""";

  /// ```dart
  /// "Aldri bruk igjen"
  /// ```
  String get never => """Aldri bruk igjen""";
}

class ChipNamesSettingsMessagesNn extends ChipNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const ChipNamesSettingsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Kategori"
  /// ```
  String get category => """Kategori""";

  /// ```dart
  /// "Butikk"
  /// ```
  String get store => """Butikk""";

  /// ```dart
  /// "Mengd"
  /// ```
  String get quantity => """Mengd""";

  /// ```dart
  /// "Pris"
  /// ```
  String get price => """Pris""";

  /// ```dart
  /// "Notat"
  /// ```
  String get note => """Notat""";

  /// ```dart
  /// "Eingongs"
  /// ```
  String get oneTime => """Eingongs""";

  /// ```dart
  /// "Gjentakande"
  /// ```
  String get recurring => """Gjentakande""";

  /// ```dart
  /// "Liste"
  /// ```
  String get list => """Liste""";
}

class ThemeNamesSettingsMessagesNn extends ThemeNamesSettingsMessages {
  final SettingsMessagesNn _parent;
  const ThemeNamesSettingsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Systemstandard"
  /// ```
  String get system => """Systemstandard""";

  /// ```dart
  /// "Lys"
  /// ```
  String get light => """Lys""";

  /// ```dart
  /// "Mørk"
  /// ```
  String get dark => """Mørk""";
}

class NotificationsMessagesNn extends NotificationsMessages {
  final MessagesNn _parent;
  const NotificationsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Varsel"
  /// ```
  String get title => """Varsel""";

  /// ```dart
  /// "Ingen nye varsel."
  /// ```
  String get empty => """Ingen nye varsel.""";

  /// ```dart
  /// "Klart ikkje laste varslingar."
  /// ```
  String get failedToLoad => """Klart ikkje laste varslingar.""";

  /// ```dart
  /// "Avvis alle"
  /// ```
  String get dismissAll => """Avvis alle""";

  /// ```dart
  /// "nett no"
  /// ```
  String get justNow => """nett no""";

  /// ```dart
  /// "${count}m sidan"
  /// ```
  String minutesAgo(int count) => """${count}m sidan""";

  /// ```dart
  /// "${count}t sidan"
  /// ```
  String hoursAgo(int count) => """${count}t sidan""";

  /// ```dart
  /// "${count}d sidan"
  /// ```
  String daysAgo(int count) => """${count}d sidan""";
}

class CategoriesMessagesNn extends CategoriesMessages {
  final MessagesNn _parent;
  const CategoriesMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Behandle kategoriar"
  /// ```
  String get manageTitle => """Behandle kategoriar""";

  /// ```dart
  /// "Ingen kategoriar enno."
  /// ```
  String get noCategories => """Ingen kategoriar enno.""";

  /// ```dart
  /// "Rediger kategori"
  /// ```
  String get editTitle => """Rediger kategori""";

  /// ```dart
  /// "Ny kategori"
  /// ```
  String get addTitle => """Ny kategori""";

  /// ```dart
  /// "Namn"
  /// ```
  String get name => """Namn""";

  /// ```dart
  /// "Ikon"
  /// ```
  String get icon => """Ikon""";

  /// ```dart
  /// "Farge"
  /// ```
  String get color => """Farge""";

  /// ```dart
  /// "Klarte ikkje lagre kategori."
  /// ```
  String get saveFailed => """Klarte ikkje lagre kategori.""";

  /// ```dart
  /// "Klarte ikkje slette kategori."
  /// ```
  String get deleteFailed => """Klarte ikkje slette kategori.""";

  /// ```dart
  /// "Slett denne kategorien?"
  /// ```
  String get deleteConfirm => """Slett denne kategorien?""";

  /// ```dart
  /// "Oppføringar i denne kategorien vil verta ukategoriserte. Dette kan ikkje angrast."
  /// ```
  String get deleteConfirmBody =>
      """Oppføringar i denne kategorien vil verta ukategoriserte. Dette kan ikkje angrast.""";
  SortCategoriesMessagesNn get sort => SortCategoriesMessagesNn(this);
}

class SortCategoriesMessagesNn extends SortCategoriesMessages {
  final CategoriesMessagesNn _parent;
  const SortCategoriesMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Namn A-Z"
  /// ```
  String get nameAZ => """Namn A-Z""";

  /// ```dart
  /// "Namn Z-A"
  /// ```
  String get nameZA => """Namn Z-A""";

  /// ```dart
  /// "Sjølvvald"
  /// ```
  String get custom => """Sjølvvald""";
}

class StoresMessagesNn extends StoresMessages {
  final MessagesNn _parent;
  const StoresMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Behandle butikkar"
  /// ```
  String get manageTitle => """Behandle butikkar""";

  /// ```dart
  /// "Ingen butikkar enno."
  /// ```
  String get noStores => """Ingen butikkar enno.""";

  /// ```dart
  /// "Rediger butikk"
  /// ```
  String get editTitle => """Rediger butikk""";

  /// ```dart
  /// "Ny butikk"
  /// ```
  String get addTitle => """Ny butikk""";

  /// ```dart
  /// "Namn"
  /// ```
  String get name => """Namn""";

  /// ```dart
  /// "Ikon"
  /// ```
  String get icon => """Ikon""";

  /// ```dart
  /// "Farge"
  /// ```
  String get color => """Farge""";

  /// ```dart
  /// "Klarte ikkje lagre butikk."
  /// ```
  String get saveFailed => """Klarte ikkje lagre butikk.""";

  /// ```dart
  /// "Klarte ikkje slette butikk."
  /// ```
  String get deleteFailed => """Klarte ikkje slette butikk.""";

  /// ```dart
  /// "Slett butikk?"
  /// ```
  String get deleteConfirm => """Slett butikk?""";

  /// ```dart
  /// "Butikken vil bli fjerna frå alle oppføringar. Dette kan ikkje angrast."
  /// ```
  String get deleteConfirmBody =>
      """Butikken vil bli fjerna frå alle oppføringar. Dette kan ikkje angrast.""";

  /// ```dart
  /// "Merke/kjede"
  /// ```
  String get brand => """Merke/kjede""";

  /// ```dart
  /// "t.d. Meny, IKEA"
  /// ```
  String get brandHint => """t.d. Meny, IKEA""";

  /// ```dart
  /// "Stad"
  /// ```
  String get location => """Stad""";

  /// ```dart
  /// "t.d. Karl Johans gate 22"
  /// ```
  String get locationHint => """t.d. Karl Johans gate 22""";

  /// ```dart
  /// "Opningstider"
  /// ```
  String get openingHours => """Opningstider""";

  /// ```dart
  /// "Legg til opningstider"
  /// ```
  String get addOpeningHours => """Legg til opningstider""";

  /// ```dart
  /// "Start"
  /// ```
  String get openingHoursStart => """Start""";

  /// ```dart
  /// "Slutt"
  /// ```
  String get openingHoursEnd => """Slutt""";

  /// ```dart
  /// "Legg til"
  /// ```
  String get openingHoursAdd => """Legg til""";

  /// ```dart
  /// "Kontakt"
  /// ```
  String get contact => """Kontakt""";

  /// ```dart
  /// "t.d. telefonnummer, nettstad, sosiale medier"
  /// ```
  String get contactHint => """t.d. telefonnummer, nettstad, sosiale medier""";

  /// ```dart
  /// "Ansvarleg"
  /// ```
  String get responsible => """Ansvarleg""";

  /// ```dart
  /// "t.d. butikksjef"
  /// ```
  String get responsibleHint => """t.d. butikksjef""";

  /// ```dart
  /// "Notat"
  /// ```
  String get notes => """Notat""";

  /// ```dart
  /// "Andre ting som er verdt å hugse"
  /// ```
  String get notesHint => """Andre ting som er verdt å hugse""";

  /// ```dart
  /// "Ingen detaljar er lagt til enno."
  /// ```
  String get noDetails => """Ingen detaljar er lagt til enno.""";

  /// ```dart
  /// "Rediger"
  /// ```
  String get editAction => """Rediger""";
  SortStoresMessagesNn get sort => SortStoresMessagesNn(this);
}

class SortStoresMessagesNn extends SortStoresMessages {
  final StoresMessagesNn _parent;
  const SortStoresMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Namn A–Å"
  /// ```
  String get nameAZ => """Namn A–Å""";

  /// ```dart
  /// "Namn Å–A"
  /// ```
  String get nameZA => """Namn Å–A""";

  /// ```dart
  /// "Tilpassa"
  /// ```
  String get custom => """Tilpassa""";
}

class ChecklistsMessagesNn extends ChecklistsMessages {
  final MessagesNn _parent;
  const ChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Kategoriar"
  /// ```
  String get categories => """Kategoriar""";

  /// ```dart
  /// "Ingen sjekklister enno."
  /// ```
  String get noChecklists => """Ingen sjekklister enno.""";

  /// ```dart
  /// "Ingen oppføringar i denne lista."
  /// ```
  String get noItems => """Ingen oppføringar i denne lista.""";

  /// ```dart
  /// "Ingen oppføringar samsvarer med søket."
  /// ```
  String get noSearchResults => """Ingen oppføringar samsvarer med søket.""";

  /// ```dart
  /// "Skriv for å filtrere…"
  /// ```
  String get searchHint => """Skriv for å filtrere…""";
  BarcodeChecklistsMessagesNn get barcode => BarcodeChecklistsMessagesNn(this);

  /// ```dart
  /// "Alle"
  /// ```
  String get allCategories => """Alle""";

  /// ```dart
  /// "Alle"
  /// ```
  String get allListsChip => """Alle""";

  /// ```dart
  /// "Filter etter liste"
  /// ```
  String get filterByList => """Filter etter liste""";

  /// ```dart
  /// "Filter etter kategori"
  /// ```
  String get filterByCategory => """Filter etter kategori""";
  FiltersChecklistsMessagesNn get filters => FiltersChecklistsMessagesNn(this);

  /// ```dart
  /// "Kunne ikkje laste sjekklister."
  /// ```
  String get failedToLoad => """Kunne ikkje laste sjekklister.""";

  /// ```dart
  /// "Kunne ikkje laste oppføringar."
  /// ```
  String get failedToLoadItems => """Kunne ikkje laste oppføringar.""";

  /// ```dart
  /// "Fullført ($count)"
  /// ```
  String completedCount(int count) => """Fullført ($count)""";

  /// ```dart
  /// "Rediger oppføring"
  /// ```
  String get editItem => """Rediger oppføring""";

  /// ```dart
  /// "Fjern oppføring"
  /// ```
  String get removeItem => """Fjern oppføring""";

  /// ```dart
  /// "Flytt til liste"
  /// ```
  String get moveItem => """Flytt til liste""";

  /// ```dart
  /// "Klarte ikkje flytte oppføring."
  /// ```
  String get moveFailed => """Klarte ikkje flytte oppføring.""";

  /// ```dart
  /// "Kopier til liste"
  /// ```
  String get copyItem => """Kopier til liste""";

  /// ```dart
  /// "Klarte ikkje kopiere oppføring."
  /// ```
  String get copyFailed => """Klarte ikkje kopiere oppføring.""";

  /// ```dart
  /// "Oppføring kopiert"
  /// ```
  String get itemCopied => """Oppføring kopiert""";

  /// ```dart
  /// "Oppføring markert som fullført"
  /// ```
  String get itemMarkedDone => """Oppføring markert som fullført""";

  /// ```dart
  /// "Oppføring fjerna"
  /// ```
  String get itemRemoved => """Oppføring fjerna""";

  /// ```dart
  /// "Angre"
  /// ```
  String get undo => """Angre""";

  /// ```dart
  /// "Vel oppføringar"
  /// ```
  String get selectItems => """Vel oppføringar""";
  BatchChecklistsMessagesNn get batch => BatchChecklistsMessagesNn(this);

  /// ```dart
  /// "Sjå papirkorga"
  /// ```
  String get viewTrash => """Sjå papirkorga""";

  /// ```dart
  /// "Gå ut av papirkorga"
  /// ```
  String get exitTrash => """Gå ut av papirkorga""";

  /// ```dart
  /// "Sjå kven som la til kvar oppføring"
  /// ```
  String get showAddedBy => """Sjå kven som la til kvar oppføring""";

  /// ```dart
  /// "Vis eit framgangskort på denne lista"
  /// ```
  String get showProgressHero => """Vis eit framgangskort på denne lista""";

  /// ```dart
  /// "Lagt til av $name"
  /// ```
  String addedBy(String name) => """Lagt til av $name""";

  /// ```dart
  /// "Papirkorg"
  /// ```
  String get trashTitle => """Papirkorg""";

  /// ```dart
  /// "Papirkorga er tom."
  /// ```
  String get noTrashedItems => """Papirkorga er tom.""";

  /// ```dart
  /// "Tøm papirkorga"
  /// ```
  String get emptyTrash => """Tøm papirkorga""";

  /// ```dart
  /// "Tøm papirkorga?"
  /// ```
  String get emptyTrashConfirm => """Tøm papirkorga?""";

  /// ```dart
  /// "Alle oppføringar i papirkorga vil bli sletta permanent. Dette kan ikkje angrast."
  /// ```
  String get emptyTrashConfirmBody =>
      """Alle oppføringar i papirkorga vil bli sletta permanent. Dette kan ikkje angrast.""";

  /// ```dart
  /// "Klarte ikkje tømme papirkorga."
  /// ```
  String get emptyTrashFailed => """Klarte ikkje tømme papirkorga.""";

  /// ```dart
  /// "Gjenopprett"
  /// ```
  String get restoreItem => """Gjenopprett""";

  /// ```dart
  /// "Slett"
  /// ```
  String get permanentlyDeleteItem => """Slett""";

  /// ```dart
  /// "Slett denne oppføringa permanent?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """Slett denne oppføringa permanent?""";

  /// ```dart
  /// "Dette kan ikkje angrast."
  /// ```
  String get permanentlyDeleteConfirmBody => """Dette kan ikkje angrast.""";

  /// ```dart
  /// "Kunne ikkje gjenopprette oppføring."
  /// ```
  String get restoreFailed => """Kunne ikkje gjenopprette oppføring.""";

  /// ```dart
  /// "Klarte ikkje slette oppføring."
  /// ```
  String get permanentlyDeleteFailed => """Klarte ikkje slette oppføring.""";

  /// ```dart
  /// "Oppføring gjenoppretta"
  /// ```
  String get itemRestored => """Oppføring gjenoppretta""";

  /// ```dart
  /// "Vis arkiv"
  /// ```
  String get viewArchive => """Vis arkiv""";

  /// ```dart
  /// "Gå ut av arkiv"
  /// ```
  String get exitArchive => """Gå ut av arkiv""";

  /// ```dart
  /// "Arkiver"
  /// ```
  String get archiveTitle => """Arkiver""";

  /// ```dart
  /// "Ingen kategori"
  /// ```
  String get noCategory => """Ingen kategori""";

  /// ```dart
  /// "Ingen butikk"
  /// ```
  String get noStore => """Ingen butikk""";

  /// ```dart
  /// "Arkivet er tomt."
  /// ```
  String get noArchivedItems => """Arkivet er tomt.""";

  /// ```dart
  /// "Arkiver"
  /// ```
  String get archiveItem => """Arkiver""";

  /// ```dart
  /// "Angre arkivering"
  /// ```
  String get unarchiveItem => """Angre arkivering""";

  /// ```dart
  /// "Klarte ikkje arkivere oppføring"
  /// ```
  String get archiveFailed => """Klarte ikkje arkivere oppføring""";

  /// ```dart
  /// "Kunne ikkje flytte oppføringa ut av arkivet."
  /// ```
  String get unarchiveFailed =>
      """Kunne ikkje flytte oppføringa ut av arkivet.""";

  /// ```dart
  /// "Oppføring arkivert"
  /// ```
  String get itemArchived => """Oppføring arkivert""";

  /// ```dart
  /// "Oppføring flytta frå arkivet"
  /// ```
  String get itemUnarchived => """Oppføring flytta frå arkivet""";

  /// ```dart
  /// "Kunne ikkje laste arkivet."
  /// ```
  String get failedToLoadArchive => """Kunne ikkje laste arkivet.""";

  /// ```dart
  /// "Sletta lister"
  /// ```
  String get viewListsTrash => """Sletta lister""";

  /// ```dart
  /// "Sletta lister"
  /// ```
  String get listsTrashTitle => """Sletta lister""";

  /// ```dart
  /// "Klarte ikkje laste papirkorga."
  /// ```
  String get failedToLoadTrash => """Klarte ikkje laste papirkorga.""";

  /// ```dart
  /// "Ingen sletta lister"
  /// ```
  String get listTrashEmpty => """Ingen sletta lister""";

  /// ```dart
  /// "Fest liste"
  /// ```
  String get pinList => """Fest liste""";

  /// ```dart
  /// "Fjern festing av liste"
  /// ```
  String get unpinList => """Fjern festing av liste""";

  /// ```dart
  /// "Fjern liste"
  /// ```
  String get removeList => """Fjern liste""";

  /// ```dart
  /// "Rediger liste"
  /// ```
  String get editList => """Rediger liste""";

  /// ```dart
  /// "Rediger liste"
  /// ```
  String get editListTitle => """Rediger liste""";

  /// ```dart
  /// "Lagre endringar"
  /// ```
  String get saveListButton => """Lagre endringar""";

  /// ```dart
  /// "Kunne ikkje oppdatere liste."
  /// ```
  String get updateListFailed => """Kunne ikkje oppdatere liste.""";

  /// ```dart
  /// "Fjern liste?"
  /// ```
  String get removeListConfirm => """Fjern liste?""";

  /// ```dart
  /// "Fjern lista «$name»? Du kan gjenopprette den frå papirkorga."
  /// ```
  String removeListConfirmBody(String name) =>
      """Fjern lista «$name»? Du kan gjenopprette den frå papirkorga.""";

  /// ```dart
  /// "Kunne ikkje fjerne liste."
  /// ```
  String get removeListFailed => """Kunne ikkje fjerne liste.""";

  /// ```dart
  /// "Gjenopprett liste"
  /// ```
  String get restoreList => """Gjenopprett liste""";

  /// ```dart
  /// "Slett permanent"
  /// ```
  String get permanentlyDeleteList => """Slett permanent""";

  /// ```dart
  /// "Liste fjerna"
  /// ```
  String get listRemoved => """Liste fjerna""";

  /// ```dart
  /// "Ny liste"
  /// ```
  String get createList => """Ny liste""";

  /// ```dart
  /// "Listenamn"
  /// ```
  String get listName => """Listenamn""";

  /// ```dart
  /// "Skildring (valfritt)"
  /// ```
  String get listDescription => """Skildring (valfritt)""";

  /// ```dart
  /// "Ikon"
  /// ```
  String get listIcon => """Ikon""";

  /// ```dart
  /// "Kunne ikkje opprette liste."
  /// ```
  String get createListFailed => """Kunne ikkje opprette liste.""";
  ViewItemChecklistsMessagesNn get viewItem =>
      ViewItemChecklistsMessagesNn(this);
  ItemFormChecklistsMessagesNn get itemForm =>
      ItemFormChecklistsMessagesNn(this);
  SortChecklistsMessagesNn get sort => SortChecklistsMessagesNn(this);

  /// ```dart
  /// "${_plural(count, one: '1 oppføring igjen', many: '$count oppføringar igjen')}"
  /// ```
  String itemsLeft(int count) =>
      """${_plural(count, one: '1 oppføring igjen', many: '$count oppføringar igjen')}""";

  /// ```dart
  /// "Ferdig 🎉"
  /// ```
  String get allDone => """Ferdig 🎉""";

  /// ```dart
  /// "$done av $total fullført"
  /// ```
  String listProgress(int done, int total) => """$done av $total fullført""";

  /// ```dart
  /// "Sjul framgangskort"
  /// ```
  String get hideProgressHero => """Sjul framgangskort""";

  /// ```dart
  /// "Sorter"
  /// ```
  String get sortTooltip => """Sorter""";

  /// ```dart
  /// "Fullført · $count"
  /// ```
  String doneCount(int count) => """Fullført · $count""";

  /// ```dart
  /// "Legg til $name…"
  /// ```
  String addToList(String name) => """Legg til $name…""";

  /// ```dart
  /// "Legg til di fyrste oppføring…"
  /// ```
  String get addFirstItem => """Legg til di fyrste oppføring…""";

  /// ```dart
  /// "Ingenting på denne lista enno"
  /// ```
  String get noItemsTitle => """Ingenting på denne lista enno""";

  /// ```dart
  /// "Legg til di fyrste oppføring under, vel ein kategori, mengdm eller tidsplan ved å bruke brikkene."
  /// ```
  String get noItemsBody =>
      """Legg til di fyrste oppføring under, vel ein kategori, mengdm eller tidsplan ved å bruke brikkene.""";

  /// ```dart
  /// "Ingen sjekklister enno"
  /// ```
  String get noListsTitle => """Ingen sjekklister enno""";

  /// ```dart
  /// "Opprett di fyrste liste for å handtere daglegvarer, oppgåver og andre ting som hushaldninga treng å halde styr på."
  /// ```
  String get noListsBody =>
      """Opprett di fyrste liste for å handtere daglegvarer, oppgåver og andre ting som hushaldninga treng å halde styr på.""";

  /// ```dart
  /// "Opprett di fyrste liste"
  /// ```
  String get createFirstList => """Opprett di fyrste liste""";

  /// ```dart
  /// "Dine sjekklister"
  /// ```
  String get yourChecklists => """Dine sjekklister""";

  /// ```dart
  /// "${_plural(count, one: '1 liste', many: '$count lister')}"
  /// ```
  String listsCount(int count) =>
      """${_plural(count, one: '1 liste', many: '$count lister')}""";

  /// ```dart
  /// "${_plural(count, one: '1 oppføring', many: '$count oppføringar')}"
  /// ```
  String itemsSummary(int count) =>
      """${_plural(count, one: '1 oppføring', many: '$count oppføringar')}""";

  /// ```dart
  /// "Ferdig · 0 igjen"
  /// ```
  String get allDoneSummary => """Ferdig · 0 igjen""";

  /// ```dart
  /// "Ny sjekkliste"
  /// ```
  String get newChecklist => """Ny sjekkliste""";

  /// ```dart
  /// "Opprett liste"
  /// ```
  String get createListButton => """Opprett liste""";

  /// ```dart
  /// "Vis"
  /// ```
  String get view => """Vis""";

  /// ```dart
  /// "Vis"
  /// ```
  String get swipeView => """Vis""";

  /// ```dart
  /// "Rediger"
  /// ```
  String get swipeEdit => """Rediger""";

  /// ```dart
  /// "Flytt"
  /// ```
  String get swipeMove => """Flytt""";

  /// ```dart
  /// "Kopier"
  /// ```
  String get swipeCopy => """Kopier""";

  /// ```dart
  /// "Fjern"
  /// ```
  String get swipeDelete => """Fjern""";

  /// ```dart
  /// "Arkiver"
  /// ```
  String get swipeArchive => """Arkiver""";

  /// ```dart
  /// "Fleire handlingar"
  /// ```
  String get moreActions => """Fleire handlingar""";

  /// ```dart
  /// "Listevisning"
  /// ```
  String get viewList => """Listevisning""";

  /// ```dart
  /// "Kortvisning"
  /// ```
  String get viewCards => """Kortvisning""";

  /// ```dart
  /// "Farge"
  /// ```
  String get listColor => """Farge""";
  ItemTypesChecklistsMessagesNn get itemTypes =>
      ItemTypesChecklistsMessagesNn(this);
  ComposeChecklistsMessagesNn get compose => ComposeChecklistsMessagesNn(this);
  PriceChecklistsMessagesNn get price => PriceChecklistsMessagesNn(this);
  ReuseChecklistsMessagesNn get reuse => ReuseChecklistsMessagesNn(this);

  /// ```dart
  /// "Alle lister"
  /// ```
  String get allLists => """Alle lister""";

  /// ```dart
  /// "Oppføringar frå alle lister"
  /// ```
  String get allListsSubtitle => """Oppføringar frå alle lister""";

  /// ```dart
  /// "Lag oppføring…"
  /// ```
  String get addToAnyList => """Lag oppføring…""";

  /// ```dart
  /// "Kva liste vil du leggje den til?"
  /// ```
  String get pickListTitle => """Kva liste vil du leggje den til?""";
  MarkdownChecklistsMessagesNn get markdown =>
      MarkdownChecklistsMessagesNn(this);
}

class BarcodeChecklistsMessagesNn extends BarcodeChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const BarcodeChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Skann strekkode"
  /// ```
  String get scan => """Skann strekkode""";

  /// ```dart
  /// "Skann strekkode"
  /// ```
  String get scanTitle => """Skann strekkode""";

  /// ```dart
  /// "Rett kameraet mot ein produktstrekkode"
  /// ```
  String get scanInstructions => """Rett kameraet mot ein produktstrekkode""";

  /// ```dart
  /// "Skriv inn manuelt"
  /// ```
  String get enterManually => """Skriv inn manuelt""";

  /// ```dart
  /// "Skriv inn strekkode"
  /// ```
  String get manualTitle => """Skriv inn strekkode""";

  /// ```dart
  /// "Strekkodenummer"
  /// ```
  String get manualHint => """Strekkodenummer""";

  /// ```dart
  /// "Det ser ikkje ut som ein gyldig strekkode"
  /// ```
  String get invalidBarcode => """Det ser ikkje ut som ein gyldig strekkode""";

  /// ```dart
  /// "Fann ikkje produktinfo for den strekkoden"
  /// ```
  String get notFound => """Fann ikkje produktinfo for den strekkoden""";

  /// ```dart
  /// "Produkt levert av ${linkStart}Open Food Facts${linkEnd}, ein ekstern fellesskapsdatabase som Pantry ikkje eig eller kontrollerer."
  /// ```
  String disclaimer(String linkStart, String linkEnd) =>
      """Produkt levert av ${linkStart}Open Food Facts${linkEnd}, ein ekstern fellesskapsdatabase som Pantry ikkje eig eller kontrollerer.""";
}

class FiltersChecklistsMessagesNn extends FiltersChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const FiltersChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Lister"
  /// ```
  String get lists => """Lister""";

  /// ```dart
  /// "Kategoriar"
  /// ```
  String get categories => """Kategoriar""";

  /// ```dart
  /// "Butikkar"
  /// ```
  String get stores => """Butikkar""";

  /// ```dart
  /// "Alle lister"
  /// ```
  String get allLists => """Alle lister""";

  /// ```dart
  /// "Alle kategoriar"
  /// ```
  String get allCategories => """Alle kategoriar""";

  /// ```dart
  /// "Alle butikkar"
  /// ```
  String get allStores => """Alle butikkar""";

  /// ```dart
  /// "Ingen kategori"
  /// ```
  String get noCategory => """Ingen kategori""";

  /// ```dart
  /// "Ingen butikkar"
  /// ```
  String get noStores => """Ingen butikkar""";

  /// ```dart
  /// "Pris"
  /// ```
  String get price => """Pris""";

  /// ```dart
  /// "Kva som helst valuta"
  /// ```
  String get anyCurrency => """Kva som helst valuta""";
}

class BatchChecklistsMessagesNn extends BatchChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const BatchChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "${_plural(count, one: '1 vald', many: '$count vald')}"
  /// ```
  String selected(int count) =>
      """${_plural(count, one: '1 vald', many: '$count vald')}""";

  /// ```dart
  /// "Flytt oppføringar til"
  /// ```
  String get moveTitle => """Flytt oppføringar til""";

  /// ```dart
  /// "Kopier oppføringar til"
  /// ```
  String get copyTitle => """Kopier oppføringar til""";

  /// ```dart
  /// "Vel kategori"
  /// ```
  String get categoryTitle => """Vel kategori""";

  /// ```dart
  /// "Vel butikkar"
  /// ```
  String get storesTitle => """Vel butikkar""";

  /// ```dart
  /// "Ingen kategori"
  /// ```
  String get clearCategory => """Ingen kategori""";

  /// ```dart
  /// "Flytt"
  /// ```
  String get move => """Flytt""";

  /// ```dart
  /// "Kopier"
  /// ```
  String get copy => """Kopier""";

  /// ```dart
  /// "Kategori"
  /// ```
  String get category => """Kategori""";

  /// ```dart
  /// "Butikkar"
  /// ```
  String get stores => """Butikkar""";

  /// ```dart
  /// "Slett"
  /// ```
  String get delete => """Slett""";

  /// ```dart
  /// "Arkiver"
  /// ```
  String get archive => """Arkiver""";

  /// ```dart
  /// "Angre arkivering"
  /// ```
  String get unarchive => """Angre arkivering""";

  /// ```dart
  /// "Slett oppføringar?"
  /// ```
  String get deleteConfirmTitle => """Slett oppføringar?""";

  /// ```dart
  /// "${_plural(count, one: 'Slett 1 vald oppføring? Du kan gjenopprette det frå papirkorga.', many: 'Slett $count valde oppføringar? Du kan gjenopprette dei frå papirkorga.')}"
  /// ```
  String deleteConfirmBody(int count) =>
      """${_plural(count, one: 'Slett 1 vald oppføring? Du kan gjenopprette det frå papirkorga.', many: 'Slett $count valde oppføringar? Du kan gjenopprette dei frå papirkorga.')}""";

  /// ```dart
  /// "${_plural(count, one: 'Flytta 1 oppføring', many: 'Flytta $count oppføringar')}"
  /// ```
  String moved(int count) =>
      """${_plural(count, one: 'Flytta 1 oppføring', many: 'Flytta $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Kopiert 1 oppføring', many: 'Kopiert $count oppføringar')}"
  /// ```
  String copied(int count) =>
      """${_plural(count, one: 'Kopiert 1 oppføring', many: 'Kopiert $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Sletta 1 oppføring', many: 'Sletta $count oppføringar')}"
  /// ```
  String deleted(int count) =>
      """${_plural(count, one: 'Sletta 1 oppføring', many: 'Sletta $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Gjenoppretta 1 oppføring', many: 'Gjenoppretta $count oppføringar')}"
  /// ```
  String restored(int count) =>
      """${_plural(count, one: 'Gjenoppretta 1 oppføring', many: 'Gjenoppretta $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Arkiverte 1 oppføring', many: 'Arkiverte $count oppføringar')}"
  /// ```
  String archived(int count) =>
      """${_plural(count, one: 'Arkiverte 1 oppføring', many: 'Arkiverte $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Flytta 1 oppføring frå arkivet', many: 'Flytta $count oppføringar frå arkivet')}"
  /// ```
  String unarchived(int count) =>
      """${_plural(count, one: 'Flytta 1 oppføring frå arkivet', many: 'Flytta $count oppføringar frå arkivet')}""";

  /// ```dart
  /// "${_plural(count, one: 'Oppdaterte 1 oppføring', many: 'Oppdaterte $count oppføringar')}"
  /// ```
  String categorySet(int count) =>
      """${_plural(count, one: 'Oppdaterte 1 oppføring', many: 'Oppdaterte $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Oppdaterte 1 oppføring', many: 'Oppdaterte $count oppføringar')}"
  /// ```
  String storesSet(int count) =>
      """${_plural(count, one: 'Oppdaterte 1 oppføring', many: 'Oppdaterte $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Hoppa over 1', many: 'Hoppa over $count')}"
  /// ```
  String skipped(int count) =>
      """${_plural(count, one: 'Hoppa over 1', many: 'Hoppa over $count')}""";

  /// ```dart
  /// "Noko er feil. Prøv igjen."
  /// ```
  String get failed => """Noko er feil. Prøv igjen.""";
}

class ViewItemChecklistsMessagesNn extends ViewItemChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const ViewItemChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Mengd:"
  /// ```
  String get quantity => """Mengd:""";

  /// ```dart
  /// "Kategori:"
  /// ```
  String get category => """Kategori:""";

  /// ```dart
  /// "Tidsplan:"
  /// ```
  String get recurrence => """Tidsplan:""";

  /// ```dart
  /// "Neste gjentaking:"
  /// ```
  String get nextDue => """Neste gjentaking:""";

  /// ```dart
  /// "Neste gjentaking (frå sist fullført):"
  /// ```
  String get nextDueFromCompletion =>
      """Neste gjentaking (frå sist fullført):""";

  /// ```dart
  /// "Forfalt"
  /// ```
  String get overdue => """Forfalt""";

  /// ```dart
  /// "Tal"
  /// ```
  String get quantityLabel => """Tal""";

  /// ```dart
  /// "Type"
  /// ```
  String get typeLabel => """Type""";

  /// ```dart
  /// "Pris"
  /// ```
  String get priceLabel => """Pris""";

  /// ```dart
  /// "Skildring"
  /// ```
  String get descriptionLabel => """Skildring""";

  /// ```dart
  /// "Inga skildring lagt til."
  /// ```
  String get noDescription => """Inga skildring lagt til.""";

  /// ```dart
  /// "Lagt til av $name · $time"
  /// ```
  String addedByMeta(String name, String time) =>
      """Lagt til av $name · $time""";

  /// ```dart
  /// "Lagt til av deg · $time"
  /// ```
  String addedByYouMeta(String time) => """Lagt til av deg · $time""";

  /// ```dart
  /// "Lagt til $time"
  /// ```
  String addedMeta(String time) => """Lagt til $time""";

  /// ```dart
  /// "nett no"
  /// ```
  String get relJustNow => """nett no""";

  /// ```dart
  /// "i dag"
  /// ```
  String get relToday => """i dag""";

  /// ```dart
  /// "i går"
  /// ```
  String get relYesterday => """i går""";

  /// ```dart
  /// "$n dagar sidan"
  /// ```
  String relDaysAgo(int n) => """$n dagar sidan""";

  /// ```dart
  /// "${_plural(n, one: '1 veke sidan', many: '$n veker sidan')}"
  /// ```
  String relWeeksAgo(int n) =>
      """${_plural(n, one: '1 veke sidan', many: '$n veker sidan')}""";

  /// ```dart
  /// "${_plural(n, one: '1 månad sidan', many: '$n månadar sidan')}"
  /// ```
  String relMonthsAgo(int n) =>
      """${_plural(n, one: '1 månad sidan', many: '$n månadar sidan')}""";

  /// ```dart
  /// "${_plural(n, one: '1 år sidan', many: '$n år sidan')}"
  /// ```
  String relYearsAgo(int n) =>
      """${_plural(n, one: '1 år sidan', many: '$n år sidan')}""";
}

class ItemFormChecklistsMessagesNn extends ItemFormChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const ItemFormChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Legg til oppføring"
  /// ```
  String get addTitle => """Legg til oppføring""";

  /// ```dart
  /// "Rediger oppføring"
  /// ```
  String get editTitle => """Rediger oppføring""";

  /// ```dart
  /// "Namn"
  /// ```
  String get name => """Namn""";

  /// ```dart
  /// "Skildring"
  /// ```
  String get description => """Skildring""";

  /// ```dart
  /// "Tal"
  /// ```
  String get quantity => """Tal""";

  /// ```dart
  /// "Kategori"
  /// ```
  String get category => """Kategori""";

  /// ```dart
  /// "Ingen"
  /// ```
  String get noCategory => """Ingen""";

  /// ```dart
  /// "Ingen kategoriar tilgjengeleg."
  /// ```
  String get noCategories => """Ingen kategoriar tilgjengeleg.""";

  /// ```dart
  /// "Ny kategori"
  /// ```
  String get createCategory => """Ny kategori""";

  /// ```dart
  /// "Namn"
  /// ```
  String get categoryName => """Namn""";

  /// ```dart
  /// "Ikon"
  /// ```
  String get categoryIcon => """Ikon""";

  /// ```dart
  /// "Farge"
  /// ```
  String get categoryColor => """Farge""";

  /// ```dart
  /// "Kategori oppretta."
  /// ```
  String get categoryCreated => """Kategori oppretta.""";

  /// ```dart
  /// "Klarte ikkje opprette kategori."
  /// ```
  String get categoryCreateFailed => """Klarte ikkje opprette kategori.""";

  /// ```dart
  /// "Butikkar"
  /// ```
  String get stores => """Butikkar""";

  /// ```dart
  /// "Ingen"
  /// ```
  String get noStores => """Ingen""";

  /// ```dart
  /// "Ny butikk"
  /// ```
  String get createStore => """Ny butikk""";

  /// ```dart
  /// "Endre"
  /// ```
  String get storesChange => """Endre""";

  /// ```dart
  /// "Vel nokre"
  /// ```
  String get storesPick => """Vel nokre""";

  /// ```dart
  /// "Gjentek"
  /// ```
  String get repeat => """Gjentek""";

  /// ```dart
  /// "Ein gang"
  /// ```
  String get once => """Ein gang""";

  /// ```dart
  /// "Slett denne oppføringa når den er markert som fullført."
  /// ```
  String get onceDescription =>
      """Slett denne oppføringa når den er markert som fullført.""";

  /// ```dart
  /// "Bilete"
  /// ```
  String get image => """Bilete""";

  /// ```dart
  /// "Legg til bilete"
  /// ```
  String get addImage => """Legg til bilete""";

  /// ```dart
  /// "Ta bilete"
  /// ```
  String get takePhoto => """Ta bilete""";

  /// ```dart
  /// "Vel bilete"
  /// ```
  String get chooseImage => """Vel bilete""";

  /// ```dart
  /// "Erstatt"
  /// ```
  String get replaceImage => """Erstatt""";

  /// ```dart
  /// "Fjern"
  /// ```
  String get removeImage => """Fjern""";

  /// ```dart
  /// "Klarte ikkje slette oppføring."
  /// ```
  String get saveFailed => """Klarte ikkje slette oppføring.""";

  /// ```dart
  /// "Klarte ikkje slette oppføring."
  /// ```
  String get deleteFailed => """Klarte ikkje slette oppføring.""";

  /// ```dart
  /// "Slett denne oppføringa?"
  /// ```
  String get deleteConfirm => """Slett denne oppføringa?""";

  /// ```dart
  /// "Lagre endringar"
  /// ```
  String get save => """Lagre endringar""";

  /// ```dart
  /// "Legg til ei skildring (valfritt)"
  /// ```
  String get descHint => """Legg til ei skildring (valfritt)""";

  /// ```dart
  /// "Endre"
  /// ```
  String get categoryChange => """Endre""";

  /// ```dart
  /// "Vel ein"
  /// ```
  String get categoryPick => """Vel ein""";

  /// ```dart
  /// "Oppføring utan namn"
  /// ```
  String get untitledItem => """Oppføring utan namn""";

  /// ```dart
  /// "Fest oppføring"
  /// ```
  String get typeStaple => """Fest oppføring""";

  /// ```dart
  /// "Ein gang"
  /// ```
  String get typeOnce => """Ein gang""";

  /// ```dart
  /// "Gjentek"
  /// ```
  String get typeRecurring => """Gjentek""";
}

class SortChecklistsMessagesNn extends SortChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const SortChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Nyaste fyrst"
  /// ```
  String get newestFirst => """Nyaste fyrst""";

  /// ```dart
  /// "Eldste fyrst"
  /// ```
  String get oldestFirst => """Eldste fyrst""";

  /// ```dart
  /// "Namn A-Z"
  /// ```
  String get nameAZ => """Namn A-Z""";

  /// ```dart
  /// "Namn Z-A"
  /// ```
  String get nameZA => """Namn Z-A""";

  /// ```dart
  /// "Etter kategori"
  /// ```
  String get category => """Etter kategori""";

  /// ```dart
  /// "Etter butikk"
  /// ```
  String get store => """Etter butikk""";

  /// ```dart
  /// "Sjølvvald"
  /// ```
  String get custom => """Sjølvvald""";
}

class ItemTypesChecklistsMessagesNn extends ItemTypesChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const ItemTypesChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Type"
  /// ```
  String get label => """Type""";

  /// ```dart
  /// "Fest"
  /// ```
  String get staple => """Fest""";

  /// ```dart
  /// "Blir verande på lista etter at du har markert den som fullført"
  /// ```
  String get stapleBody =>
      """Blir verande på lista etter at du har markert den som fullført""";

  /// ```dart
  /// "Eingongsbruk"
  /// ```
  String get onceTime => """Eingongsbruk""";

  /// ```dart
  /// "Fjerna når du fullførar den."
  /// ```
  String get onceTimeBody => """Fjerna når du fullførar den.""";

  /// ```dart
  /// "Gjentek"
  /// ```
  String get recurring => """Gjentek""";

  /// ```dart
  /// "Kjem tilbake basert på ein tidsplan"
  /// ```
  String get recurringBody => """Kjem tilbake basert på ein tidsplan""";

  /// ```dart
  /// "Kvar veke"
  /// ```
  String get weekly => """Kvar veke""";

  /// ```dart
  /// "Kvar $n veke"
  /// ```
  String everyNWeeks(int n) => """Kvar $n veke""";
}

class ComposeChecklistsMessagesNn extends ComposeChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const ComposeChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Kategori"
  /// ```
  String get chipCategory => """Kategori""";

  /// ```dart
  /// "Butikkar"
  /// ```
  String get chipStore => """Butikkar""";

  /// ```dart
  /// "Tal"
  /// ```
  String get chipQuantity => """Tal""";

  /// ```dart
  /// "Type"
  /// ```
  String get chipType => """Type""";

  /// ```dart
  /// "Bilete"
  /// ```
  String get chipImage => """Bilete""";

  /// ```dart
  /// "Skildring"
  /// ```
  String get chipDescription => """Skildring""";

  /// ```dart
  /// "Notat, instruksjonar, lenkjer…"
  /// ```
  String get descHint => """Notat, instruksjonar, lenkjer…""";

  /// ```dart
  /// "t.d. 2 l, 500 g"
  /// ```
  String get qtyHint => """t.d. 2 l, 500 g""";

  /// ```dart
  /// "＋ / − endre mengden og behald eininga."
  /// ```
  String get qtyStepperHelp => """＋ / − endre mengden og behald eininga.""";

  /// ```dart
  /// "Ingen"
  /// ```
  String get none => """Ingen""";

  /// ```dart
  /// "Kvar"
  /// ```
  String get every => """Kvar""";

  /// ```dart
  /// "veke"
  /// ```
  String get week => """veke""";

  /// ```dart
  /// "veker"
  /// ```
  String get weeks => """veker""";

  /// ```dart
  /// "Liste"
  /// ```
  String get chipTargetList => """Liste""";

  /// ```dart
  /// "Vel ei liste"
  /// ```
  String get pickTargetList => """Vel ei liste""";

  /// ```dart
  /// "Fleire"
  /// ```
  String get multiple => """Fleire""";

  /// ```dart
  /// "Skil ulike oppføringar ved å lage ei ny linje"
  /// ```
  String get multipleHint =>
      """Skil ulike oppføringar ved å lage ei ny linje""";
}

class PriceChecklistsMessagesNn extends PriceChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const PriceChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Pris"
  /// ```
  String get label => """Pris""";

  /// ```dart
  /// "Fast"
  /// ```
  String get set => """Fast""";

  /// ```dart
  /// "Område"
  /// ```
  String get range => """Område""";

  /// ```dart
  /// "Beløp"
  /// ```
  String get amount => """Beløp""";

  /// ```dart
  /// "Min"
  /// ```
  String get min => """Min""";

  /// ```dart
  /// "Maks"
  /// ```
  String get max => """Maks""";

  /// ```dart
  /// "Valuta"
  /// ```
  String get currency => """Valuta""";

  /// ```dart
  /// "Fjern pris"
  /// ```
  String get clear => """Fjern pris""";
}

class ReuseChecklistsMessagesNn extends ReuseChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const ReuseChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Oppføringa finst allereie"
  /// ```
  String get dialogTitle => """Oppføringa finst allereie""";

  /// ```dart
  /// "Ein oppføring som heiter «$name» finst allereie på denne lista. Vil du bruke denne på nytt i staden for å opprette ein ny?"
  /// ```
  String dialogBody(String name) =>
      """Ein oppføring som heiter «$name» finst allereie på denne lista. Vil du bruke denne på nytt i staden for å opprette ein ny?""";

  /// ```dart
  /// "Gjenbruk"
  /// ```
  String get reuseExisting => """Gjenbruk""";

  /// ```dart
  /// "Legg til likevel"
  /// ```
  String get addAnyway => """Legg til likevel""";

  /// ```dart
  /// "Brukar eksisterande oppføring «$name» på nytt"
  /// ```
  String reusedSnack(String name) =>
      """Brukar eksisterande oppføring «$name» på nytt""";

  /// ```dart
  /// "Allereie i denne lista"
  /// ```
  String get suggestionsHeader => """Allereie i denne lista""";
}

class MarkdownChecklistsMessagesNn extends MarkdownChecklistsMessages {
  final ChecklistsMessagesNn _parent;
  const MarkdownChecklistsMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Eksportert $date"
  /// ```
  String exported(String date) => """Eksportert $date""";

  /// ```dart
  /// "Ukategorisert"
  /// ```
  String get uncategorized => """Ukategorisert""";

  /// ```dart
  /// "Eksporter til markdown"
  /// ```
  String get exportTitle => """Eksporter til markdown""";

  /// ```dart
  /// "Importer frå markdown"
  /// ```
  String get importTitle => """Importer frå markdown""";

  /// ```dart
  /// "Inkluder fullførte oppføringar"
  /// ```
  String get includeCompleted => """Inkluder fullførte oppføringar""";

  /// ```dart
  /// "Rediger teksten under for å endre den eksporterte lista"
  /// ```
  String get editHint =>
      """Rediger teksten under for å endre den eksporterte lista""";

  /// ```dart
  /// "Kopier"
  /// ```
  String get copy => """Kopier""";

  /// ```dart
  /// "Last ned .md"
  /// ```
  String get download => """Last ned .md""";

  /// ```dart
  /// "Kopiert til utklippstavla"
  /// ```
  String get copied => """Kopiert til utklippstavla""";

  /// ```dart
  /// "Kunne ikkje kopiere til utklippstavla"
  /// ```
  String get copyFailed => """Kunne ikkje kopiere til utklippstavla""";

  /// ```dart
  /// "Lukk"
  /// ```
  String get close => """Lukk""";

  /// ```dart
  /// "Kunne ikkje eksportere fila"
  /// ```
  String get shareFailed => """Kunne ikkje eksportere fila""";

  /// ```dart
  /// "Last opp ei .md-fil"
  /// ```
  String get uploadFile => """Last opp ei .md-fil""";

  /// ```dart
  /// "Lim inn markdown"
  /// ```
  String get pasteLabel => """Lim inn markdown""";

  /// ```dart
  /// "Lim inn ei Markdown-liste her."
  /// ```
  String get pastePlaceholder => """Lim inn ei Markdown-liste her.""";

  /// ```dart
  /// "Fann ingen listeoppføringar i teksten."
  /// ```
  String get noneFound => """Fann ingen listeoppføringar i teksten.""";

  /// ```dart
  /// "Merk alt"
  /// ```
  String get selectAll => """Merk alt""";

  /// ```dart
  /// "Fjern markeringa av alt"
  /// ```
  String get deselectAll => """Fjern markeringa av alt""";

  /// ```dart
  /// "Bruk eksisterande oppføringar i staden for å opprette duplikatar"
  /// ```
  String get reuseExisting =>
      """Bruk eksisterande oppføringar i staden for å opprette duplikatar""";

  /// ```dart
  /// "Standardinnstillingar som blir brukt på kvar oppføring"
  /// ```
  String get defaultFields =>
      """Standardinnstillingar som blir brukt på kvar oppføring""";

  /// ```dart
  /// "${_plural(count, one: 'fant 1 oppføring ', many: 'fant $count oppføringar')}"
  /// ```
  String itemsFound(int count) =>
      """${_plural(count, one: 'fant 1 oppføring ', many: 'fant $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Legg til 1 oppføring', many: 'Legg til $count oppføringar')}"
  /// ```
  String addItems(int count) =>
      """${_plural(count, one: 'Legg til 1 oppføring', many: 'Legg til $count oppføringar')}""";

  /// ```dart
  /// "${_plural(count, one: 'Importert 1 oppføring', many: 'Importert $count oppføringar')}"
  /// ```
  String imported(int count) =>
      """${_plural(count, one: 'Importert 1 oppføring', many: 'Importert $count oppføringar')}""";
}

class NotesWallMessagesNn extends NotesWallMessages {
  final MessagesNn _parent;
  const NotesWallMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Ingen notat enno"
  /// ```
  String get noNotes => """Ingen notat enno""";

  /// ```dart
  /// "Klarte ikkje laste notat"
  /// ```
  String get failedToLoad => """Klarte ikkje laste notat""";

  /// ```dart
  /// "Klarte ikkje lagre notat."
  /// ```
  String get saveFailed => """Klarte ikkje lagre notat.""";

  /// ```dart
  /// "Klarte ikkje slette notatet."
  /// ```
  String get deleteFailed => """Klarte ikkje slette notatet.""";

  /// ```dart
  /// "Slett dette notatet?"
  /// ```
  String get deleteConfirm => """Slett dette notatet?""";

  /// ```dart
  /// "Slett ${_plural(count, one: 'dette notatet', many: '$count notat')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """Slett ${_plural(count, one: 'dette notatet', many: '$count notat')}?""";

  /// ```dart
  /// "${_plural(count, one: 'Notat sletta', many: '$count notat sletta')}"
  /// ```
  String noteRemoved(int count) =>
      """${_plural(count, one: 'Notat sletta', many: '$count notat sletta')}""";

  /// ```dart
  /// "Vis papirkorga"
  /// ```
  String get viewTrash => """Vis papirkorga""";

  /// ```dart
  /// "Gå ut av papirkorga"
  /// ```
  String get exitTrash => """Gå ut av papirkorga""";

  /// ```dart
  /// "Papirkorg"
  /// ```
  String get trashTitle => """Papirkorg""";

  /// ```dart
  /// "Papirkorga er tom."
  /// ```
  String get trashEmpty => """Papirkorga er tom.""";

  /// ```dart
  /// "Tøm papirkorga"
  /// ```
  String get emptyTrash => """Tøm papirkorga""";

  /// ```dart
  /// "Tøm papirkorga?"
  /// ```
  String get emptyTrashConfirm => """Tøm papirkorga?""";

  /// ```dart
  /// "Alle notata i papirkorga vil bli sletta permanent. Dette kan ikkje angrast."
  /// ```
  String get emptyTrashConfirmBody =>
      """Alle notata i papirkorga vil bli sletta permanent. Dette kan ikkje angrast.""";

  /// ```dart
  /// "Klarte ikkje tømme papirkorga."
  /// ```
  String get emptyTrashFailed => """Klarte ikkje tømme papirkorga.""";

  /// ```dart
  /// "Klarte ikkje laste papirkorga."
  /// ```
  String get failedToLoadTrash => """Klarte ikkje laste papirkorga.""";

  /// ```dart
  /// "Gjenopprett"
  /// ```
  String get restore => """Gjenopprett""";

  /// ```dart
  /// "Klarte ikkje gjenopprette notat."
  /// ```
  String get restoreFailed => """Klarte ikkje gjenopprette notat.""";

  /// ```dart
  /// "Slett permanent"
  /// ```
  String get permanentlyDelete => """Slett permanent""";

  /// ```dart
  /// "Slett dette notatet permanent?"
  /// ```
  String get permanentlyDeleteConfirm => """Slett dette notatet permanent?""";

  /// ```dart
  /// "Dette kan ikkje angrast."
  /// ```
  String get permanentlyDeleteConfirmBody => """Dette kan ikkje angrast.""";

  /// ```dart
  /// "Nytt notat"
  /// ```
  String get newNote => """Nytt notat""";

  /// ```dart
  /// "Rediger notat"
  /// ```
  String get editNote => """Rediger notat""";

  /// ```dart
  /// "Ulagra endringar"
  /// ```
  String get unsavedChanges => """Ulagra endringar""";

  /// ```dart
  /// "Du har ulagra endringar. Vil du lagre dei?"
  /// ```
  String get unsavedChangesBody =>
      """Du har ulagra endringar. Vil du lagre dei?""";

  /// ```dart
  /// "Forkast"
  /// ```
  String get discard => """Forkast""";

  /// ```dart
  /// "Fortset å redigere"
  /// ```
  String get keepEditing => """Fortset å redigere""";

  /// ```dart
  /// "Fest notat"
  /// ```
  String get pinNote => """Fest notat""";

  /// ```dart
  /// "Fjern festing av notat"
  /// ```
  String get unpinNote => """Fjern festing av notat""";

  /// ```dart
  /// "Tittel"
  /// ```
  String get title => """Tittel""";

  /// ```dart
  /// "Innhald"
  /// ```
  String get content => """Innhald""";

  /// ```dart
  /// "Farge"
  /// ```
  String get color => """Farge""";
  SortNotesWallMessagesNn get sort => SortNotesWallMessagesNn(this);
}

class SortNotesWallMessagesNn extends SortNotesWallMessages {
  final NotesWallMessagesNn _parent;
  const SortNotesWallMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Nyaste fyrst"
  /// ```
  String get newestFirst => """Nyaste fyrst""";

  /// ```dart
  /// "Eldste fyrst"
  /// ```
  String get oldestFirst => """Eldste fyrst""";

  /// ```dart
  /// "Tittel A-Z"
  /// ```
  String get titleAZ => """Tittel A-Z""";

  /// ```dart
  /// "Tittel Z-A"
  /// ```
  String get titleZA => """Tittel Z-A""";

  /// ```dart
  /// "Sjølvvald"
  /// ```
  String get custom => """Sjølvvald""";
}

class PhotoBoardMessagesNn extends PhotoBoardMessages {
  final MessagesNn _parent;
  const PhotoBoardMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Ingen bilete enno."
  /// ```
  String get noPhotos => """Ingen bilete enno.""";

  /// ```dart
  /// "Klarte ikkje laste bilete."
  /// ```
  String get failedToLoad => """Klarte ikkje laste bilete.""";

  /// ```dart
  /// "Klarte ikkje laste opp bilete."
  /// ```
  String get uploadFailed => """Klarte ikkje laste opp bilete.""";

  /// ```dart
  /// "Klarte ikkje slette bilete"
  /// ```
  String get deleteFailed => """Klarte ikkje slette bilete""";

  /// ```dart
  /// "Slett dette biletet?"
  /// ```
  String get deleteConfirm => """Slett dette biletet?""";

  /// ```dart
  /// "Slett ${_plural(count, one: 'dette bilete', many: '$count bilete')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """Slett ${_plural(count, one: 'dette bilete', many: '$count bilete')}?""";

  /// ```dart
  /// "${_plural(count, one: 'Bilete sletta', many: '$count bilete sletta')}"
  /// ```
  String photoRemoved(int count) =>
      """${_plural(count, one: 'Bilete sletta', many: '$count bilete sletta')}""";

  /// ```dart
  /// "Vis papirkorga"
  /// ```
  String get viewTrash => """Vis papirkorga""";

  /// ```dart
  /// "Gå ut av papirkorga"
  /// ```
  String get exitTrash => """Gå ut av papirkorga""";

  /// ```dart
  /// "Papirkorg"
  /// ```
  String get trashTitle => """Papirkorg""";

  /// ```dart
  /// "Papirkorga er tom."
  /// ```
  String get trashEmpty => """Papirkorga er tom.""";

  /// ```dart
  /// "Tøm papirkorga"
  /// ```
  String get emptyTrash => """Tøm papirkorga""";

  /// ```dart
  /// "Tøm papirkorga?"
  /// ```
  String get emptyTrashConfirm => """Tøm papirkorga?""";

  /// ```dart
  /// "Alle bielta i papirkorga vil bli sletta permanent. Dette kan ikkje angrast."
  /// ```
  String get emptyTrashConfirmBody =>
      """Alle bielta i papirkorga vil bli sletta permanent. Dette kan ikkje angrast.""";

  /// ```dart
  /// "Klarte ikkje tømme papirkorga."
  /// ```
  String get emptyTrashFailed => """Klarte ikkje tømme papirkorga.""";

  /// ```dart
  /// "Klarte ikkje laste papirkorga."
  /// ```
  String get failedToLoadTrash => """Klarte ikkje laste papirkorga.""";

  /// ```dart
  /// "Gjenopprett"
  /// ```
  String get restore => """Gjenopprett""";

  /// ```dart
  /// "Kunne ikkje gjenopprette bilete."
  /// ```
  String get restoreFailed => """Kunne ikkje gjenopprette bilete.""";

  /// ```dart
  /// "Slett permanent"
  /// ```
  String get permanentlyDelete => """Slett permanent""";

  /// ```dart
  /// "Slett dette biletet permanent?"
  /// ```
  String get permanentlyDeleteConfirm => """Slett dette biletet permanent?""";

  /// ```dart
  /// "Dette kan ikkje angrast."
  /// ```
  String get permanentlyDeleteConfirmBody => """Dette kan ikkje angrast.""";

  /// ```dart
  /// "Slett mappe"
  /// ```
  String get deleteFolder => """Slett mappe""";

  /// ```dart
  /// "Slett denne mappa?"
  /// ```
  String get deleteFolderConfirm => """Slett denne mappa?""";

  /// ```dart
  /// "Flytt bilete til rotmappa."
  /// ```
  String get deleteFolderKeepPhotos => """Flytt bilete til rotmappa.""";

  /// ```dart
  /// "Slett mappa og bilete"
  /// ```
  String get deleteFolderDeleteAll => """Slett mappa og bilete""";

  /// ```dart
  /// "Ny mappe"
  /// ```
  String get newFolder => """Ny mappe""";

  /// ```dart
  /// "Katalognavn"
  /// ```
  String get folderName => """Katalognavn""";

  /// ```dart
  /// "Gi nytt namn til mappe"
  /// ```
  String get renameFolder => """Gi nytt namn til mappe""";

  /// ```dart
  /// "Bilettekst"
  /// ```
  String get caption => """Bilettekst""";

  /// ```dart
  /// "$count"
  /// ```
  String photoCount(int count) => """$count""";
  AddMenuPhotoBoardMessagesNn get addMenu => AddMenuPhotoBoardMessagesNn(this);
  SortPhotoBoardMessagesNn get sort => SortPhotoBoardMessagesNn(this);
}

class AddMenuPhotoBoardMessagesNn extends AddMenuPhotoBoardMessages {
  final PhotoBoardMessagesNn _parent;
  const AddMenuPhotoBoardMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Last opp bilete"
  /// ```
  String get upload => """Last opp bilete""";

  /// ```dart
  /// "Ta bilete"
  /// ```
  String get camera => """Ta bilete""";

  /// ```dart
  /// "Ny mappe"
  /// ```
  String get newFolder => """Ny mappe""";
}

class SortPhotoBoardMessagesNn extends SortPhotoBoardMessages {
  final PhotoBoardMessagesNn _parent;
  const SortPhotoBoardMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Mapper fyrst"
  /// ```
  String get foldersFirst => """Mapper fyrst""";

  /// ```dart
  /// "Nyaste fyrst"
  /// ```
  String get newestFirst => """Nyaste fyrst""";

  /// ```dart
  /// "Eldste fyrst"
  /// ```
  String get oldestFirst => """Eldste fyrst""";

  /// ```dart
  /// "Bilettekst A-Z"
  /// ```
  String get captionAZ => """Bilettekst A-Z""";

  /// ```dart
  /// "Bilettekst Z-a"
  /// ```
  String get captionZA => """Bilettekst Z-a""";

  /// ```dart
  /// "Sjølvvald"
  /// ```
  String get custom => """Sjølvvald""";
}

class ShoppingMessagesNn extends ShoppingMessages {
  final MessagesNn _parent;
  const ShoppingMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Start handel"
  /// ```
  String get startShopping => """Start handel""";

  /// ```dart
  /// "Hald fram handelen"
  /// ```
  String get resumeShopping => """Hald fram handelen""";

  /// ```dart
  /// "Handelshistorikk"
  /// ```
  String get shoppingHistory => """Handelshistorikk""";

  /// ```dart
  /// "Hald fram"
  /// ```
  String get resume => """Hald fram""";

  /// ```dart
  /// "Handlar på ${store}"
  /// ```
  String bannerShoppingAt(String store) => """Handlar på ${store}""";

  /// ```dart
  /// "Butikk $index/$total"
  /// ```
  String bannerStoreProgress(int index, int total) =>
      """Butikk $index/$total""";

  /// ```dart
  /// "Handlar no"
  /// ```
  String get bannerShoppingNow => """Handlar no""";

  /// ```dart
  /// "Start handel"
  /// ```
  String get startTitle => """Start handel""";

  /// ```dart
  /// "Lister å handle"
  /// ```
  String get listsToShop => """Lister å handle""";

  /// ```dart
  /// "Vel alle"
  /// ```
  String get selectAll => """Vel alle""";

  /// ```dart
  /// "Vel ingen"
  /// ```
  String get selectNone => """Vel ingen""";

  /// ```dart
  /// "Ingen lister å handle enno."
  /// ```
  String get noListsToShop => """Ingen lister å handle enno.""";

  /// ```dart
  /// "Butikkar"
  /// ```
  String get storesTitle => """Butikkar""";

  /// ```dart
  /// "Slå på eller av butikkane du skal innom, og dra for å setje rekkjefølgja."
  /// ```
  String get storesHint =>
      """Slå på eller av butikkane du skal innom, og dra for å setje rekkjefølgja.""";

  /// ```dart
  /// "Ingen av dei valde listene har varer knytte til ein butikk."
  /// ```
  String get noStoresWithItems =>
      """Ingen av dei valde listene har varer knytte til ein butikk.""";

  /// ```dart
  /// "Ta med varer utan butikk"
  /// ```
  String get includeUnassigned => """Ta med varer utan butikk""";

  /// ```dart
  /// "Start"
  /// ```
  String get start => """Start""";

  /// ```dart
  /// "Klarte ikkje å starte handelen."
  /// ```
  String get startFailed => """Klarte ikkje å starte handelen.""";

  /// ```dart
  /// "Du har allereie ein handel i gang."
  /// ```
  String get tripInProgress => """Du har allereie ein handel i gang.""";

  /// ```dart
  /// "Du har ein handel i gang i ${house}."
  /// ```
  String tripInProgressElsewhere(String house) =>
      """Du har ein handel i gang i ${house}.""";

  /// ```dart
  /// "Avslutt førre handel"
  /// ```
  String get endPreviousTrip => """Avslutt førre handel""";

  /// ```dart
  /// "Klarte ikkje å avslutte førre handel."
  /// ```
  String get endPreviousFailed => """Klarte ikkje å avslutte førre handel.""";

  /// ```dart
  /// "$count i korga"
  /// ```
  String inCart(int count) => """$count i korga""";

  /// ```dart
  /// "Skjul handelen for husfellane"
  /// ```
  String get makePrivate => """Skjul handelen for husfellane""";

  /// ```dart
  /// "Vis handelen for husfellane"
  /// ```
  String get makePublic => """Vis handelen for husfellane""";

  /// ```dart
  /// "Privat"
  /// ```
  String get privateBadge => """Privat""";

  /// ```dart
  /// "Neste butikk"
  /// ```
  String get nextStore => """Neste butikk""";

  /// ```dart
  /// "Fullfør"
  /// ```
  String get finish => """Fullfør""";

  /// ```dart
  /// "Fullfør handelen"
  /// ```
  String get finishTrip => """Fullfør handelen""";

  /// ```dart
  /// "Alt kryssa av her"
  /// ```
  String get allCheckedHere => """Alt kryssa av her""";

  /// ```dart
  /// "Gå vidare til neste butikk."
  /// ```
  String get moveOnToNext => """Gå vidare til neste butikk.""";

  /// ```dart
  /// "Alt ferdig"
  /// ```
  String get allDone => """Alt ferdig""";

  /// ```dart
  /// "Alt er i korga."
  /// ```
  String get everythingInCart => """Alt er i korga.""";

  /// ```dart
  /// "Ferdig ($count)"
  /// ```
  String doneToday(int count) => """Ferdig ($count)""";

  /// ```dart
  /// "Ingenting å kjøpe her."
  /// ```
  String get nothingToBuyHere => """Ingenting å kjøpe her.""";

  /// ```dart
  /// "Klarte ikkje å oppdatere vara."
  /// ```
  String get checkFailed => """Klarte ikkje å oppdatere vara.""";

  /// ```dart
  /// "Klarte ikkje å laste varene."
  /// ```
  String get loadItemsFailed => """Klarte ikkje å laste varene.""";

  /// ```dart
  /// "Fjern frå handleturen"
  /// ```
  String get removeFromTrip => """Fjern frå handleturen""";

  /// ```dart
  /// "Fjerna frå denne handleturen"
  /// ```
  String get removedFromTrip => """Fjerna frå denne handleturen""";

  /// ```dart
  /// "Angre"
  /// ```
  String get undo => """Angre""";

  /// ```dart
  /// "Klarte ikkje å angre."
  /// ```
  String get undoRemoveFailed => """Klarte ikkje å angre.""";

  /// ```dart
  /// "Oppsummering"
  /// ```
  String get reviewTitle => """Oppsummering""";

  /// ```dart
  /// "Neste butikk"
  /// ```
  String get advanceTitle => """Neste butikk""";

  /// ```dart
  /// "Faktisk betalt"
  /// ```
  String get actualPaid => """Faktisk betalt""";

  /// ```dart
  /// "Totalsum"
  /// ```
  String get grandTotal => """Totalsum""";

  /// ```dart
  /// "${_plural(count, one: '1 vare utan pris', many: '$count varer utan pris')}"
  /// ```
  String itemsWithoutPrice(int count) =>
      """${_plural(count, one: '1 vare utan pris', many: '$count varer utan pris')}""";

  /// ```dart
  /// "${_plural(count, one: '1 vare enno ikkje kryssa av', many: '$count varer enno ikkje kryssa av')}"
  /// ```
  String itemsStillUnchecked(int count) =>
      """${_plural(count, one: '1 vare enno ikkje kryssa av', many: '$count varer enno ikkje kryssa av')}""";

  /// ```dart
  /// "Kva som helst butikk"
  /// ```
  String get anyStore => """Kva som helst butikk""";

  /// ```dart
  /// "Klarte ikkje å lagre summen."
  /// ```
  String get saveTotalFailed => """Klarte ikkje å lagre summen.""";

  /// ```dart
  /// "Påminningar"
  /// ```
  String get remindersTitle => """Påminningar""";

  /// ```dart
  /// "Handter påminningar"
  /// ```
  String get manageReminders => """Handter påminningar""";

  /// ```dart
  /// "Ved start"
  /// ```
  String get reminderGroupStart => """Ved start""";

  /// ```dart
  /// "Mellom butikkar"
  /// ```
  String get reminderGroupAdvance => """Mellom butikkar""";

  /// ```dart
  /// "Ved slutt"
  /// ```
  String get reminderGroupEnd => """Ved slutt""";

  /// ```dart
  /// "Ingen påminningar her enno."
  /// ```
  String get noRemindersHere => """Ingen påminningar her enno.""";

  /// ```dart
  /// "Ingen påminningar for dette steget enno."
  /// ```
  String get noRemindersStep => """Ingen påminningar for dette steget enno.""";

  /// ```dart
  /// "Legg til påminningar"
  /// ```
  String get addReminders => """Legg til påminningar""";

  /// ```dart
  /// "Legg til ei påminning"
  /// ```
  String get addReminderHint => """Legg til ei påminning""";

  /// ```dart
  /// "Når skal ho visast"
  /// ```
  String get reminderWhen => """Når skal ho visast""";

  /// ```dart
  /// "Ved start"
  /// ```
  String get whenOnStart => """Ved start""";

  /// ```dart
  /// "Mellom butikkar"
  /// ```
  String get whenOnStoreAdvance => """Mellom butikkar""";

  /// ```dart
  /// "Ved slutt"
  /// ```
  String get whenOnClose => """Ved slutt""";

  /// ```dart
  /// "Legg til"
  /// ```
  String get add => """Legg til""";

  /// ```dart
  /// "Klarte ikkje å lagre påminninga."
  /// ```
  String get reminderSaveFailed => """Klarte ikkje å lagre påminninga.""";

  /// ```dart
  /// "Klarte ikkje å slette påminninga."
  /// ```
  String get reminderDeleteFailed => """Klarte ikkje å slette påminninga.""";

  /// ```dart
  /// "Handelshistorikk"
  /// ```
  String get historyTitle => """Handelshistorikk""";

  /// ```dart
  /// "Mine"
  /// ```
  String get scopeMine => """Mine""";

  /// ```dart
  /// "Hus"
  /// ```
  String get scopeHouse => """Hus""";

  /// ```dart
  /// "Ingen butikk"
  /// ```
  String get noStorePath => """Ingen butikk""";

  /// ```dart
  /// "${_plural(count, one: '1 vare', many: '$count varer')}"
  /// ```
  String itemsCount(int count) =>
      """${_plural(count, one: '1 vare', many: '$count varer')}""";

  /// ```dart
  /// "Last inn meir"
  /// ```
  String get loadMore => """Last inn meir""";

  /// ```dart
  /// "Ingen handlar enno."
  /// ```
  String get noTripsYet => """Ingen handlar enno.""";

  /// ```dart
  /// "Ingen handlar i dette huset enno."
  /// ```
  String get noHouseTripsYet => """Ingen handlar i dette huset enno.""";

  /// ```dart
  /// "Klarte ikkje å laste historikken."
  /// ```
  String get loadHistoryFailed => """Klarte ikkje å laste historikken.""";

  /// ```dart
  /// "Noko gjekk gale. Prøv igjen."
  /// ```
  String get loadFailed => """Noko gjekk gale. Prøv igjen.""";

  /// ```dart
  /// "Utan kategori"
  /// ```
  String get uncategorized => """Utan kategori""";
}

class ShareMessagesNn extends ShareMessages {
  final MessagesNn _parent;
  const ShareMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Del til Pantry"
  /// ```
  String get title => """Del til Pantry""";

  /// ```dart
  /// "Vel hus"
  /// ```
  String get chooseHouse => """Vel hus""";

  /// ```dart
  /// "Last opp til"
  /// ```
  String get choosePhotoDestination => """Last opp til""";

  /// ```dart
  /// "Fotovegg"
  /// ```
  String get photoBoardRoot => """Fotovegg""";

  /// ```dart
  /// "Ny mappe"
  /// ```
  String get newFolder => """Ny mappe""";

  /// ```dart
  /// "Katalognavn"
  /// ```
  String get newFolderName => """Katalognavn""";

  /// ```dart
  /// "Klarte ikkje opprette mappe."
  /// ```
  String get failedToCreateFolder => """Klarte ikkje opprette mappe.""";

  /// ```dart
  /// "Kunne ikkje opne det delte innhaldet."
  /// ```
  String get failedToOpenShare => """Kunne ikkje opne det delte innhaldet.""";

  /// ```dart
  /// "Ingen hus tilgjengeleg. Opprett eit hus fyrst."
  /// ```
  String get noHouses => """Ingen hus tilgjengeleg. Opprett eit hus fyrst.""";
}

class RecurrenceMessagesNn extends RecurrenceMessages {
  final MessagesNn _parent;
  const RecurrenceMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Gjentaking"
  /// ```
  String get title => """Gjentaking""";

  /// ```dart
  /// "Førehandsval"
  /// ```
  String get presets => """Førehandsval""";

  /// ```dart
  /// "Kvar dag"
  /// ```
  String get daily => """Kvar dag""";

  /// ```dart
  /// "Kvar veke"
  /// ```
  String get weekly => """Kvar veke""";

  /// ```dart
  /// "Månadleg"
  /// ```
  String get monthly => """Månadleg""";

  /// ```dart
  /// "Kvar"
  /// ```
  String get everyLabel => """Kvar""";

  /// ```dart
  /// "Eining"
  /// ```
  String get unit => """Eining""";

  /// ```dart
  /// "dagar"
  /// ```
  String get unitDays => """dagar""";

  /// ```dart
  /// "veker"
  /// ```
  String get unitWeeks => """veker""";

  /// ```dart
  /// "månadar"
  /// ```
  String get unitMonths => """månadar""";

  /// ```dart
  /// "år"
  /// ```
  String get unitYears => """år""";

  /// ```dart
  /// "Gjenta på"
  /// ```
  String get repeatOn => """Gjenta på""";

  /// ```dart
  /// "Sluttar"
  /// ```
  String get ends => """Sluttar""";

  /// ```dart
  /// "Aldri"
  /// ```
  String get never => """Aldri""";

  /// ```dart
  /// "Etter"
  /// ```
  String get after => """Etter""";

  /// ```dart
  /// "gjentakingar"
  /// ```
  String get occurrences => """gjentakingar""";

  /// ```dart
  /// "På dato"
  /// ```
  String get onDate => """På dato""";

  /// ```dart
  /// "Baser intervallet på når oppføringa var markert som fullført"
  /// ```
  String get countFromCompletion =>
      """Baser intervallet på når oppføringa var markert som fullført""";

  /// ```dart
  /// "Tidsplanen er førehandsdefinert: oppføringa kjem tilbake uavhengig av når det var markert som fullført."
  /// ```
  String get countFromCompletionHintOff =>
      """Tidsplanen er førehandsdefinert: oppføringa kjem tilbake uavhengig av når det var markert som fullført.""";

  /// ```dart
  /// "Den neste gjentakinga er basert frå når du markerar oppføringa som fullført, så det kjem alltid tilbake eit fullt intervall etter att det var fullført."
  /// ```
  String get countFromCompletionHintOn =>
      """Den neste gjentakinga er basert frå når du markerar oppføringa som fullført, så det kjem alltid tilbake eit fullt intervall etter att det var fullført.""";

  /// ```dart
  /// "Oppsumering"
  /// ```
  String get summary => """Oppsumering""";

  /// ```dart
  /// "ikkje angitt"
  /// ```
  String get notSet => """ikkje angitt""";

  /// ```dart
  /// "angitt"
  /// ```
  String get set => """angitt""";

  /// ```dart
  /// "Kvar $unit"
  /// ```
  String every(String unit) => """Kvar $unit""";

  /// ```dart
  /// "Kvar $unit"
  /// ```
  String everyButton(String unit) => """Kvar $unit""";

  /// ```dart
  /// "på $days"
  /// ```
  String onDays(String days) => """på $days""";

  /// ```dart
  /// "${_plural(count, one: 'dag', many: '$count dagar')}"
  /// ```
  String day(int count) =>
      """${_plural(count, one: 'dag', many: '$count dagar')}""";

  /// ```dart
  /// "${_plural(count, one: 'veke', many: '$count veker')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'veke', many: '$count veker')}""";

  /// ```dart
  /// "${_plural(count, one: 'månad', many: '$count månadar')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'månad', many: '$count månadar')}""";

  /// ```dart
  /// "${_plural(count, one: 'år', many: '$count år')}"
  /// ```
  String year(int count) =>
      """${_plural(count, one: 'år', many: '$count år')}""";
  DayNamesRecurrenceMessagesNn get dayNames =>
      DayNamesRecurrenceMessagesNn(this);
  DayAbbrRecurrenceMessagesNn get dayAbbr => DayAbbrRecurrenceMessagesNn(this);
}

class DayNamesRecurrenceMessagesNn extends DayNamesRecurrenceMessages {
  final RecurrenceMessagesNn _parent;
  const DayNamesRecurrenceMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Måndag"
  /// ```
  String get monday => """Måndag""";

  /// ```dart
  /// "Tysdag"
  /// ```
  String get tuesday => """Tysdag""";

  /// ```dart
  /// "Onsdag"
  /// ```
  String get wednesday => """Onsdag""";

  /// ```dart
  /// "Torsdag"
  /// ```
  String get thursday => """Torsdag""";

  /// ```dart
  /// "Fredag"
  /// ```
  String get friday => """Fredag""";

  /// ```dart
  /// "Laurdag"
  /// ```
  String get saturday => """Laurdag""";

  /// ```dart
  /// "Sundag"
  /// ```
  String get sunday => """Sundag""";
}

class DayAbbrRecurrenceMessagesNn extends DayAbbrRecurrenceMessages {
  final RecurrenceMessagesNn _parent;
  const DayAbbrRecurrenceMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Må"
  /// ```
  String get mo => """Må""";

  /// ```dart
  /// "Ty"
  /// ```
  String get tu => """Ty""";

  /// ```dart
  /// "On"
  /// ```
  String get we => """On""";

  /// ```dart
  /// "To"
  /// ```
  String get th => """To""";

  /// ```dart
  /// "Fr"
  /// ```
  String get fr => """Fr""";

  /// ```dart
  /// "La"
  /// ```
  String get sa => """La""";

  /// ```dart
  /// "Su"
  /// ```
  String get su => """Su""";
}

class SyncMessagesNn extends SyncMessages {
  final MessagesNn _parent;
  const SyncMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Fråkobla"
  /// ```
  String get offline => """Fråkobla""";

  /// ```dart
  /// "Synkroniserer endringar…"
  /// ```
  String get syncing => """Synkroniserer endringar…""";

  /// ```dart
  /// "${_plural(count, one: '1 endring ventar på synkronisering', many: '${count} endringar venter på synkronisering')}"
  /// ```
  String pendingChanges(int count) =>
      """${_plural(count, one: '1 endring ventar på synkronisering', many: '${count} endringar venter på synkronisering')}""";

  /// ```dart
  /// "Kunne ikkje synkronisere endringar"
  /// ```
  String get syncError => """Kunne ikkje synkronisere endringar""";

  /// ```dart
  /// "Prøv igjen no"
  /// ```
  String get retry => """Prøv igjen no""";
}

class MarkdownEditorMessagesNn extends MarkdownEditorMessages {
  final MessagesNn _parent;
  const MarkdownEditorMessagesNn(this._parent) : super(_parent);

  /// ```dart
  /// "Markdown"
  /// ```
  String get editSource => """Markdown""";

  /// ```dart
  /// "Rik tekst"
  /// ```
  String get editRich => """Rik tekst""";
}

Map<String, String> get messagesNnMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Avbryt""",
  """common.delete""": """Slett""",
  """common.save""": """Lagre""",
  """common.retry""": """Prøv på nytt""",
  """common.refresh""": """Oppfrisk""",
  """common.logout""": """Logg ut""",
  """common.loading""": """Lastar...""",
  """common.error""": """Feil""",
  """common.copy""": """Kopier""",
  """common.copied""": """Kopiert""",
  """common.closeDialog""": """Ferdig""",
  """common.remove""": """Fjern""",
  """common.clear""": """Tøm""",
  """common.permissionDenied""": """Du har ikkje tilgang til å gjere det""",
  """common.noAccessTitle""": """Ingen tilgang""",
  """common.noAccessBody""":
      """Du har ikkje tilgang til noko i dette huset enno. Ein administrator kan gi deg tilgang gjennom Pantry-nettappen.""",
  """login.connectToNextcloud""": """Koble til Nextcloud-instansen din""",
  """login.serverUrl""": """Tenaradresse""",
  """login.serverUrlHint""": """sky.example.com""",
  """login.connect""": """Koble til""",
  """login.waitingForAuth""": """Ventar på autentisering...
Fullfør innlogginga i nettlesaren din.""",
  """login.couldNotConnect""":
      """Kunne ikkje koble til tenaren. Sjekk at adressa er korrekt.""",
  """login.loginFailed""": """Innlogginga mislukkast. Prøv igjen.""",
  """login.seeDetails""": """Sjå detaljar""",
  """login.errorDetailsTitle""": """Feildetaljar""",
  """login.untrustedCertTitle""": """Sertifikat ikkje godkjent""",
  """login.untrustedCertWarning""":
      """Berre stol på sertifikatet viss du kjennar att fingeravtrykket. Å stole på eit sertifikat frå nokon uvedkommande kan la ein angripar lese trafikken din.""",
  """login.trustCertificate""": """Stol på sertifikat""",
  """login.certFingerprint""": """SHA-256 fingeravtrykk""",
  """login.certSubject""": """Emne""",
  """login.certIssuer""": """Utstedt av""",
  """login.certValidity""": """Gyldig""",
  """login.useAppPassword""": """Logg inn med eit app-passord i stadenfor""",
  """login.useBrowserLogin""": """Logg inn med nettlesaren i stadenfor""",
  """login.username""": """Brukarnamn""",
  """login.appPassword""": """App passord""",
  """login.appPasswordHelp""":
      """Lag eit app passord i Nextcloud under Innstillingar → Sikkerheit → Einingar & sesjonar. Bruk dette viss nettlesaren ikkje vil opne eller tenaren brukar eit sjølvsignert sertifikat.""",
  """login.appPasswordMissing""": """Skriv inn brukarnamn og app passord.""",
  """login.signIn""": """Logg inn""",
  """login.couldNotReachServer""":
      """Kunne ikkje kople til tenaren. Sjekk adressa og nettverk- eller VPN-tilkoblinga di.""",
  """login.connectionTimeout""":
      """Tenaren tok for lang tid til å svare. Sjekk adressa og nettverk- eller VPN-tilkoblinga di.""",
  """login.certProbeFailed""":
      """Klarte ikkje å lese sertifikatet til tenaren for å bekrefte det. Tilkoblinga kan vere ustabil, eller tenaren kan vere utilgjengeleg.""",
  """home.noHouses""": """Ingen hus enno.""",
  """home.noHousesBody""":
      """Hus er eit område for hushaldninga di. Opprett ditt fyrste hus for å kunne leggje til sjekklister, bilete og notat.""",
  """home.createHouse""": """Opprett hus""",
  """home.houseName""": """Namn på hus""",
  """home.houseDescription""": """Skildring (valfritt)""",
  """home.createHouseFailed""": """Klarte ikkje opprette hus""",
  """home.failedToLoadHouses""": """Klarte ikkje laste hus""",
  """home.serverAppMissingTitle""": """Pantry er ikkje installert""",
  """home.serverAppMissingBody""":
      """Denne appen er ein klient for Pantry-appen i Nextcloud. Det ser ut til at Pantry ikkje er installert på tenaren din enno. Spør administratoren om dei kan installere den frå Nextcloud app-butikken, eller installer den sjølv viss du har administratortilgang.""",
  """home.openAppStore""": """Opne Nextcloud appar""",
  """home.learnMore""": """Lær meir""",
  """nav.checklists""": """Sjekkliste""",
  """nav.photoBoard""": """Fotovegg""",
  """nav.notesWall""": """Notatvegg""",
  """onboarding.next""": """Neste""",
  """onboarding.back""": """Tilbake""",
  """onboarding.skip""": """Hopp over""",
  """onboarding.done""": """Kom i gang""",
  """onboarding.welcomeNewTitle""": """Velkomen til Pantry""",
  """onboarding.welcomeNewBody""":
      """Få ein kort introduksjon til korleis Pantry fungerer og korleis du kan få mest mogleg ut av den.""",
  """onboarding.welcomeUpdateTitle""": """Kva er nytt""",
  """onboarding.welcomeUpdateBody""":
      """Pantry har fått nokre nye funksjonar sidan du opna den sist. Her er ein kort gjennomgang av kva som er endra.""",
  """onboarding.checklistsRedesignTitle""":
      """Sjekklister har fått ein ny utsjånad""",
  """onboarding.checklistsRedesignBody""":
      """Sjekklistesida har blit bygga opp på nytt med eit reinare oppsett, raskare måtar å leggje til oppføringar og hurtighandlingar på kvar rad. Dei neste sidene tek deg gjennom kva som er nytt.""",
  """onboarding.checklistSelectorTitle""": """Byt lister på toppen""",
  """onboarding.checklistSelectorBody""":
      """Trykk på eit namnet eller ikonet til ei liste på toppen av skjermen for å byte mellom lister eller opprette ei ny liste.""",
  """onboarding.checklistSelectorHint""": """Trykk for å byte lister""",
  """onboarding.mockListGroceries""": """Daglegvarer""",
  """onboarding.mockListHardware""": """Jernvarebutikk""",
  """onboarding.mockListWeekend""": """Helgetur""",
  """onboarding.newListLabel""": """Ny liste""",
  """onboarding.swipeActionsTitle""":
      """Svei på oppføringar for å handsame dei""",
  """onboarding.swipeActionsBody""":
      """Sveip frå høgre til venstre på ei oppføring for å vise hurtighandlingar for redigering, flytting og sletting.""",
  """onboarding.swipeActionsHint""": """Sveip mot venstre""",
  """onboarding.swipeActionsHintBack""": """Sveip mot høgre""",
  """onboarding.quickActionsTitle""": """Hurtighandlingar på kvar oppføring""",
  """onboarding.quickActionsBody""":
      """Kvar oppføring viser handlingsknappar, trykk på ein av dei for å redigere, flytte eller slette ein oppføring utan å opne den.""",
  """onboarding.addItemsTitle""":
      """Ein raskare måte å leggje til oppføringar""",
  """onboarding.addItemsBody""":
      """Trykk på feltet ved bunnen for å skrive inn ei ny oppføring, merk det med ein kategori, mengd, type eller bilete ved å bruke brikkene over.""",
  """onboarding.mockComposeListName""": """Daglegvarer""",
  """onboarding.progressHeroTitle""": """Skjul framgangskortet""",
  """onboarding.progressHeroBody""":
      """Treng du ikkje framdriftsringen på toppen? Sveip den bort.""",
  """onboarding.progressHeroHint""": """Sveip for å avvise""",
  """onboarding.progressHeroDismissTitle""": """Skjul framgangskortet""",
  """onboarding.progressHeroDismissBody""":
      """Treng du ikkje framdriftsringen på toppen? Trykk på X-en på kortet for å skjule det.""",
  """onboarding.pinnedListsTitle""": """Fest lister til heimskjermen""",
  """onboarding.pinnedListsBody""":
      """Legg skjermelementet til Pantry på heimskjermen for å sjå kor mange oppføringar som er igjen på favorittlistene dine utan å opne appen.""",
  """onboarding.pinnedListsMenuLabel""": """kebab-menyen""",
  """onboarding.pinnedListsActionLabel""": """Fest liste""",
  """onboarding.pinnedListsWidgetTitle""": """Pantry""",
  """onboarding.pinnedListsWidgetEmpty""": """Ferdig""",
  """onboarding.pinnedNotesTitle""": """Hald viktige notat på toppen""",
  """onboarding.pinnedNotesBody""":
      """Fest eit notat frå overflytsmenyen for å låse det til toppen av notatveggen, sånn at det alltid er synleg.""",
  """onboarding.mockPinnedNoteTitle""": """Wi-Fi passord""",
  """onboarding.mockPinnedNoteContent""": """Nettverk: Heime
Passord: pantry""",
  """onboarding.mockItemName""": """Tomat""",
  """onboarding.mockItemQuantity""": """x2""",
  """onboarding.mockItemCategory""": """Meieriprodukt""",
  """onboarding.mockHardwareItemName""": """Lyspærer""",
  """onboarding.mockBulkItemThird""": """Mjølk""",
  """onboarding.mockBulkItemFourth""": """Brød""",
  """onboarding.allListsTitle""": """Alt i ei visning""",
  """onboarding.allListsBody""":
      """Opne «Alle lister»-visninga frå listebytaren for å sjå oppføringar frå alle listene dine samla. Når du legg til ein oppføring her vil du bli spurd om kva liste du vil putte det i, det kan du velje frå «Liste»-brikka.""",
  """onboarding.bulkAddTitle""": """Legg til mange oppføringar på ein gang""",
  """onboarding.bulkAddBody""":
      """Slå på «fleire» og tekstfeltet blir til eit felt med fleire linjer, og kvar linje blir sin eigen oppføring. Nyttig når du limar inn eller skriv ned ei heil handleliste.""",
  """onboarding.bulkSelectTitle""":
      """Utfør handlingar på fleire oppføringar om gangen""",
  """onboarding.bulkSelectBody""":
      """Trykk og hald nede på ei oppføring eller trykk på «Vel oppføringar» i menyen for å flytte, kopiere, endre kategori eller slette alle dei valde på ein gang.""",
  """onboarding.barcodeScanTitle""":
      """Skann ein strekkode for å legge til oppføringar""",
  """onboarding.barcodeScanBody""":
      """Trykk på skanneknappen i tilleggsfeltet og rett kameraet mot strekkoden på eit produkt. Pantry slår opp namn, kategori og bilete og fyller dei inn for deg - eller skriv nummeret inn for hand. Den første skanninga av eit produkt gjer oppslaget, etter det er det momentant for alle i huset ditt.""",
  """onboarding.barcodeScanMockName""": """Coca-Cola Zero""",
  """onboarding.barcodeScanMockCategory""": """Drikke""",
  """onboarding.priceTitle""": """Legg til prisar på oppføringane dine""",
  """onboarding.priceBody""":
      """Gje ei kvar oppføring ein pris – eit enkelt beløp eller eit område – i valutaen du vil. Han vert vist som ein brikke på oppføringa, og du kan filtrere lista etter pris for å halde deg innanfor budsjettet.""",
  """onboarding.priceMockName""": """Olivenolje""",
  """onboarding.shoppingIntroTitle""": """Handle butikk for butikk""",
  """onboarding.shoppingIntroBody""":
      """Start ein handletur over listene dine, gå gjennom kvar butikk i rekkjefølgje og kryss av varer undervegs — med ei løpande prissum.""",
  """onboarding.shoppingMockStoreActive""": """Supermarknad""",
  """onboarding.shoppingMockStoreNext""": """Apotek""",
  """onboarding.dev.showOnboarding""": """Vis oppstartshjelp""",
  """onboarding.dev.pickLastSeenTitle""": """Førehandsvis kva som er nytt""",
  """onboarding.dev.pickLastSeenBody""":
      """Vel versjonen du vil sjå endringar sidan.""",
  """onboarding.dev.neverSeen""": """Aldri sett (ny brukar)""",
  """onboarding.dev.forceAllFeatures""": """Tving alle funksjonar på""",
  """onboarding.dev.sendTestNotification""": """Send ein testvarsling""",
  """notificationsIntro.title""": """Hald deg oppdatert""",
  """notificationsIntro.body""":
      """Pantry kan varsle deg når nokon legg oppføringar til på lister, lastar opp bilete eller legg igjen notat. Varslingar vert henta frå din Nextcloud-tenar - ingenting blir sendt via Google eller andre tredjepartar.""",
  """notificationsIntro.bullet1""": """Varslingar for hushaldningsaktivitet""",
  """notificationsIntro.bullet2""": """Henta direkte frå tenaren""",
  """notificationsIntro.bullet3""": """Fungerer sjølv om appen er lukka""",
  """notificationsIntro.enableButton""": """Slå på varslingar""",
  """notificationsIntro.skipButton""": """Ikkje no""",
  """notificationsIntro.permissionDeniedTitle""": """Tilgang nekta""",
  """notificationsIntro.permissionDeniedBody""":
      """Du kan slå på varslingar seinare i innstillingane til appen. Om eininga di blokkerer varslingane må du endre det i innstillingane til eininga di.""",
  """notificationsIntro.ok""": """Ok""",
  """about.title""": """Om""",
  """about.developer""": """Utviklar""",
  """about.email""": """Epost""",
  """about.repository""": """Kjeldekode""",
  """about.nextcloudApp""": """Nextcloud-app""",
  """about.privacyPolicy""": """Personvern""",
  """about.feedback""": """Tilbakemelding og problemrapportar""",
  """about.serverVersion""": """Nextcloud tenar""",
  """about.pantryServerVersion""": """Pantry på tenar""",
  """about.versionUnknown""": """Ukjend""",
  """about.buyMeACoffee""": """Kjøp ein kaffi""",
  """settings.title""": """Innstillingar""",
  """settings.generalSection""": """Generelt""",
  """settings.interfaceSection""": """Brukargrensesnitt""",
  """settings.defaultItemTapAction""": """Standardhandling for rad""",
  """settings.defaultItemTapActionBody""":
      """Kva som skjer når du trykkar på ei rad.""",
  """settings.itemTapActionNames.done""": """Marker som ferdig""",
  """settings.itemTapActionNames.view""": """Vis""",
  """settings.itemTapActionNames.edit""": """Rediger""",
  """settings.itemTapActionNames.none""": """Ingen""",
  """settings.defaultItemLongPressAction""":
      """Standardhandling for trykk-og-hald""",
  """settings.defaultItemLongPressActionBody""":
      """Kva som skjer når du trykkar og hald nede på ei rad""",
  """settings.itemLongPressActionNames.multiselect""":
      """Fleirval/Endre rekkefylgje""",
  """settings.itemLongPressActionNames.done""": """Marker som ferdig""",
  """settings.itemLongPressActionNames.view""": """Vis""",
  """settings.itemLongPressActionNames.edit""": """Rediger""",
  """settings.itemLongPressActionNames.none""": """Ingen""",
  """settings.checkboxPosition""": """Posisjon for avkrysningsboks""",
  """settings.checkboxPositionBody""":
      """Kva side av rada avkrysningsboksen kjem opp på""",
  """settings.checkboxPositionNames.start""": """Start""",
  """settings.checkboxPositionNames.end""": """Slutt""",
  """settings.density""": """Listetettleik""",
  """settings.densityBody""":
      """Kor mykje plass kvar oppføring får i listene.""",
  """settings.densityNames.normal""": """Normal""",
  """settings.densityNames.dense""": """Tett""",
  """settings.densityNames.compact""": """Ekstra tett""",
  """settings.swipeActions""": """Sveiphandlingar""",
  """settings.swipeActionsBody""":
      """Sveip på oppføringar for å vise hurtighandlingar. Når slått av vil desse handlingane bli flytta til ein menyknapp på kvar oppføring.""",
  """settings.itemActions""": """Handlingar""",
  """settings.itemActionsBody""":
      """Vis hurtighandlingar på kvar oppføring. Når slått av vil handlingane bli flytta til ein menyknapp på kvar oppføring.""",
  """settings.reuseExistingItems""":
      """Bruk eksisterande oppføringar på nytt når du leggjer til nye""",
  """settings.reuseExistingItemsBody""":
      """Når du prøver å leggje til ei oppføring som allereie finst, bruk den eksisterande oppføringa på nytt i staden for å lage ei ny oppføring.""",
  """settings.reuseExistingItemsNames.ask""": """Alltid spør""",
  """settings.reuseExistingItemsNames.reuse""": """Alltid bruk igjen""",
  """settings.reuseExistingItemsNames.never""": """Aldri bruk igjen""",
  """settings.navOrderTitle""": """Navigasjonsrekkefylgje""",
  """settings.navOrderSubtitle""":
      """Endre rekkefylgja på navigasjonsfanene. Den fyrste oppføringa er den som blir vist når du opnar appen.""",
  """settings.navOrderBody""":
      """Dra for å endre rekkefylgja på fanene. Den fyrste synlege oppføringa blir vist når du opnar appen. Slå av delar du ikkje brukar for å skjula fana deira – minst éi må vera på.""",
  """settings.navOrderDefaultHint""": """Blir vist når du opnar appen""",
  """settings.navOrderReset""": """Nullstill""",
  """settings.visibleChipsTitle""": """Varedetaljar""",
  """settings.visibleChipsSubtitle""":
      """Vel kva detaljar som blir viste på kvar vare.""",
  """settings.visibleChipsBody""":
      """Slå av detaljar du ikkje vil ha viste som merkelapp på varelinjene.""",
  """settings.visibleChipsReset""": """Nullstill""",
  """settings.chipNames.category""": """Kategori""",
  """settings.chipNames.store""": """Butikk""",
  """settings.chipNames.quantity""": """Mengd""",
  """settings.chipNames.price""": """Pris""",
  """settings.chipNames.note""": """Notat""",
  """settings.chipNames.oneTime""": """Eingongs""",
  """settings.chipNames.recurring""": """Gjentakande""",
  """settings.chipNames.list""": """Liste""",
  """settings.language""": """Språk""",
  """settings.systemLanguage""": """Systemstandard""",
  """settings.theme""": """Drakt""",
  """settings.themeNames.system""": """Systemstandard""",
  """settings.themeNames.light""": """Lys""",
  """settings.themeNames.dark""": """Mørk""",
  """settings.useServerThemeColor""": """Bruk Nextcloud-temafarge""",
  """settings.useServerThemeColorBody""":
      """Fargelegg appen med temafargen til Nextcloud-brukaren din. Slå av for å bruke appen sine eigne fargar.""",
  """settings.notificationsSection""": """Varsel""",
  """settings.enableNotifications""": """Slå på varsel""",
  """settings.enableNotificationsBody""":
      """Vis varsel når nokon legg til eller opppdaterer innhald.""",
  """settings.pollInterval""": """Sjå etter ny aktivitet""",
  """settings.pollInterval15m""": """Kvart 15. minutt""",
  """settings.pollInterval30m""": """Kvart 30. minutt""",
  """settings.pollInterval1h""": """Kvar time""",
  """settings.pollInterval2h""": """Kvart 2. time""",
  """settings.pollInterval6h""": """Kvart 6. time""",
  """settings.permissionDenied""":
      """Tilgang til å sende varslar vart ikkje gitt. Slå det på i systeminnstillingane.""",
  """settings.refreshSection""": """Automatisk oppdatering""",
  """settings.refreshSectionBody""":
      """Kor ofte kvar skjerm ser etter endringar på tenaren medan du ser på han. Du kan alltid dra ned for å oppdatere manuelt.""",
  """settings.checklistRefresh""": """Lister""",
  """settings.notesRefresh""": """Notat""",
  """settings.photosRefresh""": """Bilete""",
  """settings.shoppingRefresh""": """Handlemodus""",
  """settings.refreshOff""": """Av""",
  """settings.refreshInherit""": """Som lister""",
  """settings.refresh15s""": """Kvart 15. sekund""",
  """settings.refresh30s""": """Kvart 30. sekund""",
  """settings.refresh1m""": """Kvart minutt""",
  """settings.refresh2m""": """Kvart 2. minutt""",
  """settings.refresh5m""": """Kvart 5. minutt""",
  """notifications.title""": """Varsel""",
  """notifications.empty""": """Ingen nye varsel.""",
  """notifications.failedToLoad""": """Klart ikkje laste varslingar.""",
  """notifications.dismissAll""": """Avvis alle""",
  """notifications.justNow""": """nett no""",
  """categories.manageTitle""": """Behandle kategoriar""",
  """categories.noCategories""": """Ingen kategoriar enno.""",
  """categories.editTitle""": """Rediger kategori""",
  """categories.addTitle""": """Ny kategori""",
  """categories.name""": """Namn""",
  """categories.icon""": """Ikon""",
  """categories.color""": """Farge""",
  """categories.saveFailed""": """Klarte ikkje lagre kategori.""",
  """categories.deleteFailed""": """Klarte ikkje slette kategori.""",
  """categories.deleteConfirm""": """Slett denne kategorien?""",
  """categories.deleteConfirmBody""":
      """Oppføringar i denne kategorien vil verta ukategoriserte. Dette kan ikkje angrast.""",
  """categories.sort.nameAZ""": """Namn A-Z""",
  """categories.sort.nameZA""": """Namn Z-A""",
  """categories.sort.custom""": """Sjølvvald""",
  """stores.manageTitle""": """Behandle butikkar""",
  """stores.noStores""": """Ingen butikkar enno.""",
  """stores.editTitle""": """Rediger butikk""",
  """stores.addTitle""": """Ny butikk""",
  """stores.name""": """Namn""",
  """stores.icon""": """Ikon""",
  """stores.color""": """Farge""",
  """stores.saveFailed""": """Klarte ikkje lagre butikk.""",
  """stores.deleteFailed""": """Klarte ikkje slette butikk.""",
  """stores.deleteConfirm""": """Slett butikk?""",
  """stores.deleteConfirmBody""":
      """Butikken vil bli fjerna frå alle oppføringar. Dette kan ikkje angrast.""",
  """stores.brand""": """Merke/kjede""",
  """stores.brandHint""": """t.d. Meny, IKEA""",
  """stores.location""": """Stad""",
  """stores.locationHint""": """t.d. Karl Johans gate 22""",
  """stores.openingHours""": """Opningstider""",
  """stores.addOpeningHours""": """Legg til opningstider""",
  """stores.openingHoursStart""": """Start""",
  """stores.openingHoursEnd""": """Slutt""",
  """stores.openingHoursAdd""": """Legg til""",
  """stores.contact""": """Kontakt""",
  """stores.contactHint""": """t.d. telefonnummer, nettstad, sosiale medier""",
  """stores.responsible""": """Ansvarleg""",
  """stores.responsibleHint""": """t.d. butikksjef""",
  """stores.notes""": """Notat""",
  """stores.notesHint""": """Andre ting som er verdt å hugse""",
  """stores.noDetails""": """Ingen detaljar er lagt til enno.""",
  """stores.editAction""": """Rediger""",
  """stores.sort.nameAZ""": """Namn A–Å""",
  """stores.sort.nameZA""": """Namn Å–A""",
  """stores.sort.custom""": """Tilpassa""",
  """checklists.categories""": """Kategoriar""",
  """checklists.noChecklists""": """Ingen sjekklister enno.""",
  """checklists.noItems""": """Ingen oppføringar i denne lista.""",
  """checklists.noSearchResults""":
      """Ingen oppføringar samsvarer med søket.""",
  """checklists.searchHint""": """Skriv for å filtrere…""",
  """checklists.barcode.scan""": """Skann strekkode""",
  """checklists.barcode.scanTitle""": """Skann strekkode""",
  """checklists.barcode.scanInstructions""":
      """Rett kameraet mot ein produktstrekkode""",
  """checklists.barcode.enterManually""": """Skriv inn manuelt""",
  """checklists.barcode.manualTitle""": """Skriv inn strekkode""",
  """checklists.barcode.manualHint""": """Strekkodenummer""",
  """checklists.barcode.invalidBarcode""":
      """Det ser ikkje ut som ein gyldig strekkode""",
  """checklists.barcode.notFound""":
      """Fann ikkje produktinfo for den strekkoden""",
  """checklists.allCategories""": """Alle""",
  """checklists.allListsChip""": """Alle""",
  """checklists.filterByList""": """Filter etter liste""",
  """checklists.filterByCategory""": """Filter etter kategori""",
  """checklists.filters.lists""": """Lister""",
  """checklists.filters.categories""": """Kategoriar""",
  """checklists.filters.stores""": """Butikkar""",
  """checklists.filters.allLists""": """Alle lister""",
  """checklists.filters.allCategories""": """Alle kategoriar""",
  """checklists.filters.allStores""": """Alle butikkar""",
  """checklists.filters.noCategory""": """Ingen kategori""",
  """checklists.filters.noStores""": """Ingen butikkar""",
  """checklists.filters.price""": """Pris""",
  """checklists.filters.anyCurrency""": """Kva som helst valuta""",
  """checklists.failedToLoad""": """Kunne ikkje laste sjekklister.""",
  """checklists.failedToLoadItems""": """Kunne ikkje laste oppføringar.""",
  """checklists.editItem""": """Rediger oppføring""",
  """checklists.removeItem""": """Fjern oppføring""",
  """checklists.moveItem""": """Flytt til liste""",
  """checklists.moveFailed""": """Klarte ikkje flytte oppføring.""",
  """checklists.copyItem""": """Kopier til liste""",
  """checklists.copyFailed""": """Klarte ikkje kopiere oppføring.""",
  """checklists.itemCopied""": """Oppføring kopiert""",
  """checklists.itemMarkedDone""": """Oppføring markert som fullført""",
  """checklists.itemRemoved""": """Oppføring fjerna""",
  """checklists.undo""": """Angre""",
  """checklists.selectItems""": """Vel oppføringar""",
  """checklists.batch.moveTitle""": """Flytt oppføringar til""",
  """checklists.batch.copyTitle""": """Kopier oppføringar til""",
  """checklists.batch.categoryTitle""": """Vel kategori""",
  """checklists.batch.storesTitle""": """Vel butikkar""",
  """checklists.batch.clearCategory""": """Ingen kategori""",
  """checklists.batch.move""": """Flytt""",
  """checklists.batch.copy""": """Kopier""",
  """checklists.batch.category""": """Kategori""",
  """checklists.batch.stores""": """Butikkar""",
  """checklists.batch.delete""": """Slett""",
  """checklists.batch.archive""": """Arkiver""",
  """checklists.batch.unarchive""": """Angre arkivering""",
  """checklists.batch.deleteConfirmTitle""": """Slett oppføringar?""",
  """checklists.batch.failed""": """Noko er feil. Prøv igjen.""",
  """checklists.viewTrash""": """Sjå papirkorga""",
  """checklists.exitTrash""": """Gå ut av papirkorga""",
  """checklists.showAddedBy""": """Sjå kven som la til kvar oppføring""",
  """checklists.showProgressHero""": """Vis eit framgangskort på denne lista""",
  """checklists.trashTitle""": """Papirkorg""",
  """checklists.noTrashedItems""": """Papirkorga er tom.""",
  """checklists.emptyTrash""": """Tøm papirkorga""",
  """checklists.emptyTrashConfirm""": """Tøm papirkorga?""",
  """checklists.emptyTrashConfirmBody""":
      """Alle oppføringar i papirkorga vil bli sletta permanent. Dette kan ikkje angrast.""",
  """checklists.emptyTrashFailed""": """Klarte ikkje tømme papirkorga.""",
  """checklists.restoreItem""": """Gjenopprett""",
  """checklists.permanentlyDeleteItem""": """Slett""",
  """checklists.permanentlyDeleteConfirm""":
      """Slett denne oppføringa permanent?""",
  """checklists.permanentlyDeleteConfirmBody""": """Dette kan ikkje angrast.""",
  """checklists.restoreFailed""": """Kunne ikkje gjenopprette oppføring.""",
  """checklists.permanentlyDeleteFailed""":
      """Klarte ikkje slette oppføring.""",
  """checklists.itemRestored""": """Oppføring gjenoppretta""",
  """checklists.viewArchive""": """Vis arkiv""",
  """checklists.exitArchive""": """Gå ut av arkiv""",
  """checklists.archiveTitle""": """Arkiver""",
  """checklists.noCategory""": """Ingen kategori""",
  """checklists.noStore""": """Ingen butikk""",
  """checklists.noArchivedItems""": """Arkivet er tomt.""",
  """checklists.archiveItem""": """Arkiver""",
  """checklists.unarchiveItem""": """Angre arkivering""",
  """checklists.archiveFailed""": """Klarte ikkje arkivere oppføring""",
  """checklists.unarchiveFailed""":
      """Kunne ikkje flytte oppføringa ut av arkivet.""",
  """checklists.itemArchived""": """Oppføring arkivert""",
  """checklists.itemUnarchived""": """Oppføring flytta frå arkivet""",
  """checklists.failedToLoadArchive""": """Kunne ikkje laste arkivet.""",
  """checklists.viewListsTrash""": """Sletta lister""",
  """checklists.listsTrashTitle""": """Sletta lister""",
  """checklists.failedToLoadTrash""": """Klarte ikkje laste papirkorga.""",
  """checklists.listTrashEmpty""": """Ingen sletta lister""",
  """checklists.pinList""": """Fest liste""",
  """checklists.unpinList""": """Fjern festing av liste""",
  """checklists.removeList""": """Fjern liste""",
  """checklists.editList""": """Rediger liste""",
  """checklists.editListTitle""": """Rediger liste""",
  """checklists.saveListButton""": """Lagre endringar""",
  """checklists.updateListFailed""": """Kunne ikkje oppdatere liste.""",
  """checklists.removeListConfirm""": """Fjern liste?""",
  """checklists.removeListFailed""": """Kunne ikkje fjerne liste.""",
  """checklists.restoreList""": """Gjenopprett liste""",
  """checklists.permanentlyDeleteList""": """Slett permanent""",
  """checklists.listRemoved""": """Liste fjerna""",
  """checklists.createList""": """Ny liste""",
  """checklists.listName""": """Listenamn""",
  """checklists.listDescription""": """Skildring (valfritt)""",
  """checklists.listIcon""": """Ikon""",
  """checklists.createListFailed""": """Kunne ikkje opprette liste.""",
  """checklists.viewItem.quantity""": """Mengd:""",
  """checklists.viewItem.category""": """Kategori:""",
  """checklists.viewItem.recurrence""": """Tidsplan:""",
  """checklists.viewItem.nextDue""": """Neste gjentaking:""",
  """checklists.viewItem.nextDueFromCompletion""":
      """Neste gjentaking (frå sist fullført):""",
  """checklists.viewItem.overdue""": """Forfalt""",
  """checklists.viewItem.quantityLabel""": """Tal""",
  """checklists.viewItem.typeLabel""": """Type""",
  """checklists.viewItem.priceLabel""": """Pris""",
  """checklists.viewItem.descriptionLabel""": """Skildring""",
  """checklists.viewItem.noDescription""": """Inga skildring lagt til.""",
  """checklists.viewItem.relJustNow""": """nett no""",
  """checklists.viewItem.relToday""": """i dag""",
  """checklists.viewItem.relYesterday""": """i går""",
  """checklists.itemForm.addTitle""": """Legg til oppføring""",
  """checklists.itemForm.editTitle""": """Rediger oppføring""",
  """checklists.itemForm.name""": """Namn""",
  """checklists.itemForm.description""": """Skildring""",
  """checklists.itemForm.quantity""": """Tal""",
  """checklists.itemForm.category""": """Kategori""",
  """checklists.itemForm.noCategory""": """Ingen""",
  """checklists.itemForm.noCategories""": """Ingen kategoriar tilgjengeleg.""",
  """checklists.itemForm.createCategory""": """Ny kategori""",
  """checklists.itemForm.categoryName""": """Namn""",
  """checklists.itemForm.categoryIcon""": """Ikon""",
  """checklists.itemForm.categoryColor""": """Farge""",
  """checklists.itemForm.categoryCreated""": """Kategori oppretta.""",
  """checklists.itemForm.categoryCreateFailed""":
      """Klarte ikkje opprette kategori.""",
  """checklists.itemForm.stores""": """Butikkar""",
  """checklists.itemForm.noStores""": """Ingen""",
  """checklists.itemForm.createStore""": """Ny butikk""",
  """checklists.itemForm.storesChange""": """Endre""",
  """checklists.itemForm.storesPick""": """Vel nokre""",
  """checklists.itemForm.repeat""": """Gjentek""",
  """checklists.itemForm.once""": """Ein gang""",
  """checklists.itemForm.onceDescription""":
      """Slett denne oppføringa når den er markert som fullført.""",
  """checklists.itemForm.image""": """Bilete""",
  """checklists.itemForm.addImage""": """Legg til bilete""",
  """checklists.itemForm.takePhoto""": """Ta bilete""",
  """checklists.itemForm.chooseImage""": """Vel bilete""",
  """checklists.itemForm.replaceImage""": """Erstatt""",
  """checklists.itemForm.removeImage""": """Fjern""",
  """checklists.itemForm.saveFailed""": """Klarte ikkje slette oppføring.""",
  """checklists.itemForm.deleteFailed""": """Klarte ikkje slette oppføring.""",
  """checklists.itemForm.deleteConfirm""": """Slett denne oppføringa?""",
  """checklists.itemForm.save""": """Lagre endringar""",
  """checklists.itemForm.descHint""": """Legg til ei skildring (valfritt)""",
  """checklists.itemForm.categoryChange""": """Endre""",
  """checklists.itemForm.categoryPick""": """Vel ein""",
  """checklists.itemForm.untitledItem""": """Oppføring utan namn""",
  """checklists.itemForm.typeStaple""": """Fest oppføring""",
  """checklists.itemForm.typeOnce""": """Ein gang""",
  """checklists.itemForm.typeRecurring""": """Gjentek""",
  """checklists.sort.newestFirst""": """Nyaste fyrst""",
  """checklists.sort.oldestFirst""": """Eldste fyrst""",
  """checklists.sort.nameAZ""": """Namn A-Z""",
  """checklists.sort.nameZA""": """Namn Z-A""",
  """checklists.sort.category""": """Etter kategori""",
  """checklists.sort.store""": """Etter butikk""",
  """checklists.sort.custom""": """Sjølvvald""",
  """checklists.allDone""": """Ferdig 🎉""",
  """checklists.hideProgressHero""": """Sjul framgangskort""",
  """checklists.sortTooltip""": """Sorter""",
  """checklists.addFirstItem""": """Legg til di fyrste oppføring…""",
  """checklists.noItemsTitle""": """Ingenting på denne lista enno""",
  """checklists.noItemsBody""":
      """Legg til di fyrste oppføring under, vel ein kategori, mengdm eller tidsplan ved å bruke brikkene.""",
  """checklists.noListsTitle""": """Ingen sjekklister enno""",
  """checklists.noListsBody""":
      """Opprett di fyrste liste for å handtere daglegvarer, oppgåver og andre ting som hushaldninga treng å halde styr på.""",
  """checklists.createFirstList""": """Opprett di fyrste liste""",
  """checklists.yourChecklists""": """Dine sjekklister""",
  """checklists.allDoneSummary""": """Ferdig · 0 igjen""",
  """checklists.newChecklist""": """Ny sjekkliste""",
  """checklists.createListButton""": """Opprett liste""",
  """checklists.view""": """Vis""",
  """checklists.swipeView""": """Vis""",
  """checklists.swipeEdit""": """Rediger""",
  """checklists.swipeMove""": """Flytt""",
  """checklists.swipeCopy""": """Kopier""",
  """checklists.swipeDelete""": """Fjern""",
  """checklists.swipeArchive""": """Arkiver""",
  """checklists.moreActions""": """Fleire handlingar""",
  """checklists.viewList""": """Listevisning""",
  """checklists.viewCards""": """Kortvisning""",
  """checklists.listColor""": """Farge""",
  """checklists.itemTypes.label""": """Type""",
  """checklists.itemTypes.staple""": """Fest""",
  """checklists.itemTypes.stapleBody""":
      """Blir verande på lista etter at du har markert den som fullført""",
  """checklists.itemTypes.onceTime""": """Eingongsbruk""",
  """checklists.itemTypes.onceTimeBody""": """Fjerna når du fullførar den.""",
  """checklists.itemTypes.recurring""": """Gjentek""",
  """checklists.itemTypes.recurringBody""":
      """Kjem tilbake basert på ein tidsplan""",
  """checklists.itemTypes.weekly""": """Kvar veke""",
  """checklists.compose.chipCategory""": """Kategori""",
  """checklists.compose.chipStore""": """Butikkar""",
  """checklists.compose.chipQuantity""": """Tal""",
  """checklists.compose.chipType""": """Type""",
  """checklists.compose.chipImage""": """Bilete""",
  """checklists.compose.chipDescription""": """Skildring""",
  """checklists.compose.descHint""": """Notat, instruksjonar, lenkjer…""",
  """checklists.compose.qtyHint""": """t.d. 2 l, 500 g""",
  """checklists.compose.qtyStepperHelp""":
      """＋ / − endre mengden og behald eininga.""",
  """checklists.compose.none""": """Ingen""",
  """checklists.compose.every""": """Kvar""",
  """checklists.compose.week""": """veke""",
  """checklists.compose.weeks""": """veker""",
  """checklists.compose.chipTargetList""": """Liste""",
  """checklists.compose.pickTargetList""": """Vel ei liste""",
  """checklists.compose.multiple""": """Fleire""",
  """checklists.compose.multipleHint""":
      """Skil ulike oppføringar ved å lage ei ny linje""",
  """checklists.price.label""": """Pris""",
  """checklists.price.set""": """Fast""",
  """checklists.price.range""": """Område""",
  """checklists.price.amount""": """Beløp""",
  """checklists.price.min""": """Min""",
  """checklists.price.max""": """Maks""",
  """checklists.price.currency""": """Valuta""",
  """checklists.price.clear""": """Fjern pris""",
  """checklists.reuse.dialogTitle""": """Oppføringa finst allereie""",
  """checklists.reuse.reuseExisting""": """Gjenbruk""",
  """checklists.reuse.addAnyway""": """Legg til likevel""",
  """checklists.reuse.suggestionsHeader""": """Allereie i denne lista""",
  """checklists.allLists""": """Alle lister""",
  """checklists.allListsSubtitle""": """Oppføringar frå alle lister""",
  """checklists.addToAnyList""": """Lag oppføring…""",
  """checklists.pickListTitle""": """Kva liste vil du leggje den til?""",
  """checklists.markdown.uncategorized""": """Ukategorisert""",
  """checklists.markdown.exportTitle""": """Eksporter til markdown""",
  """checklists.markdown.importTitle""": """Importer frå markdown""",
  """checklists.markdown.includeCompleted""":
      """Inkluder fullførte oppføringar""",
  """checklists.markdown.editHint""":
      """Rediger teksten under for å endre den eksporterte lista""",
  """checklists.markdown.copy""": """Kopier""",
  """checklists.markdown.download""": """Last ned .md""",
  """checklists.markdown.copied""": """Kopiert til utklippstavla""",
  """checklists.markdown.copyFailed""":
      """Kunne ikkje kopiere til utklippstavla""",
  """checklists.markdown.close""": """Lukk""",
  """checklists.markdown.shareFailed""": """Kunne ikkje eksportere fila""",
  """checklists.markdown.uploadFile""": """Last opp ei .md-fil""",
  """checklists.markdown.pasteLabel""": """Lim inn markdown""",
  """checklists.markdown.pastePlaceholder""":
      """Lim inn ei Markdown-liste her.""",
  """checklists.markdown.noneFound""":
      """Fann ingen listeoppføringar i teksten.""",
  """checklists.markdown.selectAll""": """Merk alt""",
  """checklists.markdown.deselectAll""": """Fjern markeringa av alt""",
  """checklists.markdown.reuseExisting""":
      """Bruk eksisterande oppføringar i staden for å opprette duplikatar""",
  """checklists.markdown.defaultFields""":
      """Standardinnstillingar som blir brukt på kvar oppføring""",
  """notesWall.noNotes""": """Ingen notat enno""",
  """notesWall.failedToLoad""": """Klarte ikkje laste notat""",
  """notesWall.saveFailed""": """Klarte ikkje lagre notat.""",
  """notesWall.deleteFailed""": """Klarte ikkje slette notatet.""",
  """notesWall.deleteConfirm""": """Slett dette notatet?""",
  """notesWall.viewTrash""": """Vis papirkorga""",
  """notesWall.exitTrash""": """Gå ut av papirkorga""",
  """notesWall.trashTitle""": """Papirkorg""",
  """notesWall.trashEmpty""": """Papirkorga er tom.""",
  """notesWall.emptyTrash""": """Tøm papirkorga""",
  """notesWall.emptyTrashConfirm""": """Tøm papirkorga?""",
  """notesWall.emptyTrashConfirmBody""":
      """Alle notata i papirkorga vil bli sletta permanent. Dette kan ikkje angrast.""",
  """notesWall.emptyTrashFailed""": """Klarte ikkje tømme papirkorga.""",
  """notesWall.failedToLoadTrash""": """Klarte ikkje laste papirkorga.""",
  """notesWall.restore""": """Gjenopprett""",
  """notesWall.restoreFailed""": """Klarte ikkje gjenopprette notat.""",
  """notesWall.permanentlyDelete""": """Slett permanent""",
  """notesWall.permanentlyDeleteConfirm""":
      """Slett dette notatet permanent?""",
  """notesWall.permanentlyDeleteConfirmBody""": """Dette kan ikkje angrast.""",
  """notesWall.newNote""": """Nytt notat""",
  """notesWall.editNote""": """Rediger notat""",
  """notesWall.unsavedChanges""": """Ulagra endringar""",
  """notesWall.unsavedChangesBody""":
      """Du har ulagra endringar. Vil du lagre dei?""",
  """notesWall.discard""": """Forkast""",
  """notesWall.keepEditing""": """Fortset å redigere""",
  """notesWall.pinNote""": """Fest notat""",
  """notesWall.unpinNote""": """Fjern festing av notat""",
  """notesWall.title""": """Tittel""",
  """notesWall.content""": """Innhald""",
  """notesWall.color""": """Farge""",
  """notesWall.sort.newestFirst""": """Nyaste fyrst""",
  """notesWall.sort.oldestFirst""": """Eldste fyrst""",
  """notesWall.sort.titleAZ""": """Tittel A-Z""",
  """notesWall.sort.titleZA""": """Tittel Z-A""",
  """notesWall.sort.custom""": """Sjølvvald""",
  """photoBoard.noPhotos""": """Ingen bilete enno.""",
  """photoBoard.failedToLoad""": """Klarte ikkje laste bilete.""",
  """photoBoard.uploadFailed""": """Klarte ikkje laste opp bilete.""",
  """photoBoard.deleteFailed""": """Klarte ikkje slette bilete""",
  """photoBoard.deleteConfirm""": """Slett dette biletet?""",
  """photoBoard.viewTrash""": """Vis papirkorga""",
  """photoBoard.exitTrash""": """Gå ut av papirkorga""",
  """photoBoard.trashTitle""": """Papirkorg""",
  """photoBoard.trashEmpty""": """Papirkorga er tom.""",
  """photoBoard.emptyTrash""": """Tøm papirkorga""",
  """photoBoard.emptyTrashConfirm""": """Tøm papirkorga?""",
  """photoBoard.emptyTrashConfirmBody""":
      """Alle bielta i papirkorga vil bli sletta permanent. Dette kan ikkje angrast.""",
  """photoBoard.emptyTrashFailed""": """Klarte ikkje tømme papirkorga.""",
  """photoBoard.failedToLoadTrash""": """Klarte ikkje laste papirkorga.""",
  """photoBoard.restore""": """Gjenopprett""",
  """photoBoard.restoreFailed""": """Kunne ikkje gjenopprette bilete.""",
  """photoBoard.permanentlyDelete""": """Slett permanent""",
  """photoBoard.permanentlyDeleteConfirm""":
      """Slett dette biletet permanent?""",
  """photoBoard.permanentlyDeleteConfirmBody""": """Dette kan ikkje angrast.""",
  """photoBoard.deleteFolder""": """Slett mappe""",
  """photoBoard.deleteFolderConfirm""": """Slett denne mappa?""",
  """photoBoard.deleteFolderKeepPhotos""": """Flytt bilete til rotmappa.""",
  """photoBoard.deleteFolderDeleteAll""": """Slett mappa og bilete""",
  """photoBoard.newFolder""": """Ny mappe""",
  """photoBoard.folderName""": """Katalognavn""",
  """photoBoard.renameFolder""": """Gi nytt namn til mappe""",
  """photoBoard.caption""": """Bilettekst""",
  """photoBoard.addMenu.upload""": """Last opp bilete""",
  """photoBoard.addMenu.camera""": """Ta bilete""",
  """photoBoard.addMenu.newFolder""": """Ny mappe""",
  """photoBoard.sort.foldersFirst""": """Mapper fyrst""",
  """photoBoard.sort.newestFirst""": """Nyaste fyrst""",
  """photoBoard.sort.oldestFirst""": """Eldste fyrst""",
  """photoBoard.sort.captionAZ""": """Bilettekst A-Z""",
  """photoBoard.sort.captionZA""": """Bilettekst Z-a""",
  """photoBoard.sort.custom""": """Sjølvvald""",
  """shopping.startShopping""": """Start handel""",
  """shopping.resumeShopping""": """Hald fram handelen""",
  """shopping.shoppingHistory""": """Handelshistorikk""",
  """shopping.resume""": """Hald fram""",
  """shopping.bannerShoppingNow""": """Handlar no""",
  """shopping.startTitle""": """Start handel""",
  """shopping.listsToShop""": """Lister å handle""",
  """shopping.selectAll""": """Vel alle""",
  """shopping.selectNone""": """Vel ingen""",
  """shopping.noListsToShop""": """Ingen lister å handle enno.""",
  """shopping.storesTitle""": """Butikkar""",
  """shopping.storesHint""":
      """Slå på eller av butikkane du skal innom, og dra for å setje rekkjefølgja.""",
  """shopping.noStoresWithItems""":
      """Ingen av dei valde listene har varer knytte til ein butikk.""",
  """shopping.includeUnassigned""": """Ta med varer utan butikk""",
  """shopping.start""": """Start""",
  """shopping.startFailed""": """Klarte ikkje å starte handelen.""",
  """shopping.tripInProgress""": """Du har allereie ein handel i gang.""",
  """shopping.endPreviousTrip""": """Avslutt førre handel""",
  """shopping.endPreviousFailed""": """Klarte ikkje å avslutte førre handel.""",
  """shopping.makePrivate""": """Skjul handelen for husfellane""",
  """shopping.makePublic""": """Vis handelen for husfellane""",
  """shopping.privateBadge""": """Privat""",
  """shopping.nextStore""": """Neste butikk""",
  """shopping.finish""": """Fullfør""",
  """shopping.finishTrip""": """Fullfør handelen""",
  """shopping.allCheckedHere""": """Alt kryssa av her""",
  """shopping.moveOnToNext""": """Gå vidare til neste butikk.""",
  """shopping.allDone""": """Alt ferdig""",
  """shopping.everythingInCart""": """Alt er i korga.""",
  """shopping.nothingToBuyHere""": """Ingenting å kjøpe her.""",
  """shopping.checkFailed""": """Klarte ikkje å oppdatere vara.""",
  """shopping.loadItemsFailed""": """Klarte ikkje å laste varene.""",
  """shopping.removeFromTrip""": """Fjern frå handleturen""",
  """shopping.removedFromTrip""": """Fjerna frå denne handleturen""",
  """shopping.undo""": """Angre""",
  """shopping.undoRemoveFailed""": """Klarte ikkje å angre.""",
  """shopping.reviewTitle""": """Oppsummering""",
  """shopping.advanceTitle""": """Neste butikk""",
  """shopping.actualPaid""": """Faktisk betalt""",
  """shopping.grandTotal""": """Totalsum""",
  """shopping.anyStore""": """Kva som helst butikk""",
  """shopping.saveTotalFailed""": """Klarte ikkje å lagre summen.""",
  """shopping.remindersTitle""": """Påminningar""",
  """shopping.manageReminders""": """Handter påminningar""",
  """shopping.reminderGroupStart""": """Ved start""",
  """shopping.reminderGroupAdvance""": """Mellom butikkar""",
  """shopping.reminderGroupEnd""": """Ved slutt""",
  """shopping.noRemindersHere""": """Ingen påminningar her enno.""",
  """shopping.noRemindersStep""":
      """Ingen påminningar for dette steget enno.""",
  """shopping.addReminders""": """Legg til påminningar""",
  """shopping.addReminderHint""": """Legg til ei påminning""",
  """shopping.reminderWhen""": """Når skal ho visast""",
  """shopping.whenOnStart""": """Ved start""",
  """shopping.whenOnStoreAdvance""": """Mellom butikkar""",
  """shopping.whenOnClose""": """Ved slutt""",
  """shopping.add""": """Legg til""",
  """shopping.reminderSaveFailed""": """Klarte ikkje å lagre påminninga.""",
  """shopping.reminderDeleteFailed""": """Klarte ikkje å slette påminninga.""",
  """shopping.historyTitle""": """Handelshistorikk""",
  """shopping.scopeMine""": """Mine""",
  """shopping.scopeHouse""": """Hus""",
  """shopping.noStorePath""": """Ingen butikk""",
  """shopping.loadMore""": """Last inn meir""",
  """shopping.noTripsYet""": """Ingen handlar enno.""",
  """shopping.noHouseTripsYet""": """Ingen handlar i dette huset enno.""",
  """shopping.loadHistoryFailed""": """Klarte ikkje å laste historikken.""",
  """shopping.loadFailed""": """Noko gjekk gale. Prøv igjen.""",
  """shopping.uncategorized""": """Utan kategori""",
  """share.title""": """Del til Pantry""",
  """share.chooseHouse""": """Vel hus""",
  """share.choosePhotoDestination""": """Last opp til""",
  """share.photoBoardRoot""": """Fotovegg""",
  """share.newFolder""": """Ny mappe""",
  """share.newFolderName""": """Katalognavn""",
  """share.failedToCreateFolder""": """Klarte ikkje opprette mappe.""",
  """share.failedToOpenShare""": """Kunne ikkje opne det delte innhaldet.""",
  """share.noHouses""": """Ingen hus tilgjengeleg. Opprett eit hus fyrst.""",
  """recurrence.title""": """Gjentaking""",
  """recurrence.presets""": """Førehandsval""",
  """recurrence.daily""": """Kvar dag""",
  """recurrence.weekly""": """Kvar veke""",
  """recurrence.monthly""": """Månadleg""",
  """recurrence.everyLabel""": """Kvar""",
  """recurrence.unit""": """Eining""",
  """recurrence.unitDays""": """dagar""",
  """recurrence.unitWeeks""": """veker""",
  """recurrence.unitMonths""": """månadar""",
  """recurrence.unitYears""": """år""",
  """recurrence.repeatOn""": """Gjenta på""",
  """recurrence.ends""": """Sluttar""",
  """recurrence.never""": """Aldri""",
  """recurrence.after""": """Etter""",
  """recurrence.occurrences""": """gjentakingar""",
  """recurrence.onDate""": """På dato""",
  """recurrence.countFromCompletion""":
      """Baser intervallet på når oppføringa var markert som fullført""",
  """recurrence.countFromCompletionHintOff""":
      """Tidsplanen er førehandsdefinert: oppføringa kjem tilbake uavhengig av når det var markert som fullført.""",
  """recurrence.countFromCompletionHintOn""":
      """Den neste gjentakinga er basert frå når du markerar oppføringa som fullført, så det kjem alltid tilbake eit fullt intervall etter att det var fullført.""",
  """recurrence.summary""": """Oppsumering""",
  """recurrence.notSet""": """ikkje angitt""",
  """recurrence.set""": """angitt""",
  """recurrence.dayNames.monday""": """Måndag""",
  """recurrence.dayNames.tuesday""": """Tysdag""",
  """recurrence.dayNames.wednesday""": """Onsdag""",
  """recurrence.dayNames.thursday""": """Torsdag""",
  """recurrence.dayNames.friday""": """Fredag""",
  """recurrence.dayNames.saturday""": """Laurdag""",
  """recurrence.dayNames.sunday""": """Sundag""",
  """recurrence.dayAbbr.mo""": """Må""",
  """recurrence.dayAbbr.tu""": """Ty""",
  """recurrence.dayAbbr.we""": """On""",
  """recurrence.dayAbbr.th""": """To""",
  """recurrence.dayAbbr.fr""": """Fr""",
  """recurrence.dayAbbr.sa""": """La""",
  """recurrence.dayAbbr.su""": """Su""",
  """sync.offline""": """Fråkobla""",
  """sync.syncing""": """Synkroniserer endringar…""",
  """sync.syncError""": """Kunne ikkje synkronisere endringar""",
  """sync.retry""": """Prøv igjen no""",
  """markdownEditor.editSource""": """Markdown""",
  """markdownEditor.editRich""": """Rik tekst""",
};
