import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveDropboxCursor(String cursor) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("dropbox_cursor", cursor);
}

Future<String?> loadDropboxCursor() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("dropbox_cursor");
}

Future<void> clearDropboxCursor() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("dropbox_cursor");
}
