import 'package:flutter/material.dart';
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
    if (category.id == AppCategories.categoryLiveTv &&
        (video.isLive ||
            video.uploadDate.toLowerCase().contains('live') ||
            video.title.toLowerCase().contains('live') ||
            video.title.contains('সরাসরি') ||
            video.duration == Duration.zero)) {
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

  /// Check if a video represents songs, music, movies, or general pop entertainment
  bool isSongsOrMovies(VideoModel video) {
    // 1. Explicit Category Tags
    if (video.categoryTag == AppCategories.categoryMusicSongs ||
        video.categoryTag == AppCategories.categoryMoviesCinema ||
        video.categoryTag == AppCategories.categoryEntertainment) {
      return true;
    }

    // Halal nasheed, news, islamic waz, educational tech are protected exceptions
    if (video.categoryTag == AppCategories.categoryHalalNasheed ||
        video.categoryTag == AppCategories.categoryIslamicWaz ||
        video.categoryTag == AppCategories.categoryNews) {
      return false;
    }

    final lowerTitle = video.title.toLowerCase();
    final lowerAuthor = video.author.toLowerCase();
    final lowerDesc = video.description.toLowerCase();
    final tags = video.tags.map((t) => t.toLowerCase()).join(' ');
    final allText = '$lowerTitle $lowerAuthor $lowerDesc $tags';

    // Comprehensive music & songs keywords in English, Bengali, and Hindi
    const songKeywords = [
      'song', 'songs', 'music', 'gan', 'gaan', 'গান', 'গীতি', 'সঙ্গীত', 'সুর', 'শিল্পী',
      'audio song', 'music video', 'official video', 'official audio', 'lyric video',
      'lyrics video', 'lyrical', 'remix', 'soundtrack', 'ost', 'album', 'single track',
      'pop music', 'pop hit', 'pop song', 'rock song', 'hip hop', 'rap song', 'edm',
      'concert', 'live concert', 'unplugged', 'acoustic cover', 'vocal cover', 'cover song',
      'dj remix', 'dj song', 'coke studio', 't-series', 'vevo', 'zee music', 'speed records',
      'svf music', 'anupam recording', 'soundtek', 'laser vision', 'sangeet', 'geet',
      'bangla song', 'hindi song', 'bollywood song', 'punjabi song', 'english song',
      'romantic song', 'sad song', 'love song', 'party song', 'dance song', 'item song',
      'ghazal', 'qawwali', 'bhajan', 'kirtan', 'karaoke', 'instrumental song', 'melody track',
      'arijit singh', 'atif aslam', 'shreya ghoshal', 'neha kakkar', 'jubin nautiyal',
      'taylor swift', 'ed sheeran', 'justin bieber', 'billie eilish', 'drake', 'the weeknd',
      'bts', 'blackpink', 'dua lipa', 'eminem', 'shakira', 'rihanna', 'selena gomez',
      'habib wahid', 'tahsan', 'james', 'ayub bachchu', 'miles', 'warfaze', 'artcell'
    ];

    for (final kw in songKeywords) {
      if (allText.contains(kw)) {
        return true;
      }
    }

    // Comprehensive movie keywords
    const movieKeywords = [
      'movie', 'movies', 'full movie', 'cinema', 'trailer', 'official trailer', 'teaser',
      'film', 'feature film', 'চলচ্চিত্র', 'নাটক', 'telefilm', 'natok', 'short film',
      'bollywood movie', 'hollywood movie', 'bangla movie', 'south movie', 'tamil movie',
      'hindi movie', 'action movie', 'blockbuster movie', 'box office'
    ];

    for (final kw in movieKeywords) {
      if (allText.contains(kw)) {
        return true;
      }
    }

    return false;
  }

  /// Check if a search query is asking for songs, music, or movies
  bool isSongOrMovieQuery(String query) {
    final lower = query.toLowerCase().trim();
    const queryKeywords = [
      'song', 'songs', 'music', 'gan', 'gaan', 'গান', 'সঙ্গীত', 'সুর', 'audio',
      'music video', 'lyrics', 'remix', 'album', 'pop', 'rock', 'rap', 'concert',
      'movie', 'movies', 'film', 'cinema', 'trailer', 'চলচ্চিত্র', 'নাটক',
      'coke studio', 'bollywood', 'hollywood', 'dj', 'arijit', 'atif aslam',
      'taylor swift', 'bts', 'singer', 'band', 'soundtrack', 'track'
    ];
    for (final kw in queryKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Master Filter Evaluator
  /// Returns `true` if the video is safe and permitted under all active user settings.
  /// If `block18Plus` is false (18+ button enabled), the user can see all contents (songs, movies, etc.) like default YouTube.
  bool isAllowedVideo(
    VideoModel video, {
    required bool enableShorts,
    required bool block18Plus,
    required bool strictCategoryMode,
    required List<CategoryModel> enabledCategories,
    required List<String> customBlacklist,
    List<String> hiddenVideoIds = const [],
    List<String> blockedChannels = const [],
    String? currentSelectedCategoryId,
  }) {
    // 0. Hidden video IDs & Blocked channels ("Not interested" / "Don't recommend channel")
    if (hiddenVideoIds.contains(video.id)) {
      return false;
    }
    final lowerAuthor = video.author.toLowerCase().trim();
    final lowerChannelId = video.channelId.toLowerCase().trim();
    for (final b in blockedChannels) {
      final clean = b.toLowerCase().trim();
      if (clean.isNotEmpty && (lowerAuthor == clean || lowerAuthor.contains(clean) || lowerChannelId == clean)) {
        return false;
      }
    }

    // 1. Reels / Shorts switch check
    if (video.isShort && !enableShorts) {
      return false; // Shorts globally disabled
    }

    // 2. Custom blacklist check (always enforced)
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

    // 3. 18+ & UNRESTRICTED MODE:
    // If block18Plus is FALSE (18+ button is ENABLED by user):
    // -> The user can see ALL contents like songs, movies, adult content, etc., all as like default YouTube!
    if (!block18Plus) {
      if (currentSelectedCategoryId != null &&
          currentSelectedCategoryId != 'all' &&
          currentSelectedCategoryId.isNotEmpty) {
        final selectedCategory = enabledCategories.firstWhere(
          (c) => c.id == currentSelectedCategoryId,
          orElse: () => AppCategories.allAvailableCategories.firstWhere(
            (c) => c.id == currentSelectedCategoryId,
            orElse: () => CategoryModel(id: currentSelectedCategoryId, name: currentSelectedCategoryId, icon: Icons.folder, color: Colors.grey, keywords: const []),
          ),
        );
        return matchesCategory(video, selectedCategory);
      }
      return true; // All content permitted like default YouTube!
    }

    // 4. PROTECTED MODE (block18Plus == true, 18+ button DISABLED):
    // -> Strictly block 18+ and adult content
    if (is18Plus(video, customBlacklist)) {
      return false;
    }

    // -> Strictly block songs, movies, and unfiltered pop entertainment
    if (isSongsOrMovies(video)) {
      return false;
    }

    // -> Category Filter & Out-of-category Isolation
    if (currentSelectedCategoryId != null &&
        currentSelectedCategoryId != 'all' &&
        currentSelectedCategoryId.isNotEmpty) {
      final selectedCategory = enabledCategories.firstWhere(
        (c) => c.id == currentSelectedCategoryId,
        orElse: () => AppCategories.allAvailableCategories.firstWhere(
          (c) => c.id == currentSelectedCategoryId,
          orElse: () => currentSelectedCategoryId == AppCategories.categoryLiveTv
              ? AppCategories.liveTvCategory
              : CategoryModel(
                  id: currentSelectedCategoryId,
                  name: currentSelectedCategoryId,
                  icon: Icons.tv,
                  color: Colors.red,
                  keywords: const ['live', 'tv'],
                ),
        ),
      );
      if (!matchesCategory(video, selectedCategory)) {
        return false; // Block out-of-category content
      }
      return true;
    }

    // If strict category mode is ON, content OUTSIDE enabled categories is BLOCKED
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
    List<String> hiddenVideoIds = const [],
    List<String> blockedChannels = const [],
    String? currentSelectedCategoryId,
  }) {
    final List<VideoModel> allowed = [];
    int filteredCount = 0;
    int eighteenPlusCount = 0;
    int shortsCount = 0;

    for (final v in videos) {
      // Check hidden video IDs ("Not interested")
      if (hiddenVideoIds.contains(v.id)) {
        filteredCount++;
        continue;
      }

      // Check blocked channels ("Don't recommend channel")
      final lowerAuthor = v.author.toLowerCase().trim();
      final lowerChannelId = v.channelId.toLowerCase().trim();
      bool isBlocked = false;
      for (final b in blockedChannels) {
        final clean = b.toLowerCase().trim();
        if (clean.isNotEmpty && (lowerAuthor == clean || lowerAuthor.contains(clean) || lowerChannelId == clean)) {
          isBlocked = true;
          break;
        }
      }
      if (isBlocked) {
        filteredCount++;
        continue;
      }

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

      if (block18Plus && isSongsOrMovies(v)) {
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
        hiddenVideoIds: hiddenVideoIds,
        blockedChannels: blockedChannels,
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
