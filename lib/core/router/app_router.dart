import 'package:go_router/go_router.dart';
import 'package:acepool/features/splash/presentation/pages/splash_page.dart';
import 'package:acepool/features/home/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
