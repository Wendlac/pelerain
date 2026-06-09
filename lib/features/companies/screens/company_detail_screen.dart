import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/pelerain_app_bar.dart';
import '../../../shared/models/agency.dart';
import '../../../shared/models/company.dart';
import '../../../shared/providers/search_provider.dart';

/// Company detail — per MVP spec §3 Écran 4.
///
/// Sections:
/// 1. AppBar "Compagnie" + section title "Détails compagnie"
/// 2. Logo + company name card
/// 3. Description text
/// 4. Agencies grouped by city — each row has phone + WhatsApp round
///    buttons (cream background, dark icons)
/// 5. "Où nous trouver?" — map with yellow pins for each agency
/// 6. Bottom CTA "Rechercher un trajet" → /home
class CompanyDetailScreen extends ConsumerWidget {
  final Company company;
  const CompanyDetailScreen({super.key, required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pull the fully hydrated company (with agencies) from the cached list.
    final cached = ref.watch(companiesProvider).valueOrNull;
    final hydrated = cached?.firstWhere(
          (c) => c.id == company.id,
          orElse: () => company,
        ) ??
        company;

    final agenciesByCity = hydrated.agenciesByCity;
    final allAgencies = hydrated.agencies;
    final isLoadingAgencies =
        allAgencies.isEmpty && ref.watch(companiesProvider).isLoading;

    final mapCenter = allAgencies.isNotEmpty
        ? LatLng(
            allAgencies.map((a) => a.latitude).reduce((a, b) => a + b) /
                allAgencies.length,
            allAgencies.map((a) => a.longitude).reduce((a, b) => a + b) /
                allAgencies.length,
          )
        : const LatLng(12.3714, -1.5197);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PelerainAppBar(
            appBarTitle: 'Compagnie',
            sectionTitle: 'Détails compagnie',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CompanyHeaderCard(company: hydrated),
                  const Gap(28),

                  if (hydrated.description != null) ...[
                    _SectionLabel('Description'),
                    const Gap(8),
                    Text(
                      hydrated.description!,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.contentSecondary,
                        height: 1.55,
                      ),
                    ),
                    const Gap(28),
                  ],

                  _SectionLabel('Agences'),
                  const Gap(12),
                  if (isLoadingAgencies)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (agenciesByCity.isEmpty)
                    Text(
                      'Aucune agence référencée pour cette compagnie.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.contentTertiary,
                      ),
                    )
                  else
                    ...agenciesByCity.entries.map((entry) => _CityAgencyGroup(
                          city: entry.key,
                          agencies: entry.value,
                        )),

                  if (allAgencies.isNotEmpty) ...[
                    const Gap(28),
                    Text(
                      'Où nous trouver?',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.content,
                      ),
                    ),
                    const Gap(12),
                    _AgencyMap(
                      agencies: allAgencies,
                      center: mapCenter,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticService.medium();
                  context.go('/home');
                },
                icon: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 20,
                  color: AppColors.content,
                ),
                label: const Text('Rechercher un trajet'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-blocks ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.content,
      ),
    );
  }
}

class _CompanyHeaderCard extends StatelessWidget {
  final Company company;
  const _CompanyHeaderCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final initial = company.name.isNotEmpty
        ? company.name[0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.errorDark, width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.errorDark,
                ),
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Text(
              company.name,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.content,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityAgencyGroup extends StatelessWidget {
  final String city;
  final List<Agency> agencies;
  const _CityAgencyGroup({required this.city, required this.agencies});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            city,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.content,
            ),
          ),
          const Gap(8),
          ...agencies.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AgencyRow(agency: a),
              )),
        ],
      ),
    );
  }
}

class _AgencyRow extends StatelessWidget {
  final Agency agency;
  const _AgencyRow({required this.agency});

  Future<void> _call(BuildContext context) async {
    HapticService.medium();
    final uri = Uri(scheme: 'tel', path: agency.phone);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      _showCopiedToast(context, agency.phone);
    }
  }

  Future<void> _whatsapp(BuildContext context) async {
    HapticService.medium();
    final number = agency.whatsApp ?? agency.phone;
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showCopiedToast(context, number);
    }
  }

  void _showCopiedToast(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Numéro copié : $text'),
        backgroundColor: AppColors.content,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.local_gas_station_rounded,
          size: 20,
          color: AppColors.contentSecondary,
        ),
        const Gap(8),
        Expanded(
          child: Text(
            agency.name,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.content,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _ContactButton(
          icon: Icons.phone_rounded,
          onTap: () => _call(context),
        ),
        const Gap(10),
        _ContactButton(
          // Re-use a phone-like icon since lucide_react in Flutter doesn't
          // expose WhatsApp directly. Material's chat bubble does the trick.
          icon: Icons.chat_rounded,
          onTap: () => _whatsapp(context),
        ),
      ],
    );
  }
}

/// Round cream button with a dark icon — matches the contact buttons in
/// the maquette.
class _ContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceElevated,
        ),
        child: Icon(icon, size: 20, color: AppColors.content),
      ),
    );
  }
}

class _AgencyMap extends StatelessWidget {
  final List<Agency> agencies;
  final LatLng center;
  const _AgencyMap({required this.agencies, required this.center});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pelerain.pelerain',
            ),
            MarkerLayer(
              markers: agencies
                  .map((a) => Marker(
                        point: LatLng(a.latitude, a.longitude),
                        width: 32,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 36,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black26),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
