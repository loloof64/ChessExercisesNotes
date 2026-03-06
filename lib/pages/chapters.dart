import 'dart:io';

import 'package:chess_exercises_notes/models/chapter.dart';
import 'package:chess_exercises_notes/pages/grid_constants.dart';
import 'package:chess_exercises_notes/pages/widgets/chapters_page_widgets.dart';
import 'package:chess_exercises_notes/pages/widgets/common_drawer.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/pages/widgets/grid_item.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ChaptersPageWidget extends StatefulWidget {
  const ChaptersPageWidget({
    super.key,
    required this.bookFolderName,
    required this.bookTitle,
    required this.bookAuthors,
  });
  final String bookFolderName;
  final String bookTitle;
  final String? bookAuthors;

  @override
  State<ChaptersPageWidget> createState() => _ChaptersPageWidgetState();
}

class _ChaptersPageWidgetState extends State<ChaptersPageWidget> {
  bool _isLoading = false;
  List<Chapter> _chapters = [];
  final TextEditingController _newChapterNameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshFolderItems().then((value) {});
  }

  @override
  void dispose() {
    _newChapterNameController.dispose();
    super.dispose();
  }

  Future<void> _purposeAddChapter() async {
    final Chapter? chapterToCreate = await _showAddChapterDialog();
    if (chapterToCreate == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final chaptersDir = Directory(p.join(booksDir.path, widget.bookFolderName));
    await chaptersDir.create();

    final Directory newChapterFolder = Directory(
      p.join(chaptersDir.path, chapterToCreate.name),
    );
    await newChapterFolder.create();
    await chapterToCreate.serializeToFile(newChapterFolder, metadataFileName);

    await _refreshFolderItems();
  }

  Future<void> _purposeConfirmDeleteChapter({
    required String chapterFolderName,
    required String chapterName,
  }) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: I18nText(
            "pages.chapters.dialogs.remove_chapter_confirmation.title",
          ),
          content: I18nText(
            "pages.chapters.dialogs.remove_chapter_confirmation.message",
            translationParams: {"chapterName": chapterName},
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
    await _deleteChapter(chapterFolderName);
  }

  /// Shows the add chapter dialog.
  /// Return : (the new chapter) Chapter?
  Future<Chapter?> _showAddChapterDialog() async {
    return await showDialog<Chapter>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: I18nText("pages.chapters.dialogs.add_chapter.title"),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5.0,
            children: [
              Row(
                spacing: 5.0,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  I18nText("pages.chapters.dialogs.add_chapter.label_name"),
                  Expanded(
                    child: TextField(
                      controller: _newChapterNameController,
                      decoration: InputDecoration(
                        hint: I18nText(
                          "pages.chapters.dialogs.add_chapter.placeholder_name",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            CancelButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
            ),
            OkButton(
              onPressed: () async {
                final purposedNewName = _newChapterNameController.text;
                final securedFolderName = secureFolderName(purposedNewName);
                final isFolderUnique = !await _isFolderNameReserved(
                  securedFolderName,
                );

                if (!dialogContext.mounted) return;

                if (purposedNewName.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: I18nText(
                        "pages.chapters.dialogs.add_chapter.snack_errors.empty_name",
                      ),
                    ),
                  );
                  return;
                } else if (isFolderUnique) {
                  _newChapterNameController.clear();
                  final createdChapter = Chapter(
                    folderName: securedFolderName,
                    name: purposedNewName,
                  );
                  Navigator.of(dialogContext).pop(createdChapter);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: I18nText(
                        "pages.books.dialogs.snack_errors.already_used_name",
                      ),
                    ),
                  );
                  return;
                }
              },
            ),
          ],
        );
      },
    );
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

    final children = await listSubdirectoryNames(chaptersDir);
    final newChapters = <Chapter>[];

    for (final child in children) {
      final currentChapterDirectory = Directory(
        p.join(chaptersDir.path, child),
      );
      await currentChapterDirectory.create();

      final relatedChapter = await getChapterFromFile(
        currentChapterDirectory,
        metadataFileName,
      );
      newChapters.add(relatedChapter);
    }

    setState(() {
      _chapters = newChapters;
      _isLoading = false;
    });
  }

  Future<bool> _isFolderNameReserved(String folderName) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final chaptersDir = Directory(p.join(booksDir.path, widget.bookFolderName));
    await chaptersDir.create();

    final children = await listSubdirectoryNames(chaptersDir);
    return children.contains(folderName);
  }

  Future<void> _deleteChapter(String chapterFolderName) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final chaptersDir = Directory(p.join(booksDir.path, widget.bookFolderName));
    await chaptersDir.create();

    final Directory chapterFolder = Directory(
      p.join(chaptersDir.path, chapterFolderName),
    );
    if (!await chapterFolder.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText(
            "pages.chapters.dialogs.snack_errors.inexistant_chapter",
          ),
        ),
      );
      return;
    }

    await chapterFolder.create();
    await chapterFolder.delete(recursive: true);
    await _refreshFolderItems();
  }

  void _navigateIntoItem(String chapterFolderName) {
    //TODO navigate into chapter
  }

  Future<void> _purposeEditChapter({
    required String chapterFolderName,
    required Chapter relatedChapter,
  }) async {
    final Chapter? chapterToUpdate = await _showEditChapterDialog(
      chapterFolderName: chapterFolderName,
      relatedChapter: relatedChapter,
    );
    if (chapterToUpdate == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final Directory chaptersDir = Directory(
      p.join(booksDir.path, chapterFolderName),
    );
    await chaptersDir.create();

    final Directory newChapterFolder = Directory(
      p.join(chaptersDir.path, chapterToUpdate.folderName),
    );
    await newChapterFolder.create();

    await chapterToUpdate.serializeToFile(newChapterFolder, metadataFileName);
    await _refreshFolderItems();
  }

  Future<Chapter?> _showEditChapterDialog({
    required String chapterFolderName,
    required Chapter relatedChapter,
  }) async {
    _newChapterNameController.text = relatedChapter.name;
    final newBook = await showDialog<Chapter>(
      context: context,
      builder: (dialogContex) {
        return EditChapterWidget(
          isInAddMode: false,
          newChapterNameController: _newChapterNameController,
          isFolderNameReserved: _isFolderNameReserved,
        );
      },
    );
    return newBook;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.widthOf(context);
    final gridCrossAxisCount = (screenWidth / gridElementWidth).floor();

    final booksWidgets = _chapters.map((currentChapter) {
      return GridItemWidget(
        relatedItem: currentChapter.toGridItem(),
        onEditRequest: () {
          _purposeEditChapter(
            chapterFolderName: currentChapter.folderName,
            relatedChapter: currentChapter,
          );
        },
        onDeleteRequest: () {
          _purposeConfirmDeleteChapter(
            chapterFolderName: currentChapter.folderName,
            chapterName: currentChapter.name,
          );
        },
        onClickRequest: () {
          _navigateIntoItem(currentChapter.folderName);
        },
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: I18nText("pages.chapters.title"),
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
              padding: const EdgeInsets.all(20.0),
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
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: gridCrossAxisCount,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      children: booksWidgets,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: IconButton.outlined(
        color: Colors.lightGreen,
        onPressed: _purposeAddChapter,
        icon: Icon(Icons.add),
      ),
    );
  }
}
