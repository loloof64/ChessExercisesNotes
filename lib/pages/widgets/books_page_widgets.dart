import 'package:chess_exercises_notes/models/book.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';

class EditBookWidget extends StatelessWidget {
  final bool isInAddMode;
  final TextEditingController newBookNameController;
  final List<TextEditingController> newBookAuthorsControllers;
  final Future<bool> Function(String folderName) isFolderNameReserved;

  const EditBookWidget({
    super.key,
    required this.isInAddMode,
    required this.newBookNameController,
    required this.newBookAuthorsControllers,
    required this.isFolderNameReserved,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText(
        isInAddMode
            ? "pages.books.dialogs.add_book.title"
            : "pages.books.dialogs.edit_book.title",
      ),
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
                  controller: newBookNameController,
                  decoration: InputDecoration(
                    hint: I18nText(
                      "pages.books.dialogs.add_book.placeholder_name",
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (var line = 0; line < newBookAuthorsControllers.length; line++)
            Row(
              spacing: 5.0,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                I18nText("pages.books.dialogs.add_book.label_author"),
                Expanded(
                  child: TextField(
                    controller: newBookAuthorsControllers[line],
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
            newBookNameController.clear();
            for (final controller in newBookAuthorsControllers) {
              controller.clear();
            }
            Navigator.of(context).pop(null);
          },
        ),
        OkButton(
          onPressed: () async {
            final purposedNewName = newBookNameController.text;
            final securedFolderName = secureFileItemName(purposedNewName);
            final isFolderUnique = !await isFolderNameReserved(
              securedFolderName,
            );
            final authors = <String>[];

            for (final controller in newBookAuthorsControllers) {
              if (controller.text.isNotEmpty) {
                authors.add(controller.text);
              }
            }

            if (!context.mounted) return;

            if (purposedNewName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: I18nText(
                    "pages.books.dialogs.snack_errors.empty_name",
                  ),
                ),
              );
              return;
            }
            /* If in edit mode, we don't to check for uniqueness */
            else if (!isInAddMode || isFolderUnique) {
              newBookNameController.clear();
              for (final controller in newBookAuthorsControllers) {
                controller.clear();
              }
              final createdBook = Book(
                folderName: securedFolderName,
                title: purposedNewName,
                authors: authors,
              );
              Navigator.of(context).pop(createdBook);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
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
  }
}
