import '../entities/booking.dart';

/// Contract for appointment availability and booking management.
abstract interface class BookingRepository {
  Future<List<Booking>> getBookings();

  /// Available start times at [salonId] on [day] for an appointment of
  /// [durationMinutes], optionally constrained to one professional.
  Future<List<DateTime>> getAvailableSlots({
    required String salonId,
    required DateTime day,
    required int durationMinutes,
    String? staffId,
  });

  Future<Booking> createBooking(Booking booking);

  Future<void> cancelBooking(String bookingId);
}
