import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onFinish;

  const OnboardingScreen({
    super.key,
    this.isDarkMode = false,
    required this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'End-to-End Encryption',
      'subtitle': 'Zero-Trust Communication',
      'description': 'Every text message, audio note, and HD video call is encrypted right on your device. Only you and your peer hold the keys.',
      'icon': Icons.lock_outline_rounded,
      'tag': 'AES-256 & Curve25519',
    },
    {
      'title': 'Zero-Knowledge Identity',
      'subtitle': 'No Phone Numbers Needed',
      'description': 'Create anonymous identity profiles with custom usernames and private identity handles. Zero personal tracking or contact syncing.',
      'icon': Icons.shield_outlined,
      'tag': 'Total Anonymity',
    },
    {
      'title': 'Disappearing Messages',
      'subtitle': 'Self-Destructing Timers & View-Once',
      'description': 'Set auto-expire timers on conversations and send view-once protected media with screenshot prevention overlays.',
      'icon': Icons.timer_rounded,
      'tag': 'Zero Digital Trace',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnim = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
    ));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgCol = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final titleTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyTxt = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final skipTxt = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final indicatorUnsel = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgCol,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // Top Bar with Logo & Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Our',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFBB86FC) : const Color(0xFF7B2FBE),
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text: 'Space',
                              style: const TextStyle(
                                color: Color(0xFFE91E8C),
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onFinish,
                        child: Text('Skip', style: TextStyle(color: skipTxt, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

                // PageView Slider Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    itemCount: _slides.length,
                    itemBuilder: (ctx, idx) {
                      final slide = _slides[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hero Icon Card with Scale Animation
                            ScaleTransition(
                              scale: _scaleAnim,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                                      const Color(0xFFE91E8C).withValues(alpha: 0.06),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Icon(
                                    slide['icon'] as IconData,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Feature Tag Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                                    const Color(0xFFE91E8C).withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
                                ),
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                                ).createShader(bounds),
                                child: Text(
                                  (slide['tag'] as String).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Title & Subtitle
                            Text(
                              slide['title'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: titleTxt,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE91E8C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Description Body
                            Text(
                              slide['description'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: bodyTxt,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation Indicators & Action CTA Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Column(
                    children: [
                      // Animated Page Indicator Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (idx) {
                          final isSel = _currentPage == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isSel ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: isSel
                                  ? const LinearGradient(
                                      colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                                    )
                                  : null,
                              color: isSel ? null : indicatorUnsel,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Next / Get Started AppGradientButton
                      AppGradientButton(
                        label: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        onTap: _nextPage,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
