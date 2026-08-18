import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onBack;

  const AboutUsScreen({
    super.key,
    required this.isDarkMode,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bgCol = isDarkMode ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final txtCol = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtxtCol = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDarkMode ? const Color(0xFF121317) : Colors.white;
    final cardBorderCol = isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txtCol, size: 20),
          onPressed: onBack,
        ),
        title: Text(
          'About OurSpace',
          style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Logo Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/Our Space Logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0066FF),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'OurSpace Privacy Chat',
              style: TextStyle(color: txtCol, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.4),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0 (Build 100)',
              style: TextStyle(color: subtxtCol, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Specs Grid Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderCol),
              ),
              child: Column(
                children: [
                  _buildSpecRow('Encryption Standard', 'AES-256-GCM + ECDH', txtCol, subtxtCol),
                  Divider(height: 20, color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9)),
                  _buildSpecRow('Key Exchange Protocol', 'Elliptic-Curve Diffie-Hellman', txtCol, subtxtCol),
                  Divider(height: 20, color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9)),
                  _buildSpecRow('Audio/Video Calls', 'WebRTC Peer-to-Peer', txtCol, subtxtCol),
                  Divider(height: 20, color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9)),
                  _buildSpecRow('Data Collection', 'Zero (No Logs Kept)', txtCol, subtxtCol),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mission & Architecture', style: TextStyle(color: txtCol, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    'OurSpace was engineered to establish a completely private, zero-trust messaging environment. By combining military-grade AES-256-GCM encryption, peer-to-peer WebRTC voice/video calls, and automatic disappearing timers, OurSpace guarantees that your conversations remain confidential.',
                    style: TextStyle(color: subtxtCol, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSpecRow(String label, String value, Color txtColor, Color subColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF0066FF), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
