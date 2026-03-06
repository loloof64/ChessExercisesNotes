import 'dart:io';

import 'package:chess_exercises_notes/pages/widgets/grid_item.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;

class Chapter {
  final String folderName;
  final String name;

  Chapter({required this.folderName, required this.name});

  Future<void> serializeToFile(Directory baseDirectory, String fileName) async {
    final path = Directory(p.join(baseDirectory.path, fileName)).path;
    final editor = YamlEditor('{}');
    editor.update(["name"], name);

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
  final folderName = baseDirectory.path.split(Platform.pathSeparator).last;
  final name = editor.parseAt(["name"]).value as String;

  return Chapter(folderName: folderName, name: name);
}
