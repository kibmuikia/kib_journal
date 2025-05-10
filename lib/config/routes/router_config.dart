import 'package:go_router/go_router.dart' show GoRoute, GoRouter;
import 'package:kib_journal/core/constants/app_constants.dart' show appName;
import 'package:kib_journal/presentation/screens/my_home_page.dart';

final appRouteConfig = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MyHomePage(title: '$appName Demo Page'),
    ),
  ],
);
