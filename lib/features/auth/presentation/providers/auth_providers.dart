import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/user_profile.dart';

/// The identity behind the session — a guest until the user signs in.
/// Invalidate after sign-in/up/out (together with `bookingsProvider`,
/// since bookings follow the identity).
final currentUserProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(authRepositoryProvider).getCurrentUser(),
);
