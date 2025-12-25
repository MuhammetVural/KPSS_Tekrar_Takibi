import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/features/exams/presentation/exam_list_page.dart';

import 'package:kpss_tekrar_takibi/features/subjects/presentation/subjects_page.dart';

import '../../features/topics/presentation/topics_page.dart';


part 'app_router.gr.dart';

final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: ExamListRoute.page, initial: true),
    AutoRoute(page: SubjectsRoute.page),
    AutoRoute(page: TopicsRoute.page),
  ];
}