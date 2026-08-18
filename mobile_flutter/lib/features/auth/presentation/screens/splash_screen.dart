import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback? onContinue;

  const SplashScreen({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      body: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

