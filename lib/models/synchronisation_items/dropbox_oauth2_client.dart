import 'dart:io';
import 'package:oauth2_client/oauth2_client.dart';

final isDesktop =
    Platform.isWindows ||
    Platform.isMacOS ||
    Platform.isLinux ||
    Platform.isFuchsia;

final redirectUri = isDesktop
    ? 'http://localhost:53682/oauth2redirect'
    : 'https://chess-exercises-notes-website.vercel.app/oauth2redirect';

final callbackUrlScheme = isDesktop
    ? 'http://localhost:53682'
    : 'chess-exercises-notes';

/// OAuth2 client configuration for Dropbox, handling desktop and mobile/web.
class DropboxOAuth2Client extends OAuth2Client {
  DropboxOAuth2Client()
    : super(
        authorizeUrl: 'https://www.dropbox.com/oauth2/authorize',
        tokenUrl: 'https://api.dropboxapi.com/oauth2/token',
        redirectUri: redirectUri,
        customUriScheme: callbackUrlScheme,
      );
}
