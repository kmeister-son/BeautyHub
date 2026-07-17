import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';

typedef SlotQuery = ({
  String salonId,
  String? staffId,
  DateTime day,
  int durationMinutes,
});

/// Available start times for the given salon/professional/day.
/// Record keys give the family value equality for free.
final availableSlotsProvider =
    FutureProvider.autoDispose.family<List<DateTime>, SlotQuery>((ref, query) {
  return ref.watch(bookingRepositoryProvider).getAvailableSlots(
        salonId: query.salonId,
        staffId: query.staffId,
        day: query.day,
        durationMinutes: query.durationMinutes,
      );
});
