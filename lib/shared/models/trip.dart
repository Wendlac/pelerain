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
  final int availableSeats;
  final int totalSeats;
  final TripStatus status;
  final String? amenities;

  const Trip({
    required this.id,
    required this.company,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.totalSeats,
    this.status = TripStatus.active,
    this.amenities,
  });

  /// Builds a Trip from a Supabase row.
  /// The [company] must be provided separately (resolved by the caller from
  /// the trips join or from a separate companies fetch).
  factory Trip.fromJson(Map<String, dynamic> json, {required Company company}) {
    final seats = (json['available_seats'] as num?)?.toInt() ?? 0;
    return Trip(
      id: json['id'] as String,
      company: company,
      departureCity: json['departure_city'] as String,
      arrivalCity: json['arrival_city'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      price: (json['price'] as num).toDouble(),
      availableSeats: seats,
      // totalSeats isn't tracked in DB yet — fall back to availableSeats so the
      // UI keeps working. We can split it out in a later sprint.
      totalSeats: seats,
      status: _tripStatusFromString(json['status'] as String?),
      amenities: json['amenities'] as String?,
    );
  }

  Duration get duration => arrivalTime.difference(departureTime);

  String get durationLabel {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  bool get hasAvailableSeats => availableSeats > 0;
  bool get isAlmostFull => availableSeats > 0 && availableSeats <= 5;
}
