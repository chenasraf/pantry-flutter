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
  NotificationsIntroMessagesHe get notificationsIntro =>
      NotificationsIntroMessagesHe(this);
  SettingsMessagesHe get settings => SettingsMessagesHe(this);
  NotificationsMessagesHe get notifications => NotificationsMessagesHe(this);
  CategoriesMessagesHe get categories => CategoriesMessagesHe(this);
  ChecklistsMessagesHe get checklists => ChecklistsMessagesHe(this);
  NotesWallMessagesHe get notesWall => NotesWallMessagesHe(this);
  PhotoBoardMessagesHe get photoBoard => PhotoBoardMessagesHe(this);
  RecurrenceMessagesHe get recurrence => RecurrenceMessagesHe(this);
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
  /// "שפה"
  /// ```
  String get language => """שפה""";
  LanguageNamesSettingsMessagesHe get languageNames =>
      LanguageNamesSettingsMessagesHe(this);

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
  /// "הערה חדשה"
  /// ```
  String get newNote => """הערה חדשה""";

  /// ```dart
  /// "עריכת הערה"
  /// ```
  String get editNote => """עריכת הערה""";

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
  SortPhotoBoardMessagesHe get sort => SortPhotoBoardMessagesHe(this);
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
  /// "כל שבועיים"
  /// ```
  String get everyTwoWeeks => """כל שבועיים""";

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
  /// "כל $count $unit"
  /// ```
  String everyN(int count, String unit) => """כל $count $unit""";

  /// ```dart
  /// "ב$days"
  /// ```
  String onDays(String days) => """ב$days""";

  /// ```dart
  /// "${_plural(count, one: 'יום', many: 'ימים')}"
  /// ```
  String day(int count) => """${_plural(count, one: 'יום', many: 'ימים')}""";

  /// ```dart
  /// "${_plural(count, one: 'שבוע', many: 'שבועות')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'שבוע', many: 'שבועות')}""";

  /// ```dart
  /// "${_plural(count, one: 'חודש', many: 'חודשים')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'חודש', many: 'חודשים')}""";

  /// ```dart
  /// "${_plural(count, one: 'שנה', many: 'שנים')}"
  /// ```
  String year(int count) => """${_plural(count, one: 'שנה', many: 'שנים')}""";
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

Map<String, String> get messagesHeMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """ביטול""",
  """common.delete""": """מחיקה""",
  """common.save""": """שמירה""",
  """common.retry""": """נסה שוב""",
  """common.logout""": """התנתקות""",
  """common.loading""": """טוען...""",
  """common.error""": """שגיאה""",
  """login.connectToNextcloud""": """התחבר לשרת ה-Nextcloud שלך""",
  """login.serverUrl""": """כתובת השרת""",
  """login.serverUrlHint""": """cloud.example.com""",
  """login.connect""": """התחבר""",
  """login.waitingForAuth""": """ממתין לאימות...
אנא השלם את ההתחברות בדפדפן.""",
  """login.couldNotConnect""": """לא ניתן להתחבר לשרת. אנא בדוק את הכתובת.""",
  """login.loginFailed""": """ההתחברות נכשלה. אנא נסה שוב.""",
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
  """settings.title""": """הגדרות האפליקציה""",
  """settings.generalSection""": """כללי""",
  """settings.language""": """שפה""",
  """settings.languageNames.system""": """ברירת מחדל (שפת המערכת)""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
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
  """checklists.categories""": """קטגוריות""",
  """checklists.noChecklists""": """אין רשימות עדיין.""",
  """checklists.noItems""": """אין פריטים ברשימה.""",
  """checklists.failedToLoad""": """טעינת הרשימות נכשלה.""",
  """checklists.failedToLoadItems""": """טעינת הפריטים נכשלה.""",
  """checklists.editItem""": """ערוך פריט""",
  """checklists.removeItem""": """הסר פריט""",
  """checklists.moveItem""": """העבר לרשימה""",
  """checklists.moveFailed""": """העברת הפריט נכשלה.""",
  """checklists.createList""": """רשימה חדשה""",
  """checklists.listName""": """שם הרשימה""",
  """checklists.listDescription""": """תיאור (אופציונלי)""",
  """checklists.listIcon""": """אייקון""",
  """checklists.createListFailed""": """יצירת הרשימה נכשלה.""",
  """checklists.viewItem.quantity""": """כמות:""",
  """checklists.viewItem.category""": """קטגוריה:""",
  """checklists.viewItem.recurrence""": """חזרה:""",
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
  """checklists.itemForm.saveFailed""": """שמירת הפריט נכשלה.""",
  """checklists.itemForm.deleteFailed""": """מחיקת הפריט נכשלה.""",
  """checklists.itemForm.deleteConfirm""": """למחוק את הפריט?""",
  """checklists.sort.newestFirst""": """החדש ביותר""",
  """checklists.sort.oldestFirst""": """הישן ביותר""",
  """checklists.sort.nameAZ""": """שם א–ת""",
  """checklists.sort.nameZA""": """שם ת–א""",
  """checklists.sort.category""": """לפי קטגוריה""",
  """checklists.sort.custom""": """מותאם אישית""",
  """notesWall.noNotes""": """אין הערות עדיין.""",
  """notesWall.failedToLoad""": """טעינת ההערות נכשלה.""",
  """notesWall.saveFailed""": """שמירת ההערה נכשלה.""",
  """notesWall.deleteFailed""": """מחיקת ההערה נכשלה.""",
  """notesWall.deleteConfirm""": """למחוק את ההערה?""",
  """notesWall.newNote""": """הערה חדשה""",
  """notesWall.editNote""": """עריכת הערה""",
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
  """photoBoard.deleteFolder""": """מחק תיקייה""",
  """photoBoard.deleteFolderConfirm""": """למחוק את התיקייה?""",
  """photoBoard.deleteFolderKeepPhotos""": """העבר תמונות לשורש""",
  """photoBoard.deleteFolderDeleteAll""": """מחק תיקייה ותמונות""",
  """photoBoard.newFolder""": """תיקייה חדשה""",
  """photoBoard.folderName""": """שם התיקייה""",
  """photoBoard.renameFolder""": """שנה שם תיקייה""",
  """photoBoard.caption""": """כיתוב""",
  """photoBoard.sort.foldersFirst""": """תיקיות קודם""",
  """photoBoard.sort.newestFirst""": """החדש ביותר""",
  """photoBoard.sort.oldestFirst""": """הישן ביותר""",
  """photoBoard.sort.captionAZ""": """כיתוב א–ת""",
  """photoBoard.sort.captionZA""": """כיתוב ת–א""",
  """photoBoard.sort.custom""": """מותאם אישית""",
  """recurrence.title""": """חזרה""",
  """recurrence.presets""": """הגדרות מוכנות""",
  """recurrence.daily""": """יומי""",
  """recurrence.weekly""": """שבועי""",
  """recurrence.everyTwoWeeks""": """כל שבועיים""",
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
};
