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
  NotificationsIntroMessages get notificationsIntro =>
      NotificationsIntroMessages(this);
  AboutMessages get about => AboutMessages(this);
  SettingsMessages get settings => SettingsMessages(this);
  NotificationsMessages get notifications => NotificationsMessages(this);
  CategoriesMessages get categories => CategoriesMessages(this);
  ChecklistsMessages get checklists => ChecklistsMessages(this);
  NotesWallMessages get notesWall => NotesWallMessages(this);
  PhotoBoardMessages get photoBoard => PhotoBoardMessages(this);
  ShareMessages get share => ShareMessages(this);
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
  /// "No houses yet."
  /// ```
  String get noHouses => """No houses yet.""";

  /// ```dart
  /// "Houses are shared spaces for your household. Create your first house to start adding checklists, photos and notes."
  /// ```
  String get noHousesBody =>
      """Houses are shared spaces for your household. Create your first house to start adding checklists, photos and notes.""";

  /// ```dart
  /// "Create house"
  /// ```
  String get createHouse => """Create house""";

  /// ```dart
  /// "House name"
  /// ```
  String get houseName => """House name""";

  /// ```dart
  /// "Description (optional)"
  /// ```
  String get houseDescription => """Description (optional)""";

  /// ```dart
  /// "Failed to create house."
  /// ```
  String get createHouseFailed => """Failed to create house.""";

  /// ```dart
  /// "Failed to load houses."
  /// ```
  String get failedToLoadHouses => """Failed to load houses.""";

  /// ```dart
  /// "Pantry is not installed"
  /// ```
  String get serverAppMissingTitle => """Pantry is not installed""";

  /// ```dart
  /// "This app is a client for the Pantry app on Nextcloud. It looks like Pantry isn't installed on your server yet. Ask your administrator to install it from the Nextcloud app store, or install it yourself if you have admin access."
  /// ```
  String get serverAppMissingBody =>
      """This app is a client for the Pantry app on Nextcloud. It looks like Pantry isn't installed on your server yet. Ask your administrator to install it from the Nextcloud app store, or install it yourself if you have admin access.""";

  /// ```dart
  /// "Open Nextcloud apps"
  /// ```
  String get openAppStore => """Open Nextcloud apps""";

  /// ```dart
  /// "Learn more"
  /// ```
  String get learnMore => """Learn more""";
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

class NotificationsIntroMessages {
  final Messages _parent;
  const NotificationsIntroMessages(this._parent);

  /// ```dart
  /// "Stay in the loop"
  /// ```
  String get title => """Stay in the loop""";

  /// ```dart
  /// "Pantry can notify you when household members add items to checklists, upload photos, or leave notes. Notifications are fetched from your own Nextcloud server — nothing goes through Google or third parties."
  /// ```
  String get body =>
      """Pantry can notify you when household members add items to checklists, upload photos, or leave notes. Notifications are fetched from your own Nextcloud server — nothing goes through Google or third parties.""";

  /// ```dart
  /// "Household activity alerts"
  /// ```
  String get bullet1 => """Household activity alerts""";

  /// ```dart
  /// "Fetched directly from your server"
  /// ```
  String get bullet2 => """Fetched directly from your server""";

  /// ```dart
  /// "Works even when the app is closed"
  /// ```
  String get bullet3 => """Works even when the app is closed""";

  /// ```dart
  /// "Enable notifications"
  /// ```
  String get enableButton => """Enable notifications""";

  /// ```dart
  /// "Not now"
  /// ```
  String get skipButton => """Not now""";

  /// ```dart
  /// "Permission denied"
  /// ```
  String get permissionDeniedTitle => """Permission denied""";

  /// ```dart
  /// "You can enable notifications later in App Settings. If your device blocks them, you'll need to allow them in system settings first."
  /// ```
  String get permissionDeniedBody =>
      """You can enable notifications later in App Settings. If your device blocks them, you'll need to allow them in system settings first.""";

  /// ```dart
  /// "OK"
  /// ```
  String get ok => """OK""";
}

class AboutMessages {
  final Messages _parent;
  const AboutMessages(this._parent);

  /// ```dart
  /// "About"
  /// ```
  String get title => """About""";

  /// ```dart
  /// "Developer"
  /// ```
  String get developer => """Developer""";

  /// ```dart
  /// "Email"
  /// ```
  String get email => """Email""";

  /// ```dart
  /// "Source code"
  /// ```
  String get repository => """Source code""";

  /// ```dart
  /// "Nextcloud app"
  /// ```
  String get nextcloudApp => """Nextcloud app""";

  /// ```dart
  /// "Privacy policy"
  /// ```
  String get privacyPolicy => """Privacy policy""";

  /// ```dart
  /// "Feedback & issues"
  /// ```
  String get feedback => """Feedback & issues""";
}

class SettingsMessages {
  final Messages _parent;
  const SettingsMessages(this._parent);

  /// ```dart
  /// "App Settings"
  /// ```
  String get title => """App Settings""";

  /// ```dart
  /// "General"
  /// ```
  String get generalSection => """General""";

  /// ```dart
  /// "Interface"
  /// ```
  String get interfaceSection => """Interface""";

  /// ```dart
  /// "Tap row to complete items"
  /// ```
  String get tapRowToComplete => """Tap row to complete items""";

  /// ```dart
  /// "When off, items are only marked complete by tapping the checkbox."
  /// ```
  String get tapRowToCompleteBody =>
      """When off, items are only marked complete by tapping the checkbox.""";

  /// ```dart
  /// "Show spacing between categories in list items"
  /// ```
  String get categorySpacing =>
      """Show spacing between categories in list items""";

  /// ```dart
  /// "Only visible when sorting by category"
  /// ```
  String get categorySpacingBody => """Only visible when sorting by category""";
  CategorySpacingNamesSettingsMessages get categorySpacingNames =>
      CategorySpacingNamesSettingsMessages(this);

  /// ```dart
  /// "Language"
  /// ```
  String get language => """Language""";
  LanguageNamesSettingsMessages get languageNames =>
      LanguageNamesSettingsMessages(this);

  /// ```dart
  /// "Theme"
  /// ```
  String get theme => """Theme""";
  ThemeNamesSettingsMessages get themeNames => ThemeNamesSettingsMessages(this);

  /// ```dart
  /// "Notifications"
  /// ```
  String get notificationsSection => """Notifications""";

  /// ```dart
  /// "Enable notifications"
  /// ```
  String get enableNotifications => """Enable notifications""";

  /// ```dart
  /// "Show alerts when household members add or update content."
  /// ```
  String get enableNotificationsBody =>
      """Show alerts when household members add or update content.""";

  /// ```dart
  /// "Check for new activity"
  /// ```
  String get pollInterval => """Check for new activity""";

  /// ```dart
  /// "Every 15 minutes"
  /// ```
  String get pollInterval15m => """Every 15 minutes""";

  /// ```dart
  /// "Every 30 minutes"
  /// ```
  String get pollInterval30m => """Every 30 minutes""";

  /// ```dart
  /// "Every hour"
  /// ```
  String get pollInterval1h => """Every hour""";

  /// ```dart
  /// "Every 2 hours"
  /// ```
  String get pollInterval2h => """Every 2 hours""";

  /// ```dart
  /// "Every 6 hours"
  /// ```
  String get pollInterval6h => """Every 6 hours""";

  /// ```dart
  /// "Notification permission was denied. Enable it in system settings."
  /// ```
  String get permissionDenied =>
      """Notification permission was denied. Enable it in system settings.""";
}

class CategorySpacingNamesSettingsMessages {
  final SettingsMessages _parent;
  const CategorySpacingNamesSettingsMessages(this._parent);

  /// ```dart
  /// "Disabled"
  /// ```
  String get disabled => """Disabled""";

  /// ```dart
  /// "Space"
  /// ```
  String get space => """Space""";

  /// ```dart
  /// "Divider"
  /// ```
  String get divider => """Divider""";
}

class LanguageNamesSettingsMessages {
  final SettingsMessages _parent;
  const LanguageNamesSettingsMessages(this._parent);

  /// ```dart
  /// "System default"
  /// ```
  String get system => """System default""";

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

class ThemeNamesSettingsMessages {
  final SettingsMessages _parent;
  const ThemeNamesSettingsMessages(this._parent);

  /// ```dart
  /// "System default"
  /// ```
  String get system => """System default""";

  /// ```dart
  /// "Light"
  /// ```
  String get light => """Light""";

  /// ```dart
  /// "Dark"
  /// ```
  String get dark => """Dark""";
}

class NotificationsMessages {
  final Messages _parent;
  const NotificationsMessages(this._parent);

  /// ```dart
  /// "Notifications"
  /// ```
  String get title => """Notifications""";

  /// ```dart
  /// "No new notifications."
  /// ```
  String get empty => """No new notifications.""";

  /// ```dart
  /// "Failed to load notifications."
  /// ```
  String get failedToLoad => """Failed to load notifications.""";

  /// ```dart
  /// "Dismiss all"
  /// ```
  String get dismissAll => """Dismiss all""";

  /// ```dart
  /// "just now"
  /// ```
  String get justNow => """just now""";

  /// ```dart
  /// "${count}m ago"
  /// ```
  String minutesAgo(int count) => """${count}m ago""";

  /// ```dart
  /// "${count}h ago"
  /// ```
  String hoursAgo(int count) => """${count}h ago""";

  /// ```dart
  /// "${count}d ago"
  /// ```
  String daysAgo(int count) => """${count}d ago""";
}

class CategoriesMessages {
  final Messages _parent;
  const CategoriesMessages(this._parent);

  /// ```dart
  /// "Manage categories"
  /// ```
  String get manageTitle => """Manage categories""";

  /// ```dart
  /// "No categories yet."
  /// ```
  String get noCategories => """No categories yet.""";

  /// ```dart
  /// "Edit category"
  /// ```
  String get editTitle => """Edit category""";

  /// ```dart
  /// "New category"
  /// ```
  String get addTitle => """New category""";

  /// ```dart
  /// "Name"
  /// ```
  String get name => """Name""";

  /// ```dart
  /// "Icon"
  /// ```
  String get icon => """Icon""";

  /// ```dart
  /// "Color"
  /// ```
  String get color => """Color""";

  /// ```dart
  /// "Failed to save category."
  /// ```
  String get saveFailed => """Failed to save category.""";

  /// ```dart
  /// "Failed to delete category."
  /// ```
  String get deleteFailed => """Failed to delete category.""";

  /// ```dart
  /// "Delete this category?"
  /// ```
  String get deleteConfirm => """Delete this category?""";

  /// ```dart
  /// "Items currently in this category will be uncategorized. This cannot be undone."
  /// ```
  String get deleteConfirmBody =>
      """Items currently in this category will be uncategorized. This cannot be undone.""";
}

class ChecklistsMessages {
  final Messages _parent;
  const ChecklistsMessages(this._parent);

  /// ```dart
  /// "Categories"
  /// ```
  String get categories => """Categories""";

  /// ```dart
  /// "No checklists yet."
  /// ```
  String get noChecklists => """No checklists yet.""";

  /// ```dart
  /// "No items in this list."
  /// ```
  String get noItems => """No items in this list.""";

  /// ```dart
  /// "No items match your search."
  /// ```
  String get noSearchResults => """No items match your search.""";

  /// ```dart
  /// "Type to filter..."
  /// ```
  String get searchHint => """Type to filter...""";

  /// ```dart
  /// "All"
  /// ```
  String get allCategories => """All""";

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

  /// ```dart
  /// "Move to list"
  /// ```
  String get moveItem => """Move to list""";

  /// ```dart
  /// "Failed to move item."
  /// ```
  String get moveFailed => """Failed to move item.""";

  /// ```dart
  /// "Item marked as done"
  /// ```
  String get itemMarkedDone => """Item marked as done""";

  /// ```dart
  /// "Undo"
  /// ```
  String get undo => """Undo""";

  /// ```dart
  /// "New list"
  /// ```
  String get createList => """New list""";

  /// ```dart
  /// "List name"
  /// ```
  String get listName => """List name""";

  /// ```dart
  /// "Description (optional)"
  /// ```
  String get listDescription => """Description (optional)""";

  /// ```dart
  /// "Icon"
  /// ```
  String get listIcon => """Icon""";

  /// ```dart
  /// "Failed to create list."
  /// ```
  String get createListFailed => """Failed to create list.""";
  ViewItemChecklistsMessages get viewItem => ViewItemChecklistsMessages(this);
  ItemFormChecklistsMessages get itemForm => ItemFormChecklistsMessages(this);
  SortChecklistsMessages get sort => SortChecklistsMessages(this);
}

class ViewItemChecklistsMessages {
  final ChecklistsMessages _parent;
  const ViewItemChecklistsMessages(this._parent);

  /// ```dart
  /// "Quantity:"
  /// ```
  String get quantity => """Quantity:""";

  /// ```dart
  /// "Category:"
  /// ```
  String get category => """Category:""";

  /// ```dart
  /// "Recurrence:"
  /// ```
  String get recurrence => """Recurrence:""";

  /// ```dart
  /// "Next due:"
  /// ```
  String get nextDue => """Next due:""";

  /// ```dart
  /// "Next due (from completion):"
  /// ```
  String get nextDueFromCompletion => """Next due (from completion):""";

  /// ```dart
  /// "Overdue"
  /// ```
  String get overdue => """Overdue""";
}

class ItemFormChecklistsMessages {
  final ChecklistsMessages _parent;
  const ItemFormChecklistsMessages(this._parent);

  /// ```dart
  /// "Add item"
  /// ```
  String get addTitle => """Add item""";

  /// ```dart
  /// "Edit item"
  /// ```
  String get editTitle => """Edit item""";

  /// ```dart
  /// "Item name"
  /// ```
  String get name => """Item name""";

  /// ```dart
  /// "Description"
  /// ```
  String get description => """Description""";

  /// ```dart
  /// "Quantity"
  /// ```
  String get quantity => """Quantity""";

  /// ```dart
  /// "Category"
  /// ```
  String get category => """Category""";

  /// ```dart
  /// "None"
  /// ```
  String get noCategory => """None""";

  /// ```dart
  /// "No categories available."
  /// ```
  String get noCategories => """No categories available.""";

  /// ```dart
  /// "New category"
  /// ```
  String get createCategory => """New category""";

  /// ```dart
  /// "Name"
  /// ```
  String get categoryName => """Name""";

  /// ```dart
  /// "Icon"
  /// ```
  String get categoryIcon => """Icon""";

  /// ```dart
  /// "Color"
  /// ```
  String get categoryColor => """Color""";

  /// ```dart
  /// "Category created."
  /// ```
  String get categoryCreated => """Category created.""";

  /// ```dart
  /// "Failed to create category."
  /// ```
  String get categoryCreateFailed => """Failed to create category.""";

  /// ```dart
  /// "Repeat"
  /// ```
  String get repeat => """Repeat""";

  /// ```dart
  /// "Once"
  /// ```
  String get once => """Once""";

  /// ```dart
  /// "Delete this item once it is marked as done."
  /// ```
  String get onceDescription =>
      """Delete this item once it is marked as done.""";

  /// ```dart
  /// "Image"
  /// ```
  String get image => """Image""";

  /// ```dart
  /// "Add image"
  /// ```
  String get addImage => """Add image""";

  /// ```dart
  /// "Replace"
  /// ```
  String get replaceImage => """Replace""";

  /// ```dart
  /// "Remove"
  /// ```
  String get removeImage => """Remove""";

  /// ```dart
  /// "Failed to save item."
  /// ```
  String get saveFailed => """Failed to save item.""";

  /// ```dart
  /// "Failed to delete item."
  /// ```
  String get deleteFailed => """Failed to delete item.""";

  /// ```dart
  /// "Delete this item?"
  /// ```
  String get deleteConfirm => """Delete this item?""";
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
  /// "By category"
  /// ```
  String get category => """By category""";

  /// ```dart
  /// "Custom"
  /// ```
  String get custom => """Custom""";
}

class NotesWallMessages {
  final Messages _parent;
  const NotesWallMessages(this._parent);

  /// ```dart
  /// "No notes yet."
  /// ```
  String get noNotes => """No notes yet.""";

  /// ```dart
  /// "Failed to load notes."
  /// ```
  String get failedToLoad => """Failed to load notes.""";

  /// ```dart
  /// "Failed to save note."
  /// ```
  String get saveFailed => """Failed to save note.""";

  /// ```dart
  /// "Failed to delete note."
  /// ```
  String get deleteFailed => """Failed to delete note.""";

  /// ```dart
  /// "Delete this note?"
  /// ```
  String get deleteConfirm => """Delete this note?""";

  /// ```dart
  /// "Delete ${_plural(count, one: 'this note', many: '$count notes')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """Delete ${_plural(count, one: 'this note', many: '$count notes')}?""";

  /// ```dart
  /// "New note"
  /// ```
  String get newNote => """New note""";

  /// ```dart
  /// "Edit note"
  /// ```
  String get editNote => """Edit note""";

  /// ```dart
  /// "Title"
  /// ```
  String get title => """Title""";

  /// ```dart
  /// "Content"
  /// ```
  String get content => """Content""";

  /// ```dart
  /// "Color"
  /// ```
  String get color => """Color""";
  SortNotesWallMessages get sort => SortNotesWallMessages(this);
}

class SortNotesWallMessages {
  final NotesWallMessages _parent;
  const SortNotesWallMessages(this._parent);

  /// ```dart
  /// "Newest first"
  /// ```
  String get newestFirst => """Newest first""";

  /// ```dart
  /// "Oldest first"
  /// ```
  String get oldestFirst => """Oldest first""";

  /// ```dart
  /// "Title A–Z"
  /// ```
  String get titleAZ => """Title A–Z""";

  /// ```dart
  /// "Title Z–A"
  /// ```
  String get titleZA => """Title Z–A""";

  /// ```dart
  /// "Custom"
  /// ```
  String get custom => """Custom""";
}

class PhotoBoardMessages {
  final Messages _parent;
  const PhotoBoardMessages(this._parent);

  /// ```dart
  /// "No photos yet."
  /// ```
  String get noPhotos => """No photos yet.""";

  /// ```dart
  /// "Failed to load photos."
  /// ```
  String get failedToLoad => """Failed to load photos.""";

  /// ```dart
  /// "Failed to upload photo."
  /// ```
  String get uploadFailed => """Failed to upload photo.""";

  /// ```dart
  /// "Failed to delete photo."
  /// ```
  String get deleteFailed => """Failed to delete photo.""";

  /// ```dart
  /// "Delete this photo?"
  /// ```
  String get deleteConfirm => """Delete this photo?""";

  /// ```dart
  /// "Delete ${_plural(count, one: 'this photo', many: '$count photos')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """Delete ${_plural(count, one: 'this photo', many: '$count photos')}?""";

  /// ```dart
  /// "Delete folder"
  /// ```
  String get deleteFolder => """Delete folder""";

  /// ```dart
  /// "Delete this folder?"
  /// ```
  String get deleteFolderConfirm => """Delete this folder?""";

  /// ```dart
  /// "Move photos to root"
  /// ```
  String get deleteFolderKeepPhotos => """Move photos to root""";

  /// ```dart
  /// "Delete folder and photos"
  /// ```
  String get deleteFolderDeleteAll => """Delete folder and photos""";

  /// ```dart
  /// "New folder"
  /// ```
  String get newFolder => """New folder""";

  /// ```dart
  /// "Folder name"
  /// ```
  String get folderName => """Folder name""";

  /// ```dart
  /// "Rename folder"
  /// ```
  String get renameFolder => """Rename folder""";

  /// ```dart
  /// "Caption"
  /// ```
  String get caption => """Caption""";

  /// ```dart
  /// "$count"
  /// ```
  String photoCount(int count) => """$count""";
  AddMenuPhotoBoardMessages get addMenu => AddMenuPhotoBoardMessages(this);
  SortPhotoBoardMessages get sort => SortPhotoBoardMessages(this);
}

class AddMenuPhotoBoardMessages {
  final PhotoBoardMessages _parent;
  const AddMenuPhotoBoardMessages(this._parent);

  /// ```dart
  /// "Upload photos"
  /// ```
  String get upload => """Upload photos""";

  /// ```dart
  /// "Take photo"
  /// ```
  String get camera => """Take photo""";

  /// ```dart
  /// "New folder"
  /// ```
  String get newFolder => """New folder""";
}

class SortPhotoBoardMessages {
  final PhotoBoardMessages _parent;
  const SortPhotoBoardMessages(this._parent);

  /// ```dart
  /// "Folders first"
  /// ```
  String get foldersFirst => """Folders first""";

  /// ```dart
  /// "Newest first"
  /// ```
  String get newestFirst => """Newest first""";

  /// ```dart
  /// "Oldest first"
  /// ```
  String get oldestFirst => """Oldest first""";

  /// ```dart
  /// "Caption A–Z"
  /// ```
  String get captionAZ => """Caption A–Z""";

  /// ```dart
  /// "Caption Z–A"
  /// ```
  String get captionZA => """Caption Z–A""";

  /// ```dart
  /// "Custom"
  /// ```
  String get custom => """Custom""";
}

class ShareMessages {
  final Messages _parent;
  const ShareMessages(this._parent);

  /// ```dart
  /// "Share to Pantry"
  /// ```
  String get title => """Share to Pantry""";

  /// ```dart
  /// "Choose house"
  /// ```
  String get chooseHouse => """Choose house""";

  /// ```dart
  /// "Upload to"
  /// ```
  String get choosePhotoDestination => """Upload to""";

  /// ```dart
  /// "Photo Board"
  /// ```
  String get photoBoardRoot => """Photo Board""";

  /// ```dart
  /// "New folder"
  /// ```
  String get newFolder => """New folder""";

  /// ```dart
  /// "Folder name"
  /// ```
  String get newFolderName => """Folder name""";

  /// ```dart
  /// "Failed to create folder."
  /// ```
  String get failedToCreateFolder => """Failed to create folder.""";

  /// ```dart
  /// "Could not open the shared content."
  /// ```
  String get failedToOpenShare => """Could not open the shared content.""";

  /// ```dart
  /// "No houses available. Create a house first."
  /// ```
  String get noHouses => """No houses available. Create a house first.""";
}

class RecurrenceMessages {
  final Messages _parent;
  const RecurrenceMessages(this._parent);

  /// ```dart
  /// "Recurrence"
  /// ```
  String get title => """Recurrence""";

  /// ```dart
  /// "Presets"
  /// ```
  String get presets => """Presets""";

  /// ```dart
  /// "Daily"
  /// ```
  String get daily => """Daily""";

  /// ```dart
  /// "Weekly"
  /// ```
  String get weekly => """Weekly""";

  /// ```dart
  /// "Monthly"
  /// ```
  String get monthly => """Monthly""";

  /// ```dart
  /// "Every"
  /// ```
  String get everyLabel => """Every""";

  /// ```dart
  /// "Unit"
  /// ```
  String get unit => """Unit""";

  /// ```dart
  /// "days"
  /// ```
  String get unitDays => """days""";

  /// ```dart
  /// "weeks"
  /// ```
  String get unitWeeks => """weeks""";

  /// ```dart
  /// "months"
  /// ```
  String get unitMonths => """months""";

  /// ```dart
  /// "years"
  /// ```
  String get unitYears => """years""";

  /// ```dart
  /// "Repeat on"
  /// ```
  String get repeatOn => """Repeat on""";

  /// ```dart
  /// "Ends"
  /// ```
  String get ends => """Ends""";

  /// ```dart
  /// "Never"
  /// ```
  String get never => """Never""";

  /// ```dart
  /// "After"
  /// ```
  String get after => """After""";

  /// ```dart
  /// "occurrences"
  /// ```
  String get occurrences => """occurrences""";

  /// ```dart
  /// "On date"
  /// ```
  String get onDate => """On date""";

  /// ```dart
  /// "Count interval from when the item is ticked off"
  /// ```
  String get countFromCompletion =>
      """Count interval from when the item is ticked off""";

  /// ```dart
  /// "The schedule is fixed: the item reappears on its next scheduled occurrence, regardless of when you tick it off."
  /// ```
  String get countFromCompletionHintOff =>
      """The schedule is fixed: the item reappears on its next scheduled occurrence, regardless of when you tick it off.""";

  /// ```dart
  /// "The next occurrence is counted from the moment you tick the item off, so it always comes back a full interval after it was completed."
  /// ```
  String get countFromCompletionHintOn =>
      """The next occurrence is counted from the moment you tick the item off, so it always comes back a full interval after it was completed.""";

  /// ```dart
  /// "Summary"
  /// ```
  String get summary => """Summary""";

  /// ```dart
  /// "not set"
  /// ```
  String get notSet => """not set""";

  /// ```dart
  /// "set"
  /// ```
  String get set => """set""";

  /// ```dart
  /// "every $unit"
  /// ```
  String every(String unit) => """every $unit""";

  /// ```dart
  /// "Every $unit"
  /// ```
  String everyButton(String unit) => """Every $unit""";

  /// ```dart
  /// "on $days"
  /// ```
  String onDays(String days) => """on $days""";

  /// ```dart
  /// "${_plural(count, one: 'day', many: '$count days')}"
  /// ```
  String day(int count) =>
      """${_plural(count, one: 'day', many: '$count days')}""";

  /// ```dart
  /// "${_plural(count, one: 'week', many: '$count weeks')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'week', many: '$count weeks')}""";

  /// ```dart
  /// "${_plural(count, one: 'month', many: '$count months')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'month', many: '$count months')}""";

  /// ```dart
  /// "${_plural(count, one: 'year', many: '$count years')}"
  /// ```
  String year(int count) =>
      """${_plural(count, one: 'year', many: '$count years')}""";
  DayNamesRecurrenceMessages get dayNames => DayNamesRecurrenceMessages(this);
  DayAbbrRecurrenceMessages get dayAbbr => DayAbbrRecurrenceMessages(this);
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

class DayAbbrRecurrenceMessages {
  final RecurrenceMessages _parent;
  const DayAbbrRecurrenceMessages(this._parent);

  /// ```dart
  /// "Mo"
  /// ```
  String get mo => """Mo""";

  /// ```dart
  /// "Tu"
  /// ```
  String get tu => """Tu""";

  /// ```dart
  /// "We"
  /// ```
  String get we => """We""";

  /// ```dart
  /// "Th"
  /// ```
  String get th => """Th""";

  /// ```dart
  /// "Fr"
  /// ```
  String get fr => """Fr""";

  /// ```dart
  /// "Sa"
  /// ```
  String get sa => """Sa""";

  /// ```dart
  /// "Su"
  /// ```
  String get su => """Su""";
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
  """home.noHouses""": """No houses yet.""",
  """home.noHousesBody""":
      """Houses are shared spaces for your household. Create your first house to start adding checklists, photos and notes.""",
  """home.createHouse""": """Create house""",
  """home.houseName""": """House name""",
  """home.houseDescription""": """Description (optional)""",
  """home.createHouseFailed""": """Failed to create house.""",
  """home.failedToLoadHouses""": """Failed to load houses.""",
  """home.serverAppMissingTitle""": """Pantry is not installed""",
  """home.serverAppMissingBody""":
      """This app is a client for the Pantry app on Nextcloud. It looks like Pantry isn't installed on your server yet. Ask your administrator to install it from the Nextcloud app store, or install it yourself if you have admin access.""",
  """home.openAppStore""": """Open Nextcloud apps""",
  """home.learnMore""": """Learn more""",
  """nav.checklists""": """Checklists""",
  """nav.photoBoard""": """Photo Board""",
  """nav.notesWall""": """Notes Wall""",
  """notificationsIntro.title""": """Stay in the loop""",
  """notificationsIntro.body""":
      """Pantry can notify you when household members add items to checklists, upload photos, or leave notes. Notifications are fetched from your own Nextcloud server — nothing goes through Google or third parties.""",
  """notificationsIntro.bullet1""": """Household activity alerts""",
  """notificationsIntro.bullet2""": """Fetched directly from your server""",
  """notificationsIntro.bullet3""": """Works even when the app is closed""",
  """notificationsIntro.enableButton""": """Enable notifications""",
  """notificationsIntro.skipButton""": """Not now""",
  """notificationsIntro.permissionDeniedTitle""": """Permission denied""",
  """notificationsIntro.permissionDeniedBody""":
      """You can enable notifications later in App Settings. If your device blocks them, you'll need to allow them in system settings first.""",
  """notificationsIntro.ok""": """OK""",
  """about.title""": """About""",
  """about.developer""": """Developer""",
  """about.email""": """Email""",
  """about.repository""": """Source code""",
  """about.nextcloudApp""": """Nextcloud app""",
  """about.privacyPolicy""": """Privacy policy""",
  """about.feedback""": """Feedback & issues""",
  """settings.title""": """App Settings""",
  """settings.generalSection""": """General""",
  """settings.interfaceSection""": """Interface""",
  """settings.tapRowToComplete""": """Tap row to complete items""",
  """settings.tapRowToCompleteBody""":
      """When off, items are only marked complete by tapping the checkbox.""",
  """settings.categorySpacing""":
      """Show spacing between categories in list items""",
  """settings.categorySpacingBody""":
      """Only visible when sorting by category""",
  """settings.categorySpacingNames.disabled""": """Disabled""",
  """settings.categorySpacingNames.space""": """Space""",
  """settings.categorySpacingNames.divider""": """Divider""",
  """settings.language""": """Language""",
  """settings.languageNames.system""": """System default""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
  """settings.theme""": """Theme""",
  """settings.themeNames.system""": """System default""",
  """settings.themeNames.light""": """Light""",
  """settings.themeNames.dark""": """Dark""",
  """settings.notificationsSection""": """Notifications""",
  """settings.enableNotifications""": """Enable notifications""",
  """settings.enableNotificationsBody""":
      """Show alerts when household members add or update content.""",
  """settings.pollInterval""": """Check for new activity""",
  """settings.pollInterval15m""": """Every 15 minutes""",
  """settings.pollInterval30m""": """Every 30 minutes""",
  """settings.pollInterval1h""": """Every hour""",
  """settings.pollInterval2h""": """Every 2 hours""",
  """settings.pollInterval6h""": """Every 6 hours""",
  """settings.permissionDenied""":
      """Notification permission was denied. Enable it in system settings.""",
  """notifications.title""": """Notifications""",
  """notifications.empty""": """No new notifications.""",
  """notifications.failedToLoad""": """Failed to load notifications.""",
  """notifications.dismissAll""": """Dismiss all""",
  """notifications.justNow""": """just now""",
  """categories.manageTitle""": """Manage categories""",
  """categories.noCategories""": """No categories yet.""",
  """categories.editTitle""": """Edit category""",
  """categories.addTitle""": """New category""",
  """categories.name""": """Name""",
  """categories.icon""": """Icon""",
  """categories.color""": """Color""",
  """categories.saveFailed""": """Failed to save category.""",
  """categories.deleteFailed""": """Failed to delete category.""",
  """categories.deleteConfirm""": """Delete this category?""",
  """categories.deleteConfirmBody""":
      """Items currently in this category will be uncategorized. This cannot be undone.""",
  """checklists.categories""": """Categories""",
  """checklists.noChecklists""": """No checklists yet.""",
  """checklists.noItems""": """No items in this list.""",
  """checklists.noSearchResults""": """No items match your search.""",
  """checklists.searchHint""": """Type to filter...""",
  """checklists.allCategories""": """All""",
  """checklists.failedToLoad""": """Failed to load checklists.""",
  """checklists.failedToLoadItems""": """Failed to load items.""",
  """checklists.editItem""": """Edit item""",
  """checklists.removeItem""": """Remove item""",
  """checklists.moveItem""": """Move to list""",
  """checklists.moveFailed""": """Failed to move item.""",
  """checklists.itemMarkedDone""": """Item marked as done""",
  """checklists.undo""": """Undo""",
  """checklists.createList""": """New list""",
  """checklists.listName""": """List name""",
  """checklists.listDescription""": """Description (optional)""",
  """checklists.listIcon""": """Icon""",
  """checklists.createListFailed""": """Failed to create list.""",
  """checklists.viewItem.quantity""": """Quantity:""",
  """checklists.viewItem.category""": """Category:""",
  """checklists.viewItem.recurrence""": """Recurrence:""",
  """checklists.viewItem.nextDue""": """Next due:""",
  """checklists.viewItem.nextDueFromCompletion""":
      """Next due (from completion):""",
  """checklists.viewItem.overdue""": """Overdue""",
  """checklists.itemForm.addTitle""": """Add item""",
  """checklists.itemForm.editTitle""": """Edit item""",
  """checklists.itemForm.name""": """Item name""",
  """checklists.itemForm.description""": """Description""",
  """checklists.itemForm.quantity""": """Quantity""",
  """checklists.itemForm.category""": """Category""",
  """checklists.itemForm.noCategory""": """None""",
  """checklists.itemForm.noCategories""": """No categories available.""",
  """checklists.itemForm.createCategory""": """New category""",
  """checklists.itemForm.categoryName""": """Name""",
  """checklists.itemForm.categoryIcon""": """Icon""",
  """checklists.itemForm.categoryColor""": """Color""",
  """checklists.itemForm.categoryCreated""": """Category created.""",
  """checklists.itemForm.categoryCreateFailed""":
      """Failed to create category.""",
  """checklists.itemForm.repeat""": """Repeat""",
  """checklists.itemForm.once""": """Once""",
  """checklists.itemForm.onceDescription""":
      """Delete this item once it is marked as done.""",
  """checklists.itemForm.image""": """Image""",
  """checklists.itemForm.addImage""": """Add image""",
  """checklists.itemForm.replaceImage""": """Replace""",
  """checklists.itemForm.removeImage""": """Remove""",
  """checklists.itemForm.saveFailed""": """Failed to save item.""",
  """checklists.itemForm.deleteFailed""": """Failed to delete item.""",
  """checklists.itemForm.deleteConfirm""": """Delete this item?""",
  """checklists.sort.newestFirst""": """Newest first""",
  """checklists.sort.oldestFirst""": """Oldest first""",
  """checklists.sort.nameAZ""": """Name A–Z""",
  """checklists.sort.nameZA""": """Name Z–A""",
  """checklists.sort.category""": """By category""",
  """checklists.sort.custom""": """Custom""",
  """notesWall.noNotes""": """No notes yet.""",
  """notesWall.failedToLoad""": """Failed to load notes.""",
  """notesWall.saveFailed""": """Failed to save note.""",
  """notesWall.deleteFailed""": """Failed to delete note.""",
  """notesWall.deleteConfirm""": """Delete this note?""",
  """notesWall.newNote""": """New note""",
  """notesWall.editNote""": """Edit note""",
  """notesWall.title""": """Title""",
  """notesWall.content""": """Content""",
  """notesWall.color""": """Color""",
  """notesWall.sort.newestFirst""": """Newest first""",
  """notesWall.sort.oldestFirst""": """Oldest first""",
  """notesWall.sort.titleAZ""": """Title A–Z""",
  """notesWall.sort.titleZA""": """Title Z–A""",
  """notesWall.sort.custom""": """Custom""",
  """photoBoard.noPhotos""": """No photos yet.""",
  """photoBoard.failedToLoad""": """Failed to load photos.""",
  """photoBoard.uploadFailed""": """Failed to upload photo.""",
  """photoBoard.deleteFailed""": """Failed to delete photo.""",
  """photoBoard.deleteConfirm""": """Delete this photo?""",
  """photoBoard.deleteFolder""": """Delete folder""",
  """photoBoard.deleteFolderConfirm""": """Delete this folder?""",
  """photoBoard.deleteFolderKeepPhotos""": """Move photos to root""",
  """photoBoard.deleteFolderDeleteAll""": """Delete folder and photos""",
  """photoBoard.newFolder""": """New folder""",
  """photoBoard.folderName""": """Folder name""",
  """photoBoard.renameFolder""": """Rename folder""",
  """photoBoard.caption""": """Caption""",
  """photoBoard.addMenu.upload""": """Upload photos""",
  """photoBoard.addMenu.camera""": """Take photo""",
  """photoBoard.addMenu.newFolder""": """New folder""",
  """photoBoard.sort.foldersFirst""": """Folders first""",
  """photoBoard.sort.newestFirst""": """Newest first""",
  """photoBoard.sort.oldestFirst""": """Oldest first""",
  """photoBoard.sort.captionAZ""": """Caption A–Z""",
  """photoBoard.sort.captionZA""": """Caption Z–A""",
  """photoBoard.sort.custom""": """Custom""",
  """share.title""": """Share to Pantry""",
  """share.chooseHouse""": """Choose house""",
  """share.choosePhotoDestination""": """Upload to""",
  """share.photoBoardRoot""": """Photo Board""",
  """share.newFolder""": """New folder""",
  """share.newFolderName""": """Folder name""",
  """share.failedToCreateFolder""": """Failed to create folder.""",
  """share.failedToOpenShare""": """Could not open the shared content.""",
  """share.noHouses""": """No houses available. Create a house first.""",
  """recurrence.title""": """Recurrence""",
  """recurrence.presets""": """Presets""",
  """recurrence.daily""": """Daily""",
  """recurrence.weekly""": """Weekly""",
  """recurrence.monthly""": """Monthly""",
  """recurrence.everyLabel""": """Every""",
  """recurrence.unit""": """Unit""",
  """recurrence.unitDays""": """days""",
  """recurrence.unitWeeks""": """weeks""",
  """recurrence.unitMonths""": """months""",
  """recurrence.unitYears""": """years""",
  """recurrence.repeatOn""": """Repeat on""",
  """recurrence.ends""": """Ends""",
  """recurrence.never""": """Never""",
  """recurrence.after""": """After""",
  """recurrence.occurrences""": """occurrences""",
  """recurrence.onDate""": """On date""",
  """recurrence.countFromCompletion""":
      """Count interval from when the item is ticked off""",
  """recurrence.countFromCompletionHintOff""":
      """The schedule is fixed: the item reappears on its next scheduled occurrence, regardless of when you tick it off.""",
  """recurrence.countFromCompletionHintOn""":
      """The next occurrence is counted from the moment you tick the item off, so it always comes back a full interval after it was completed.""",
  """recurrence.summary""": """Summary""",
  """recurrence.notSet""": """not set""",
  """recurrence.set""": """set""",
  """recurrence.dayNames.monday""": """Monday""",
  """recurrence.dayNames.tuesday""": """Tuesday""",
  """recurrence.dayNames.wednesday""": """Wednesday""",
  """recurrence.dayNames.thursday""": """Thursday""",
  """recurrence.dayNames.friday""": """Friday""",
  """recurrence.dayNames.saturday""": """Saturday""",
  """recurrence.dayNames.sunday""": """Sunday""",
  """recurrence.dayAbbr.mo""": """Mo""",
  """recurrence.dayAbbr.tu""": """Tu""",
  """recurrence.dayAbbr.we""": """We""",
  """recurrence.dayAbbr.th""": """Th""",
  """recurrence.dayAbbr.fr""": """Fr""",
  """recurrence.dayAbbr.sa""": """Sa""",
  """recurrence.dayAbbr.su""": """Su""",
};
