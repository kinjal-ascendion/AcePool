import 'package:flutter/material.dart';

class SplashText extends StatelessWidget {
  const SplashText({super.key, required this.fade, required this.slide});

  final Animation<double> fade;
  final Animation<Offset> slide;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
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
    );
  }
}
