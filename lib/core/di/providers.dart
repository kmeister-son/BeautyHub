import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_booking_repository.dart';
import '../../data/repositories/mock_salon_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/salon_repository.dart';

/// Composition root. Swap the mock implementations for API-backed ones
/// here when a backend exists — nothing else changes.
final salonRepositoryProvider = Provider<SalonRepository>(
  (ref) => MockSalonRepository(),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => MockBookingRepository(),
);
