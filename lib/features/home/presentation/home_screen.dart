import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import 'providers/home_providers.dart';
import 'widgets/category_chips.dart';
import 'widgets/salon_card.dart';
import 'widgets/salon_list_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(selectedCategoryProvider);
    final isBrowsing = query.trim().isEmpty && category == null;
    final filtered = ref.watch(filteredSalonsProvider);
    final featured = ref.watch(featuredSalonsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(salonsProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello there 👋',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find your next look',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: TextField(
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Search salons, barbers, services…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: CategoryChips()),
              if (isBrowsing) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(title: 'Featured'),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 218,
                    child: featured.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Could not load salons')),
                      data: (salons) => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: salons.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => SalonCard(
                          salon: salons[index],
                          onTap: () => context.push('/salon/${salons[index].id}'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SectionHeader(title: 'Near you'),
                ),
              ] else
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: filtered.maybeWhen(
                      data: (salons) =>
                          '${salons.length} result${salons.length == 1 ? '' : 's'}',
                      orElse: () => 'Results',
                    ),
                  ),
                ),
              filtered.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Something went wrong',
                    message: 'We could not load salons. Pull down to retry.',
                  ),
                ),
                data: (salons) => salons.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message:
                              'Try a different search term or clear the category filter.',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.separated(
                          itemCount: salons.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => SalonListTile(
                            salon: salons[index],
                            onTap: () => context.push('/salon/${salons[index].id}'),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
