import 'dart:io';

import 'package:chess_exercises_notes/models/book.dart';
import 'package:chess_exercises_notes/pages/chapters.dart';
import 'package:chess_exercises_notes/pages/grid_constants.dart';
import 'package:chess_exercises_notes/pages/widgets/common_drawer.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/pages/widgets/grid_item.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const maxAuthorsCountPerBook = 5;

class BooksPageWidget extends StatefulWidget {
  const BooksPageWidget({super.key});

  @override
  State<BooksPageWidget> createState() => _BooksPageWidgetState();
}

class _BooksPageWidgetState extends State<BooksPageWidget> {
  List<Book> _books = [];
  final TextEditingController _newBookNameController = TextEditingController();
  final List<TextEditingController> _newBookAuthorsControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _refreshFolderItems().then((value) {});
  }

  @override
  void dispose() {
    _newBookNameController.dispose();
    for (final controller in _newBookAuthorsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _purposeAddBook() async {
    final Book? bookToCreate = await _showAddBookDialog();
    if (bookToCreate == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final Directory newBookFolder = Directory(
      p.join(booksDir.path, bookToCreate.folderName),
    );
    await newBookFolder.create();
    await bookToCreate.serializeToFile(newBookFolder, metadataFileName);

    await _refreshFolderItems();
  }

  Future<void> _purposeConfirmDeleteBook({
    required String bookFolderName,
    required String bookTitle,
  }) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: I18nText("pages.books.dialogs.remove_book_confirmation.title"),
          content: I18nText(
            "pages.books.dialogs.remove_book_confirmation.message",
            translationParams: {"bookName": bookTitle},
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
    await _deleteBook(bookFolderName);
  }

  /// Shows the add book dialog.
  /// Return : (the new book) Book?
  Future<Book?> _showAddBookDialog() async {
    return await showDialog<Book?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: I18nText("pages.books.dialogs.add_book.title"),
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
                  I18nText("pages.books.dialogs.add_book.label_name"),
                  Expanded(
                    child: TextField(
                      controller: _newBookNameController,
                      decoration: InputDecoration(
                        hint: I18nText(
                          "pages.books.dialogs.add_book.placeholder_name",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              for (
                var line = 0;
                line < _newBookAuthorsControllers.length;
                line++
              )
                Row(
                  spacing: 5.0,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    I18nText("pages.books.dialogs.add_book.label_author"),
                    Expanded(
                      child: TextField(
                        controller: _newBookAuthorsControllers[line],
                        decoration: InputDecoration(
                          hint: I18nText(
                            "pages.books.dialogs.add_book.placeholder_author",
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
                final purposedNewName = _newBookNameController.text;
                final securedFolderName = secureFolderName(purposedNewName);
                final isFolderUnique = !await _isFolderNameReserved(
                  securedFolderName,
                );
                final authors = <String>[];

                for (final controller in _newBookAuthorsControllers) {
                  if (controller.text.isNotEmpty) {
                    authors.add(controller.text);
                  }
                }

                if (!dialogContext.mounted) return;

                if (purposedNewName.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: I18nText(
                        "pages.books.dialogs.snack_errors.empty_name",
                      ),
                    ),
                  );
                  return;
                } else if (isFolderUnique) {
                  _newBookNameController.clear();
                  for (final controller in _newBookAuthorsControllers) {
                    controller.clear();
                  }
                  final createdBook = Book(
                    folderName: securedFolderName,
                    title: purposedNewName,
                    authors: authors,
                  );
                  Navigator.of(dialogContext).pop(createdBook);
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

  Future<void> _deleteBook(String bookFolderName) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final Directory bookFolder = Directory(
      p.join(booksDir.path, bookFolderName),
    );
    if (!await bookFolder.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText(
            "pages.books.dialogs.add_book.snack_errors.inexistant_book",
          ),
        ),
      );
      return;
    }

    await bookFolder.create();
    await bookFolder.delete(recursive: true);
    await _refreshFolderItems();
  }

  void _navigateIntoItem({
    required String bookFolderName,
    required String bookTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) {
          return ChaptersWidget(
            bookFolderName: bookFolderName,
            bookTitle: bookTitle,
          );
        },
      ),
    );
  }

  Future<void> _refreshFolderItems() async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final children = await listSubdirectoryNames(booksDir);
    final newBooks = <Book>[];
    for (final child in children) {
      final currentBookDirectory = Directory(p.join(booksDir.path, child));
      await currentBookDirectory.create();

      final relatedBook = await getBookFromFile(
        currentBookDirectory,
        metadataFileName,
      );
      newBooks.add(relatedBook);
    }

    setState(() {
      _books = newBooks;
    });
  }

  Future<bool> _isFolderNameReserved(String folderName) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();
    final children = await listSubdirectoryNames(booksDir);

    return children.contains(folderName);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.widthOf(context);
    final gridCrossAxisCount = (screenWidth / gridElementWidth).floor();

    final booksWidgets = _books.map((currentBook) {
      return GridItemWidget(
        relatedItem: currentBook.toGridItem(),
        onDeleteRequest: () {
          _purposeConfirmDeleteBook(
            bookFolderName: currentBook.folderName,
            bookTitle: currentBook.title,
          );
        },
        onClickRequest: () {
          _navigateIntoItem(
            bookFolderName: currentBook.folderName,
            bookTitle: currentBook.title,
          );
        },
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(title: I18nText("pages.books.title")),
      drawer: CommonDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: gridCrossAxisCount,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          children: booksWidgets,
        ),
      ),
      floatingActionButton: IconButton.outlined(
        color: Colors.lightGreen,
        onPressed: _purposeAddBook,
        icon: Icon(Icons.add),
      ),
    );
  }
}
