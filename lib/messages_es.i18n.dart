// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:i18n/i18n.dart' as i18n;
import 'messages.i18n.dart';

String get _languageCode => 'es';
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

class MessagesEs extends Messages {
  const MessagesEs();
  String get locale => "es";
  String get languageCode => "es";
  CommonMessagesEs get common => CommonMessagesEs(this);
  LoginMessagesEs get login => LoginMessagesEs(this);
  HomeMessagesEs get home => HomeMessagesEs(this);
  NavMessagesEs get nav => NavMessagesEs(this);
  NotificationsIntroMessagesEs get notificationsIntro =>
      NotificationsIntroMessagesEs(this);
  SettingsMessagesEs get settings => SettingsMessagesEs(this);
  NotificationsMessagesEs get notifications => NotificationsMessagesEs(this);
  CategoriesMessagesEs get categories => CategoriesMessagesEs(this);
  ChecklistsMessagesEs get checklists => ChecklistsMessagesEs(this);
  NotesWallMessagesEs get notesWall => NotesWallMessagesEs(this);
  PhotoBoardMessagesEs get photoBoard => PhotoBoardMessagesEs(this);
  RecurrenceMessagesEs get recurrence => RecurrenceMessagesEs(this);
}

class CommonMessagesEs extends CommonMessages {
  final MessagesEs _parent;
  const CommonMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Pantry"
  /// ```
  String get appTitle => """Pantry""";

  /// ```dart
  /// "Cancelar"
  /// ```
  String get cancel => """Cancelar""";

  /// ```dart
  /// "Eliminar"
  /// ```
  String get delete => """Eliminar""";

  /// ```dart
  /// "Guardar"
  /// ```
  String get save => """Guardar""";

  /// ```dart
  /// "Reintentar"
  /// ```
  String get retry => """Reintentar""";

  /// ```dart
  /// "Cerrar sesión"
  /// ```
  String get logout => """Cerrar sesión""";

  /// ```dart
  /// "Cargando..."
  /// ```
  String get loading => """Cargando...""";

  /// ```dart
  /// "Error"
  /// ```
  String get error => """Error""";
}

class LoginMessagesEs extends LoginMessages {
  final MessagesEs _parent;
  const LoginMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Conéctate a tu instancia de Nextcloud"
  /// ```
  String get connectToNextcloud => """Conéctate a tu instancia de Nextcloud""";

  /// ```dart
  /// "URL del servidor"
  /// ```
  String get serverUrl => """URL del servidor""";

  /// ```dart
  /// "cloud.example.com"
  /// ```
  String get serverUrlHint => """cloud.example.com""";

  /// ```dart
  /// "Conectar"
  /// ```
  String get connect => """Conectar""";

  /// ```dart
  /// """
  /// Esperando autenticación...
  /// Por favor, completa el inicio de sesión en tu navegador.
  /// """
  /// ```
  String get waitingForAuth => """Esperando autenticación...
Por favor, completa el inicio de sesión en tu navegador.""";

  /// ```dart
  /// "No se pudo conectar al servidor. Por favor, verifica la URL."
  /// ```
  String get couldNotConnect =>
      """No se pudo conectar al servidor. Por favor, verifica la URL.""";

  /// ```dart
  /// "Inicio de sesión fallido. Por favor, inténtalo de nuevo."
  /// ```
  String get loginFailed =>
      """Inicio de sesión fallido. Por favor, inténtalo de nuevo.""";
}

class HomeMessagesEs extends HomeMessages {
  final MessagesEs _parent;
  const HomeMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Aún no hay casas."
  /// ```
  String get noHouses => """Aún no hay casas.""";

  /// ```dart
  /// "Las casas son espacios compartidos para tu hogar. Crea tu primera casa para comenzar a agregar listas, fotos y notas."
  /// ```
  String get noHousesBody =>
      """Las casas son espacios compartidos para tu hogar. Crea tu primera casa para comenzar a agregar listas, fotos y notas.""";

  /// ```dart
  /// "Crear casa"
  /// ```
  String get createHouse => """Crear casa""";

  /// ```dart
  /// "Nombre de la casa"
  /// ```
  String get houseName => """Nombre de la casa""";

  /// ```dart
  /// "Descripción (opcional)"
  /// ```
  String get houseDescription => """Descripción (opcional)""";

  /// ```dart
  /// "No se pudo crear la casa."
  /// ```
  String get createHouseFailed => """No se pudo crear la casa.""";

  /// ```dart
  /// "No se pudieron cargar las casas."
  /// ```
  String get failedToLoadHouses => """No se pudieron cargar las casas.""";

  /// ```dart
  /// "Pantry no está instalado"
  /// ```
  String get serverAppMissingTitle => """Pantry no está instalado""";

  /// ```dart
  /// "Esta app es un cliente para la app Pantry en Nextcloud. Parece que Pantry aún no está instalado en tu servidor. Pide a tu administrador que lo instale desde la tienda de apps de Nextcloud, o instálalo tú mismo si tienes acceso de administrador."
  /// ```
  String get serverAppMissingBody =>
      """Esta app es un cliente para la app Pantry en Nextcloud. Parece que Pantry aún no está instalado en tu servidor. Pide a tu administrador que lo instale desde la tienda de apps de Nextcloud, o instálalo tú mismo si tienes acceso de administrador.""";

  /// ```dart
  /// "Abrir apps de Nextcloud"
  /// ```
  String get openAppStore => """Abrir apps de Nextcloud""";

  /// ```dart
  /// "Más información"
  /// ```
  String get learnMore => """Más información""";
}

class NavMessagesEs extends NavMessages {
  final MessagesEs _parent;
  const NavMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Listas"
  /// ```
  String get checklists => """Listas""";

  /// ```dart
  /// "Tablero de fotos"
  /// ```
  String get photoBoard => """Tablero de fotos""";

  /// ```dart
  /// "Muro de notas"
  /// ```
  String get notesWall => """Muro de notas""";
}

class NotificationsIntroMessagesEs extends NotificationsIntroMessages {
  final MessagesEs _parent;
  const NotificationsIntroMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Mantente al día"
  /// ```
  String get title => """Mantente al día""";

  /// ```dart
  /// "Pantry puede notificarte cuando los miembros del hogar agreguen artículos a las listas, suban fotos o dejen notas. Las notificaciones se obtienen de tu propio servidor Nextcloud — nada pasa por Google ni terceros."
  /// ```
  String get body =>
      """Pantry puede notificarte cuando los miembros del hogar agreguen artículos a las listas, suban fotos o dejen notas. Las notificaciones se obtienen de tu propio servidor Nextcloud — nada pasa por Google ni terceros.""";

  /// ```dart
  /// "Alertas de actividad del hogar"
  /// ```
  String get bullet1 => """Alertas de actividad del hogar""";

  /// ```dart
  /// "Obtenidas directamente de tu servidor"
  /// ```
  String get bullet2 => """Obtenidas directamente de tu servidor""";

  /// ```dart
  /// "Funciona incluso con la app cerrada"
  /// ```
  String get bullet3 => """Funciona incluso con la app cerrada""";

  /// ```dart
  /// "Activar notificaciones"
  /// ```
  String get enableButton => """Activar notificaciones""";

  /// ```dart
  /// "Ahora no"
  /// ```
  String get skipButton => """Ahora no""";

  /// ```dart
  /// "Permiso denegado"
  /// ```
  String get permissionDeniedTitle => """Permiso denegado""";

  /// ```dart
  /// "Puedes activar las notificaciones más tarde en los ajustes de la app. Si tu dispositivo las bloquea, primero deberás permitirlas en los ajustes del sistema."
  /// ```
  String get permissionDeniedBody =>
      """Puedes activar las notificaciones más tarde en los ajustes de la app. Si tu dispositivo las bloquea, primero deberás permitirlas en los ajustes del sistema.""";

  /// ```dart
  /// "OK"
  /// ```
  String get ok => """OK""";
}

class SettingsMessagesEs extends SettingsMessages {
  final MessagesEs _parent;
  const SettingsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Ajustes de la app"
  /// ```
  String get title => """Ajustes de la app""";

  /// ```dart
  /// "General"
  /// ```
  String get generalSection => """General""";

  /// ```dart
  /// "Idioma"
  /// ```
  String get language => """Idioma""";
  LanguageNamesSettingsMessagesEs get languageNames =>
      LanguageNamesSettingsMessagesEs(this);

  /// ```dart
  /// "Notificaciones"
  /// ```
  String get notificationsSection => """Notificaciones""";

  /// ```dart
  /// "Activar notificaciones"
  /// ```
  String get enableNotifications => """Activar notificaciones""";

  /// ```dart
  /// "Mostrar alertas cuando los miembros del hogar agreguen o actualicen contenido."
  /// ```
  String get enableNotificationsBody =>
      """Mostrar alertas cuando los miembros del hogar agreguen o actualicen contenido.""";

  /// ```dart
  /// "Buscar nueva actividad"
  /// ```
  String get pollInterval => """Buscar nueva actividad""";

  /// ```dart
  /// "Cada 15 minutos"
  /// ```
  String get pollInterval15m => """Cada 15 minutos""";

  /// ```dart
  /// "Cada 30 minutos"
  /// ```
  String get pollInterval30m => """Cada 30 minutos""";

  /// ```dart
  /// "Cada hora"
  /// ```
  String get pollInterval1h => """Cada hora""";

  /// ```dart
  /// "Cada 2 horas"
  /// ```
  String get pollInterval2h => """Cada 2 horas""";

  /// ```dart
  /// "Cada 6 horas"
  /// ```
  String get pollInterval6h => """Cada 6 horas""";

  /// ```dart
  /// "El permiso de notificaciones fue denegado. Actívalo en los ajustes del sistema."
  /// ```
  String get permissionDenied =>
      """El permiso de notificaciones fue denegado. Actívalo en los ajustes del sistema.""";
}

class LanguageNamesSettingsMessagesEs extends LanguageNamesSettingsMessages {
  final SettingsMessagesEs _parent;
  const LanguageNamesSettingsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Predeterminado del sistema"
  /// ```
  String get system => """Predeterminado del sistema""";

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

class NotificationsMessagesEs extends NotificationsMessages {
  final MessagesEs _parent;
  const NotificationsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Notificaciones"
  /// ```
  String get title => """Notificaciones""";

  /// ```dart
  /// "No hay notificaciones nuevas."
  /// ```
  String get empty => """No hay notificaciones nuevas.""";

  /// ```dart
  /// "No se pudieron cargar las notificaciones."
  /// ```
  String get failedToLoad => """No se pudieron cargar las notificaciones.""";

  /// ```dart
  /// "Descartar todas"
  /// ```
  String get dismissAll => """Descartar todas""";

  /// ```dart
  /// "ahora mismo"
  /// ```
  String get justNow => """ahora mismo""";

  /// ```dart
  /// "hace ${count} min"
  /// ```
  String minutesAgo(int count) => """hace ${count} min""";

  /// ```dart
  /// "hace ${count} h"
  /// ```
  String hoursAgo(int count) => """hace ${count} h""";

  /// ```dart
  /// "hace ${count} d"
  /// ```
  String daysAgo(int count) => """hace ${count} d""";
}

class CategoriesMessagesEs extends CategoriesMessages {
  final MessagesEs _parent;
  const CategoriesMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Gestionar categorías"
  /// ```
  String get manageTitle => """Gestionar categorías""";

  /// ```dart
  /// "Aún no hay categorías."
  /// ```
  String get noCategories => """Aún no hay categorías.""";

  /// ```dart
  /// "Editar categoría"
  /// ```
  String get editTitle => """Editar categoría""";

  /// ```dart
  /// "Nueva categoría"
  /// ```
  String get addTitle => """Nueva categoría""";

  /// ```dart
  /// "Nombre"
  /// ```
  String get name => """Nombre""";

  /// ```dart
  /// "Icono"
  /// ```
  String get icon => """Icono""";

  /// ```dart
  /// "Color"
  /// ```
  String get color => """Color""";

  /// ```dart
  /// "No se pudo guardar la categoría."
  /// ```
  String get saveFailed => """No se pudo guardar la categoría.""";

  /// ```dart
  /// "No se pudo eliminar la categoría."
  /// ```
  String get deleteFailed => """No se pudo eliminar la categoría.""";

  /// ```dart
  /// "¿Eliminar esta categoría?"
  /// ```
  String get deleteConfirm => """¿Eliminar esta categoría?""";

  /// ```dart
  /// "Los artículos en esta categoría quedarán sin categoría. Esta acción no se puede deshacer."
  /// ```
  String get deleteConfirmBody =>
      """Los artículos en esta categoría quedarán sin categoría. Esta acción no se puede deshacer.""";
}

class ChecklistsMessagesEs extends ChecklistsMessages {
  final MessagesEs _parent;
  const ChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Categorías"
  /// ```
  String get categories => """Categorías""";

  /// ```dart
  /// "Aún no hay listas."
  /// ```
  String get noChecklists => """Aún no hay listas.""";

  /// ```dart
  /// "No hay artículos en esta lista."
  /// ```
  String get noItems => """No hay artículos en esta lista.""";

  /// ```dart
  /// "No se pudieron cargar las listas."
  /// ```
  String get failedToLoad => """No se pudieron cargar las listas.""";

  /// ```dart
  /// "No se pudieron cargar los artículos."
  /// ```
  String get failedToLoadItems => """No se pudieron cargar los artículos.""";

  /// ```dart
  /// "Completados ($count)"
  /// ```
  String completedCount(int count) => """Completados ($count)""";

  /// ```dart
  /// "Editar artículo"
  /// ```
  String get editItem => """Editar artículo""";

  /// ```dart
  /// "Eliminar artículo"
  /// ```
  String get removeItem => """Eliminar artículo""";

  /// ```dart
  /// "Mover a lista"
  /// ```
  String get moveItem => """Mover a lista""";

  /// ```dart
  /// "No se pudo mover el artículo."
  /// ```
  String get moveFailed => """No se pudo mover el artículo.""";

  /// ```dart
  /// "Nueva lista"
  /// ```
  String get createList => """Nueva lista""";

  /// ```dart
  /// "Nombre de la lista"
  /// ```
  String get listName => """Nombre de la lista""";

  /// ```dart
  /// "Descripción (opcional)"
  /// ```
  String get listDescription => """Descripción (opcional)""";

  /// ```dart
  /// "Icono"
  /// ```
  String get listIcon => """Icono""";

  /// ```dart
  /// "No se pudo crear la lista."
  /// ```
  String get createListFailed => """No se pudo crear la lista.""";
  ViewItemChecklistsMessagesEs get viewItem =>
      ViewItemChecklistsMessagesEs(this);
  ItemFormChecklistsMessagesEs get itemForm =>
      ItemFormChecklistsMessagesEs(this);
  SortChecklistsMessagesEs get sort => SortChecklistsMessagesEs(this);
}

class ViewItemChecklistsMessagesEs extends ViewItemChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const ViewItemChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Cantidad:"
  /// ```
  String get quantity => """Cantidad:""";

  /// ```dart
  /// "Categoría:"
  /// ```
  String get category => """Categoría:""";

  /// ```dart
  /// "Recurrencia:"
  /// ```
  String get recurrence => """Recurrencia:""";

  /// ```dart
  /// "Próximo vencimiento:"
  /// ```
  String get nextDue => """Próximo vencimiento:""";

  /// ```dart
  /// "Próximo vencimiento (desde finalización):"
  /// ```
  String get nextDueFromCompletion =>
      """Próximo vencimiento (desde finalización):""";

  /// ```dart
  /// "Vencido"
  /// ```
  String get overdue => """Vencido""";
}

class ItemFormChecklistsMessagesEs extends ItemFormChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const ItemFormChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Agregar artículo"
  /// ```
  String get addTitle => """Agregar artículo""";

  /// ```dart
  /// "Editar artículo"
  /// ```
  String get editTitle => """Editar artículo""";

  /// ```dart
  /// "Nombre del artículo"
  /// ```
  String get name => """Nombre del artículo""";

  /// ```dart
  /// "Descripción"
  /// ```
  String get description => """Descripción""";

  /// ```dart
  /// "Cantidad"
  /// ```
  String get quantity => """Cantidad""";

  /// ```dart
  /// "Categoría"
  /// ```
  String get category => """Categoría""";

  /// ```dart
  /// "Ninguna"
  /// ```
  String get noCategory => """Ninguna""";

  /// ```dart
  /// "No hay categorías disponibles."
  /// ```
  String get noCategories => """No hay categorías disponibles.""";

  /// ```dart
  /// "Nueva categoría"
  /// ```
  String get createCategory => """Nueva categoría""";

  /// ```dart
  /// "Nombre"
  /// ```
  String get categoryName => """Nombre""";

  /// ```dart
  /// "Icono"
  /// ```
  String get categoryIcon => """Icono""";

  /// ```dart
  /// "Color"
  /// ```
  String get categoryColor => """Color""";

  /// ```dart
  /// "Categoría creada."
  /// ```
  String get categoryCreated => """Categoría creada.""";

  /// ```dart
  /// "No se pudo crear la categoría."
  /// ```
  String get categoryCreateFailed => """No se pudo crear la categoría.""";

  /// ```dart
  /// "Repetir"
  /// ```
  String get repeat => """Repetir""";

  /// ```dart
  /// "No se pudo guardar el artículo."
  /// ```
  String get saveFailed => """No se pudo guardar el artículo.""";

  /// ```dart
  /// "No se pudo eliminar el artículo."
  /// ```
  String get deleteFailed => """No se pudo eliminar el artículo.""";

  /// ```dart
  /// "¿Eliminar este artículo?"
  /// ```
  String get deleteConfirm => """¿Eliminar este artículo?""";
}

class SortChecklistsMessagesEs extends SortChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const SortChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Más recientes"
  /// ```
  String get newestFirst => """Más recientes""";

  /// ```dart
  /// "Más antiguos"
  /// ```
  String get oldestFirst => """Más antiguos""";

  /// ```dart
  /// "Nombre A–Z"
  /// ```
  String get nameAZ => """Nombre A–Z""";

  /// ```dart
  /// "Nombre Z–A"
  /// ```
  String get nameZA => """Nombre Z–A""";

  /// ```dart
  /// "Por categoría"
  /// ```
  String get category => """Por categoría""";

  /// ```dart
  /// "Personalizado"
  /// ```
  String get custom => """Personalizado""";
}

class NotesWallMessagesEs extends NotesWallMessages {
  final MessagesEs _parent;
  const NotesWallMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Aún no hay notas."
  /// ```
  String get noNotes => """Aún no hay notas.""";

  /// ```dart
  /// "No se pudieron cargar las notas."
  /// ```
  String get failedToLoad => """No se pudieron cargar las notas.""";

  /// ```dart
  /// "No se pudo guardar la nota."
  /// ```
  String get saveFailed => """No se pudo guardar la nota.""";

  /// ```dart
  /// "No se pudo eliminar la nota."
  /// ```
  String get deleteFailed => """No se pudo eliminar la nota.""";

  /// ```dart
  /// "¿Eliminar esta nota?"
  /// ```
  String get deleteConfirm => """¿Eliminar esta nota?""";

  /// ```dart
  /// "¿Eliminar ${_plural(count, one: 'esta nota', many: '$count notas')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """¿Eliminar ${_plural(count, one: 'esta nota', many: '$count notas')}?""";

  /// ```dart
  /// "Nueva nota"
  /// ```
  String get newNote => """Nueva nota""";

  /// ```dart
  /// "Editar nota"
  /// ```
  String get editNote => """Editar nota""";

  /// ```dart
  /// "Título"
  /// ```
  String get title => """Título""";

  /// ```dart
  /// "Contenido"
  /// ```
  String get content => """Contenido""";

  /// ```dart
  /// "Color"
  /// ```
  String get color => """Color""";
  SortNotesWallMessagesEs get sort => SortNotesWallMessagesEs(this);
}

class SortNotesWallMessagesEs extends SortNotesWallMessages {
  final NotesWallMessagesEs _parent;
  const SortNotesWallMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Más recientes"
  /// ```
  String get newestFirst => """Más recientes""";

  /// ```dart
  /// "Más antiguos"
  /// ```
  String get oldestFirst => """Más antiguos""";

  /// ```dart
  /// "Título A–Z"
  /// ```
  String get titleAZ => """Título A–Z""";

  /// ```dart
  /// "Título Z–A"
  /// ```
  String get titleZA => """Título Z–A""";

  /// ```dart
  /// "Personalizado"
  /// ```
  String get custom => """Personalizado""";
}

class PhotoBoardMessagesEs extends PhotoBoardMessages {
  final MessagesEs _parent;
  const PhotoBoardMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Aún no hay fotos."
  /// ```
  String get noPhotos => """Aún no hay fotos.""";

  /// ```dart
  /// "No se pudieron cargar las fotos."
  /// ```
  String get failedToLoad => """No se pudieron cargar las fotos.""";

  /// ```dart
  /// "No se pudo subir la foto."
  /// ```
  String get uploadFailed => """No se pudo subir la foto.""";

  /// ```dart
  /// "No se pudo eliminar la foto."
  /// ```
  String get deleteFailed => """No se pudo eliminar la foto.""";

  /// ```dart
  /// "¿Eliminar esta foto?"
  /// ```
  String get deleteConfirm => """¿Eliminar esta foto?""";

  /// ```dart
  /// "¿Eliminar ${_plural(count, one: 'esta foto', many: '$count fotos')}?"
  /// ```
  String deleteSelectedConfirm(int count) =>
      """¿Eliminar ${_plural(count, one: 'esta foto', many: '$count fotos')}?""";

  /// ```dart
  /// "Eliminar carpeta"
  /// ```
  String get deleteFolder => """Eliminar carpeta""";

  /// ```dart
  /// "¿Eliminar esta carpeta?"
  /// ```
  String get deleteFolderConfirm => """¿Eliminar esta carpeta?""";

  /// ```dart
  /// "Mover fotos a la raíz"
  /// ```
  String get deleteFolderKeepPhotos => """Mover fotos a la raíz""";

  /// ```dart
  /// "Eliminar carpeta y fotos"
  /// ```
  String get deleteFolderDeleteAll => """Eliminar carpeta y fotos""";

  /// ```dart
  /// "Nueva carpeta"
  /// ```
  String get newFolder => """Nueva carpeta""";

  /// ```dart
  /// "Nombre de la carpeta"
  /// ```
  String get folderName => """Nombre de la carpeta""";

  /// ```dart
  /// "Renombrar carpeta"
  /// ```
  String get renameFolder => """Renombrar carpeta""";

  /// ```dart
  /// "Descripción"
  /// ```
  String get caption => """Descripción""";

  /// ```dart
  /// "$count"
  /// ```
  String photoCount(int count) => """$count""";
  SortPhotoBoardMessagesEs get sort => SortPhotoBoardMessagesEs(this);
}

class SortPhotoBoardMessagesEs extends SortPhotoBoardMessages {
  final PhotoBoardMessagesEs _parent;
  const SortPhotoBoardMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Carpetas primero"
  /// ```
  String get foldersFirst => """Carpetas primero""";

  /// ```dart
  /// "Más recientes"
  /// ```
  String get newestFirst => """Más recientes""";

  /// ```dart
  /// "Más antiguos"
  /// ```
  String get oldestFirst => """Más antiguos""";

  /// ```dart
  /// "Descripción A–Z"
  /// ```
  String get captionAZ => """Descripción A–Z""";

  /// ```dart
  /// "Descripción Z–A"
  /// ```
  String get captionZA => """Descripción Z–A""";

  /// ```dart
  /// "Personalizado"
  /// ```
  String get custom => """Personalizado""";
}

class RecurrenceMessagesEs extends RecurrenceMessages {
  final MessagesEs _parent;
  const RecurrenceMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Recurrencia"
  /// ```
  String get title => """Recurrencia""";

  /// ```dart
  /// "Preajustes"
  /// ```
  String get presets => """Preajustes""";

  /// ```dart
  /// "Diario"
  /// ```
  String get daily => """Diario""";

  /// ```dart
  /// "Semanal"
  /// ```
  String get weekly => """Semanal""";

  /// ```dart
  /// "Mensual"
  /// ```
  String get monthly => """Mensual""";

  /// ```dart
  /// "Cada"
  /// ```
  String get everyLabel => """Cada""";

  /// ```dart
  /// "Unidad"
  /// ```
  String get unit => """Unidad""";

  /// ```dart
  /// "días"
  /// ```
  String get unitDays => """días""";

  /// ```dart
  /// "semanas"
  /// ```
  String get unitWeeks => """semanas""";

  /// ```dart
  /// "meses"
  /// ```
  String get unitMonths => """meses""";

  /// ```dart
  /// "años"
  /// ```
  String get unitYears => """años""";

  /// ```dart
  /// "Repetir en"
  /// ```
  String get repeatOn => """Repetir en""";

  /// ```dart
  /// "Termina"
  /// ```
  String get ends => """Termina""";

  /// ```dart
  /// "Nunca"
  /// ```
  String get never => """Nunca""";

  /// ```dart
  /// "Después de"
  /// ```
  String get after => """Después de""";

  /// ```dart
  /// "repeticiones"
  /// ```
  String get occurrences => """repeticiones""";

  /// ```dart
  /// "En fecha"
  /// ```
  String get onDate => """En fecha""";

  /// ```dart
  /// "Contar intervalo desde que se marca el artículo"
  /// ```
  String get countFromCompletion =>
      """Contar intervalo desde que se marca el artículo""";

  /// ```dart
  /// "El horario es fijo: el artículo reaparece en su próxima ocurrencia programada, sin importar cuándo lo marques."
  /// ```
  String get countFromCompletionHintOff =>
      """El horario es fijo: el artículo reaparece en su próxima ocurrencia programada, sin importar cuándo lo marques.""";

  /// ```dart
  /// "La próxima ocurrencia se cuenta desde el momento en que marcas el artículo, así que siempre vuelve un intervalo completo después de completarlo."
  /// ```
  String get countFromCompletionHintOn =>
      """La próxima ocurrencia se cuenta desde el momento en que marcas el artículo, así que siempre vuelve un intervalo completo después de completarlo.""";

  /// ```dart
  /// "Resumen"
  /// ```
  String get summary => """Resumen""";

  /// ```dart
  /// "no establecido"
  /// ```
  String get notSet => """no establecido""";

  /// ```dart
  /// "establecido"
  /// ```
  String get set => """establecido""";

  /// ```dart
  /// "cada $unit"
  /// ```
  String every(String unit) => """cada $unit""";

  /// ```dart
  /// "Cada $unit"
  /// ```
  String everyButton(String unit) => """Cada $unit""";

  /// ```dart
  /// "los $days"
  /// ```
  String onDays(String days) => """los $days""";

  /// ```dart
  /// "${_plural(count, one: 'día', many: '$count días')}"
  /// ```
  String day(int count) =>
      """${_plural(count, one: 'día', many: '$count días')}""";

  /// ```dart
  /// "${_plural(count, one: 'semana', many: '$count semanas')}"
  /// ```
  String week(int count) =>
      """${_plural(count, one: 'semana', many: '$count semanas')}""";

  /// ```dart
  /// "${_plural(count, one: 'mes', many: '$count meses')}"
  /// ```
  String month(int count) =>
      """${_plural(count, one: 'mes', many: '$count meses')}""";

  /// ```dart
  /// "${_plural(count, one: 'año', many: '$count años')}"
  /// ```
  String year(int count) =>
      """${_plural(count, one: 'año', many: '$count años')}""";
  DayNamesRecurrenceMessagesEs get dayNames =>
      DayNamesRecurrenceMessagesEs(this);
  DayAbbrRecurrenceMessagesEs get dayAbbr => DayAbbrRecurrenceMessagesEs(this);
}

class DayNamesRecurrenceMessagesEs extends DayNamesRecurrenceMessages {
  final RecurrenceMessagesEs _parent;
  const DayNamesRecurrenceMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Lunes"
  /// ```
  String get monday => """Lunes""";

  /// ```dart
  /// "Martes"
  /// ```
  String get tuesday => """Martes""";

  /// ```dart
  /// "Miércoles"
  /// ```
  String get wednesday => """Miércoles""";

  /// ```dart
  /// "Jueves"
  /// ```
  String get thursday => """Jueves""";

  /// ```dart
  /// "Viernes"
  /// ```
  String get friday => """Viernes""";

  /// ```dart
  /// "Sábado"
  /// ```
  String get saturday => """Sábado""";

  /// ```dart
  /// "Domingo"
  /// ```
  String get sunday => """Domingo""";
}

class DayAbbrRecurrenceMessagesEs extends DayAbbrRecurrenceMessages {
  final RecurrenceMessagesEs _parent;
  const DayAbbrRecurrenceMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Lu"
  /// ```
  String get mo => """Lu""";

  /// ```dart
  /// "Ma"
  /// ```
  String get tu => """Ma""";

  /// ```dart
  /// "Mi"
  /// ```
  String get we => """Mi""";

  /// ```dart
  /// "Ju"
  /// ```
  String get th => """Ju""";

  /// ```dart
  /// "Vi"
  /// ```
  String get fr => """Vi""";

  /// ```dart
  /// "Sá"
  /// ```
  String get sa => """Sá""";

  /// ```dart
  /// "Do"
  /// ```
  String get su => """Do""";
}

Map<String, String> get messagesEsMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Cancelar""",
  """common.delete""": """Eliminar""",
  """common.save""": """Guardar""",
  """common.retry""": """Reintentar""",
  """common.logout""": """Cerrar sesión""",
  """common.loading""": """Cargando...""",
  """common.error""": """Error""",
  """login.connectToNextcloud""": """Conéctate a tu instancia de Nextcloud""",
  """login.serverUrl""": """URL del servidor""",
  """login.serverUrlHint""": """cloud.example.com""",
  """login.connect""": """Conectar""",
  """login.waitingForAuth""": """Esperando autenticación...
Por favor, completa el inicio de sesión en tu navegador.""",
  """login.couldNotConnect""":
      """No se pudo conectar al servidor. Por favor, verifica la URL.""",
  """login.loginFailed""":
      """Inicio de sesión fallido. Por favor, inténtalo de nuevo.""",
  """home.noHouses""": """Aún no hay casas.""",
  """home.noHousesBody""":
      """Las casas son espacios compartidos para tu hogar. Crea tu primera casa para comenzar a agregar listas, fotos y notas.""",
  """home.createHouse""": """Crear casa""",
  """home.houseName""": """Nombre de la casa""",
  """home.houseDescription""": """Descripción (opcional)""",
  """home.createHouseFailed""": """No se pudo crear la casa.""",
  """home.failedToLoadHouses""": """No se pudieron cargar las casas.""",
  """home.serverAppMissingTitle""": """Pantry no está instalado""",
  """home.serverAppMissingBody""":
      """Esta app es un cliente para la app Pantry en Nextcloud. Parece que Pantry aún no está instalado en tu servidor. Pide a tu administrador que lo instale desde la tienda de apps de Nextcloud, o instálalo tú mismo si tienes acceso de administrador.""",
  """home.openAppStore""": """Abrir apps de Nextcloud""",
  """home.learnMore""": """Más información""",
  """nav.checklists""": """Listas""",
  """nav.photoBoard""": """Tablero de fotos""",
  """nav.notesWall""": """Muro de notas""",
  """notificationsIntro.title""": """Mantente al día""",
  """notificationsIntro.body""":
      """Pantry puede notificarte cuando los miembros del hogar agreguen artículos a las listas, suban fotos o dejen notas. Las notificaciones se obtienen de tu propio servidor Nextcloud — nada pasa por Google ni terceros.""",
  """notificationsIntro.bullet1""": """Alertas de actividad del hogar""",
  """notificationsIntro.bullet2""": """Obtenidas directamente de tu servidor""",
  """notificationsIntro.bullet3""": """Funciona incluso con la app cerrada""",
  """notificationsIntro.enableButton""": """Activar notificaciones""",
  """notificationsIntro.skipButton""": """Ahora no""",
  """notificationsIntro.permissionDeniedTitle""": """Permiso denegado""",
  """notificationsIntro.permissionDeniedBody""":
      """Puedes activar las notificaciones más tarde en los ajustes de la app. Si tu dispositivo las bloquea, primero deberás permitirlas en los ajustes del sistema.""",
  """notificationsIntro.ok""": """OK""",
  """settings.title""": """Ajustes de la app""",
  """settings.generalSection""": """General""",
  """settings.language""": """Idioma""",
  """settings.languageNames.system""": """Predeterminado del sistema""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
  """settings.notificationsSection""": """Notificaciones""",
  """settings.enableNotifications""": """Activar notificaciones""",
  """settings.enableNotificationsBody""":
      """Mostrar alertas cuando los miembros del hogar agreguen o actualicen contenido.""",
  """settings.pollInterval""": """Buscar nueva actividad""",
  """settings.pollInterval15m""": """Cada 15 minutos""",
  """settings.pollInterval30m""": """Cada 30 minutos""",
  """settings.pollInterval1h""": """Cada hora""",
  """settings.pollInterval2h""": """Cada 2 horas""",
  """settings.pollInterval6h""": """Cada 6 horas""",
  """settings.permissionDenied""":
      """El permiso de notificaciones fue denegado. Actívalo en los ajustes del sistema.""",
  """notifications.title""": """Notificaciones""",
  """notifications.empty""": """No hay notificaciones nuevas.""",
  """notifications.failedToLoad""":
      """No se pudieron cargar las notificaciones.""",
  """notifications.dismissAll""": """Descartar todas""",
  """notifications.justNow""": """ahora mismo""",
  """categories.manageTitle""": """Gestionar categorías""",
  """categories.noCategories""": """Aún no hay categorías.""",
  """categories.editTitle""": """Editar categoría""",
  """categories.addTitle""": """Nueva categoría""",
  """categories.name""": """Nombre""",
  """categories.icon""": """Icono""",
  """categories.color""": """Color""",
  """categories.saveFailed""": """No se pudo guardar la categoría.""",
  """categories.deleteFailed""": """No se pudo eliminar la categoría.""",
  """categories.deleteConfirm""": """¿Eliminar esta categoría?""",
  """categories.deleteConfirmBody""":
      """Los artículos en esta categoría quedarán sin categoría. Esta acción no se puede deshacer.""",
  """checklists.categories""": """Categorías""",
  """checklists.noChecklists""": """Aún no hay listas.""",
  """checklists.noItems""": """No hay artículos en esta lista.""",
  """checklists.failedToLoad""": """No se pudieron cargar las listas.""",
  """checklists.failedToLoadItems""":
      """No se pudieron cargar los artículos.""",
  """checklists.editItem""": """Editar artículo""",
  """checklists.removeItem""": """Eliminar artículo""",
  """checklists.moveItem""": """Mover a lista""",
  """checklists.moveFailed""": """No se pudo mover el artículo.""",
  """checklists.createList""": """Nueva lista""",
  """checklists.listName""": """Nombre de la lista""",
  """checklists.listDescription""": """Descripción (opcional)""",
  """checklists.listIcon""": """Icono""",
  """checklists.createListFailed""": """No se pudo crear la lista.""",
  """checklists.viewItem.quantity""": """Cantidad:""",
  """checklists.viewItem.category""": """Categoría:""",
  """checklists.viewItem.recurrence""": """Recurrencia:""",
  """checklists.viewItem.nextDue""": """Próximo vencimiento:""",
  """checklists.viewItem.nextDueFromCompletion""":
      """Próximo vencimiento (desde finalización):""",
  """checklists.viewItem.overdue""": """Vencido""",
  """checklists.itemForm.addTitle""": """Agregar artículo""",
  """checklists.itemForm.editTitle""": """Editar artículo""",
  """checklists.itemForm.name""": """Nombre del artículo""",
  """checklists.itemForm.description""": """Descripción""",
  """checklists.itemForm.quantity""": """Cantidad""",
  """checklists.itemForm.category""": """Categoría""",
  """checklists.itemForm.noCategory""": """Ninguna""",
  """checklists.itemForm.noCategories""": """No hay categorías disponibles.""",
  """checklists.itemForm.createCategory""": """Nueva categoría""",
  """checklists.itemForm.categoryName""": """Nombre""",
  """checklists.itemForm.categoryIcon""": """Icono""",
  """checklists.itemForm.categoryColor""": """Color""",
  """checklists.itemForm.categoryCreated""": """Categoría creada.""",
  """checklists.itemForm.categoryCreateFailed""":
      """No se pudo crear la categoría.""",
  """checklists.itemForm.repeat""": """Repetir""",
  """checklists.itemForm.saveFailed""": """No se pudo guardar el artículo.""",
  """checklists.itemForm.deleteFailed""":
      """No se pudo eliminar el artículo.""",
  """checklists.itemForm.deleteConfirm""": """¿Eliminar este artículo?""",
  """checklists.sort.newestFirst""": """Más recientes""",
  """checklists.sort.oldestFirst""": """Más antiguos""",
  """checklists.sort.nameAZ""": """Nombre A–Z""",
  """checklists.sort.nameZA""": """Nombre Z–A""",
  """checklists.sort.category""": """Por categoría""",
  """checklists.sort.custom""": """Personalizado""",
  """notesWall.noNotes""": """Aún no hay notas.""",
  """notesWall.failedToLoad""": """No se pudieron cargar las notas.""",
  """notesWall.saveFailed""": """No se pudo guardar la nota.""",
  """notesWall.deleteFailed""": """No se pudo eliminar la nota.""",
  """notesWall.deleteConfirm""": """¿Eliminar esta nota?""",
  """notesWall.newNote""": """Nueva nota""",
  """notesWall.editNote""": """Editar nota""",
  """notesWall.title""": """Título""",
  """notesWall.content""": """Contenido""",
  """notesWall.color""": """Color""",
  """notesWall.sort.newestFirst""": """Más recientes""",
  """notesWall.sort.oldestFirst""": """Más antiguos""",
  """notesWall.sort.titleAZ""": """Título A–Z""",
  """notesWall.sort.titleZA""": """Título Z–A""",
  """notesWall.sort.custom""": """Personalizado""",
  """photoBoard.noPhotos""": """Aún no hay fotos.""",
  """photoBoard.failedToLoad""": """No se pudieron cargar las fotos.""",
  """photoBoard.uploadFailed""": """No se pudo subir la foto.""",
  """photoBoard.deleteFailed""": """No se pudo eliminar la foto.""",
  """photoBoard.deleteConfirm""": """¿Eliminar esta foto?""",
  """photoBoard.deleteFolder""": """Eliminar carpeta""",
  """photoBoard.deleteFolderConfirm""": """¿Eliminar esta carpeta?""",
  """photoBoard.deleteFolderKeepPhotos""": """Mover fotos a la raíz""",
  """photoBoard.deleteFolderDeleteAll""": """Eliminar carpeta y fotos""",
  """photoBoard.newFolder""": """Nueva carpeta""",
  """photoBoard.folderName""": """Nombre de la carpeta""",
  """photoBoard.renameFolder""": """Renombrar carpeta""",
  """photoBoard.caption""": """Descripción""",
  """photoBoard.sort.foldersFirst""": """Carpetas primero""",
  """photoBoard.sort.newestFirst""": """Más recientes""",
  """photoBoard.sort.oldestFirst""": """Más antiguos""",
  """photoBoard.sort.captionAZ""": """Descripción A–Z""",
  """photoBoard.sort.captionZA""": """Descripción Z–A""",
  """photoBoard.sort.custom""": """Personalizado""",
  """recurrence.title""": """Recurrencia""",
  """recurrence.presets""": """Preajustes""",
  """recurrence.daily""": """Diario""",
  """recurrence.weekly""": """Semanal""",
  """recurrence.monthly""": """Mensual""",
  """recurrence.everyLabel""": """Cada""",
  """recurrence.unit""": """Unidad""",
  """recurrence.unitDays""": """días""",
  """recurrence.unitWeeks""": """semanas""",
  """recurrence.unitMonths""": """meses""",
  """recurrence.unitYears""": """años""",
  """recurrence.repeatOn""": """Repetir en""",
  """recurrence.ends""": """Termina""",
  """recurrence.never""": """Nunca""",
  """recurrence.after""": """Después de""",
  """recurrence.occurrences""": """repeticiones""",
  """recurrence.onDate""": """En fecha""",
  """recurrence.countFromCompletion""":
      """Contar intervalo desde que se marca el artículo""",
  """recurrence.countFromCompletionHintOff""":
      """El horario es fijo: el artículo reaparece en su próxima ocurrencia programada, sin importar cuándo lo marques.""",
  """recurrence.countFromCompletionHintOn""":
      """La próxima ocurrencia se cuenta desde el momento en que marcas el artículo, así que siempre vuelve un intervalo completo después de completarlo.""",
  """recurrence.summary""": """Resumen""",
  """recurrence.notSet""": """no establecido""",
  """recurrence.set""": """establecido""",
  """recurrence.dayNames.monday""": """Lunes""",
  """recurrence.dayNames.tuesday""": """Martes""",
  """recurrence.dayNames.wednesday""": """Miércoles""",
  """recurrence.dayNames.thursday""": """Jueves""",
  """recurrence.dayNames.friday""": """Viernes""",
  """recurrence.dayNames.saturday""": """Sábado""",
  """recurrence.dayNames.sunday""": """Domingo""",
  """recurrence.dayAbbr.mo""": """Lu""",
  """recurrence.dayAbbr.tu""": """Ma""",
  """recurrence.dayAbbr.we""": """Mi""",
  """recurrence.dayAbbr.th""": """Ju""",
  """recurrence.dayAbbr.fr""": """Vi""",
  """recurrence.dayAbbr.sa""": """Sá""",
  """recurrence.dayAbbr.su""": """Do""",
};
