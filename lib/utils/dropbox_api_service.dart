import 'dart:convert';
import 'package:chess_exercises_notes/utils/dropbox_cursor_service.dart';
import 'package:http/http.dart' as http;

/// Simple service wrapper around Dropbox REST API
class DropboxApiService {
  final String accessToken;

  DropboxApiService(this.accessToken);

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
    final response = await http.post(
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
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> _listFolderContinue(String cursor) async {
    final response = await http.post(
      Uri.parse("https://api.dropboxapi.com/2/files/list_folder/continue"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"cursor": cursor}),
    );

    return jsonDecode(response.body);
  }

  /// Upload a file
  Future<void> uploadFile(String dropboxPath, List<int> bytes) async {
    final response = await http.post(
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
    );

    if (response.statusCode != 200) {
      throw Exception("Dropbox upload error: ${response.body}");
    }
  }

  /// Download a file
  Future<List<int>> downloadFile(String dropboxPath) async {
    final response = await http.post(
      Uri.parse("https://content.dropboxapi.com/2/files/download"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Dropbox-API-Arg": jsonEncode({"path": dropboxPath}),
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Dropbox download error: ${response.body}");
    }

    return response.bodyBytes;
  }
}
