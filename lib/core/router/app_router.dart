import 'package:go_router/go_router.dart';
import 'package:acepool/features/splash/presentation/pages/splash_page.dart';
import 'package:acepool/features/home/presentation/pages/home_page.dart';
import 'package:acepool/features/auth/presentation/pages/login_page.dart';
import 'package:acepool/features/auth/presentation/pages/signup_page.dart';

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
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
