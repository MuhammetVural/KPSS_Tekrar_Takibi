import 'package:auto_route/annotations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';
import 'package:kpss_tekrar_takibi/features/topics/domain/review_intervals.dart';

@RoutePage()
class TopicsPage extends ConsumerWidget {
  final String subjectId;
  final String subjectName;

  const TopicsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  String _statusText(int? nextReviewAtMs) {
    if (nextReviewAtMs == null) return 'Başlamadın';

    final now = DateTime.now();
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAtMs);

    final today = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(next.year, next.month, next.day);
    final diffDays = nextDay.difference(today).inDays;

    if (diffDays < 0) return 'Gecikti';
    if (diffDays == 0) return 'Bugün';
    return '$diffDays gün sonra';
  }

  Future<void> _markReviewed(AppDatabase db, Topic row) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // intervalIndex: bir sonraki aralığı belirler.
    final idx = ReviewIntervals.clampIndex(row.intervalIndex);
    final days = ReviewIntervals.days[idx];

    final nextMs = nowMs + Duration(days: days).inMilliseconds;
    final nextIdx = ReviewIntervals.clampIndex(idx + 1);

    await (db.update(db.topics)..where((t) => t.id.equals(row.id))).write(
      TopicsCompanion(
        intervalIndex: drift.Value(nextIdx),
        lastReviewedAt: drift.Value(nowMs),
        nextReviewAt: drift.Value(nextMs),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    final future = (db.select(db.topics)
      ..where((t) => t.subjectId.equals(subjectId) & t.archived.equals(false))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.questionCount)]))
        .get();

    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: FutureBuilder<List<Topic>>(
        future: future,
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

          final topics = snapshot.data ?? const <Topic>[];
          if (topics.isEmpty) {
            return const Center(child: Text('Bu derste konu yok. (Seed ekleyeceğiz)'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final t = topics[i];
              final status = _statusText(t.nextReviewAt);

              return Card(
                child: ListTile(
                  title: Text('${t.title} (${t.questionCount})'),
                  subtitle: Text('Tekrar: $status'),
                  trailing: TextButton(
                    onPressed: () async {
                      await _markReviewed(db, t);
                      if (context.mounted) {
                        // hızlı refresh: sayfayı yeniden oluştur
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => TopicsPage(
                              subjectId: subjectId,
                              subjectName: subjectName,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Tekrar ettim'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}