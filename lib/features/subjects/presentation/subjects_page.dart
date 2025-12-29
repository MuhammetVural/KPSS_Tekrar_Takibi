import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';

import '../../../app/router/app_router.dart';
import '../../home/application/selected_subject_provider.dart';
import '../../topics/application/topics_controller.dart';

@RoutePage()
class SubjectsPage extends ConsumerWidget {
  final String examId;

  const SubjectsPage({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    final startedAsync = ref.watch(startedHomeTopicsByExamProvider(examId));
    final now = DateTime.now();

    final query = (db.select(db.subjects)
      ..where((t) => t.examId.equals(examId))
      ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
        .get();

    return Scaffold(
      appBar: AppBar(title: const Text('Dersler')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Subject>>(
              future: query,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('DB okuma hatası: ${snapshot.error}'),
                    ),
                  );
                }

                final subjects = snapshot.data ?? const <Subject>[];
                if (subjects.isEmpty) {
                  return const Center(child: Text('Bu sınav için ders bulunamadı.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final s = subjects[i];
                    return Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text('id: ${s.id}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.router.push(
                            TopicsRoute(subjectId: s.id, subjectName: s.name),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Dashboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StartedTopicsDashboard(now: now, startedAsync: startedAsync),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _StartedTopicsDashboard extends StatelessWidget {
  final DateTime now;
  final AsyncValue<List<HomeTopicItem>> startedAsync;

  const _StartedTopicsDashboard({
    required this.now,
    required this.startedAsync,
  });

  @override
  Widget build(BuildContext context) {
    return startedAsync.when(
      loading: () => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: const CircularProgressIndicator(),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Text('Başlatılan konular okunamadı: $e'),
      ),
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Başlatılan Konular',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('${items.length}',
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: items.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Henüz başlatılan konu yok.'),
              )
                  : SizedBox(
                height: 180,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: items.length > 10 ? 10 : items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -2),
                      title: Text(item.topic.title),
                      subtitle: Text(item.subjectName),
                      trailing: CountdownWithRemaining(
                        now: now,
                        intervalIndex: item.topic.intervalIndex,
                        lastReviewedAt: item.topic.lastReviewedAt,
                        nextReviewAt: item.topic.nextReviewAt,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}