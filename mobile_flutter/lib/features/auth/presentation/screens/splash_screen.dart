import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const SplashScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Shield Brand Logo Badge
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_rounded, size: 54, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Our',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                          ),
                          TextSpan(
                            text: 'Space',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF10B981), letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'SECURE PRIVATE MESSAGING & CALLS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // Feature Pill Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeaturePill(Icons.lock_rounded, 'E2E Encrypted'),
                        const SizedBox(width: 8),
                        _buildFeaturePill(Icons.visibility_off_rounded, 'Zero Knowledge'),
                        const SizedBox(width: 8),
                        _buildFeaturePill(Icons.timer_rounded, 'Auto Disappear'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'No phone numbers required. Instant zero-trace encrypted communication built for total privacy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                    ),
                  ],
                ),
              ),

              // Get Started CTA Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: onContinue,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF10B981)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
