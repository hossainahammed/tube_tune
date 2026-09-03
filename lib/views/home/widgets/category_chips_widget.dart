import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../viewmodels/settings_viewmodel.dart';
import '../../explore/explore_view.dart';

/// Horizontal scrolling category selector chips identical to official YouTube mobile.
class CategoryChipsWidget extends StatelessWidget {
  const CategoryChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final enabledCategories = List<CategoryModel>.from(settingsVm.enabledCategories);
    if (!enabledCategories.any((c) => c.id == AppCategories.categoryLiveTv)) {
      enabledCategories.insert(0, AppCategories.liveTvCategory);
    }
    if (settingsVm.block18Plus) {
      enabledCategories.removeWhere(
        (c) =>
            c.id == AppCategories.categoryMusicSongs ||
            c.id == AppCategories.categoryMoviesCinema ||
            c.id == AppCategories.categoryEntertainment,
      );
    } else {
      if (!enabledCategories.any((c) => c.id == AppCategories.categoryMusicSongs)) {
        enabledCategories.insert(1, AppCategories.musicCategory);
      }
      if (!enabledCategories.any((c) => c.id == AppCategories.categoryMoviesCinema)) {
        enabledCategories.insert(2, AppCategories.moviesCategory);
      }
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: enabledCategories.length + 2, // 1 for Explore, 1 for "All", rest for categories
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // 1. YouTube Explore Compass Chip (First item)
          if (index == 0) {
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExploreView()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_outlined, size: 16, color: Colors.white),
                  ],
                ),
              ),
            );
          }

          // 2. "All" Filter Chip
          if (index == 1) {
            final isSelected = homeVm.selectedCategory == AppCategories.categoryAll;
            return _buildChip(
              label: 'All',
              isSelected: isSelected,
              onTap: () => homeVm.selectCategory(AppCategories.categoryAll),
            );
          }

          // 3. User Filtered Category Chips
          final category = enabledCategories[index - 2];
          final isSelected = homeVm.selectedCategory == category.id;

          return _buildChip(
            label: category.name,
            isSelected: isSelected,
            onTap: () => homeVm.selectCategory(category.id),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F0F0F) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
