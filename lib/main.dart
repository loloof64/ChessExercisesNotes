import 'dart:io';

import 'package:chess_exercises_notes/pages/books.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/yaml_decode_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  final isDesktop =
      Platform.isWindows ||
      Platform.isMacOS ||
      Platform.isLinux ||
      Platform.isFuchsia;
  final home = isDesktop ? const AppDesktop() : const AppMobile();
  if (isDesktop) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: "Chess exercises notes",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
  runApp(home);
}

class AppMobile extends StatelessWidget {
  const AppMobile({super.key});

  @override
  Widget build(BuildContext context) => MainApp();
}

class AppDesktop extends StatefulWidget {
  const AppDesktop({super.key});

  @override
  State<StatefulWidget> createState() => _AppDesktopState();
}

class _AppDesktopState extends State<AppDesktop> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainApp();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chess exercises notes",
      theme: FlexThemeData.light(scheme: FlexScheme.greenM3),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.blueWhale),
      home: BooksPageWidget(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: 'assets/i18n',
            useCountryCode: false,
            fallbackFile: 'en',
            decodeStrategies: [YamlDecodeStrategy()],
          ),
          missingTranslationHandler: (key, locale) {
            Logger().w(
              "--- Missing Key: $key, languageCode: ${locale?.languageCode}",
            );
          },
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
      ],
    );
  }
}
