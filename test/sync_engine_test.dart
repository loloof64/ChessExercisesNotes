import 'dart:typed_data';

import 'package:chess_exercises_notes/utils/sync_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dropbox content hash', () {
    test('empty file has no block: SHA-256 of nothing', () {
      expect(
        SyncEngine.computeDropboxContentHash(Uint8List(0)),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('non-empty file: SHA-256 of the block digests', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(
        SyncEngine.computeDropboxContentHash(bytes),
        sha256.convert(sha256.convert(bytes).bytes).toString(),
      );
    });
  });
}
