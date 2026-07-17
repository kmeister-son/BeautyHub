import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/salon.dart';
import '../../../../domain/entities/service_category.dart';

final salonsProvider = FutureProvider<List<Salon>>(
  (ref) => ref.watch(salonRepositoryProvider).getSalons(),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Null means "all categories".
final selectedCategoryProvider = StateProvider<ServiceCategory?>((ref) => null);

/// Salons matching the current search query and category filter,
/// nearest first.
final filteredSalonsProvider = Provider<AsyncValue<List<Salon>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(salonsProvider).whenData((salons) {
    final filtered = salons.where((salon) {
      final matchesCategory = category == null || salon.categories.contains(category);
      final matchesQuery = query.isEmpty ||
          salon.name.toLowerCase().contains(query) ||
          salon.tagline.toLowerCase().contains(query) ||
          salon.services.any((s) => s.name.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return filtered;
  });
});

final featuredSalonsProvider = Provider<AsyncValue<List<Salon>>>((ref) {
  return ref
      .watch(salonsProvider)
      .whenData((salons) => salons.where((s) => s.isFeatured).toList());
});
