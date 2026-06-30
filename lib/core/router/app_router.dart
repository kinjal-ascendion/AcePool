import 'package:acepool/features/auth/presentation/pages/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:acepool/features/splash/presentation/pages/splash_page.dart';
import 'package:acepool/features/home/presentation/pages/main_shell_page.dart';
import 'package:acepool/features/auth/presentation/pages/login_page.dart';
import 'package:acepool/features/auth/presentation/pages/signup_page.dart';

class AppRouter {
  AppRouter._();

  static final _authRoutes = {'/login', '/signup', '/splash', '/otp'};

  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);
      if (!isLoggedIn && !isAuthRoute) return '/login';
      // Allow logged-in users to stay on /otp for email verification
      if (isLoggedIn &&
          isAuthRoute &&
          state.matchedLocation != '/splash' &&
          state.matchedLocation != '/otp') {
        return '/home';
      }
      return null;
    },
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
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return OtpPage(email: extra['email']!, uid: extra['uid']!);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainShellPage(),
      ),
    ],
  );
}
