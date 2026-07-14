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
  OnboardingMessagesEs get onboarding => OnboardingMessagesEs(this);
  NotificationsIntroMessagesEs get notificationsIntro =>
      NotificationsIntroMessagesEs(this);
  AboutMessagesEs get about => AboutMessagesEs(this);
  SettingsMessagesEs get settings => SettingsMessagesEs(this);
  NotificationsMessagesEs get notifications => NotificationsMessagesEs(this);
  CategoriesMessagesEs get categories => CategoriesMessagesEs(this);
  ChecklistsMessagesEs get checklists => ChecklistsMessagesEs(this);
  NotesWallMessagesEs get notesWall => NotesWallMessagesEs(this);
  PhotoBoardMessagesEs get photoBoard => PhotoBoardMessagesEs(this);
  ShareMessagesEs get share => ShareMessagesEs(this);
  RecurrenceMessagesEs get recurrence => RecurrenceMessagesEs(this);
  SyncMessagesEs get sync => SyncMessagesEs(this);
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
  /// "Actualizar"
  /// ```
  String get refresh => """Actualizar""";

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

  /// ```dart
  /// "Copiar"
  /// ```
  String get copy => """Copiar""";

  /// ```dart
  /// "Copiado"
  /// ```
  String get copied => """Copiado""";

  /// ```dart
  /// "Listo"
  /// ```
  String get closeDialog => """Listo""";

  /// ```dart
  /// "Quitar"
  /// ```
  String get remove => """Quitar""";

  /// ```dart
  /// "No tienes permiso para hacer eso"
  /// ```
  String get permissionDenied => """No tienes permiso para hacer eso""";

  /// ```dart
  /// "Sin acceso"
  /// ```
  String get noAccessTitle => """Sin acceso""";

  /// ```dart
  /// "Todavía no tienes acceso a nada en este hogar. Un administrador puede concederte permisos en la aplicación web de Pantry."
  /// ```
  String get noAccessBody =>
      """Todavía no tienes acceso a nada en este hogar. Un administrador puede concederte permisos en la aplicación web de Pantry.""";
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

  /// ```dart
  /// "Ver detalles"
  /// ```
  String get seeDetails => """Ver detalles""";

  /// ```dart
  /// "Detalles del error"
  /// ```
  String get errorDetailsTitle => """Detalles del error""";

  /// ```dart
  /// "Certificado no confiable"
  /// ```
  String get untrustedCertTitle => """Certificado no confiable""";

  /// ```dart
  /// "${host} está usando un certificado que tu dispositivo no reconoce — normalmente porque es autofirmado. Comprueba que la huella digital coincida con la que te dio el administrador del servidor antes de confiar en él."
  /// ```
  String untrustedCertBody(String host) =>
      """${host} está usando un certificado que tu dispositivo no reconoce — normalmente porque es autofirmado. Comprueba que la huella digital coincida con la que te dio el administrador del servidor antes de confiar en él.""";

  /// ```dart
  /// "Confía en este certificado solo si reconoces la huella digital. Confiar en un certificado inesperado puede permitir que un atacante lea tu tráfico."
  /// ```
  String get untrustedCertWarning =>
      """Confía en este certificado solo si reconoces la huella digital. Confiar en un certificado inesperado puede permitir que un atacante lea tu tráfico.""";

  /// ```dart
  /// "Confiar en el certificado"
  /// ```
  String get trustCertificate => """Confiar en el certificado""";

  /// ```dart
  /// "Huella SHA-256"
  /// ```
  String get certFingerprint => """Huella SHA-256""";

  /// ```dart
  /// "Sujeto"
  /// ```
  String get certSubject => """Sujeto""";

  /// ```dart
  /// "Emisor"
  /// ```
  String get certIssuer => """Emisor""";

  /// ```dart
  /// "Válido"
  /// ```
  String get certValidity => """Válido""";

  /// ```dart
  /// "Iniciar sesión con una contraseña de aplicación"
  /// ```
  String get useAppPassword =>
      """Iniciar sesión con una contraseña de aplicación""";

  /// ```dart
  /// "Iniciar sesión con el navegador"
  /// ```
  String get useBrowserLogin => """Iniciar sesión con el navegador""";

  /// ```dart
  /// "Nombre de usuario"
  /// ```
  String get username => """Nombre de usuario""";

  /// ```dart
  /// "Contraseña de aplicación"
  /// ```
  String get appPassword => """Contraseña de aplicación""";

  /// ```dart
  /// "Crea una contraseña de aplicación en Nextcloud en Ajustes → Seguridad → Dispositivos y sesiones. Úsala si el inicio de sesión del navegador no se abre o tu servidor usa un certificado autofirmado."
  /// ```
  String get appPasswordHelp =>
      """Crea una contraseña de aplicación en Nextcloud en Ajustes → Seguridad → Dispositivos y sesiones. Úsala si el inicio de sesión del navegador no se abre o tu servidor usa un certificado autofirmado.""";

  /// ```dart
  /// "Introduce tu nombre de usuario y tu contraseña de aplicación."
  /// ```
  String get appPasswordMissing =>
      """Introduce tu nombre de usuario y tu contraseña de aplicación.""";

  /// ```dart
  /// "Iniciar sesión"
  /// ```
  String get signIn => """Iniciar sesión""";

  /// ```dart
  /// "No se pudo conectar con el servidor. Comprueba la dirección y tu conexión de red o VPN."
  /// ```
  String get couldNotReachServer =>
      """No se pudo conectar con el servidor. Comprueba la dirección y tu conexión de red o VPN.""";

  /// ```dart
  /// "El servidor tardó demasiado en responder. Comprueba tu conexión de red o VPN e inténtalo de nuevo."
  /// ```
  String get connectionTimeout =>
      """El servidor tardó demasiado en responder. Comprueba tu conexión de red o VPN e inténtalo de nuevo.""";

  /// ```dart
  /// "No se pudo leer el certificado del servidor para verificarlo. La conexión puede ser inestable o el servidor no estar disponible."
  /// ```
  String get certProbeFailed =>
      """No se pudo leer el certificado del servidor para verificarlo. La conexión puede ser inestable o el servidor no estar disponible.""";
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

class OnboardingMessagesEs extends OnboardingMessages {
  final MessagesEs _parent;
  const OnboardingMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Siguiente"
  /// ```
  String get next => """Siguiente""";

  /// ```dart
  /// "Atrás"
  /// ```
  String get back => """Atrás""";

  /// ```dart
  /// "Omitir"
  /// ```
  String get skip => """Omitir""";

  /// ```dart
  /// "Empezar"
  /// ```
  String get done => """Empezar""";

  /// ```dart
  /// "Paso ${current} de ${total}"
  /// ```
  String stepLabel(int current, int total) => """Paso ${current} de ${total}""";

  /// ```dart
  /// "Bienvenido a Pantry"
  /// ```
  String get welcomeNewTitle => """Bienvenido a Pantry""";

  /// ```dart
  /// "Vamos a hacer un recorrido rápido por cómo funciona Pantry para que le saques el máximo provecho."
  /// ```
  String get welcomeNewBody =>
      """Vamos a hacer un recorrido rápido por cómo funciona Pantry para que le saques el máximo provecho.""";

  /// ```dart
  /// "Novedades"
  /// ```
  String get welcomeUpdateTitle => """Novedades""";

  /// ```dart
  /// "Pantry ha aprendido algunos trucos nuevos desde la última vez que lo abriste. Aquí tienes un repaso rápido."
  /// ```
  String get welcomeUpdateBody =>
      """Pantry ha aprendido algunos trucos nuevos desde la última vez que lo abriste. Aquí tienes un repaso rápido.""";

  /// ```dart
  /// "Las listas tienen un nuevo aspecto"
  /// ```
  String get checklistsRedesignTitle =>
      """Las listas tienen un nuevo aspecto""";

  /// ```dart
  /// "La página de listas se ha rehecho desde cero: un diseño más limpio, una forma más rápida de añadir elementos y acciones rápidas en cada fila. Las próximas páginas te muestran las novedades."
  /// ```
  String get checklistsRedesignBody =>
      """La página de listas se ha rehecho desde cero: un diseño más limpio, una forma más rápida de añadir elementos y acciones rápidas en cada fila. Las próximas páginas te muestran las novedades.""";

  /// ```dart
  /// "Cambia de lista desde arriba"
  /// ```
  String get checklistSelectorTitle => """Cambia de lista desde arriba""";

  /// ```dart
  /// "Toca el nombre de la lista o su icono en la parte superior para cambiar entre listas o crear una nueva."
  /// ```
  String get checklistSelectorBody =>
      """Toca el nombre de la lista o su icono en la parte superior para cambiar entre listas o crear una nueva.""";

  /// ```dart
  /// "Toca para cambiar de lista"
  /// ```
  String get checklistSelectorHint => """Toca para cambiar de lista""";

  /// ```dart
  /// "Compras"
  /// ```
  String get mockListGroceries => """Compras""";

  /// ```dart
  /// "Ferretería"
  /// ```
  String get mockListHardware => """Ferretería""";

  /// ```dart
  /// "Viaje de fin de semana"
  /// ```
  String get mockListWeekend => """Viaje de fin de semana""";

  /// ```dart
  /// "${count} artículos"
  /// ```
  String mockItemCountSummary(int count) => """${count} artículos""";

  /// ```dart
  /// "Nueva lista"
  /// ```
  String get newListLabel => """Nueva lista""";

  /// ```dart
  /// "Desliza los artículos para gestionarlos"
  /// ```
  String get swipeActionsTitle => """Desliza los artículos para gestionarlos""";

  /// ```dart
  /// "Desliza un artículo de derecha a izquierda para ver acciones rápidas: editar, mover o eliminar."
  /// ```
  String get swipeActionsBody =>
      """Desliza un artículo de derecha a izquierda para ver acciones rápidas: editar, mover o eliminar.""";

  /// ```dart
  /// "Desliza a la izquierda"
  /// ```
  String get swipeActionsHint => """Desliza a la izquierda""";

  /// ```dart
  /// "Desliza a la derecha"
  /// ```
  String get swipeActionsHintBack => """Desliza a la derecha""";

  /// ```dart
  /// "Acciones rápidas en cada artículo"
  /// ```
  String get quickActionsTitle => """Acciones rápidas en cada artículo""";

  /// ```dart
  /// "Cada artículo muestra botones de acción al final — pulsa uno para editar, mover o eliminar el artículo sin abrirlo."
  /// ```
  String get quickActionsBody =>
      """Cada artículo muestra botones de acción al final — pulsa uno para editar, mover o eliminar el artículo sin abrirlo.""";

  /// ```dart
  /// "Una forma más rápida de añadir"
  /// ```
  String get addItemsTitle => """Una forma más rápida de añadir""";

  /// ```dart
  /// "Toca el campo de abajo para escribir un nuevo artículo, y luego etiquétalo con una categoría, cantidad, tipo o foto usando los chips de arriba."
  /// ```
  String get addItemsBody =>
      """Toca el campo de abajo para escribir un nuevo artículo, y luego etiquétalo con una categoría, cantidad, tipo o foto usando los chips de arriba.""";

  /// ```dart
  /// "Compras"
  /// ```
  String get mockComposeListName => """Compras""";

  /// ```dart
  /// "Oculta la tarjeta de progreso"
  /// ```
  String get progressHeroTitle => """Oculta la tarjeta de progreso""";

  /// ```dart
  /// "¿No necesitas el anillo de progreso arriba? Deslízalo para descartarlo."
  /// ```
  String get progressHeroBody =>
      """¿No necesitas el anillo de progreso arriba? Deslízalo para descartarlo.""";

  /// ```dart
  /// "Puedes volver a mostrarla en cualquier momento desde el menú de la lista → ${toggle}."
  /// ```
  String progressHeroBringBack(String toggle) =>
      """Puedes volver a mostrarla en cualquier momento desde el menú de la lista → ${toggle}.""";

  /// ```dart
  /// "Desliza para descartar"
  /// ```
  String get progressHeroHint => """Desliza para descartar""";

  /// ```dart
  /// "Oculta la tarjeta de progreso"
  /// ```
  String get progressHeroDismissTitle => """Oculta la tarjeta de progreso""";

  /// ```dart
  /// "¿No necesitas el anillo de progreso arriba? Pulsa la X en la tarjeta para ocultarla."
  /// ```
  String get progressHeroDismissBody =>
      """¿No necesitas el anillo de progreso arriba? Pulsa la X en la tarjeta para ocultarla.""";

  /// ```dart
  /// "Fija listas en tu pantalla de inicio"
  /// ```
  String get pinnedListsTitle => """Fija listas en tu pantalla de inicio""";

  /// ```dart
  /// "Añade el widget de Pantry a tu pantalla de inicio para ver de un vistazo cuántos artículos quedan en tus listas favoritas, sin abrir la app."
  /// ```
  String get pinnedListsBody =>
      """Añade el widget de Pantry a tu pantalla de inicio para ver de un vistazo cuántos artículos quedan en tus listas favoritas, sin abrir la app.""";

  /// ```dart
  /// "Abre una lista, toca ${menu} en la esquina superior y elige ${action}. Las listas fijadas aparecen en el widget; quita la fijación para ocultarlas."
  /// ```
  String pinnedListsHow(String menu, String action) =>
      """Abre una lista, toca ${menu} en la esquina superior y elige ${action}. Las listas fijadas aparecen en el widget; quita la fijación para ocultarlas.""";

  /// ```dart
  /// "el menú"
  /// ```
  String get pinnedListsMenuLabel => """el menú""";

  /// ```dart
  /// "Fijar lista"
  /// ```
  String get pinnedListsActionLabel => """Fijar lista""";

  /// ```dart
  /// "Pantry"
  /// ```
  String get pinnedListsWidgetTitle => """Pantry""";

  /// ```dart
  /// "${_plural(count, one: '1 pendiente', many: '${count} pendientes')}"
  /// ```
  String pinnedListsWidgetItemsLeft(int count) =>
      """${_plural(count, one: '1 pendiente', many: '${count} pendientes')}""";

  /// ```dart
  /// "Todo hecho"
  /// ```
  String get pinnedListsWidgetEmpty => """Todo hecho""";

  /// ```dart
  /// "Mantén tus notas importantes arriba"
  /// ```
  String get pinnedNotesTitle => """Mantén tus notas importantes arriba""";

  /// ```dart
  /// "Fija una nota desde su menú de opciones para que se mantenga en lo alto del muro de notas, por encima de las notas más recientes."
  /// ```
  String get pinnedNotesBody =>
      """Fija una nota desde su menú de opciones para que se mantenga en lo alto del muro de notas, por encima de las notas más recientes.""";

  /// ```dart
  /// "Contraseña Wi-Fi"
  /// ```
  String get mockPinnedNoteTitle => """Contraseña Wi-Fi""";

  /// ```dart
  /// """
  /// Red: Casa
  /// Contraseña: pantry-rocks
  /// """
  /// ```
  String get mockPinnedNoteContent => """Red: Casa
Contraseña: pantry-rocks""";

  /// ```dart
  /// "Tomates"
  /// ```
  String get mockItemName => """Tomates""";

  /// ```dart
  /// "x2"
  /// ```
  String get mockItemQuantity => """x2""";

  /// ```dart
  /// "Verduras"
  /// ```
  String get mockItemCategory => """Verduras""";

  /// ```dart
  /// "Bombillas"
  /// ```
  String get mockHardwareItemName => """Bombillas""";

  /// ```dart
  /// "Leche"
  /// ```
  String get mockBulkItemThird => """Leche""";

  /// ```dart
  /// "Pan"
  /// ```
  String get mockBulkItemFourth => """Pan""";

  /// ```dart
  /// "Todo en una sola vista"
  /// ```
  String get allListsTitle => """Todo en una sola vista""";

  /// ```dart
  /// "Abre la vista Todas las listas desde el selector para ver los elementos de todas tus listas juntos. Cuando añades un elemento desde aquí, el formulario te pide a qué lista enviarlo — elígela en el chip de lista."
  /// ```
  String get allListsBody =>
      """Abre la vista Todas las listas desde el selector para ver los elementos de todas tus listas juntos. Cuando añades un elemento desde aquí, el formulario te pide a qué lista enviarlo — elígela en el chip de lista.""";

  /// ```dart
  /// "Añade varios artículos a la vez"
  /// ```
  String get bulkAddTitle => """Añade varios artículos a la vez""";

  /// ```dart
  /// "Activa el interruptor Múltiple y el campo se convierte en un cuadro de varias líneas — cada línea se convierte en un artículo. Práctico cuando pegas una lista o anotas toda la compra de golpe."
  /// ```
  String get bulkAddBody =>
      """Activa el interruptor Múltiple y el campo se convierte en un cuadro de varias líneas — cada línea se convierte en un artículo. Práctico cuando pegas una lista o anotas toda la compra de golpe.""";

  /// ```dart
  /// "Actúa sobre varios artículos a la vez"
  /// ```
  String get bulkSelectTitle => """Actúa sobre varios artículos a la vez""";

  /// ```dart
  /// "Mantén pulsado un artículo —o toca Seleccionar en el menú— para empezar a seleccionar y luego mover, copiar, asignar una categoría o eliminar todo lo elegido de una vez."
  /// ```
  String get bulkSelectBody =>
      """Mantén pulsado un artículo —o toca Seleccionar en el menú— para empezar a seleccionar y luego mover, copiar, asignar una categoría o eliminar todo lo elegido de una vez.""";
  DevOnboardingMessagesEs get dev => DevOnboardingMessagesEs(this);
}

class DevOnboardingMessagesEs extends DevOnboardingMessages {
  final OnboardingMessagesEs _parent;
  const DevOnboardingMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Mostrar introducción"
  /// ```
  String get showOnboarding => """Mostrar introducción""";

  /// ```dart
  /// "Ver novedades"
  /// ```
  String get pickLastSeenTitle => """Ver novedades""";

  /// ```dart
  /// "Elige la versión cuyas novedades quieres ver, tal como las vería quien actualiza a esa versión."
  /// ```
  String get pickLastSeenBody =>
      """Elige la versión cuyas novedades quieres ver, tal como las vería quien actualiza a esa versión.""";

  /// ```dart
  /// "Nunca vista (usuario nuevo)"
  /// ```
  String get neverSeen => """Nunca vista (usuario nuevo)""";

  /// ```dart
  /// "Forzar todas las funciones"
  /// ```
  String get forceAllFeatures => """Forzar todas las funciones""";

  /// ```dart
  /// "Enviar notificación de prueba"
  /// ```
  String get sendTestNotification => """Enviar notificación de prueba""";
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

class AboutMessagesEs extends AboutMessages {
  final MessagesEs _parent;
  const AboutMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Acerca de"
  /// ```
  String get title => """Acerca de""";

  /// ```dart
  /// "Desarrollador"
  /// ```
  String get developer => """Desarrollador""";

  /// ```dart
  /// "Correo"
  /// ```
  String get email => """Correo""";

  /// ```dart
  /// "Código fuente"
  /// ```
  String get repository => """Código fuente""";

  /// ```dart
  /// "App de Nextcloud"
  /// ```
  String get nextcloudApp => """App de Nextcloud""";

  /// ```dart
  /// "Política de privacidad"
  /// ```
  String get privacyPolicy => """Política de privacidad""";

  /// ```dart
  /// "Comentarios y problemas"
  /// ```
  String get feedback => """Comentarios y problemas""";

  /// ```dart
  /// "Servidor Nextcloud"
  /// ```
  String get serverVersion => """Servidor Nextcloud""";

  /// ```dart
  /// "Pantry en el servidor"
  /// ```
  String get pantryServerVersion => """Pantry en el servidor""";

  /// ```dart
  /// "Desconocido"
  /// ```
  String get versionUnknown => """Desconocido""";

  /// ```dart
  /// "Invítame a un café"
  /// ```
  String get buyMeACoffee => """Invítame a un café""";
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
  /// "Interfaz"
  /// ```
  String get interfaceSection => """Interfaz""";

  /// ```dart
  /// "Acción al tocar un elemento"
  /// ```
  String get defaultItemTapAction => """Acción al tocar un elemento""";

  /// ```dart
  /// "Qué ocurre al tocar la fila de un elemento."
  /// ```
  String get defaultItemTapActionBody =>
      """Qué ocurre al tocar la fila de un elemento.""";
  ItemTapActionNamesSettingsMessagesEs get itemTapActionNames =>
      ItemTapActionNamesSettingsMessagesEs(this);

  /// ```dart
  /// "Posición de la casilla"
  /// ```
  String get checkboxPosition => """Posición de la casilla""";

  /// ```dart
  /// "En qué lado de la fila aparece la casilla."
  /// ```
  String get checkboxPositionBody =>
      """En qué lado de la fila aparece la casilla.""";
  CheckboxPositionNamesSettingsMessagesEs get checkboxPositionNames =>
      CheckboxPositionNamesSettingsMessagesEs(this);

  /// ```dart
  /// "Densidad de la lista"
  /// ```
  String get density => """Densidad de la lista""";

  /// ```dart
  /// "Cuánto espacio ocupa cada artículo en tus listas."
  /// ```
  String get densityBody =>
      """Cuánto espacio ocupa cada artículo en tus listas.""";
  DensityNamesSettingsMessagesEs get densityNames =>
      DensityNamesSettingsMessagesEs(this);

  /// ```dart
  /// "Reutilizar artículos existentes al añadir"
  /// ```
  String get reuseExistingItems =>
      """Reutilizar artículos existentes al añadir""";

  /// ```dart
  /// "Cuando intentes añadir un artículo que ya existe en la lista, reutiliza ese artículo."
  /// ```
  String get reuseExistingItemsBody =>
      """Cuando intentes añadir un artículo que ya existe en la lista, reutiliza ese artículo.""";
  ReuseExistingItemsNamesSettingsMessagesEs get reuseExistingItemsNames =>
      ReuseExistingItemsNamesSettingsMessagesEs(this);

  /// ```dart
  /// "Orden de navegación"
  /// ```
  String get navOrderTitle => """Orden de navegación""";

  /// ```dart
  /// "Reordena las pestañas de navegación. El primer elemento se abre al iniciar la app."
  /// ```
  String get navOrderSubtitle =>
      """Reordena las pestañas de navegación. El primer elemento se abre al iniciar la app.""";

  /// ```dart
  /// "Arrastra para reordenar. El primer elemento es la sección que se abre al iniciar la app."
  /// ```
  String get navOrderBody =>
      """Arrastra para reordenar. El primer elemento es la sección que se abre al iniciar la app.""";

  /// ```dart
  /// "Se abre al iniciar"
  /// ```
  String get navOrderDefaultHint => """Se abre al iniciar""";

  /// ```dart
  /// "Restablecer"
  /// ```
  String get navOrderReset => """Restablecer""";

  /// ```dart
  /// "Idioma"
  /// ```
  String get language => """Idioma""";
  LanguageNamesSettingsMessagesEs get languageNames =>
      LanguageNamesSettingsMessagesEs(this);

  /// ```dart
  /// "Tema"
  /// ```
  String get theme => """Tema""";
  ThemeNamesSettingsMessagesEs get themeNames =>
      ThemeNamesSettingsMessagesEs(this);

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

class ItemTapActionNamesSettingsMessagesEs
    extends ItemTapActionNamesSettingsMessages {
  final SettingsMessagesEs _parent;
  const ItemTapActionNamesSettingsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Marcar como completado"
  /// ```
  String get done => """Marcar como completado""";

  /// ```dart
  /// "Ver"
  /// ```
  String get view => """Ver""";

  /// ```dart
  /// "Editar"
  /// ```
  String get edit => """Editar""";

  /// ```dart
  /// "Ninguna"
  /// ```
  String get none => """Ninguna""";
}

class CheckboxPositionNamesSettingsMessagesEs
    extends CheckboxPositionNamesSettingsMessages {
  final SettingsMessagesEs _parent;
  const CheckboxPositionNamesSettingsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Inicio"
  /// ```
  String get start => """Inicio""";

  /// ```dart
  /// "Fin"
  /// ```
  String get end => """Fin""";
}

class DensityNamesSettingsMessagesEs extends DensityNamesSettingsMessages {
  final SettingsMessagesEs _parent;
  const DensityNamesSettingsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Normal"
  /// ```
  String get normal => """Normal""";

  /// ```dart
  /// "Compacta"
  /// ```
  String get dense => """Compacta""";
}

class ReuseExistingItemsNamesSettingsMessagesEs
    extends ReuseExistingItemsNamesSettingsMessages {
  final SettingsMessagesEs _parent;
  const ReuseExistingItemsNamesSettingsMessagesEs(this._parent)
    : super(_parent);

  /// ```dart
  /// "Preguntar siempre"
  /// ```
  String get ask => """Preguntar siempre""";

  /// ```dart
  /// "Reutilizar siempre"
  /// ```
  String get reuse => """Reutilizar siempre""";

  /// ```dart
  /// "Nunca reutilizar"
  /// ```
  String get never => """Nunca reutilizar""";
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

class ThemeNamesSettingsMessagesEs extends ThemeNamesSettingsMessages {
  final SettingsMessagesEs _parent;
  const ThemeNamesSettingsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Predeterminado del sistema"
  /// ```
  String get system => """Predeterminado del sistema""";

  /// ```dart
  /// "Claro"
  /// ```
  String get light => """Claro""";

  /// ```dart
  /// "Oscuro"
  /// ```
  String get dark => """Oscuro""";
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
  SortCategoriesMessagesEs get sort => SortCategoriesMessagesEs(this);
}

class SortCategoriesMessagesEs extends SortCategoriesMessages {
  final CategoriesMessagesEs _parent;
  const SortCategoriesMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Nombre A–Z"
  /// ```
  String get nameAZ => """Nombre A–Z""";

  /// ```dart
  /// "Nombre Z–A"
  /// ```
  String get nameZA => """Nombre Z–A""";

  /// ```dart
  /// "Personalizado"
  /// ```
  String get custom => """Personalizado""";
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
  /// "Ningún artículo coincide con tu búsqueda."
  /// ```
  String get noSearchResults => """Ningún artículo coincide con tu búsqueda.""";

  /// ```dart
  /// "Escribe para filtrar..."
  /// ```
  String get searchHint => """Escribe para filtrar...""";

  /// ```dart
  /// "Todos"
  /// ```
  String get allCategories => """Todos""";

  /// ```dart
  /// "Todos"
  /// ```
  String get allListsChip => """Todos""";

  /// ```dart
  /// "Filtrar por lista"
  /// ```
  String get filterByList => """Filtrar por lista""";

  /// ```dart
  /// "Filtrar por categoría"
  /// ```
  String get filterByCategory => """Filtrar por categoría""";

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
  /// "Copiar a lista"
  /// ```
  String get copyItem => """Copiar a lista""";

  /// ```dart
  /// "No se pudo copiar el artículo."
  /// ```
  String get copyFailed => """No se pudo copiar el artículo.""";

  /// ```dart
  /// "Artículo copiado"
  /// ```
  String get itemCopied => """Artículo copiado""";

  /// ```dart
  /// "Artículo marcado como hecho"
  /// ```
  String get itemMarkedDone => """Artículo marcado como hecho""";

  /// ```dart
  /// "Artículo eliminado"
  /// ```
  String get itemRemoved => """Artículo eliminado""";

  /// ```dart
  /// "Deshacer"
  /// ```
  String get undo => """Deshacer""";

  /// ```dart
  /// "Seleccionar"
  /// ```
  String get selectItems => """Seleccionar""";
  BatchChecklistsMessagesEs get batch => BatchChecklistsMessagesEs(this);

  /// ```dart
  /// "Ver papelera"
  /// ```
  String get viewTrash => """Ver papelera""";

  /// ```dart
  /// "Salir de la papelera"
  /// ```
  String get exitTrash => """Salir de la papelera""";

  /// ```dart
  /// "Mostrar quién añadió cada artículo"
  /// ```
  String get showAddedBy => """Mostrar quién añadió cada artículo""";

  /// ```dart
  /// "Mostrar tarjeta de progreso en esta lista"
  /// ```
  String get showProgressHero =>
      """Mostrar tarjeta de progreso en esta lista""";

  /// ```dart
  /// "Añadido por $name"
  /// ```
  String addedBy(String name) => """Añadido por $name""";

  /// ```dart
  /// "Papelera"
  /// ```
  String get trashTitle => """Papelera""";

  /// ```dart
  /// "La papelera está vacía."
  /// ```
  String get noTrashedItems => """La papelera está vacía.""";

  /// ```dart
  /// "Vaciar papelera"
  /// ```
  String get emptyTrash => """Vaciar papelera""";

  /// ```dart
  /// "¿Vaciar la papelera?"
  /// ```
  String get emptyTrashConfirm => """¿Vaciar la papelera?""";

  /// ```dart
  /// "Todos los artículos de la papelera se eliminarán permanentemente. Esta acción no se puede deshacer."
  /// ```
  String get emptyTrashConfirmBody =>
      """Todos los artículos de la papelera se eliminarán permanentemente. Esta acción no se puede deshacer.""";

  /// ```dart
  /// "No se pudo vaciar la papelera."
  /// ```
  String get emptyTrashFailed => """No se pudo vaciar la papelera.""";

  /// ```dart
  /// "Restaurar"
  /// ```
  String get restoreItem => """Restaurar""";

  /// ```dart
  /// "Eliminar"
  /// ```
  String get permanentlyDeleteItem => """Eliminar""";

  /// ```dart
  /// "¿Eliminar este artículo permanentemente?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """¿Eliminar este artículo permanentemente?""";

  /// ```dart
  /// "Esta acción no se puede deshacer."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Esta acción no se puede deshacer.""";

  /// ```dart
  /// "No se pudo restaurar el artículo."
  /// ```
  String get restoreFailed => """No se pudo restaurar el artículo.""";

  /// ```dart
  /// "No se pudo eliminar el artículo."
  /// ```
  String get permanentlyDeleteFailed => """No se pudo eliminar el artículo.""";

  /// ```dart
  /// "Artículo restaurado"
  /// ```
  String get itemRestored => """Artículo restaurado""";

  /// ```dart
  /// "Ver archivo"
  /// ```
  String get viewArchive => """Ver archivo""";

  /// ```dart
  /// "Salir del archivo"
  /// ```
  String get exitArchive => """Salir del archivo""";

  /// ```dart
  /// "Archivo"
  /// ```
  String get archiveTitle => """Archivo""";

  /// ```dart
  /// "Sin categoría"
  /// ```
  String get noCategory => """Sin categoría""";

  /// ```dart
  /// "El archivo está vacío."
  /// ```
  String get noArchivedItems => """El archivo está vacío.""";

  /// ```dart
  /// "Archivar"
  /// ```
  String get archiveItem => """Archivar""";

  /// ```dart
  /// "Desarchivar"
  /// ```
  String get unarchiveItem => """Desarchivar""";

  /// ```dart
  /// "No se pudo archivar el artículo."
  /// ```
  String get archiveFailed => """No se pudo archivar el artículo.""";

  /// ```dart
  /// "No se pudo desarchivar el artículo."
  /// ```
  String get unarchiveFailed => """No se pudo desarchivar el artículo.""";

  /// ```dart
  /// "Artículo archivado"
  /// ```
  String get itemArchived => """Artículo archivado""";

  /// ```dart
  /// "Artículo desarchivado"
  /// ```
  String get itemUnarchived => """Artículo desarchivado""";

  /// ```dart
  /// "No se pudo cargar el archivo."
  /// ```
  String get failedToLoadArchive => """No se pudo cargar el archivo.""";

  /// ```dart
  /// "Listas eliminadas"
  /// ```
  String get viewListsTrash => """Listas eliminadas""";

  /// ```dart
  /// "Listas eliminadas"
  /// ```
  String get listsTrashTitle => """Listas eliminadas""";

  /// ```dart
  /// "No se pudo cargar la papelera."
  /// ```
  String get failedToLoadTrash => """No se pudo cargar la papelera.""";

  /// ```dart
  /// "No hay listas eliminadas."
  /// ```
  String get listTrashEmpty => """No hay listas eliminadas.""";

  /// ```dart
  /// "Fijar lista"
  /// ```
  String get pinList => """Fijar lista""";

  /// ```dart
  /// "Desfijar lista"
  /// ```
  String get unpinList => """Desfijar lista""";

  /// ```dart
  /// "Quitar lista"
  /// ```
  String get removeList => """Quitar lista""";

  /// ```dart
  /// "Editar lista"
  /// ```
  String get editList => """Editar lista""";

  /// ```dart
  /// "Editar lista"
  /// ```
  String get editListTitle => """Editar lista""";

  /// ```dart
  /// "Guardar cambios"
  /// ```
  String get saveListButton => """Guardar cambios""";

  /// ```dart
  /// "No se pudo actualizar la lista."
  /// ```
  String get updateListFailed => """No se pudo actualizar la lista.""";

  /// ```dart
  /// "¿Quitar la lista?"
  /// ```
  String get removeListConfirm => """¿Quitar la lista?""";

  /// ```dart
  /// "¿Quitar la lista "$name"? Puedes restaurarla desde la papelera."
  /// ```
  String removeListConfirmBody(String name) =>
      """¿Quitar la lista "$name"? Puedes restaurarla desde la papelera.""";

  /// ```dart
  /// "No se pudo quitar la lista."
  /// ```
  String get removeListFailed => """No se pudo quitar la lista.""";

  /// ```dart
  /// "Restaurar lista"
  /// ```
  String get restoreList => """Restaurar lista""";

  /// ```dart
  /// "Eliminar para siempre"
  /// ```
  String get permanentlyDeleteList => """Eliminar para siempre""";

  /// ```dart
  /// "Lista eliminada"
  /// ```
  String get listRemoved => """Lista eliminada""";

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

  /// ```dart
  /// "${_plural(count, one: '1 artículo restante', many: '$count artículos restantes')}"
  /// ```
  String itemsLeft(int count) =>
      """${_plural(count, one: '1 artículo restante', many: '$count artículos restantes')}""";

  /// ```dart
  /// "Todo listo 🎉"
  /// ```
  String get allDone => """Todo listo 🎉""";

  /// ```dart
  /// "$done de $total hechos"
  /// ```
  String listProgress(int done, int total) => """$done de $total hechos""";

  /// ```dart
  /// "Ocultar tarjeta de progreso"
  /// ```
  String get hideProgressHero => """Ocultar tarjeta de progreso""";

  /// ```dart
  /// "Ordenar"
  /// ```
  String get sortTooltip => """Ordenar""";

  /// ```dart
  /// "Hechos · $count"
  /// ```
  String doneCount(int count) => """Hechos · $count""";

  /// ```dart
  /// "Agregar a $name…"
  /// ```
  String addToList(String name) => """Agregar a $name…""";

  /// ```dart
  /// "Agrega tu primer artículo…"
  /// ```
  String get addFirstItem => """Agrega tu primer artículo…""";

  /// ```dart
  /// "Nada en esta lista todavía"
  /// ```
  String get noItemsTitle => """Nada en esta lista todavía""";

  /// ```dart
  /// "Agrega tu primer artículo con la barra de abajo — configura una categoría, cantidad o programación con los chips."
  /// ```
  String get noItemsBody =>
      """Agrega tu primer artículo con la barra de abajo — configura una categoría, cantidad o programación con los chips.""";

  /// ```dart
  /// "Aún no hay listas"
  /// ```
  String get noListsTitle => """Aún no hay listas""";

  /// ```dart
  /// "Crea tu primera lista para empezar a rastrear compras, recados, tareas o cualquier cosa que tu hogar necesite tener al día."
  /// ```
  String get noListsBody =>
      """Crea tu primera lista para empezar a rastrear compras, recados, tareas o cualquier cosa que tu hogar necesite tener al día.""";

  /// ```dart
  /// "Crear tu primera lista"
  /// ```
  String get createFirstList => """Crear tu primera lista""";

  /// ```dart
  /// "Tus listas"
  /// ```
  String get yourChecklists => """Tus listas""";

  /// ```dart
  /// "${_plural(count, one: '1 lista', many: '$count listas')}"
  /// ```
  String listsCount(int count) =>
      """${_plural(count, one: '1 lista', many: '$count listas')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo', many: '$count artículos')}"
  /// ```
  String itemsSummary(int count) =>
      """${_plural(count, one: '1 artículo', many: '$count artículos')}""";

  /// ```dart
  /// "Todo listo · 0 restantes"
  /// ```
  String get allDoneSummary => """Todo listo · 0 restantes""";

  /// ```dart
  /// "Nueva lista"
  /// ```
  String get newChecklist => """Nueva lista""";

  /// ```dart
  /// "Crear lista"
  /// ```
  String get createListButton => """Crear lista""";

  /// ```dart
  /// "Ver"
  /// ```
  String get view => """Ver""";

  /// ```dart
  /// "Ver"
  /// ```
  String get swipeView => """Ver""";

  /// ```dart
  /// "Editar"
  /// ```
  String get swipeEdit => """Editar""";

  /// ```dart
  /// "Mover"
  /// ```
  String get swipeMove => """Mover""";

  /// ```dart
  /// "Copiar"
  /// ```
  String get swipeCopy => """Copiar""";

  /// ```dart
  /// "Quitar"
  /// ```
  String get swipeDelete => """Quitar""";

  /// ```dart
  /// "Archivar"
  /// ```
  String get swipeArchive => """Archivar""";

  /// ```dart
  /// "Vista de lista"
  /// ```
  String get viewList => """Vista de lista""";

  /// ```dart
  /// "Vista de tarjetas"
  /// ```
  String get viewCards => """Vista de tarjetas""";

  /// ```dart
  /// "Color"
  /// ```
  String get listColor => """Color""";
  ItemTypesChecklistsMessagesEs get itemTypes =>
      ItemTypesChecklistsMessagesEs(this);
  ComposeChecklistsMessagesEs get compose => ComposeChecklistsMessagesEs(this);
  ReuseChecklistsMessagesEs get reuse => ReuseChecklistsMessagesEs(this);

  /// ```dart
  /// "Todas las listas"
  /// ```
  String get allLists => """Todas las listas""";

  /// ```dart
  /// "Elementos de todas las listas"
  /// ```
  String get allListsSubtitle => """Elementos de todas las listas""";

  /// ```dart
  /// "Añadir un elemento…"
  /// ```
  String get addToAnyList => """Añadir un elemento…""";

  /// ```dart
  /// "¿A qué lista añadir?"
  /// ```
  String get pickListTitle => """¿A qué lista añadir?""";
  MarkdownChecklistsMessagesEs get markdown =>
      MarkdownChecklistsMessagesEs(this);
}

class BatchChecklistsMessagesEs extends BatchChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const BatchChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "${_plural(count, one: '1 seleccionado', many: '$count seleccionados')}"
  /// ```
  String selected(int count) =>
      """${_plural(count, one: '1 seleccionado', many: '$count seleccionados')}""";

  /// ```dart
  /// "Mover artículos a"
  /// ```
  String get moveTitle => """Mover artículos a""";

  /// ```dart
  /// "Copiar artículos a"
  /// ```
  String get copyTitle => """Copiar artículos a""";

  /// ```dart
  /// "Establecer categoría"
  /// ```
  String get categoryTitle => """Establecer categoría""";

  /// ```dart
  /// "Sin categoría"
  /// ```
  String get clearCategory => """Sin categoría""";

  /// ```dart
  /// "Mover"
  /// ```
  String get move => """Mover""";

  /// ```dart
  /// "Copiar"
  /// ```
  String get copy => """Copiar""";

  /// ```dart
  /// "Categoría"
  /// ```
  String get category => """Categoría""";

  /// ```dart
  /// "Eliminar"
  /// ```
  String get delete => """Eliminar""";

  /// ```dart
  /// "Archivar"
  /// ```
  String get archive => """Archivar""";

  /// ```dart
  /// "Desarchivar"
  /// ```
  String get unarchive => """Desarchivar""";

  /// ```dart
  /// "¿Eliminar artículos?"
  /// ```
  String get deleteConfirmTitle => """¿Eliminar artículos?""";

  /// ```dart
  /// "${_plural(count, one: '¿Eliminar 1 artículo seleccionado? Puedes restaurarlo desde la papelera.', many: '¿Eliminar $count artículos seleccionados? Puedes restaurarlos desde la papelera.')}"
  /// ```
  String deleteConfirmBody(int count) =>
      """${_plural(count, one: '¿Eliminar 1 artículo seleccionado? Puedes restaurarlo desde la papelera.', many: '¿Eliminar $count artículos seleccionados? Puedes restaurarlos desde la papelera.')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo movido', many: '$count artículos movidos')}"
  /// ```
  String moved(int count) =>
      """${_plural(count, one: '1 artículo movido', many: '$count artículos movidos')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo copiado', many: '$count artículos copiados')}"
  /// ```
  String copied(int count) =>
      """${_plural(count, one: '1 artículo copiado', many: '$count artículos copiados')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo eliminado', many: '$count artículos eliminados')}"
  /// ```
  String deleted(int count) =>
      """${_plural(count, one: '1 artículo eliminado', many: '$count artículos eliminados')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo restaurado', many: '$count artículos restaurados')}"
  /// ```
  String restored(int count) =>
      """${_plural(count, one: '1 artículo restaurado', many: '$count artículos restaurados')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo archivado', many: '$count artículos archivados')}"
  /// ```
  String archived(int count) =>
      """${_plural(count, one: '1 artículo archivado', many: '$count artículos archivados')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo desarchivado', many: '$count artículos desarchivados')}"
  /// ```
  String unarchived(int count) =>
      """${_plural(count, one: '1 artículo desarchivado', many: '$count artículos desarchivados')}""";

  /// ```dart
  /// "${_plural(count, one: '1 artículo actualizado', many: '$count artículos actualizados')}"
  /// ```
  String categorySet(int count) =>
      """${_plural(count, one: '1 artículo actualizado', many: '$count artículos actualizados')}""";

  /// ```dart
  /// "${_plural(count, one: '1 omitido', many: '$count omitidos')}"
  /// ```
  String skipped(int count) =>
      """${_plural(count, one: '1 omitido', many: '$count omitidos')}""";

  /// ```dart
  /// "Algo salió mal. Inténtalo de nuevo."
  /// ```
  String get failed => """Algo salió mal. Inténtalo de nuevo.""";
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

  /// ```dart
  /// "Cantidad"
  /// ```
  String get quantityLabel => """Cantidad""";

  /// ```dart
  /// "Tipo"
  /// ```
  String get typeLabel => """Tipo""";

  /// ```dart
  /// "Descripción"
  /// ```
  String get descriptionLabel => """Descripción""";

  /// ```dart
  /// "Sin descripción."
  /// ```
  String get noDescription => """Sin descripción.""";

  /// ```dart
  /// "Añadido por $name · $time"
  /// ```
  String addedByMeta(String name, String time) =>
      """Añadido por $name · $time""";

  /// ```dart
  /// "Añadido por ti · $time"
  /// ```
  String addedByYouMeta(String time) => """Añadido por ti · $time""";

  /// ```dart
  /// "Añadido $time"
  /// ```
  String addedMeta(String time) => """Añadido $time""";

  /// ```dart
  /// "ahora mismo"
  /// ```
  String get relJustNow => """ahora mismo""";

  /// ```dart
  /// "hoy"
  /// ```
  String get relToday => """hoy""";

  /// ```dart
  /// "ayer"
  /// ```
  String get relYesterday => """ayer""";

  /// ```dart
  /// "hace $n días"
  /// ```
  String relDaysAgo(int n) => """hace $n días""";

  /// ```dart
  /// "${_plural(n, one: 'hace 1 semana', many: 'hace $n semanas')}"
  /// ```
  String relWeeksAgo(int n) =>
      """${_plural(n, one: 'hace 1 semana', many: 'hace $n semanas')}""";

  /// ```dart
  /// "${_plural(n, one: 'hace 1 mes', many: 'hace $n meses')}"
  /// ```
  String relMonthsAgo(int n) =>
      """${_plural(n, one: 'hace 1 mes', many: 'hace $n meses')}""";

  /// ```dart
  /// "${_plural(n, one: 'hace 1 año', many: 'hace $n años')}"
  /// ```
  String relYearsAgo(int n) =>
      """${_plural(n, one: 'hace 1 año', many: 'hace $n años')}""";
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
  /// "Una vez"
  /// ```
  String get once => """Una vez""";

  /// ```dart
  /// "Eliminar este artículo cuando se marque como hecho."
  /// ```
  String get onceDescription =>
      """Eliminar este artículo cuando se marque como hecho.""";

  /// ```dart
  /// "Imagen"
  /// ```
  String get image => """Imagen""";

  /// ```dart
  /// "Agregar imagen"
  /// ```
  String get addImage => """Agregar imagen""";

  /// ```dart
  /// "Tomar foto"
  /// ```
  String get takePhoto => """Tomar foto""";

  /// ```dart
  /// "Elegir imagen"
  /// ```
  String get chooseImage => """Elegir imagen""";

  /// ```dart
  /// "Reemplazar"
  /// ```
  String get replaceImage => """Reemplazar""";

  /// ```dart
  /// "Eliminar"
  /// ```
  String get removeImage => """Eliminar""";

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

  /// ```dart
  /// "Guardar cambios"
  /// ```
  String get save => """Guardar cambios""";

  /// ```dart
  /// "Añadir una descripción (opcional)"
  /// ```
  String get descHint => """Añadir una descripción (opcional)""";

  /// ```dart
  /// "Cambiar"
  /// ```
  String get categoryChange => """Cambiar""";

  /// ```dart
  /// "Elige una"
  /// ```
  String get categoryPick => """Elige una""";

  /// ```dart
  /// "Artículo sin título"
  /// ```
  String get untitledItem => """Artículo sin título""";

  /// ```dart
  /// "Artículo recurrente"
  /// ```
  String get typeStaple => """Artículo recurrente""";

  /// ```dart
  /// "Artículo único"
  /// ```
  String get typeOnce => """Artículo único""";

  /// ```dart
  /// "Recurrente"
  /// ```
  String get typeRecurring => """Recurrente""";
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

class ItemTypesChecklistsMessagesEs extends ItemTypesChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const ItemTypesChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Tipo de artículo"
  /// ```
  String get label => """Tipo de artículo""";

  /// ```dart
  /// "Habitual"
  /// ```
  String get staple => """Habitual""";

  /// ```dart
  /// "Permanece en la lista después de completarlo"
  /// ```
  String get stapleBody => """Permanece en la lista después de completarlo""";

  /// ```dart
  /// "Una vez"
  /// ```
  String get onceTime => """Una vez""";

  /// ```dart
  /// "Se elimina al completarlo"
  /// ```
  String get onceTimeBody => """Se elimina al completarlo""";

  /// ```dart
  /// "Recurrente"
  /// ```
  String get recurring => """Recurrente""";

  /// ```dart
  /// "Vuelve según un horario"
  /// ```
  String get recurringBody => """Vuelve según un horario""";

  /// ```dart
  /// "Semanal"
  /// ```
  String get weekly => """Semanal""";

  /// ```dart
  /// "Cada $n sem"
  /// ```
  String everyNWeeks(int n) => """Cada $n sem""";
}

class ComposeChecklistsMessagesEs extends ComposeChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const ComposeChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Categoría"
  /// ```
  String get chipCategory => """Categoría""";

  /// ```dart
  /// "Cantidad"
  /// ```
  String get chipQuantity => """Cantidad""";

  /// ```dart
  /// "Tipo"
  /// ```
  String get chipType => """Tipo""";

  /// ```dart
  /// "Imagen"
  /// ```
  String get chipImage => """Imagen""";

  /// ```dart
  /// "Descripción"
  /// ```
  String get chipDescription => """Descripción""";

  /// ```dart
  /// "Notas, instrucciones, enlaces…"
  /// ```
  String get descHint => """Notas, instrucciones, enlaces…""";

  /// ```dart
  /// "p. ej. 2 L, 500 g"
  /// ```
  String get qtyHint => """p. ej. 2 L, 500 g""";

  /// ```dart
  /// "＋ / − cambian el número y mantienen la unidad."
  /// ```
  String get qtyStepperHelp =>
      """＋ / − cambian el número y mantienen la unidad.""";

  /// ```dart
  /// "Ninguna"
  /// ```
  String get none => """Ninguna""";

  /// ```dart
  /// "Cada"
  /// ```
  String get every => """Cada""";

  /// ```dart
  /// "semana"
  /// ```
  String get week => """semana""";

  /// ```dart
  /// "semanas"
  /// ```
  String get weeks => """semanas""";

  /// ```dart
  /// "Lista"
  /// ```
  String get chipTargetList => """Lista""";

  /// ```dart
  /// "Elige una lista"
  /// ```
  String get pickTargetList => """Elige una lista""";

  /// ```dart
  /// "Varios"
  /// ```
  String get multiple => """Varios""";

  /// ```dart
  /// "Separa los elementos con saltos de línea"
  /// ```
  String get multipleHint => """Separa los elementos con saltos de línea""";
}

class ReuseChecklistsMessagesEs extends ReuseChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const ReuseChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "El artículo ya existe"
  /// ```
  String get dialogTitle => """El artículo ya existe""";

  /// ```dart
  /// "Ya existe un artículo llamado "$name" en esta lista. ¿Reutilizarlo en lugar de añadir uno nuevo?"
  /// ```
  String dialogBody(String name) =>
      """Ya existe un artículo llamado "$name" en esta lista. ¿Reutilizarlo en lugar de añadir uno nuevo?""";

  /// ```dart
  /// "Reutilizar existente"
  /// ```
  String get reuseExisting => """Reutilizar existente""";

  /// ```dart
  /// "Añadir de todos modos"
  /// ```
  String get addAnyway => """Añadir de todos modos""";

  /// ```dart
  /// "Se reutilizó el artículo existente “$name”"
  /// ```
  String reusedSnack(String name) =>
      """Se reutilizó el artículo existente “$name”""";
}

class MarkdownChecklistsMessagesEs extends MarkdownChecklistsMessages {
  final ChecklistsMessagesEs _parent;
  const MarkdownChecklistsMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Exportado el $date"
  /// ```
  String exported(String date) => """Exportado el $date""";

  /// ```dart
  /// "Sin categoría"
  /// ```
  String get uncategorized => """Sin categoría""";

  /// ```dart
  /// "Exportar a Markdown"
  /// ```
  String get exportTitle => """Exportar a Markdown""";

  /// ```dart
  /// "Importar desde Markdown"
  /// ```
  String get importTitle => """Importar desde Markdown""";

  /// ```dart
  /// "Incluir elementos completados"
  /// ```
  String get includeCompleted => """Incluir elementos completados""";

  /// ```dart
  /// "Edita el texto de abajo para modificar la lista exportada"
  /// ```
  String get editHint =>
      """Edita el texto de abajo para modificar la lista exportada""";

  /// ```dart
  /// "Copiar"
  /// ```
  String get copy => """Copiar""";

  /// ```dart
  /// "Descargar .md"
  /// ```
  String get download => """Descargar .md""";

  /// ```dart
  /// "Copiado al portapapeles"
  /// ```
  String get copied => """Copiado al portapapeles""";

  /// ```dart
  /// "No se pudo copiar al portapapeles"
  /// ```
  String get copyFailed => """No se pudo copiar al portapapeles""";

  /// ```dart
  /// "Cerrar"
  /// ```
  String get close => """Cerrar""";

  /// ```dart
  /// "No se pudo exportar el archivo"
  /// ```
  String get shareFailed => """No se pudo exportar el archivo""";

  /// ```dart
  /// "Subir archivo .md"
  /// ```
  String get uploadFile => """Subir archivo .md""";

  /// ```dart
  /// "Pegar Markdown"
  /// ```
  String get pasteLabel => """Pegar Markdown""";

  /// ```dart
  /// "Pega aquí una lista en Markdown…"
  /// ```
  String get pastePlaceholder => """Pega aquí una lista en Markdown…""";

  /// ```dart
  /// "No se encontraron elementos de lista en el texto."
  /// ```
  String get noneFound =>
      """No se encontraron elementos de lista en el texto.""";

  /// ```dart
  /// "Seleccionar todo"
  /// ```
  String get selectAll => """Seleccionar todo""";

  /// ```dart
  /// "Deseleccionar todo"
  /// ```
  String get deselectAll => """Deseleccionar todo""";

  /// ```dart
  /// "Reutilizar elementos existentes en lugar de añadir duplicados"
  /// ```
  String get reuseExisting =>
      """Reutilizar elementos existentes en lugar de añadir duplicados""";

  /// ```dart
  /// "Valores aplicados a cada elemento importado"
  /// ```
  String get defaultFields => """Valores aplicados a cada elemento importado""";

  /// ```dart
  /// "${_plural(count, one: '1 elemento encontrado', many: '$count elementos encontrados')}"
  /// ```
  String itemsFound(int count) =>
      """${_plural(count, one: '1 elemento encontrado', many: '$count elementos encontrados')}""";

  /// ```dart
  /// "${_plural(count, one: 'Añadir 1 elemento', many: 'Añadir $count elementos')}"
  /// ```
  String addItems(int count) =>
      """${_plural(count, one: 'Añadir 1 elemento', many: 'Añadir $count elementos')}""";

  /// ```dart
  /// "${_plural(count, one: '1 elemento importado', many: '$count elementos importados')}"
  /// ```
  String imported(int count) =>
      """${_plural(count, one: '1 elemento importado', many: '$count elementos importados')}""";
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
  /// "${_plural(count, one: 'Nota eliminada', many: '$count notas eliminadas')}"
  /// ```
  String noteRemoved(int count) =>
      """${_plural(count, one: 'Nota eliminada', many: '$count notas eliminadas')}""";

  /// ```dart
  /// "Ver papelera"
  /// ```
  String get viewTrash => """Ver papelera""";

  /// ```dart
  /// "Salir de la papelera"
  /// ```
  String get exitTrash => """Salir de la papelera""";

  /// ```dart
  /// "Papelera"
  /// ```
  String get trashTitle => """Papelera""";

  /// ```dart
  /// "La papelera está vacía."
  /// ```
  String get trashEmpty => """La papelera está vacía.""";

  /// ```dart
  /// "Vaciar papelera"
  /// ```
  String get emptyTrash => """Vaciar papelera""";

  /// ```dart
  /// "¿Vaciar la papelera?"
  /// ```
  String get emptyTrashConfirm => """¿Vaciar la papelera?""";

  /// ```dart
  /// "Todas las notas en la papelera se eliminarán permanentemente. Esta acción no se puede deshacer."
  /// ```
  String get emptyTrashConfirmBody =>
      """Todas las notas en la papelera se eliminarán permanentemente. Esta acción no se puede deshacer.""";

  /// ```dart
  /// "No se pudo vaciar la papelera."
  /// ```
  String get emptyTrashFailed => """No se pudo vaciar la papelera.""";

  /// ```dart
  /// "No se pudo cargar la papelera."
  /// ```
  String get failedToLoadTrash => """No se pudo cargar la papelera.""";

  /// ```dart
  /// "Restaurar"
  /// ```
  String get restore => """Restaurar""";

  /// ```dart
  /// "No se pudo restaurar la nota."
  /// ```
  String get restoreFailed => """No se pudo restaurar la nota.""";

  /// ```dart
  /// "Eliminar para siempre"
  /// ```
  String get permanentlyDelete => """Eliminar para siempre""";

  /// ```dart
  /// "¿Eliminar esta nota permanentemente?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """¿Eliminar esta nota permanentemente?""";

  /// ```dart
  /// "Esta acción no se puede deshacer."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Esta acción no se puede deshacer.""";

  /// ```dart
  /// "Nueva nota"
  /// ```
  String get newNote => """Nueva nota""";

  /// ```dart
  /// "Editar nota"
  /// ```
  String get editNote => """Editar nota""";

  /// ```dart
  /// "Fijar nota"
  /// ```
  String get pinNote => """Fijar nota""";

  /// ```dart
  /// "Quitar fijación"
  /// ```
  String get unpinNote => """Quitar fijación""";

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
  /// "${_plural(count, one: 'Foto eliminada', many: '$count fotos eliminadas')}"
  /// ```
  String photoRemoved(int count) =>
      """${_plural(count, one: 'Foto eliminada', many: '$count fotos eliminadas')}""";

  /// ```dart
  /// "Ver papelera"
  /// ```
  String get viewTrash => """Ver papelera""";

  /// ```dart
  /// "Salir de la papelera"
  /// ```
  String get exitTrash => """Salir de la papelera""";

  /// ```dart
  /// "Papelera"
  /// ```
  String get trashTitle => """Papelera""";

  /// ```dart
  /// "La papelera está vacía."
  /// ```
  String get trashEmpty => """La papelera está vacía.""";

  /// ```dart
  /// "Vaciar papelera"
  /// ```
  String get emptyTrash => """Vaciar papelera""";

  /// ```dart
  /// "¿Vaciar la papelera?"
  /// ```
  String get emptyTrashConfirm => """¿Vaciar la papelera?""";

  /// ```dart
  /// "Todas las fotos en la papelera se eliminarán permanentemente. Esta acción no se puede deshacer."
  /// ```
  String get emptyTrashConfirmBody =>
      """Todas las fotos en la papelera se eliminarán permanentemente. Esta acción no se puede deshacer.""";

  /// ```dart
  /// "No se pudo vaciar la papelera."
  /// ```
  String get emptyTrashFailed => """No se pudo vaciar la papelera.""";

  /// ```dart
  /// "No se pudo cargar la papelera."
  /// ```
  String get failedToLoadTrash => """No se pudo cargar la papelera.""";

  /// ```dart
  /// "Restaurar"
  /// ```
  String get restore => """Restaurar""";

  /// ```dart
  /// "No se pudo restaurar la foto."
  /// ```
  String get restoreFailed => """No se pudo restaurar la foto.""";

  /// ```dart
  /// "Eliminar para siempre"
  /// ```
  String get permanentlyDelete => """Eliminar para siempre""";

  /// ```dart
  /// "¿Eliminar esta foto permanentemente?"
  /// ```
  String get permanentlyDeleteConfirm =>
      """¿Eliminar esta foto permanentemente?""";

  /// ```dart
  /// "Esta acción no se puede deshacer."
  /// ```
  String get permanentlyDeleteConfirmBody =>
      """Esta acción no se puede deshacer.""";

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
  AddMenuPhotoBoardMessagesEs get addMenu => AddMenuPhotoBoardMessagesEs(this);
  SortPhotoBoardMessagesEs get sort => SortPhotoBoardMessagesEs(this);
}

class AddMenuPhotoBoardMessagesEs extends AddMenuPhotoBoardMessages {
  final PhotoBoardMessagesEs _parent;
  const AddMenuPhotoBoardMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Subir fotos"
  /// ```
  String get upload => """Subir fotos""";

  /// ```dart
  /// "Tomar foto"
  /// ```
  String get camera => """Tomar foto""";

  /// ```dart
  /// "Nueva carpeta"
  /// ```
  String get newFolder => """Nueva carpeta""";
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

class ShareMessagesEs extends ShareMessages {
  final MessagesEs _parent;
  const ShareMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Compartir con Pantry"
  /// ```
  String get title => """Compartir con Pantry""";

  /// ```dart
  /// "Elegir casa"
  /// ```
  String get chooseHouse => """Elegir casa""";

  /// ```dart
  /// "Subir a"
  /// ```
  String get choosePhotoDestination => """Subir a""";

  /// ```dart
  /// "Tablón de fotos"
  /// ```
  String get photoBoardRoot => """Tablón de fotos""";

  /// ```dart
  /// "Nueva carpeta"
  /// ```
  String get newFolder => """Nueva carpeta""";

  /// ```dart
  /// "Nombre de la carpeta"
  /// ```
  String get newFolderName => """Nombre de la carpeta""";

  /// ```dart
  /// "No se pudo crear la carpeta."
  /// ```
  String get failedToCreateFolder => """No se pudo crear la carpeta.""";

  /// ```dart
  /// "No se pudo abrir el contenido compartido."
  /// ```
  String get failedToOpenShare =>
      """No se pudo abrir el contenido compartido.""";

  /// ```dart
  /// "No hay casas disponibles. Crea una casa primero."
  /// ```
  String get noHouses => """No hay casas disponibles. Crea una casa primero.""";
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

class SyncMessagesEs extends SyncMessages {
  final MessagesEs _parent;
  const SyncMessagesEs(this._parent) : super(_parent);

  /// ```dart
  /// "Sin conexión"
  /// ```
  String get offline => """Sin conexión""";

  /// ```dart
  /// "Sincronizando cambios…"
  /// ```
  String get syncing => """Sincronizando cambios…""";

  /// ```dart
  /// "${_plural(count, one: '1 cambio esperando a sincronizar', many: '${count} cambios esperando a sincronizar')}"
  /// ```
  String pendingChanges(int count) =>
      """${_plural(count, one: '1 cambio esperando a sincronizar', many: '${count} cambios esperando a sincronizar')}""";

  /// ```dart
  /// "No se pudieron sincronizar los cambios"
  /// ```
  String get syncError => """No se pudieron sincronizar los cambios""";

  /// ```dart
  /// "Reintentar"
  /// ```
  String get retry => """Reintentar""";
}

Map<String, String> get messagesEsMap => {
  """common.appTitle""": """Pantry""",
  """common.cancel""": """Cancelar""",
  """common.delete""": """Eliminar""",
  """common.save""": """Guardar""",
  """common.retry""": """Reintentar""",
  """common.refresh""": """Actualizar""",
  """common.logout""": """Cerrar sesión""",
  """common.loading""": """Cargando...""",
  """common.error""": """Error""",
  """common.copy""": """Copiar""",
  """common.copied""": """Copiado""",
  """common.closeDialog""": """Listo""",
  """common.remove""": """Quitar""",
  """common.permissionDenied""": """No tienes permiso para hacer eso""",
  """common.noAccessTitle""": """Sin acceso""",
  """common.noAccessBody""":
      """Todavía no tienes acceso a nada en este hogar. Un administrador puede concederte permisos en la aplicación web de Pantry.""",
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
  """login.seeDetails""": """Ver detalles""",
  """login.errorDetailsTitle""": """Detalles del error""",
  """login.untrustedCertTitle""": """Certificado no confiable""",
  """login.untrustedCertWarning""":
      """Confía en este certificado solo si reconoces la huella digital. Confiar en un certificado inesperado puede permitir que un atacante lea tu tráfico.""",
  """login.trustCertificate""": """Confiar en el certificado""",
  """login.certFingerprint""": """Huella SHA-256""",
  """login.certSubject""": """Sujeto""",
  """login.certIssuer""": """Emisor""",
  """login.certValidity""": """Válido""",
  """login.useAppPassword""":
      """Iniciar sesión con una contraseña de aplicación""",
  """login.useBrowserLogin""": """Iniciar sesión con el navegador""",
  """login.username""": """Nombre de usuario""",
  """login.appPassword""": """Contraseña de aplicación""",
  """login.appPasswordHelp""":
      """Crea una contraseña de aplicación en Nextcloud en Ajustes → Seguridad → Dispositivos y sesiones. Úsala si el inicio de sesión del navegador no se abre o tu servidor usa un certificado autofirmado.""",
  """login.appPasswordMissing""":
      """Introduce tu nombre de usuario y tu contraseña de aplicación.""",
  """login.signIn""": """Iniciar sesión""",
  """login.couldNotReachServer""":
      """No se pudo conectar con el servidor. Comprueba la dirección y tu conexión de red o VPN.""",
  """login.connectionTimeout""":
      """El servidor tardó demasiado en responder. Comprueba tu conexión de red o VPN e inténtalo de nuevo.""",
  """login.certProbeFailed""":
      """No se pudo leer el certificado del servidor para verificarlo. La conexión puede ser inestable o el servidor no estar disponible.""",
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
  """onboarding.next""": """Siguiente""",
  """onboarding.back""": """Atrás""",
  """onboarding.skip""": """Omitir""",
  """onboarding.done""": """Empezar""",
  """onboarding.welcomeNewTitle""": """Bienvenido a Pantry""",
  """onboarding.welcomeNewBody""":
      """Vamos a hacer un recorrido rápido por cómo funciona Pantry para que le saques el máximo provecho.""",
  """onboarding.welcomeUpdateTitle""": """Novedades""",
  """onboarding.welcomeUpdateBody""":
      """Pantry ha aprendido algunos trucos nuevos desde la última vez que lo abriste. Aquí tienes un repaso rápido.""",
  """onboarding.checklistsRedesignTitle""":
      """Las listas tienen un nuevo aspecto""",
  """onboarding.checklistsRedesignBody""":
      """La página de listas se ha rehecho desde cero: un diseño más limpio, una forma más rápida de añadir elementos y acciones rápidas en cada fila. Las próximas páginas te muestran las novedades.""",
  """onboarding.checklistSelectorTitle""": """Cambia de lista desde arriba""",
  """onboarding.checklistSelectorBody""":
      """Toca el nombre de la lista o su icono en la parte superior para cambiar entre listas o crear una nueva.""",
  """onboarding.checklistSelectorHint""": """Toca para cambiar de lista""",
  """onboarding.mockListGroceries""": """Compras""",
  """onboarding.mockListHardware""": """Ferretería""",
  """onboarding.mockListWeekend""": """Viaje de fin de semana""",
  """onboarding.newListLabel""": """Nueva lista""",
  """onboarding.swipeActionsTitle""":
      """Desliza los artículos para gestionarlos""",
  """onboarding.swipeActionsBody""":
      """Desliza un artículo de derecha a izquierda para ver acciones rápidas: editar, mover o eliminar.""",
  """onboarding.swipeActionsHint""": """Desliza a la izquierda""",
  """onboarding.swipeActionsHintBack""": """Desliza a la derecha""",
  """onboarding.quickActionsTitle""": """Acciones rápidas en cada artículo""",
  """onboarding.quickActionsBody""":
      """Cada artículo muestra botones de acción al final — pulsa uno para editar, mover o eliminar el artículo sin abrirlo.""",
  """onboarding.addItemsTitle""": """Una forma más rápida de añadir""",
  """onboarding.addItemsBody""":
      """Toca el campo de abajo para escribir un nuevo artículo, y luego etiquétalo con una categoría, cantidad, tipo o foto usando los chips de arriba.""",
  """onboarding.mockComposeListName""": """Compras""",
  """onboarding.progressHeroTitle""": """Oculta la tarjeta de progreso""",
  """onboarding.progressHeroBody""":
      """¿No necesitas el anillo de progreso arriba? Deslízalo para descartarlo.""",
  """onboarding.progressHeroHint""": """Desliza para descartar""",
  """onboarding.progressHeroDismissTitle""":
      """Oculta la tarjeta de progreso""",
  """onboarding.progressHeroDismissBody""":
      """¿No necesitas el anillo de progreso arriba? Pulsa la X en la tarjeta para ocultarla.""",
  """onboarding.pinnedListsTitle""": """Fija listas en tu pantalla de inicio""",
  """onboarding.pinnedListsBody""":
      """Añade el widget de Pantry a tu pantalla de inicio para ver de un vistazo cuántos artículos quedan en tus listas favoritas, sin abrir la app.""",
  """onboarding.pinnedListsMenuLabel""": """el menú""",
  """onboarding.pinnedListsActionLabel""": """Fijar lista""",
  """onboarding.pinnedListsWidgetTitle""": """Pantry""",
  """onboarding.pinnedListsWidgetEmpty""": """Todo hecho""",
  """onboarding.pinnedNotesTitle""": """Mantén tus notas importantes arriba""",
  """onboarding.pinnedNotesBody""":
      """Fija una nota desde su menú de opciones para que se mantenga en lo alto del muro de notas, por encima de las notas más recientes.""",
  """onboarding.mockPinnedNoteTitle""": """Contraseña Wi-Fi""",
  """onboarding.mockPinnedNoteContent""": """Red: Casa
Contraseña: pantry-rocks""",
  """onboarding.mockItemName""": """Tomates""",
  """onboarding.mockItemQuantity""": """x2""",
  """onboarding.mockItemCategory""": """Verduras""",
  """onboarding.mockHardwareItemName""": """Bombillas""",
  """onboarding.mockBulkItemThird""": """Leche""",
  """onboarding.mockBulkItemFourth""": """Pan""",
  """onboarding.allListsTitle""": """Todo en una sola vista""",
  """onboarding.allListsBody""":
      """Abre la vista Todas las listas desde el selector para ver los elementos de todas tus listas juntos. Cuando añades un elemento desde aquí, el formulario te pide a qué lista enviarlo — elígela en el chip de lista.""",
  """onboarding.bulkAddTitle""": """Añade varios artículos a la vez""",
  """onboarding.bulkAddBody""":
      """Activa el interruptor Múltiple y el campo se convierte en un cuadro de varias líneas — cada línea se convierte en un artículo. Práctico cuando pegas una lista o anotas toda la compra de golpe.""",
  """onboarding.bulkSelectTitle""": """Actúa sobre varios artículos a la vez""",
  """onboarding.bulkSelectBody""":
      """Mantén pulsado un artículo —o toca Seleccionar en el menú— para empezar a seleccionar y luego mover, copiar, asignar una categoría o eliminar todo lo elegido de una vez.""",
  """onboarding.dev.showOnboarding""": """Mostrar introducción""",
  """onboarding.dev.pickLastSeenTitle""": """Ver novedades""",
  """onboarding.dev.pickLastSeenBody""":
      """Elige la versión cuyas novedades quieres ver, tal como las vería quien actualiza a esa versión.""",
  """onboarding.dev.neverSeen""": """Nunca vista (usuario nuevo)""",
  """onboarding.dev.forceAllFeatures""": """Forzar todas las funciones""",
  """onboarding.dev.sendTestNotification""":
      """Enviar notificación de prueba""",
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
  """about.title""": """Acerca de""",
  """about.developer""": """Desarrollador""",
  """about.email""": """Correo""",
  """about.repository""": """Código fuente""",
  """about.nextcloudApp""": """App de Nextcloud""",
  """about.privacyPolicy""": """Política de privacidad""",
  """about.feedback""": """Comentarios y problemas""",
  """about.serverVersion""": """Servidor Nextcloud""",
  """about.pantryServerVersion""": """Pantry en el servidor""",
  """about.versionUnknown""": """Desconocido""",
  """about.buyMeACoffee""": """Invítame a un café""",
  """settings.title""": """Ajustes de la app""",
  """settings.generalSection""": """General""",
  """settings.interfaceSection""": """Interfaz""",
  """settings.defaultItemTapAction""": """Acción al tocar un elemento""",
  """settings.defaultItemTapActionBody""":
      """Qué ocurre al tocar la fila de un elemento.""",
  """settings.itemTapActionNames.done""": """Marcar como completado""",
  """settings.itemTapActionNames.view""": """Ver""",
  """settings.itemTapActionNames.edit""": """Editar""",
  """settings.itemTapActionNames.none""": """Ninguna""",
  """settings.checkboxPosition""": """Posición de la casilla""",
  """settings.checkboxPositionBody""":
      """En qué lado de la fila aparece la casilla.""",
  """settings.checkboxPositionNames.start""": """Inicio""",
  """settings.checkboxPositionNames.end""": """Fin""",
  """settings.density""": """Densidad de la lista""",
  """settings.densityBody""":
      """Cuánto espacio ocupa cada artículo en tus listas.""",
  """settings.densityNames.normal""": """Normal""",
  """settings.densityNames.dense""": """Compacta""",
  """settings.reuseExistingItems""":
      """Reutilizar artículos existentes al añadir""",
  """settings.reuseExistingItemsBody""":
      """Cuando intentes añadir un artículo que ya existe en la lista, reutiliza ese artículo.""",
  """settings.reuseExistingItemsNames.ask""": """Preguntar siempre""",
  """settings.reuseExistingItemsNames.reuse""": """Reutilizar siempre""",
  """settings.reuseExistingItemsNames.never""": """Nunca reutilizar""",
  """settings.navOrderTitle""": """Orden de navegación""",
  """settings.navOrderSubtitle""":
      """Reordena las pestañas de navegación. El primer elemento se abre al iniciar la app.""",
  """settings.navOrderBody""":
      """Arrastra para reordenar. El primer elemento es la sección que se abre al iniciar la app.""",
  """settings.navOrderDefaultHint""": """Se abre al iniciar""",
  """settings.navOrderReset""": """Restablecer""",
  """settings.language""": """Idioma""",
  """settings.languageNames.system""": """Predeterminado del sistema""",
  """settings.languageNames.english""": """English""",
  """settings.languageNames.hebrew""": """עברית""",
  """settings.languageNames.german""": """Deutsch""",
  """settings.languageNames.spanish""": """Español""",
  """settings.languageNames.french""": """Français""",
  """settings.theme""": """Tema""",
  """settings.themeNames.system""": """Predeterminado del sistema""",
  """settings.themeNames.light""": """Claro""",
  """settings.themeNames.dark""": """Oscuro""",
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
  """categories.sort.nameAZ""": """Nombre A–Z""",
  """categories.sort.nameZA""": """Nombre Z–A""",
  """categories.sort.custom""": """Personalizado""",
  """checklists.categories""": """Categorías""",
  """checklists.noChecklists""": """Aún no hay listas.""",
  """checklists.noItems""": """No hay artículos en esta lista.""",
  """checklists.noSearchResults""":
      """Ningún artículo coincide con tu búsqueda.""",
  """checklists.searchHint""": """Escribe para filtrar...""",
  """checklists.allCategories""": """Todos""",
  """checklists.allListsChip""": """Todos""",
  """checklists.filterByList""": """Filtrar por lista""",
  """checklists.filterByCategory""": """Filtrar por categoría""",
  """checklists.failedToLoad""": """No se pudieron cargar las listas.""",
  """checklists.failedToLoadItems""":
      """No se pudieron cargar los artículos.""",
  """checklists.editItem""": """Editar artículo""",
  """checklists.removeItem""": """Eliminar artículo""",
  """checklists.moveItem""": """Mover a lista""",
  """checklists.moveFailed""": """No se pudo mover el artículo.""",
  """checklists.copyItem""": """Copiar a lista""",
  """checklists.copyFailed""": """No se pudo copiar el artículo.""",
  """checklists.itemCopied""": """Artículo copiado""",
  """checklists.itemMarkedDone""": """Artículo marcado como hecho""",
  """checklists.itemRemoved""": """Artículo eliminado""",
  """checklists.undo""": """Deshacer""",
  """checklists.selectItems""": """Seleccionar""",
  """checklists.batch.moveTitle""": """Mover artículos a""",
  """checklists.batch.copyTitle""": """Copiar artículos a""",
  """checklists.batch.categoryTitle""": """Establecer categoría""",
  """checklists.batch.clearCategory""": """Sin categoría""",
  """checklists.batch.move""": """Mover""",
  """checklists.batch.copy""": """Copiar""",
  """checklists.batch.category""": """Categoría""",
  """checklists.batch.delete""": """Eliminar""",
  """checklists.batch.archive""": """Archivar""",
  """checklists.batch.unarchive""": """Desarchivar""",
  """checklists.batch.deleteConfirmTitle""": """¿Eliminar artículos?""",
  """checklists.batch.failed""": """Algo salió mal. Inténtalo de nuevo.""",
  """checklists.viewTrash""": """Ver papelera""",
  """checklists.exitTrash""": """Salir de la papelera""",
  """checklists.showAddedBy""": """Mostrar quién añadió cada artículo""",
  """checklists.showProgressHero""":
      """Mostrar tarjeta de progreso en esta lista""",
  """checklists.trashTitle""": """Papelera""",
  """checklists.noTrashedItems""": """La papelera está vacía.""",
  """checklists.emptyTrash""": """Vaciar papelera""",
  """checklists.emptyTrashConfirm""": """¿Vaciar la papelera?""",
  """checklists.emptyTrashConfirmBody""":
      """Todos los artículos de la papelera se eliminarán permanentemente. Esta acción no se puede deshacer.""",
  """checklists.emptyTrashFailed""": """No se pudo vaciar la papelera.""",
  """checklists.restoreItem""": """Restaurar""",
  """checklists.permanentlyDeleteItem""": """Eliminar""",
  """checklists.permanentlyDeleteConfirm""":
      """¿Eliminar este artículo permanentemente?""",
  """checklists.permanentlyDeleteConfirmBody""":
      """Esta acción no se puede deshacer.""",
  """checklists.restoreFailed""": """No se pudo restaurar el artículo.""",
  """checklists.permanentlyDeleteFailed""":
      """No se pudo eliminar el artículo.""",
  """checklists.itemRestored""": """Artículo restaurado""",
  """checklists.viewArchive""": """Ver archivo""",
  """checklists.exitArchive""": """Salir del archivo""",
  """checklists.archiveTitle""": """Archivo""",
  """checklists.noCategory""": """Sin categoría""",
  """checklists.noArchivedItems""": """El archivo está vacío.""",
  """checklists.archiveItem""": """Archivar""",
  """checklists.unarchiveItem""": """Desarchivar""",
  """checklists.archiveFailed""": """No se pudo archivar el artículo.""",
  """checklists.unarchiveFailed""": """No se pudo desarchivar el artículo.""",
  """checklists.itemArchived""": """Artículo archivado""",
  """checklists.itemUnarchived""": """Artículo desarchivado""",
  """checklists.failedToLoadArchive""": """No se pudo cargar el archivo.""",
  """checklists.viewListsTrash""": """Listas eliminadas""",
  """checklists.listsTrashTitle""": """Listas eliminadas""",
  """checklists.failedToLoadTrash""": """No se pudo cargar la papelera.""",
  """checklists.listTrashEmpty""": """No hay listas eliminadas.""",
  """checklists.pinList""": """Fijar lista""",
  """checklists.unpinList""": """Desfijar lista""",
  """checklists.removeList""": """Quitar lista""",
  """checklists.editList""": """Editar lista""",
  """checklists.editListTitle""": """Editar lista""",
  """checklists.saveListButton""": """Guardar cambios""",
  """checklists.updateListFailed""": """No se pudo actualizar la lista.""",
  """checklists.removeListConfirm""": """¿Quitar la lista?""",
  """checklists.removeListFailed""": """No se pudo quitar la lista.""",
  """checklists.restoreList""": """Restaurar lista""",
  """checklists.permanentlyDeleteList""": """Eliminar para siempre""",
  """checklists.listRemoved""": """Lista eliminada""",
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
  """checklists.viewItem.quantityLabel""": """Cantidad""",
  """checklists.viewItem.typeLabel""": """Tipo""",
  """checklists.viewItem.descriptionLabel""": """Descripción""",
  """checklists.viewItem.noDescription""": """Sin descripción.""",
  """checklists.viewItem.relJustNow""": """ahora mismo""",
  """checklists.viewItem.relToday""": """hoy""",
  """checklists.viewItem.relYesterday""": """ayer""",
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
  """checklists.itemForm.once""": """Una vez""",
  """checklists.itemForm.onceDescription""":
      """Eliminar este artículo cuando se marque como hecho.""",
  """checklists.itemForm.image""": """Imagen""",
  """checklists.itemForm.addImage""": """Agregar imagen""",
  """checklists.itemForm.takePhoto""": """Tomar foto""",
  """checklists.itemForm.chooseImage""": """Elegir imagen""",
  """checklists.itemForm.replaceImage""": """Reemplazar""",
  """checklists.itemForm.removeImage""": """Eliminar""",
  """checklists.itemForm.saveFailed""": """No se pudo guardar el artículo.""",
  """checklists.itemForm.deleteFailed""":
      """No se pudo eliminar el artículo.""",
  """checklists.itemForm.deleteConfirm""": """¿Eliminar este artículo?""",
  """checklists.itemForm.save""": """Guardar cambios""",
  """checklists.itemForm.descHint""": """Añadir una descripción (opcional)""",
  """checklists.itemForm.categoryChange""": """Cambiar""",
  """checklists.itemForm.categoryPick""": """Elige una""",
  """checklists.itemForm.untitledItem""": """Artículo sin título""",
  """checklists.itemForm.typeStaple""": """Artículo recurrente""",
  """checklists.itemForm.typeOnce""": """Artículo único""",
  """checklists.itemForm.typeRecurring""": """Recurrente""",
  """checklists.sort.newestFirst""": """Más recientes""",
  """checklists.sort.oldestFirst""": """Más antiguos""",
  """checklists.sort.nameAZ""": """Nombre A–Z""",
  """checklists.sort.nameZA""": """Nombre Z–A""",
  """checklists.sort.category""": """Por categoría""",
  """checklists.sort.custom""": """Personalizado""",
  """checklists.allDone""": """Todo listo 🎉""",
  """checklists.hideProgressHero""": """Ocultar tarjeta de progreso""",
  """checklists.sortTooltip""": """Ordenar""",
  """checklists.addFirstItem""": """Agrega tu primer artículo…""",
  """checklists.noItemsTitle""": """Nada en esta lista todavía""",
  """checklists.noItemsBody""":
      """Agrega tu primer artículo con la barra de abajo — configura una categoría, cantidad o programación con los chips.""",
  """checklists.noListsTitle""": """Aún no hay listas""",
  """checklists.noListsBody""":
      """Crea tu primera lista para empezar a rastrear compras, recados, tareas o cualquier cosa que tu hogar necesite tener al día.""",
  """checklists.createFirstList""": """Crear tu primera lista""",
  """checklists.yourChecklists""": """Tus listas""",
  """checklists.allDoneSummary""": """Todo listo · 0 restantes""",
  """checklists.newChecklist""": """Nueva lista""",
  """checklists.createListButton""": """Crear lista""",
  """checklists.view""": """Ver""",
  """checklists.swipeView""": """Ver""",
  """checklists.swipeEdit""": """Editar""",
  """checklists.swipeMove""": """Mover""",
  """checklists.swipeCopy""": """Copiar""",
  """checklists.swipeDelete""": """Quitar""",
  """checklists.swipeArchive""": """Archivar""",
  """checklists.viewList""": """Vista de lista""",
  """checklists.viewCards""": """Vista de tarjetas""",
  """checklists.listColor""": """Color""",
  """checklists.itemTypes.label""": """Tipo de artículo""",
  """checklists.itemTypes.staple""": """Habitual""",
  """checklists.itemTypes.stapleBody""":
      """Permanece en la lista después de completarlo""",
  """checklists.itemTypes.onceTime""": """Una vez""",
  """checklists.itemTypes.onceTimeBody""": """Se elimina al completarlo""",
  """checklists.itemTypes.recurring""": """Recurrente""",
  """checklists.itemTypes.recurringBody""": """Vuelve según un horario""",
  """checklists.itemTypes.weekly""": """Semanal""",
  """checklists.compose.chipCategory""": """Categoría""",
  """checklists.compose.chipQuantity""": """Cantidad""",
  """checklists.compose.chipType""": """Tipo""",
  """checklists.compose.chipImage""": """Imagen""",
  """checklists.compose.chipDescription""": """Descripción""",
  """checklists.compose.descHint""": """Notas, instrucciones, enlaces…""",
  """checklists.compose.qtyHint""": """p. ej. 2 L, 500 g""",
  """checklists.compose.qtyStepperHelp""":
      """＋ / − cambian el número y mantienen la unidad.""",
  """checklists.compose.none""": """Ninguna""",
  """checklists.compose.every""": """Cada""",
  """checklists.compose.week""": """semana""",
  """checklists.compose.weeks""": """semanas""",
  """checklists.compose.chipTargetList""": """Lista""",
  """checklists.compose.pickTargetList""": """Elige una lista""",
  """checklists.compose.multiple""": """Varios""",
  """checklists.compose.multipleHint""":
      """Separa los elementos con saltos de línea""",
  """checklists.reuse.dialogTitle""": """El artículo ya existe""",
  """checklists.reuse.reuseExisting""": """Reutilizar existente""",
  """checklists.reuse.addAnyway""": """Añadir de todos modos""",
  """checklists.allLists""": """Todas las listas""",
  """checklists.allListsSubtitle""": """Elementos de todas las listas""",
  """checklists.addToAnyList""": """Añadir un elemento…""",
  """checklists.pickListTitle""": """¿A qué lista añadir?""",
  """checklists.markdown.uncategorized""": """Sin categoría""",
  """checklists.markdown.exportTitle""": """Exportar a Markdown""",
  """checklists.markdown.importTitle""": """Importar desde Markdown""",
  """checklists.markdown.includeCompleted""":
      """Incluir elementos completados""",
  """checklists.markdown.editHint""":
      """Edita el texto de abajo para modificar la lista exportada""",
  """checklists.markdown.copy""": """Copiar""",
  """checklists.markdown.download""": """Descargar .md""",
  """checklists.markdown.copied""": """Copiado al portapapeles""",
  """checklists.markdown.copyFailed""": """No se pudo copiar al portapapeles""",
  """checklists.markdown.close""": """Cerrar""",
  """checklists.markdown.shareFailed""": """No se pudo exportar el archivo""",
  """checklists.markdown.uploadFile""": """Subir archivo .md""",
  """checklists.markdown.pasteLabel""": """Pegar Markdown""",
  """checklists.markdown.pastePlaceholder""":
      """Pega aquí una lista en Markdown…""",
  """checklists.markdown.noneFound""":
      """No se encontraron elementos de lista en el texto.""",
  """checklists.markdown.selectAll""": """Seleccionar todo""",
  """checklists.markdown.deselectAll""": """Deseleccionar todo""",
  """checklists.markdown.reuseExisting""":
      """Reutilizar elementos existentes en lugar de añadir duplicados""",
  """checklists.markdown.defaultFields""":
      """Valores aplicados a cada elemento importado""",
  """notesWall.noNotes""": """Aún no hay notas.""",
  """notesWall.failedToLoad""": """No se pudieron cargar las notas.""",
  """notesWall.saveFailed""": """No se pudo guardar la nota.""",
  """notesWall.deleteFailed""": """No se pudo eliminar la nota.""",
  """notesWall.deleteConfirm""": """¿Eliminar esta nota?""",
  """notesWall.viewTrash""": """Ver papelera""",
  """notesWall.exitTrash""": """Salir de la papelera""",
  """notesWall.trashTitle""": """Papelera""",
  """notesWall.trashEmpty""": """La papelera está vacía.""",
  """notesWall.emptyTrash""": """Vaciar papelera""",
  """notesWall.emptyTrashConfirm""": """¿Vaciar la papelera?""",
  """notesWall.emptyTrashConfirmBody""":
      """Todas las notas en la papelera se eliminarán permanentemente. Esta acción no se puede deshacer.""",
  """notesWall.emptyTrashFailed""": """No se pudo vaciar la papelera.""",
  """notesWall.failedToLoadTrash""": """No se pudo cargar la papelera.""",
  """notesWall.restore""": """Restaurar""",
  """notesWall.restoreFailed""": """No se pudo restaurar la nota.""",
  """notesWall.permanentlyDelete""": """Eliminar para siempre""",
  """notesWall.permanentlyDeleteConfirm""":
      """¿Eliminar esta nota permanentemente?""",
  """notesWall.permanentlyDeleteConfirmBody""":
      """Esta acción no se puede deshacer.""",
  """notesWall.newNote""": """Nueva nota""",
  """notesWall.editNote""": """Editar nota""",
  """notesWall.pinNote""": """Fijar nota""",
  """notesWall.unpinNote""": """Quitar fijación""",
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
  """photoBoard.viewTrash""": """Ver papelera""",
  """photoBoard.exitTrash""": """Salir de la papelera""",
  """photoBoard.trashTitle""": """Papelera""",
  """photoBoard.trashEmpty""": """La papelera está vacía.""",
  """photoBoard.emptyTrash""": """Vaciar papelera""",
  """photoBoard.emptyTrashConfirm""": """¿Vaciar la papelera?""",
  """photoBoard.emptyTrashConfirmBody""":
      """Todas las fotos en la papelera se eliminarán permanentemente. Esta acción no se puede deshacer.""",
  """photoBoard.emptyTrashFailed""": """No se pudo vaciar la papelera.""",
  """photoBoard.failedToLoadTrash""": """No se pudo cargar la papelera.""",
  """photoBoard.restore""": """Restaurar""",
  """photoBoard.restoreFailed""": """No se pudo restaurar la foto.""",
  """photoBoard.permanentlyDelete""": """Eliminar para siempre""",
  """photoBoard.permanentlyDeleteConfirm""":
      """¿Eliminar esta foto permanentemente?""",
  """photoBoard.permanentlyDeleteConfirmBody""":
      """Esta acción no se puede deshacer.""",
  """photoBoard.deleteFolder""": """Eliminar carpeta""",
  """photoBoard.deleteFolderConfirm""": """¿Eliminar esta carpeta?""",
  """photoBoard.deleteFolderKeepPhotos""": """Mover fotos a la raíz""",
  """photoBoard.deleteFolderDeleteAll""": """Eliminar carpeta y fotos""",
  """photoBoard.newFolder""": """Nueva carpeta""",
  """photoBoard.folderName""": """Nombre de la carpeta""",
  """photoBoard.renameFolder""": """Renombrar carpeta""",
  """photoBoard.caption""": """Descripción""",
  """photoBoard.addMenu.upload""": """Subir fotos""",
  """photoBoard.addMenu.camera""": """Tomar foto""",
  """photoBoard.addMenu.newFolder""": """Nueva carpeta""",
  """photoBoard.sort.foldersFirst""": """Carpetas primero""",
  """photoBoard.sort.newestFirst""": """Más recientes""",
  """photoBoard.sort.oldestFirst""": """Más antiguos""",
  """photoBoard.sort.captionAZ""": """Descripción A–Z""",
  """photoBoard.sort.captionZA""": """Descripción Z–A""",
  """photoBoard.sort.custom""": """Personalizado""",
  """share.title""": """Compartir con Pantry""",
  """share.chooseHouse""": """Elegir casa""",
  """share.choosePhotoDestination""": """Subir a""",
  """share.photoBoardRoot""": """Tablón de fotos""",
  """share.newFolder""": """Nueva carpeta""",
  """share.newFolderName""": """Nombre de la carpeta""",
  """share.failedToCreateFolder""": """No se pudo crear la carpeta.""",
  """share.failedToOpenShare""":
      """No se pudo abrir el contenido compartido.""",
  """share.noHouses""": """No hay casas disponibles. Crea una casa primero.""",
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
  """sync.offline""": """Sin conexión""",
  """sync.syncing""": """Sincronizando cambios…""",
  """sync.syncError""": """No se pudieron sincronizar los cambios""",
  """sync.retry""": """Reintentar""",
};
