import 'package:auto_route/auto_route.dart';
import 'package:kpss_tekrar_takibi/features/home/presentation/home_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
      ];
}
