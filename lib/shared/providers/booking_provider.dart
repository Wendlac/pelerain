import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/passenger.dart';
import '../models/reservation.dart';

final selectedTripProvider = StateProvider<Trip?>((ref) => null);

final bookingPassengersProvider = StateProvider<List<Passenger>>((ref) => []);

final reservationsProvider = StateNotifierProvider<ReservationsNotifier, List<Reservation>>(
  (ref) => ReservationsNotifier(),
);

class ReservationsNotifier extends StateNotifier<List<Reservation>> {
  ReservationsNotifier() : super([]);

  final _uuid = const Uuid();

  Reservation createReservation({
    required Trip trip,
    required List<Passenger> passengers,
  }) {
    final code = _generateCode();
    final now = DateTime.now();
    final reservation = Reservation(
      id: _uuid.v4(),
      trip: trip,
      reservationCode: code,
      status: ReservationStatus.pending,
      passengers: passengers,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      totalPrice: trip.price * passengers.length,
    );
    state = [...state, reservation];
    return reservation;
  }

  void cancel(String reservationId) {
    state = state.map((r) {
      if (r.id == reservationId) {
        return Reservation(
          id: r.id,
          trip: r.trip,
          reservationCode: r.reservationCode,
          status: ReservationStatus.cancelled,
          passengers: r.passengers,
          createdAt: r.createdAt,
          expiresAt: r.expiresAt,
          totalPrice: r.totalPrice,
        );
      }
      return r;
    }).toList();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(5, (i) => chars[DateTime.now().microsecondsSinceEpoch % (i + 7) % chars.length]).join();
    return 'PEL-$random';
  }
}

final lastReservationProvider = Provider<Reservation?>((ref) {
  final reservations = ref.watch(reservationsProvider);
  if (reservations.isEmpty) return null;
  return reservations.last;
});
