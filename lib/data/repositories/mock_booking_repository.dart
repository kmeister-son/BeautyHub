import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

/// In-memory booking store. Slots are generated deterministically so the
/// same day always shows the same availability during a session.
class MockBookingRepository implements BookingRepository {
  MockBookingRepository() {
    final now = DateTime.now();
    _bookings.add(
      Booking(
        id: 'bk-seed-1',
        salonId: 'salon-kings',
        salonName: "King's Chair Barbershop",
        salonAddress: '48 Meridian St, Old Town',
        coverSeed: 1,
        serviceNames: const ['Skin Fade'],
        staffName: 'Marcus Dube',
        start: DateTime(now.year, now.month, now.day, 11).subtract(const Duration(days: 12)),
        totalDurationMinutes: 45,
        totalPrice: 25,
        status: BookingStatus.confirmed,
      ),
    );
  }

  static const _latency = Duration(milliseconds: 350);

  final List<Booking> _bookings = [];
  int _idCounter = 0;

  @override
  Future<List<Booking>> getBookings() async {
    await Future<void>.delayed(_latency);
    final sorted = [..._bookings]..sort((a, b) => b.start.compareTo(a.start));
    return List.unmodifiable(sorted);
  }

  @override
  Future<List<DateTime>> getAvailableSlots({
    required String salonId,
    required DateTime day,
    required int durationMinutes,
    String? staffId,
  }) async {
    await Future<void>.delayed(_latency);
    // Business hours are part of the salon aggregate; the mock uses a
    // typical 9–19 window and thins slots out pseudo-randomly.
    const openHour = 9;
    const closeHour = 19;
    final now = DateTime.now();
    final slots = <DateTime>[];
    var slot = DateTime(day.year, day.month, day.day, openHour);
    final lastStart = DateTime(day.year, day.month, day.day, closeHour)
        .subtract(Duration(minutes: durationMinutes));
    var index = 0;
    while (!slot.isAfter(lastStart)) {
      final seed = Object.hash(salonId, staffId ?? 'any', day.day, day.month, index);
      final isTaken = seed % 10 < 3;
      final conflictsWithBooking = _bookings.any((b) =>
          b.status == BookingStatus.confirmed &&
          b.salonId == salonId &&
          slot.isBefore(b.end) &&
          b.start.isBefore(slot.add(Duration(minutes: durationMinutes))));
      if (!isTaken && !conflictsWithBooking && slot.isAfter(now)) {
        slots.add(slot);
      }
      slot = slot.add(const Duration(minutes: 30));
      index++;
    }
    return slots;
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    await Future<void>.delayed(_latency);
    final created = Booking(
      id: 'bk-${++_idCounter}',
      salonId: booking.salonId,
      salonName: booking.salonName,
      salonAddress: booking.salonAddress,
      coverSeed: booking.coverSeed,
      serviceNames: booking.serviceNames,
      staffName: booking.staffName,
      start: booking.start,
      totalDurationMinutes: booking.totalDurationMinutes,
      totalPrice: booking.totalPrice,
      status: BookingStatus.confirmed,
    );
    _bookings.add(created);
    return created;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await Future<void>.delayed(_latency);
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw StateError('Booking not found: $bookingId');
    _bookings[index] = _bookings[index].copyWith(status: BookingStatus.cancelled);
  }
}
