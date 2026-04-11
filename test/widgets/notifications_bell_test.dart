import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/notifications_bell.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

void main() {
  group('NotificationsBell', () {
    testWidgets('renders the bell icon', (tester) async {
      final controller = FakeNotificationsController();
      var tapped = 0;

      await tester.pumpWidget(
        wrapForTest(
          NotificationsBell(controller: controller, onTap: () => tapped++),
        ),
      );

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(tapped, 0);
    });

    testWidgets('shows no badge when there are no notifications', (
      tester,
    ) async {
      final controller = FakeNotificationsController();

      await tester.pumpWidget(
        wrapForTest(NotificationsBell(controller: controller, onTap: () {})),
      );

      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('shows badge with count when there are notifications', (
      tester,
    ) async {
      final controller = FakeNotificationsController(
        notifications: [
          makeNotification(notificationId: 1),
          makeNotification(notificationId: 2),
          makeNotification(notificationId: 3),
        ],
      );

      await tester.pumpWidget(
        wrapForTest(NotificationsBell(controller: controller, onTap: () {})),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows "99+" when count exceeds 99', (tester) async {
      final controller = FakeNotificationsController(
        notifications: List.generate(
          120,
          (i) => makeNotification(notificationId: i),
        ),
      );

      await tester.pumpWidget(
        wrapForTest(NotificationsBell(controller: controller, onTap: () {})),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('invokes onTap when pressed', (tester) async {
      final controller = FakeNotificationsController();
      var tapped = 0;

      await tester.pumpWidget(
        wrapForTest(
          NotificationsBell(controller: controller, onTap: () => tapped++),
        ),
      );

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });
  });
}
