import 'company.dart';

enum TripStatus { active, cancelled, full }

TripStatus _tripStatusFromString(String? s) {
  switch (s) {
    case 'cancelled': return TripStatus.cancelled;
    case 'completed': return TripStatus.full;
    case 'active':
    default:          return TripStatus.active;
  }
}

class Trip {
  final String id;
  final Company company;
  final String departureCity;
  final String arrivalCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final TripStatus status;
  final String? amenities;

  /// Minutes the traveler must be at the departure agency before the bus
  /// leaves ("heure de convocation"). Defaults to 30 — common practice for
  /// Burkina Faso intercity buses.
  final int boardingOffsetMinutes;

  const Trip({
    required this.id,
    required this.company,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    this.status = TripStatus.active,
    this.amenities,
    this.boardingOffsetMinutes = 30,
  });

  /// Projects a recurring `schedules` row onto a specific calendar [date]
  /// to produce the Trip the traveler will see on screen.
  ///
  /// Why this exists: we used to persist one row per (company × day × hour)
  /// in a `trips` table. That ballooned the DB and meant the agent had to
  /// re-enter every recurring departure — see commit message of M4.
  /// Now we only store one row per recurring template; the mobile builds
  /// concrete trips on the fly when the traveler picks a date.
  ///
  /// [scheduleRow] must include: id, departure_city, arrival_city,
  /// departure_time_local (HH:MM:SS), duration_minutes, price, amenities,
  /// boarding_offset_minutes, status.
  factory Trip.fromSchedule(
    Map<String, dynamic> scheduleRow, {
    required Company company,
    required DateTime date,
  }) {
    // Parse "HH:MM:SS" → hour + minute, then combine with the search date.
    final timeStr = scheduleRow['departure_time_local'] as String;
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;

    final departure = DateTime(
      date.year, date.month, date.day, hour, minute,
    );
    final durationMin = (scheduleRow['duration_minutes'] as num).toInt();
    final arrival = departure.add(Duration(minutes: durationMin));

    return Trip(
      id: scheduleRow['id'] as String,
      company: company,
      departureCity: scheduleRow['departure_city'] as String,
      arrivalCity: scheduleRow['arrival_city'] as String,
      departureTime: departure,
      arrivalTime: arrival,
      price: (scheduleRow['price'] as num).toDouble(),
      status: _tripStatusFromString(scheduleRow['status'] as String?),
      amenities: scheduleRow['amenities'] as String?,
      boardingOffsetMinutes:
          (scheduleRow['boarding_offset_minutes'] as num?)?.toInt() ?? 30,
    );
  }

  Duration get duration => arrivalTime.difference(departureTime);

  String get durationLabel {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  /// Time the traveler must be at the departure agency.
  /// = departureTime − boardingOffsetMinutes.
  DateTime get boardingTime =>
      departureTime.subtract(Duration(minutes: boardingOffsetMinutes));
}
