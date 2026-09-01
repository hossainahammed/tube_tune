import 'package:flutter/foundation.dart';
import '../core/constants/app_categories.dart';
import '../core/services/storage_service.dart';
import '../core/services/timer_service.dart';
import '../models/category_model.dart';
import '../models/timer_model.dart';

/// ViewModel managing settings, data filtration toggles, categories, and timers.
class SettingsViewModel with ChangeNotifier {
  final StorageService storage;
  final TimerService timerService;

  bool _enableShorts = true;
  bool _block18Plus = true;
  bool _enableAdBlock = true;
  bool _strictCategoryMode = true;
  String _selectedFocusMode = 'all';
  List<CategoryModel> _categories = [];
  List<String> _customBlacklist = [];

  int _totalVideosFiltered = 0;
  int _total18PlusBlocked = 0;
  int _totalShortsBlocked = 0;

  SettingsViewModel({
    required this.storage,
    required this.timerService,
  }) {
    timerService.addListener(notifyListeners);
    _loadSettings();
  }

  // Getters
  bool get enableShorts => _enableShorts;
  bool get block18Plus => _block18Plus;
  bool get enableAdBlock => _enableAdBlock;
  bool get strictCategoryMode => _strictCategoryMode;
  String get selectedFocusMode => _selectedFocusMode;
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<CategoryModel> get enabledCategories => _categories.where((c) => c.isEnabled).toList();
  List<String> get customBlacklist => List.unmodifiable(_customBlacklist);

  int get totalVideosFiltered => _totalVideosFiltered;
  int get total18PlusBlocked => _total18PlusBlocked;
  int get totalShortsBlocked => _totalShortsBlocked;

  void _loadSettings() {
    _enableShorts = storage.getEnableShorts();
    _block18Plus = storage.getBlock18Plus();
    _enableAdBlock = storage.getEnableAdBlock();
    _strictCategoryMode = storage.getStrictCategoryMode();
    _selectedFocusMode = storage.getSelectedFocusMode();
    _customBlacklist = storage.getCustomBlacklist();

    _totalVideosFiltered = storage.getStatsVideosFiltered();
    _total18PlusBlocked = storage.getStats18PlusBlocked();
    _totalShortsBlocked = storage.getStatsShortsBlocked();

    final savedEnabledCategoryIds = storage.getEnabledCategories();
    _categories = AppCategories.defaultCategories.map((defaultCat) {
      if (savedEnabledCategoryIds.isEmpty) {
        // By default ALL are enabled
        return defaultCat.copyWith(isEnabled: true);
      }
      final isEnabled = savedEnabledCategoryIds.contains(defaultCat.id);
      return defaultCat.copyWith(isEnabled: isEnabled);
    }).toList();

    notifyListeners();
  }

  // --- Toggle Actions ---

  Future<void> toggleEnableShorts(bool value) async {
    _enableShorts = value;
    await storage.setEnableShorts(value);
    notifyListeners();
  }

  Future<void> toggleBlock18Plus(bool value) async {
    _block18Plus = value;
    await storage.setBlock18Plus(value);
    notifyListeners();
  }

  Future<void> toggleEnableAdBlock(bool value) async {
    _enableAdBlock = value;
    await storage.setEnableAdBlock(value);
    notifyListeners();
  }

  Future<void> toggleStrictCategoryMode(bool value) async {
    _strictCategoryMode = value;
    await storage.setStrictCategoryMode(value);
    notifyListeners();
  }

  /// Preset Focus Modes (Islamic & Waz Only, Kids Only, News Only, All, etc.)
  Future<void> setFocusMode(String mode) async {
    _selectedFocusMode = mode;
    await storage.setSelectedFocusMode(mode);

    if (mode == 'all') {
      _categories = _categories.map((c) => c.copyWith(isEnabled: true)).toList();
      _strictCategoryMode = false;
      await storage.setStrictCategoryMode(false);
    } else if (mode == 'custom') {
      _strictCategoryMode = true;
      await storage.setStrictCategoryMode(true);
    } else {
      // Single Category Focus Mode (e.g. islamic_waz, kids_cartoons, news)
      _strictCategoryMode = true;
      await storage.setStrictCategoryMode(true);
      _categories = _categories.map((c) {
        return c.copyWith(isEnabled: c.id == mode);
      }).toList();
    }

    await _saveEnabledCategoryList();
    notifyListeners();
  }

  /// Toggle individual category on/off
  Future<void> toggleCategory(String categoryId, bool enabled) async {
    _categories = _categories.map((c) {
      if (c.id == categoryId) {
        return c.copyWith(isEnabled: enabled);
      }
      return c;
    }).toList();

    _selectedFocusMode = 'custom';
    await storage.setSelectedFocusMode('custom');
    await _saveEnabledCategoryList();
    notifyListeners();
  }

  Future<void> _saveEnabledCategoryList() async {
    final ids = _categories.where((c) => c.isEnabled).map((c) => c.id).toList();
    await storage.setEnabledCategories(ids);
  }

  // --- Blacklist Management ---

  Future<void> addBlacklistKeyword(String keyword) async {
    if (keyword.trim().isEmpty) return;
    if (!_customBlacklist.contains(keyword.trim())) {
      _customBlacklist = [..._customBlacklist, keyword.trim()];
      await storage.setCustomBlacklist(_customBlacklist);
      notifyListeners();
    }
  }

  Future<void> removeBlacklistKeyword(String keyword) async {
    _customBlacklist = _customBlacklist.where((k) => k != keyword).toList();
    await storage.setCustomBlacklist(_customBlacklist);
    notifyListeners();
  }

  // --- Statistics Recording ---

  void recordRejectionStats({int filtered = 0, int eighteenPlus = 0, int shorts = 0}) {
    if (filtered > 0) {
      _totalVideosFiltered += filtered;
      storage.incrementVideosFiltered(filtered);
    }
    if (eighteenPlus > 0) {
      _total18PlusBlocked += eighteenPlus;
      storage.increment18PlusBlocked(eighteenPlus);
    }
    if (shorts > 0) {
      _totalShortsBlocked += shorts;
      storage.incrementShortsBlocked(shorts);
    }
    notifyListeners();
  }

  // --- Timer & Schedule Convenience Methods ---

  void setTimerEnabled(bool enabled) {
    timerService.setTimerEnabled(enabled);
    notifyListeners();
  }

  void setSessionDuration(int minutes) {
    timerService.setSessionDuration(minutes);
    notifyListeners();
  }

  void setBreakDuration(int minutes) {
    timerService.setBreakDuration(minutes);
    notifyListeners();
  }

  void setScheduleEnabled(bool isEnabled) {
    timerService.setScheduleEnabled(isEnabled);
    notifyListeners();
  }

  void addScheduleWindow(ScheduleWindow window) {
    timerService.addScheduleWindow(window);
    notifyListeners();
  }

  void updateScheduleWindow(ScheduleWindow window) {
    timerService.updateScheduleWindow(window);
    notifyListeners();
  }

  void removeScheduleWindow(String windowId) {
    timerService.removeScheduleWindow(windowId);
    notifyListeners();
  }

  void toggleScheduleWindow(String windowId, bool isEnabled) {
    timerService.toggleScheduleWindow(windowId, isEnabled);
    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    final res = timerService.unlockWithPin(pin);
    notifyListeners();
    return res;
  }

  void setPinCode(String pin, bool isRequired) {
    timerService.setPinCode(pin, isRequired);
    notifyListeners();
  }

  void resetSession() {
    timerService.resetSession();
    notifyListeners();
  }

  @override
  void dispose() {
    timerService.removeListener(notifyListeners);
    super.dispose();
  }
}
