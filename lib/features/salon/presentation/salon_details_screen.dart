import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../core/widgets/salon_cover.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/salon.dart';
import 'providers/salon_providers.dart';
import 'widgets/service_tile.dart';

class SalonDetailsScreen extends ConsumerStatefulWidget {
  const SalonDetailsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends ConsumerState<SalonDetailsScreen> {
  final Set<String> _selectedServiceIds = {};

  @override
  Widget build(BuildContext context) {
    final salonAsync = ref.watch(salonProvider(widget.salonId));
    return Scaffold(
      body: salonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load this salon.\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (salon) => _SalonDetailsBody(
          salon: salon,
          selectedServiceIds: _selectedServiceIds,
          onToggleService: (id) => setState(() {
            _selectedServiceIds.contains(id)
                ? _selectedServiceIds.remove(id)
                : _selectedServiceIds.add(id);
          }),
        ),
      ),
      bottomNavigationBar: salonAsync.maybeWhen(
        data: (salon) {
          final selected =
              salon.services.where((s) => _selectedServiceIds.contains(s.id)).toList();
          if (selected.isEmpty) return null;
          final total = selected.fold<double>(0, (sum, s) => sum + s.price);
          final minutes = selected.fold<int>(0, (sum, s) => sum + s.durationMinutes);
          final scheme = Theme.of(context).colorScheme;
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.money(total),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${selected.length} service${selected.length == 1 ? '' : 's'} · ${Formatters.duration(minutes)}',
                        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.push(
                        '/salon/${salon.id}/book?services=${_selectedServiceIds.join(',')}',
                      ),
                      child: const Text('Book now'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _SalonDetailsBody extends StatelessWidget {
  const _SalonDetailsBody({
    required this.salon,
    required this.selectedServiceIds,
    required this.onToggleService,
  });

  final Salon salon;
  final Set<String> selectedServiceIds;
  final ValueChanged<String> onToggleService;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: SalonCover(
              seed: salon.coverSeed,
              emoji: salon.categories.first.emoji,
              emojiSize: 52,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.name,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RatingBadge(rating: salon.rating, reviewCount: salon.reviewCount),
                    const SizedBox(width: 12),
                    Icon(Icons.place_outlined, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      Formatters.distance(salon.distanceKm),
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  salon.address,
                  style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Open ${salon.openHour.toString().padLeft(2, '0')}:00 – ${salon.closeHour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Text(salon.about, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Services')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: salon.services.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final service = salon.services[index];
              return ServiceTile(
                service: service,
                isSelected: selectedServiceIds.contains(service.id),
                onToggle: () => onToggleService(service.id),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Team')),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: salon.staff.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final member = salon.staff[index];
                return SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors
                            .coverGradient(salon.coverSeed + index)
                            .first
                            .withValues(alpha: 0.25),
                        child: Text(
                          member.initials,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        member.name.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        member.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Reviews')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList.separated(
            itemCount: salon.reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final review = salon.reviews[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.authorName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          RatingBadge(rating: review.rating),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(review.comment, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.day(review.date),
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
