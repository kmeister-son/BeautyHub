import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/salon.dart';

final salonProvider = FutureProvider.autoDispose.family<Salon, String>(
  (ref, id) => ref.watch(salonRepositoryProvider).getSalonById(id),
);
