import 'dart:convert';

import 'package:chess_exercises_notes/models/synchronisation_items/dropbox_oauth2_client.dart';
import 'package:flutter/material.dart';
import 'package:chess_exercises_notes/providers/dropbox_account_notifier.dart';
import 'package:chess_exercises_notes/models/synchronisation_items/dropbox_account.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:chess_exercises_notes/providers/sync_provider.dart';

part 'dropbox_login_provider.g.dart';

@Riverpod(keepAlive: true)
class DropboxLogin extends _$DropboxLogin {
  late final OAuth2Helper _helper;
  // secure storage keys
  static const _kAccessTokenKey = 'dropbox_access_token';
  static const _kRefreshTokenKey = 'dropbox_refresh_token';
  static const _kExpiresAtKey = 'dropbox_token_expires_at';

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

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

    // Try to silently restore a previous session using stored refresh token.
    await _tryRestoreSession();

    // Return current token (may be null)
    return state.asData?.value;
  }

  /// Interactive login
  Future<AccessTokenResponse?> login() async {
    final token = await _helper.getToken();

    state = AsyncValue.data(token);

    // persist tokens for future silent restore
    await _saveTokensToStorage(token);

    // fetch and populate DropboxAccount for UI
    try {
      final access = token?.accessToken;
      if (access != null) await _fetchAndSetAccount(access);
      // trigger a sync after interactive login
      if (access != null) {
        try {
          await ref.read(syncProvider.notifier).sync();
        } catch (e) {
          debugPrint('Background sync after interactive login failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch Dropbox account after login: $e');
    }

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

    // also clear our secure storage copy
    await _clearStoredTokens();

    // clear stored account as well
    try {
      ref.read(dropboxAccountProvider.notifier).clear();
    } catch (_) {}

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

  // --- Silent restore helpers ---
  Future<void> _tryRestoreSession() async {
    try {
      // indicate loading so UI can show a spinner
      state = const AsyncValue.loading();

      final refresh = await _secureStorage.read(key: _kRefreshTokenKey);
      debugPrint('Silent restore: refresh token present=${refresh != null}');
      if (refresh == null) {
        // nothing to restore
        state = const AsyncValue.data(null);
        return;
      }

      final success = await _refreshWithRefreshToken(refresh);
      if (!success) {
        await _clearStoredTokens();
        state = const AsyncValue.data(null);
      }

      // If silent restore succeeded, start a non-blocking background sync.
      // We intentionally do not await this so app startup isn't delayed.
      // The sync provider/engine already has safety guards (manifest,
      // deletion thresholds) to avoid destructive operations on first-run.
      if (success) {
        ref.read(syncProvider.notifier).sync().then((_) {
          debugPrint('Background sync after silent restore completed');
        }).catchError((e) {
          debugPrint('Background sync after silent restore failed: $e');
        });
      }
    } catch (e) {
      debugPrint('Silent session restore failed: $e');
      await _clearStoredTokens();
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> _refreshWithRefreshToken(String refreshToken) async {
    final uri = Uri.parse('https://api.dropboxapi.com/oauth2/token');
    final response = await http.post(
      uri,
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': 'oja5n3i5ibq4mdp',
      },
    );
    debugPrint(
      'Dropbox refresh response status=${response.statusCode} body=${response.body}',
    );
    if (response.statusCode != 200) {
      debugPrint(
        'Dropbox refresh token request failed: ${response.statusCode}',
      );
      return false;
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final access = json['access_token'] as String?;
    final refresh = json['refresh_token'] as String?;
    final expiresIn = (json['expires_in'] as num?)?.toInt();

    debugPrint(
      'Parsed refresh response: access_present=${access != null} refresh_present=${refresh != null} expiresIn=$expiresIn',
    );

    if (access == null) return false;

    final tokenMap = <String, dynamic>{'access_token': access};
    if (refresh != null) tokenMap['refresh_token'] = refresh;
    if (expiresIn != null) tokenMap['expires_in'] = expiresIn;
    debugPrint('Constructed tokenMap for AccessTokenResponse: $tokenMap');

    try {
      final tokenResp = AccessTokenResponse.fromMap(tokenMap);
      debugPrint(
        'AccessTokenResponse created: access=${tokenResp.accessToken} refresh=${tokenResp.refreshToken} expiresIn=${tokenResp.expiresIn}',
      );
      state = AsyncValue.data(tokenResp);
      await _saveTokensToStorage(tokenResp);

      // populate DropboxAccount for UI
      final access = tokenResp.accessToken;
      if (access != null) {
        try {
          await _fetchAndSetAccount(access);
        } catch (e) {
          debugPrint(
            'Failed to fetch Dropbox account during silent restore: $e',
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Failed to construct AccessTokenResponse from refresh: $e');
      return false;
    }
  }

  Future<void> _saveTokensToStorage(AccessTokenResponse? token) async {
    if (token == null) return;
    if (token.accessToken != null) {
      await _secureStorage.write(
        key: _kAccessTokenKey,
        value: token.accessToken,
      );
    }
    if (token.refreshToken != null) {
      await _secureStorage.write(
        key: _kRefreshTokenKey,
        value: token.refreshToken,
      );
    }
    if (token.expiresIn != null) {
      final expiresAt = DateTime.now()
          .toUtc()
          .add(Duration(seconds: token.expiresIn!))
          .toIso8601String();
      await _secureStorage.write(key: _kExpiresAtKey, value: expiresAt);
    }
  }

  Future<void> _clearStoredTokens() async {
    await _secureStorage.delete(key: _kAccessTokenKey);
    await _secureStorage.delete(key: _kRefreshTokenKey);
    await _secureStorage.delete(key: _kExpiresAtKey);
  }

  Future<void> _fetchAndSetAccount(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/2/users/get_current_account'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      debugPrint(
        'get_current_account response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Failed to fetch Dropbox account: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final Map<String, dynamic>? data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      if (data == null) return;

      final accountId = data['account_id'] as String?;
      if (accountId == null) return;

      final email = data['email'] as String?;
      final nameObj = data['name'] as Map<String, dynamic>?;
      final displayName = nameObj != null
          ? (nameObj['display_name'] as String? ?? email ?? 'Dropbox user')
          : (email ?? 'Dropbox user');
      final profilePhotoUrl = data['profile_photo_url'] as String?;

      final account = DropboxAccount(
        displayName: displayName,
        email: email ?? 'Dropbox user',
        accountId: accountId,
        profilePhotoUrl: profilePhotoUrl,
      );

      debugPrint(
        'Setting DropboxAccount displayName=${account.displayName} email=${account.email} accountId=${account.accountId}',
      );
      ref.read(dropboxAccountProvider.notifier).setAccount(account);
    } catch (e) {
      debugPrint('Error while fetching Dropbox account: $e');
    }
  }
}
