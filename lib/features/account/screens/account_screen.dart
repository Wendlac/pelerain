import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationsProvider);
    final totalSpent = reservations.fold<double>(0, (s, r) => s + r.totalPrice);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ── Top bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Modifier le profil',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Avatar + name ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  children: [
                    // Avatar with camera badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'VP',
                              style: GoogleFonts.dmSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.content,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Gap(20),

                    // Large ALL-CAPS name
                    Text(
                      'VOYAGEUR\nPELERAIN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppColors.content,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),

                    const Gap(8),

                    // Subtitle
                    Text(
                      'Compte personnel',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.contentTertiary,
                      ),
                    ),

                    const Gap(32),
                    const Divider(color: Color(0xFFF0F0F0), height: 1),
                  ],
                ),
              ),
            ),

            // ── Votre compte section ──
            SliverToBoxAdapter(
              child: _MenuSection(
                title: 'Votre compte',
                items: [
                  _MenuEntry(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Mes réservations',
                    badge: reservations.isNotEmpty
                        ? '${reservations.length}'
                        : null,
                    onTap: () {},
                  ),
                  _MenuEntry(
                    icon: Icons.payments_outlined,
                    label: 'Total dépensé',
                    subtitle: totalSpent > 0
                        ? Formatters.price(totalSpent)
                        : 'Aucune dépense',
                    onTap: () {},
                  ),
                  _MenuEntry(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Color(0xFFF0F0F0), height: 1),
              ),
            ),

            // ── Paramètres section ──
            SliverToBoxAdapter(
              child: _MenuSection(
                title: 'Paramètres',
                items: [
                  _MenuEntry(
                    icon: Icons.language_rounded,
                    label: 'Langue',
                    subtitle: 'Français',
                    onTap: () {},
                  ),
                  _MenuEntry(
                    icon: Icons.dark_mode_outlined,
                    label: 'Thème',
                    subtitle: 'Clair',
                    onTap: () {},
                  ),
                  _MenuEntry(
                    icon: Icons.security_outlined,
                    label: 'Sécurité et confidentialité',
                    subtitle: 'Gérez vos préférences de sécurité',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Color(0xFFF0F0F0), height: 1),
              ),
            ),

            // ── Aide section ──
            SliverToBoxAdapter(
              child: _MenuSection(
                title: 'Aide',
                items: [
                  _MenuEntry(
                    icon: Icons.help_outline_rounded,
                    label: 'Centre d\'aide & FAQ',
                    onTap: () {},
                  ),
                  _MenuEntry(
                    icon: Icons.mail_outline_rounded,
                    label: 'Nous contacter',
                    subtitle: 'contact@pelerain.com',
                    onTap: () {},
                  ),
                  _MenuEntry(
                    icon: Icons.info_outline_rounded,
                    label: 'À propos de Pelerain',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Bottom padding for floating nav
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuEntry> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.content,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(8),
          ...items.map((item) => _MenuRow(entry: item)),
        ],
      ),
    );
  }
}

// ─── Menu Row ─────────────────────────────────────────────────────────────────

class _MenuEntry {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MenuEntry({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    required this.onTap,
  });
}

class _MenuRow extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: entry.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Outline circle icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Icon(
                entry.icon,
                size: 20,
                color: AppColors.content,
              ),
            ),
            const Gap(16),

            // Label + optional subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.content,
                    ),
                  ),
                  if (entry.subtitle != null) ...[
                    const Gap(2),
                    Text(
                      entry.subtitle!,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.contentTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge or chevron
            if (entry.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  entry.badge!,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFAAAAAA),
              ),
          ],
        ),
      ),
    );
  }
}

