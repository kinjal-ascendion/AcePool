/// The current user's profile doc, as streamed on the main Profile screen.
class ProfileSummary {
  const ProfileSummary({
    required this.fullName,
    required this.employeeId,
    this.phone,
    this.licenceVerified,
    this.licenceNumber,
    this.travelPreference,
    this.hasVehicles = false,
    this.ridesCompleted = 0,
  });

  final String fullName;
  final String employeeId;
  final String? phone;
  final bool? licenceVerified;
  final String? licenceNumber;
  final String? travelPreference;
  final bool hasVehicles;
  final int ridesCompleted;

  bool get isDriver =>
      travelPreference == 'drive' || travelPreference == 'both' || hasVehicles;

  bool get isRider =>
      travelPreference == 'ride' || travelPreference == 'both';

  String get initials => fullName.trim().isNotEmpty
      ? fullName
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join()
      : '?';
}
