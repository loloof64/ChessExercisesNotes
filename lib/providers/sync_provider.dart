import 'dart:io';

import 'package:chess_exercises_notes/models/synchronisation_items/sync_state.dart';
import 'package:chess_exercises_notes/providers/dropbox_login_provider.dart';
import 'package:chess_exercises_notes/utils/dropbox_api_service.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:chess_exercises_notes/utils/sync_engine.dart';
import 'package:chess_exercises_notes/utils/sync_manifest_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

@Riverpod(keepAlive: true)
class Sync extends _$Sync {
  @override
  SyncState build() => const SyncState();

  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;

    state = const SyncState(status: SyncStatus.syncing);

    try {
      final loginNotifier = ref.read(dropboxLoginProvider.notifier);
      final accessToken = await loginNotifier.getAccessToken();

      if (accessToken == null) {
        state = const SyncState(
          status: SyncStatus.error,
          errorMessage: 'Not logged in',
        );
        return;
      }

      final appSupportDir = await getApplicationSupportDirectory();
      final booksDir = Directory(
        p.join(appSupportDir.path, booksRootFolderName),
      );

      // Ensure local books directory exists
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final manifestService = SyncManifestService(appSupportDir: appSupportDir);
      final previousManifest = await manifestService.load();

      final api = DropboxApiService(accessToken);
      final engine = SyncEngine(
        api: api,
        localBooksDir: booksDir,
        previousManifest: previousManifest,
        onProgress: (total, completed) {
          state = SyncState(
            status: SyncStatus.syncing,
            totalActions: total,
            completedActions: completed,
          );
        },
      );

      final newManifest = await engine.sync();
      await manifestService.save(newManifest);

      state = const SyncState(status: SyncStatus.success);
    } catch (e, st) {
      debugPrint('Sync failed: $e\n$st');
      state = SyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }
}
