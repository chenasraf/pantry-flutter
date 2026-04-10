import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/upload_tile.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('shows progress indicator when loading', (tester) async {
    final controller = FakePhotoBoardController();
    final task = makeUploadTask(progress: 0.5);

    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 120,
          height: 120,
          child: UploadTile(task: task, controller: controller),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('shows refresh icon when errored', (tester) async {
    final controller = FakePhotoBoardController();
    final task = makeUploadTask(error: 'network', done: true);

    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 120,
          height: 120,
          child: UploadTile(task: task, controller: controller),
        ),
      ),
    );

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('tap-to-retry calls controller.retryUpload on errored tile', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    final task = makeUploadTask(error: 'network', done: true);

    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 120,
          height: 120,
          child: UploadTile(task: task, controller: controller),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(controller.retryCalls, 1);
    expect(controller.lastRetried, same(task));
  });

  testWidgets('tapping close dismisses upload', (tester) async {
    final controller = FakePhotoBoardController();
    final task = makeUploadTask(progress: 0.2);

    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 120,
          height: 120,
          child: UploadTile(task: task, controller: controller),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(controller.dismissCalls, 1);
  });
}
