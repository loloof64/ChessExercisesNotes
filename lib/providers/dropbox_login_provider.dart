import 'dart:convert';

import 'package:chess_exercises_notes/models/synchronisation_items/dropbox_oauth2_client.dart';
import 'package:flutter/material.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

part 'dropbox_login_provider.g.dart';

@Riverpod(keepAlive: true)
class DropboxLogin extends _$DropboxLogin {
  late final OAuth2Helper _helper;

  @override
  Future<AccessTokenResponse?> build() async {
    final client = DropboxOAuth2Client();
    _helper = OAuth2Helper(
      client,
      clientId: "oja5n3i5ibq4mdp",
      scopes: [
        'files.metadata.read',
        'files.content.read',
        'files.content.write',
        'account_info.read',
      ],
      enablePKCE: true,
      grantType: OAuth2Helper.authorizationCode,
      authCodeParams: {'token_access_type': 'offline'},
      webAuthOpts: {'useWebview': false},
    );

    // Do NOT login automatically
    return null;
  }

  /// Interactive login
  Future<AccessTokenResponse?> login() async {
    final token = await _helper.getToken();

    state = AsyncValue.data(token);

    return token;
  }

  /// Returns valid access token (auto refresh if needed)
  Future<String?> getAccessToken() async {
    final token = await _helper.getToken();

    state = AsyncValue.data(token);

    return token?.accessToken;
  }

  /// Logout
  Future<void> logout() async {
    final token = state.asData?.value;

    if (token?.accessToken != null) {
      try {
        await _revokeDropboxToken(token!.accessToken!);
      } catch (e) {
        // If token is already invalid/revoked on Dropbox, ignore and continue
        // We still want to remove local tokens and clear state.
        // Log for diagnostics.
        // ignore: avoid_print
        debugPrint('Ignoring error while revoking Dropbox token: $e');
      }
    }

    // remove tokens stored by oauth2_client to force a fresh interactive flow
    await _helper.removeAllTokens();

    state = const AsyncValue.data(null);
  }

  /// Revoke token on Dropbox
  Future<void> _revokeDropboxToken(String accessToken) async {
    final uri = Uri.parse("https://api.dropboxapi.com/2/auth/token/revoke");

    final response = await http.post(
      uri,
      headers: {"Authorization": "Bearer $accessToken"},
    );

    if (response.statusCode == 200) return;

    // If token is invalid at Dropbox side, treat as already revoked and return.
    if (response.statusCode == 401) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final error = body?['error'] as Map<String, dynamic>?;
        final tag = error?['.tag'] as String?;
        if (tag == 'invalid_access_token') {
          debugPrint('Dropbox revoke: token already invalid: ${response.body}');
          return;
        }
      } catch (e) {
        debugPrint('Failed to parse Dropbox revoke error body: $e');
        // fallthrough to throw below
      }
    }

    throw Exception("Failed to revoke Dropbox token: ${response.body}");
  }

  /// Returns true if there is a valid access token
  Future<bool> isLoggedIn() async {
    try {
      // Try to get a token (will auto-refresh if needed)
      final token = await _helper.getToken();

      // If token exists and not expired
      return token?.accessToken != null;
    } catch (_) {
      return false;
    }
  }
}
