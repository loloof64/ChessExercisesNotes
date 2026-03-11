import 'dart:io';

import 'package:chess_exercises_notes/utils/dropbox_api_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum _SyncActionType {
  upload,
  download,
  createLocalFolder,
  createRemoteFolder,
  deleteLocal,
  deleteRemote,
}

class _SyncAction {
  final _SyncActionType type;

  /// Lowercase normalized path used for manifest and comparison.
  final String normalizedPath;

  /// Original-cased path for actual file/API operations.
  final String operationPath;
  final bool isFolder;

  _SyncAction({
    required this.type,
    required this.normalizedPath,
    required this.operationPath,
    this.isFolder = false,
  });
}

class _LocalFileInfo {
  final bool isFolder;
  final DateTime? lastModified;
  final String originalRelativePath;

  _LocalFileInfo({
    required this.isFolder,
    this.lastModified,
    required this.originalRelativePath,
  });
}

class _RemoteFileInfo {
  final bool isFolder;
  final DateTime? serverModified;
  final String? contentHash;
  final String originalRelativePath;

  _RemoteFileInfo({
    required this.isFolder,
    this.serverModified,
    this.contentHash,
    required this.originalRelativePath,
  });
}

class SyncEngine {
  final DropboxApiService _api;
  final Directory _localBooksDir;
  final Set<String> _previousManifest;
  final void Function(int total, int completed)? onProgress;

  SyncEngine({
    required DropboxApiService api,
    required Directory localBooksDir,
    required Set<String> previousManifest,
    this.onProgress,
  }) : _api = api,
       _localBooksDir = localBooksDir,
       _previousManifest = previousManifest;

  /// Run the full bidirectional sync.
  /// Returns the set of all synced paths (to be saved as the new manifest).
  Future<Set<String>> sync() async {
    final localFiles = await _scanLocalFiles();
    final remoteFiles = await _scanRemoteFiles();

    debugPrint(
      'Sync: ${localFiles.length} local entries, '
      '${remoteFiles.length} remote entries, '
      '${_previousManifest.length} manifest entries.',
    );

    // --- Asymmetry safety guards (must run before _computeActions) ---

    // Guard 1: local scan empty but remote has files + non-empty manifest.
    // This is how the original mass-remote-deletion happened: local dir
    // wasn't found → all remote files flagged as "deleted locally" → deleteRemote.
    // Abort immediately instead of risking data loss.
    if (localFiles.isEmpty &&
        remoteFiles.isNotEmpty &&
        _previousManifest.isNotEmpty) {
      debugPrint(
        'Sync ABORTED (safety): local scan returned 0 entries but remote has '
        '${remoteFiles.length} entries and manifest has '
        '${_previousManifest.length} entries. '
        'This would delete all remote files — aborting.',
      );
      throw Exception(
        'Sync safety: local scan returned 0 entries unexpectedly. '
        'Aborting to prevent remote data loss.',
      );
    }

    // Guard 2: remote scan empty but local has files + non-empty manifest.
    // Means the remote /books folder was deleted (e.g. by a previous bad sync).
    // Recover by treating this as a first-sync so all local files get uploaded
    // and nothing is deleted locally.
    final remoteRootDeleted =
        remoteFiles.isEmpty &&
        localFiles.isNotEmpty &&
        _previousManifest.isNotEmpty;
    if (remoteRootDeleted) {
      debugPrint(
        'Sync: remote /books folder appears deleted '
        '(0 remote entries, ${_previousManifest.length} manifest entries, '
        '${localFiles.length} local entries). '
        'Recovering: treating as first-sync and uploading all local files.',
      );
    }

    final actions = _computeActions(
      localFiles,
      remoteFiles,
      forceFirstSync: remoteRootDeleted,
    );

    if (actions.isEmpty) {
      debugPrint('Sync: nothing to do — local and remote are identical.');
    } else {
      _logPlannedActions(actions);
      await _executeActions(actions);
    }

    // Build the new manifest: everything that exists after sync
    return _buildPostSyncManifest(localFiles, remoteFiles, actions);
  }

  // ---------------------------------------------------------------------------
  // Local scanning
  // ---------------------------------------------------------------------------

  Future<Map<String, _LocalFileInfo>> _scanLocalFiles() async {
    final map = <String, _LocalFileInfo>{};

    if (!await _localBooksDir.exists()) return map;

    // Parent dir is the appSupportDir; relative paths start with "books/..."
    final baseDir = _localBooksDir.parent;

    // Include the books root dir itself. Dropbox list_folder('/books') returns
    // '/books' as one of the entries (tag=folder), but Dart's Directory.list()
    // only returns the *contents*, not the directory itself. Without this entry
    // the engine sees books as "present remote, absent local" → deleteRemote.
    final rootRelative = p
        .relative(_localBooksDir.path, from: baseDir.path)
        .replaceAll('\\', '/');
    map[rootRelative.toLowerCase()] = _LocalFileInfo(
      isFolder: true,
      originalRelativePath: rootRelative,
    );

    await for (final entity in _localBooksDir.list(recursive: true)) {
      final originalRelative = p
          .relative(entity.path, from: baseDir.path)
          .replaceAll('\\', '/');

      final key = originalRelative.toLowerCase();

      if (entity is File) {
        final stat = await entity.stat();
        map[key] = _LocalFileInfo(
          isFolder: false,
          lastModified: stat.modified.toUtc(),
          originalRelativePath: originalRelative,
        );
      } else if (entity is Directory) {
        map[key] = _LocalFileInfo(
          isFolder: true,
          originalRelativePath: originalRelative,
        );
      }
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // Remote scanning
  // ---------------------------------------------------------------------------

  Future<Map<String, _RemoteFileInfo>> _scanRemoteFiles() async {
    final entries = await _api.listAllFilesForSync('/books');
    final map = <String, _RemoteFileInfo>{};

    for (final entry in entries) {
      final tag = entry['.tag'] as String?;
      final pathDisplay = entry['path_display'] as String?;
      final pathLower = entry['path_lower'] as String?;
      if (pathDisplay == null) continue;

      // Use path_lower for the key (case-insensitive matching).
      // Fall back to lowercased path_display if path_lower is absent.
      final rawKey = pathLower ?? pathDisplay.toLowerCase();
      final key = rawKey.startsWith('/') ? rawKey.substring(1) : rawKey;

      final originalRelative = pathDisplay.startsWith('/')
          ? pathDisplay.substring(1)
          : pathDisplay;

      if (tag == 'file') {
        final serverModifiedStr = entry['server_modified'] as String?;
        final contentHash = entry['content_hash'] as String?;
        map[key] = _RemoteFileInfo(
          isFolder: false,
          serverModified: serverModifiedStr != null
              ? DateTime.parse(serverModifiedStr).toUtc()
              : null,
          contentHash: contentHash,
          originalRelativePath: originalRelative,
        );
      } else if (tag == 'folder') {
        map[key] = _RemoteFileInfo(
          isFolder: true,
          originalRelativePath: originalRelative,
        );
      }
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // Diff / action computation
  // ---------------------------------------------------------------------------

  List<_SyncAction> _computeActions(
    Map<String, _LocalFileInfo> local,
    Map<String, _RemoteFileInfo> remote, {
    bool forceFirstSync = false,
  }) {
    final actions = <_SyncAction>[];
    final allPaths = {...local.keys, ...remote.keys, ..._previousManifest};
    // forceFirstSync is set when remote appears to have been deleted;
    // we want to upload all local files without planning any deletions.
    final isFirstSync = _previousManifest.isEmpty || forceFirstSync;

    // The sync root folder ('books') must never be deleted — it is the anchor
    // of the whole sync tree. Deleting it would remove all content from Dropbox.
    const _syncRoot = 'books';

    for (final path in allPaths) {
      // Belt-and-suspenders: never plan a deletion of the sync root itself.
      if (path == _syncRoot) continue;

      final l = local[path];
      final r = remote[path];
      final wasInManifest = _previousManifest.contains(path);

      if (l != null && r == null) {
        if (wasInManifest && !isFirstSync) {
          // Was synced before, now gone from remote → deleted on Dropbox
          actions.add(
            _SyncAction(
              type: _SyncActionType.deleteLocal,
              normalizedPath: path,
              operationPath: l.originalRelativePath,
              isFolder: l.isFolder,
            ),
          );
        } else {
          // New local entry → push to Dropbox
          actions.add(
            _SyncAction(
              type: l.isFolder
                  ? _SyncActionType.createRemoteFolder
                  : _SyncActionType.upload,
              normalizedPath: path,
              operationPath: l.originalRelativePath,
            ),
          );
        }
      } else if (l == null && r != null) {
        if (wasInManifest && !isFirstSync) {
          // Was synced before, now gone locally → deleted locally
          actions.add(
            _SyncAction(
              type: _SyncActionType.deleteRemote,
              normalizedPath: path,
              operationPath: r.originalRelativePath,
              isFolder: r.isFolder,
            ),
          );
        } else {
          // New remote entry → pull locally
          actions.add(
            _SyncAction(
              type: r.isFolder
                  ? _SyncActionType.createLocalFolder
                  : _SyncActionType.download,
              normalizedPath: path,
              operationPath: r.originalRelativePath,
            ),
          );
        }
      } else if (l != null && r != null && !l.isFolder && !r.isFolder) {
        // Both exist as files → compare content hash then date
        final needsSync = _fileNeedsSync(l, r, path);
        if (needsSync != null) actions.add(needsSync);
      }
    }

    // --- Safety: abort if mass deletions are detected ---
    final deleteCount = actions
        .where(
          (a) =>
              a.type == _SyncActionType.deleteLocal ||
              a.type == _SyncActionType.deleteRemote,
        )
        .length;

    if (deleteCount > 0 && _previousManifest.isNotEmpty) {
      final threshold = (_previousManifest.length * 0.5).ceil().clamp(5, 9999);
      if (deleteCount > threshold) {
        debugPrint(
          'Sync ABORTED: $deleteCount deletions planned '
          '(threshold=$threshold, manifest=${_previousManifest.length}).',
        );
        throw Exception(
          'Sync safety: too many deletions ($deleteCount). '
          'Aborting to protect data.',
        );
      }
    }

    // Sort: create folders first, then files, then delete files, then delete
    // folders (deepest first so children are removed before parents).
    actions.sort((a, b) {
      final order = _actionSortOrder(a).compareTo(_actionSortOrder(b));
      if (order != 0) return order;
      // For delete actions, reverse order so deeper paths come first
      if (a.type == _SyncActionType.deleteLocal ||
          a.type == _SyncActionType.deleteRemote) {
        return b.normalizedPath.compareTo(a.normalizedPath);
      }
      return a.normalizedPath.compareTo(b.normalizedPath);
    });

    return actions;
  }

  static int _actionSortOrder(_SyncAction a) {
    switch (a.type) {
      case _SyncActionType.createLocalFolder:
      case _SyncActionType.createRemoteFolder:
        return 0;
      case _SyncActionType.upload:
      case _SyncActionType.download:
        return 1;
      case _SyncActionType.deleteLocal:
      case _SyncActionType.deleteRemote:
        return a.isFolder ? 3 : 2; // delete files before folders
    }
  }

  /// Returns an upload or download action if the file contents differ,
  /// or null if the file is already up-to-date.
  _SyncAction? _fileNeedsSync(
    _LocalFileInfo local,
    _RemoteFileInfo remote,
    String normalizedPath,
  ) {
    // If we have a remote content hash, compute local hash and compare.
    if (remote.contentHash != null) {
      final localFile = File(
        p.join(_localBooksDir.parent.path, local.originalRelativePath),
      );
      final localBytes = localFile.readAsBytesSync();
      final localHash = _computeDropboxContentHash(localBytes);

      if (localHash == remote.contentHash) return null; // identical
    }

    // Content differs — use modification dates to pick direction.
    if (local.lastModified != null && remote.serverModified != null) {
      if (local.lastModified!.isAfter(remote.serverModified!)) {
        return _SyncAction(
          type: _SyncActionType.upload,
          normalizedPath: normalizedPath,
          operationPath: local.originalRelativePath,
        );
      } else {
        return _SyncAction(
          type: _SyncActionType.download,
          normalizedPath: normalizedPath,
          operationPath: remote.originalRelativePath,
        );
      }
    }

    // Fallback: if no date info, upload local version.
    return _SyncAction(
      type: _SyncActionType.upload,
      normalizedPath: normalizedPath,
      operationPath: local.originalRelativePath,
    );
  }

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  void _logPlannedActions(List<_SyncAction> actions) {
    final counts = <_SyncActionType, int>{};
    for (final a in actions) {
      counts[a.type] = (counts[a.type] ?? 0) + 1;
    }
    debugPrint(
      'Sync plan: ${actions.length} actions — '
      '${counts.entries.map((e) => '${e.key.name}=${e.value}').join(', ')}',
    );
    for (final a in actions) {
      debugPrint(
        '  ${a.type.name}: ${a.operationPath}'
        '${a.isFolder ? " [folder]" : ""}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Action execution
  // ---------------------------------------------------------------------------

  Future<void> _executeActions(List<_SyncAction> actions) async {
    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];

      switch (action.type) {
        case _SyncActionType.upload:
          final file = File(
            p.join(_localBooksDir.parent.path, action.operationPath),
          );
          final bytes = await file.readAsBytes();
          await _api.uploadFile('/${action.operationPath}', bytes);
          debugPrint('Sync ↑ uploaded ${action.operationPath}');

        case _SyncActionType.download:
          final file = File(
            p.join(_localBooksDir.parent.path, action.operationPath),
          );
          await file.parent.create(recursive: true);
          final bytes = await _api.downloadFile('/${action.operationPath}');
          await file.writeAsBytes(bytes);
          debugPrint('Sync ↓ downloaded ${action.operationPath}');

        case _SyncActionType.createLocalFolder:
          final dir = Directory(
            p.join(_localBooksDir.parent.path, action.operationPath),
          );
          await dir.create(recursive: true);
          debugPrint('Sync 📁 created local folder ${action.operationPath}');

        case _SyncActionType.createRemoteFolder:
          await _api.createFolder('/${action.operationPath}');
          debugPrint('Sync 📁 created remote folder ${action.operationPath}');

        case _SyncActionType.deleteLocal:
          final absPath = p.join(
            _localBooksDir.parent.path,
            action.operationPath,
          );
          if (action.isFolder) {
            final dir = Directory(absPath);
            if (await dir.exists()) {
              await dir.delete(recursive: true);
            }
          } else {
            final file = File(absPath);
            if (await file.exists()) {
              await file.delete();
            }
          }
          debugPrint('Sync 🗑 deleted local ${action.operationPath}');

        case _SyncActionType.deleteRemote:
          await _api.deletePath('/${action.operationPath}');
          debugPrint('Sync 🗑 deleted remote ${action.operationPath}');
      }

      onProgress?.call(actions.length, i + 1);
    }
  }

  // ---------------------------------------------------------------------------
  // Post-sync manifest
  // ---------------------------------------------------------------------------

  /// Build the set of all paths that exist after sync (union of what remains).
  Set<String> _buildPostSyncManifest(
    Map<String, _LocalFileInfo> local,
    Map<String, _RemoteFileInfo> remote,
    List<_SyncAction> executedActions,
  ) {
    // Start from everything on both sides
    final manifest = <String>{...local.keys, ...remote.keys};

    // Remove anything that was deleted
    for (final action in executedActions) {
      if (action.type == _SyncActionType.deleteLocal ||
          action.type == _SyncActionType.deleteRemote) {
        manifest.remove(action.normalizedPath);
        // Also remove children if we deleted a folder
        if (action.isFolder) {
          manifest.removeWhere(
            (p) => p.startsWith('${action.normalizedPath}/'),
          );
        }
      }
    }

    return manifest;
  }

  // ---------------------------------------------------------------------------
  // Dropbox content hash (SHA-256 of 4 MB block hashes)
  // ---------------------------------------------------------------------------

  static String _computeDropboxContentHash(Uint8List fileBytes) {
    const blockSize = 4 * 1024 * 1024; // 4 MB
    final blockHashes = <int>[];

    if (fileBytes.isEmpty) {
      blockHashes.addAll(sha256.convert(<int>[]).bytes);
    } else {
      for (var offset = 0; offset < fileBytes.length; offset += blockSize) {
        final end = (offset + blockSize < fileBytes.length)
            ? offset + blockSize
            : fileBytes.length;
        final block = fileBytes.sublist(offset, end);
        blockHashes.addAll(sha256.convert(block).bytes);
      }
    }

    final overallHash = sha256.convert(blockHashes);
    return overallHash.toString(); // lowercase hex
  }
}
