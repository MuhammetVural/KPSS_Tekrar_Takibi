import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kpss_tekrar_takibi/features/topics/application/topics_controller.dart';
import 'package:kpss_tekrar_takibi/app/router/app_router.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';
import 'package:kpss_tekrar_takibi/features/topics/domain/review_intervals.dart';

/// subjectId + parentTopicId kombinasyonu ile (ana/alt) listeleri çekmek için.
class TopicsArgs {
  final String subjectId;
  final String? parentTopicId;

  const TopicsArgs({
    required this.subjectId,
    required this.parentTopicId,
  });

  @override
  bool operator ==(Object other) {
    return other is TopicsArgs &&
        other.subjectId == subjectId &&
        other.parentTopicId == parentTopicId;
  }

  @override
  int get hashCode => Object.hash(subjectId, parentTopicId);
}

/// parentTopicId == null => ANA konular
/// parentTopicId dolu => sadece o parent'ın ALT konuları
final topicsProvider = FutureProvider.family<List<Topic>, TopicsArgs>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);

  final q = db.select(db.topics)
    ..where((t) {
      final base = t.subjectId.equals(args.subjectId) & t.archived.equals(false);
      if (args.parentTopicId == null) {
        return base & t.parentTopicId.isNull();
      }
      return base & t.parentTopicId.equals(args.parentTopicId!);
    })
    ..orderBy([
          (t) => drift.OrderingTerm.desc(t.questionCount),
          (t) => drift.OrderingTerm.asc(t.title),
    ]);

  return q.get();
});

/// Subject içindeki tüm alt konuları çekip parentId bazında sayar.
/// (Ana konu kartında "Alt konular (n)" göstermek için.)
final subtopicCountsProvider = FutureProvider.family<Map<String, int>, String>((ref, subjectId) async {
  final db = ref.watch(appDatabaseProvider);

  final rows = await (db.select(db.topics)
    ..where((t) =>
    t.subjectId.equals(subjectId) &
    t.archived.equals(false) &
    t.parentTopicId.isNotNull()))
      .get();

  final map = <String, int>{};
  for (final r in rows) {
    final pid = r.parentTopicId;
    if (pid == null) continue;
    map[pid] = (map[pid] ?? 0) + 1;
  }
  return map;
});

/// Ana konular sayfasında: hangi ana konuların kartı genişletilmiş?
final expandedParentsProvider = StateProvider<Set<String>>((ref) => <String>{});
final nowTickerProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

@RoutePage()
class TopicsPage extends ConsumerWidget {
  final String subjectId;
  final String subjectName;

  /// null => ana konular
  /// dolu => bu parent'ın alt konuları
  final String? parentTopicId;

  /// Alt konular sayfası AppBar başlığı için
  final String? parentTitle;

  const TopicsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.parentTopicId,
    this.parentTitle,
  });


  Future<void> _openTopicSheet(
      BuildContext context,
      WidgetRef ref, {
        required Topic topic,
        required String subjectName,
        required bool isSubtopic,
        required TopicsArgs listArgs,
        String? parentTopicTitle,
      }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        int difficulty = topic.difficulty;

        return StatefulBuilder(
          builder: (ctx, setState) {
            final header = (parentTopicTitle == null || parentTopicTitle!.trim().isEmpty)
                ? topic.title
                : '${parentTopicTitle!} > ${topic.title}';

            final hasStarted = topic.nextReviewAt != null;
            final now = DateTime.now();
            final state = MemoryUtils.stateLabel(now, topic.lastReviewedAt, topic.nextReviewAt);
            final memPercent = topic.nextReviewAt == null
                ? '-'
                : '%${MemoryUtils.percent(now, topic.lastReviewedAt, topic.nextReviewAt)}';
            final remaining = MemoryUtils.remainingLong(now, topic.nextReviewAt);
            final totalLevels = ReviewIntervals.daysForDifficulty(difficulty).length;
            final level = topic.nextReviewAt == null
                ? '-/$totalLevels'
                : '${topic.intervalIndex + 1}/$totalLevels';

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(header, style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subjectName, style: Theme.of(ctx).textTheme.bodyMedium),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChipInfo(label: 'Hafıza', value: '$memPercent ($state)'),
                        ChipInfo(label: 'Unutmaya', value: remaining),
                        ChipInfo(label: 'Seviye', value: level),
                        ChipInfo(label: 'Aralık', value: _nextIntervalLabel(topic.intervalIndex, difficulty)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (!hasStarted) ...[
                      Row(
                        children: [
                          Text('Zorluk', style: Theme.of(ctx).textTheme.titleMedium),
                          InkWell(
                            onTap: () => _showDifficultyInfo(ctx),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 2), // istersen 0 yap
                              child: Icon(Icons.info_outline_rounded, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Kolay'),
                            selected: difficulty == 0,
                            onSelected: (_) => setState(() => difficulty = 0),
                          ),
                          ChoiceChip(
                            label: const Text('Orta'),
                            selected: difficulty == 1,
                            onSelected: (_) => setState(() => difficulty = 1),
                          ),
                          ChoiceChip(
                            label: const Text('Zor'),
                            selected: difficulty == 2,
                            onSelected: (_) => setState(() => difficulty = 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!hasStarted) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            await _startReview(ref, topic, listArgs, difficulty: difficulty);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Konu ve Soru Çözümü Bitti Takibi Başlat'),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await _markReviewed(ref, topic, listArgs, difficulty: difficulty);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Tekrar yaptım'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await _markFailed(ref, topic, listArgs, difficulty: difficulty);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Yapamadım'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _nextIntervalLabel(int intervalIndex, int difficulty) {
    final days = ReviewIntervals.daysForDifficulty(difficulty);
    final idx = ReviewIntervals.clampIndex(intervalIndex, length: days.length);
    final d = days[idx];
    return '$d.gün';
  }

  void _showDifficultyInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dctx) {
        return AlertDialog(
          title: const Text('Zorluk seviyesi ne işe yarar?'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bu seçim tekrar aralıklarını etkiler.'),
              SizedBox(height: 10),
              Text('• Kolay: Aralıklar daha uzun başlar (daha seyrek tekrar).'),
              Text('• Orta: Standart aralıklarla başlar.'),
              Text('• Zor: Aralıklar daha kısa başlar (daha sık tekrar).'),
              SizedBox(height: 10),
              Text('Not: İleride “Yapamadım” aksiyonu ile aralığı tekrar kısaltacağız.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }



  Future<void> _markReviewed(
      WidgetRef ref,
      Topic row,
      TopicsArgs currentArgs, {
        required int difficulty,
      }) async {
    final db = ref.read(appDatabaseProvider);

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final days = ReviewIntervals.daysForDifficulty(difficulty);
    final idx = ReviewIntervals.clampIndex(row.intervalIndex, length: days.length);
    final nextIdx = ReviewIntervals.clampIndex(idx + 1, length: days.length);
    final nextDays = days[nextIdx];

    final nextMs = nowMs + Duration(days: nextDays).inMilliseconds;

    await (db.update(db.topics)..where((t) => t.id.equals(row.id))).write(
      TopicsCompanion(
        difficulty: drift.Value(difficulty),
        intervalIndex: drift.Value(nextIdx),
        lastReviewedAt: drift.Value(nowMs),
        nextReviewAt: drift.Value(nextMs),
      ),
    );

    ref.invalidate(topicsProvider(currentArgs));
  }

  Future<void> _markFailed(
      WidgetRef ref,
      Topic row,
      TopicsArgs currentArgs, {
        required int difficulty,
      }) async {
    final db = ref.read(appDatabaseProvider);

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final days = ReviewIntervals.daysForDifficulty(difficulty);
    final idx = ReviewIntervals.clampIndex(row.intervalIndex, length: days.length);
    final nextIdx = ReviewIntervals.clampIndex(idx - 1, length: days.length);
    final nextDays = days[nextIdx];

    final nextMs = nowMs + Duration(days: nextDays).inMilliseconds;

    await (db.update(db.topics)..where((t) => t.id.equals(row.id))).write(
      TopicsCompanion(
        difficulty: drift.Value(difficulty),
        intervalIndex: drift.Value(nextIdx),
        lastReviewedAt: drift.Value(nowMs),
        nextReviewAt: drift.Value(nextMs),
      ),
    );

    ref.invalidate(topicsProvider(currentArgs));
  }

  Future<void> _startReview(
      WidgetRef ref,
      Topic row,
      TopicsArgs listArgs, {
        required int difficulty,
      }) async {
    final db = ref.read(appDatabaseProvider);

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final days = ReviewIntervals.daysForDifficulty(difficulty);
    final startIdx = 0; // ilk tekrar her zaman yarın
    final nextMs = nowMs + Duration(days: days[startIdx]).inMilliseconds;

    await (db.update(db.topics)..where((t) => t.id.equals(row.id))).write(
      TopicsCompanion(
        difficulty: drift.Value(difficulty),
        intervalIndex: drift.Value(startIdx),
        lastReviewedAt: drift.Value(nowMs),
        nextReviewAt: drift.Value(nextMs),
      ),
    );

    ref.invalidate(topicsProvider(listArgs));
  }

  void _toggleExpanded(WidgetRef ref, String parentId) {
    final current = ref.read(expandedParentsProvider);
    final next = <String>{...current};
    if (next.contains(parentId)) {
      next.remove(parentId);
    } else {
      next.add(parentId);
    }
    ref.read(expandedParentsProvider.notifier).state = next;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = TopicsArgs(subjectId: subjectId, parentTopicId: parentTopicId);
    final topicsAsync = ref.watch(topicsProvider(args));

    final now = ref.watch(nowTickerProvider).maybeWhen(
      data: (d) => d,
      orElse: () => DateTime.now(),
    );

    // Sadece ana konular sayfasında count + expand state mantıklı
    final countsAsync = parentTopicId == null
        ? ref.watch(subtopicCountsProvider(subjectId))
        : const AsyncData(<String, int>{});

    final title = parentTopicId == null ? subjectName : (parentTitle ?? 'Alt konular');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('DB okuma hatası: $err'),
          ),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('Bu listede konu yok.'));
          }

          return countsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('DB okuma hatası: $e'),
              ),
            ),
            data: (counts) {
              final expanded = ref.watch(expandedParentsProvider);

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final t = topics[i];
                  final tint = MemoryUtils.cardTint(context, now, t.lastReviewedAt, t.nextReviewAt);
                  final state = MemoryUtils.stateLabel(now, t.lastReviewedAt, t.nextReviewAt);
                  final memPercent = t.nextReviewAt == null
                      ? '-'
                      : '%${MemoryUtils.percent(now, t.lastReviewedAt, t.nextReviewAt)}';
                  final remainingShort = MemoryUtils.remainingShort(now, t.nextReviewAt);
                  final subCount = counts[t.id] ?? 0;
                  final hasSubtopics = parentTopicId == null && subCount > 0;
                  final isExpanded = expanded.contains(t.id);

                  final childrenArgs = TopicsArgs(subjectId: subjectId, parentTopicId: t.id);
                  final childrenAsync = (hasSubtopics && isExpanded)
                      ? ref.watch(topicsProvider(childrenArgs))
                      : null;

                  return Card(
                    color: tint,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            onTap: () => _openTopicSheet(
                              context,
                              ref,
                              topic: t,
                              subjectName: subjectName,
                              isSubtopic: parentTopicId != null,
                              listArgs: args,
                              parentTopicTitle: parentTopicId == null ? null : (parentTitle ?? subjectName),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text('${t.title} (${t.questionCount})')),
                                const SizedBox(width: 8),
                                CountdownWithRemaining(
                                  now: now,
                                  intervalIndex: t.intervalIndex,
                                  lastReviewedAt: t.lastReviewedAt,
                                  nextReviewAt: t.nextReviewAt,
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hafıza: $memPercent ($state) • Unutmaya: $remainingShort'),
                                  const SizedBox(height: 8),
                                  IntervalStrip(
                                    intervalIndex: t.intervalIndex,
                                    difficulty: t.difficulty,
                                    started: t.nextReviewAt != null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (hasSubtopics)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _toggleExpanded(ref, t.id),
                                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                    label: Text(isExpanded
                                        ? 'Alt konuları gizle ($subCount)'
                                        : 'Alt konuları gör ($subCount)'),
                                  ),
                                ],
                              ),
                            ),

                          if (hasSubtopics && isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
                              child: SubtopicsPanel(
                                now: now,
                                asyncValue: childrenAsync!,
                                onTapTopic: (child) {
                                  context.router.push(
                                    TopicsRoute(
                                      subjectId: subjectId,
                                      subjectName: subjectName,
                                      parentTopicId: child.id,
                                      parentTitle: child.title,
                                    ),
                                  );
                                },
                                onOpenSheet: (child) => _openTopicSheet(
                                  context,
                                  ref,
                                  topic: child,
                                  subjectName: subjectName,
                                  isSubtopic: true,
                                  listArgs: childrenArgs, // önemli: alt listeyi invalidate etmek için
                                  parentTopicTitle: t.title,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
