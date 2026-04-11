import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/views/notifications/notifications_view.dart';

import '../helpers/fakes.dart';
import '../helpers/test_models.dart';

void main() {
  group('NotificationsView', () {
    testWidgets('shows empty state when there are no notifications', (
      tester,
    ) async {
      final controller = FakeNotificationsController();

      await tester.pumpWidget(
        MaterialApp(home: NotificationsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text(m.notifications.empty), findsOneWidget);
    });

    testWidgets('renders a list of notifications', (tester) async {
      final controller = FakeNotificationsController(
        notifications: [
          makeNotification(notificationId: 1, subject: 'alice added Milk'),
          makeNotification(notificationId: 2, subject: 'bob uploaded a photo'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: NotificationsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('alice added Milk'), findsOneWidget);
      expect(find.text('bob uploaded a photo'), findsOneWidget);
    });

    testWidgets('shows the dismiss-all action when notifications exist', (
      tester,
    ) async {
      final controller = FakeNotificationsController(
        notifications: [makeNotification()],
      );

      await tester.pumpWidget(
        MaterialApp(home: NotificationsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('hides the dismiss-all action when empty', (tester) async {
      final controller = FakeNotificationsController();

      await tester.pumpWidget(
        MaterialApp(home: NotificationsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('tapping dismiss-all calls controller.dismissAll', (
      tester,
    ) async {
      final controller = FakeNotificationsController(
        notifications: [makeNotification()],
      );

      await tester.pumpWidget(
        MaterialApp(home: NotificationsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(controller.dismissAllCalls, 1);
    });

    testWidgets('swipe-to-dismiss removes a notification', (tester) async {
      final controller = FakeNotificationsController(
        notifications: [
          makeNotification(notificationId: 1, subject: 'first'),
          makeNotification(notificationId: 2, subject: 'second'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: NotificationsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('first'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(controller.dismissCalls, 1);
      expect(controller.lastDismissed?.notificationId, 1);
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });
  });
}
