import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/haptic_service.dart';

/// Reusable header used on every screen except the home/loading.
///
/// Renders the maquette pattern:
/// ```
/// ←      <appBarTitle>      (small, centered)
///
/// <sectionTitle>            (large, bold, left-aligned)
/// ```
///
/// The whole block sits at the very top of the page on the cream background.
/// It does NOT use Scaffold's `appBar` — it's a regular widget so the section
/// title can scroll with the content if the parent is a CustomScrollView.
class PelerainAppBar extends StatelessWidget {
  /// Short title shown in the centered chip ("Compagnie", "Voyages"...).
  final String appBarTitle;

  /// Big bold title shown below the back arrow row.
  final String sectionTitle;

  /// Override the back action. Defaults to `context.pop()`.
  final VoidCallback? onBack;

  const PelerainAppBar({
    super.key,
    required this.appBarTitle,
    required this.sectionTitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: back + centered title ─────────────────────────────
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            // Use a Row with mirrored spacers so the title is truly centered
            // while the back button stays anchored at the left. A previous
            // Stack + Positioned implementation rendered fine on mobile but
            // not on Flutter Web, hence this simpler layout.
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: canPop
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.content,
                            size: 24,
                          ),
                          onPressed: () {
                            HapticService.light();
                            if (onBack != null) {
                              onBack!();
                            } else {
                              context.pop();
                            }
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      appBarTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.content,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                // Mirror the back-button slot so the title stays centered.
                const SizedBox(width: 56),
              ],
            ),
          ),
        ),

        // ── Section title (Denk One display, uppercased) ──────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            sectionTitle.toUpperCase(),
            style: AppTextStyles.pageHeadline,
          ),
        ),
      ],
    );
  }
}
