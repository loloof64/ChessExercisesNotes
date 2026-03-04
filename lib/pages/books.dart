import 'package:chess_exercises_notes/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

final gridElementWidth = 200;
final bookWidth = 150.0;
final bookHeight = 400.0;

class BooksPageWidget extends StatefulWidget {
  const BooksPageWidget({super.key});

  @override
  State<BooksPageWidget> createState() => _BooksPageWidgetState();
}

class _BooksPageWidgetState extends State<BooksPageWidget> {
  final List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.widthOf(context);
    final gridCrossAxisCount = (screenWidth / gridElementWidth).floor();

    final booksWidgets = _books.map((currentBook) {
      return BookWidget(relatedBook: currentBook);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: I18nText("pages.books.title")),
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
        onPressed: () {},
        icon: Icon(Icons.add),
      ),
    );
  }
}

class BookWidget extends StatelessWidget {
  const BookWidget({super.key, required this.relatedBook});
  final Book relatedBook;

  @override
  Widget build(BuildContext context) {
    final authors = relatedBook.authors.join("\n");

    return Container(
      width: bookWidth,
      height: bookHeight,
      decoration: BoxDecoration(border: BoxBorder.all(width: 1.0)),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight(700)),
                ),
                if (authors.isNotEmpty)
                  Text(
                    authors,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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
                      onPressed: () {},
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
