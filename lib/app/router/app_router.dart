import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/features/exams/presentation/exam_list_page.dart';

import 'package:kpss_tekrar_takibi/features/subjects/presentation/subjects_page.dart';
import 'package:kpss_tekrar_takibi/features/home/presentation/home_page.dart';
import '../../features/topics/presentation/topics_page.dart';


part 'app_router.gr.dart';

/// Single router instance so notification taps can navigate reliably.
final AppRouter rootAppRouter = AppRouter();

final appRouterProvider = Provider<AppRouter>((ref) => rootAppRouter);

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, ),
    AutoRoute(page: ExamListRoute.page,initial: true ),
    AutoRoute(page: SubjectsRoute.page),
    AutoRoute(page: TopicsRoute.page),
  ];
}