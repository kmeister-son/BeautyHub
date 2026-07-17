import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/service_category.dart';
import '../providers/home_providers.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip(
            context,
            label: 'All',
            isSelected: selected == null,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
          ),
          for (final category in ServiceCategory.values)
            _chip(
              context,
              label: '${category.emoji} ${category.label}',
              isSelected: selected == category,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state =
                  selected == category ? null : category,
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isSelected ? scheme.onPrimary : null,
        ),
      ),
    );
  }
}
