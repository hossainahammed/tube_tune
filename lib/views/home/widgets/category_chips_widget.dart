import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../viewmodels/settings_viewmodel.dart';

/// Horizontal scrolling category selector chips adhering to user's category filters.
class CategoryChipsWidget extends StatelessWidget {
  const CategoryChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final enabledCategories = settingsVm.enabledCategories;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: enabledCategories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = homeVm.selectedCategory == AppCategories.categoryAll;
            return ChoiceChip(
              label: const Text('All'),
              selected: isSelected,
              onSelected: (selected) => homeVm.selectCategory(AppCategories.categoryAll),
              selectedColor: Colors.white,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              showCheckmark: false,
            );
          }

          final category = enabledCategories[index - 1];
          final isSelected = homeVm.selectedCategory == category.id;

          return ChoiceChip(
            avatar: Icon(
              category.icon,
              size: 16,
              color: isSelected ? Colors.black : category.color,
            ),
            label: Text(category.name),
            selected: isSelected,
            onSelected: (selected) => homeVm.selectCategory(category.id),
            selectedColor: Colors.white,
            backgroundColor: AppColors.surfaceLight,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
