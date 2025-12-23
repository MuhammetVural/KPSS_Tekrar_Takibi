import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kpss_tekrar_takibi/app/router/app_router.dart';
import 'package:kpss_tekrar_takibi/core/theme/app_theme.dart';
import 'package:kpss_tekrar_takibi/l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KPSS Tekrar Takibi',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      routerConfig: _router.config(),
    );
  }
}
