import 'package:chess_exercises_notes/models/local_items/answer.dart';
import 'package:chess_exercises_notes/pages/answers.dart';
import 'package:chess_exercises_notes/pages/widgets/dialog_buttons.dart';
import 'package:chess_exercises_notes/utils/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';

class EditAnswerWidget extends StatelessWidget {
  final bool isInAddMode;
  final String originalFileName;
  final TextEditingController newAnswerNameController;
  final TextEditingController newAnswerContentController;
  final Future<bool> Function(String fileName) isFileNameReserved;

  const EditAnswerWidget({
    super.key,
    required this.isInAddMode,
    required this.originalFileName,
    required this.newAnswerNameController,
    required this.newAnswerContentController,
    required this.isFileNameReserved,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: isInAddMode
          ? I18nText("pages.answers.dialogs.add_answer.title")
          : I18nText(
              "pages.answers.dialogs.edit_answer.title",
              translationParams: {"answerName": originalFileName},
            ),
      content: SingleChildScrollView(
        child: Column(
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
                I18nText("pages.answers.dialogs.add_answer.label_name"),
                Expanded(
                  child: TextField(
                    controller: newAnswerNameController,
                    decoration: InputDecoration(
                      hint: I18nText(
                        "pages.answers.dialogs.add_answer.placeholder_name",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 5.0,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                I18nText("pages.answers.dialogs.add_answer.label_content"),
                Expanded(
                  child: TextField(
                    controller: newAnswerContentController,
                    minLines: 5,
                    maxLines: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        CancelButton(
          onPressed: () {
            newAnswerNameController.clear();
            newAnswerContentController.clear();
            Navigator.of(context).pop(null);
          },
        ),
        OkButton(
          onPressed: () async {
            final purposedNewName = newAnswerNameController.text;
            final purposedNewContent = newAnswerContentController.text;
            final securedAnswerName = secureFileItemName(purposedNewName);
            final usedNewName = "$securedAnswerName.txt";
            final isFileUnique = !await isFileNameReserved(usedNewName);

            if (!context.mounted) return;

            // Do not test on usedNewName !
            if (purposedNewName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: I18nText(
                    "pages.answers.dialogs.add_chapter.snack_errors.empty_name",
                  ),
                ),
              );
              return;
            }
            // If we changed the name, it should remain unique
            else if (!isInAddMode &&
                (purposedNewName != originalFileName) &&
                !isFileUnique) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: I18nText(
                    "pages.answers.dialogs.snack_errors.already_used_name",
                  ),
                ),
              );
              return;
            }
            /* If in edit mode, we don't to check for uniqueness */
            else if (!isInAddMode || isFileUnique) {
              final createdAnswer = AnswerData(
                Answer(title: purposedNewName, content: purposedNewContent),
                usedNewName,
              );
              newAnswerNameController.clear();
              newAnswerContentController.clear();
              Navigator.of(context).pop(createdAnswer);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: I18nText(
                    "pages.answers.dialogs.snack_errors.already_used_name",
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
