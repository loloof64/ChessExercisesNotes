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

  @override
  void initState() {
    super.initState();
    _checkLogged();
  }

  Future<void> _checkLogged() async {
    final tokenState = ref.read(dropboxLoginProvider);
    final token = tokenState.asData?.value;
    final logged = token?.accessToken != null;
    if (!mounted) return;
    setState(() => _isLoggedIn = logged);
  }

  Future<void> _loginDropbox() async {
    final dropboxAccount = ref.read(dropboxAccountProvider.notifier);
    final dropboxLogin = ref.read(dropboxLoginProvider.notifier);
    if (_isLoggedIn) return;

    try {
      final tokenResponse = await dropboxLogin.login(); // interactive login
      final accessToken = tokenResponse?.accessToken;

      if (accessToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_error",
            ),
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse("https://api.dropboxapi.com/2/users/get_current_account"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      // Handle invalid token: revoke local tokens and ask user to re-login
      if (response.statusCode == 401) {
        debugPrint(
          'Dropbox API returned 401 — token invalid. Revoking local tokens.',
        );
        await dropboxLogin.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_error",
            ),
          ),
        );
        return;
      }

      if (response.statusCode != 200) {
        debugPrint(
          "Dropbox get_current_account failed: ${response.statusCode} ${response.body}",
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_error",
            ),
          ),
        );
        return;
      }

      final Map<String, dynamic>? data = (response.body.isNotEmpty)
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      if (data == null) {
        debugPrint(
          "Dropbox get_current_account returned empty or invalid JSON: ${response.body}",
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_error",
            ),
          ),
        );
        return;
      }

      final accountId = data['account_id'] as String?;
      if (accountId == null || accountId.isEmpty) {
        debugPrint("Dropbox response missing account_id: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_error",
            ),
          ),
        );
        return;
      }

      final email = data['email'] as String?;
      if (email == null || email.isEmpty) {
        debugPrint("Dropbox response missing email: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: I18nText(
              "options.snack_messages.dropbox.connection_error",
            ),
          ),
        );
        return;
      }

      final nameObj = data['name'] as Map<String, dynamic>?;
      final displayName = nameObj != null
          ? (nameObj['display_name'] as String? ?? email)
          : email;
      final profilePhotoUrl = data['profile_photo_url'] as String?;

      dropboxAccount.setAccount(
        DropboxAccount(
          displayName: displayName,
          email: email,
          accountId: accountId,
          profilePhotoUrl: profilePhotoUrl,
        ),
      );

      setState(() => _isLoggedIn = true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText(
            "options.snack_messages.dropbox.connection_success",
          ),
        ),
      );
    } catch (e, st) {
      debugPrint("Error while login Dropbox account : $e\n$st");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: I18nText("options.snack_messages.dropbox.connection_error"),
        ),
      );
    }
  }

  Future<void> _logoutDropbox() async {
    final dropboxAccount = ref.read(dropboxAccountProvider.notifier);
    final dropboxLogin = ref.read(dropboxLoginProvider.notifier);
    if (!_isLoggedIn) return;

    try {
      await dropboxLogin.logout();
      dropboxAccount.clear();
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
