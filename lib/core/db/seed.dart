import 'package:drift/drift.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';

Future<void> seedIfNeeded(AppDatabase db) async {
  // Seed exams if empty
  final examsExisting = await db.select(db.exams).get();
  if (examsExisting.isEmpty) {
    await db.batch((b) {
      b.insertAll(db.exams, const [
        ExamsCompanion(id: Value('kpss'), name: Value('KPSS')),
        ExamsCompanion(id: Value('ales'), name: Value('ALES')),
        ExamsCompanion(id: Value('dgs'), name: Value('DGS')),
        ExamsCompanion(id: Value('tyt'), name: Value('TYT')),
      ]);
    });
  }


  // Seed subjects if empty
  final subjectsExisting = await db.select(db.subjects).get();
  if (subjectsExisting.isEmpty) {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.batch((b) {
      b.insertAll(db.subjects, [
        // KPSS
        SubjectsCompanion(id: const Value('kpss_tr'), examId: const Value('kpss'), name: const Value('Türkçe'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('kpss_mat'), examId: const Value('kpss'), name: const Value('Matematik'), sortOrder: const Value(2)),
        SubjectsCompanion(id: const Value('kpss_tarih'), examId: const Value('kpss'), name: const Value('Tarih'), sortOrder: const Value(3)),
        SubjectsCompanion(id: const Value('kpss_cog'), examId: const Value('kpss'), name: const Value('Coğrafya'), sortOrder: const Value(4)),
        SubjectsCompanion(id: const Value('kpss_vat'), examId: const Value('kpss'), name: const Value('Vatandaşlık'), sortOrder: const Value(5)),

        // ALES (başlangıç)
        SubjectsCompanion(id: const Value('ales_say'), examId: const Value('ales'), name: const Value('Sayısal'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('ales_soz'), examId: const Value('ales'), name: const Value('Sözel'), sortOrder: const Value(2)),

        // DGS (başlangıç)
        SubjectsCompanion(id: const Value('dgs_say'), examId: const Value('dgs'), name: const Value('Sayısal'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('dgs_soz'), examId: const Value('dgs'), name: const Value('Sözel'), sortOrder: const Value(2)),

        // TYT (başlangıç)
        SubjectsCompanion(id: const Value('tyt_tr'), examId: const Value('tyt'), name: const Value('Türkçe'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('tyt_mat'), examId: const Value('tyt'), name: const Value('Matematik'), sortOrder: const Value(2)),
        SubjectsCompanion(id: const Value('tyt_fen'), examId: const Value('tyt'), name: const Value('Fen'), sortOrder: const Value(3)),
        SubjectsCompanion(id: const Value('tyt_sos'), examId: const Value('tyt'), name: const Value('Sosyal'), sortOrder: const Value(4)),
      ]);

      // Not: createdAt alanı Subjects tablosunda yok; now şu an kullanılmıyor.
      // İleride Topics seed ederken createdAt set edeceğiz.
      // ignore: unused_local_variable
      // final _ = now;
    });
  }

  // Seed topics if empty
  final topicsExisting = await db.select(db.topics).get();
  if (topicsExisting.isEmpty) {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.batch((b) {
      b.insertAll(db.topics, [
        // KPSS - Türkçe
        TopicsCompanion(
          id: const Value('kpss_tr_paragraf'),
          subjectId: const Value('kpss_tr'),
          title: const Value('Paragraf'),
          questionCount: const Value(12),
          intervalIndex: const Value(0),
          lastReviewedAt: const Value(null),
          nextReviewAt: const Value(null),
          archived: const Value(false),
          createdAt: Value(now),
        ),
        TopicsCompanion(
          id: const Value('kpss_tr_anlatim_bozuklugu'),
          subjectId: const Value('kpss_tr'),
          title: const Value('Anlatım Bozukluğu'),
          questionCount: const Value(6),
          intervalIndex: const Value(0),
          lastReviewedAt: const Value(null),
          nextReviewAt: const Value(null),
          archived: const Value(false),
          createdAt: Value(now),
        ),

        // KPSS - Matematik
        TopicsCompanion(
          id: const Value('kpss_mat_sayilar'),
          subjectId: const Value('kpss_mat'),
          title: const Value('Sayılar'),
          questionCount: const Value(8),
          intervalIndex: const Value(0),
          lastReviewedAt: const Value(null),
          nextReviewAt: const Value(null),
          archived: const Value(false),
          createdAt: Value(now),
        ),
      ]);
    });
  }

}