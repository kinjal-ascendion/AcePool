import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:acepool/core/router/app_router.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:acepool/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  initDependencies();

  runApp(const AcePoolApp());
}

class AcePoolApp extends StatelessWidget {
  const AcePoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AcePool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
