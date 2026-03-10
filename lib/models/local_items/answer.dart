import 'dart:io';
import 'package:path/path.dart' as p;

class Answer {
  Answer({required this.title, required this.content});

  final String title;
  final String content;

  Future<void> serializeToFile(Directory baseDirectory, String fileName) async {
    final path = Directory(p.join(baseDirectory.path, fileName)).path;
    final file = File(path);

    await file.create();
    await file.writeAsString(content, flush: true);
  }
}
