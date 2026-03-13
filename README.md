# chess_exercises_notes

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

### Riverpod files generation

```bash
dart run build_runner watch -d
```

## Credits

### Images

- logo has been taken from [SVG Repo](https://www.svgrepo.com/svg/281590/notes-notepad)
