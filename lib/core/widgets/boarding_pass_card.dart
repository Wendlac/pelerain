import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';
import '../../shared/models/trip.dart';

/// The card used on the search results and trip detail screens.
///
/// Looks like a boarding pass with a vertical dashed strip down the left edge
/// (purely decorative). Inside the card body:
/// - company logo + name
/// - departure date
/// - large price
/// - two stacked time rows linked by a dashed vertical between two dots:
///     • outline circle for departure
///     • filled green circle for arrival
///   each row shows the time, "Heure de convocation HH:MM" under the
///   departure row only, and a cream pill labelled with the city name.
///
/// Toggle `compact: true` to render slightly tighter spacings — used in the
/// results list to fit more cards on screen.
class BoardingPassCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final bool compact;

  const BoardingPassCard({
    super.key,
    required this.trip,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashed strip on the left edge
              _DashedStrip(
                color: AppColors.contentDisabled.withValues(alpha: 0.5),
              ),
              const Gap(8),

              // Body
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    compact ? 18 : 20,
                    20,
                    compact ? 18 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompanyRow(trip: trip),
                      Gap(compact ? 14 : 16),
                      _DateAndPrice(trip: trip, compact: compact),
                      Gap(compact ? 14 : 18),
                      _TimeRows(trip: trip),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Decorative dashed left strip ───────────────────────────────────────────

class _DashedStrip extends StatelessWidget {
  final Color color;
  const _DashedStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: 1.5,
        child: CustomPaint(
          painter: _VerticalDashedLinePainter(color: color),
        ),
      ),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  const _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dash = 5.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Sub-blocks ─────────────────────────────────────────────────────────────

class _CompanyRow extends StatelessWidget {
  final Trip trip;
  const _CompanyRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final initial = trip.company.name.isNotEmpty
        ? trip.company.name[0].toUpperCase()
        : '?';
    return Row(
      children: [
        // Yellow disc logo with first letter (used as placeholder until each
        // company gets an actual logo asset in the back-office).
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.errorDark, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.errorDark,
              ),
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Text(
            trip.company.name,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.content,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DateAndPrice extends StatelessWidget {
  final Trip trip;
  final bool compact;
  const _DateAndPrice({required this.trip, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Formatters.dateLong(trip.departureTime),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.content,
          ),
        ),
        const Gap(6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.priceAmount(trip.price),
              style: GoogleFonts.dmSans(
                fontSize: compact ? 36 : 42,
                fontWeight: FontWeight.w900,
                color: AppColors.content,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'FCFA',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.contentSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeRows extends StatelessWidget {
  final Trip trip;
  const _TimeRows({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical dot rail
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            children: [
              // Departure: outline ring
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.contentTertiary,
                    width: 2,
                  ),
                ),
              ),
              SizedBox(
                height: 64,
                child: CustomPaint(
                  size: const Size(2, 64),
                  painter: _VerticalDashedLinePainter(
                    color: AppColors.contentDisabled,
                  ),
                ),
              ),
              // Arrival: filled green
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const Gap(12),

        // Times + cities
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeRow(
                time: Formatters.time(trip.departureTime),
                cityLabel: trip.departureCity,
                boardingTime: Formatters.time(trip.boardingTime),
              ),
              const Gap(18),
              _TimeRow(
                time: Formatters.time(trip.arrivalTime),
                cityLabel: trip.arrivalCity,
                boardingTime: null, // arrival shows no convocation
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String time;
  final String cityLabel;
  final String? boardingTime;
  const _TimeRow({
    required this.time,
    required this.cityLabel,
    this.boardingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Time + convocation block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.content,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
              if (boardingTime != null) ...[
                const Gap(4),
                Text(
                  'Heure de convocation',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.contentSecondary,
                  ),
                ),
                Text(
                  boardingTime!,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.content,
                  ),
                ),
              ],
            ],
          ),
        ),
        // City pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            cityLabel,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.content,
            ),
          ),
        ),
      ],
    );
  }
}
