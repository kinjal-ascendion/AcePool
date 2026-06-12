import 'package:flutter/material.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, required this.slide, required this.glowPulse});

  final Animation<Offset> slide;
  final Animation<double> glowPulse;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SlideTransition(
      position: slide,
      child: AnimatedBuilder(
        animation: glowPulse,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: glowPulse.value * 0.25),
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
          color: onSurface,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    );
  }
}
