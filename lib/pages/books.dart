import 'dart:io';

import 'package:chess_exercises_notes/models/book.dart';
import 'package:chess_exercises_notes/pages/widgets/common_drawer.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final gridElementWidth = 200;
final bookWidth = 150.0;
final bookHeight = 400.0;

class BooksPageWidget extends StatefulWidget {
  const BooksPageWidget({super.key});

  @override
  State<BooksPageWidget> createState() => _BooksPageWidgetState();
}

class _BooksPageWidgetState extends State<BooksPageWidget> {
  List<Book> _books = [];
  final TextEditingController _newBookNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _refreshFolderItems().then((value) {});
  }

  @override
  void dispose() {
    _newBookNameController.dispose();
    super.dispose();
  }

  Future<void> _purposeAddBook() async {
    final bookName = await _showAddBookDialog();
    if (bookName == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(p.join(appSupportDir.path, "books"));
    await booksDir.create();

    final Directory newBookFolder = Directory(p.join(booksDir.path, bookName));
    await newBookFolder.create();

    //TODO add metadata yaml inside folder

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
  /// Return : (the new book name) String?
  Future<String?> _showAddBookDialog() async {
    return await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: I18nText("pages.books.dialogs.add_book.title"),
          content: Row(
            spacing: 5.0,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              I18nText("pages.books.dialogs.add_book.label_name"),
              Expanded(
                child: TextField(
                  controller: _newBookNameController,
                  decoration: InputDecoration(
                    hint: I18nText("pages.books.dialogs.add_book.placeholder"),
                  ),
                ),
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
                final isUnique = !await _isFolderNameReserved(purposedNewName);
                if (!dialogContext.mounted) return;

                if (purposedNewName.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: I18nText(
                        "pages.books.dialogs.add_book.snack_errors.empty_name",
                      ),
                    ),
                  );
                  return;
                } else if (isUnique) {
                  Navigator.of(dialogContext).pop(purposedNewName);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: I18nText(
                        "pages.books.dialogs.add_book.snack_errors.already_used_name",
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
    final Directory booksDir = Directory(p.join(appSupportDir.path, "books"));
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

  Future<void> _refreshFolderItems() async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(p.join(appSupportDir.path, "books"));
    await booksDir.create();

    final children = await listSubdirectoryNames(booksDir);
    final newBooks = <Book>[];
    for (final child in children) {
      //TODO read authors from book yaml
      newBooks.add(Book(folderName: child, title: child, authors: <String>[]));
    }

    setState(() {
      _books = newBooks;
    });
  }

  Future<bool> _isFolderNameReserved(String folderName) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(p.join(appSupportDir.path, "books"));
    await booksDir.create();
    final children = await listSubdirectoryNames(booksDir);

    return children.contains(folderName);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.widthOf(context);
    final gridCrossAxisCount = (screenWidth / gridElementWidth).floor();

    final booksWidgets = _books.map((currentBook) {
      return BookWidget(
        relatedBook: currentBook,
        onDeleteRequest: () {
          //TODO get book title from metadata yaml file
          _purposeConfirmDeleteBook(
            bookFolderName: currentBook.folderName,
            bookTitle: currentBook.folderName,
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

class BookWidget extends StatelessWidget {
  const BookWidget({
    super.key,
    required this.relatedBook,
    required this.onDeleteRequest,
  });
  final Book relatedBook;
  final void Function() onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final authors = relatedBook.authors.join("\n");

    return Container(
      width: bookWidth,
      height: bookHeight,
      decoration: BoxDecoration(
        border: BoxBorder.all(
          width: 1.0,
          color: Theme.of(context).colorScheme.primary,
        ),
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Stack(
          children: [
            Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  relatedBook.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight(700),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (authors.isNotEmpty)
                  Text(
                    authors,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      onPressed: () {},
                      icon: Icon(Icons.edit, color: Colors.blue),
                    ),
                    IconButton.outlined(
                      onPressed: onDeleteRequest,
                      icon: Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
