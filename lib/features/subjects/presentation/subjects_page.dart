import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';

import '../../../app/router/app_router.dart';
import '../../home/application/selected_subject_provider.dart';
import '../../topics/application/topics_controller.dart';

class _SubjectsVm {
  final String examName;
  final List<Subject> subjects;

  const _SubjectsVm({
    required this.examName,
    required this.subjects,
  });
}

@RoutePage()
class SubjectsPage extends ConsumerWidget {
  final String examId;

  const SubjectsPage({
    super.key,
    required this.examId,
  });

  Future<_SubjectsVm> _load(AppDatabase db) async {
    final exam = await (db.select(db.exams)..where((e) => e.id.equals(examId)))
        .getSingleOrNull();

    final subjects = await (db.select(db.subjects)
          ..where((t) => t.examId.equals(examId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
        .get();

    final name = (exam?.name.trim().isNotEmpty ?? false) ? exam!.name : examId;
    return _SubjectsVm(examName: name, subjects: subjects);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    final startedAsync = ref.watch(startedHomeTopicsByExamProvider(examId));
    final now = DateTime.now();

    return FutureBuilder<_SubjectsVm>(
      future: _load(db),
      builder: (context, snapshot) {
        final title = '${snapshot.data?.examName ?? 'Dersler'} Dersleri';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('DB okuma hatası: ${snapshot.error}'),
              ),
            ),
          );
        }

        final subjects = snapshot.data?.subjects ?? const <Subject>[];

        // Ders yoksa bile dashboard görünsün
        if (subjects.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              children: [
                const Text('Bu sınav için ders bulunamadı.'),
                const SizedBox(height: 16),
                _StartedTopicsCard(now: now, startedAsync: startedAsync),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            itemCount: subjects.length + 1, // + dashboard
            separatorBuilder: (_, i) {
              // son ders ile dashboard arası biraz daha geniş
              if (i == subjects.length - 1) return const SizedBox(height: 16);
              return const SizedBox(height: 10);
            },
            itemBuilder: (ctx, i) {
              if (i < subjects.length) {
                final s = subjects[i];
                return _SubjectPreviewCard(
                  subject: s,
                  onTap: () {
                    context.router.push(
                      TopicsRoute(subjectId: s.id, subjectName: s.name),
                    );
                  },
                );
              }

              // Dashboard card ders listesinin en altında, listeyle birlikte scroll olur
              return SafeArea(
                top: false,
                child: _StartedTopicsCard(now: now, startedAsync: startedAsync),
              );
            },
          ),
        );
      },
    );
  }
}

class _SubjectPreviewCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const _SubjectPreviewCard({
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          color: Colors.black.withValues(alpha: 0.03),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Konulara git',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _StartedTopicsCard extends StatelessWidget {
  final DateTime now;
  final AsyncValue<List<HomeTopicItem>> startedAsync;

  const _StartedTopicsCard({
    required this.now,
    required this.startedAsync,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: startedAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(14),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text('Başlatılan konular okunamadı: $e'),
        ),
        data: (items) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Başlatılan Konular',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      child: Text(
                        '${items.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'En yakındaki tekrarlar üstte.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 10),

                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Henüz başlatılan konu yok.'),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return _TopicPreviewCard(now: now, item: item);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopicPreviewCard extends StatelessWidget {
  final DateTime now;
  final HomeTopicItem item;

  const _TopicPreviewCard({
    required this.now,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.topic;

    final label = MemoryUtils.stateLabel(now, t.lastReviewedAt, t.nextReviewAt);
    final dot = MemoryUtils.stateColor(context, now, t.lastReviewedAt, t.nextReviewAt);
    final tint = MemoryUtils.cardTint(context, now, t.lastReviewedAt, t.nextReviewAt);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final t = item.topic;

        context.router.push(
          TopicsRoute(
            subjectId: t.subjectId,
            subjectName: item.subjectName,

            // Alt konu ise doğrudan alt konular sayfasına götürür
            parentTopicId: t.parentTopicId,

            // Scroll + highlight hedefi
            focusTopicId: t.id,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          color: tint ?? Colors.black.withValues(alpha: 0.03),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.subjectName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: Colors.black.withValues(alpha: 0.70),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CountdownWithRemaining(
              now: now,
              intervalIndex: t.intervalIndex,
              lastReviewedAt: t.lastReviewedAt,
              nextReviewAt: t.nextReviewAt,
            ),
          ],
        ),
      ),
    );
  }
}