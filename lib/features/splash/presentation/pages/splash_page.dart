import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';

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

  // Logo slides up from below
  late final Animation<Offset> _logoSlide;
  // Text fades + slides down from above
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  // Glow pulse on logo
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
          context.go('/home');
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
              // ASCENDION arched text — slides in from top
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/images/splash_text.png',
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.onSurface,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Circle A logo — slides in from bottom with glow
              SlideTransition(
                position: _logoSlide,
                child: AnimatedBuilder(
                  animation: _glowPulse,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: _glowPulse.value * 0.25),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    width: 220,
                    color: Theme.of(context).colorScheme.onSurface,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),

              const SizedBox(height: 64),

              // Loading dots
              const _LoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = (((_controller.value - delay) % 1.0 + 1.0) % 1.0);
            final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: opacity.clamp(0.15, 1.0),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
