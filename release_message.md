# Release

## ⚠️ Android: you must reinstall the app

For security reasons, the key used to sign the Android app has been replaced.
Android cannot install this version over the previous one.

1. In the installed app, synchronize with Dropbox.
2. Check in Dropbox that your data is there. **Uninstalling the app deletes its local data.**
3. Uninstall the app.
4. Install the new APK, then sign in to Dropbox again and synchronize.

Only download the APK from this repository's GitHub releases page.

This does not apply to the Linux and Windows versions.

## Changes

- Books, chapters and answers pages now refresh automatically after a synchronization
- Fixed possible crashes of the books and chapters pages while folders were not fully downloaded
- Fixed empty files being uploaded again on every synchronization
- Security: Dropbox tokens and account data are no longer written to the logs
- Upgraded to Flutter 3.50
