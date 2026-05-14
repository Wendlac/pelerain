import 'trip.dart';
import 'passenger.dart';

enum ReservationStatus { pending, confirmed, cancelled, expired }

ReservationStatus _reservationStatusFromString(String? s) {
  switch (s) {
    case 'confirmed': return ReservationStatus.confirmed;
    case 'cancelled': return ReservationStatus.cancelled;
    case 'expired':   return ReservationStatus.expired;
    case 'pending':
    default:          return ReservationStatus.pending;
  }
}

String reservationStatusToString(ReservationStatus s) {
  switch (s) {
    case ReservationStatus.pending:   return 'pending';
    case ReservationStatus.confirmed: return 'confirmed';
    case ReservationStatus.cancelled: return 'cancelled';
    case ReservationStatus.expired:   return 'expired';
  }
}

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

  /// Builds a Reservation from a Supabase row. The [trip] (with its company)
  /// and [passengers] are resolved by the repository before calling this.
  factory Reservation.fromJson(
    Map<String, dynamic> json, {
    required Trip trip,
    required List<Passenger> passengers,
  }) =>
      Reservation(
        id: json['id'] as String,
        trip: trip,
        reservationCode: json['reservation_code'] as String,
        status: _reservationStatusFromString(json['status'] as String?),
        passengers: passengers,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : DateTime.parse(json['created_at'] as String)
                .add(const Duration(hours: 24)),
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      );

  int get seatsCount => passengers.length;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == ReservationStatus.pending || status == ReservationStatus.confirmed;
}
