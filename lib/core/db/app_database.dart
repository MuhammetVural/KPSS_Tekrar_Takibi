import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

class Exams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get examId => text().references(Exams, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Topics extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  /// Alt konu desteği (parent topic). Null ise ana konudur.
  /// Self-reference için customConstraint kullanıyoruz.
  TextColumn get parentTopicId =>
      text().nullable().customConstraint('NULL REFERENCES topics(id)')();
  TextColumn get title => text()();

  IntColumn get difficulty => integer().withDefault(const Constant(1))();

  /// 0=notStarted, 1=active, 2=completed, 3=maintenance
  IntColumn get reviewState => integer().withDefault(const Constant(0))();

  /// Bakım modunda tekrar aralığı (gün). Default: 30
  IntColumn get maintenanceDays => integer().withDefault(const Constant(30))();

  IntColumn get questionCount => integer().withDefault(const Constant(0))();

  IntColumn get intervalIndex => integer().withDefault(const Constant(0))();

  /// Epoch milliseconds
  IntColumn get lastReviewedAt => integer().nullable()();

  /// Epoch milliseconds
  IntColumn get nextReviewAt => integer().nullable()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// Epoch milliseconds (şimdilik 0; insert ederken set edeceğiz)
  IntColumn get createdAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Exams, Subjects, Topics])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v2: Topics tablosuna parentTopicId eklendi
      if (from < 4) {
        await m.addColumn(topics, topics.parentTopicId);
      }
    },
  );


}
