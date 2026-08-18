import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactUsScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onBack;

  const ContactUsScreen({
    super.key,
    required this.isDarkMode,
    required this.onBack,
  });

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final bgCol = widget.isDarkMode ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final txtCol = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtxtCol = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = widget.isDarkMode ? const Color(0xFF121317) : Colors.white;
    final cardBorderCol = widget.isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txtCol, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Contact & Support',
          style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Official Email Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF7B2FBE).withValues(alpha: 0.12) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B2FBE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Official Support Email', style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text('support@ourspace.app', style: TextStyle(color: txtCol, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF7B2FBE), size: 20),
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: 'support@ourspace.app'));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied support email: support@ourspace.app'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Send Support Ticket', style: TextStyle(color: txtCol, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_isSubmitted)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                    const SizedBox(height: 12),
                    Text('Ticket Submitted Successfully!', style: TextStyle(color: txtCol, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Our privacy security engineering team will review your ticket within 24 hours.', style: TextStyle(color: subtxtCol, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _isSubmitted = false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Send Another Message', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _subjectCtrl,
                      style: TextStyle(color: txtCol, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: 'e.g. Help with messaging',
                        labelStyle: TextStyle(color: subtxtCol, fontSize: 13),
                        hintStyle: TextStyle(color: subtxtCol.withValues(alpha: 0.6), fontSize: 13),
                        filled: true,
                        fillColor: widget.isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      style: TextStyle(color: txtCol, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Your Message',
                        hintText: 'Type your message or feedback here...',
                        labelStyle: TextStyle(color: subtxtCol, fontSize: 13),
                        hintStyle: TextStyle(color: subtxtCol.withValues(alpha: 0.6), fontSize: 13),
                        filled: true,
                        fillColor: widget.isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF7B2FBE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please fill in both subject and message.'),
                              backgroundColor: const Color(0xFFF43F5E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        setState(() => _isSubmitted = true);
                        _subjectCtrl.clear();
                        _messageCtrl.clear();
                      },
                      child: const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
}
