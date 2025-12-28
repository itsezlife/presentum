import 'package:app_ui/app_ui.dart';
import 'package:example/src/app/router/router_state_mixin.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> with RouterStateMixin {
  late final ThemeData _theme;
  late final ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _theme = const AppTheme().theme;
    _darkTheme = const AppDarkTheme().theme;
  }

  final Key builderKey = GlobalKey(); // Disable recreate widget tree

  @override
  Widget build(BuildContext context) {
    const themeMode = ThemeMode.system;

    return MaterialApp.router(
      title: 'Presentum: Example',
      debugShowCheckedModeBanner: !Config.environment.isProduction,

      // Router
      routerConfig: router.config,

      // Localizations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: defaultLocale,

      // Theme
      theme: _theme,
      themeMode: themeMode,
      darkTheme: _darkTheme,

      // Builder
      builder: (context, child) => MediaQuery(
        key: builderKey,
        data: context.mediaQuery.copyWith(
          platformBrightness: themeMode == ThemeMode.system
              ? SchedulerBinding.instance.platformDispatcher.platformBrightness
              : themeMode == ThemeMode.light
              ? Brightness.light
              : Brightness.dark,
          textScaler: TextScaler.linear(
            context.textScaleFactor(maxTextScaleFactor: 1.1),
          ),
        ),
        child: child!,
      ),
    );
  }
}
