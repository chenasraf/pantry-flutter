/// Which tab a notification maps to on the home screen.
enum NotificationTarget { checklists, photos, notes }

/// A Nextcloud notification as returned by the Notifications OCS API.
class NcNotification {
  final int notificationId;
  final String app;
  final String user;
  final String subject;
  final String message;
  final String datetime;
  final String objectType;
  final String objectId;
  final String? icon;
  final String? link;
  final Map<String, dynamic> subjectRichParameters;

  const NcNotification({
    required this.notificationId,
    required this.app,
    required this.user,
    required this.subject,
    required this.message,
    required this.datetime,
    required this.objectType,
    required this.objectId,
    this.icon,
    this.link,
    this.subjectRichParameters = const {},
  });

  factory NcNotification.fromJson(Map<String, dynamic> json) => NcNotification(
    notificationId: json['notification_id'] as int,
    app: json['app'] as String? ?? '',
    user: json['user'] as String? ?? '',
    // Prefer `subject` (already-parsed plain text) over `subjectRich`
    // (template with `{placeholder}` tokens). Nextcloud populates both.
    subject:
        (json['subject'] as String?) ?? (json['subjectRich'] as String?) ?? '',
    message:
        (json['message'] as String?) ?? (json['messageRich'] as String?) ?? '',
    datetime: json['datetime'] as String? ?? '',
    objectType: json['object_type'] as String? ?? '',
    objectId: json['object_id'] as String? ?? '',
    icon: json['icon'] as String?,
    link: json['link'] as String?,
    subjectRichParameters:
        (json['subjectRichParameters'] as Map<String, dynamic>?) ?? const {},
  );

  /// Parsed timestamp or null if unparseable.
  DateTime? get parsedDatetime => DateTime.tryParse(datetime);

  /// House id extracted from the rich parameters, if present.
  int? get houseId {
    final house = subjectRichParameters['house'];
    if (house is! Map) return null;
    final id = house['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  /// Which tab this notification should open on tap.
  NotificationTarget? get target {
    switch (objectType) {
      case 'photo':
        return NotificationTarget.photos;
      case 'note':
        return NotificationTarget.notes;
      case 'item':
        return NotificationTarget.checklists;
      default:
        return null;
    }
  }
}
