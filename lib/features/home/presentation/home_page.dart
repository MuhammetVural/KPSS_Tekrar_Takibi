import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/theme/app_theme.dart';
import 'package:kpss_tekrar_takibi/features/home/application/selected_subject_provider.dart';
import 'package:kpss_tekrar_takibi/features/topics/application/topics_controller.dart';
import 'package:kpss_tekrar_takibi/l10n/app_localizations.dart';

@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  bool _isDue(DateTime now, int? nextReviewAt) {
    if (nextReviewAt == null) return false;
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    return !next.isAfter(now); // <= now
  }

  bool _isToday(DateTime now, int? nextReviewAt) {
    if (nextReviewAt == null) return false;
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(next.year, next.month, next.day);
    return a == b;
  }

  bool _isOverdue(DateTime now, int? nextReviewAt) {
    if (nextReviewAt == null) return false;
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    return next.isBefore(now);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final nowAsync = ref.watch(nowTickProvider);
    final startedAsync = ref.watch(startedHomeTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: 'Theme',
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state = switch (current) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
            },
            icon: const Icon(Icons.brightness_6),
          ),
          IconButton(
            tooltip: 'TR/EN',
            onPressed: () {
              final current = ref.read(localeProvider);
              ref.read(localeProvider.notifier).state =
              (current?.languageCode == 'tr')
                  ? const Locale('en')
                  : const Locale('tr');
            },
            icon: const Icon(Icons.language),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: nowAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Saat akışı hatası: $e')),
        data: (now) {
          return startedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Başlatılan konular okunamadı: $e')),
            data: (items) {
              final startedCount = items.length;

              final due = items.where((x) => _isDue(now, x.topic.nextReviewAt)).toList();
              final overdue = items.where((x) => _isOverdue(now, x.topic.nextReviewAt)).toList();
              final today = items.where((x) => _isToday(now, x.topic.nextReviewAt)).toList();

              final upcoming = [...items]
                ..sort((a, b) {
                  final an = a.topic.nextReviewAt;
                  final bn = b.topic.nextReviewAt;
                  if (an == null && bn == null) {
                    return a.topic.title.compareTo(b.topic.title);
                  }
                  if (an == null) return 1;
                  if (bn == null) return -1;
                  return an.compareTo(bn);
                });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChipInfo(label: 'Başlatılan', value: startedCount.toString()),
                        ChipInfo(label: 'Bugün', value: today.length.toString()),
                        ChipInfo(label: 'Gecikmiş', value: overdue.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (startedCount == 0) ...[
                      const Text('Henüz başlatılmış konu yok.'),
                      const SizedBox(height: 8),
                      Text(
                        'Bir konuyu başlatınca burada geri sayım ve sıradaki tekrarlar görünecek.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      Text('Bugünkü tekrarlar', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),

                      if (due.isEmpty)
                        Text('Şu an vadesi gelen tekrar yok.', style: Theme.of(context).textTheme.bodySmall)
                      else
                        _HomeTopicList(now: now, items: due),

                      const SizedBox(height: 18),

                      Text('Sıradaki tekrarlar', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _HomeTopicList(
                        now: now,
                        items: upcoming.take(12).toList(growable: false),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeTopicList extends StatelessWidget {
  final DateTime now;
  final List<HomeTopicItem> items;

  const _HomeTopicList({
    required this.now,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
      itemBuilder: (ctx, i) {
        final x = items[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(x.topic.title),
          subtitle: Text(x.subjectName),
          trailing: CountdownWithRemaining(
            now: now,
            intervalIndex: x.topic.intervalIndex,
            lastReviewedAt: x.topic.lastReviewedAt,
            nextReviewAt: x.topic.nextReviewAt,
          ),
        );
      },
    );
  }
}