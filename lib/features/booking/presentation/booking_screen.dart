import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/salon.dart';
import '../../bookings/presentation/providers/bookings_providers.dart';
import '../../salon/presentation/providers/salon_providers.dart';
import 'providers/booking_providers.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({
    super.key,
    required this.salonId,
    required this.serviceIds,
  });

  final String salonId;
  final List<String> serviceIds;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  String? _staffId; // null = any professional
  late DateTime _day;
  DateTime? _slot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
  }

  Future<void> _confirm(Salon salon) async {
    final services =
        salon.services.where((s) => widget.serviceIds.contains(s.id)).toList();
    final staff = _staffId == null
        ? null
        : salon.staff.firstWhere((m) => m.id == _staffId);
    setState(() => _submitting = true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).createBooking(
            Booking(
              id: '',
              salonId: salon.id,
              salonName: salon.name,
              salonAddress: salon.address,
              coverSeed: salon.coverSeed,
              serviceNames: services.map((s) => s.name).toList(),
              staffName: staff?.name,
              start: _slot!,
              totalDurationMinutes:
                  services.fold(0, (sum, s) => sum + s.durationMinutes),
              totalPrice: services.fold(0.0, (sum, s) => sum + s.price),
              status: BookingStatus.confirmed,
            ),
          );
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => _BookingConfirmedSheet(booking: booking),
      );
      if (!mounted) return;
      context.go('/bookings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonAsync = ref.watch(salonProvider(widget.salonId));
    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: salonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load booking details.\n$e')),
        data: (salon) => _buildForm(salon),
      ),
    );
  }

  Widget _buildForm(Salon salon) {
    final services =
        salon.services.where((s) => widget.serviceIds.contains(s.id)).toList();
    if (services.isEmpty) {
      return const Center(child: Text('No services selected.'));
    }
    final duration = services.fold(0, (sum, s) => sum + s.durationMinutes);
    final total = services.fold(0.0, (sum, s) => sum + s.price);
    final scheme = Theme.of(context).colorScheme;

    final slotsAsync = ref.watch(availableSlotsProvider((
      salonId: salon.id,
      staffId: _staffId,
      day: _day,
      durationMinutes: duration,
    )));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SectionHeader(title: 'Professional'),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _staffChip(label: 'Any professional', id: null),
              for (final member in salon.staff)
                _staffChip(label: member.name, id: member.id),
            ],
          ),
        ),
        const SectionHeader(title: 'Date'),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 14,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final now = DateTime.now();
              final date = DateTime(now.year, now.month, now.day)
                  .add(Duration(days: index));
              final isSelected = date == _day;
              return GestureDetector(
                onTap: () => setState(() {
                  _day = date;
                  _slot = null;
                }),
                child: Container(
                  width: 62,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Formatters.day(date).substring(0, 3),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? scheme.onPrimary.withValues(alpha: 0.8)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SectionHeader(title: 'Time'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: slotsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Text('Could not load availability.'),
            data: (slots) => slots.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No availability on this day. Try another date.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final slot in slots)
                        ChoiceChip(
                          label: Text(Formatters.time(slot)),
                          selected: _slot == slot,
                          showCheckmark: false,
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _slot == slot ? scheme.onPrimary : null,
                          ),
                          onSelected: (_) => setState(() => _slot = slot),
                        ),
                    ],
                  ),
          ),
        ),
        const SectionHeader(title: 'Summary'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salon.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  for (final service in services)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(service.name)),
                          Text(
                            Formatters.money(service.price),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        Formatters.money(total),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.duration(duration)}'
                    '${_slot != null ? ' · ${Formatters.day(_day)} at ${Formatters.time(_slot!)}' : ''}',
                    style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton(
            onPressed: _slot == null || _submitting ? null : () => _confirm(salon),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Confirm booking'),
          ),
        ),
      ],
    );
  }

  Widget _staffChip({required String label, required String? id}) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _staffId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? scheme.onPrimary : null,
        ),
        onSelected: (_) => setState(() {
          _staffId = id;
          _slot = null;
        }),
      ),
    );
  }
}

class _BookingConfirmedSheet extends StatelessWidget {
  const _BookingConfirmedSheet({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, size: 48, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${booking.serviceNames.join(', ')}\n'
              '${Formatters.dayLong(booking.start)} at ${Formatters.time(booking.start)}\n'
              '${booking.salonName}',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('View my bookings'),
            ),
          ],
        ),
      ),
    );
  }
}
