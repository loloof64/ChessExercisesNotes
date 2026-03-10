import 'dart:io';

import 'package:chess_exercises_notes/models/local_items/book.dart';
import 'package:chess_exercises_notes/pages/chapters.dart';
import 'package:chess_exercises_notes/pages/grid_constants.dart';
import 'package:chess_exercises_notes/pages/widgets/books_page_widgets.dart';
import 'package:chess_exercises_notes/pages/widgets/common_drawer.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/pages/widgets/grid_item.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const maxAuthorsCountPerBook = 5;

class BooksPageWidget extends ConsumerStatefulWidget {
  const BooksPageWidget({super.key});

  @override
  ConsumerState<BooksPageWidget> createState() => _BooksPageWidgetState();
}

class _BooksPageWidgetState extends ConsumerState<BooksPageWidget> {
  bool _isLoading = false;
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

  Future<Book?> _showEditBookDialog({
    required String bookFolderName,
    required Book relatedBook,
  }) async {
    _newBookNameController.text = relatedBook.title;
    for (var i = 0; i < relatedBook.authors.length; i++) {
      _newBookAuthorsControllers[i].text = relatedBook.authors[i];
    }
    final newBook = await showDialog<Book>(
      context: context,
      builder: (dialogContex) {
        return EditBookWidget(
          isInAddMode: false,
          newBookNameController: _newBookNameController,
          newBookAuthorsControllers: _newBookAuthorsControllers,
          isFolderNameReserved: _isFolderNameReserved,
        );
      },
    );
    return newBook;
  }

  Future<void> _purposeEditBook({
    required String bookFolderName,
    required Book relatedBook,
  }) async {
    final Book? bookToUpdate = await _showEditBookDialog(
      bookFolderName: bookFolderName,
      relatedBook: relatedBook,
    );
    if (bookToUpdate == null) return;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory booksDir = Directory(
      p.join(appSupportDir.path, booksRootFolderName),
    );
    await booksDir.create();

    final Directory newBookFolder = Directory(
      p.join(booksDir.path, bookToUpdate.folderName),
    );
    await newBookFolder.create();
    await bookToUpdate.serializeToFile(newBookFolder, metadataFileName);

    await _refreshFolderItems();
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
        return EditBookWidget(
          isInAddMode: true,
          newBookNameController: _newBookNameController,
          newBookAuthorsControllers: _newBookAuthorsControllers,
          isFolderNameReserved: _isFolderNameReserved,
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
    required String? bookAuthors,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) {
          return ChaptersPageWidget(
            bookFolderName: bookFolderName,
            bookTitle: bookTitle,
            bookAuthors: bookAuthors,
          );
        },
      ),
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
      _isLoading = false;
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
      final currentBookAuthors = currentBook.authors.isEmpty
          ? null
          : currentBook.authors.join(", ");
      return GridItemWidget(
        relatedItem: currentBook.toGridItem(),
        onEditRequest: () {
          _purposeEditBook(
            bookFolderName: currentBook.folderName,
            relatedBook: currentBook,
          );
        },
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
            bookAuthors: currentBookAuthors,
          );
        },
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: I18nText("pages.books.title"),
        actions: [
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
