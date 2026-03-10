import 'package:chess_exercises_notes/models/local_items/chapter.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';

class EditChapterWidget extends StatelessWidget {
  final bool isInAddMode;
  final TextEditingController newChapterNameController;
  final Future<bool> Function(String folderName) isFolderNameReserved;

  const EditChapterWidget({
    super.key,
    required this.isInAddMode,
    required this.newChapterNameController,
    required this.isFolderNameReserved,
  });

  @override
  Widget build(BuildContext context) {
    final originalName = newChapterNameController.text;
    return AlertDialog(
      title: isInAddMode
          ? I18nText("pages.chapters.dialogs.add_chapter.title")
          : I18nText(
              "pages.chapters.dialogs.edit_chapter.title",
              translationParams: {"chapterName": originalName},
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
              I18nText("pages.chapters.dialogs.add_chapter.label_name"),
              Expanded(
                child: TextField(
                  controller: newChapterNameController,
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
            newChapterNameController.clear();
            Navigator.of(context).pop(null);
          },
        ),
        OkButton(
          onPressed: () async {
            final purposedNewName = newChapterNameController.text;
            final securedFolderName = secureFileItemName(purposedNewName);
            final isFolderUnique = !await isFolderNameReserved(
              securedFolderName,
            );

            if (!context.mounted) return;

            if (purposedNewName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: I18nText(
                    "pages.chapters.dialogs.add_chapter.snack_errors.empty_name",
                  ),
                ),
              );
              return;
            }
            /* If in edit mode, we don't to check for uniqueness */
            else if (!isInAddMode || isFolderUnique) {
              newChapterNameController.clear();
              final createdChapter = Chapter(
                chapterFolderName: securedFolderName,
                name: purposedNewName,
              );
              Navigator.of(context).pop(createdChapter);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: I18nText(
                    "pages.chapters.dialogs.snack_errors.already_used_name",
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
