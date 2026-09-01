import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/timer_status_bar.dart';

/// Safe Search View with adult query blocking and category-isolated search results.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchVm = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Safe Search videos, waz, news, kids...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      searchVm.clearSearch();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() {}),
          onSubmitted: (query) => searchVm.performSearch(query),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.youtubeRed),
            onPressed: () => searchVm.performSearch(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          const TimerStatusBar(),
          Expanded(child: _buildSearchBody(context, searchVm)),
        ],
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context, SearchViewModel searchVm) {
    // 1. If 18+ Query is Blocked
    if (searchVm.isQueryBlocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, size: 56, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search Query Blocked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                '18+, NSFW, or blacklisted search keywords are prohibited under TubeTune Strict Safe Mode.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Loading State
    if (searchVm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.youtubeRed));
    }

    // 3. Search Results Found
    if (searchVm.searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: searchVm.searchResults.length,
        itemBuilder: (context, index) {
          return VideoCardWidget(video: searchVm.searchResults[index]);
        },
      );
    }

    // 4. Initial Safe Suggestions Screen
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Safe Topics',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchVm.popularSafeSuggestions.map((suggestion) {
              return ActionChip(
                backgroundColor: AppColors.surfaceLight,
                label: Text(suggestion),
                labelStyle: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                avatar: const Icon(Icons.trending_up, size: 16, color: AppColors.youtubeRed),
                onPressed: () {
                  _searchController.text = suggestion;
                  searchVm.performSearch(suggestion);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
