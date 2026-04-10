import 'package:flutter_test/flutter_test.dart';

// TODO: Smoke tests for HomeView, NotesWallView, ChecklistsView, and
// PhotoBoardView are intentionally omitted.
//
// These views instantiate their controllers internally (e.g.
// `late final _controller = HomeController();`) rather than accepting them
// via constructor injection. Their controllers in turn call the global
// service singletons (HouseService.instance, NoteService.instance,
// PhotoService.instance, ChecklistService.instance) which perform real HTTP
// calls via ApiClient.instance (no mock HTTP client hook). Rendering any of
// these views in a test causes them to start a real network request and
// either hang, throw, or log noisy async errors.
//
// To enable smoke tests here, the production views would need one of:
//   1. An optional `controller` constructor parameter that defaults to a new
//      one, so tests can pass a fake.
//   2. A dependency-injection point for the backing services (e.g. a
//      `ServiceLocator` or a constructor parameter).
//   3. An HTTP client override on ApiClient so tests can replace it with a
//      fake that returns synthetic responses.
//
// Any of these changes is a production-code refactor and out of scope for
// the current test pass. Individual widgets used by these views are already
// covered by the tests under test/widgets/.

void main() {
  test('main-view smoke tests skipped — see TODO above', () {
    expect(true, isTrue);
  });
}
