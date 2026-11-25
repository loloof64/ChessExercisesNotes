import 'package:chess_exercises_notes/models/synchronisation_items/sync_state.dart';
import 'package:chess_exercises_notes/providers/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeSync extends Sync {
  void emit(SyncStatus status) => state = switch (status) {
    SyncStatus.success => const SyncState(status: SyncStatus.success),
    _ => SyncState(status: status),
  };
}

class _Page extends ConsumerWidget {
  const _Page(this.onSyncEnd);
  final VoidCallback onSyncEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForSyncEnd(ref, onSyncEnd);
    return const SizedBox();
  }
}

void main() {
  late ProviderContainer container;
  late int refreshes;

  Future<_FakeSync> pumpPage(WidgetTester tester) async {
    refreshes = 0;
    container = ProviderContainer(
      overrides: [syncProvider.overrideWith(_FakeSync.new)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: _Page(() => refreshes++)),
      ),
    );
    return container.read(syncProvider.notifier) as _FakeSync;
  }

  Future<void> runSync(
    WidgetTester tester,
    _FakeSync sync,
    SyncStatus end,
  ) async {
    sync.emit(SyncStatus.syncing);
    await tester.pump();
    sync.emit(SyncStatus.syncing); // progress update
    await tester.pump();
    sync.emit(end);
    await tester.pump();
  }

  testWidgets('refreshes once per finished sync, failed ones included', (
    tester,
  ) async {
    final sync = await pumpPage(tester);

    await runSync(tester, sync, SyncStatus.success);
    expect(refreshes, 1);

    // A failed sync may have changed some files already.
    await runSync(tester, sync, SyncStatus.error);
    expect(refreshes, 2);
  });

  testWidgets('a covered page catches up when shown again', (tester) async {
    final sync = await pumpPage(tester);
    await runSync(tester, sync, SyncStatus.success);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute(builder: (_) => const SizedBox()));
    await tester.pumpAndSettle();
    await runSync(tester, sync, SyncStatus.success);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(refreshes, 2);
  });
}
