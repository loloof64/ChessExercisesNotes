import 'dart:io';

import 'package:chess_exercises_notes/models/answer.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AnswerPageWidget extends StatefulWidget {
  const AnswerPageWidget({
    super.key,
    required this.bookFolderName,
    required this.chapterFolderName,
    required this.bookTitle,
    required this.bookAuthors,
    required this.chapterName,
  });
  final String bookFolderName;
  final String chapterFolderName;
  final String bookTitle;
  final String? bookAuthors;
  final String chapterName;

  @override
  State<AnswerPageWidget> createState() => _AnswerPageWidgetState();
}

class _AnswerPageWidgetState extends State<AnswerPageWidget> {
  List<Answer> _answers = <Answer>[];
  bool _isLoading = false;

  Future<void> _refreshFolderItems() async {
    setState(() {
      _isLoading = true;
    });
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final chaptersDir = Directory(p.join(booksDir.path, widget.bookFolderName));
    await chaptersDir.create();

    final exercisesDir = Directory(
      p.join(chaptersDir.path, widget.chapterFolderName),
    );

    final childrenFiles = await exercisesDir
        .list()
        .where((elt) => elt is File)
        .toList();
    final newAnswers = <Answer>[];

    for (final child in childrenFiles) {
      final childName = child.path.split(Platform.pathSeparator).last;
      if (childName == metadataFileName) {
        continue;
      }
      var simpleNameList = childName.split(".");
      simpleNameList.removeLast();
      final simpleName = simpleNameList.join(".");
      if (child is File) {
        final fileContent = await child.readAsString();
        newAnswers.add(Answer(title: simpleName, content: fileContent));
      }
    }

    setState(() {
      _answers = newAnswers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final answerTitles = _answers.map((current) => current.title).toList();

    return Scaffold(
      appBar: AppBar(
        title: I18nText("pages.answers.title"),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          IconButton(onPressed: _refreshFolderItems, icon: Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                spacing: 4,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Text(
                            widget.bookTitle,
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.bookAuthors != null)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.shade200,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            child: Text(
                              widget.bookAuthors!,
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Text(
                            widget.chapterName,
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemBuilder: (itemContext, index) => Text(
                        answerTitles[index],
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      separatorBuilder: (itemContext, index) => const Divider(),
                      itemCount: _answers.length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
