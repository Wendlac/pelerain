enum PassengerType { adult, child, infant }

PassengerType _passengerTypeFromString(String? s) {
  switch (s) {
    case 'child':  return PassengerType.child;
    case 'infant': return PassengerType.infant;
    case 'adult':
    default:       return PassengerType.adult;
  }
}

String _passengerTypeToString(PassengerType t) {
  switch (t) {
    case PassengerType.adult:  return 'adult';
    case PassengerType.child:  return 'child';
    case PassengerType.infant: return 'infant';
  }
}

class Passenger {
  final String firstName;
  final String lastName;
  final PassengerType type;
  final int? age;

  const Passenger({
    required this.firstName,
    required this.lastName,
    required this.type,
    this.age,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        type: _passengerTypeFromString(json['type'] as String?),
      );

  /// Used when inserting passengers along with a reservation.
  Map<String, dynamic> toInsertJson({required String reservationId, int? seatNumber}) => {
        'reservation_id': reservationId,
        'first_name': firstName,
        'last_name': lastName,
        'type': _passengerTypeToString(type),
        if (seatNumber != null) 'seat_number': seatNumber,
      };

  String get fullName => '$firstName $lastName';

  String get typeLabel {
    switch (type) {
      case PassengerType.adult:  return 'Adulte';
      case PassengerType.child:  return 'Enfant';
      case PassengerType.infant: return 'Nourrisson';
    }
  }
}
