# chess_exercises_notes

[![build_releases](https://github.com/loloof64/ChessExercisesNotes/actions/workflows/main.yml/badge.svg?branch=releases)](https://github.com/loloof64/ChessExercisesNotes/actions/workflows/main.yml)

Synchronize your chess exercises books answers across your devices :

- you can create books references, chapters references and answers files locally
- you can connect into your dropbox account
- you can synchronize elements between your local filesystem and your dropbox account

## Special installation notes

### Fedora users

You may experience issues running the AppImage file, in which case I just suggest you to install the rpm file instead.

### Ubuntu users

In order to install the deb file, you may want to activate the universe repository

```bash
sudo add-apt-repository universe
```

then

```bash
sudo apt install ./chess_exercises_notes-vx.x.x.deb
```

where you replace x.x.x with the package version.

Also, if you can't manage to run the AppImage, I suggest you to install the deb file instead.

## For developpers

### Android signing keystore

The release APK/AAB must be signed with a personal keystore. This keystore and its credentials file (`key.properties`) are **never committed to git**.

**1. Generate the keystore**

Generate keystore from terminal and set it in folder `android/app`
(replace relevant parts accordingly)

```
keytool -genkeypair -v \
  -keystore android/app/production-release.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 11000
```

**2. Create `android/key.properties`** with the following content (replace values accordingly):

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=<key-alias>
storeFile=<keystore-name.jks>
```

Both `android/key.properties` and `android/app/<keystore-name>.jks` are already listed in `android/.gitignore` and will not be published.

**3. GitHub Actions secrets**

The CI workflow reconstructs the keystore and `key.properties` from repository secrets. Add the following secrets in **GitHub → Settings → Secrets and variables → Actions**:

| Secret name               | Value                                                                  |
| ------------------------- | ---------------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore (`base64 -w0 android/app/<keystore-name>.jks`) |
| `ANDROID_STORE_PASSWORD`  | Store password                                                         |
| `ANDROID_KEY_PASSWORD`    | Key password                                                           |
| `ANDROID_KEY_ALIAS`       | Key alias                                                              |

Generate the base64 value with:

```bash
base64 -w0 android/app/<keystore-name>.jks
```

### Riverpod files generation

```bash
dart run build_runner watch -d
```

## Credits

### Images

- logo has been taken from [SVG Repo](https://www.svgrepo.com/svg/281590/notes-notepad)
