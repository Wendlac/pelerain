import 'trip.dart';
import 'passenger.dart';

enum ReservationStatus { pending, confirmed, cancelled, expired }

class Reservation {
  final String id;
  final Trip trip;
  final String reservationCode;
  final ReservationStatus status;
  final List<Passenger> passengers;
  final DateTime createdAt;
  final DateTime expiresAt;
  final double totalPrice;

  const Reservation({
    required this.id,
    required this.trip,
    required this.reservationCode,
    required this.status,
    required this.passengers,
    required this.createdAt,
    required this.expiresAt,
    required this.totalPrice,
  });

  int get seatsCount => passengers.length;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == ReservationStatus.pending || status == ReservationStatus.confirmed;
}
