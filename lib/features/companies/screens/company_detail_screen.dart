import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/models/agency.dart';
import '../../../shared/models/company.dart';
import '../../../shared/providers/search_provider.dart';

class CompanyDetailScreen extends ConsumerWidget {
  final Company company;
  const CompanyDetailScreen({super.key, required this.company});

  /// Color per company initial (brand feel)
  Color get _logoColor {
    switch (company.id) {
      case 'tsr-001':     return const Color(0xFF761CEA);
      case 'rakieta-001': return const Color(0xFF2BD9FE);
      case 'stmb-001':    return const Color(0xFF20BF55);
      case 'tgb-001':     return const Color(0xFFFFE45E);
      case 'confort-001': return const Color(0xFFFF6B35);
      default:            return AppColors.primary;
    }
  }

  Color get _logoTextColor {
    if (company.id == 'tgb-001') return AppColors.content;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The `company` passed via go_router comes from a trip's join, which
    // doesn't include the agencies (separate table). Look it up in the
    // cached companies list — that one has agencies populated.
    final cached = ref.watch(companiesProvider).valueOrNull;
    final hydrated = cached
            ?.firstWhere(
              (c) => c.id == company.id,
              orElse: () => company,
            ) ??
        company;
    final displayCompany = hydrated;

    final agenciesByCity = displayCompany.agenciesByCity;
    final allAgencies = displayCompany.agencies;
    final isLoadingAgencies =
        allAgencies.isEmpty && ref.watch(companiesProvider).isLoading;

    final mapCenter = allAgencies.isNotEmpty
        ? LatLng(
            allAgencies.map((a) => a.latitude).reduce((a, b) => a + b) /
                allAgencies.length,
            allAgencies.map((a) => a.longitude).reduce((a, b) => a + b) /
                allAgencies.length,
          )
        : const LatLng(12.3714, -1.5197); // Default: Ouagadougou

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.content),
              onPressed: () {
                HapticService.light();
                context.pop();
              },
            ),
            title: Row(
              children: [
                _CompanyLogo(
                  name: displayCompany.name,
                  color: _logoColor,
                  textColor: _logoTextColor,
                  size: 32,
                  fontSize: 13,
                ),
                const Gap(10),
                Text(
                  displayCompany.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.content,
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Rating banner ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      // Stars
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < displayCompany.rating.floor()
                              ? Icons.star_rounded
                              : (i < displayCompany.rating
                                  ? Icons.star_half_rounded
                                  : Icons.star_border_rounded),
                          size: 16,
                          color: AppColors.warning,
                        )),
                      ),
                      const Gap(6),
                      Text(
                        displayCompany.rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.content,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '· ${displayCompany.totalTrips} trajets effectués',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.contentTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppColors.divider, height: 1),
                const Gap(20),

                // ── Description ──
                if (displayCompany.description != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: AppTextStyles.headingXS),
                        const Gap(10),
                        Text(
                          displayCompany.description!,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.contentSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(28),
                ],

                // ── Agencies grouped by city ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Agences', style: AppTextStyles.headingXS),
                ),
                const Gap(12),

                if (isLoadingAgencies)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (agenciesByCity.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Aucune agence référencée pour cette compagnie.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.contentTertiary,
                      ),
                    ),
                  )
                else
                  ...agenciesByCity.entries.map((entry) => _CityAgencyGroup(
                        city: entry.key,
                        agencies: entry.value,
                        logoColor: _logoColor,
                      )),
                const Gap(28),

                // ── Map ──
                if (allAgencies.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Où nous trouver?', style: AppTextStyles.headingXS),
                  ),
                  const Gap(12),
                  _AgencyMap(
                    agencies: allAgencies,
                    center: mapCenter,
                    logoColor: _logoColor,
                  ),
                  const Gap(40),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Company Logo ────────────────────────────────────────────────────────────

class _CompanyLogo extends StatelessWidget {
  final String name;
  final Color color;
  final Color textColor;
  final double size;
  final double fontSize;

  const _CompanyLogo({
    required this.name,
    required this.color,
    required this.textColor,
    this.size = 48,
    this.fontSize = 18,
  });

  String get _initials {
    final words = name.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.dmSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─── City + Agencies group ───────────────────────────────────────────────────

class _CityAgencyGroup extends StatelessWidget {
  final String city;
  final List<Agency> agencies;
  final Color logoColor;

  const _CityAgencyGroup({
    required this.city,
    required this.agencies,
    required this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            city,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.content,
            ),
          ),
        ),
        ...agencies.map((agency) => _AgencyRow(
          agency: agency,
          accentColor: logoColor,
        )),
        const Gap(16),
      ],
    );
  }
}

// ─── Agency Row ───────────────────────────────────────────────────────────────

class _AgencyRow extends StatelessWidget {
  final Agency agency;
  final Color accentColor;

  const _AgencyRow({required this.agency, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Building icon
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 20,
            color: AppColors.contentTertiary,
          ),
          const Gap(12),

          // Agency name
          Expanded(
            child: Text(
              agency.name,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.content,
              ),
            ),
          ),

          // Phone button
          _ActionBtn(
            icon: Icons.phone_rounded,
            color: AppColors.primary,
            onTap: () {
              HapticService.medium();
              Clipboard.setData(ClipboardData(text: agency.phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${agency.phone} copié'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Gap(10),

          // WhatsApp button
          if (agency.whatsApp != null)
            _ActionBtn(
              icon: Icons.chat_rounded,
              color: AppColors.secondary,
              onTap: () {
                HapticService.medium();
                Clipboard.setData(ClipboardData(text: agency.whatsApp!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('WhatsApp ${agency.whatsApp} copié'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ─── Agency Map ───────────────────────────────────────────────────────────────

class _AgencyMap extends StatelessWidget {
  final List<Agency> agencies;
  final LatLng center;
  final Color logoColor;

  const _AgencyMap({
    required this.agencies,
    required this.center,
    required this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 280,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pelerain.app',
              ),
              MarkerLayer(
                markers: agencies.map((agency) => Marker(
                  point: LatLng(agency.latitude, agency.longitude),
                  width: 36,
                  height: 36,
                  child: _MapPin(color: logoColor),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  const _MapPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.store_mall_directory_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
        // Pin tail
        Container(
          width: 2,
          height: 6,
          color: color,
        ),
      ],
    );
  }
}
