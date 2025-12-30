import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';

/// Home ekranında göstermek için topic + subject adı.
class HomeTopicItem {
  final Topic topic;
  final String subjectName;

  const HomeTopicItem({
    required this.topic,
    required this.subjectName,
  });
}

/// UI'nın canlı kalması için "now" tick.
/// 30 sn'de bir rebuild tetikler.
final nowTickProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 30),
        (_) => DateTime.now(),
  );
});

/// Başlatılmış konular:
/// - archived=false
/// - lastReviewedAt veya nextReviewAt dolu
/// Konu + ders adı birlikte gelir.
final startedHomeTopicsProvider = StreamProvider<List<HomeTopicItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);

  final t = db.topics;
  final s = db.subjects;

  final query = db.select(t).join([
    innerJoin(s, s.id.equalsExp(t.subjectId)),
  ])
    ..where(
      t.archived.equals(false) &
      (t.lastReviewedAt.isNotNull() | t.nextReviewAt.isNotNull()),
    )
    ..orderBy([
      OrderingTerm(
        expression: t.nextReviewAt,
        mode: OrderingMode.asc,
        nulls: NullsOrder.last,
      ),
      OrderingTerm(expression: t.title),
    ]);

  return query.watch().map((rows) {
    return rows
        .map(
          (r) => HomeTopicItem(
        topic: r.readTable(t),
        subjectName: r.readTable(s).name,
      ),
    )
        .toList(growable: false);
  });
});

/// Başlatılmış konular (sadece seçilen sınav için)
final startedHomeTopicsByExamProvider =
StreamProvider.family<List<HomeTopicItem>, String>((ref, examId) {
  final db = ref.watch(appDatabaseProvider);

  final t = db.topics;
  final s = db.subjects;

  final query = db.select(t).join([
    innerJoin(s, s.id.equalsExp(t.subjectId)),
  ])
    ..where(
      s.examId.equals(examId) &
      t.archived.equals(false) &
      (t.lastReviewedAt.isNotNull() | t.nextReviewAt.isNotNull()),
    )
    ..orderBy([
      OrderingTerm(
        expression: t.nextReviewAt,
        mode: OrderingMode.asc,
        nulls: NullsOrder.last,
      ),
      OrderingTerm(expression: t.title),
    ]);

  return query.watch().map((rows) {
    return rows
        .map(
          (r) => HomeTopicItem(
        topic: r.readTable(t),
        subjectName: r.readTable(s).name,
      ),
    )
        .toList(growable: false);
  });
});