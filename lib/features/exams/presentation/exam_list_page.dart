import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';
import 'package:kpss_tekrar_takibi/app/router/app_router.dart';

@RoutePage()
class ExamListPage extends ConsumerWidget {
  const ExamListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sınav Seç')),
      body: FutureBuilder<List<Exam>>(
        future: db.select(db.exams).get(),
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

          final exams = snapshot.data ?? const <Exam>[];
          if (exams.isEmpty) {
            return const Center(child: Text('Sınav bulunamadı (DB boş).'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final e = exams[i];
              return Card(
                child: ListTile(
                  title: Text(e.name),
                  subtitle: const Text('Derslere geç'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.router.push(SubjectsRoute(examId: e.id));
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