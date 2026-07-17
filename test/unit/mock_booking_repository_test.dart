import 'package:beautyhub/data/repositories/mock_booking_repository.dart';
import 'package:beautyhub/domain/entities/booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockBookingRepository', () {
    test('creates and lists a booking', () async {
      final repo = MockBookingRepository();
      final start = DateTime.now().add(const Duration(days: 1));
      final created = await repo.createBooking(
        Booking(
          id: '',
          salonId: 'salon-velvet',
          salonName: 'Velvet & Vine Studio',
          salonAddress: '12 Rosewood Ave',
          coverSeed: 0,
          serviceNames: const ['Blowout'],
          staffName: null,
          start: start,
          totalDurationMinutes: 45,
          totalPrice: 30,
          status: BookingStatus.confirmed,
        ),
      );

      expect(created.id, isNotEmpty);
      final bookings = await repo.getBookings();
      expect(bookings.any((b) => b.id == created.id), isTrue);
    });

    test('cancelling flips status', () async {
      final repo = MockBookingRepository();
      final created = await repo.createBooking(
        Booking(
          id: '',
          salonId: 's',
          salonName: 'S',
          salonAddress: 'A',
          coverSeed: 0,
          serviceNames: const ['X'],
          staffName: null,
          start: DateTime.now().add(const Duration(days: 2)),
          totalDurationMinutes: 30,
          totalPrice: 10,
          status: BookingStatus.confirmed,
        ),
      );
      await repo.cancelBooking(created.id);
      final bookings = await repo.getBookings();
      final cancelled = bookings.firstWhere((b) => b.id == created.id);
      expect(cancelled.status, BookingStatus.cancelled);
      expect(cancelled.isUpcoming, isFalse);
    });

    test('slots exclude times conflicting with confirmed bookings', () async {
      final repo = MockBookingRepository();
      final day = DateTime.now().add(const Duration(days: 3));
      final slots = await repo.getAvailableSlots(
        salonId: 'salon-velvet',
        day: day,
        durationMinutes: 60,
      );
      expect(slots, isNotEmpty);
      expect(slots.every((s) => s.hour >= 9 && s.hour < 19), isTrue);
    });
  });
}
