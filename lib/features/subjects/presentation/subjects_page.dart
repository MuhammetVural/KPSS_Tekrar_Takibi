import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';

import '../../../app/router/app_router.dart';

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

    final query = (db.select(db.subjects)
      ..where((t) => t.examId.equals(examId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    return Scaffold(
      appBar: AppBar(title: const Text('Dersler')),
      body: FutureBuilder<List<Subject>>(
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
            padding: const EdgeInsets.all(16),
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
    );
  }
}