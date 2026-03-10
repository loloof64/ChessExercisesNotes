import 'dart:io';

import 'package:chess_exercises_notes/pages/widgets/grid_item.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;

class Book {
  final String folderName;
  final String title;
  List<String> authors;

  Book({required this.folderName, required this.title, required this.authors});

  Future<void> serializeToFile(Directory baseDirectory, String fileName) async {
    final path = Directory(p.join(baseDirectory.path, fileName)).path;
    final editor = YamlEditor('{}');
    editor.update(["title"], title);
    editor.update(["authors"], authors);

    final yamlText = editor.toString();
    final file = File(path);
    await file.create();
    await file.writeAsString(yamlText);
  }

  GridItem toGridItem() {
    return GridItem(name: title, authors: authors);
  }
}

Future<Book> getBookFromFile(Directory baseDirectory, String fileName) async {
  final path = Directory(p.join(baseDirectory.path, fileName)).path;
  final file = File(path);

  final content = await file.readAsString();
  final editor = YamlEditor(content);
  final folderName = baseDirectory.path.split(Platform.pathSeparator).last;
  final title = editor.parseAt(["title"]).value as String;
  final authors = List<String>.from(editor.parseAt(["authors"]).value);

  return Book(folderName: folderName, title: title, authors: authors);
}
