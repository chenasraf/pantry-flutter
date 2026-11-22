import 'package:pantry_core/models/suggestion_rejected.dart';
import 'package:pantry_core/services/item_memory_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/item_input.dart';

/// The guesses a person has dropped for one item being composed.
class ItemGuessDrops {
  /// The quantity read out of the typed text, so the text is taken whole as
  /// the name.
  bool parsedQuantity = false;

  /// The amount remembered for the name on the target list.
  bool rememberedQuantity = false;

  /// The remembered category that was dropped.
  int? categoryId;

  void clear() {
    parsedQuantity = false;
    rememberedQuantity = false;
    categoryId = null;
  }

  /// What to send with the item. A dropped amount is only reported when the
  /// item goes out without one: an item saved with another amount teaches
  /// that amount instead, and reporting the drop would stop it from doing so.
  SuggestionRejected? rejection({required String? submittedQuantity}) {
    final rejected = SuggestionRejected(
      categoryId: categoryId,
      quantity: rememberedQuantity && (submittedQuantity ?? '').trim().isEmpty,
    );
    return rejected.isEmpty ? null : rejected;
  }
}

/// What the typed text of one item reads as: its name, a quantity typed into
/// it or remembered for it, and the category the household usually files it
/// under.
class ItemGuess {
  final String name;
  final String? quantity;

  /// Whether [quantity] comes from item memory rather than the typed text.
  final bool quantityRemembered;

  final int? categoryId;

  const ItemGuess(
    this.name, {
    this.quantity,
    this.quantityRemembered = false,
    this.categoryId,
  });

  /// Guesses for [text] added to [listId] in [houseId]. A category is only
  /// guessed among [usableCategoryIds], and nothing in [drops] is offered
  /// again. With smart input off the text is the name, as typed.
  factory ItemGuess.of(
    String text, {
    required int houseId,
    required int? listId,
    required Iterable<int> usableCategoryIds,
    ItemGuessDrops? drops,
  }) {
    final typed = text.trim();
    if (!PrefsService.instance.smartItemInput || typed.isEmpty) {
      return ItemGuess(typed);
    }
    final parsed = drops?.parsedQuantity == true
        ? ItemInput(typed)
        : parseItemInput(
            typed,
            LocaleService.instance.effectiveLocale.languageCode,
          );
    final memory = ItemMemoryService.instance;
    String? quantity = parsed.quantity;
    var remembered = false;
    if (quantity == null &&
        listId != null &&
        drops?.rememberedQuantity != true) {
      quantity = memory.guessQuantity(houseId, listId, parsed.name);
      remembered = quantity != null;
    }
    final categoryId = memory.guessCategory(
      houseId,
      parsed.name,
      usableCategoryIds,
    );
    return ItemGuess(
      parsed.name,
      quantity: quantity,
      quantityRemembered: remembered,
      categoryId: categoryId == drops?.categoryId ? null : categoryId,
    );
  }

  /// Drop the quantity guess: a typed one gives the text back to the name, a
  /// remembered one is not offered again.
  void dropQuantity(ItemGuessDrops drops) {
    if (quantityRemembered) {
      drops.rememberedQuantity = true;
    } else {
      drops.parsedQuantity = true;
    }
  }
}
