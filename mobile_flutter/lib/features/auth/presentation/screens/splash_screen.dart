import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const SplashScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 48, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Private Communication',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('CHAT.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2)),
                        SizedBox(width: 8),
                        Text('CALL.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2)),
                        SizedBox(width: 8),
                        Text('DISAPPEAR.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10B981), letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Zero knowledge. End-to-end encrypted. No phone number or email required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onContinue,
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
