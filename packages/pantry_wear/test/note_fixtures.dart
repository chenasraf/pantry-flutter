import 'package:flutter/foundation.dart';
import 'package:pantry_core/models/note.dart';

/// Sample notes, shaped like the ones a household keeps.
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
class SampleNote {
  final int id;
  final String title;

  /// Raw markdown, exactly as `Note.content` holds it.
  final String body;

  /// The user's chosen note colour, as the server stores it — a `#RRGGBB`
  /// string. The set is the Material 500 palette `note_form_view.dart` offers,
  /// so the samples span both ink branches: yellow and amber take dark text,
  /// the rest light.
  final String? color;
  final bool pinned;

  const SampleNote({
    required this.id,
    required this.title,
    required this.body,
    this.color,
    this.pinned = false,
  });
}

const sampleNotes = <SampleNote>[
  // Pure task list — the case scope A is built for.
  SampleNote(
    id: 1,
    title: 'Hardware shop',
    pinned: true,
    color: '#2196F3', // blue
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
  SampleNote(
    id: 2,
    title: 'Boiler service',
    color: '#FFC107', // amber — light enough to need dark ink
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
  SampleNote(
    id: 3,
    title: 'Bin day',
    color: '#4CAF50', // green
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
  SampleNote(
    id: 4,
    title: 'House rules for sitters',
    color: '#9C27B0', // purple
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
  SampleNote(id: 5, title: 'Spare key with Dana', body: ''),

  // RTL, with tasks, so direction is judged on both surfaces.
  SampleNote(
    id: 6,
    title: 'פינוי אשפה',
    color: '#FFEB3B', // yellow — the lightest the palette offers
    body: '''
שלישי בבוקר, לפני שבע.

- [ ] להוציא את הפח הירוק
- [x] קרטונים לפינה
- [ ] לבדוק את קוד השער
''',
  ),
];

/// The sample as the app sees it: what the mirror lands and the wall draws.
Note noteOf(SampleNote sample, {int houseId = 1}) => Note(
  id: sample.id,
  houseId: houseId,
  title: sample.title,
  content: sample.body,
  color: sample.color,
  createdBy: 'someone',
  sortOrder: sample.id,
  isPinned: sample.pinned,
  createdAt: 0,
  updatedAt: 0,
);

List<Note> sampleNoteRecords({int houseId = 1}) => [
  for (final s in sampleNotes) noteOf(s, houseId: houseId),
];
