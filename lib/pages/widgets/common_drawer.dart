import 'dart:convert';

import 'package:chess_exercises_notes/models/synchronisation_items/dropbox_account.dart';
import 'package:chess_exercises_notes/providers/dropbox_account_notifier.dart';
import 'package:chess_exercises_notes/providers/dropbox_login_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/widgets/i18n_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess_exercises_notes/providers/dark_theme_provider.dart';
import 'package:http/http.dart' as http;

class CommonDrawer extends ConsumerStatefulWidget {
  const CommonDrawer({super.key});

  @override
  ConsumerState<CommonDrawer> createState() => _ConsumerDrawerState();
}

class _ConsumerDrawerState extends ConsumerState<CommonDrawer> {
  bool _isLoggedIn = false;

  Future<void> _loginDropbox() async {
    final dropboxAccount = ref.read(dropboxAccountProvider.notifier);
    final dropboxLogin = ref.read(dropboxLoginProvider.notifier);
    if (_isLoggedIn) return;

    try {
      final accessToken = await dropboxLogin.getAccessToken();

      if (accessToken != null) {
        final response = await http.post(
          Uri.parse("https://api.dropboxapi.com/2/users/get_current_account"),
          headers: {"Authorization": "Bearer $accessToken"},
        );

        final data = jsonDecode(response.body);

        final email = data["email"];
        final accountId = data["account_id"];
        final profilePhotoUrl = data["profile_photo_url"];
        final displayName = data["name"]["display_name"];

        dropboxAccount.setAccount(
          DropboxAccount(
            displayName: displayName,
            email: email,
            accountId: accountId,
            profilePhotoUrl: profilePhotoUrl,
          ),
        );

        setState(() {
          _isLoggedIn = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_success",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error while login Dropbox account : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText("options.snack_messages.dropbox.connection_error"),
        ),
      );
    }
  }

  Future<void> _logoutDropbox() async {
    final dropboxLogin = ref.read(dropboxLoginProvider.notifier);
    if (!_isLoggedIn) return;

    try {
      await dropboxLogin.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText(
            "options.snack_messages.dropbox.disconnection_success",
          ),
        ),
      );
      setState(() {
        _isLoggedIn = false;
      });
    } catch (e) {
      debugPrint("Error while login out Dropbox account : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText(
            "options.snack_messages.dropbox.disconnection_error",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inDarkMode = ref.watch(darkThemeProvider);
    final darkModeNotifier = ref.read(darkThemeProvider.notifier);
    final dropboxAccountNotifier = ref.watch(dropboxAccountProvider.notifier);

    final dropboxAccount = dropboxAccountNotifier.getAccount();
    final accountUserName = dropboxAccount?.displayName;
    final accountAvatarUrl = dropboxAccount?.profilePhotoUrl;

    return Drawer(
      child: Column(
        spacing: 15.0,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DrawerHeader(child: I18nText("options.title")),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10.0,
            children: [
              I18nText("options.dark_mode.label"),
              Switch(
                value: inDarkMode,
                onChanged: (newValue) => darkModeNotifier.toggle(),
              ),
            ],
          ),
          if (_isLoggedIn)
            ElevatedButton(
              onPressed: _logoutDropbox,
              child: I18nText("options.dropbox.logout_button"),
            ),
          if (accountUserName != null) Text(accountUserName),
          if (accountAvatarUrl != null)
            Image.network(
              accountAvatarUrl,
              width: 50.0,
              height: 50.0,
              fit: BoxFit.cover,
            ),
          if (!_isLoggedIn)
            ElevatedButton(
              onPressed: _loginDropbox,
              child: I18nText("options.dropbox.login_button"),
            ),
        ],
      ),
    );
  }
}
