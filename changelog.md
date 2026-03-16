# v0.1.24

- feat: replace floatting buttons with action buttons in the three pages
- fix : make edit answer dialog scrollable

# v0.1.23

- fix: elements cards text are centered horizontally
- fix: add a retry strategy for network operations

# v0.1.22

- fix android build

# v0.1.21

- fix dropbox connection issue in android apk

# v0.1.20

- remove AppBundle artifact

# v0.1.19

- fix android build workflow

# v0.1.18

- fix android build workflow

# v0.1.17

- fix android build workflow

# v0.1.16

- remove MSIX build
- setup keystore for Android build

# v0.1.15

- fix Wayland crash with AppImage (remove libepoxy)

# v0.1.14

- fix Wayland crash with AppImage

# v0.1.13

- fix AppImage crash on Fedora (EGL platform extensions missing) : exclude EGL/GL/Mesa libs from bundle so Impeller uses the host system's graphics stack

# v0.1.12

- fix Wayland issue with AppImage format

# v0.1.11

- upgrade gh action dependency setup-java
- add missing dependencies for Deb/Rpm/AppImage formats

# v0.1.10

- fix windows build error

# v0.1.9

- fix in workflow : forces the use of NodeJS 24
- fix windows build error

# v0.1.8

- fix in workflow : forces the use of NodeJS 24
- fix windows zip and exe artifacts : add missing DLL files

# v0.1.7

- fix Windows MSIX build (incorrect flag msix-version)

# v0.1.6

- change the flutter builder package in workflows
- fix Windows MSIX build

# v0.1.5

- fix windows NSIX build by removing interactive prompt from NSIX builder package

# v0.1.4

- fix windows MSIX building by correcting the application identity name
- force NodeJS to version 24

# v0.1.3

Add missing

- system dependencies for Linux build
- set MSIX tool as dev dependency instead of global for Windows build

# v0.1.2

Fix github workflow (attempt 2)

# v0.1.1

Fix github workflow

# v0.1.0

First release version

- you can create books references, chapters references and answers files locally
- you can connect into your dropbox account
- you can synchronize elements between your local filesystem and your dropbox account
