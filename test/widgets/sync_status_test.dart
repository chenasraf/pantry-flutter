import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/sync/sync_manager.dart';
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

  group('SyncActivityIndicator', () {
    Finder spinner() => find.byType(CircularProgressIndicator);
    Finder done() => find.byIcon(Icons.cloud_done_outlined);

    testWidgets('spins while syncing, then shows done and clears', (
      tester,
    ) async {
      setState(status: SyncStatus.idle, hasBacklog: false);
      await tester.pumpWidget(wrap(const SyncActivityIndicator()));
      expect(spinner(), findsNothing);
      expect(done(), findsNothing);

      setState(status: SyncStatus.syncing, pending: 1, hasBacklog: false);
      await tester.pump();
      expect(spinner(), findsOneWidget);

      setState(status: SyncStatus.idle, hasBacklog: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(spinner(), findsNothing);
      expect(done(), findsOneWidget);

      await tester.pump(SyncActivityIndicator.doneDuration);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(done(), findsNothing);
    });

    testWidgets('shows nothing on an idle screen that never synced', (
      tester,
    ) async {
      setState(status: SyncStatus.idle, hasBacklog: false);
      await tester.pumpWidget(wrap(const SyncActivityIndicator()));
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(Icon), findsNothing);
      expect(spinner(), findsNothing);
    });

    testWidgets('shows offline with pending changes, and errors', (
      tester,
    ) async {
      setState(status: SyncStatus.offline, pending: 2, hasBacklog: true);
      await tester.pumpWidget(wrap(const SyncActivityIndicator()));
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

      setState(status: SyncStatus.error, pending: 2, hasBacklog: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });
  });
}
