import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onBack;

  const PrivacyPolicyScreen({
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
          'Privacy Policy',
          style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Pill
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
                  Icon(Icons.shield_rounded, size: 14, color: Color(0xFF7B2FBE)),
                  SizedBox(width: 6),
                  Text('ZERO KNOWLEDGE & E2EE COMPLIANT', style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Last Updated: August 2026', style: TextStyle(color: subtxtCol, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '1. Zero Data Collection Architecture',
              'OurSpace is designed from the ground up to respect your privacy. We do not collect, store, or sell your personal information. We do not ask for your phone number, email address, real name, contacts, or location data. Your identity is represented solely by a locally generated cryptographic keypair.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '2. End-to-End Encryption (E2EE)',
              'All messages, voice calls, video calls, images, and files are encrypted end-to-end using AES-256-GCM and ECDH key exchange on your device. Only you and the intended recipient possess the decryption keys. Neither OurSpace servers nor any third party can access your communications.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '3. Self-Destructing Data & Disappearing Messages',
              'Messages sent in Ghost Mode or with custom disappearing timers are automatically purged from local memory and relay queues after the set duration (30 seconds default in Ghost Mode). Once deleted, data cannot be recovered by anyone.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '4. Third-Party Analytics & Tracking',
              'We do NOT use third-party analytics trackers, SDKs, or advertising networks. We do not track user behavior, app usage metrics, or IP addresses.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '5. Right to Erasure & Account Clearance',
              'You can erase all local keys, stored session data, and identity records at any time by tapping "Logout & Clear Private Session" in the Settings screen.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildPolicySection(Color cardBg, Color cardBorder, Color titleColor, Color textColor, String title, String content) {
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
