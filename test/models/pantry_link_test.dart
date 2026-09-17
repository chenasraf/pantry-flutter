import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/list_link.dart';
import 'package:pantry_core/models/note_link.dart';
import 'package:pantry_core/models/photo_link.dart';

/// The `pantry://` grammar, which two devices have to agree on down to the
/// segment order: the watch builds these strings and hands them to the phone
/// over the Data Layer, and the phone's link service is the only thing that
/// ever reads them back. A disagreement lands the wearer on the wrong screen
/// with nothing to say why.
void main() {
  test('a photo link survives the round trip', () {
    final uri = PhotoLink.uri(3, 91);

    expect(uri.toString(), 'pantry://photo/3/91');
    final parsed = PhotoLink.fromUri(uri);
    expect(parsed?.houseId, 3);
    expect(parsed?.photoId, 91);
  });

  test('a note link survives the round trip', () {
    final uri = NoteLink.uri(3, 12);

    expect(uri.toString(), 'pantry://note/3/12');
    final parsed = NoteLink.fromUri(uri);
    expect(parsed?.houseId, 3);
    expect(parsed?.noteId, 12);
  });

  test('a link missing its house is not a link', () {
    // Unlike a list, there is no selected photo board to fall back on, so a
    // link that names only the photo has nowhere to land.
    expect(PhotoLink.fromUri(Uri.parse('pantry://photo/91')), isNull);
    expect(NoteLink.fromUri(Uri.parse('pantry://note/12')), isNull);
  });

  test('a link whose ids are not numbers is not a link', () {
    expect(PhotoLink.fromUri(Uri.parse('pantry://photo/3/latest')), isNull);
    expect(NoteLink.fromUri(Uri.parse('pantry://note/home/12')), isNull);
  });

  test('another scheme is not ours, however well it is shaped', () {
    expect(PhotoLink.fromUri(Uri.parse('https://photo/3/91')), isNull);
    expect(NoteLink.fromUri(Uri.parse('https://note/3/12')), isNull);
  });

  test('the three hosts never answer for each other', () {
    // They arrive on one scheme and therefore through one subscription, so the
    // parsers are tried in turn against every incoming URL. Any of them
    // claiming another's link would send the wearer to the wrong section.
    final photo = PhotoLink.uri(3, 91);
    final note = NoteLink.uri(3, 12);
    final list = ListLink.uri(3, 7);

    expect(ListLink.fromUri(photo), isNull);
    expect(ListLink.fromUri(note), isNull);
    expect(PhotoLink.fromUri(note), isNull);
    expect(PhotoLink.fromUri(list), isNull);
    expect(NoteLink.fromUri(photo), isNull);
    expect(NoteLink.fromUri(list), isNull);
  });
}
