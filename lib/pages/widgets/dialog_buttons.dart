import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class OkButton extends StatelessWidget {
  final void Function() onPressed;
  const OkButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
        child: I18nText("buttons.ok"),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final void Function() onPressed;
  const CancelButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        child: I18nText("buttons.cancel"),
      ),
    );
  }
}
