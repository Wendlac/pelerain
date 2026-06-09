import 'agency.dart';

class Company {
  final String id;
  final String name;
  final String phone;
  final String? logoUrl;
  final double rating;
  final int totalTrips;
  final String? description;
  final List<Agency> agencies;

  /// Window (in hours) communicated to the traveler for paying at the
  /// agency before the seat is released. Used by the back-office only;
  /// the mobile MVP doesn't surface it but we keep the column hydrated.
  final int paymentWindowHours;

  const Company({
    required this.id,
    required this.name,
    required this.phone,
    this.logoUrl,
    this.rating = 4.0,
    this.totalTrips = 0,
    this.description,
    this.agencies = const [],
    this.paymentWindowHours = 5,
  });

  /// Build a Company from a Supabase row. Pass [agencies] separately if the
  /// query already joined them; otherwise the list starts empty and can be
  /// hydrated via `copyWith` after fetching from the agencies table.
  factory Company.fromJson(
    Map<String, dynamic> json, {
    List<Agency> agencies = const [],
  }) =>
      Company(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: (json['phone'] as String?) ?? '',
        logoUrl: json['logo_url'] as String?,
        rating: ((json['rating'] as num?) ?? 4.0).toDouble(),
        totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
        description: json['description'] as String?,
        agencies: agencies,
        paymentWindowHours:
            (json['payment_window_hours'] as num?)?.toInt() ?? 5,
      );

  Company copyWith({List<Agency>? agencies}) => Company(
        id: id,
        name: name,
        phone: phone,
        logoUrl: logoUrl,
        rating: rating,
        totalTrips: totalTrips,
        description: description,
        agencies: agencies ?? this.agencies,
        paymentWindowHours: paymentWindowHours,
      );

  /// Returns agencies grouped by city: { 'Ouagadougou': [...], 'Bobo-Dioulasso': [...] }
  Map<String, List<Agency>> get agenciesByCity {
    final map = <String, List<Agency>>{};
    for (final a in agencies) {
      map.putIfAbsent(a.city, () => []).add(a);
    }
    return map;
  }
}
