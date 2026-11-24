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
            Text('Last Updated: November 2026', style: TextStyle(color: subtxtCol, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '1. Minimal Data Collection & Privacy',
              'OurSpace is built with privacy by design. We do not sell your data, collect your contacts, or track your location. You only provide a username and password/recovery credential to authenticate your encrypted account.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '2. End-to-End Encryption & Device Permissions',
              'All messages, voice calls, video calls, and shared media use end-to-end encryption (AES-256-GCM / ECDH) and WebRTC peer-to-peer transport. Camera and Microphone permissions are used strictly during active calls or media capture when initiated by you.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '3. Push Notifications & No Ad Tracking',
              'We use Firebase Cloud Messaging (FCM) tokens solely to deliver real-time incoming call and message notifications. We do NOT use third-party advertising networks, behavioral analytics, or tracking SDKs.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '4. Disappearing Messages & Data Retention',
              'Messages sent in Ghost Mode automatically expire and are purged after the configured timer. Timed call links expire automatically after the selected duration.',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '5. Account & Data Deletion Rights',
              'You can permanently delete your account, profile, and server records at any time using "Delete Account & Wipe Database" in Settings, or clear your local session via "Logout & Clear Private Session".',
            ),
            const SizedBox(height: 14),

            _buildPolicySection(
              cardBg,
              cardBorderCol,
              txtCol,
              subtxtCol,
              '6. Age Requirement & Child Safety',
              'OurSpace is strictly intended for users aged 13 and older (or the minimum legal age in your country). We maintain zero tolerance for Child Sexual Abuse Material (CSAM) or exploitation. Any reported violations result in immediate account termination.',
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
