class Agency {
  final String id;
  final String name;
  final String city;
  final String phone;
  final String? whatsApp;
  final double latitude;
  final double longitude;

  const Agency({
    this.id = '',
    required this.name,
    required this.city,
    required this.phone,
    this.whatsApp,
    required this.latitude,
    required this.longitude,
  });

  factory Agency.fromJson(Map<String, dynamic> json) => Agency(
        id: json['id'] as String? ?? '',
        name: json['name'] as String,
        city: json['city'] as String,
        phone: json['phone'] as String,
        whatsApp: json['whatsapp'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
