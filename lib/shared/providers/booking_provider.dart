import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip.dart';
import '../models/passenger.dart';
import '../models/reservation.dart';
import 'supabase_provider.dart';

/// Trip selected for booking (persists across screens during the booking flow).
final selectedTripProvider = StateProvider<Trip?>((ref) => null);

/// Passengers being filled in the booking form.
final bookingPassengersProvider = StateProvider<List<Passenger>>((ref) => []);

/// User's reservations, fetched from Supabase. Auto-refetches whenever the
/// auth state changes (so logging out clears it, logging in loads it).
final reservationsProvider =
    AsyncNotifierProvider<ReservationsNotifier, List<Reservation>>(
  ReservationsNotifier.new,
);

class ReservationsNotifier extends AsyncNotifier<List<Reservation>> {
  @override
  Future<List<Reservation>> build() async {
    // Re-run this whenever auth changes
    ref.watch(currentUserIdProvider);
    final repo = ref.watch(supabaseRepositoryProvider);
    return repo.fetchMyReservations();
  }

  /// Creates a reservation, persists it, then refreshes local state.
  Future<Reservation> createReservation({
    required Trip trip,
    required List<Passenger> passengers,
  }) async {
    final repo = ref.read(supabaseRepositoryProvider);
    final reservation = await repo.createReservation(
      trip: trip,
      passengers: passengers,
    );
    // Optimistic update — prepend the new reservation locally
    final current = state.valueOrNull ?? const <Reservation>[];
    state = AsyncValue.data([reservation, ...current]);
    return reservation;
  }

  /// Cancels a reservation by id.
  Future<void> cancel(String reservationId) async {
    final repo = ref.read(supabaseRepositoryProvider);
    await repo.cancelReservation(reservationId);

    // Update local state without re-fetching: flip the status in place
    final current = state.valueOrNull ?? const <Reservation>[];
    state = AsyncValue.data([
      for (final r in current)
        if (r.id == reservationId)
          Reservation(
            id: r.id,
            trip: r.trip,
            reservationCode: r.reservationCode,
            status: ReservationStatus.cancelled,
            passengers: r.passengers,
            createdAt: r.createdAt,
            expiresAt: r.expiresAt,
            totalPrice: r.totalPrice,
          )
        else
          r,
    ]);
  }

  /// Force a re-fetch from Supabase.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(supabaseRepositoryProvider);
      return repo.fetchMyReservations();
    });
  }
}

/// Convenience: the most recently created reservation (or null).
final lastReservationProvider = Provider<Reservation?>((ref) {
  final reservations = ref.watch(reservationsProvider).valueOrNull;
  if (reservations == null || reservations.isEmpty) return null;
  return reservations.first; // already ordered desc by created_at
});
