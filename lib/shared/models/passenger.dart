enum PassengerType { adult, child, infant }

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

  String get fullName => '$firstName $lastName';

  String get typeLabel {
    switch (type) {
      case PassengerType.adult:  return 'Adulte';
      case PassengerType.child:  return 'Enfant';
      case PassengerType.infant: return 'Nourrisson';
    }
  }
}
