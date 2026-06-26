// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:i18n/i18n.dart' as i18n;
import 'messages.i18n.dart';

String get _languageCode => 'he';
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

class MessagesHe extends Messages {
  const MessagesHe();
  String get locale => "he";
  String get languageCode => "he";
  CommonMessagesHe get common => CommonMessagesHe(this);
  LoginMessagesHe get login => LoginMessagesHe(this);
  HomeMessagesHe get home => HomeMessagesHe(this);
  NavMessagesHe get nav => NavMessagesHe(this);
  OnboardingMessagesHe get onboarding => OnboardingMessagesHe(this);
  NotificationsIntroMessagesHe get notificationsIntro =>
      NotificationsIntroMessagesHe(this);
  AboutMessagesHe get about => AboutMessagesHe(this);
  SettingsMessagesHe get settings => SettingsMessagesHe(this);
  NotificationsMessagesHe get notifications => NotificationsMessagesHe(this);
  CategoriesMessagesHe get categories => CategoriesMessagesHe(this);
  ChecklistsMessagesHe get checklists => ChecklistsMessagesHe(this);
  NotesWallMessagesHe get notesWall => NotesWallMessagesHe(this);
  PhotoBoardMessagesHe get photoBoard => PhotoBoardMessagesHe(this);
  ShareMessagesHe get share => ShareMessagesHe(this);
  RecurrenceMessagesHe get recurrence => RecurrenceMessagesHe(this);
  SyncMessagesHe get sync => SyncMessagesHe(this);
}

class CommonMessagesHe extends CommonMessages {
  final MessagesHe _parent;
  const CommonMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "ביטול"
  /// ```
  String get cancel => """ביטול""";

  /// ```dart
  /// "מחיקה"
  /// ```
  String get delete => """מחיקה""";

  /// ```dart
  /// "שמירה"
  /// ```
  String get save => """שמירה""";

  /// ```dart
  /// "נסה שוב"
  /// ```
  String get retry => """נסה שוב""";

  /// ```dart
  /// "רענון"
  /// ```
  String get refresh => """רענון""";

  /// ```dart
  /// "התנתקות"
  /// ```
  String get logout => """התנתקות""";

  /// ```dart
  /// "טוען..."
  /// ```
  String get loading => """טוען...""";

  /// ```dart
  /// "שגיאה"
  /// ```
  String get error => """שגיאה""";

  /// ```dart
  /// "העתק"
  /// ```
  String get copy => """העתק""";

  /// ```dart
  /// "הועתק"
  /// ```
  String get copied => """הועתק""";

  /// ```dart
  /// "סיום"
  /// ```
  String get closeDialog => """סיום""";

  /// ```dart
  /// "הסר"
  /// ```
  String get remove => """הסר""";
}

class LoginMessagesHe extends LoginMessages {
  final MessagesHe _parent;
  const LoginMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "התחבר לשרת ה-Nextcloud שלך"
  /// ```
  String get connectToNextcloud => """התחבר לשרת ה-Nextcloud שלך""";

  /// ```dart
  /// "כתובת השרת"
  /// ```
  String get serverUrl => """כתובת השרת""";

  /// ```dart
  /// "cloud.example.com"
  /// ```
  String get serverUrlHint => """cloud.example.com""";

  /// ```dart
  /// "התחבר"
  /// ```
  String get connect => """התחבר""";

  /// ```dart
  /// """
  /// ממתין לאימות...
  /// אנא השלם את ההתחברות בדפדפן.
  /// """
  /// ```
  String get waitingForAuth => """ממתין לאימות...
אנא השלם את ההתחברות בדפדפן.""";

  /// ```dart
  /// "לא ניתן להתחבר לשרת. אנא בדוק את הכתובת."
  /// ```
  String get couldNotConnect => """לא ניתן להתחבר לשרת. אנא בדוק את הכתובת.""";

  /// ```dart
  /// "ההתחברות נכשלה. אנא נסה שוב."
  /// ```
  String get loginFailed => """ההתחברות נכשלה. אנא נסה שוב.""";

  /// ```dart
  /// "הצג פרטים"
  /// ```
  String get seeDetails => """הצג פרטים""";

  /// ```dart
  /// "פרטי השגיאה"
  /// ```
  String get errorDetailsTitle => """פרטי השגיאה""";

  /// ```dart
  /// "תעודה לא מהימנה"
  /// ```
  String get untrustedCertTitle => """תעודה לא מהימנה""";

  /// ```dart
  /// "${host} משתמש בתעודה שהמכשיר שלך לא סומך עליה — בדרך כלל מפני שהיא חתומה עצמית. ודא שהטביעה הדיגיטלית תואמת לזו שמנהל השרת שלך נתן לך לפני שתאשר אותה."
  /// ```
  String untrustedCertBody(String host) =>
      """${host} משתמש בתעודה שהמכשיר שלך לא סומך עליה — בדרך כלל מפני שהיא חתומה עצמית. ודא שהטביעה הדיגיטלית תואמת לזו שמנהל השרת שלך נתן לך לפני שתאשר אותה.""";

  /// ```dart
  /// "סמוך על התעודה הזו רק אם אתה מזהה את הטביעה הדיגיטלית. סמיכה על תעודה לא צפויה עלולה לאפשר לתוקף לקרוא את התעבורה שלך."
  /// ```
  String get untrustedCertWarning =>
      """סמוך על התעודה הזו רק אם אתה מזהה את הטביעה הדיגיטלית. סמיכה על תעודה לא צפויה עלולה לאפשר לתוקף לקרוא את התעבורה שלך.""";

  /// ```dart
  /// "סמוך על התעודה"
  /// ```
  String get trustCertificate => """סמוך על התעודה""";

  /// ```dart
  /// "טביעה דיגיטלית SHA-256"
  /// ```
  String get certFingerprint => """טביעה דיגיטלית SHA-256""";

  /// ```dart
  /// "נושא"
  /// ```
  String get certSubject => """נושא""";

  /// ```dart
  /// "מנפיק"
  /// ```
  String get certIssuer => """מנפיק""";

  /// ```dart
  /// "בתוקף"
  /// ```
  String get certValidity => """בתוקף""";

  /// ```dart
  /// "התחברות באמצעות סיסמת יישום"
  /// ```
  String get useAppPassword => """התחברות באמצעות סיסמת יישום""";

  /// ```dart
  /// "התחברות באמצעות הדפדפן"
  /// ```
  String get useBrowserLogin => """התחברות באמצעות הדפדפן""";

  /// ```dart
  /// "שם משתמש"
  /// ```
  String get username => """שם משתמש""";

  /// ```dart
  /// "סיסמת יישום"
  /// ```
  String get appPassword => """סיסמת יישום""";

  /// ```dart
  /// "צרו סיסמת יישום ב‑Nextcloud תחת הגדרות → אבטחה → מכשירים והפעלות. השתמשו בזה אם התחברות הדפדפן לא נפתחת או שהשרת שלכם משתמש באישור בחתימה עצמית."
  /// ```
  String get appPasswordHelp =>
      """צרו סיסמת יישום ב‑Nextcloud תחת הגדרות → אבטחה → מכשירים והפעלות. השתמשו בזה אם התחברות הדפדפן לא נפתחת או שהשרת שלכם משתמש באישור בחתימה עצמית.""";

  /// ```dart
  /// "אנא הזינו שם משתמש וסיסמת יישום."
  /// ```
  String get appPasswordMissing => """אנא הזינו שם משתמש וסיסמת יישום.""";

  /// ```dart
  /// "התחברות"
  /// ```
  String get signIn => """התחברות""";

  /// ```dart
  /// "לא ניתן להגיע לשרת. בדקו את הכתובת ואת חיבור הרשת או ה‑VPN שלכם."
  /// ```
  String get couldNotReachServer =>
      """לא ניתן להגיע לשרת. בדקו את הכתובת ואת חיבור הרשת או ה‑VPN שלכם.""";

  /// ```dart
  /// "השרת לא הגיב בזמן. בדקו את חיבור הרשת או ה‑VPN שלכם ונסו שוב."
  /// ```
  String get connectionTimeout =>
      """השרת לא הגיב בזמן. בדקו את חיבור הרשת או ה‑VPN שלכם ונסו שוב.""";

  /// ```dart
  /// "לא ניתן היה לקרוא את אישור השרת כדי לאמת אותו. ייתכן שהחיבור אינו יציב או שהשרת אינו זמין."
  /// ```
  String get certProbeFailed =>
      """לא ניתן היה לקרוא את אישור השרת כדי לאמת אותו. ייתכן שהחיבור אינו יציב או שהשרת אינו זמין.""";
}

class HomeMessagesHe extends HomeMessages {
  final MessagesHe _parent;
  const HomeMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "אין בתים עדיין."
  /// ```
  String get noHouses => """אין בתים עדיין.""";

  /// ```dart
  /// "בתים הם מרחבים משותפים למשק הבית שלך. צור את הבית הראשון שלך כדי להתחיל להוסיף רשימות, תמונות והערות."
  /// ```
  String get noHousesBody =>
      """בתים הם מרחבים משותפים למשק הבית שלך. צור את הבית הראשון שלך כדי להתחיל להוסיף רשימות, תמונות והערות.""";

  /// ```dart
  /// "צור בית"
  /// ```
  String get createHouse => """צור בית""";

  /// ```dart
  /// "שם הבית"
  /// ```
  String get houseName => """שם הבית""";

  /// ```dart
  /// "תיאור (אופציונלי)"
  /// ```
  String get houseDescription => """תיאור (אופציונלי)""";

  /// ```dart
  /// "יצירת הבית נכשלה."
  /// ```
  String get createHouseFailed => """יצירת הבית נכשלה.""";

  /// ```dart
  /// "טעינת הבתים נכשלה."
  /// ```
  String get failedToLoadHouses => """טעינת הבתים נכשלה.""";

  /// ```dart
  /// "Pantry לא מותקן"
  /// ```
  String get serverAppMissingTitle => """Pantry לא מותקן""";

  /// ```dart
  /// "אפליקציה זו היא לקוח עבור אפליקציית Pantry ב-Nextcloud. נראה ש-Pantry עדיין לא מותקן בשרת שלך. בקש ממנהל המערכת להתקין אותו מחנות האפליקציות של Nextcloud, או התקן בעצמך אם יש לך הרשאות מנהל."
  /// ```
  String get serverAppMissingBody =>
      """אפליקציה זו היא לקוח עבור אפליקציית Pantry ב-Nextcloud. נראה ש-Pantry עדיין לא מותקן בשרת שלך. בקש ממנהל המערכת להתקין אותו מחנות האפליקציות של Nextcloud, או התקן בעצמך אם יש לך הרשאות מנהל.""";

  /// ```dart
  /// "פתח אפליקציות Nextcloud"
  /// ```
  String get openAppStore => """פתח אפליקציות Nextcloud""";

  /// ```dart
  /// "למד עוד"
  /// ```
  String get learnMore => """למד עוד""";
}

class NavMessagesHe extends NavMessages {
  final MessagesHe _parent;
  const NavMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "רשימות"
  /// ```
  String get checklists => """רשימות""";

  /// ```dart
  /// "לוח תמונות"
  /// ```
  String get photoBoard => """לוח תמונות""";

  /// ```dart
  /// "קיר הערות"
  /// ```
  String get notesWall => """קיר הערות""";
}

class OnboardingMessagesHe extends OnboardingMessages {
  final MessagesHe _parent;
  const OnboardingMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "הבא"
  /// ```
  String get next => """הבא""";

  /// ```dart
  /// "חזור"
  /// ```
  String get back => """חזור""";

  /// ```dart
  /// "דלג"
  /// ```
  String get skip => """דלג""";

  /// ```dart
  /// "בואו נתחיל"
  /// ```
  String get done => """בואו נתחיל""";

  /// ```dart
  /// "שלב ${current} מתוך ${total}"
  /// ```
  String stepLabel(int current, int total) =>
      """שלב ${current} מתוך ${total}""";

  /// ```dart
  /// "ברוכים הבאים ל-Pantry"
  /// ```
  String get welcomeNewTitle => """ברוכים הבאים ל-Pantry""";

  /// ```dart
  /// "בוא נעבור סיור קצר על איך Pantry עובד כדי שתפיק ממנו את המקסימום."
  /// ```
  String get welcomeNewBody =>
      """בוא נעבור סיור קצר על איך Pantry עובד כדי שתפיק ממנו את המקסימום.""";

  /// ```dart
  /// "מה חדש"
  /// ```
  String get welcomeUpdateTitle => """מה חדש""";

  /// ```dart
  /// "מאז הפעם האחרונה שפתחת את Pantry נוספו כמה דברים חדשים. הנה סקירה קצרה של מה שהשתנה."
  /// ```
  String get welcomeUpdateBody =>
      """מאז הפעם האחרונה שפתחת את Pantry נוספו כמה דברים חדשים. הנה סקירה קצרה של מה שהשתנה.""";

  /// ```dart
  /// "הרשימות בעיצוב חדש"
  /// ```
  String get checklistsRedesignTitle => """הרשימות בעיצוב חדש""";

  /// ```dart
  /// "עמוד הרשימות נבנה מחדש מהיסוד — מבנה נקי יותר, דרך מהירה להוסיף פריטים ופעולות מהירות על כל שורה. הדפים הבאים יסבירו מה חדש."
  /// ```
  String get checklistsRedesignBody =>
      """עמוד הרשימות נבנה מחדש מהיסוד — מבנה נקי יותר, דרך מהירה להוסיף פריטים ופעולות מהירות על כל שורה. הדפים הבאים יסבירו מה חדש.""";

  /// ```dart
  /// "החלף רשימות מלמעלה"
  /// ```
  String get checklistSelectorTitle => """החלף רשימות מלמעלה""";

  /// ```dart
  /// "הקש על שם הרשימה או על הסמל למעלה כדי להחליף בין רשימות או ליצור רשימה חדשה."
  /// ```
  String get checklistSelectorBody =>
      """הקש על שם הרשימה או על הסמל למעלה כדי להחליף בין רשימות או ליצור רשימה חדשה.""";

  /// ```dart
  /// "הקש כדי להחליף רשימות"
  /// ```
  String get checklistSelectorHint => """הקש כדי להחליף רשימות""";

  /// ```dart
  /// "מצרכים"
  /// ```
  String get mockListGroceries => """מצרכים""";

  /// ```dart
  /// "חומרי בניין"
  /// ```
  String get mockListHardware => """חומרי בניין""";

  /// ```dart
  /// "טיול סוף שבוע"
  /// ```
  String get mockListWeekend => """טיול סוף שבוע""";

  /// ```dart
  /// "${count} פריטים"
  /// ```
  String mockItemCountSummary(int count) => """${count} פריטים""";

  /// ```dart
  /// "רשימה חדשה"
  /// ```
  String get newListLabel => """רשימה חדשה""";

  /// ```dart
  /// "החלק פריטים כדי לנהל אותם"
  /// ```
  String get swipeActionsTitle => """החלק פריטים כדי לנהל אותם""";

  /// ```dart
  /// "החלק פריט ברשימה משמאל לימין כדי לחשוף פעולות מהירות לעריכה, העברה או מחיקה."
  /// ```
  String get swipeActionsBody =>
      """החלק פריט ברשימה משמאל לימין כדי לחשוף פעולות מהירות לעריכה, העברה או מחיקה.""";

  /// ```dart
  /// "החלק ימינה"
  /// ```
  String get swipeActionsHint => """החלק ימינה""";

  /// ```dart
  /// "החלק שמאלה"
  /// ```
  String get swipeActionsHintBack => """החלק שמאלה""";

  /// ```dart
  /// "פעולות מהירות לכל פריט"
  /// ```
  String get quickActionsTitle => """פעולות מהירות לכל פריט""";

  /// ```dart
  /// "לכל פריט יש כפתורי פעולה בקצה — לחץ עליהם כדי לערוך, להעביר או למחוק את הפריט בלי לפתוח אותו."
  /// ```
  String get quickActionsBody =>
      """לכל פריט יש כפתורי פעולה בקצה — לחץ עליהם כדי לערוך, להעביר או למחוק את הפריט בלי לפתוח אותו.""";

  /// ```dart
  /// "דרך מהירה יותר להוסיף פריטים"
  /// ```
  String get addItemsTitle => """דרך מהירה יותר להוסיף פריטים""";

  /// ```dart
  /// "הקש על השדה בתחתית כדי להקליד פריט חדש, ואז סמן אותו עם קטגוריה, כמות, סוג או תמונה באמצעות הצ'יפים שמעליו."
  /// ```
  String get addItemsBody =>
      """הקש על השדה בתחתית כדי להקליד פריט חדש, ואז סמן אותו עם קטגוריה, כמות, סוג או תמונה באמצעות הצ'יפים שמעליו.""";

  /// ```dart
  /// "מצרכים"
  /// ```
  String get mockComposeListName => """מצרכים""";

  /// ```dart
  /// "הסתר את כרטיס ההתקדמות"
  /// ```
  String get progressHeroTitle => """הסתר את כרטיס ההתקדמות""";

  /// ```dart
  /// "לא צריך את טבעת ההתקדמות בראש הרשימה? החלק אותה החוצה."
  /// ```
  String get progressHeroBody =>
      """לא צריך את טבעת ההתקדמות בראש הרשימה? החלק אותה החוצה.""";

  /// ```dart
  /// "אפשר להחזיר אותה בכל עת דרך תפריט הרשימה ← ${toggle}."
  /// ```
  String progressHeroBringBack(String toggle) =>
      """אפשר להחזיר אותה בכל עת דרך תפריט הרשימה ← ${toggle}.""";

  /// ```dart
  /// "החלק כדי להסיר"
  /// ```
  String get progressHeroHint => """החלק כדי להסיר""";

  /// ```dart
  /// "הסתר את כרטיס ההתקדמות"
  /// ```
  String get progressHeroDismissTitle => """הסתר את כרטיס ההתקדמות""";

  /// ```dart
  /// "לא צריך את טבעת ההתקדמות למעלה? לחץ על ה-X בכרטיס כדי להסתיר אותו."
  /// ```
  String get progressHeroDismissBody =>
      """לא צריך את טבעת ההתקדמות למעלה? לחץ על ה-X בכרטיס כדי להסתיר אותו.""";

  /// ```dart
  /// "הצמד רשימות למסך הבית"
  /// ```
  String get pinnedListsTitle => """הצמד רשימות למסך הבית""";

  /// ```dart
  /// "הוסף את הווידג'ט של Pantry למסך הבית כדי לראות במבט אחד כמה פריטים נותרו ברשימות המועדפות עליך — בלי לפתוח את האפליקציה."
  /// ```
  String get pinnedListsBody =>
      """הוסף את הווידג'ט של Pantry למסך הבית כדי לראות במבט אחד כמה פריטים נותרו ברשימות המועדפות עליך — בלי לפתוח את האפליקציה.""";

  /// ```dart
  /// "פתח רשימה, הקש על ${menu} בפינה העליונה, ובחר ${action}. רשימות מוצמדות מופיעות בווידג'ט; בטל הצמדה כדי להסתיר אותן."
  /// ```
  String pinnedListsHow(String menu, String action) =>
      """פתח רשימה, הקש על ${menu} בפינה העליונה, ובחר ${action}. רשימות מוצמדות מופיעות בווידג'ט; בטל הצמדה כדי להסתיר אותן.""";

  /// ```dart
  /// "התפריט"
  /// ```
  String get pinnedListsMenuLabel => """התפריט""";

  /// ```dart
  /// "הצמד רשימה"
  /// ```
  String get pinnedListsActionLabel => """הצמד רשימה""";

  /// ```dart
  /// "Pantry"
  /// ```
  String get pinnedListsWidgetTitle => """Pantry""";

  /// ```dart
  /// "${_plural(count, one: 'פריט אחד נותר', many: '${count} נותרו')}"
  /// ```
  String pinnedListsWidgetItemsLeft(int count) =>
      """${_plural(count, one: 'פריט אחד נותר', many: '${count} נותרו')}""";

  /// ```dart
  /// "הכל בוצע"
  /// ```
  String get pinnedListsWidgetEmpty => """הכל בוצע""";

  /// ```dart
  /// "השאר הערות חשובות בראש הקיר"
  /// ```
  String get pinnedNotesTitle => """השאר הערות חשובות בראש הקיר""";

  /// ```dart
  /// "הצמד הערה מתפריט שלוש הנקודות שלה כדי שתישאר בראש קיר ההערות, מעל הערות חדשות יותר."
  /// ```
  String get pinnedNotesBody =>
      """הצמד הערה מתפריט שלוש הנקודות שלה כדי שתישאר בראש קיר ההערות, מעל הערות חדשות יותר.""";

  /// ```dart
  /// "סיסמת Wi-Fi"
  /// ```
  String get mockPinnedNoteTitle => """סיסמת Wi-Fi""";

  /// ```dart
  /// """
  /// רשת: בית
  /// סיסמה: pantry-rocks
  /// """
  /// ```
  String get mockPinnedNoteContent => """רשת: בית
סיסמה: pantry-rocks""";

  /// ```dart
  /// "עגבניות"
  /// ```
  String get mockItemName => """עגבניות""";

  /// ```dart
  /// "x2"
  /// ```
  String get mockItemQuantity => """x2""";

  /// ```dart
  /// "ירקות"
  /// ```
  String get mockItemCategory => """ירקות""";

  /// ```dart
  /// "נורות"
  /// ```
  String get mockHardwareItemName => """נורות""";

  /// ```dart
  /// "חלב"
  /// ```
  String get mockBulkItemThird => """חלב""";

  /// ```dart
  /// "לחם"
  /// ```
  String get mockBulkItemFourth => """לחם""";

  /// ```dart
  /// "הכל בתצוגה אחת"
  /// ```
  String get allListsTitle => """הכל בתצוגה אחת""";

  /// ```dart
  /// "פתח את התצוגה כל הרשימות ממחליף הרשימות כדי לראות פריטים מכל הרשימות ביחד. כשמוסיפים פריט מכאן, הטופס שואל לאיזו רשימה להוסיף אותו — בוחרים אותה מצ'יפ הרשימה."
  /// ```
  String get allListsBody =>
      """פתח את התצוגה כל הרשימות ממחליף הרשימות כדי לראות פריטים מכל הרשימות ביחד. כשמוסיפים פריט מכאן, הטופס שואל לאיזו רשימה להוסיף אותו — בוחרים אותה מצ'יפ הרשימה.""";

  /// ```dart
  /// "הוספת פריטים רבים בבת אחת"
  /// ```
  String get bulkAddTitle => """הוספת פריטים רבים בבת אחת""";

  /// ```dart
  /// "הפעל את מתג מרובה והשדה הופך לתיבת קלט רב-שורתית — כל שורה הופכת לפריט נפרד. נוח כשמדביקים רשימה או רושמים קנייה שלמה בבת אחת."
  /// ```
  String get bulkAddBody =>
      """הפעל את מתג מרובה והשדה הופך לתיבת קלט רב-שורתית — כל שורה הופכת לפריט נפרד. נוח כשמדביקים רשימה או רושמים קנייה שלמה בבת אחת.""";
  DevOnboardingMessagesHe get dev => DevOnboardingMessagesHe(this);
}

class DevOnboardingMessagesHe extends DevOnboardingMessages {
  final OnboardingMessagesHe _parent;
  const DevOnboardingMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "הצג היכרות"
  /// ```
  String get showOnboarding => """הצג היכרות""";

  /// ```dart
  /// "דמה גרסה אחרונה שנצפתה"
  /// ```
  String get pickLastSeenTitle => """דמה גרסה אחרונה שנצפתה""";

  /// ```dart
  /// "בחר באיזו גרסה המכשיר יעמיד פנים שהוא ראה לאחרונה, וההיכרות תרוץ משם."
  /// ```
  String get pickLastSeenBody =>
      """בחר באיזו גרסה המכשיר יעמיד פנים שהוא ראה לאחרונה, וההיכרות תרוץ משם.""";

  /// ```dart
  /// "מעולם לא נצפה (משתמש חדש)"
  /// ```
  String get neverSeen => """מעולם לא נצפה (משתמש חדש)""";

  /// ```dart
  /// "הפעל את כל התכונות"
  /// ```
  String get forceAllFeatures => """הפעל את כל התכונות""";
}

class NotificationsIntroMessagesHe extends NotificationsIntroMessages {
  final MessagesHe _parent;
  const NotificationsIntroMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "הישאר מעודכן"
  /// ```
  String get title => """הישאר מעודכן""";

  /// ```dart
  /// "Pantry יכול להודיע לך כשבני משק הבית מוסיפים פריטים לרשימות, מעלים תמונות או משאירים הערות. ההתראות נשלפות מהשרת שלך — שום דבר לא עובר דרך Google או צדדים שלישיים."
  /// ```
  String get body =>
      """Pantry יכול להודיע לך כשבני משק הבית מוסיפים פריטים לרשימות, מעלים תמונות או משאירים הערות. ההתראות נשלפות מהשרת שלך — שום דבר לא עובר דרך Google או צדדים שלישיים.""";

  /// ```dart
  /// "התראות על פעילות במשק הבית"
  /// ```
  String get bullet1 => """התראות על פעילות במשק הבית""";

  /// ```dart
  /// "נשלפות ישירות מהשרת שלך"
  /// ```
  String get bullet2 => """נשלפות ישירות מהשרת שלך""";

  /// ```dart
  /// "עובד גם כשהאפליקציה סגורה"
  /// ```
  String get bullet3 => """עובד גם כשהאפליקציה סגורה""";

  /// ```dart
  /// "הפעל התראות"
  /// ```
  String get enableButton => """הפעל התראות""";

  /// ```dart
  /// "לא עכשיו"
  /// ```
  String get skipButton => """לא עכשיו""";

  /// ```dart
  /// "ההרשאה נדחתה"
  /// ```
  String get permissionDeniedTitle => """ההרשאה נדחתה""";

  /// ```dart
  /// "תוכל להפעיל התראות מאוחר יותר בהגדרות האפליקציה. אם המכשיר חוסם אותן, תצטרך לאשר אותן קודם בהגדרות המערכת."
  /// ```
  String get permissionDeniedBody =>
      """תוכל להפעיל התראות מאוחר יותר בהגדרות האפליקציה. אם המכשיר חוסם אותן, תצטרך לאשר אותן קודם בהגדרות המערכת.""";

  /// ```dart
  /// "אישור"
  /// ```
  String get ok => """אישור""";
}

class AboutMessagesHe extends AboutMessages {
  final MessagesHe _parent;
  const AboutMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "אודות"
  /// ```
  String get title => """אודות""";

  /// ```dart
  /// "מפתח"
  /// ```
  String get developer => """מפתח""";

  /// ```dart
  /// "דוא"ל"
  /// ```
  String get email => """דוא"ל""";

  /// ```dart
  /// "קוד מקור"
  /// ```
  String get repository => """קוד מקור""";

  /// ```dart
  /// "אפליקציית Nextcloud"
  /// ```
  String get nextcloudApp => """אפליקציית Nextcloud""";

  /// ```dart
  /// "מדיניות פרטיות"
  /// ```
  String get privacyPolicy => """מדיניות פרטיות""";

  /// ```dart
  /// "משוב ובעיות"
  /// ```
  String get feedback => """משוב ובעיות""";

  /// ```dart
  /// "שרת Nextcloud"
  /// ```
  String get serverVersion => """שרת Nextcloud""";

  /// ```dart
  /// "Pantry בשרת"
  /// ```
  String get pantryServerVersion => """Pantry בשרת""";

  /// ```dart
  /// "לא ידוע"
  /// ```
  String get versionUnknown => """לא ידוע""";

  /// ```dart
  /// "קנו לי קפה"
  /// ```
  String get buyMeACoffee => """קנו לי קפה""";
}

class SettingsMessagesHe extends SettingsMessages {
  final MessagesHe _parent;
  const SettingsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "הגדרות האפליקציה"
  /// ```
  String get title => """הגדרות האפליקציה""";

  /// ```dart
  /// "כללי"
  /// ```
  String get generalSection => """כללי""";

  /// ```dart
  /// "ממשק"
  /// ```
  String get interfaceSection => """ממשק""";

  /// ```dart
  /// "פעולת ברירת מחדל בלחיצה"
  /// ```
  String get defaultItemTapAction => """פעולת ברירת מחדל בלחיצה""";

  /// ```dart
  /// "מה קורה כאשר לוחצים על שורת פריט."
  /// ```
  String get defaultItemTapActionBody =>
      """מה קורה כאשר לוחצים על שורת פריט.""";
  ItemTapActionNamesSettingsMessagesHe get itemTapActionNames =>
      ItemTapActionNamesSettingsMessagesHe(this);

  /// ```dart
  /// "הצג רווח בין קטגוריות בפריטי הרשימה"
  /// ```
  String get categorySpacing => """הצג רווח בין קטגוריות בפריטי הרשימה""";

  /// ```dart
  /// "מוצג רק בעת מיון לפי קטגוריה"
  /// ```
  String get categorySpacingBody => """מוצג רק בעת מיון לפי קטגוריה""";
  CategorySpacingNamesSettingsMessagesHe get categorySpacingNames =>
      CategorySpacingNamesSettingsMessagesHe(this);

  /// ```dart
  /// "שימוש חוזר בפריטים קיימים בעת הוספה"
  /// ```
  String get reuseExistingItems => """שימוש חוזר בפריטים קיימים בעת הוספה""";

  /// ```dart
  /// "כשמנסים להוסיף פריט שכבר קיים ברשימה, השתמש בפריט הקיים."
  /// ```
  String get reuseExistingItemsBody =>
      """כשמנסים להוסיף פריט שכבר קיים ברשימה, השתמש בפריט הקיים.""";
  ReuseExistingItemsNamesSettingsMessagesHe get reuseExistingItemsNames =>
      ReuseExistingItemsNamesSettingsMessagesHe(this);

  /// ```dart
  /// "סדר ניווט"
  /// ```
  String get navOrderTitle => """סדר ניווט""";

  /// ```dart
  /// "שינוי הסדר של לשוניות הניווט. הפריט הראשון הוא זה שנפתח עם הפעלת האפליקציה."
  /// ```
  String get navOrderSubtitle =>
      """שינוי הסדר של לשוניות הניווט. הפריט הראשון הוא זה שנפתח עם הפעלת האפליקציה.""";

  /// ```dart
  /// "גרור כדי לשנות את הסדר. הפריט הראשון הוא הקטע שנפתח עם הפעלת האפליקציה."
  /// ```
  String get navOrderBody =>
      """גרור כדי לשנות את הסדר. הפריט הראשון הוא הקטע שנפתח עם הפעלת האפליקציה.""";

  /// ```dart
  /// "נפתח עם הפעלת האפליקציה"
  /// ```
  String get navOrderDefaultHint => """נפתח עם הפעלת האפליקציה""";

  /// ```dart
  /// "איפוס"
  /// ```
  String get navOrderReset => """איפוס""";

  /// ```dart
  /// "שפה"
  /// ```
  String get language => """שפה""";
  LanguageNamesSettingsMessagesHe get languageNames =>
      LanguageNamesSettingsMessagesHe(this);

  /// ```dart
  /// "ערכת נושא"
  /// ```
  String get theme => """ערכת נושא""";
  ThemeNamesSettingsMessagesHe get themeNames =>
      ThemeNamesSettingsMessagesHe(this);

  /// ```dart
  /// "התראות"
  /// ```
  String get notificationsSection => """התראות""";

  /// ```dart
  /// "הפעל התראות"
  /// ```
  String get enableNotifications => """הפעל התראות""";

  /// ```dart
  /// "הצג התראות כשבני משק הבית מוסיפים או מעדכנים תוכן."
  /// ```
  String get enableNotificationsBody =>
      """הצג התראות כשבני משק הבית מוסיפים או מעדכנים תוכן.""";

  /// ```dart
  /// "בדוק פעילות חדשה"
  /// ```
  String get pollInterval => """בדוק פעילות חדשה""";

  /// ```dart
  /// "כל 15 דקות"
  /// ```
  String get pollInterval15m => """כל 15 דקות""";

  /// ```dart
  /// "כל 30 דקות"
  /// ```
  String get pollInterval30m => """כל 30 דקות""";

  /// ```dart
  /// "כל שעה"
  /// ```
  String get pollInterval1h => """כל שעה""";

  /// ```dart
  /// "כל שעתיים"
  /// ```
  String get pollInterval2h => """כל שעתיים""";

  /// ```dart
  /// "כל 6 שעות"
  /// ```
  String get pollInterval6h => """כל 6 שעות""";

  /// ```dart
  /// "הרשאת ההתראות נדחתה. הפעל אותה בהגדרות המערכת."
  /// ```
  String get permissionDenied =>
      """הרשאת ההתראות נדחתה. הפעל אותה בהגדרות המערכת.""";
}

class ItemTapActionNamesSettingsMessagesHe
    extends ItemTapActionNamesSettingsMessages {
  final SettingsMessagesHe _parent;
  const ItemTapActionNamesSettingsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "סמן כהושלם"
  /// ```
  String get done => """סמן כהושלם""";

  /// ```dart
  /// "צפייה"
  /// ```
  String get view => """צפייה""";

  /// ```dart
  /// "עריכה"
  /// ```
  String get edit => """עריכה""";

  /// ```dart
  /// "ללא"
  /// ```
  String get none => """ללא""";
}

class CategorySpacingNamesSettingsMessagesHe
    extends CategorySpacingNamesSettingsMessages {
  final SettingsMessagesHe _parent;
  const CategorySpacingNamesSettingsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "מושבת"
  /// ```
  String get disabled => """מושבת""";

  /// ```dart
  /// "רווח"
  /// ```
  String get space => """רווח""";

  /// ```dart
  /// "קו מפריד"
  /// ```
  String get divider => """קו מפריד""";
}

class ReuseExistingItemsNamesSettingsMessagesHe
    extends ReuseExistingItemsNamesSettingsMessages {
  final SettingsMessagesHe _parent;
  const ReuseExistingItemsNamesSettingsMessagesHe(this._parent)
    : super(_parent);

  /// ```dart
  /// "תמיד לשאול"
  /// ```
  String get ask => """תמיד לשאול""";

  /// ```dart
  /// "תמיד להשתמש מחדש"
  /// ```
  String get reuse => """תמיד להשתמש מחדש""";

  /// ```dart
  /// "לעולם לא להשתמש מחדש"
  /// ```
  String get never => """לעולם לא להשתמש מחדש""";
}

class LanguageNamesSettingsMessagesHe extends LanguageNamesSettingsMessages {
  final SettingsMessagesHe _parent;
  const LanguageNamesSettingsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "ברירת מחדל (שפת המערכת)"
  /// ```
  String get system => """ברירת מחדל (שפת המערכת)""";

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

class ThemeNamesSettingsMessagesHe extends ThemeNamesSettingsMessages {
  final SettingsMessagesHe _parent;
  const ThemeNamesSettingsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "ברירת מחדל (המערכת)"
  /// ```
  String get system => """ברירת מחדל (המערכת)""";

  /// ```dart
  /// "בהיר"
  /// ```
  String get light => """בהיר""";

  /// ```dart
  /// "כהה"
  /// ```
  String get dark => """כהה""";
}

class NotificationsMessagesHe extends NotificationsMessages {
  final MessagesHe _parent;
  const NotificationsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "התראות"
  /// ```
  String get title => """התראות""";

  /// ```dart
  /// "אין התראות חדשות."
  /// ```
  String get empty => """אין התראות חדשות.""";

  /// ```dart
  /// "טעינת ההתראות נכשלה."
  /// ```
  String get failedToLoad => """טעינת ההתראות נכשלה.""";

  /// ```dart
  /// "סגור הכל"
  /// ```
  String get dismissAll => """סגור הכל""";

  /// ```dart
  /// "הרגע"
  /// ```
  String get justNow => """הרגע""";

  /// ```dart
  /// "לפני ${count} ד׳"
  /// ```
  String minutesAgo(int count) => """לפני ${count} ד׳""";

  /// ```dart
  /// "לפני ${count} שע׳"
  /// ```
  String hoursAgo(int count) => """לפני ${count} שע׳""";

  /// ```dart
  /// "לפני ${count} י׳"
  /// ```
  String daysAgo(int count) => """לפני ${count} י׳""";
}

class CategoriesMessagesHe extends CategoriesMessages {
  final MessagesHe _parent;
  const CategoriesMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "ניהול קטגוריות"
  /// ```
  String get manageTitle => """ניהול קטגוריות""";

  /// ```dart
  /// "אין קטגוריות עדיין."
  /// ```
  String get noCategories => """אין קטגוריות עדיין.""";

  /// ```dart
  /// "עריכת קטגוריה"
  /// ```
  String get editTitle => """עריכת קטגוריה""";

  /// ```dart
  /// "קטגוריה חדשה"
  /// ```
  String get addTitle => """קטגוריה חדשה""";

  /// ```dart
  /// "שם"
  /// ```
  String get name => """שם""";

  /// ```dart
  /// "אייקון"
  /// ```
  String get icon => """אייקון""";

  /// ```dart
  /// "צבע"
  /// ```
  String get color => """צבע""";

  /// ```dart
  /// "שמירת הקטגוריה נכשלה."
  /// ```
  String get saveFailed => """שמירת הקטגוריה נכשלה.""";

  /// ```dart
  /// "מחיקת הקטגוריה נכשלה."
  /// ```
  String get deleteFailed => """מחיקת הקטגוריה נכשלה.""";

  /// ```dart
  /// "למחוק את הקטגוריה?"
  /// ```
  String get deleteConfirm => """למחוק את הקטגוריה?""";

  /// ```dart
  /// "פריטים בקטגוריה זו יהפכו ללא קטגוריה. לא ניתן לבטל פעולה זו."
  /// ```
  String get deleteConfirmBody =>
      """פריטים בקטגוריה זו יהפכו ללא קטגוריה. לא ניתן לבטל פעולה זו.""";
  SortCategoriesMessagesHe get sort => SortCategoriesMessagesHe(this);
}

class SortCategoriesMessagesHe extends SortCategoriesMessages {
  final CategoriesMessagesHe _parent;
  const SortCategoriesMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "שם א'–ת'"
  /// ```
  String get nameAZ => """שם א'–ת'""";

  /// ```dart
  /// "שם ת'–א'"
  /// ```
  String get nameZA => """שם ת'–א'""";

  /// ```dart
  /// "מותאם אישית"
  /// ```
  String get custom => """מותאם אישית""";
}

class ChecklistsMessagesHe extends ChecklistsMessages {
  final MessagesHe _parent;
  const ChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "קטגוריות"
  /// ```
  String get categories => """קטגוריות""";

  /// ```dart
  /// "אין רשימות עדיין."
  /// ```
  String get noChecklists => """אין רשימות עדיין.""";

  /// ```dart
  /// "אין פריטים ברשימה."
  /// ```
  String get noItems => """אין פריטים ברשימה.""";

  /// ```dart
  /// "אין פריטים תואמים לחיפוש."
  /// ```
  String get noSearchResults => """אין פריטים תואמים לחיפוש.""";

  /// ```dart
  /// "הקלד לסינון..."
  /// ```
  String get searchHint => """הקלד לסינון...""";

  /// ```dart
  /// "הכל"
  /// ```
  String get allCategories => """הכל""";

  /// ```dart
  /// "הכל"
  /// ```
  String get allListsChip => """הכל""";

  /// ```dart
  /// "סינון לפי רשימה"
  /// ```
  String get filterByList => """סינון לפי רשימה""";

  /// ```dart
  /// "סינון לפי קטגוריה"
  /// ```
  String get filterByCategory => """סינון לפי קטגוריה""";

  /// ```dart
  /// "טעינת הרשימות נכשלה."
  /// ```
  String get failedToLoad => """טעינת הרשימות נכשלה.""";

  /// ```dart
  /// "טעינת הפריטים נכשלה."
  /// ```
  String get failedToLoadItems => """טעינת הפריטים נכשלה.""";

  /// ```dart
  /// "הושלמו ($count)"
  /// ```
  String completedCount(int count) => """הושלמו ($count)""";

  /// ```dart
  /// "ערוך פריט"
  /// ```
  String get editItem => """ערוך פריט""";

  /// ```dart
  /// "הסר פריט"
  /// ```
  String get removeItem => """הסר פריט""";

  /// ```dart
  /// "העבר לרשימה"
  /// ```
  String get moveItem => """העבר לרשימה""";

  /// ```dart
  /// "העברת הפריט נכשלה."
  /// ```
  String get moveFailed => """העברת הפריט נכשלה.""";

  /// ```dart
  /// "העתק לרשימה"
  /// ```
  String get copyItem => """העתק לרשימה""";

  /// ```dart
  /// "העתקת הפריט נכשלה."
  /// ```
  String get copyFailed => """העתקת הפריט נכשלה.""";

  /// ```dart
  /// "הפריט הועתק"
  /// ```
  String get itemCopied => """הפריט הועתק""";

  /// ```dart
  /// "הפריט סומן כהושלם"
  /// ```
  String get itemMarkedDone => """הפריט סומן כהושלם""";

  /// ```dart
  /// "הפריט הוסר"
  /// ```
  String get itemRemoved => """הפריט הוסר""";

  /// ```dart
  /// "בטל"
  /// ```
  String get undo => """בטל""";

  /// ```dart
  /// "הצג אשפה"
  /// ```
  String get viewTrash => """הצג אשפה""";

  /// ```dart
  /// "צא מהאשפה"
  /// ```
  String get exitTrash => """צא מהאשפה""";

  /// ```dart
  /// "הצג מי הוסיף כל פריט"
  /// ```
  String get showAddedBy => """הצג מי הוסיף כל פריט""";

  /// ```dart
  /// "הצג כרטיס התקדמות ברשימה הזו"
  /// ```
  String get showProgressHero => """הצג כרטיס התקדמות ברשימה הזו""";

  /// ```dart
  /// "הוסף על ידי $name"
  /// ```
  String addedBy(String name) => """הוסף על ידי $name""";

  /// ```dart
  /// "אשפה"
  /// ```
  String get trashTitle => """אשפה""";

  /// ```dart
  /// "האשפה ריקה."
  /// ```
  String get noTrashedItems => """האשפה ריקה.""";

  /// ```dart
  /// "רוקן אשפה"
  /// ```
  String get emptyTrash => """רוקן אשפה""";

  /// ```dart
  /// "לרוקן את האשפה?"
  /// ```
  String get emptyTrashConfirm => """לרוקן את האשפה?""";

  /// ```dart
  /// "כל הפריטים באשפה יימחקו לצמיתות. לא ניתן לבטל פעולה זו."
  /// ```
  String get emptyTrashConfirmBody =>
      """כל הפריטים באשפה יימחקו לצמיתות. לא ניתן לבטל פעולה זו.""";

  /// ```dart
  /// "ריקון האשפה נכשל."
  /// ```
  String get emptyTrashFailed => """ריקון האשפה נכשל.""";

  /// ```dart
  /// "שחזר"
  /// ```
  String get restoreItem => """שחזר""";

  /// ```dart
  /// "מחק"
  /// ```
  String get permanentlyDeleteItem => """מחק""";

  /// ```dart
  /// "למחוק את הפריט לצמיתות?"
  /// ```
  String get permanentlyDeleteConfirm => """למחוק את הפריט לצמיתות?""";

  /// ```dart
  /// "לא ניתן לבטל פעולה זו."
  /// ```
  String get permanentlyDeleteConfirmBody => """לא ניתן לבטל פעולה זו.""";

  /// ```dart
  /// "שחזור הפריט נכשל."
  /// ```
  String get restoreFailed => """שחזור הפריט נכשל.""";

  /// ```dart
  /// "מחיקת הפריט נכשלה."
  /// ```
  String get permanentlyDeleteFailed => """מחיקת הפריט נכשלה.""";

  /// ```dart
  /// "הפריט שוחזר"
  /// ```
  String get itemRestored => """הפריט שוחזר""";

  /// ```dart
  /// "רשימות שנמחקו"
  /// ```
  String get viewListsTrash => """רשימות שנמחקו""";

  /// ```dart
  /// "רשימות שנמחקו"
  /// ```
  String get listsTrashTitle => """רשימות שנמחקו""";

  /// ```dart
  /// "טעינת סל המיחזור נכשלה."
  /// ```
  String get failedToLoadTrash => """טעינת סל המיחזור נכשלה.""";

  /// ```dart
  /// "אין רשימות שנמחקו."
  /// ```
  String get listTrashEmpty => """אין רשימות שנמחקו.""";

  /// ```dart
  /// "הצמד רשימה"
  /// ```
  String get pinList => """הצמד רשימה""";

  /// ```dart
  /// "בטל הצמדה"
  /// ```
  String get unpinList => """בטל הצמדה""";

  /// ```dart
  /// "הסר רשימה"
  /// ```
  String get removeList => """הסר רשימה""";

  /// ```dart
  /// "ערוך רשימה"
  /// ```
  String get editList => """ערוך רשימה""";

  /// ```dart
  /// "ערוך רשימה"
  /// ```
  String get editListTitle => """ערוך רשימה""";

  /// ```dart
  /// "שמור שינויים"
  /// ```
  String get saveListButton => """שמור שינויים""";

  /// ```dart
  /// "עדכון הרשימה נכשל."
  /// ```
  String get updateListFailed => """עדכון הרשימה נכשל.""";

  /// ```dart
  /// "להסיר את הרשימה?"
  /// ```
  String get removeListConfirm => """להסיר את הרשימה?""";

  /// ```dart
  /// "להסיר את הרשימה "$name"? ניתן לשחזר אותה מסל המיחזור."
  /// ```
  String removeListConfirmBody(String name) =>
      """להסיר את הרשימה "$name"? ניתן לשחזר אותה מסל המיחזור.""";

  /// ```dart
  /// "הסרת הרשימה נכשלה."
  /// ```
  String get removeListFailed => """הסרת הרשימה נכשלה.""";

  /// ```dart
  /// "שחזר רשימה"
  /// ```
  String get restoreList => """שחזר רשימה""";

  /// ```dart
  /// "מחק לצמיתות"
  /// ```
  String get permanentlyDeleteList => """מחק לצמיתות""";

  /// ```dart
  /// "הרשימה הוסרה"
  /// ```
  String get listRemoved => """הרשימה הוסרה""";

  /// ```dart
  /// "רשימה חדשה"
  /// ```
  String get createList => """רשימה חדשה""";

  /// ```dart
  /// "שם הרשימה"
  /// ```
  String get listName => """שם הרשימה""";

  /// ```dart
  /// "תיאור (אופציונלי)"
  /// ```
  String get listDescription => """תיאור (אופציונלי)""";

  /// ```dart
  /// "אייקון"
  /// ```
  String get listIcon => """אייקון""";

  /// ```dart
  /// "יצירת הרשימה נכשלה."
  /// ```
  String get createListFailed => """יצירת הרשימה נכשלה.""";
  ViewItemChecklistsMessagesHe get viewItem =>
      ViewItemChecklistsMessagesHe(this);
  ItemFormChecklistsMessagesHe get itemForm =>
      ItemFormChecklistsMessagesHe(this);
  SortChecklistsMessagesHe get sort => SortChecklistsMessagesHe(this);

  /// ```dart
  /// "${_plural(count, one: 'פריט אחד נותר', many: '$count פריטים נותרו')}"
  /// ```
  String itemsLeft(int count) =>
      """${_plural(count, one: 'פריט אחד נותר', many: '$count פריטים נותרו')}""";

  /// ```dart
  /// "הכל בוצע 🎉"
  /// ```
  String get allDone => """הכל בוצע 🎉""";

  /// ```dart
  /// "$done מתוך $total בוצעו"
  /// ```
  String listProgress(int done, int total) => """$done מתוך $total בוצעו""";

  /// ```dart
  /// "הסתר כרטיס התקדמות"
  /// ```
  String get hideProgressHero => """הסתר כרטיס התקדמות""";

  /// ```dart
  /// "מיון"
  /// ```
  String get sortTooltip => """מיון""";

  /// ```dart
  /// "בוצעו · $count"
  /// ```
  String doneCount(int count) => """בוצעו · $count""";

  /// ```dart
  /// "הוסף אל $name…"
  /// ```
  String addToList(String name) => """הוסף אל $name…""";

  /// ```dart
  /// "הוסף את הפריט הראשון…"
  /// ```
  String get addFirstItem => """הוסף את הפריט הראשון…""";

  /// ```dart
  /// "אין פריטים ברשימה"
  /// ```
  String get noItemsTitle => """אין פריטים ברשימה""";

  /// ```dart
  /// "הוסף את הפריט הראשון בעזרת השורה למטה — קבע קטגוריה, כמות או לוח זמנים בעזרת הצ׳יפים."
  /// ```
  String get noItemsBody =>
      """הוסף את הפריט הראשון בעזרת השורה למטה — קבע קטגוריה, כמות או לוח זמנים בעזרת הצ׳יפים.""";

  /// ```dart
  /// "אין רשימות עדיין"
  /// ```
  String get noListsTitle => """אין רשימות עדיין""";

  /// ```dart
  /// "צור את הרשימה הראשונה שלך כדי להתחיל לעקוב אחר מצרכים, סידורים, משימות או כל דבר שמשק הבית צריך לזכור."
  /// ```
  String get noListsBody =>
      """צור את הרשימה הראשונה שלך כדי להתחיל לעקוב אחר מצרכים, סידורים, משימות או כל דבר שמשק הבית צריך לזכור.""";

  /// ```dart
  /// "צור את הרשימה הראשונה"
  /// ```
  String get createFirstList => """צור את הרשימה הראשונה""";

  /// ```dart
  /// "הרשימות שלך"
  /// ```
  String get yourChecklists => """הרשימות שלך""";

  /// ```dart
  /// "${_plural(count, one: 'רשימה אחת', many: '$count רשימות')}"
  /// ```
  String listsCount(int count) =>
      """${_plural(count, one: 'רשימה אחת', many: '$count רשימות')}""";

  /// ```dart
  /// "${_plural(count, one: 'פריט אחד', many: '$count פריטים')}"
  /// ```
  String itemsSummary(int count) =>
      """${_plural(count, one: 'פריט אחד', many: '$count פריטים')}""";

  /// ```dart
  /// "הכל בוצע · 0 נותרו"
  /// ```
  String get allDoneSummary => """הכל בוצע · 0 נותרו""";

  /// ```dart
  /// "רשימה חדשה"
  /// ```
  String get newChecklist => """רשימה חדשה""";

  /// ```dart
  /// "צור רשימה"
  /// ```
  String get createListButton => """צור רשימה""";

  /// ```dart
  /// "צפה"
  /// ```
  String get view => """צפה""";

  /// ```dart
  /// "צפייה"
  /// ```
  String get swipeView => """צפייה""";

  /// ```dart
  /// "עריכה"
  /// ```
  String get swipeEdit => """עריכה""";

  /// ```dart
  /// "העברה"
  /// ```
  String get swipeMove => """העברה""";

  /// ```dart
  /// "העתקה"
  /// ```
  String get swipeCopy => """העתקה""";

  /// ```dart
  /// "הסר"
  /// ```
  String get swipeDelete => """הסר""";

  /// ```dart
  /// "תצוגת רשימה"
  /// ```
  String get viewList => """תצוגת רשימה""";

  /// ```dart
  /// "תצוגת כרטיסים"
  /// ```
  String get viewCards => """תצוגת כרטיסים""";

  /// ```dart
  /// "צבע"
  /// ```
  String get listColor => """צבע""";
  ItemTypesChecklistsMessagesHe get itemTypes =>
      ItemTypesChecklistsMessagesHe(this);
  ComposeChecklistsMessagesHe get compose => ComposeChecklistsMessagesHe(this);
  ReuseChecklistsMessagesHe get reuse => ReuseChecklistsMessagesHe(this);

  /// ```dart
  /// "כל הרשימות"
  /// ```
  String get allLists => """כל הרשימות""";

  /// ```dart
  /// "פריטים מכל הרשימות"
  /// ```
  String get allListsSubtitle => """פריטים מכל הרשימות""";

  /// ```dart
  /// "הוסף פריט…"
  /// ```
  String get addToAnyList => """הוסף פריט…""";

  /// ```dart
  /// "להוסיף לאיזו רשימה?"
  /// ```
  String get pickListTitle => """להוסיף לאיזו רשימה?""";
  MarkdownChecklistsMessagesHe get markdown =>
      MarkdownChecklistsMessagesHe(this);
}

class ViewItemChecklistsMessagesHe extends ViewItemChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const ViewItemChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "כמות:"
  /// ```
  String get quantity => """כמות:""";

  /// ```dart
  /// "קטגוריה:"
  /// ```
  String get category => """קטגוריה:""";

  /// ```dart
  /// "חזרה:"
  /// ```
  String get recurrence => """חזרה:""";

  /// ```dart
  /// "מועד הבא:"
  /// ```
  String get nextDue => """מועד הבא:""";

  /// ```dart
  /// "מועד הבא (מהשלמה):"
  /// ```
  String get nextDueFromCompletion => """מועד הבא (מהשלמה):""";

  /// ```dart
  /// "באיחור"
  /// ```
  String get overdue => """באיחור""";

  /// ```dart
  /// "כמות"
  /// ```
  String get quantityLabel => """כמות""";

  /// ```dart
  /// "סוג"
  /// ```
  String get typeLabel => """סוג""";

  /// ```dart
  /// "תיאור"
  /// ```
  String get descriptionLabel => """תיאור""";

  /// ```dart
  /// "לא נוסף תיאור."
  /// ```
  String get noDescription => """לא נוסף תיאור.""";

  /// ```dart
  /// "נוסף על-ידי $name · $time"
  /// ```
  String addedByMeta(String name, String time) =>
      """נוסף על-ידי $name · $time""";

  /// ```dart
  /// "נוסף על-ידך · $time"
  /// ```
  String addedByYouMeta(String time) => """נוסף על-ידך · $time""";

  /// ```dart
  /// "נוסף $time"
  /// ```
  String addedMeta(String time) => """נוסף $time""";

  /// ```dart
  /// "ממש עכשיו"
  /// ```
  String get relJustNow => """ממש עכשיו""";

  /// ```dart
  /// "היום"
  /// ```
  String get relToday => """היום""";

  /// ```dart
  /// "אתמול"
  /// ```
  String get relYesterday => """אתמול""";

  /// ```dart
  /// "לפני $n ימים"
  /// ```
  String relDaysAgo(int n) => """לפני $n ימים""";

  /// ```dart
  /// "${_plural(n, one: 'לפני שבוע', many: 'לפני $n שבועות')}"
  /// ```
  String relWeeksAgo(int n) =>
      """${_plural(n, one: 'לפני שבוע', many: 'לפני $n שבועות')}""";

  /// ```dart
  /// "${_plural(n, one: 'לפני חודש', many: 'לפני $n חודשים')}"
  /// ```
  String relMonthsAgo(int n) =>
      """${_plural(n, one: 'לפני חודש', many: 'לפני $n חודשים')}""";

  /// ```dart
  /// "${_plural(n, one: 'לפני שנה', many: 'לפני $n שנים')}"
  /// ```
  String relYearsAgo(int n) =>
      """${_plural(n, one: 'לפני שנה', many: 'לפני $n שנים')}""";
}

class ItemFormChecklistsMessagesHe extends ItemFormChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const ItemFormChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "הוסף פריט"
  /// ```
  String get addTitle => """הוסף פריט""";

  /// ```dart
  /// "ערוך פריט"
  /// ```
  String get editTitle => """ערוך פריט""";

  /// ```dart
  /// "שם הפריט"
  /// ```
  String get name => """שם הפריט""";

  /// ```dart
  /// "תיאור"
  /// ```
  String get description => """תיאור""";

  /// ```dart
  /// "כמות"
  /// ```
  String get quantity => """כמות""";

  /// ```dart
  /// "קטגוריה"
  /// ```
  String get category => """קטגוריה""";

  /// ```dart
  /// "ללא"
  /// ```
  String get noCategory => """ללא""";

  /// ```dart
  /// "אין קטגוריות זמינות."
  /// ```
  String get noCategories => """אין קטגוריות זמינות.""";

  /// ```dart
  /// "קטגוריה חדשה"
  /// ```
  String get createCategory => """קטגוריה חדשה""";

  /// ```dart
  /// "שם"
  /// ```
  String get categoryName => """שם""";

  /// ```dart
  /// "אייקון"
  /// ```
  String get categoryIcon => """אייקון""";

  /// ```dart
  /// "צבע"
  /// ```
  String get categoryColor => """צבע""";

  /// ```dart
  /// "הקטגוריה נוצרה."
  /// ```
  String get categoryCreated => """הקטגוריה נוצרה.""";

  /// ```dart
  /// "יצירת הקטגוריה נכשלה."
  /// ```
  String get categoryCreateFailed => """יצירת הקטגוריה נכשלה.""";

  /// ```dart
  /// "חזרה"
  /// ```
  String get repeat => """חזרה""";

  /// ```dart
  /// "פעם אחת"
  /// ```
  String get once => """פעם אחת""";

  /// ```dart
  /// "מחק את הפריט ברגע שהוא מסומן כבוצע."
  /// ```
  String get onceDescription => """מחק את הפריט ברגע שהוא מסומן כבוצע.""";

  /// ```dart
  /// "תמונה"
  /// ```
  String get image => """תמונה""";

  /// ```dart
  /// "הוסף תמונה"
  /// ```
  String get addImage => """הוסף תמונה""";

  /// ```dart
  /// "צלם תמונה"
  /// ```
  String get takePhoto => """צלם תמונה""";

  /// ```dart
  /// "בחר תמונה"
  /// ```
  String get chooseImage => """בחר תמונה""";

  /// ```dart
  /// "החלף"
  /// ```
  String get replaceImage => """החלף""";

  /// ```dart
  /// "הסר"
  /// ```
  String get removeImage => """הסר""";

  /// ```dart
  /// "שמירת הפריט נכשלה."
  /// ```
  String get saveFailed => """שמירת הפריט נכשלה.""";

  /// ```dart
  /// "מחיקת הפריט נכשלה."
  /// ```
  String get deleteFailed => """מחיקת הפריט נכשלה.""";

  /// ```dart
  /// "למחוק את הפריט?"
  /// ```
  String get deleteConfirm => """למחוק את הפריט?""";

  /// ```dart
  /// "שמור שינויים"
  /// ```
  String get save => """שמור שינויים""";

  /// ```dart
  /// "הוסף תיאור (אופציונלי)"
  /// ```
  String get descHint => """הוסף תיאור (אופציונלי)""";

  /// ```dart
  /// "שנה"
  /// ```
  String get categoryChange => """שנה""";

  /// ```dart
  /// "בחר אחת"
  /// ```
  String get categoryPick => """בחר אחת""";

  /// ```dart
  /// "פריט ללא שם"
  /// ```
  String get untitledItem => """פריט ללא שם""";

  /// ```dart
  /// "פריט קבוע"
  /// ```
  String get typeStaple => """פריט קבוע""";

  /// ```dart
  /// "פריט חד-פעמי"
  /// ```
  String get typeOnce => """פריט חד-פעמי""";

  /// ```dart
  /// "חוזר"
  /// ```
  String get typeRecurring => """חוזר""";
}

class SortChecklistsMessagesHe extends SortChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const SortChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "החדש ביותר"
  /// ```
  String get newestFirst => """החדש ביותר""";

  /// ```dart
  /// "הישן ביותר"
  /// ```
  String get oldestFirst => """הישן ביותר""";

  /// ```dart
  /// "שם א–ת"
  /// ```
  String get nameAZ => """שם א–ת""";

  /// ```dart
  /// "שם ת–א"
  /// ```
  String get nameZA => """שם ת–א""";

  /// ```dart
  /// "לפי קטגוריה"
  /// ```
  String get category => """לפי קטגוריה""";

  /// ```dart
  /// "מותאם אישית"
  /// ```
  String get custom => """מותאם אישית""";
}

class ItemTypesChecklistsMessagesHe extends ItemTypesChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const ItemTypesChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "סוג פריט"
  /// ```
  String get label => """סוג פריט""";

  /// ```dart
  /// "קבוע"
  /// ```
  String get staple => """קבוע""";

  /// ```dart
  /// "נשאר ברשימה אחרי שמסמנים אותו כבוצע"
  /// ```
  String get stapleBody => """נשאר ברשימה אחרי שמסמנים אותו כבוצע""";

  /// ```dart
  /// "חד-פעמי"
  /// ```
  String get onceTime => """חד-פעמי""";

  /// ```dart
  /// "מוסר מהרשימה ברגע שמסמנים אותו כבוצע"
  /// ```
  String get onceTimeBody => """מוסר מהרשימה ברגע שמסמנים אותו כבוצע""";

  /// ```dart
  /// "חוזר"
  /// ```
  String get recurring => """חוזר""";

  /// ```dart
  /// "חוזר ברשימה לפי לוח זמנים"
  /// ```
  String get recurringBody => """חוזר ברשימה לפי לוח זמנים""";

  /// ```dart
  /// "שבועי"
  /// ```
  String get weekly => """שבועי""";

  /// ```dart
  /// "כל $n שבועות"
  /// ```
  String everyNWeeks(int n) => """כל $n שבועות""";
}

class ComposeChecklistsMessagesHe extends ComposeChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const ComposeChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "קטגוריה"
  /// ```
  String get chipCategory => """קטגוריה""";

  /// ```dart
  /// "כמות"
  /// ```
  String get chipQuantity => """כמות""";

  /// ```dart
  /// "סוג פריט"
  /// ```
  String get chipType => """סוג פריט""";

  /// ```dart
  /// "תמונה"
  /// ```
  String get chipImage => """תמונה""";

  /// ```dart
  /// "תיאור"
  /// ```
  String get chipDescription => """תיאור""";

  /// ```dart
  /// "הערות, הוראות, קישורים…"
  /// ```
  String get descHint => """הערות, הוראות, קישורים…""";

  /// ```dart
  /// "למשל 2 ליטר, 500 ג׳"
  /// ```
  String get qtyHint => """למשל 2 ליטר, 500 ג׳""";

  /// ```dart
  /// "＋ / − משנים את המספר ושומרים על היחידה."
  /// ```
  String get qtyStepperHelp => """＋ / − משנים את המספר ושומרים על היחידה.""";

  /// ```dart
  /// "ללא"
  /// ```
  String get none => """ללא""";

  /// ```dart
  /// "כל"
  /// ```
  String get every => """כל""";

  /// ```dart
  /// "שבוע"
  /// ```
  String get week => """שבוע""";

  /// ```dart
  /// "שבועות"
  /// ```
  String get weeks => """שבועות""";

  /// ```dart
  /// "רשימה"
  /// ```
  String get chipTargetList => """רשימה""";

  /// ```dart
  /// "בחר רשימה"
  /// ```
  String get pickTargetList => """בחר רשימה""";

  /// ```dart
  /// "מרובה"
  /// ```
  String get multiple => """מרובה""";

  /// ```dart
  /// "הפרד פריטים בשורות חדשות"
  /// ```
  String get multipleHint => """הפרד פריטים בשורות חדשות""";
}

class ReuseChecklistsMessagesHe extends ReuseChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const ReuseChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "הפריט כבר קיים"
  /// ```
  String get dialogTitle => """הפריט כבר קיים""";

  /// ```dart
  /// "פריט בשם "$name" כבר קיים ברשימה. להשתמש בו במקום להוסיף פריט חדש?"
  /// ```
  String dialogBody(String name) =>
      """פריט בשם "$name" כבר קיים ברשימה. להשתמש בו במקום להוסיף פריט חדש?""";

  /// ```dart
  /// "השתמש בקיים"
  /// ```
  String get reuseExisting => """השתמש בקיים""";

  /// ```dart
  /// "הוסף בכל זאת"
  /// ```
  String get addAnyway => """הוסף בכל זאת""";

  /// ```dart
  /// "נעשה שימוש חוזר בפריט “$name”"
  /// ```
  String reusedSnack(String name) => """נעשה שימוש חוזר בפריט “$name”""";
}

class MarkdownChecklistsMessagesHe extends MarkdownChecklistsMessages {
  final ChecklistsMessagesHe _parent;
  const MarkdownChecklistsMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "יוצא בתאריך $date"
  /// ```
  String exported(String date) => """יוצא בתאריך $date""";

  /// ```dart
  /// "ללא קטגוריה"
  /// ```
  String get uncategorized => """ללא קטגוריה""";

  /// ```dart
  /// "ייצוא ל-Markdown"
  /// ```
  String get exportTitle => """ייצוא ל-Markdown""";

  /// ```dart
  /// "ייבוא מ-Markdown"
  /// ```
  String get importTitle => """ייבוא מ-Markdown""";

  /// ```dart
  /// "לכלול פריטים שהושלמו"
  /// ```
  String get includeCompleted => """לכלול פריטים שהושלמו""";

  /// ```dart
  /// "ערכו את הטקסט למטה כדי לשנות את הרשימה המיוצאת"
  /// ```
  String get editHint => """ערכו את הטקסט למטה כדי לשנות את הרשימה המיוצאת""";

  /// ```dart
  /// "העתקה"
  /// ```
  String get copy => """העתקה""";

  /// ```dart
  /// "הורדת .md"
  /// ```
  String get download => """הורדת .md""";

  /// ```dart
  /// "הועתק ללוח"
  /// ```
  String get copied => """הועתק ללוח""";

  /// ```dart
  /// "לא ניתן להעתיק ללוח"
  /// ```
  String get copyFailed => """לא ניתן להעתיק ללוח""";

  /// ```dart
  /// "סגירה"
  /// ```
  String get close => """סגירה""";

  /// ```dart
  /// "לא ניתן לייצא את הקובץ"
  /// ```
  String get shareFailed => """לא ניתן לייצא את הקובץ""";

  /// ```dart
  /// "העלאת קובץ .md"
  /// ```
  String get uploadFile => """העלאת קובץ .md""";

  /// ```dart
  /// "הדבקת Markdown"
  /// ```
  String get pasteLabel => """הדבקת Markdown""";

  /// ```dart
  /// "הדביקו כאן רשימת Markdown…"
  /// ```
  String get pastePlaceholder => """הדביקו כאן רשימת Markdown…""";

  /// ```dart
  /// "לא נמצאו פריטי רשימה בטקסט."
  /// ```
  String get noneFound => """לא נמצאו פריטי רשימה בטקסט.""";

  /// ```dart
  /// "בחירת הכול"
  /// ```
  String get selectAll => """בחירת הכול""";

  /// ```dart
  /// "ביטול בחירת הכול"
  /// ```
  String get deselectAll => """ביטול בחירת הכול""";

  /// ```dart
  /// "שימוש חוזר בפריטים קיימים במקום הוספת כפילויות"
  /// ```
  String get reuseExisting =>
      """שימוש חוזר בפריטים קיימים במקום הוספת כפילויות""";

  /// ```dart
  /// "ערכים שיחולו על כל פריט מיובא"
  /// ```
  String get defaultFields => """ערכים שיחולו על כל פריט מיובא""";

  /// ```dart
  /// "${_plural(count, one: 'נמצא פריט אחד', many: 'נמצאו $count פריטים')}"
  /// ```
  String itemsFound(int count) =>
      """${_plural(count, one: 'נמצא פריט אחד', many: 'נמצאו $count פריטים')}""";

  /// ```dart
  /// "${_plural(count, one: 'הוספת פריט אחד', many: 'הוספת $count פריטים')}"
  /// ```
  String addItems(int count) =>
      """${_plural(count, one: 'הוספת פריט אחד', many: 'הוספת $count פריטים')}""";

  /// ```dart
  /// "${_plural(count, one: 'יובא פריט אחד', many: 'יובאו $count פריטים')}"
  /// ```
  String imported(int count) =>
      """${_plural(count, one: 'יובא פריט אחד', many: 'יובאו $count פריטים')}""";
}

class NotesWallMessagesHe extends NotesWallMessages {
  final MessagesHe _parent;
  const NotesWallMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "אין הערות עדיין."
  /// ```
  String get noNotes => """אין הערות עדיין.""";

  /// ```dart
  /// "טעינת ההערות נכשלה."
  /// ```
  String get failedToLoad => """טעינת ההערות נכשלה.""";

  /// ```dart
  /// "שמירת ההערה נכשלה."
  /// ```
  String get saveFailed => """שמירת ההערה נכשלה.""";

  /// ```dart
  /// "מחיקת ההערה נכשלה."
  /// ```
  String get deleteFailed => """מחיקת ההערה נכשלה.""";

  /// ```dart
  /// "למחוק את ההערה?"
  /// ```
  String get deleteConfirm => """למחוק את ההערה?""";

  /// ```dart
  /// "למחוק ${_plural(count, one: 'הערה זו', many: '$count הערות')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """למחוק ${_plural(count, one: 'הערה זו', many: '$count הערות')}?""";

  /// ```dart
  /// "${_plural(count, one: 'הערה נמחקה', many: '$count הערות נמחקו')}"
  /// ```
  String noteRemoved(int count) =>
      """${_plural(count, one: 'הערה נמחקה', many: '$count הערות נמחקו')}""";

  /// ```dart
  /// "הצג סל מיחזור"
  /// ```
  String get viewTrash => """הצג סל מיחזור""";

  /// ```dart
  /// "צא מסל המיחזור"
  /// ```
  String get exitTrash => """צא מסל המיחזור""";

  /// ```dart
  /// "סל מיחזור"
  /// ```
  String get trashTitle => """סל מיחזור""";

  /// ```dart
  /// "סל המיחזור ריק."
  /// ```
  String get trashEmpty => """סל המיחזור ריק.""";

  /// ```dart
  /// "רוקן סל מיחזור"
  /// ```
  String get emptyTrash => """רוקן סל מיחזור""";

  /// ```dart
  /// "לרוקן את סל המיחזור?"
  /// ```
  String get emptyTrashConfirm => """לרוקן את סל המיחזור?""";

  /// ```dart
  /// "כל ההערות בסל המיחזור יימחקו לצמיתות. לא ניתן לבטל פעולה זו."
  /// ```
  String get emptyTrashConfirmBody =>
      """כל ההערות בסל המיחזור יימחקו לצמיתות. לא ניתן לבטל פעולה זו.""";

  /// ```dart
  /// "ריקון סל המיחזור נכשל."
  /// ```
  String get emptyTrashFailed => """ריקון סל המיחזור נכשל.""";

  /// ```dart
  /// "טעינת סל המיחזור נכשלה."
  /// ```
  String get failedToLoadTrash => """טעינת סל המיחזור נכשלה.""";

  /// ```dart
  /// "שחזר"
  /// ```
  String get restore => """שחזר""";

  /// ```dart
  /// "שחזור ההערה נכשל."
  /// ```
  String get restoreFailed => """שחזור ההערה נכשל.""";

  /// ```dart
  /// "מחק לצמיתות"
  /// ```
  String get permanentlyDelete => """מחק לצמיתות""";

  /// ```dart
  /// "למחוק את ההערה לצמיתות?"
  /// ```
  String get permanentlyDeleteConfirm => """למחוק את ההערה לצמיתות?""";

  /// ```dart
  /// "לא ניתן לבטל פעולה זו."
  /// ```
  String get permanentlyDeleteConfirmBody => """לא ניתן לבטל פעולה זו.""";

  /// ```dart
  /// "הערה חדשה"
  /// ```
  String get newNote => """הערה חדשה""";

  /// ```dart
  /// "עריכת הערה"
  /// ```
  String get editNote => """עריכת הערה""";

  /// ```dart
  /// "הצמדת הערה"
  /// ```
  String get pinNote => """הצמדת הערה""";

  /// ```dart
  /// "ביטול הצמדה"
  /// ```
  String get unpinNote => """ביטול הצמדה""";

  /// ```dart
  /// "כותרת"
  /// ```
  String get title => """כותרת""";

  /// ```dart
  /// "תוכן"
  /// ```
  String get content => """תוכן""";

  /// ```dart
  /// "צבע"
  /// ```
  String get color => """צבע""";
  SortNotesWallMessagesHe get sort => SortNotesWallMessagesHe(this);
}

class SortNotesWallMessagesHe extends SortNotesWallMessages {
  final NotesWallMessagesHe _parent;
  const SortNotesWallMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "החדש ביותר"
  /// ```
  String get newestFirst => """החדש ביותר""";

  /// ```dart
  /// "הישן ביותר"
  /// ```
  String get oldestFirst => """הישן ביותר""";

  /// ```dart
  /// "כותרת א–ת"
  /// ```
  String get titleAZ => """כותרת א–ת""";

  /// ```dart
  /// "כותרת ת–א"
  /// ```
  String get titleZA => """כותרת ת–א""";

  /// ```dart
  /// "מותאם אישית"
  /// ```
  String get custom => """מותאם אישית""";
}

class PhotoBoardMessagesHe extends PhotoBoardMessages {
  final MessagesHe _parent;
  const PhotoBoardMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "אין תמונות עדיין."
  /// ```
  String get noPhotos => """אין תמונות עדיין.""";

  /// ```dart
  /// "טעינת התמונות נכשלה."
  /// ```
  String get failedToLoad => """טעינת התמונות נכשלה.""";

  /// ```dart
  /// "העלאת התמונה נכשלה."
  /// ```
  String get uploadFailed => """העלאת התמונה נכשלה.""";

  /// ```dart
  /// "מחיקת התמונה נכשלה."
  /// ```
  String get deleteFailed => """מחיקת התמונה נכשלה.""";

  /// ```dart
  /// "למחוק את התמונה?"
  /// ```
  String get deleteConfirm => """למחוק את התמונה?""";

  /// ```dart
  /// "למחוק ${_plural(count, one: 'תמונה זו', many: '$count תמונות')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """למחוק ${_plural(count, one: 'תמונה זו', many: '$count תמונות')}?""";

  /// ```dart
  /// "${_plural(count, one: 'תמונה נמחקה', many: '$count תמונות נמחקו')}"
  /// ```
  String photoRemoved(int count) =>
      """${_plural(count, one: 'תמונה נמחקה', many: '$count תמונות נמחקו')}""";

  /// ```dart
  /// "הצג סל מיחזור"
  /// ```
  String get viewTrash => """הצג סל מיחזור""";

  /// ```dart
  /// "צא מסל המיחזור"
  /// ```
  String get exitTrash => """צא מסל המיחזור""";

  /// ```dart
  /// "סל מיחזור"
  /// ```
  String get trashTitle => """סל מיחזור""";

  /// ```dart
  /// "סל המיחזור ריק."
  /// ```
  String get trashEmpty => """סל המיחזור ריק.""";

  /// ```dart
  /// "רוקן סל מיחזור"
  /// ```
  String get emptyTrash => """רוקן סל מיחזור""";

  /// ```dart
  /// "לרוקן את סל המיחזור?"
  /// ```
  String get emptyTrashConfirm => """לרוקן את סל המיחזור?""";

  /// ```dart
  /// "כל התמונות בסל המיחזור יימחקו לצמיתות. לא ניתן לבטל פעולה זו."
  /// ```
  String get emptyTrashConfirmBody =>
      """כל התמונות בסל המיחזור יימחקו לצמיתות. לא ניתן לבטל פעולה זו.""";

  /// ```dart
  /// "ריקון סל המיחזור נכשל."
  /// ```
  String get emptyTrashFailed => """ריקון סל המיחזור נכשל.""";

  /// ```dart
  /// "טעינת סל המיחזור נכשלה."
  /// ```
  String get failedToLoadTrash => """טעינת סל המיחזור נכשלה.""";

  /// ```dart
  /// "שחזר"
  /// ```
  String get restore => """שחזר""";

  /// ```dart
  /// "שחזור התמונה נכשל."
  /// ```
  String get restoreFailed => """שחזור התמונה נכשל.""";

  /// ```dart
  /// "מחק לצמיתות"
  /// ```
  String get permanentlyDelete => """מחק לצמיתות""";

  /// ```dart
  /// "למחוק את התמונה לצמיתות?"
  /// ```
  String get permanentlyDeleteConfirm => """למחוק את התמונה לצמיתות?""";

  /// ```dart
  /// "לא ניתן לבטל פעולה זו."
  /// ```
  String get permanentlyDeleteConfirmBody => """לא ניתן לבטל פעולה זו.""";

  /// ```dart
  /// "מחק תיקייה"
  /// ```
  String get deleteFolder => """מחק תיקייה""";

  /// ```dart
  /// "למחוק את התיקייה?"
  /// ```
  String get deleteFolderConfirm => """למחוק את התיקייה?""";

  /// ```dart
  /// "העבר תמונות לשורש"
  /// ```
  String get deleteFolderKeepPhotos => """העבר תמונות לשורש""";

  /// ```dart
  /// "מחק תיקייה ותמונות"
  /// ```
  String get deleteFolderDeleteAll => """מחק תיקייה ותמונות""";

  /// ```dart
  /// "תיקייה חדשה"
  /// ```
  String get newFolder => """תיקייה חדשה""";

  /// ```dart
  /// "שם התיקייה"
  /// ```
  String get folderName => """שם התיקייה""";

  /// ```dart
  /// "שנה שם תיקייה"
  /// ```
  String get renameFolder => """שנה שם תיקייה""";

  /// ```dart
  /// "כיתוב"
  /// ```
  String get caption => """כיתוב""";

  /// ```dart
  /// "$count"
  /// ```
  String photoCount(int count) => """$count""";
  AddMenuPhotoBoardMessagesHe get addMenu => AddMenuPhotoBoardMessagesHe(this);
  SortPhotoBoardMessagesHe get sort => SortPhotoBoardMessagesHe(this);
}

class AddMenuPhotoBoardMessagesHe extends AddMenuPhotoBoardMessages {
  final PhotoBoardMessagesHe _parent;
  const AddMenuPhotoBoardMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "העלאת תמונות"
  /// ```
  String get upload => """העלאת תמונות""";

  /// ```dart
  /// "צילום תמונה"
  /// ```
  String get camera => """צילום תמונה""";

  /// ```dart
  /// "תיקייה חדשה"
  /// ```
  String get newFolder => """תיקייה חדשה""";
}

class SortPhotoBoardMessagesHe extends SortPhotoBoardMessages {
  final PhotoBoardMessagesHe _parent;
  const SortPhotoBoardMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "תיקיות קודם"
  /// ```
  String get foldersFirst => """תיקיות קודם""";

  /// ```dart
  /// "החדש ביותר"
  /// ```
  String get newestFirst => """החדש ביותר""";

  /// ```dart
  /// "הישן ביותר"
  /// ```
  String get oldestFirst => """הישן ביותר""";

  /// ```dart
  /// "כיתוב א–ת"
  /// ```
  String get captionAZ => """כיתוב א–ת""";

  /// ```dart
  /// "כיתוב ת–א"
  /// ```
  String get captionZA => """כיתוב ת–א""";

  /// ```dart
  /// "מותאם אישית"
  /// ```
  String get custom => """מותאם אישית""";
}

class ShareMessagesHe extends ShareMessages {
  final MessagesHe _parent;
  const ShareMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "שיתוף ל-Pantry"
  /// ```
  String get title => """שיתוף ל-Pantry""";

  /// ```dart
  /// "בחר בית"
  /// ```
  String get chooseHouse => """בחר בית""";

  /// ```dart
  /// "העלה אל"
  /// ```
  String get choosePhotoDestination => """העלה אל""";

  /// ```dart
  /// "לוח התמונות"
  /// ```
  String get photoBoardRoot => """לוח התמונות""";

  /// ```dart
  /// "תיקייה חדשה"
  /// ```
  String get newFolder => """תיקייה חדשה""";

  /// ```dart
  /// "שם התיקייה"
  /// ```
  String get newFolderName => """שם התיקייה""";

  /// ```dart
  /// "יצירת התיקייה נכשלה."
  /// ```
  String get failedToCreateFolder => """יצירת התיקייה נכשלה.""";

  /// ```dart
  /// "לא ניתן לפתוח את התוכן ששותף."
  /// ```
  String get failedToOpenShare => """לא ניתן לפתוח את התוכן ששותף.""";

  /// ```dart
  /// "אין בתים זמינים. צור תחילה בית."
  /// ```
  String get noHouses => """אין בתים זמינים. צור תחילה בית.""";
}

class RecurrenceMessagesHe extends RecurrenceMessages {
  final MessagesHe _parent;
  const RecurrenceMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "חזרה"
  /// ```
  String get title => """חזרה""";

  /// ```dart
  /// "הגדרות מוכנות"
  /// ```
  String get presets => """הגדרות מוכנות""";

  /// ```dart
  /// "יומי"
  /// ```
  String get daily => """יומי""";

  /// ```dart
  /// "שבועי"
  /// ```
  String get weekly => """שבועי""";

  /// ```dart
  /// "חודשי"
  /// ```
  String get monthly => """חודשי""";

  /// ```dart
  /// "כל"
  /// ```
  String get everyLabel => """כל""";

  /// ```dart
  /// "יחידה"
  /// ```
  String get unit => """יחידה""";

  /// ```dart
  /// "ימים"
  /// ```
  String get unitDays => """ימים""";

  /// ```dart
  /// "שבועות"
  /// ```
  String get unitWeeks => """שבועות""";

  /// ```dart
  /// "חודשים"
  /// ```
  String get unitMonths => """חודשים""";

  /// ```dart
  /// "שנים"
  /// ```
  String get unitYears => """שנים""";

  /// ```dart
  /// "חזור ב"
  /// ```
  String get repeatOn => """חזור ב""";

  /// ```dart
  /// "מסתיים"
  /// ```
  String get ends => """מסתיים""";

  /// ```dart
  /// "לעולם לא"
  /// ```
  String get never => """לעולם לא""";

  /// ```dart
  /// "אחרי"
  /// ```
  String get after => """אחרי""";

  /// ```dart
  /// "חזרות"
  /// ```
  String get occurrences => """חזרות""";

  /// ```dart
  /// "בתאריך"
  /// ```
  String get onDate => """בתאריך""";

  /// ```dart
  /// "חשב מרווח מרגע סימון הפריט"
  /// ```
  String get countFromCompletion => """חשב מרווח מרגע סימון הפריט""";

  /// ```dart
  /// "לוח הזמנים קבוע: הפריט יופיע מחדש במועד המתוכנן הבא, ללא קשר למתי סימנת אותו."
  /// ```
  String get countFromCompletionHintOff =>
      """לוח הזמנים קבוע: הפריט יופיע מחדש במועד המתוכנן הבא, ללא קשר למתי סימנת אותו.""";

  /// ```dart
  /// "המועד הבא נספר מרגע סימון הפריט, כך שהוא תמיד חוזר מרווח מלא לאחר ההשלמה."
  /// ```
  String get countFromCompletionHintOn =>
      """המועד הבא נספר מרגע סימון הפריט, כך שהוא תמיד חוזר מרווח מלא לאחר ההשלמה.""";

  /// ```dart
  /// "סיכום"
  /// ```
  String get summary => """סיכום""";

  /// ```dart
  /// "לא נקבע"
  /// ```
  String get notSet => """לא נקבע""";

  /// ```dart
  /// "נקבע"
  /// ```
  String get set => """נקבע""";

  /// ```dart
  /// "כל $unit"
  /// ```
  String every(String unit) => """כל $unit""";

  /// ```dart
  /// "כל $unit"
  /// ```
  String everyButton(String unit) => """כל $unit""";

  /// ```dart
  /// "ב$days"
  /// ```
  String onDays(String days) => """ב$days""";

  /// ```dart
  /// "${_plural(count, one: 'יום', two: 'יומיים', many: '$count ימים')}"
  /// ```
  String day(int count) =>
      """${_plural(count, one: 'יום', two: 'יומיים', many: '$count ימים')}""";

  /// ```dart
  /// "${_plural(count, one: 'שבוע', two: 'שבועיים', many: '$count שבועות')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'שבוע', two: 'שבועיים', many: '$count שבועות')}""";

  /// ```dart
  /// "${_plural(count, one: 'חודש', two: 'חודשיים', many: '$count חודשים')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'חודש', two: 'חודשיים', many: '$count חודשים')}""";

  /// ```dart
  /// "${_plural(count, one: 'שנה', two: 'שנתיים', many: '$count שנים')}"
  /// ```
  String year(int count) =>
      """${_plural(count, one: 'שנה', two: 'שנתיים', many: '$count שנים')}""";
  DayNamesRecurrenceMessagesHe get dayNames =>
      DayNamesRecurrenceMessagesHe(this);
  DayAbbrRecurrenceMessagesHe get dayAbbr => DayAbbrRecurrenceMessagesHe(this);
}

class DayNamesRecurrenceMessagesHe extends DayNamesRecurrenceMessages {
  final RecurrenceMessagesHe _parent;
  const DayNamesRecurrenceMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "יום שני"
  /// ```
  String get monday => """יום שני""";

  /// ```dart
  /// "יום שלישי"
  /// ```
  String get tuesday => """יום שלישי""";

  /// ```dart
  /// "יום רביעי"
  /// ```
  String get wednesday => """יום רביעי""";

  /// ```dart
  /// "יום חמישי"
  /// ```
  String get thursday => """יום חמישי""";

  /// ```dart
  /// "יום שישי"
  /// ```
  String get friday => """יום שישי""";

  /// ```dart
  /// "שבת"
  /// ```
  String get saturday => """שבת""";

  /// ```dart
  /// "יום ראשון"
  /// ```
  String get sunday => """יום ראשון""";
}

class DayAbbrRecurrenceMessagesHe extends DayAbbrRecurrenceMessages {
  final RecurrenceMessagesHe _parent;
  const DayAbbrRecurrenceMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "ב׳"
  /// ```
  String get mo => """ב׳""";

  /// ```dart
  /// "ג׳"
  /// ```
  String get tu => """ג׳""";

  /// ```dart
  /// "ד׳"
  /// ```
  String get we => """ד׳""";

  /// ```dart
  /// "ה׳"
  /// ```
  String get th => """ה׳""";

  /// ```dart
  /// "ו׳"
  /// ```
  String get fr => """ו׳""";

  /// ```dart
  /// "ש׳"
  /// ```
  String get sa => """ש׳""";

  /// ```dart
  /// "א׳"
  /// ```
  String get su => """א׳""";
}

class SyncMessagesHe extends SyncMessages {
  final MessagesHe _parent;
  const SyncMessagesHe(this._parent) : super(_parent);

  /// ```dart
  /// "לא מקוון"
  /// ```
  String get offline => """לא מקוון""";

  /// ```dart
  /// "מסנכרן שינויים…"
  /// ```
  String get syncing => """מסנכרן שינויים…""";

  /// ```dart
  /// "${_plural(count, one: 'שינוי אחד ממתין לסנכרון', two: '2 שינויים ממתינים לסנכרון', many: '${count} שינויים ממתינים לסנכרון')}"
  /// ```
  String pendingChanges(int count) =>
      """${_plural(count, one: 'שינוי אחד ממתין לסנכרון', two: '2 שינויים ממתינים לסנכרון', many: '${count} שינויים ממתינים לסנכרון')}""";

  /// ```dart
  /// "לא ניתן היה לסנכרן את השינויים"
  /// ```
  String get syncError => """לא ניתן היה לסנכרן את השינויים""";

  /// ```dart
  /// "נסה שוב"
  /// ```
  String get retry => """נסה שוב""";
}

Map<String, String> get messagesHeMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """ביטול""",
  """common.delete""": """מחיקה""",
  """common.save""": """שמירה""",
  """common.retry""": """נסה שוב""",
  """common.refresh""": """רענון""",
  """common.logout""": """התנתקות""",
  """common.loading""": """טוען...""",
  """common.error""": """שגיאה""",
  """common.copy""": """העתק""",
  """common.copied""": """הועתק""",
  """common.closeDialog""": """סיום""",
  """common.remove""": """הסר""",
  """login.connectToNextcloud""": """התחבר לשרת ה-Nextcloud שלך""",
  """login.serverUrl""": """כתובת השרת""",
  """login.serverUrlHint""": """cloud.example.com""",
  """login.connect""": """התחבר""",
  """login.waitingForAuth""": """ממתין לאימות...
אנא השלם את ההתחברות בדפדפן.""",
  """login.couldNotConnect""": """לא ניתן להתחבר לשרת. אנא בדוק את הכתובת.""",
  """login.loginFailed""": """ההתחברות נכשלה. אנא נסה שוב.""",
  """login.seeDetails""": """הצג פרטים""",
  """login.errorDetailsTitle""": """פרטי השגיאה""",
  """login.untrustedCertTitle""": """תעודה לא מהימנה""",
  """login.untrustedCertWarning""":
      """סמוך על התעודה הזו רק אם אתה מזהה את הטביעה הדיגיטלית. סמיכה על תעודה לא צפויה עלולה לאפשר לתוקף לקרוא את התעבורה שלך.""",
  """login.trustCertificate""": """סמוך על התעודה""",
  """login.certFingerprint""": """טביעה דיגיטלית SHA-256""",
  """login.certSubject""": """נושא""",
  """login.certIssuer""": """מנפיק""",
  """login.certValidity""": """בתוקף""",
  """login.useAppPassword""": """התחברות באמצעות סיסמת יישום""",
  """login.useBrowserLogin""": """התחברות באמצעות הדפדפן""",
  """login.username""": """שם משתמש""",
  """login.appPassword""": """סיסמת יישום""",
  """login.appPasswordHelp""":
      """צרו סיסמת יישום ב‑Nextcloud תחת הגדרות → אבטחה → מכשירים והפעלות. השתמשו בזה אם התחברות הדפדפן לא נפתחת או שהשרת שלכם משתמש באישור בחתימה עצמית.""",
  """login.appPasswordMissing""": """אנא הזינו שם משתמש וסיסמת יישום.""",
  """login.signIn""": """התחברות""",
  """login.couldNotReachServer""":
      """לא ניתן להגיע לשרת. בדקו את הכתובת ואת חיבור הרשת או ה‑VPN שלכם.""",
  """login.connectionTimeout""":
      """השרת לא הגיב בזמן. בדקו את חיבור הרשת או ה‑VPN שלכם ונסו שוב.""",
  """login.certProbeFailed""":
      """לא ניתן היה לקרוא את אישור השרת כדי לאמת אותו. ייתכן שהחיבור אינו יציב או שהשרת אינו זמין.""",
  """home.noHouses""": """אין בתים עדיין.""",
  """home.noHousesBody""":
      """בתים הם מרחבים משותפים למשק הבית שלך. צור את הבית הראשון שלך כדי להתחיל להוסיף רשימות, תמונות והערות.""",
  """home.createHouse""": """צור בית""",
  """home.houseName""": """שם הבית""",
  """home.houseDescription""": """תיאור (אופציונלי)""",
  """home.createHouseFailed""": """יצירת הבית נכשלה.""",
  """home.failedToLoadHouses""": """טעינת הבתים נכשלה.""",
  """home.serverAppMissingTitle""": """Pantry לא מותקן""",
  """home.serverAppMissingBody""":
      """אפליקציה זו היא לקוח עבור אפליקציית Pantry ב-Nextcloud. נראה ש-Pantry עדיין לא מותקן בשרת שלך. בקש ממנהל המערכת להתקין אותו מחנות האפליקציות של Nextcloud, או התקן בעצמך אם יש לך הרשאות מנהל.""",
  """home.openAppStore""": """פתח אפליקציות Nextcloud""",
  """home.learnMore""": """למד עוד""",
  """nav.checklists""": """רשימות""",
  """nav.photoBoard""": """לוח תמונות""",
  """nav.notesWall""": """קיר הערות""",
  """onboarding.next""": """הבא""",
  """onboarding.back""": """חזור""",
  """onboarding.skip""": """דלג""",
  """onboarding.done""": """בואו נתחיל""",
  """onboarding.welcomeNewTitle""": """ברוכים הבאים ל-Pantry""",
  """onboarding.welcomeNewBody""":
      """בוא נעבור סיור קצר על איך Pantry עובד כדי שתפיק ממנו את המקסימום.""",
  """onboarding.welcomeUpdateTitle""": """מה חדש""",
  """onboarding.welcomeUpdateBody""":
      """מאז הפעם האחרונה שפתחת את Pantry נוספו כמה דברים חדשים. הנה סקירה קצרה של מה שהשתנה.""",
  """onboarding.checklistsRedesignTitle""": """הרשימות בעיצוב חדש""",
  """onboarding.checklistsRedesignBody""":
      """עמוד הרשימות נבנה מחדש מהיסוד — מבנה נקי יותר, דרך מהירה להוסיף פריטים ופעולות מהירות על כל שורה. הדפים הבאים יסבירו מה חדש.""",
  """onboarding.checklistSelectorTitle""": """החלף רשימות מלמעלה""",
  """onboarding.checklistSelectorBody""":
      """הקש על שם הרשימה או על הסמל למעלה כדי להחליף בין רשימות או ליצור רשימה חדשה.""",
  """onboarding.checklistSelectorHint""": """הקש כדי להחליף רשימות""",
  """onboarding.mockListGroceries""": """מצרכים""",
  """onboarding.mockListHardware""": """חומרי בניין""",
  """onboarding.mockListWeekend""": """טיול סוף שבוע""",
  """onboarding.newListLabel""": """רשימה חדשה""",
  """onboarding.swipeActionsTitle""": """החלק פריטים כדי לנהל אותם""",
  """onboarding.swipeActionsBody""":
      """החלק פריט ברשימה משמאל לימין כדי לחשוף פעולות מהירות לעריכה, העברה או מחיקה.""",
  """onboarding.swipeActionsHint""": """החלק ימינה""",
  """onboarding.swipeActionsHintBack""": """החלק שמאלה""",
  """onboarding.quickActionsTitle""": """פעולות מהירות לכל פריט""",
  """onboarding.quickActionsBody""":
      """לכל פריט יש כפתורי פעולה בקצה — לחץ עליהם כדי לערוך, להעביר או למחוק את הפריט בלי לפתוח אותו.""",
  """onboarding.addItemsTitle""": """דרך מהירה יותר להוסיף פריטים""",
  """onboarding.addItemsBody""":
      """הקש על השדה בתחתית כדי להקליד פריט חדש, ואז סמן אותו עם קטגוריה, כמות, סוג או תמונה באמצעות הצ'יפים שמעליו.""",
  """onboarding.mockComposeListName""": """מצרכים""",
  """onboarding.progressHeroTitle""": """הסתר את כרטיס ההתקדמות""",
  """onboarding.progressHeroBody""":
      """לא צריך את טבעת ההתקדמות בראש הרשימה? החלק אותה החוצה.""",
  """onboarding.progressHeroHint""": """החלק כדי להסיר""",
  """onboarding.progressHeroDismissTitle""": """הסתר את כרטיס ההתקדמות""",
  """onboarding.progressHeroDismissBody""":
      """לא צריך את טבעת ההתקדמות למעלה? לחץ על ה-X בכרטיס כדי להסתיר אותו.""",
  """onboarding.pinnedListsTitle""": """הצמד רשימות למסך הבית""",
  """onboarding.pinnedListsBody""":
      """הוסף את הווידג'ט של Pantry למסך הבית כדי לראות במבט אחד כמה פריטים נותרו ברשימות המועדפות עליך — בלי לפתוח את האפליקציה.""",
  """onboarding.pinnedListsMenuLabel""": """התפריט""",
  """onboarding.pinnedListsActionLabel""": """הצמד רשימה""",
  """onboarding.pinnedListsWidgetTitle""": """Pantry""",
  """onboarding.pinnedListsWidgetEmpty""": """הכל בוצע""",
  """onboarding.pinnedNotesTitle""": """השאר הערות חשובות בראש הקיר""",
  """onboarding.pinnedNotesBody""":
      """הצמד הערה מתפריט שלוש הנקודות שלה כדי שתישאר בראש קיר ההערות, מעל הערות חדשות יותר.""",
  """onboarding.mockPinnedNoteTitle""": """סיסמת Wi-Fi""",
  """onboarding.mockPinnedNoteContent""": """רשת: בית
סיסמה: pantry-rocks""",
  """onboarding.mockItemName""": """עגבניות""",
  """onboarding.mockItemQuantity""": """x2""",
  """onboarding.mockItemCategory""": """ירקות""",
  """onboarding.mockHardwareItemName""": """נורות""",
  """onboarding.mockBulkItemThird""": """חלב""",
  """onboarding.mockBulkItemFourth""": """לחם""",
  """onboarding.allListsTitle""": """הכל בתצוגה אחת""",
  """onboarding.allListsBody""":
      """פתח את התצוגה כל הרשימות ממחליף הרשימות כדי לראות פריטים מכל הרשימות ביחד. כשמוסיפים פריט מכאן, הטופס שואל לאיזו רשימה להוסיף אותו — בוחרים אותה מצ'יפ הרשימה.""",
  """onboarding.bulkAddTitle""": """הוספת פריטים רבים בבת אחת""",
  """onboarding.bulkAddBody""":
      """הפעל את מתג מרובה והשדה הופך לתיבת קלט רב-שורתית — כל שורה הופכת לפריט נפרד. נוח כשמדביקים רשימה או רושמים קנייה שלמה בבת אחת.""",
  """onboarding.dev.showOnboarding""": """הצג היכרות""",
  """onboarding.dev.pickLastSeenTitle""": """דמה גרסה אחרונה שנצפתה""",
  """onboarding.dev.pickLastSeenBody""":
      """בחר באיזו גרסה המכשיר יעמיד פנים שהוא ראה לאחרונה, וההיכרות תרוץ משם.""",
  """onboarding.dev.neverSeen""": """מעולם לא נצפה (משתמש חדש)""",
  """onboarding.dev.forceAllFeatures""": """הפעל את כל התכונות""",
  """notificationsIntro.title""": """הישאר מעודכן""",
  """notificationsIntro.body""":
      """Pantry יכול להודיע לך כשבני משק הבית מוסיפים פריטים לרשימות, מעלים תמונות או משאירים הערות. ההתראות נשלפות מהשרת שלך — שום דבר לא עובר דרך Google או צדדים שלישיים.""",
  """notificationsIntro.bullet1""": """התראות על פעילות במשק הבית""",
  """notificationsIntro.bullet2""": """נשלפות ישירות מהשרת שלך""",
  """notificationsIntro.bullet3""": """עובד גם כשהאפליקציה סגורה""",
  """notificationsIntro.enableButton""": """הפעל התראות""",
  """notificationsIntro.skipButton""": """לא עכשיו""",
  """notificationsIntro.permissionDeniedTitle""": """ההרשאה נדחתה""",
  """notificationsIntro.permissionDeniedBody""":
      """תוכל להפעיל התראות מאוחר יותר בהגדרות האפליקציה. אם המכשיר חוסם אותן, תצטרך לאשר אותן קודם בהגדרות המערכת.""",
  """notificationsIntro.ok""": """אישור""",
  """about.title""": """אודות""",
  """about.developer""": """מפתח""",
  """about.email""": """דוא"ל""",
  """about.repository""": """קוד מקור""",
  """about.nextcloudApp""": """אפליקציית Nextcloud""",
  """about.privacyPolicy""": """מדיניות פרטיות""",
  """about.feedback""": """משוב ובעיות""",
  """about.serverVersion""": """שרת Nextcloud""",
  """about.pantryServerVersion""": """Pantry בשרת""",
  """about.versionUnknown""": """לא ידוע""",
  """about.buyMeACoffee""": """קנו לי קפה""",
  """settings.title""": """הגדרות האפליקציה""",
  """settings.generalSection""": """כללי""",
  """settings.interfaceSection""": """ממשק""",
  """settings.defaultItemTapAction""": """פעולת ברירת מחדל בלחיצה""",
  """settings.defaultItemTapActionBody""":
      """מה קורה כאשר לוחצים על שורת פריט.""",
  """settings.itemTapActionNames.done""": """סמן כהושלם""",
  """settings.itemTapActionNames.view""": """צפייה""",
  """settings.itemTapActionNames.edit""": """עריכה""",
  """settings.itemTapActionNames.none""": """ללא""",
  """settings.categorySpacing""": """הצג רווח בין קטגוריות בפריטי הרשימה""",
  """settings.categorySpacingBody""": """מוצג רק בעת מיון לפי קטגוריה""",
  """settings.categorySpacingNames.disabled""": """מושבת""",
  """settings.categorySpacingNames.space""": """רווח""",
  """settings.categorySpacingNames.divider""": """קו מפריד""",
  """settings.reuseExistingItems""": """שימוש חוזר בפריטים קיימים בעת הוספה""",
  """settings.reuseExistingItemsBody""":
      """כשמנסים להוסיף פריט שכבר קיים ברשימה, השתמש בפריט הקיים.""",
  """settings.reuseExistingItemsNames.ask""": """תמיד לשאול""",
  """settings.reuseExistingItemsNames.reuse""": """תמיד להשתמש מחדש""",
  """settings.reuseExistingItemsNames.never""": """לעולם לא להשתמש מחדש""",
  """settings.navOrderTitle""": """סדר ניווט""",
  """settings.navOrderSubtitle""":
      """שינוי הסדר של לשוניות הניווט. הפריט הראשון הוא זה שנפתח עם הפעלת האפליקציה.""",
  """settings.navOrderBody""":
      """גרור כדי לשנות את הסדר. הפריט הראשון הוא הקטע שנפתח עם הפעלת האפליקציה.""",
  """settings.navOrderDefaultHint""": """נפתח עם הפעלת האפליקציה""",
  """settings.navOrderReset""": """איפוס""",
  """settings.language""": """שפה""",
  """settings.languageNames.system""": """ברירת מחדל (שפת המערכת)""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
  """settings.theme""": """ערכת נושא""",
  """settings.themeNames.system""": """ברירת מחדל (המערכת)""",
  """settings.themeNames.light""": """בהיר""",
  """settings.themeNames.dark""": """כהה""",
  """settings.notificationsSection""": """התראות""",
  """settings.enableNotifications""": """הפעל התראות""",
  """settings.enableNotificationsBody""":
      """הצג התראות כשבני משק הבית מוסיפים או מעדכנים תוכן.""",
  """settings.pollInterval""": """בדוק פעילות חדשה""",
  """settings.pollInterval15m""": """כל 15 דקות""",
  """settings.pollInterval30m""": """כל 30 דקות""",
  """settings.pollInterval1h""": """כל שעה""",
  """settings.pollInterval2h""": """כל שעתיים""",
  """settings.pollInterval6h""": """כל 6 שעות""",
  """settings.permissionDenied""":
      """הרשאת ההתראות נדחתה. הפעל אותה בהגדרות המערכת.""",
  """notifications.title""": """התראות""",
  """notifications.empty""": """אין התראות חדשות.""",
  """notifications.failedToLoad""": """טעינת ההתראות נכשלה.""",
  """notifications.dismissAll""": """סגור הכל""",
  """notifications.justNow""": """הרגע""",
  """categories.manageTitle""": """ניהול קטגוריות""",
  """categories.noCategories""": """אין קטגוריות עדיין.""",
  """categories.editTitle""": """עריכת קטגוריה""",
  """categories.addTitle""": """קטגוריה חדשה""",
  """categories.name""": """שם""",
  """categories.icon""": """אייקון""",
  """categories.color""": """צבע""",
  """categories.saveFailed""": """שמירת הקטגוריה נכשלה.""",
  """categories.deleteFailed""": """מחיקת הקטגוריה נכשלה.""",
  """categories.deleteConfirm""": """למחוק את הקטגוריה?""",
  """categories.deleteConfirmBody""":
      """פריטים בקטגוריה זו יהפכו ללא קטגוריה. לא ניתן לבטל פעולה זו.""",
  """categories.sort.nameAZ""": """שם א'–ת'""",
  """categories.sort.nameZA""": """שם ת'–א'""",
  """categories.sort.custom""": """מותאם אישית""",
  """checklists.categories""": """קטגוריות""",
  """checklists.noChecklists""": """אין רשימות עדיין.""",
  """checklists.noItems""": """אין פריטים ברשימה.""",
  """checklists.noSearchResults""": """אין פריטים תואמים לחיפוש.""",
  """checklists.searchHint""": """הקלד לסינון...""",
  """checklists.allCategories""": """הכל""",
  """checklists.allListsChip""": """הכל""",
  """checklists.filterByList""": """סינון לפי רשימה""",
  """checklists.filterByCategory""": """סינון לפי קטגוריה""",
  """checklists.failedToLoad""": """טעינת הרשימות נכשלה.""",
  """checklists.failedToLoadItems""": """טעינת הפריטים נכשלה.""",
  """checklists.editItem""": """ערוך פריט""",
  """checklists.removeItem""": """הסר פריט""",
  """checklists.moveItem""": """העבר לרשימה""",
  """checklists.moveFailed""": """העברת הפריט נכשלה.""",
  """checklists.copyItem""": """העתק לרשימה""",
  """checklists.copyFailed""": """העתקת הפריט נכשלה.""",
  """checklists.itemCopied""": """הפריט הועתק""",
  """checklists.itemMarkedDone""": """הפריט סומן כהושלם""",
  """checklists.itemRemoved""": """הפריט הוסר""",
  """checklists.undo""": """בטל""",
  """checklists.viewTrash""": """הצג אשפה""",
  """checklists.exitTrash""": """צא מהאשפה""",
  """checklists.showAddedBy""": """הצג מי הוסיף כל פריט""",
  """checklists.showProgressHero""": """הצג כרטיס התקדמות ברשימה הזו""",
  """checklists.trashTitle""": """אשפה""",
  """checklists.noTrashedItems""": """האשפה ריקה.""",
  """checklists.emptyTrash""": """רוקן אשפה""",
  """checklists.emptyTrashConfirm""": """לרוקן את האשפה?""",
  """checklists.emptyTrashConfirmBody""":
      """כל הפריטים באשפה יימחקו לצמיתות. לא ניתן לבטל פעולה זו.""",
  """checklists.emptyTrashFailed""": """ריקון האשפה נכשל.""",
  """checklists.restoreItem""": """שחזר""",
  """checklists.permanentlyDeleteItem""": """מחק""",
  """checklists.permanentlyDeleteConfirm""": """למחוק את הפריט לצמיתות?""",
  """checklists.permanentlyDeleteConfirmBody""": """לא ניתן לבטל פעולה זו.""",
  """checklists.restoreFailed""": """שחזור הפריט נכשל.""",
  """checklists.permanentlyDeleteFailed""": """מחיקת הפריט נכשלה.""",
  """checklists.itemRestored""": """הפריט שוחזר""",
  """checklists.viewListsTrash""": """רשימות שנמחקו""",
  """checklists.listsTrashTitle""": """רשימות שנמחקו""",
  """checklists.failedToLoadTrash""": """טעינת סל המיחזור נכשלה.""",
  """checklists.listTrashEmpty""": """אין רשימות שנמחקו.""",
  """checklists.pinList""": """הצמד רשימה""",
  """checklists.unpinList""": """בטל הצמדה""",
  """checklists.removeList""": """הסר רשימה""",
  """checklists.editList""": """ערוך רשימה""",
  """checklists.editListTitle""": """ערוך רשימה""",
  """checklists.saveListButton""": """שמור שינויים""",
  """checklists.updateListFailed""": """עדכון הרשימה נכשל.""",
  """checklists.removeListConfirm""": """להסיר את הרשימה?""",
  """checklists.removeListFailed""": """הסרת הרשימה נכשלה.""",
  """checklists.restoreList""": """שחזר רשימה""",
  """checklists.permanentlyDeleteList""": """מחק לצמיתות""",
  """checklists.listRemoved""": """הרשימה הוסרה""",
  """checklists.createList""": """רשימה חדשה""",
  """checklists.listName""": """שם הרשימה""",
  """checklists.listDescription""": """תיאור (אופציונלי)""",
  """checklists.listIcon""": """אייקון""",
  """checklists.createListFailed""": """יצירת הרשימה נכשלה.""",
  """checklists.viewItem.quantity""": """כמות:""",
  """checklists.viewItem.category""": """קטגוריה:""",
  """checklists.viewItem.recurrence""": """חזרה:""",
  """checklists.viewItem.nextDue""": """מועד הבא:""",
  """checklists.viewItem.nextDueFromCompletion""": """מועד הבא (מהשלמה):""",
  """checklists.viewItem.overdue""": """באיחור""",
  """checklists.viewItem.quantityLabel""": """כמות""",
  """checklists.viewItem.typeLabel""": """סוג""",
  """checklists.viewItem.descriptionLabel""": """תיאור""",
  """checklists.viewItem.noDescription""": """לא נוסף תיאור.""",
  """checklists.viewItem.relJustNow""": """ממש עכשיו""",
  """checklists.viewItem.relToday""": """היום""",
  """checklists.viewItem.relYesterday""": """אתמול""",
  """checklists.itemForm.addTitle""": """הוסף פריט""",
  """checklists.itemForm.editTitle""": """ערוך פריט""",
  """checklists.itemForm.name""": """שם הפריט""",
  """checklists.itemForm.description""": """תיאור""",
  """checklists.itemForm.quantity""": """כמות""",
  """checklists.itemForm.category""": """קטגוריה""",
  """checklists.itemForm.noCategory""": """ללא""",
  """checklists.itemForm.noCategories""": """אין קטגוריות זמינות.""",
  """checklists.itemForm.createCategory""": """קטגוריה חדשה""",
  """checklists.itemForm.categoryName""": """שם""",
  """checklists.itemForm.categoryIcon""": """אייקון""",
  """checklists.itemForm.categoryColor""": """צבע""",
  """checklists.itemForm.categoryCreated""": """הקטגוריה נוצרה.""",
  """checklists.itemForm.categoryCreateFailed""": """יצירת הקטגוריה נכשלה.""",
  """checklists.itemForm.repeat""": """חזרה""",
  """checklists.itemForm.once""": """פעם אחת""",
  """checklists.itemForm.onceDescription""":
      """מחק את הפריט ברגע שהוא מסומן כבוצע.""",
  """checklists.itemForm.image""": """תמונה""",
  """checklists.itemForm.addImage""": """הוסף תמונה""",
  """checklists.itemForm.takePhoto""": """צלם תמונה""",
  """checklists.itemForm.chooseImage""": """בחר תמונה""",
  """checklists.itemForm.replaceImage""": """החלף""",
  """checklists.itemForm.removeImage""": """הסר""",
  """checklists.itemForm.saveFailed""": """שמירת הפריט נכשלה.""",
  """checklists.itemForm.deleteFailed""": """מחיקת הפריט נכשלה.""",
  """checklists.itemForm.deleteConfirm""": """למחוק את הפריט?""",
  """checklists.itemForm.save""": """שמור שינויים""",
  """checklists.itemForm.descHint""": """הוסף תיאור (אופציונלי)""",
  """checklists.itemForm.categoryChange""": """שנה""",
  """checklists.itemForm.categoryPick""": """בחר אחת""",
  """checklists.itemForm.untitledItem""": """פריט ללא שם""",
  """checklists.itemForm.typeStaple""": """פריט קבוע""",
  """checklists.itemForm.typeOnce""": """פריט חד-פעמי""",
  """checklists.itemForm.typeRecurring""": """חוזר""",
  """checklists.sort.newestFirst""": """החדש ביותר""",
  """checklists.sort.oldestFirst""": """הישן ביותר""",
  """checklists.sort.nameAZ""": """שם א–ת""",
  """checklists.sort.nameZA""": """שם ת–א""",
  """checklists.sort.category""": """לפי קטגוריה""",
  """checklists.sort.custom""": """מותאם אישית""",
  """checklists.allDone""": """הכל בוצע 🎉""",
  """checklists.hideProgressHero""": """הסתר כרטיס התקדמות""",
  """checklists.sortTooltip""": """מיון""",
  """checklists.addFirstItem""": """הוסף את הפריט הראשון…""",
  """checklists.noItemsTitle""": """אין פריטים ברשימה""",
  """checklists.noItemsBody""":
      """הוסף את הפריט הראשון בעזרת השורה למטה — קבע קטגוריה, כמות או לוח זמנים בעזרת הצ׳יפים.""",
  """checklists.noListsTitle""": """אין רשימות עדיין""",
  """checklists.noListsBody""":
      """צור את הרשימה הראשונה שלך כדי להתחיל לעקוב אחר מצרכים, סידורים, משימות או כל דבר שמשק הבית צריך לזכור.""",
  """checklists.createFirstList""": """צור את הרשימה הראשונה""",
  """checklists.yourChecklists""": """הרשימות שלך""",
  """checklists.allDoneSummary""": """הכל בוצע · 0 נותרו""",
  """checklists.newChecklist""": """רשימה חדשה""",
  """checklists.createListButton""": """צור רשימה""",
  """checklists.view""": """צפה""",
  """checklists.swipeView""": """צפייה""",
  """checklists.swipeEdit""": """עריכה""",
  """checklists.swipeMove""": """העברה""",
  """checklists.swipeCopy""": """העתקה""",
  """checklists.swipeDelete""": """הסר""",
  """checklists.viewList""": """תצוגת רשימה""",
  """checklists.viewCards""": """תצוגת כרטיסים""",
  """checklists.listColor""": """צבע""",
  """checklists.itemTypes.label""": """סוג פריט""",
  """checklists.itemTypes.staple""": """קבוע""",
  """checklists.itemTypes.stapleBody""":
      """נשאר ברשימה אחרי שמסמנים אותו כבוצע""",
  """checklists.itemTypes.onceTime""": """חד-פעמי""",
  """checklists.itemTypes.onceTimeBody""":
      """מוסר מהרשימה ברגע שמסמנים אותו כבוצע""",
  """checklists.itemTypes.recurring""": """חוזר""",
  """checklists.itemTypes.recurringBody""": """חוזר ברשימה לפי לוח זמנים""",
  """checklists.itemTypes.weekly""": """שבועי""",
  """checklists.compose.chipCategory""": """קטגוריה""",
  """checklists.compose.chipQuantity""": """כמות""",
  """checklists.compose.chipType""": """סוג פריט""",
  """checklists.compose.chipImage""": """תמונה""",
  """checklists.compose.chipDescription""": """תיאור""",
  """checklists.compose.descHint""": """הערות, הוראות, קישורים…""",
  """checklists.compose.qtyHint""": """למשל 2 ליטר, 500 ג׳""",
  """checklists.compose.qtyStepperHelp""":
      """＋ / − משנים את המספר ושומרים על היחידה.""",
  """checklists.compose.none""": """ללא""",
  """checklists.compose.every""": """כל""",
  """checklists.compose.week""": """שבוע""",
  """checklists.compose.weeks""": """שבועות""",
  """checklists.compose.chipTargetList""": """רשימה""",
  """checklists.compose.pickTargetList""": """בחר רשימה""",
  """checklists.compose.multiple""": """מרובה""",
  """checklists.compose.multipleHint""": """הפרד פריטים בשורות חדשות""",
  """checklists.reuse.dialogTitle""": """הפריט כבר קיים""",
  """checklists.reuse.reuseExisting""": """השתמש בקיים""",
  """checklists.reuse.addAnyway""": """הוסף בכל זאת""",
  """checklists.allLists""": """כל הרשימות""",
  """checklists.allListsSubtitle""": """פריטים מכל הרשימות""",
  """checklists.addToAnyList""": """הוסף פריט…""",
  """checklists.pickListTitle""": """להוסיף לאיזו רשימה?""",
  """checklists.markdown.uncategorized""": """ללא קטגוריה""",
  """checklists.markdown.exportTitle""": """ייצוא ל-Markdown""",
  """checklists.markdown.importTitle""": """ייבוא מ-Markdown""",
  """checklists.markdown.includeCompleted""": """לכלול פריטים שהושלמו""",
  """checklists.markdown.editHint""":
      """ערכו את הטקסט למטה כדי לשנות את הרשימה המיוצאת""",
  """checklists.markdown.copy""": """העתקה""",
  """checklists.markdown.download""": """הורדת .md""",
  """checklists.markdown.copied""": """הועתק ללוח""",
  """checklists.markdown.copyFailed""": """לא ניתן להעתיק ללוח""",
  """checklists.markdown.close""": """סגירה""",
  """checklists.markdown.shareFailed""": """לא ניתן לייצא את הקובץ""",
  """checklists.markdown.uploadFile""": """העלאת קובץ .md""",
  """checklists.markdown.pasteLabel""": """הדבקת Markdown""",
  """checklists.markdown.pastePlaceholder""": """הדביקו כאן רשימת Markdown…""",
  """checklists.markdown.noneFound""": """לא נמצאו פריטי רשימה בטקסט.""",
  """checklists.markdown.selectAll""": """בחירת הכול""",
  """checklists.markdown.deselectAll""": """ביטול בחירת הכול""",
  """checklists.markdown.reuseExisting""":
      """שימוש חוזר בפריטים קיימים במקום הוספת כפילויות""",
  """checklists.markdown.defaultFields""": """ערכים שיחולו על כל פריט מיובא""",
  """notesWall.noNotes""": """אין הערות עדיין.""",
  """notesWall.failedToLoad""": """טעינת ההערות נכשלה.""",
  """notesWall.saveFailed""": """שמירת ההערה נכשלה.""",
  """notesWall.deleteFailed""": """מחיקת ההערה נכשלה.""",
  """notesWall.deleteConfirm""": """למחוק את ההערה?""",
  """notesWall.viewTrash""": """הצג סל מיחזור""",
  """notesWall.exitTrash""": """צא מסל המיחזור""",
  """notesWall.trashTitle""": """סל מיחזור""",
  """notesWall.trashEmpty""": """סל המיחזור ריק.""",
  """notesWall.emptyTrash""": """רוקן סל מיחזור""",
  """notesWall.emptyTrashConfirm""": """לרוקן את סל המיחזור?""",
  """notesWall.emptyTrashConfirmBody""":
      """כל ההערות בסל המיחזור יימחקו לצמיתות. לא ניתן לבטל פעולה זו.""",
  """notesWall.emptyTrashFailed""": """ריקון סל המיחזור נכשל.""",
  """notesWall.failedToLoadTrash""": """טעינת סל המיחזור נכשלה.""",
  """notesWall.restore""": """שחזר""",
  """notesWall.restoreFailed""": """שחזור ההערה נכשל.""",
  """notesWall.permanentlyDelete""": """מחק לצמיתות""",
  """notesWall.permanentlyDeleteConfirm""": """למחוק את ההערה לצמיתות?""",
  """notesWall.permanentlyDeleteConfirmBody""": """לא ניתן לבטל פעולה זו.""",
  """notesWall.newNote""": """הערה חדשה""",
  """notesWall.editNote""": """עריכת הערה""",
  """notesWall.pinNote""": """הצמדת הערה""",
  """notesWall.unpinNote""": """ביטול הצמדה""",
  """notesWall.title""": """כותרת""",
  """notesWall.content""": """תוכן""",
  """notesWall.color""": """צבע""",
  """notesWall.sort.newestFirst""": """החדש ביותר""",
  """notesWall.sort.oldestFirst""": """הישן ביותר""",
  """notesWall.sort.titleAZ""": """כותרת א–ת""",
  """notesWall.sort.titleZA""": """כותרת ת–א""",
  """notesWall.sort.custom""": """מותאם אישית""",
  """photoBoard.noPhotos""": """אין תמונות עדיין.""",
  """photoBoard.failedToLoad""": """טעינת התמונות נכשלה.""",
  """photoBoard.uploadFailed""": """העלאת התמונה נכשלה.""",
  """photoBoard.deleteFailed""": """מחיקת התמונה נכשלה.""",
  """photoBoard.deleteConfirm""": """למחוק את התמונה?""",
  """photoBoard.viewTrash""": """הצג סל מיחזור""",
  """photoBoard.exitTrash""": """צא מסל המיחזור""",
  """photoBoard.trashTitle""": """סל מיחזור""",
  """photoBoard.trashEmpty""": """סל המיחזור ריק.""",
  """photoBoard.emptyTrash""": """רוקן סל מיחזור""",
  """photoBoard.emptyTrashConfirm""": """לרוקן את סל המיחזור?""",
  """photoBoard.emptyTrashConfirmBody""":
      """כל התמונות בסל המיחזור יימחקו לצמיתות. לא ניתן לבטל פעולה זו.""",
  """photoBoard.emptyTrashFailed""": """ריקון סל המיחזור נכשל.""",
  """photoBoard.failedToLoadTrash""": """טעינת סל המיחזור נכשלה.""",
  """photoBoard.restore""": """שחזר""",
  """photoBoard.restoreFailed""": """שחזור התמונה נכשל.""",
  """photoBoard.permanentlyDelete""": """מחק לצמיתות""",
  """photoBoard.permanentlyDeleteConfirm""": """למחוק את התמונה לצמיתות?""",
  """photoBoard.permanentlyDeleteConfirmBody""": """לא ניתן לבטל פעולה זו.""",
  """photoBoard.deleteFolder""": """מחק תיקייה""",
  """photoBoard.deleteFolderConfirm""": """למחוק את התיקייה?""",
  """photoBoard.deleteFolderKeepPhotos""": """העבר תמונות לשורש""",
  """photoBoard.deleteFolderDeleteAll""": """מחק תיקייה ותמונות""",
  """photoBoard.newFolder""": """תיקייה חדשה""",
  """photoBoard.folderName""": """שם התיקייה""",
  """photoBoard.renameFolder""": """שנה שם תיקייה""",
  """photoBoard.caption""": """כיתוב""",
  """photoBoard.addMenu.upload""": """העלאת תמונות""",
  """photoBoard.addMenu.camera""": """צילום תמונה""",
  """photoBoard.addMenu.newFolder""": """תיקייה חדשה""",
  """photoBoard.sort.foldersFirst""": """תיקיות קודם""",
  """photoBoard.sort.newestFirst""": """החדש ביותר""",
  """photoBoard.sort.oldestFirst""": """הישן ביותר""",
  """photoBoard.sort.captionAZ""": """כיתוב א–ת""",
  """photoBoard.sort.captionZA""": """כיתוב ת–א""",
  """photoBoard.sort.custom""": """מותאם אישית""",
  """share.title""": """שיתוף ל-Pantry""",
  """share.chooseHouse""": """בחר בית""",
  """share.choosePhotoDestination""": """העלה אל""",
  """share.photoBoardRoot""": """לוח התמונות""",
  """share.newFolder""": """תיקייה חדשה""",
  """share.newFolderName""": """שם התיקייה""",
  """share.failedToCreateFolder""": """יצירת התיקייה נכשלה.""",
  """share.failedToOpenShare""": """לא ניתן לפתוח את התוכן ששותף.""",
  """share.noHouses""": """אין בתים זמינים. צור תחילה בית.""",
  """recurrence.title""": """חזרה""",
  """recurrence.presets""": """הגדרות מוכנות""",
  """recurrence.daily""": """יומי""",
  """recurrence.weekly""": """שבועי""",
  """recurrence.monthly""": """חודשי""",
  """recurrence.everyLabel""": """כל""",
  """recurrence.unit""": """יחידה""",
  """recurrence.unitDays""": """ימים""",
  """recurrence.unitWeeks""": """שבועות""",
  """recurrence.unitMonths""": """חודשים""",
  """recurrence.unitYears""": """שנים""",
  """recurrence.repeatOn""": """חזור ב""",
  """recurrence.ends""": """מסתיים""",
  """recurrence.never""": """לעולם לא""",
  """recurrence.after""": """אחרי""",
  """recurrence.occurrences""": """חזרות""",
  """recurrence.onDate""": """בתאריך""",
  """recurrence.countFromCompletion""": """חשב מרווח מרגע סימון הפריט""",
  """recurrence.countFromCompletionHintOff""":
      """לוח הזמנים קבוע: הפריט יופיע מחדש במועד המתוכנן הבא, ללא קשר למתי סימנת אותו.""",
  """recurrence.countFromCompletionHintOn""":
      """המועד הבא נספר מרגע סימון הפריט, כך שהוא תמיד חוזר מרווח מלא לאחר ההשלמה.""",
  """recurrence.summary""": """סיכום""",
  """recurrence.notSet""": """לא נקבע""",
  """recurrence.set""": """נקבע""",
  """recurrence.dayNames.monday""": """יום שני""",
  """recurrence.dayNames.tuesday""": """יום שלישי""",
  """recurrence.dayNames.wednesday""": """יום רביעי""",
  """recurrence.dayNames.thursday""": """יום חמישי""",
  """recurrence.dayNames.friday""": """יום שישי""",
  """recurrence.dayNames.saturday""": """שבת""",
  """recurrence.dayNames.sunday""": """יום ראשון""",
  """recurrence.dayAbbr.mo""": """ב׳""",
  """recurrence.dayAbbr.tu""": """ג׳""",
  """recurrence.dayAbbr.we""": """ד׳""",
  """recurrence.dayAbbr.th""": """ה׳""",
  """recurrence.dayAbbr.fr""": """ו׳""",
  """recurrence.dayAbbr.sa""": """ש׳""",
  """recurrence.dayAbbr.su""": """א׳""",
  """sync.offline""": """לא מקוון""",
  """sync.syncing""": """מסנכרן שינויים…""",
  """sync.syncError""": """לא ניתן היה לסנכרן את השינויים""",
  """sync.retry""": """נסה שוב""",
};
