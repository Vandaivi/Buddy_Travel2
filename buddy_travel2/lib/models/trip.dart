// lib/models/trip.dart
class Trip {
  final String tripName;
  final String location;
  final String estimatedCost;
  final String numPeople;
  final String startDate;
  final String endDate;

  Trip({
    required this.tripName,
    required this.location,
    required this.estimatedCost,
    required this.numPeople,
    required this.startDate,
    required this.endDate,
  });
}
