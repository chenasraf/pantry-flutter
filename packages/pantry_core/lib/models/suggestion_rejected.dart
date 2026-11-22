/// Guesses the person dropped before saving an item, so the household's item
/// memory stops offering them.
class SuggestionRejected {
  /// The guessed category that was dropped.
  final int? categoryId;

  /// Whether the remembered amount was dropped.
  final bool quantity;

  const SuggestionRejected({this.categoryId, this.quantity = false});

  bool get isEmpty => categoryId == null && !quantity;

  Map<String, dynamic> toJson() => {
    'categoryId': ?categoryId,
    if (quantity) 'quantity': true,
  };

  static SuggestionRejected? fromJson(Object? json) {
    if (json is! Map) return null;
    final rejected = SuggestionRejected(
      categoryId: json['categoryId'] as int?,
      quantity: json['quantity'] == true,
    );
    return rejected.isEmpty ? null : rejected;
  }
}
