import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:acepool/features/splash/presentation/widgets/loading_dots.dart';
import 'package:acepool/features/splash/presentation/widgets/splash_logo.dart';
import 'package:acepool/features/splash/presentation/widgets/splash_text.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SplashBloc>()..add(const SplashStarted()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _glowController;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
    ));

    _textFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.75, curve: Curves.easeIn),
    );

    _glowPulse = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashComplete) {
          context.go('/login');
        } else if (state is SplashError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SplashText(fade: _textFade, slide: _textSlide),
              const SizedBox(height: 24),
              SplashLogo(slide: _logoSlide, glowPulse: _glowPulse),
              const SizedBox(height: 64),
              const LoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}
