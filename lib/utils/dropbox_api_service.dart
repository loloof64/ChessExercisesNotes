import 'dart:convert';
import 'dart:io';
import 'package:chess_exercises_notes/utils/dropbox_cursor_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Simple service wrapper around Dropbox REST API
class DropboxApiService {
  final String accessToken;

  DropboxApiService(this.accessToken);

  /// Retries [fn] up to [maxAttempts] times on transient TLS/socket errors.
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } on HandshakeException catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        debugPrint('HandshakeException (attempt $attempt), retrying… $e');
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } on SocketException catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        debugPrint('SocketException (attempt $attempt), retrying… $e');
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  Future<List<dynamic>> listAllFiles(String path) async {
    final entries = <dynamic>[];

    var cursor = await loadDropboxCursor();

    Map<String, dynamic> response;

    if (cursor == null) {
      response = await _listFolder(path);
    } else {
      response = await _listFolderContinue(cursor);
    }

    entries.addAll(response["entries"]);

    cursor = response["cursor"];
    var hasMore = response["has_more"];

    while (hasMore) {
      response = await _listFolderContinue(cursor!);

      entries.addAll(response["entries"]);
      cursor = response["cursor"];
      hasMore = response["has_more"];
    }

    // Save cursor only when the full sync succeeded
    if (cursor != null) {
      await saveDropboxCursor(cursor);
    }

    return entries;
  }

  Future<Map<String, dynamic>> _listFolder(String path) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://api.dropboxapi.com/2/files/list_folder"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "path": path,
          "recursive": true,
          "include_deleted": true,
          "include_non_downloadable_files": false,
        }),
      ),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> _listFolderContinue(String cursor) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://api.dropboxapi.com/2/files/list_folder/continue"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"cursor": cursor}),
      ),
    );

    return jsonDecode(response.body);
  }

  /// Upload a file
  Future<void> uploadFile(String dropboxPath, List<int> bytes) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://content.dropboxapi.com/2/files/upload"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Dropbox-API-Arg": jsonEncode({
            "path": dropboxPath,
            "mode": "overwrite",
            "autorename": false,
          }),
          "Content-Type": "application/octet-stream",
        },
        body: bytes,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Dropbox upload error: ${response.body}");
    }
  }

  /// Download a file
  Future<List<int>> downloadFile(String dropboxPath) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://content.dropboxapi.com/2/files/download"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Dropbox-API-Arg": jsonEncode({"path": dropboxPath}),
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Dropbox download error: ${response.body}");
    }

    return response.bodyBytes;
  }

  /// List all files without using the stored cursor (full scan for sync).
  /// Does not include deleted entries.
  Future<List<dynamic>> listAllFilesForSync(String path) async {
    final entries = <dynamic>[];

    final response = await _listFolderForSync(path);
    entries.addAll(response["entries"] as List? ?? []);

    var cursor = response["cursor"] as String?;
    var hasMore = response["has_more"] as bool? ?? false;

    while (hasMore && cursor != null) {
      final cont = await _listFolderContinue(cursor);
      entries.addAll(cont["entries"] as List? ?? []);
      cursor = cont["cursor"] as String?;
      hasMore = cont["has_more"] as bool? ?? false;
    }

    return entries;
  }

  Future<Map<String, dynamic>> _listFolderForSync(String path) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://api.dropboxapi.com/2/files/list_folder"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "path": path,
          "recursive": true,
          "include_deleted": false,
          "include_non_downloadable_files": false,
        }),
      ),
    );

    if (response.statusCode == 409) {
      // path/not_found — folder doesn't exist yet on Dropbox (or was deleted)
      debugPrint(
        'Dropbox list_folder: /books not found (409) — remote folder missing.',
      );
      return {"entries": [], "has_more": false};
    }

    if (response.statusCode != 200) {
      debugPrint(
        'Dropbox list_folder error: status=${response.statusCode} body=${response.body}',
      );
      throw Exception("Dropbox list_folder error: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  /// Create a folder on Dropbox. Ignores "already exists" errors.
  Future<void> createFolder(String dropboxPath) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://api.dropboxapi.com/2/files/create_folder_v2"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"path": dropboxPath, "autorename": false}),
      ),
    );

    if (response.statusCode == 200) return;

    // 409 with path/conflict means folder already exists — that's fine
    if (response.statusCode == 409) return;

    throw Exception("Dropbox create_folder error: ${response.body}");
  }

  /// Delete a file or folder on Dropbox.
  Future<void> deletePath(String dropboxPath) async {
    final response = await _withRetry(
      () => http.post(
        Uri.parse("https://api.dropboxapi.com/2/files/delete_v2"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"path": dropboxPath}),
      ),
    );

    if (response.statusCode == 200) return;

    // 409 path_lookup/not_found — already deleted, that's fine
    if (response.statusCode == 409) return;

    throw Exception("Dropbox delete error: ${response.body}");
  }
}
