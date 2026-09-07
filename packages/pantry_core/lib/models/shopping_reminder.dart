/// The moment at which a reminder surfaces. One [showOn] per reminder row —
/// the same text at two moments is two rows.
enum ShoppingReminderMoment {
  onStart('on_start'),
  onStoreAdvance('on_store_advance'),
  onClose('on_close');

  const ShoppingReminderMoment(this.wire);

  /// The wire value exchanged with the server.
  final String wire;

  static ShoppingReminderMoment fromWire(String value) =>
      ShoppingReminderMoment.values.firstWhere(
        (m) => m.wire == value,
        orElse: () => ShoppingReminderMoment.onStart,
      );
}

/// A house-scoped, user-defined shopping prompt. Surfaced (filtered to
/// [enabled], ordered by [position]) as a non-blocking block at the matching
/// [showOn] moment; acknowledgement is client-local only and never persists.
class ShoppingReminder {
  final int id;
  final int houseId;
  final String text;
  final ShoppingReminderMoment showOn;
  final int position;
  final bool enabled;
  final int createdAt;
  final int updatedAt;

  const ShoppingReminder({
    required this.id,
    required this.houseId,
    required this.text,
    required this.showOn,
    required this.position,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingReminder.fromJson(Map<String, dynamic> json) =>
      ShoppingReminder(
        id: json['id'] as int,
        houseId: json['houseId'] as int,
        text: json['text'] as String,
        showOn: ShoppingReminderMoment.fromWire(json['showOn'] as String),
        position: json['position'] as int,
        enabled: json['enabled'] as bool,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'text': text,
    'showOn': showOn.wire,
    'position': position,
    'enabled': enabled,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  ShoppingReminder copyWith({
    String? text,
    ShoppingReminderMoment? showOn,
    int? position,
    bool? enabled,
    int? updatedAt,
  }) => ShoppingReminder(
    id: id,
    houseId: houseId,
    text: text ?? this.text,
    showOn: showOn ?? this.showOn,
    position: position ?? this.position,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
