import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/widgets/sync_status.dart';

void main() {
  final manager = SyncManager.instance;

  void setState({
    required SyncStatus status,
    int pending = 0,
    required bool hasBacklog,
  }) {
    manager.status.value = status;
    manager.pendingCount.value = pending;
    manager.hasBacklog.value = hasBacklog;
  }

  tearDown(() async => manager.reset());

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('SyncStatusAvatarBadge', () {
    testWidgets('shows no badge when there is nothing to report', (
      tester,
    ) async {
      setState(status: SyncStatus.idle, hasBacklog: false);
      await tester.pumpWidget(
        wrap(
          const SyncStatusAvatarBadge(
            ringColor: Colors.white,
            child: Icon(Icons.person, key: Key('avatar')),
          ),
        ),
      );

      expect(find.byKey(const Key('avatar')), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets('shows an error badge on sync error', (tester) async {
      setState(status: SyncStatus.error, hasBacklog: false);
      await tester.pumpWidget(
        wrap(
          const SyncStatusAvatarBadge(
            ringColor: Colors.white,
            child: Icon(Icons.person, key: Key('avatar')),
          ),
        ),
      );

      expect(find.byKey(const Key('avatar')), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows an offline badge when a backlog is waiting', (
      tester,
    ) async {
      setState(status: SyncStatus.offline, pending: 3, hasBacklog: true);
      await tester.pumpWidget(
        wrap(
          const SyncStatusAvatarBadge(
            ringColor: Colors.white,
            child: Icon(Icons.person, key: Key('avatar')),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('reacts to status changes without a remount', (tester) async {
      setState(status: SyncStatus.idle, hasBacklog: false);
      await tester.pumpWidget(
        wrap(
          const SyncStatusAvatarBadge(
            ringColor: Colors.white,
            child: Icon(Icons.person, key: Key('avatar')),
          ),
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsNothing);

      setState(status: SyncStatus.error, hasBacklog: false);
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('syncStatusPresentation', () {
    testWidgets('is null when there is no backlog or error', (tester) async {
      SyncStatusPresentation? result = (
        icon: Icons.abc,
        color: Colors.black,
        label: 'seed',
      );
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              result = syncStatusPresentation(
                context,
                status: SyncStatus.idle,
                pending: 0,
                hasBacklog: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isNull);
    });

    testWidgets('offline with pending changes reports the pending label', (
      tester,
    ) async {
      SyncStatusPresentation? result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              result = syncStatusPresentation(
                context,
                status: SyncStatus.offline,
                pending: 2,
                hasBacklog: true,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isNotNull);
      expect(result!.icon, Icons.cloud_off_outlined);
      expect(result!.label, contains('2'));
    });
  });
}
