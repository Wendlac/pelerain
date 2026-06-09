import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/search_provider.dart';

/// Loading screen between /home and /search-results.
///
/// Per MVP spec §3 Écran 1a: cream background, "Recherche de vos
/// trajets..." headline, and a looping Lottie animation
/// (assets/lottie/search_loading.json). The Lottie file is authored at
/// 60 fps over 240 frames (= 4 s loop) so it stays smooth even on the
/// slowest devices we target.
class SearchLoadingScreen extends ConsumerStatefulWidget {
  const SearchLoadingScreen({super.key});

  @override
  ConsumerState<SearchLoadingScreen> createState() =>
      _SearchLoadingScreenState();
}

class _SearchLoadingScreenState extends ConsumerState<SearchLoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  Future<void> _runSearch() async {
    final params = ref.read(searchParamsProvider);
    if (params == null) {
      if (mounted) context.go('/home');
      return;
    }

    // Keep the loading visible long enough for a full Lottie cycle to feel
    // like a deliberate "the app is thinking" moment, not a quick flicker.
    final minDelay = Future.delayed(const Duration(milliseconds: 1400));
    final search = ref.read(searchResultsProvider.notifier).search(params);
    await Future.wait([minDelay, search]);

    if (!mounted) return;
    context.pushReplacement('/search-results');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recherche de vos trajets...',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.content,
                letterSpacing: -0.5,
              ),
            ),
            const Gap(24),
            // Lottie picto (auto-plays + loops).
            SizedBox(
              width: 160,
              height: 160,
              child: Lottie.asset(
                'assets/lottie/search_loading.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
