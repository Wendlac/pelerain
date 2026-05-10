import 'package:flutter/material.dart';

class SearchParams {
  final String departureCity;
  final String arrivalCity;
  final DateTime date;
  final TimeOfDay? departureTime;
  final int passengers;
  final bool isRoundTrip;
  final DateTime? returnDate;
  final TimeOfDay? returnTime;

  const SearchParams({
    required this.departureCity,
    required this.arrivalCity,
    required this.date,
    this.departureTime,
    required this.passengers,
    this.isRoundTrip = false,
    this.returnDate,
    this.returnTime,
  });

  SearchParams copyWith({
    String? departureCity,
    String? arrivalCity,
    DateTime? date,
    TimeOfDay? departureTime,
    int? passengers,
    bool? isRoundTrip,
    DateTime? returnDate,
    TimeOfDay? returnTime,
  }) {
    return SearchParams(
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      date: date ?? this.date,
      departureTime: departureTime ?? this.departureTime,
      passengers: passengers ?? this.passengers,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      returnDate: returnDate ?? this.returnDate,
      returnTime: returnTime ?? this.returnTime,
    );
  }
}
