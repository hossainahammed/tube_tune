import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/comment_model.dart';
import '../../models/timer_model.dart';
import '../../models/user_model.dart';
import '../../models/video_model.dart';

/// Storage Service managing persistent app settings, timers, user accounts, history, and favorites.
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const _keyEnableShorts = 'enable_shorts';
  static const _keyBlock18Plus = 'block_18_plus';
  static const _keyEnableAdBlock = 'enable_ad_block';
  static const _keyStrictCategoryMode = 'strict_category_mode';
  static const _keyEnableBackgroundPlay = 'enable_background_play';
  static const _keySelectedFocusMode = 'selected_focus_mode';
  static const _keyEnabledCategories = 'enabled_categories';
  static const _keyCustomBlacklist = 'custom_blacklist';
  static const _keyTimerState = 'timer_state';
  static const _keyUserData = 'user_data';
  static const _keyWatchHistory = 'watch_history';
  static const _keyWatchLater = 'watch_later';
  static const _keyStatsVideosFiltered = 'stats_videos_filtered';
  static const _keyStats18PlusBlocked = 'stats_18_plus_blocked';
  static const _keyStatsShortsBlocked = 'stats_shorts_blocked';

  // --- Settings Getters & Setters ---

  bool getEnableShorts() => _prefs?.getBool(_keyEnableShorts) ?? true;
  Future<bool> setEnableShorts(bool value) async => _prefs?.setBool(_keyEnableShorts, value) ?? false;

  bool getBlock18Plus() => _prefs?.getBool(_keyBlock18Plus) ?? true;
  Future<bool> setBlock18Plus(bool value) async => _prefs?.setBool(_keyBlock18Plus, value) ?? false;

  bool getEnableAdBlock() => _prefs?.getBool(_keyEnableAdBlock) ?? true;
  Future<bool> setEnableAdBlock(bool value) async => _prefs?.setBool(_keyEnableAdBlock, value) ?? false;

  bool getEnableBackgroundPlay() => _prefs?.getBool(_keyEnableBackgroundPlay) ?? true;
  Future<bool> setEnableBackgroundPlay(bool value) async => _prefs?.setBool(_keyEnableBackgroundPlay, value) ?? false;

  bool getStrictCategoryMode() => _prefs?.getBool(_keyStrictCategoryMode) ?? true;
  Future<bool> setStrictCategoryMode(bool value) async => _prefs?.setBool(_keyStrictCategoryMode, value) ?? false;

  String getSelectedFocusMode() => _prefs?.getString(_keySelectedFocusMode) ?? 'all';
  Future<bool> setSelectedFocusMode(String mode) async => _prefs?.setString(_keySelectedFocusMode, mode) ?? false;

  List<String> getEnabledCategories() {
    return _prefs?.getStringList(_keyEnabledCategories) ?? [];
  }

  Future<bool> setEnabledCategories(List<String> categoryIds) async {
    return _prefs?.setStringList(_keyEnabledCategories, categoryIds) ?? false;
  }

  List<String> getCustomBlacklist() {
    return _prefs?.getStringList(_keyCustomBlacklist) ?? [];
  }

  Future<bool> setCustomBlacklist(List<String> blacklist) async {
    return _prefs?.setStringList(_keyCustomBlacklist, blacklist) ?? false;
  }

  // --- Google / User Account Persistence ---

  UserModel getUserData() {
    final raw = _prefs?.getString(_keyUserData);
    if (raw == null || raw.isEmpty) {
      return const UserModel();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return const UserModel();
    }
  }

  Future<bool> saveUserData(UserModel user) async {
    final raw = jsonEncode(user.toJson());
    return _prefs?.setString(_keyUserData, raw) ?? false;
  }

  Future<bool> clearUserData() async {
    return _prefs?.remove(_keyUserData) ?? false;
  }

  // --- Timer State Persistence ---

  TimerModel getTimerState() {
    final raw = _prefs?.getString(_keyTimerState);
    if (raw == null || raw.isEmpty) {
      return const TimerModel();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TimerModel.fromJson(json);
    } catch (_) {
      return const TimerModel();
    }
  }

  Future<bool> saveTimerState(TimerModel timer) async {
    final raw = jsonEncode(timer.toJson());
    return _prefs?.setString(_keyTimerState, raw) ?? false;
  }

  // --- Statistics ---

  int getStatsVideosFiltered() => _prefs?.getInt(_keyStatsVideosFiltered) ?? 0;
  Future<void> incrementVideosFiltered([int count = 1]) async {
    final current = getStatsVideosFiltered();
    await _prefs?.setInt(_keyStatsVideosFiltered, current + count);
  }

  int getStats18PlusBlocked() => _prefs?.getInt(_keyStats18PlusBlocked) ?? 0;
  Future<void> increment18PlusBlocked([int count = 1]) async {
    final current = getStats18PlusBlocked();
    await _prefs?.setInt(_keyStats18PlusBlocked, current + count);
  }

  int getStatsShortsBlocked() => _prefs?.getInt(_keyStatsShortsBlocked) ?? 0;
  Future<void> incrementShortsBlocked([int count = 1]) async {
    final current = getStatsShortsBlocked();
    await _prefs?.setInt(_keyStatsShortsBlocked, current + count);
  }

  // --- History & Watch Later ---

  List<VideoModel> getWatchHistory() {
    final list = _prefs?.getStringList(_keyWatchHistory) ?? [];
    return list.map((e) {
      try {
        return VideoModel.fromJson(jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<VideoModel>().toList();
  }

  Future<void> saveWatchHistory(List<VideoModel> videos) async {
    final list = videos.take(50).map((v) => jsonEncode(v.toJson())).toList();
    await _prefs?.setStringList(_keyWatchHistory, list);
  }

  List<VideoModel> getWatchLater() {
    final list = _prefs?.getStringList(_keyWatchLater) ?? [];
    return list.map((e) {
      try {
        return VideoModel.fromJson(jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<VideoModel>().toList();
  }

  Future<void> saveWatchLater(List<VideoModel> videos) async {
    final list = videos.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs?.setStringList(_keyWatchLater, list);
  }

  // --- Video Comments Persistence ---

  List<CommentModel> getUserComments(String videoId) {
    final raw = _prefs?.getStringList('comments_$videoId') ?? [];
    return raw.map((e) {
      try {
        return CommentModel.fromJson(jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<CommentModel>().toList();
  }

  Future<void> saveUserComment(String videoId, CommentModel comment) async {
    final existing = getUserComments(videoId);
    existing.insert(0, comment);
    final encoded = existing.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs?.setStringList('comments_$videoId', encoded);
  }
}
