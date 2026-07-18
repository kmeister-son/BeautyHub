import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../data/repositories/api_booking_repository.dart';
import '../../data/repositories/api_salon_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/salon_repository.dart';

/// Composition root. Bound to the beautyhub-api service; widget tests
/// override these with the in-memory mocks from data/repositories/.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final salonRepositoryProvider = Provider<SalonRepository>(
  (ref) => ApiSalonRepository(ref.watch(apiClientProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => ApiBookingRepository(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(ref.watch(apiClientProvider)),
);
