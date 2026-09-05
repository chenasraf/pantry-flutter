import 'package:flutter/material.dart';

/// PROTOTYPE — notes to judge the wrist reading experience against.
///
/// Note bodies are **raw markdown**: that is what the server stores and what
/// the Nextcloud web app co-edits. The phone's Quill editor is a view over
/// this string, not a different representation — so a watch reading and a
/// watch writing touch the very same bytes.
///
/// The set is chosen to cover the shapes a household note actually takes, and
/// the three that break a naive design: a note whose tasks are interleaved
/// with prose, a note far longer than the screen, and an RTL note.
@immutable
class ProtoNote {
  final int id;
  final String title;

  /// Raw markdown, exactly as `Note.content` holds it.
  final String body;

  /// The user's chosen note colour, as the phone stores it.
  final Color? color;
  final bool pinned;

  const ProtoNote({
    required this.id,
    required this.title,
    required this.body,
    this.color,
    this.pinned = false,
  });
}

const protoNotes = <ProtoNote>[
  // Pure task list — the case scope A is built for.
  ProtoNote(
    id: 1,
    title: 'Hardware shop',
    pinned: true,
    color: Color(0xFF3A6EA5),
    body: '''
- [x] Picture hooks
- [ ] Masking tape
- [ ] 6mm wall plugs
- [x] Sandpaper, medium
- [ ] Wood glue
- [ ] Spare fuses
''',
  ),

  // Prose with tasks interleaved — the note that punishes any design which
  // lifts the checkboxes out into their own surface.
  ProtoNote(
    id: 2,
    title: 'Boiler service',
    color: Color(0xFF8E6A3A),
    body: '''
Engineer comes **Thursday between 8 and 12**. Someone has to be in.

- [ ] Clear the cupboard under the stairs
- [ ] Find the service booklet

He asked us to run the heating for an hour beforehand so it is warm when he
gets here.

- [ ] Turn heating on at 7
''',
  ),

  // Formatting the watch has to render or flatten: headings, emphasis, a link,
  // a nested list, inline code.
  ProtoNote(
    id: 3,
    title: 'Bin day',
    color: Color(0xFF4B7F52),
    body: '''
## Collections

- Green bin — **Tuesday**
- Recycling — every other **Friday**
  - Glass goes in the box, not the bin
- Garden waste — first Monday, `March–November` only

Missed collections: [report here](https://example.org/bins)
''',
  ),

  // Long enough that reading is the problem, not ticking.
  ProtoNote(
    id: 4,
    title: 'House rules for sitters',
    color: Color(0xFF7A4A6E),
    body: '''
## Cat

Fed twice a day, half a pouch each time. She will tell you she has not been
fed. She has been fed.

## Heating

The thermostat in the hall overrides the app. If the radiators are cold, check
the hall dial first — it gets knocked when the coats go up.

## Bins

Green bin Tuesday. The bin store code is on the fridge.

## Wifi

Guest network, password on the fridge. It drops about once a week; unplug the
white box in the cupboard for ten seconds.

## If something breaks

Call the letting agent, not the landlord. Number is in the drawer.
''',
  ),

  // No body at all — the empty case a wall card still has to draw.
  ProtoNote(id: 5, title: 'Spare key with Dana', body: ''),

  // RTL, with tasks, so direction is judged on both surfaces.
  ProtoNote(
    id: 6,
    title: 'פינוי אשפה',
    color: Color(0xFF3A7A7A),
    body: '''
שלישי בבוקר, לפני שבע.

- [ ] להוציא את הפח הירוק
- [x] קרטונים לפינה
- [ ] לבדוק את קוד השער
''',
  ),
];
