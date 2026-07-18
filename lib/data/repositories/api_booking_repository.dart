import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../api/api_client.dart';
import '../api/api_mappers.dart';

/// [BookingRepository] backed by the beautyhub-api service. Identity is the
/// install's guest user; the [ApiClient] provisions it on first use.
class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Booking>> getBookings() async {
    final json =
        await _client.get('/bookings', authenticated: true) as List<dynamic>;
    return json.map((b) => ApiMappers.booking(b as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DateTime>> getAvailableSlots({
    required String salonId,
    required DateTime day,
    required int durationMinutes,
    String? staffId,
  }) async {
    final date = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final json = await _client.get(
      '/salons/$salonId/availability',
      query: {
        'date': date,
        'durationMinutes': '$durationMinutes',
        if (staffId != null) 'staffId': staffId,
      },
    ) as List<dynamic>;
    return json.map((s) => DateTime.parse(s as String).toLocal()).toList();
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    final json = await _client.post('/bookings', body: {
      'salonId': booking.salonId,
      'start': booking.start.toUtc().toIso8601String(),
      'serviceNames': booking.serviceNames,
      if (booking.staffName != null) 'staffName': booking.staffName,
    }) as Map<String, dynamic>;
    return ApiMappers.booking(json);
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _client.post('/bookings/$bookingId/cancel');
  }
}
