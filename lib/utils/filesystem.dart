import 'dart:io';
import 'package:path/path.dart' as p;

Future<List<String>> listSubdirectoryNames(Directory dir) async {
  final names = <String>[];

  await for (final entity in dir.list()) {
    if (entity is Directory) {
      names.add(p.basename(entity.path));
    }
  }

  names.sort();
  return names;
}
