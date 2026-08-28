/// A driver's profile stats shown in the "driver profile" dialog on the
/// Trips "Ride Requests" tab. Fallback values match the original hardcoded
/// placeholders used when a field is missing on the driver's user doc.
class DriverProfileStats {
  const DriverProfileStats({
    this.employeeId = 'ASC 2001922',
    this.completedRidesCount = 30,
    this.rating = 4.72,
    this.ratingCount = 15,
  });

  final String employeeId;
  final int completedRidesCount;
  final double rating;
  final int ratingCount;
}
