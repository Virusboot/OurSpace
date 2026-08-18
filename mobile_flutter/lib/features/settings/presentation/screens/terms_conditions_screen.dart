import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onBack;

  const TermsConditionsScreen({
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
          'Terms & Conditions',
          style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel_rounded, size: 14, color: Color(0xFF7B2FBE)),
                  SizedBox(width: 6),
                  Text('TERMS OF SERVICE AGREEMENT', style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Effective Date: August 2026', style: TextStyle(color: subtxtCol, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            _buildSection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '1. Acceptance of Terms',
              'By accessing or using the OurSpace application, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you must discontinue use of the application immediately.',
            ),
            const SizedBox(height: 14),

            _buildSection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '2. Acceptable Use Policy',
              'You agree to use OurSpace solely for lawful communication. You are strictly prohibited from using the platform for illegal activities, transmitting malware, harassing individuals, or distributing non-consensual content.',
            ),
            const SizedBox(height: 14),

            _buildSection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '3. User Cryptographic Keys & Responsibility',
              'Because OurSpace uses end-to-end encryption with zero-knowledge key storage, you are solely responsible for maintaining your Master Recovery Key and PIN. OurSpace cannot recover lost encryption keys or lost access credentials.',
            ),
            const SizedBox(height: 14),

            _buildSection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '4. Service Modifications & Disclaimer',
              'OurSpace is provided on an "AS IS" and "AS AVAILABLE" basis. We reserve the right to update app security protocols and infrastructure to maintain system security and privacy compliance.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSection(Color cardBg, Color cardBorder, Color titleColor, Color textColor, String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: textColor, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
