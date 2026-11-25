import 'dart:io';
import 'package:diacritic/diacritic.dart';
import 'package:path/path.dart' as p;

const booksRootFolderName = "books";
const metadataFileName = "metadata.yaml";

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

Future<List<String>> listFilesNames(Directory dir) async {
  final names = <String>[];

  await for (final entity in dir.list()) {
    if (entity is File) {
      names.add(p.basename(entity.path));
    }
  }

  names.sort();
  return names;
}

/// A file item name without special characters
/// replacing accent letters with simple letters
String secureFileItemName(String originalName) {
  final withoutDiacritics = removeDiacritics(originalName);
  return withoutDiacritics
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(' ', '_');
}

/// Names of the book or chapter folders which can be displayed. A sync creates
/// folders before downloading their files, so some may lack metadata for now.
Future<List<String>> listItemFolderNames(Directory dir) async {
  final names = <String>[];

  for (final name in await listSubdirectoryNames(dir)) {
    if (await File(p.join(dir.path, name, metadataFileName)).exists()) {
      names.add(name);
    }
  }

  return names;
}
