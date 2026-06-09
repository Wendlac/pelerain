import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';

/// MVP splash screen — per Pelerain_MVP_Specs.md §3 Écran 0.
///
/// Layout (top → bottom):
///   1. Pelerain wordmark logo (assets/images/pelerain_logo_black.png)
///   2. Animated Pelerain mascotte (assets/lottie/splash_mascot.json) — 8 px gap
///   3. Version number at the bottom
///
/// The whole screen sits on a warm cream background.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _appVersion = '1.0.0'; // TODO: pull from PackageInfo

  @override
  void initState() {
    super.initState();
    // Go straight to /home after the mascot has had time to play (~2.4 s).
    // No auth/onboarding in the MVP — the search screen is reachable
    // directly per spec §2.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Splash keeps the warmer cream; every other screen uses the lighter
      // AppColors.background.
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Center: logo on top, then mascotte (8 px gap) ──────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wordmark logo
                  Image.asset(
                    'assets/images/pelerain_logo_black.png',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),

                  // Lottie mascotte (auto-plays + loops)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Lottie.asset(
                      'assets/lottie/splash_mascot.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ],
              ),
            ),

            // ── Version footer ────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: Text(
                  'v$_appVersion',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.contentTertiary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
