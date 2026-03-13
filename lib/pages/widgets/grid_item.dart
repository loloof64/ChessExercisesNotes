import 'package:chess_exercises_notes/pages/grid_constants.dart';
import 'package:flutter/material.dart';

class GridItem {
  final String name;
  final List<String>? authors;

  GridItem({required this.name, required this.authors});
}

class GridItemWidget extends StatelessWidget {
  const GridItemWidget({
    super.key,
    required this.relatedItem,
    required this.onEditRequest,
    required this.onDeleteRequest,
    required this.onClickRequest,
  });
  final GridItem relatedItem;
  final void Function() onEditRequest;
  final void Function() onDeleteRequest;
  final void Function() onClickRequest;

  @override
  Widget build(BuildContext context) {
    final authors = relatedItem.authors?.join("\n");

    return InkWell(
      onTap: onClickRequest,
      child: Container(
        width: bookWidth,
        height: bookHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
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
              Center(
                child: Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      relatedItem.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight(700),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (authors != null && authors.isNotEmpty)
                      Text(
                        authors,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
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
                        onPressed: onEditRequest,
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
                        onPressed: onDeleteRequest,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
