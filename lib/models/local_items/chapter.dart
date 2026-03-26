import 'dart:io';

import 'package:chess_exercises_notes/pages/widgets/grid_item.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;

class Chapter {
  final String relatedBookFolderName;
  final String chapterFolderName;
  final String name;

  Chapter({
    required this.relatedBookFolderName,
    required this.chapterFolderName,
    required this.name,
  });

  Future<void> serializeToFile(Directory baseDirectory, String fileName) async {
    final path = Directory(p.join(baseDirectory.path, fileName)).path;
    final editor = YamlEditor('{}');
    editor.update(["name"], name);
    editor.update(["bookFolderName"], relatedBookFolderName);

    final yamlText = editor.toString();
    final file = File(path);
    await file.create();
    await file.writeAsString(yamlText);
  }

  GridItem toGridItem() {
    return GridItem(name: name, authors: null);
  }
}

Future<Chapter> getChapterFromFile(
  Directory baseDirectory,
  String fileName,
) async {
  final path = Directory(p.join(baseDirectory.path, fileName)).path;
  final file = File(path);

  final content = await file.readAsString();
  final editor = YamlEditor(content);
  final chapterFolderName = baseDirectory.path
      .split(Platform.pathSeparator)
      .last;
  final name = editor.parseAt(["name"]).value as String;
  final bookFolderName = editor.parseAt(["bookFolderName"]).value as String;

  return Chapter(
    relatedBookFolderName: bookFolderName,
    chapterFolderName: chapterFolderName,
    name: name,
  );
}
