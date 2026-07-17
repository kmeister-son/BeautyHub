import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/salon_cover.dart';
import '../../../domain/entities/booking.dart';
import 'providers/bookings_providers.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'History')],
          ),
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load bookings.\n$e')),
          data: (bookings) {
            final upcoming = bookings.where((b) => b.isUpcoming).toList();
            final history = bookings.where((b) => !b.isUpcoming).toList();
            return TabBarView(
              children: [
                _BookingList(
                  bookings: upcoming,
                  emptyTitle: 'No upcoming bookings',
                  emptyMessage: 'Find a salon you love and book your next visit.',
                  showBookCta: true,
                ),
                _BookingList(
                  bookings: history,
                  emptyTitle: 'No past bookings',
                  emptyMessage: 'Your completed and cancelled bookings appear here.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showBookCta = false,
  });

  final List<Booking> bookings;
  final String emptyTitle;
  final String emptyMessage;
  final bool showBookCta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_rounded,
        title: emptyTitle,
        message: emptyMessage,
        action: showBookCta
            ? FilledButton(
                onPressed: () => context.go('/home'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Explore salons'),
                ),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(bookingsProvider.future),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'Cancel ${booking.serviceNames.join(', ')} at ${booking.salonName} on '
          '${Formatters.day(booking.start)} at ${Formatters.time(booking.start)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
    ref.invalidate(bookingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isCancelled = booking.status == BookingStatus.cancelled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: SalonCover(
                    seed: booking.coverSeed,
                    emoji: '📅',
                    emojiSize: 20,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.salonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.serviceNames.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _StatusChip(booking: booking),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  '${Formatters.day(booking.start)} · ${Formatters.time(booking.start)}'
                  ' – ${Formatters.time(booking.end)}',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  Formatters.money(booking.totalPrice),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (booking.staffName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    'with ${booking.staffName}',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            if (booking.isUpcoming && !isCancelled) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Cancel booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (booking.status) {
      BookingStatus.cancelled => ('Cancelled', Colors.red.shade400),
      BookingStatus.confirmed when booking.isUpcoming => (
          'Upcoming',
          Theme.of(context).colorScheme.primary
        ),
      BookingStatus.confirmed => ('Completed', Colors.green.shade600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
