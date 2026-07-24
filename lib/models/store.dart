/// A single opening-hours interval for a store.
///
/// [day] is ISO-8601: 1 = Monday … 7 = Sunday, identical to Dart's
/// [DateTime.weekday] — store and read the integer as-is, no conversion.
/// [start] and [end] are 24-hour `HH:MM` strings, with `start` < `end`
/// (no overnight/wrap intervals).
class OpeningHoursInterval {
  final int
  day; // 1..7, ISO-8601 (1 = Monday .. 7 = Sunday) == DateTime.weekday
  final String start; // "HH:MM"
  final String end; // "HH:MM"

  const OpeningHoursInterval({
    required this.day,
    required this.start,
    required this.end,
  });

  factory OpeningHoursInterval.fromJson(Map<String, dynamic> json) =>
      OpeningHoursInterval(
        day: json['day'] as int,
        start: json['start'] as String,
        end: json['end'] as String,
      );

  Map<String, dynamic> toJson() => {'day': day, 'start': start, 'end': end};
}

class Store {
  final int id;
  final int houseId;
  final String name;
  final String icon;
  final String color;
  final String? location;
  final List<OpeningHoursInterval>? openingHours;
  final String? contact;
  final String? responsible;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  const Store({
    required this.id,
    required this.houseId,
    required this.name,
    required this.icon,
    required this.color,
    this.location,
    this.openingHours,
    this.contact,
    this.responsible,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    location: json['location'] as String?,
    openingHours: (json['openingHours'] as List?)
        ?.map((e) => OpeningHoursInterval.fromJson(e as Map<String, dynamic>))
        .toList(),
    contact: json['contact'] as String?,
    responsible: json['responsible'] as String?,
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'icon': icon,
    'color': color,
    'location': location,
    'openingHours': openingHours?.map((e) => e.toJson()).toList(),
    'contact': contact,
    'responsible': responsible,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Store copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? updatedAt,
  }) => Store(
    id: id ?? this.id,
    houseId: houseId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    location: location,
    openingHours: openingHours,
    contact: contact,
    responsible: responsible,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// True when none of the optional info fields carry any content — used by the
  /// details view to show a placeholder instead of empty rows.
  bool get hasNoDetails =>
      (location == null || location!.trim().isEmpty) &&
      (openingHours == null || openingHours!.isEmpty) &&
      (contact == null || contact!.trim().isEmpty) &&
      (responsible == null || responsible!.trim().isEmpty) &&
      (notes == null || notes!.trim().isEmpty);
}
