enum BookingStatus { confirmed, cancelled }

/// A confirmed (or cancelled) appointment made by the customer.
class Booking {
  const Booking({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.coverSeed,
    required this.serviceNames,
    required this.staffName,
    required this.start,
    required this.totalDurationMinutes,
    required this.totalPrice,
    required this.status,
  });

  final String id;
  final String salonId;
  final String salonName;
  final String salonAddress;
  final int coverSeed;
  final List<String> serviceNames;

  /// Null means "any available professional".
  final String? staffName;

  final DateTime start;
  final int totalDurationMinutes;
  final double totalPrice;
  final BookingStatus status;

  DateTime get end => start.add(Duration(minutes: totalDurationMinutes));

  bool get isUpcoming =>
      status == BookingStatus.confirmed && end.isAfter(DateTime.now());

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        salonId: salonId,
        salonName: salonName,
        salonAddress: salonAddress,
        coverSeed: coverSeed,
        serviceNames: serviceNames,
        staffName: staffName,
        start: start,
        totalDurationMinutes: totalDurationMinutes,
        totalPrice: totalPrice,
        status: status ?? this.status,
      );
}
