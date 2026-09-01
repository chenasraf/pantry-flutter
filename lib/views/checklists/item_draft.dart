import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/models/item_lifecycle.dart';
import 'package:pantry/utils/currencies.dart';
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

  void reset(ItemLifecycle defaultLifecycle) {
    name = '';
    description = '';
    quantity = '';
    categoryId = null;
    storeIds = {};
    labelIds = {};
    lifecycle = defaultLifecycle;
    recurrence = RecurrenceState();
    imageFile = null;
    imageBytes = null;
    barcode = null;
    price = PricesDraft.empty(price.storeless.currency);
    customFields = const [];
  }

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
