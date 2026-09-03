import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/custom_app_bar.dart';
import '../shared/timer_status_bar.dart';

/// Explore View presenting organized categories (Islamic/Waz, Kids, News, Tech, etc.)
class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final homeVm = context.watch<HomeViewModel>();
    final enabledCategories = settingsVm.enabledCategories;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          const TimerStatusBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.youtubeRed,
              onRefresh: () => homeVm.loadFeed(isRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Grid Banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Explore Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${enabledCategories.length} Allowed',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Category Cards Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.3,
                      ),
                      itemCount: enabledCategories.length,
                      itemBuilder: (context, index) {
                        final cat = enabledCategories[index];
                        final isCurrent = _selectedCategory?.id == cat.id;

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedCategory = isCurrent ? null : cat);
                            homeVm.selectCategory(cat.id);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cat.color.withValues(alpha: isCurrent ? 0.4 : 0.2),
                                  AppColors.surfaceElevated,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent ? cat.color : AppColors.cardBorder,
                                width: isCurrent ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.surfaceElevated, thickness: 1),

                  // Feed Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      _selectedCategory != null
                          ? 'Showing ${_selectedCategory!.name} Content'
                          : 'Filtered Highlights',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Video List
                  if (homeVm.videos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No videos available in this category under current filter rules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: homeVm.videos.length,
                      itemBuilder: (context, index) {
                        return VideoCardWidget(video: homeVm.videos[index]);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
