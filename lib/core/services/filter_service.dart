import '../constants/app_categories.dart';
import '../../models/category_model.dart';
import '../../models/video_model.dart';

/// Comprehensive Filter Engine enforcing 18+ blocking, Reels toggle, and Strict Category Isolation.
class FilterService {
  FilterService._();

  static final FilterService instance = FilterService._();

  /// Check if text contains adult, 18+, NSFW, or blacklisted terms
  bool is18PlusText(String text, [List<String> customBlacklist = const []]) {
    final lower = text.toLowerCase();
    
    // Check built-in 18+ keywords
    for (final word in AppCategories.blocked18PlusKeywords) {
      if (_containsWordOrPhrase(lower, word.toLowerCase())) {
        return true;
      }
    }

    // Check custom user blacklist
    for (final word in customBlacklist) {
      if (word.trim().isNotEmpty && _containsWordOrPhrase(lower, word.toLowerCase().trim())) {
        return true;
      }
    }

    return false;
  }

  /// Check if a video is 18+ / adult / sensitive
  bool is18Plus(VideoModel video, [List<String> customBlacklist = const []]) {
    if (video.isAgeRestricted) return true;
    if (is18PlusText(video.title, customBlacklist)) return true;
    if (is18PlusText(video.description, customBlacklist)) return true;
    if (is18PlusText(video.author, customBlacklist)) return true;

    for (final tag in video.tags) {
      if (is18PlusText(tag, customBlacklist)) return true;
    }

    return false;
  }

  /// Check if video matches a specific category's keywords or tag
  bool matchesCategory(VideoModel video, CategoryModel category) {
    if (video.categoryTag.toLowerCase() == category.id.toLowerCase()) {
      return true;
    }

    final titleLower = video.title.toLowerCase();
    final authorLower = video.author.toLowerCase();
    final descLower = video.description.toLowerCase();
    final tagsLower = video.tags.map((t) => t.toLowerCase()).toList();

    for (final kw in category.keywords) {
      final kwLower = kw.toLowerCase();
      if (titleLower.contains(kwLower) ||
          authorLower.contains(kwLower) ||
          descLower.contains(kwLower) ||
          tagsLower.any((t) => t.contains(kwLower))) {
        return true;
      }
    }

    return false;
  }

  /// Determine if a video belongs to any of the currently enabled categories
  bool matchesAnyCategory(VideoModel video, List<CategoryModel> enabledCategories) {
    if (enabledCategories.isEmpty) return false;
    for (final cat in enabledCategories) {
      if (matchesCategory(video, cat)) {
        return true;
      }
    }
    return false;
  }

  /// Master Filter Evaluator
  /// Returns `true` if the video is safe and permitted under all active user settings.
  bool isAllowedVideo(
    VideoModel video, {
    required bool enableShorts,
    required bool block18Plus,
    required bool strictCategoryMode,
    required List<CategoryModel> enabledCategories,
    required List<String> customBlacklist,
    String? currentSelectedCategoryId,
  }) {
    // 1. Reels / Shorts switch check
    if (video.isShort && !enableShorts) {
      return false; // Shorts globally disabled
    }

    // 2. 18+ and NSFW blocker (applies to regular videos AND reels/shorts)
    if (block18Plus && is18Plus(video, customBlacklist)) {
      return false; // 18+ content blocked
    }

    // 3. Custom blacklist check
    for (final word in customBlacklist) {
      if (word.trim().isNotEmpty) {
        final w = word.toLowerCase().trim();
        if (video.title.toLowerCase().contains(w) ||
            video.author.toLowerCase().contains(w) ||
            video.tags.any((t) => t.toLowerCase().contains(w))) {
          return false;
        }
      }
    }

    // 4. Category Filter & Out-of-category Isolation
    // If a specific category tab is selected (e.g. Islamic, Kids, News), only allow videos from that category
    if (currentSelectedCategoryId != null &&
        currentSelectedCategoryId != 'all' &&
        currentSelectedCategoryId.isNotEmpty) {
      final selectedCategory = enabledCategories.firstWhere(
        (c) => c.id == currentSelectedCategoryId,
        orElse: () => AppCategories.defaultCategories.firstWhere((c) => c.id == currentSelectedCategoryId),
      );
      if (!matchesCategory(video, selectedCategory)) {
        return false; // Block out-of-category content
      }
      return true;
    }

    // If strict category mode is ON (or focus mode enabled), content OUTSIDE enabled categories is BLOCKED
    if (strictCategoryMode) {
      if (!matchesAnyCategory(video, enabledCategories)) {
        return false; // Block content that does not belong to enabled categories
      }
    }

    return true;
  }

  /// Filter an entire video list and return filtered items + rejection count
  ({List<VideoModel> allowed, int filteredCount, int eighteenPlusCount, int shortsCount}) filterList(
    List<VideoModel> videos, {
    required bool enableShorts,
    required bool block18Plus,
    required bool strictCategoryMode,
    required List<CategoryModel> enabledCategories,
    required List<String> customBlacklist,
    String? currentSelectedCategoryId,
  }) {
    final List<VideoModel> allowed = [];
    int filteredCount = 0;
    int eighteenPlusCount = 0;
    int shortsCount = 0;

    for (final v in videos) {
      if (v.isShort && !enableShorts) {
        shortsCount++;
        filteredCount++;
        continue;
      }

      if (block18Plus && is18Plus(v, customBlacklist)) {
        eighteenPlusCount++;
        filteredCount++;
        continue;
      }

      final isAllowed = isAllowedVideo(
        v,
        enableShorts: enableShorts,
        block18Plus: block18Plus,
        strictCategoryMode: strictCategoryMode,
        enabledCategories: enabledCategories,
        customBlacklist: customBlacklist,
        currentSelectedCategoryId: currentSelectedCategoryId,
      );

      if (isAllowed) {
        allowed.add(v);
      } else {
        filteredCount++;
      }
    }

    return (
      allowed: allowed,
      filteredCount: filteredCount,
      eighteenPlusCount: eighteenPlusCount,
      shortsCount: shortsCount,
    );
  }

  /// Helper for exact word / phrase matching
  bool _containsWordOrPhrase(String text, String phrase) {
    if (phrase.contains(' ') || phrase.contains('+')) {
      return text.contains(phrase);
    }
    final regex = RegExp(r'\b' + RegExp.escape(phrase) + r'\b', caseSensitive: false);
    return regex.hasMatch(text);
  }
}
