import 'package:flutter/material.dart';

/// PROTOTYPE — stand-in data for the checklists page. Nothing here reaches a
/// server: the page shows gesture, density and the feel of a hand-rolled
/// snap, none of which need real fetching.

@immutable
class ProtoCategory {
  final String name;
  final Color color;

  /// A key into `categoryIconMap`, so the watch draws the same icon the phone
  /// does rather than inventing a second vocabulary.
  final String iconKey;

  const ProtoCategory(this.name, this.color, this.iconKey);
}

const _produce = ProtoCategory('Produce', Color(0xFF6FBF73), 'vegetable');
const _dairy = ProtoCategory('Dairy', Color(0xFF6FA8DC), 'dairy');
const _pantryCat = ProtoCategory('Pantry', Color(0xFFD9A75B), 'food');
const _household = ProtoCategory('Household', Color(0xFFB07FD1), 'household');
const _frozen = ProtoCategory('Frozen', Color(0xFF71C7D6), 'frozen');

/// Store colours and icons, keyed by the store names the fixtures use.
const protoStoreColors = <String, Color>{
  'Shufersal': Color(0xFFE08A5B),
  'Am:Pm': Color(0xFF5BA8E0),
  'Lehem Erez': Color(0xFFC98FB0),
};

const protoStoreIcons = <String, String>{
  'Shufersal': 'supermarket',
  'Am:Pm': 'convenience',
  'Lehem Erez': 'bakery',
};

@immutable
class ProtoChecklistItem {
  final int id;
  final String name;
  final String? qty;
  final ProtoCategory category;
  final String store;
  final String? price;
  final String? note;

  /// The real model carries an RRULE, not a flag — the detail page has to
  /// describe the schedule, which a boolean cannot do.
  final String? rrule;
  final bool done;
  final bool skipped;

  const ProtoChecklistItem({
    required this.id,
    required this.name,
    required this.category,
    required this.store,
    this.qty,
    this.price,
    this.note,
    this.rrule,
    this.done = false,
    this.skipped = false,
  });

  ProtoChecklistItem copyWith({bool? done, bool? skipped}) =>
      ProtoChecklistItem(
        id: id,
        name: name,
        category: category,
        store: store,
        qty: qty,
        price: price,
        note: note,
        rrule: rrule,
        done: done ?? this.done,
        skipped: skipped ?? this.skipped,
      );

  bool get recurring => rrule != null;

  /// The description the read-only detail page shows under the name. Long
  /// enough on a couple of items to prove the wrapping case.
  String? get description => note;
}

/// Long enough to scroll well past a watch screen, spread over five categories
/// so grouping has something to group, and carrying the two cases that break
/// watch rows: a name too long for one line, and a right-to-left name.
const protoChecklistItems = <ProtoChecklistItem>[
  ProtoChecklistItem(
    id: 1,
    name: 'Milk',
    qty: '2 L',
    category: _dairy,
    store: 'Shufersal',
    price: '₪7.90',
  ),
  ProtoChecklistItem(
    id: 2,
    name: 'Greek yoghurt',
    qty: '1 kg',
    category: _dairy,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 3,
    name: 'Parmesan',
    category: _dairy,
    store: 'Shufersal',
    note: 'The wedge, not the pre-grated tub.',
  ),
  ProtoChecklistItem(
    id: 4,
    name: 'חלב עיזים',
    qty: '1',
    category: _dairy,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 5,
    name: 'Bananas',
    qty: '6',
    category: _produce,
    store: 'Shufersal',
    done: true,
  ),
  ProtoChecklistItem(
    id: 6,
    name: 'Tomatoes',
    qty: '500 g',
    category: _produce,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 7,
    name: 'Cucumber',
    qty: '3',
    category: _produce,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 8,
    name: 'Lemons',
    qty: '4',
    category: _produce,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 9,
    name: 'Coffee beans, dark roast',
    qty: '500 g',
    category: _pantryCat,
    store: 'Shufersal',
    price: '₪48.00',
    rrule: 'FREQ=WEEKLY;INTERVAL=2',
  ),
  ProtoChecklistItem(
    id: 10,
    name: 'Olive oil',
    category: _pantryCat,
    store: 'Shufersal',
    price: '₪32.50',
  ),
  ProtoChecklistItem(
    id: 11,
    name: 'Chickpeas',
    qty: '2 tins',
    category: _pantryCat,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 12,
    name: 'Rice',
    qty: '1 kg',
    category: _pantryCat,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 13,
    name: 'Dark chocolate, 70%',
    category: _pantryCat,
    store: 'Shufersal',
  ),
  ProtoChecklistItem(
    id: 14,
    name: 'Kitchen roll',
    qty: '4',
    category: _household,
    store: 'Am:Pm',
    rrule: 'FREQ=MONTHLY;INTERVAL=1',
  ),
  ProtoChecklistItem(
    id: 15,
    name: 'Washing-up liquid',
    category: _household,
    store: 'Am:Pm',
  ),
  ProtoChecklistItem(
    id: 16,
    name: 'Bin bags',
    category: _household,
    store: 'Am:Pm',
    done: true,
  ),
  ProtoChecklistItem(
    id: 17,
    name: 'Toothpaste',
    category: _household,
    store: 'Am:Pm',
  ),
  ProtoChecklistItem(
    id: 18,
    name: 'Frozen peas',
    category: _frozen,
    store: 'Am:Pm',
  ),
  ProtoChecklistItem(
    id: 19,
    name: 'Chicken thighs',
    qty: '1 kg',
    category: _frozen,
    store: 'Am:Pm',
    price: '₪41.20',
  ),
  ProtoChecklistItem(
    id: 20,
    name: 'Oat milk',
    qty: '2',
    category: _dairy,
    store: 'Am:Pm',
  ),
  ProtoChecklistItem(
    id: 21,
    name: 'Cat food',
    qty: '8 pouches',
    category: _household,
    store: 'Am:Pm',
    rrule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TH',
  ),
  ProtoChecklistItem(
    id: 22,
    name: 'Sourdough loaf',
    category: _pantryCat,
    store: 'Lehem Erez',
  ),
  ProtoChecklistItem(
    id: 23,
    name: 'Eggs',
    qty: '12',
    category: _dairy,
    store: 'Lehem Erez',
  ),
];

/// The account page names the house; the rail does not, so this is only here
/// to stand in for what that page would show.
const protoHouseName = 'Home';
const protoListTitle = 'Groceries';

/// A list carries its own icon and colour, the same as a category or a store,
/// so the rail names it in its own livery rather than as plain text.
const protoListIconKey = 'cart';
const protoListColor = Color(0xFF8FB8E0);

/// The store a live session is standing in. Switching between stores is card
/// 718's, so the prototype stands in one store and never advances.
const protoSessionStore = 'Shufersal';
