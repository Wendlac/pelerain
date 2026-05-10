class Agency {
  final String name;
  final String city;
  final String phone;
  final String? whatsApp;
  final double latitude;
  final double longitude;

  const Agency({
    required this.name,
    required this.city,
    required this.phone,
    this.whatsApp,
    required this.latitude,
    required this.longitude,
  });
}
