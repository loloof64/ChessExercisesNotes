import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Persists a JSON manifest of all synced paths after each successful sync.
/// Used to detect deletions: if a path was in the last manifest but is now
/// absent from local or remote, it means it was deleted on that side.
class SyncManifestService {
  static const _manifestFileName = '.sync_manifest.json';

  final Directory _appSupportDir;

  SyncManifestService({required Directory appSupportDir})
    : _appSupportDir = appSupportDir;

  File get _manifestFile =>
      File(p.join(_appSupportDir.path, _manifestFileName));

  /// Load the set of relative paths from the last successful sync.
  /// Returns an empty set if no manifest exists yet (first sync).
  Future<Set<String>> load() async {
    final file = _manifestFile;
    if (!await file.exists()) return {};

    try {
      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (e) {
      debugPrint('Failed to read sync manifest: $e');
      return {};
    }
  }

  /// Save the current set of synced paths after a successful sync.
  Future<void> save(Set<String> paths) async {
    final file = _manifestFile;
    final json = jsonEncode(paths.toList()..sort());
    await file.writeAsString(json, flush: true);
  }

  /// Clear the manifest (e.g. on logout).
  Future<void> clear() async {
    final file = _manifestFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
