// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:i18n/i18n.dart' as i18n;

String get _languageCode => 'en';
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

class Messages {
  const Messages();
  String get locale => "en";
  String get languageCode => "en";
  CommonMessages get common => CommonMessages(this);
  LoginMessages get login => LoginMessages(this);
  HomeMessages get home => HomeMessages(this);
  NavMessages get nav => NavMessages(this);
  ChecklistsMessages get checklists => ChecklistsMessages(this);
  RecurrenceMessages get recurrence => RecurrenceMessages(this);
}

class CommonMessages {
  final Messages _parent;
  const CommonMessages(this._parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "Cancel"
  /// ```
  String get cancel => """Cancel""";

  /// ```dart
  /// "Delete"
  /// ```
  String get delete => """Delete""";

  /// ```dart
  /// "Save"
  /// ```
  String get save => """Save""";

  /// ```dart
  /// "Retry"
  /// ```
  String get retry => """Retry""";

  /// ```dart
  /// "Logout"
  /// ```
  String get logout => """Logout""";

  /// ```dart
  /// "Loading..."
  /// ```
  String get loading => """Loading...""";

  /// ```dart
  /// "Error"
  /// ```
  String get error => """Error""";
}

class LoginMessages {
  final Messages _parent;
  const LoginMessages(this._parent);

  /// ```dart
  /// "Connect to your Nextcloud instance"
  /// ```
  String get connectToNextcloud => """Connect to your Nextcloud instance""";

  /// ```dart
  /// "Server URL"
  /// ```
  String get serverUrl => """Server URL""";

  /// ```dart
  /// "cloud.example.com"
  /// ```
  String get serverUrlHint => """cloud.example.com""";

  /// ```dart
  /// "Connect"
  /// ```
  String get connect => """Connect""";

  /// ```dart
  /// """
  /// Waiting for authentication...
  /// Please complete login in your browser.
  /// """
  /// ```
  String get waitingForAuth => """Waiting for authentication...
Please complete login in your browser.""";

  /// ```dart
  /// "Could not connect to server. Please check the URL."
  /// ```
  String get couldNotConnect =>
      """Could not connect to server. Please check the URL.""";

  /// ```dart
  /// "Login failed. Please try again."
  /// ```
  String get loginFailed => """Login failed. Please try again.""";
}

class HomeMessages {
  final Messages _parent;
  const HomeMessages(this._parent);

  /// ```dart
  /// "No houses found. Create one in Nextcloud first."
  /// ```
  String get noHouses => """No houses found. Create one in Nextcloud first.""";

  /// ```dart
  /// "Failed to load houses."
  /// ```
  String get failedToLoadHouses => """Failed to load houses.""";
}

class NavMessages {
  final Messages _parent;
  const NavMessages(this._parent);

  /// ```dart
  /// "Checklists"
  /// ```
  String get checklists => """Checklists""";

  /// ```dart
  /// "Photo Board"
  /// ```
  String get photoBoard => """Photo Board""";

  /// ```dart
  /// "Notes Wall"
  /// ```
  String get notesWall => """Notes Wall""";
}

class ChecklistsMessages {
  final Messages _parent;
  const ChecklistsMessages(this._parent);

  /// ```dart
  /// "No checklists yet."
  /// ```
  String get noChecklists => """No checklists yet.""";

  /// ```dart
  /// "No items in this list."
  /// ```
  String get noItems => """No items in this list.""";

  /// ```dart
  /// "Failed to load checklists."
  /// ```
  String get failedToLoad => """Failed to load checklists.""";

  /// ```dart
  /// "Failed to load items."
  /// ```
  String get failedToLoadItems => """Failed to load items.""";

  /// ```dart
  /// "Completed ($count)"
  /// ```
  String completedCount(int count) => """Completed ($count)""";

  /// ```dart
  /// "Edit item"
  /// ```
  String get editItem => """Edit item""";

  /// ```dart
  /// "Remove item"
  /// ```
  String get removeItem => """Remove item""";
  SortChecklistsMessages get sort => SortChecklistsMessages(this);
}

class SortChecklistsMessages {
  final ChecklistsMessages _parent;
  const SortChecklistsMessages(this._parent);

  /// ```dart
  /// "Newest first"
  /// ```
  String get newestFirst => """Newest first""";

  /// ```dart
  /// "Oldest first"
  /// ```
  String get oldestFirst => """Oldest first""";

  /// ```dart
  /// "Name A–Z"
  /// ```
  String get nameAZ => """Name A–Z""";

  /// ```dart
  /// "Name Z–A"
  /// ```
  String get nameZA => """Name Z–A""";

  /// ```dart
  /// "Custom"
  /// ```
  String get custom => """Custom""";
}

class RecurrenceMessages {
  final Messages _parent;
  const RecurrenceMessages(this._parent);

  /// ```dart
  /// "every $unit"
  /// ```
  String every(String unit) => """every $unit""";

  /// ```dart
  /// "every $count $unit"
  /// ```
  String everyN(int count, String unit) => """every $count $unit""";

  /// ```dart
  /// "on $days"
  /// ```
  String onDays(String days) => """on $days""";

  /// ```dart
  /// "${_plural(count, one: 'day', many: 'days')}"
  /// ```
  String day(int count) => """${_plural(count, one: 'day', many: 'days')}""";

  /// ```dart
  /// "${_plural(count, one: 'week', many: 'weeks')}"
  /// ```
  String week(int count) => """${_plural(count, one: 'week', many: 'weeks')}""";

  /// ```dart
  /// "${_plural(count, one: 'month', many: 'months')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'month', many: 'months')}""";

  /// ```dart
  /// "${_plural(count, one: 'year', many: 'years')}"
  /// ```
  String year(int count) => """${_plural(count, one: 'year', many: 'years')}""";
  DayNamesRecurrenceMessages get dayNames => DayNamesRecurrenceMessages(this);
}

class DayNamesRecurrenceMessages {
  final RecurrenceMessages _parent;
  const DayNamesRecurrenceMessages(this._parent);

  /// ```dart
  /// "Monday"
  /// ```
  String get monday => """Monday""";

  /// ```dart
  /// "Tuesday"
  /// ```
  String get tuesday => """Tuesday""";

  /// ```dart
  /// "Wednesday"
  /// ```
  String get wednesday => """Wednesday""";

  /// ```dart
  /// "Thursday"
  /// ```
  String get thursday => """Thursday""";

  /// ```dart
  /// "Friday"
  /// ```
  String get friday => """Friday""";

  /// ```dart
  /// "Saturday"
  /// ```
  String get saturday => """Saturday""";

  /// ```dart
  /// "Sunday"
  /// ```
  String get sunday => """Sunday""";
}

Map<String, String> get messagesMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Cancel""",
  """common.delete""": """Delete""",
  """common.save""": """Save""",
  """common.retry""": """Retry""",
  """common.logout""": """Logout""",
  """common.loading""": """Loading...""",
  """common.error""": """Error""",
  """login.connectToNextcloud""": """Connect to your Nextcloud instance""",
  """login.serverUrl""": """Server URL""",
  """login.serverUrlHint""": """cloud.example.com""",
  """login.connect""": """Connect""",
  """login.waitingForAuth""": """Waiting for authentication...
Please complete login in your browser.""",
  """login.couldNotConnect""":
      """Could not connect to server. Please check the URL.""",
  """login.loginFailed""": """Login failed. Please try again.""",
  """home.noHouses""": """No houses found. Create one in Nextcloud first.""",
  """home.failedToLoadHouses""": """Failed to load houses.""",
  """nav.checklists""": """Checklists""",
  """nav.photoBoard""": """Photo Board""",
  """nav.notesWall""": """Notes Wall""",
  """checklists.noChecklists""": """No checklists yet.""",
  """checklists.noItems""": """No items in this list.""",
  """checklists.failedToLoad""": """Failed to load checklists.""",
  """checklists.failedToLoadItems""": """Failed to load items.""",
  """checklists.editItem""": """Edit item""",
  """checklists.removeItem""": """Remove item""",
  """checklists.sort.newestFirst""": """Newest first""",
  """checklists.sort.oldestFirst""": """Oldest first""",
  """checklists.sort.nameAZ""": """Name A–Z""",
  """checklists.sort.nameZA""": """Name Z–A""",
  """checklists.sort.custom""": """Custom""",
  """recurrence.dayNames.monday""": """Monday""",
  """recurrence.dayNames.tuesday""": """Tuesday""",
  """recurrence.dayNames.wednesday""": """Wednesday""",
  """recurrence.dayNames.thursday""": """Thursday""",
  """recurrence.dayNames.friday""": """Friday""",
  """recurrence.dayNames.saturday""": """Saturday""",
  """recurrence.dayNames.sunday""": """Sunday""",
};
