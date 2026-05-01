import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  /// Global notifier so any widget (e.g. Settings) can change the theme at runtime.
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);
      
  /// Global notifier for currency toggle. "LKR" (default) or "USD".
  static final ValueNotifier<String> currencyNotifier =
      ValueNotifier('LKR');

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    App.themeNotifier.addListener(_onThemeChanged);
    App.currencyNotifier.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    App.themeNotifier.removeListener(_onThemeChanged);
    App.currencyNotifier.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});
  
  void _onCurrencyChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: App.themeNotifier.value,
      routerConfig: AppRouter.router,
    );
  }
}
