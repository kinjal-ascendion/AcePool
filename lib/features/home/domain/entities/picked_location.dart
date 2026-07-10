import 'package:equatable/equatable.dart';

/// Result returned by LocationSearchPage when the user picks an address.
/// lat/lng are nullable because the geocoding API can omit or return
/// malformed coordinates for a given result.
class PickedLocation extends Equatable {
  final String address;
  final double? lat;
  final double? lng;

  const PickedLocation({required this.address, this.lat, this.lng});

  @override
  List<Object?> get props => [address, lat, lng];
}
