import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/skeu_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _slides = const [
    _Slide(
      illustration: _IllustrationType.search,
      title: 'Trouvez votre trajet',
      subtitle: 'Cherchez parmi des dizaines de compagnies entre toutes les villes du Burkina Faso.',
      accent: Color(0xFF761CEA),
    ),
    _Slide(
      illustration: _IllustrationType.compare,
      title: 'Comparez les prix',
      subtitle: 'Prix, horaires, disponibilités — tout au même endroit pour choisir la meilleure offre.',
      accent: Color(0xFF5A0FA8),
    ),
    _Slide(
      illustration: _IllustrationType.book,
      title: 'Réservez en un tap',
      subtitle: 'Obtenez votre code de réservation instantanément. Payez à l\'agence à votre arrivée.',
      accent: Color(0xFF9B4FFF),
    ),
  ];

  void _next() {
    HapticService.selection();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/home');
    }
  }

  void _skip() {
    HapticService.light();
    context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Passer',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.contentTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  HapticService.selection();
                  setState(() => _currentPage = i);
                },
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // Indicators + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SkeuButton(
                    label: isLast ? 'Commencer' : 'Suivant',
                    icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _IllustrationType { search, compare, book }

class _Slide {
  final _IllustrationType illustration;
  final String title;
  final String subtitle;
  final Color accent;

  const _Slide({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Illustration(type: slide.illustration, accent: slide.accent),
          const SizedBox(height: 48),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.content,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.contentSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final _IllustrationType type;
  final Color accent;
  const _Illustration({required this.type, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(120, 120),
          painter: _IllustrationPainter(type: type, accent: accent),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final _IllustrationType type;
  final Color accent;
  const _IllustrationPainter({required this.type, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case _IllustrationType.search:
        _drawSearch(canvas, size, paint, strokePaint);
      case _IllustrationType.compare:
        _drawCompare(canvas, size, paint, strokePaint);
      case _IllustrationType.book:
        _drawBook(canvas, size, paint, strokePaint);
    }
  }

  void _drawSearch(Canvas canvas, Size s, Paint p, Paint sp) {
    // Bus body
    final busRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.1, s.height * 0.3, s.width * 0.65, s.height * 0.4),
      const Radius.circular(12),
    );
    canvas.drawRRect(busRect, p..color = p.color.withValues(alpha: 0.15));
    canvas.drawRRect(busRect, sp);

    // Windows
    for (int i = 0; i < 3; i++) {
      final wr = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * (0.16 + i * 0.18), s.height * 0.38, s.width * 0.12, s.height * 0.12),
        const Radius.circular(4),
      );
      canvas.drawRRect(wr, p..color = p.color.withValues(alpha: 0.3));
    }

    // Magnifier
    canvas.drawCircle(Offset(s.width * 0.72, s.height * 0.38), s.width * 0.14, p..color = p.color.withValues(alpha: 0.1));
    canvas.drawCircle(Offset(s.width * 0.72, s.height * 0.38), s.width * 0.14, sp);
    final handlePath = Path()
      ..moveTo(s.width * 0.82, s.height * 0.5)
      ..lineTo(s.width * 0.9, s.height * 0.6);
    canvas.drawPath(handlePath, sp..strokeWidth = 4);
  }

  void _drawCompare(Canvas canvas, Size s, Paint p, Paint sp) {
    // Two price tags
    final tag1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.05, s.height * 0.2, s.width * 0.38, s.height * 0.55),
      const Radius.circular(12),
    );
    final tag2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.57, s.height * 0.25, s.width * 0.38, s.height * 0.55),
      const Radius.circular(12),
    );
    canvas.drawRRect(tag1, p..color = p.color.withValues(alpha: 0.15));
    canvas.drawRRect(tag1, sp..color = sp.color.withValues(alpha: 0.6));
    canvas.drawRRect(tag2, p..color = p.color.withValues(alpha: 0.25));
    canvas.drawRRect(tag2, sp);

    // Lines representing text
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(s.width * 0.12, s.height * (0.35 + i * 0.12)),
        Offset(s.width * 0.36, s.height * (0.35 + i * 0.12)),
        sp..strokeWidth = 2..color = sp.color.withValues(alpha: 0.35),
      );
      canvas.drawLine(
        Offset(s.width * 0.63, s.height * (0.35 + i * 0.12)),
        Offset(s.width * 0.87, s.height * (0.35 + i * 0.12)),
        sp..strokeWidth = 2..color = sp.color.withValues(alpha: 0.5),
      );
    }

    // VS indicator
    final vsPaint = Paint()
      ..color = p.color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.5), s.width * 0.08, vsPaint);
  }

  void _drawBook(Canvas canvas, Size s, Paint p, Paint sp) {
    // Ticket shape
    final ticketPath = Path();
    ticketPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.1, s.height * 0.25, s.width * 0.8, s.height * 0.5),
      const Radius.circular(14),
    ));
    canvas.drawPath(ticketPath, p..color = p.color.withValues(alpha: 0.15));
    canvas.drawPath(ticketPath, sp);

    // Dashed center line
    final dashPaint = Paint()
      ..color = sp.color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (double x = s.width * 0.15; x < s.width * 0.85; x += 10) {
      canvas.drawLine(
        Offset(x, s.height * 0.5),
        Offset(x + 5, s.height * 0.5),
        dashPaint,
      );
    }

    // Check mark
    final checkPaint = Paint()
      ..color = p.color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path()
      ..moveTo(s.width * 0.35, s.height * 0.42)
      ..lineTo(s.width * 0.46, s.height * 0.55)
      ..lineTo(s.width * 0.65, s.height * 0.35);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
