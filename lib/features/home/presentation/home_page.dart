
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/theme/app_theme.dart';
import 'package:kpss_tekrar_takibi/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.hello),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final current = ref.read(themeModeProvider);
                    ref.read(themeModeProvider.notifier).state = switch (current) {
                      ThemeMode.system => ThemeMode.light,
                      ThemeMode.light => ThemeMode.dark,
                      ThemeMode.dark => ThemeMode.system,
                    };
                  },
                  child: const Text('Theme'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final current = ref.read(localeProvider);
                    ref.read(localeProvider.notifier).state =
                    (current?.languageCode == 'tr') ? const Locale('en') : const Locale('tr');
                  },
                  child: const Text('TR/EN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}