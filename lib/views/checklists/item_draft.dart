import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/models/item_start_values.dart';
import 'package:pantry_core/utils/currencies.dart';
import 'form_components.dart';
import 'price_input.dart';

/// Draft state for an item being composed in the quick-add bar.
class ItemDraft {
  String name = '';
  String description = '';
  String quantity = '';
  int? categoryId;
  Set<int> storeIds = {};
  Set<int> labelIds = {};
  ItemLifecycle lifecycle = ItemLifecycle.staple;
  // RRULE state when lifecycle == recurring. Default = weekly every 1 week.
  RecurrenceState recurrence = RecurrenceState();
  XFile? imageFile;
  Uint8List? imageBytes;

  /// Scanned barcode (EAN/UPC) carried through to the created item. Set by the
  /// scan flow; null for hand-typed items.
  String? barcode;

  /// Optional prices for the composed item. Currency is preserved across
  /// [reset] so the last-picked currency sticks for rapid same-currency adds.
  PricesDraft price = PricesDraft.empty(defaultCurrency);

  /// Custom-field values the user has explicitly set via the custom-fields
  /// tray. Only meaningful once [ItemComposeBarState] marks them edited; an
  /// untouched item falls back to the fields' default seeds.
  List<FieldValue> customFields = const [];

  /// Start this draft on the recurrence [value] describes.
  void applyRecurrence(RecurrenceDefaultValue value) {
    final normalized = value.normalized();
    lifecycle = normalized.kind.lifecycle;
    recurrence = RecurrenceState.fromRrule(
      normalized.rrule,
      repeatFromCompletion: normalized.repeatFromCompletion,
    );
  }

  /// Put [start]'s values on the chips a list can pre-fill, leaving the name,
  /// description, image and price alone.
  void start(ItemStartValues start) {
    quantity = start.quantity;
    categoryId = start.categoryId;
    storeIds = {...start.storeIds};
    labelIds = {...start.labelIds};
    applyRecurrence(start.recurrence);
  }

  void reset(ItemStartValues start) {
    name = '';
    description = '';
    this.start(start);
    imageFile = null;
    imageBytes = null;
    barcode = null;
    price = PricesDraft.empty(price.storeless.currency);
    customFields = const [];
  }

  /// The recurrence the composed item carries, in the shape a list remembers.
  RecurrenceDefaultValue get usedRecurrence => RecurrenceDefaultValue(
    kind: lifecycle.recurrenceKind,
    rrule: rrule,
    repeatFromCompletion: repeatFromCompletion,
  ).normalized();

  bool get repeatFromCompletion => recurrence.repeatFromCompletion;

  String? get rrule {
    if (lifecycle != ItemLifecycle.recurring) return null;
    return recurrence.toRrule();
  }

  bool get deleteOnDoneForCreate => lifecycle == ItemLifecycle.once;
}

/// Result returned by ItemComposeBar's onSubmit so caller can persist.
class ComposeSubmission {
  final String name;
  final String? description;
  final String? quantity;
  final int? categoryId;
  final List<int> storeIds;
  final List<int> labelIds;
  final String? rrule;
  final bool deleteOnDone;
  final bool repeatFromCompletion;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? imageMime;
  final String? barcode;

  /// Prices for the created item, or null when there's no price (create
  /// semantics — omit the field).
  final List<ItemPrice>? prices;

  /// Custom-field values for the created item (fields' defaults, plus any the
  /// user set in the tray), or null when there are none.
  final List<FieldValue>? customFields;

  const ComposeSubmission({
    required this.name,
    this.description,
    this.quantity,
    this.categoryId,
    this.storeIds = const [],
    this.labelIds = const [],
    this.rrule,
    required this.deleteOnDone,
    required this.repeatFromCompletion,
    this.imageBytes,
    this.imageName,
    this.imageMime,
    this.barcode,
    this.prices,
    this.customFields,
  });
}
