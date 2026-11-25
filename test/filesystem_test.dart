import 'dart:io';

import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('item folders without metadata yet are skipped', () async {
    final root = await Directory.systemTemp.createTemp('items');
    addTearDown(() => root.delete(recursive: true));
    await File(
      p.join(root.path, 'complete', metadataFileName),
    ).create(recursive: true);
    // Sync creates folders first: this one is still waiting for its metadata.
    await Directory(p.join(root.path, 'pending')).create();

    expect(await listItemFolderNames(root), ['complete']);
  });
}
