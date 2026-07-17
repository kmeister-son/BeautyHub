import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/booking.dart';

final bookingsProvider = FutureProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).getBookings(),
);
