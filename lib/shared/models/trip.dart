import 'company.dart';

enum TripStatus { active, cancelled, full }

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
