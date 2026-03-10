import 'dart:io';

import 'package:chess_exercises_notes/models/local_items/answer.dart';
import 'package:chess_exercises_notes/pages/widgets/answers_page_widget.dart';
import 'package:chess_exercises_notes/pages/widgets/common_drawer.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AnswerData {
  final Answer answer;
  final String fileName;

  AnswerData(this.answer, this.fileName);
}

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
  List<AnswerData> _answers = <AnswerData>[];
  bool _isLoading = false;
  final TextEditingController _newAnswerNameController =
      TextEditingController();
  final TextEditingController _newAnswerContentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshFolderItems().then((value) {});
  }

  @override
  void dispose() {
    _newAnswerContentController.dispose();
    _newAnswerNameController.dispose();
    super.dispose();
  }

  Future<void> _purposeAddAnswer() async {
    final AnswerData? answerToCreate = await _showAddAnswerDialog();
    if (answerToCreate == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final chaptersDir = Directory(p.join(booksDir.path, widget.bookFolderName));
    await chaptersDir.create();

    final Directory exercisesFolder = Directory(
      p.join(chaptersDir.path, widget.chapterFolderName),
    );
    await exercisesFolder.create();

    await answerToCreate.answer.serializeToFile(
      exercisesFolder,
      answerToCreate.fileName,
    );

    await _refreshFolderItems();
  }

  /// Shows the add answer dialog.
  /// Return : (the new answer data) AnswerData?
  Future<AnswerData?> _showAddAnswerDialog() async {
    return await showDialog<AnswerData>(
      context: context,
      builder: (dialogContext) {
        return EditAnswerWidget(
          isInAddMode: true,
          originalFileName: "",
          newAnswerNameController: _newAnswerNameController,
          newAnswerContentController: _newAnswerContentController,
          isFileNameReserved: _isFileNameReserved,
        );
      },
    );
  }

  Future<bool> _isFileNameReserved(String fileName) async {
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
    await exercisesDir.create();

    final children = await listFilesNames(exercisesDir);
    return children.contains(fileName);
  }

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
    final newAnswers = <AnswerData>[];

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
        final rawAnswer = Answer(title: simpleName, content: fileContent);
        newAnswers.add(AnswerData(rawAnswer, childName));
      }
    }
    newAnswers.sort((fst, snd) {
      return fst.answer.title.compareTo(snd.answer.title);
    });

    setState(() {
      _answers = newAnswers;
      _isLoading = false;
    });
  }

  Future<void> _purposeEditAnswer({
    required AnswerData relatedAnswerData,
  }) async {
    final AnswerData? answerToUpdate = await _showEditAnswerDialog(
      relatedAnswerData: relatedAnswerData,
    );
    if (answerToUpdate == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final Directory chaptersDir = Directory(
      p.join(booksDir.path, widget.bookFolderName),
    );
    await chaptersDir.create();

    final Directory chapterFolder = Directory(
      p.join(chaptersDir.path, widget.chapterFolderName),
    );
    await chapterFolder.create();

    // rename file if necessary
    if (relatedAnswerData.fileName != answerToUpdate.fileName) {
      File oldFile = File(
        p.join(chapterFolder.path, relatedAnswerData.fileName),
      );
      await oldFile.rename(p.join(chapterFolder.path, answerToUpdate.fileName));
    }

    await answerToUpdate.answer.serializeToFile(
      chapterFolder,
      answerToUpdate.fileName,
    );
    await _refreshFolderItems();
  }

  Future<AnswerData?> _showEditAnswerDialog({
    required AnswerData relatedAnswerData,
  }) async {
    _newAnswerNameController.text = relatedAnswerData.answer.title;
    _newAnswerContentController.text = relatedAnswerData.answer.content;
    final newBook = await showDialog<AnswerData>(
      context: context,
      builder: (dialogContex) {
        return EditAnswerWidget(
          isInAddMode: false,
          originalFileName: _newAnswerNameController.text,
          newAnswerNameController: _newAnswerNameController,
          newAnswerContentController: _newAnswerContentController,
          isFileNameReserved: _isFileNameReserved,
        );
      },
    );
    return newBook;
  }

  Future<void> _purposeConfirmDeleteAnswer({
    required AnswerData relatedAnswerData,
  }) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: I18nText(
            "pages.answers.dialogs.remove_answer_confirmation.title",
          ),
          content: I18nText(
            "pages.answers.dialogs.remove_answer_confirmation.message",
            translationParams: {"answerName": relatedAnswerData.answer.title},
          ),
          actions: [
            CancelButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            OkButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (confirmation != true) return;
    await _deleteAnswer(relatedAnswerData);
  }

  Future<void> _deleteAnswer(AnswerData relatedAnswerData) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final chaptersDir = Directory(p.join(booksDir.path, widget.bookFolderName));
    await chaptersDir.create();

    final Directory chapterFolder = Directory(
      p.join(chaptersDir.path, widget.chapterFolderName),
    );
    await chapterFolder.create();

    final File answerFile = File(
      p.join(chapterFolder.path, relatedAnswerData.fileName),
    );

    if (!await answerFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText(
            "pages.answers.dialogs.snack_errors.inexistant_answer",
          ),
        ),
      );
      return;
    }

    await answerFile.create();
    await answerFile.delete();
    await _refreshFolderItems();
  }

  @override
  Widget build(BuildContext context) {
    final answerTitles = _answers
        .map((current) => current.answer.title)
        .toList();

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
      drawer: CommonDrawer(),
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
                      itemBuilder: (itemContext, index) => Row(
                        spacing: 4.0,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              answerTitles[index],
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton.outlined(
                            onPressed: () {
                              final relatedAnswerData = _answers[index];
                              _purposeEditAnswer(
                                relatedAnswerData: relatedAnswerData,
                              );
                            },
                            style: ButtonStyle(
                              side: WidgetStateProperty.all(
                                BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            icon: Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton.outlined(
                            onPressed: () {
                              final relatedAnswerData = _answers[index];
                              _purposeConfirmDeleteAnswer(
                                relatedAnswerData: relatedAnswerData,
                              );
                            },
                            style: ButtonStyle(
                              side: WidgetStateProperty.all(
                                BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                      separatorBuilder: (itemContext, index) => const Divider(),
                      itemCount: _answers.length,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: IconButton.outlined(
        color: Colors.lightGreen,
        onPressed: _purposeAddAnswer,
        icon: Icon(Icons.add),
      ),
    );
  }
}
