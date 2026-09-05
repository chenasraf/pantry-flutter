import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/pantry_wear.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final link = WearDeepLink.instance;

  setUp(link.take);

  test('reads the launch link out of the entrypoint arguments', () {
    link.markFrom(['round', 'pantry://list/3/7']);

    expect(link.pending?.houseId, 3);
    expect(link.pending?.listId, 7);
  });

  test('does not depend on the shape argument coming first', () {
    link.markFrom(['pantry://list/3/7', 'round']);

    expect(link.pending?.listId, 7);
  });

  test('a launch with nothing but a shape is not a request', () {
    link.markFrom(['square']);

    expect(link.pending, isNull);
  });

  test('a url that is not one of ours is not a request', () {
    link.markFrom(['round', 'https://example.test/list/3/7']);

    expect(link.pending, isNull);
  });

  test('taking a request clears it, so it is acted on once', () {
    link.markFrom(['pantry://list/3/7']);

    expect(link.take(), isNotNull);
    expect(link.take(), isNull);
  });
}
