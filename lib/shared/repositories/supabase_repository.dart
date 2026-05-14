import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agency.dart';
import '../models/company.dart';
import '../models/trip.dart';
import '../models/passenger.dart';
import '../models/reservation.dart';

/// Centralised data access layer for Supabase.
///
/// All providers should go through this repository instead of calling
/// `supabase.from(...)` directly — that way the schema is documented in
/// one place and we can swap the backend later if needed.
class SupabaseRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  // ─── Companies ──────────────────────────────────────────────────────────

  /// Fetches all companies with their agencies attached (one query each).
  /// For a catalogue of this size (a few dozen rows) the extra round-trips
  /// are negligible and the code stays simple.
  Future<List<Company>> fetchCompanies() async {
    final companyRows = await _client
        .from('companies')
        .select()
        .order('name');

    final agencyRows = await _client
        .from('agencies')
        .select()
        .order('city');

    final agenciesByCompany = <String, List<Agency>>{};
    for (final row in agencyRows as List) {
      final json = row as Map<String, dynamic>;
      final companyId = json['company_id'] as String;
      (agenciesByCompany[companyId] ??= []).add(Agency.fromJson(json));
    }

    return (companyRows as List)
        .map((row) {
          final json = row as Map<String, dynamic>;
          return Company.fromJson(
            json,
            agencies: agenciesByCompany[json['id']] ?? const [],
          );
        })
        .toList();
  }

  /// Fetches a single company by id, with agencies populated.
  Future<Company?> fetchCompany(String id) async {
    final row = await _client
        .from('companies')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    final agencyRows = await _client
        .from('agencies')
        .select()
        .eq('company_id', id)
        .order('city');

    final agencies = (agencyRows as List)
        .map((r) => Agency.fromJson(r as Map<String, dynamic>))
        .toList();

    return Company.fromJson(row, agencies: agencies);
  }

  // ─── Trips ──────────────────────────────────────────────────────────────

  /// Searches active trips matching the criteria.
  /// [date] filters trips departing on that calendar day (00:00 → 23:59 local).
  Future<List<Trip>> searchTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await _client
        .from('trips')
        .select('*, companies(*)')
        .ilike('departure_city', departureCity)
        .ilike('arrival_city', arrivalCity)
        .gte('departure_time', dayStart.toIso8601String())
        .lt('departure_time', dayEnd.toIso8601String())
        .eq('status', 'active')
        .order('departure_time');

    return _hydrateTrips(rows as List);
  }

  /// Fetches all upcoming trips (no city/date filter) — used for "explore" UIs.
  Future<List<Trip>> fetchUpcomingTrips({int limit = 20}) async {
    final rows = await _client
        .from('trips')
        .select('*, companies(*)')
        .gte('departure_time', DateTime.now().toIso8601String())
        .eq('status', 'active')
        .order('departure_time')
        .limit(limit);

    return _hydrateTrips(rows as List);
  }

  List<Trip> _hydrateTrips(List rows) {
    return rows.map((row) {
      final json = row as Map<String, dynamic>;
      final companyJson = json['companies'] as Map<String, dynamic>;
      final company = Company.fromJson(companyJson);
      return Trip.fromJson(json, company: company);
    }).toList();
  }

  // ─── Reservations ───────────────────────────────────────────────────────

  /// Fetches the current user's reservations (newest first), with the joined
  /// trip+company and the passenger list.
  Future<List<Reservation>> fetchMyReservations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('reservations')
        .select('*, trips(*, companies(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final reservationsList = rows as List;
    if (reservationsList.isEmpty) return [];

    // Batch-fetch passengers for all returned reservations
    final reservationIds =
        reservationsList.map((r) => (r as Map)['id'] as String).toList();
    final passengerRows = await _client
        .from('passengers')
        .select()
        .inFilter('reservation_id', reservationIds);

    final passengersByReservation = <String, List<Passenger>>{};
    for (final row in passengerRows as List) {
      final json = row as Map<String, dynamic>;
      final rid = json['reservation_id'] as String;
      (passengersByReservation[rid] ??= []).add(Passenger.fromJson(json));
    }

    return reservationsList.map((row) {
      final json = row as Map<String, dynamic>;
      final tripJson = json['trips'] as Map<String, dynamic>;
      final companyJson = tripJson['companies'] as Map<String, dynamic>;
      final company = Company.fromJson(companyJson);
      final trip = Trip.fromJson(tripJson, company: company);
      return Reservation.fromJson(
        json,
        trip: trip,
        passengers: passengersByReservation[json['id']] ?? const [],
      );
    }).toList();
  }

  /// Creates a reservation + passenger rows. Returns the freshly created
  /// reservation hydrated with the trip & passenger data.
  ///
  /// Throws if the user isn't authenticated or if RLS rejects the insert.
  Future<Reservation> createReservation({
    required Trip trip,
    required List<Passenger> passengers,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot create a reservation without being logged in.');
    }

    final code = _generateReservationCode();
    final totalPrice = trip.price * passengers.length;
    final now = DateTime.now();
    // Pay-at-agency window is per-company (default 5h). If the trip itself
    // departs sooner, cap the window at the departure time — no point letting
    // someone pay after their bus is gone.
    final companyWindow = Duration(hours: trip.company.paymentWindowHours);
    final cap = trip.departureTime.isBefore(now.add(companyWindow))
        ? trip.departureTime
        : now.add(companyWindow);
    final expiresAt = cap;

    // Insert reservation
    final reservationRow = await _client
        .from('reservations')
        .insert({
          'trip_id': trip.id,
          'user_id': userId,
          'reservation_code': code,
          'status': 'pending',
          'seats': passengers.length,
          'total_price': totalPrice,
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    final reservationId = reservationRow['id'] as String;

    // Insert passengers (if any)
    if (passengers.isNotEmpty) {
      final passengerInserts = [
        for (var i = 0; i < passengers.length; i++)
          passengers[i].toInsertJson(
            reservationId: reservationId,
            seatNumber: i + 1,
          ),
      ];
      await _client.from('passengers').insert(passengerInserts);
    }

    return Reservation.fromJson(
      reservationRow,
      trip: trip,
      passengers: passengers,
    );
  }

  /// Cancels a reservation owned by the current user.
  Future<void> cancelReservation(String reservationId) async {
    await _client
        .from('reservations')
        .update({'status': 'cancelled'})
        .eq('id', reservationId);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Generates a short reservation code like `PEL-A8X3Q`.
  String _generateReservationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // skip ambiguous chars
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = List.generate(
      5,
      (i) => chars[(now ~/ (i + 7)) % chars.length],
    ).join();
    return 'PEL-$random';
  }
}
