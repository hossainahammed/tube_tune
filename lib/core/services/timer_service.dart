import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/timer_model.dart';
import 'storage_service.dart';

/// Service managing Digital Wellbeing Screen Time Limit (Auto-Lock), Break Duration (Auto-Unlock), and Multiple Usage Schedules.
class TimerService with ChangeNotifier {
  static TimerService? _instance;
  final StorageService storage;
  Timer? _ticker;
  TimerModel _state = const TimerModel();

  TimerService._(this.storage) {
    _loadState();
  }

  static Future<TimerService> getInstance(StorageService storage) async {
    _instance ??= TimerService._(storage);
    return _instance!;
  }

  TimerModel get state => _state;
  bool get isLocked => _state.isLocked || _state.isScheduleLocked;
  bool get isTimerEnabled => _state.isTimerEnabled;
  bool get isScheduleEnabled => _state.isScheduleEnabled;
  int get sessionRemainingSeconds => _state.sessionRemainingSeconds;
  int get breakRemainingSeconds => _state.breakRemainingSeconds;

  void _loadState() {
    _state = storage.getTimerState();
    _recalculateFromTimestamps();
    if (_state.isTimerEnabled || _state.isLocked || _state.isScheduleEnabled) {
      _startTicker();
    }
  }

  /// Recalculate remaining seconds and verify schedule
  void _recalculateFromTimestamps() {
    final now = DateTime.now();

    // 1. Check Multiple Schedule Windows Lock (Allowed Time-of-Day Windows)
    if (_state.isScheduleEnabled) {
      final isOutside = _state.isOutsideSchedule(now);
      if (isOutside) {
        _state = _state.copyWith(isScheduleLocked: true, isLocked: true);
      } else if (_state.isScheduleLocked) {
        _state = _state.copyWith(isScheduleLocked: false, isLocked: false);
      }
    }

    // 2. If session-locked, check if auto-unlock time has elapsed
    if (_state.isLocked && !_state.isScheduleLocked && _state.unlockAt != null) {
      final diff = _state.unlockAt!.difference(now).inSeconds;
      if (diff <= 0) {
        // Break period is finished -> Auto-Unlock
        _unlockInternal();
      } else {
        _state = _state.copyWith(breakRemainingSeconds: diff);
      }
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    final now = DateTime.now();

    // Check Multiple Schedule Windows
    if (_state.isScheduleEnabled) {
      final isOutside = _state.isOutsideSchedule(now);
      if (isOutside && !_state.isScheduleLocked) {
        _state = _state.copyWith(isScheduleLocked: true, isLocked: true);
        storage.saveTimerState(_state);
        notifyListeners();
        return;
      } else if (!isOutside && _state.isScheduleLocked) {
        _state = _state.copyWith(isScheduleLocked: false, isLocked: false);
        storage.saveTimerState(_state);
        notifyListeners();
      }
    }

    if (_state.isLocked && !_state.isScheduleLocked) {
      // We are in Break Lock Mode
      if (_state.breakRemainingSeconds > 0) {
        _state = _state.copyWith(
          breakRemainingSeconds: _state.breakRemainingSeconds - 1,
        );
        notifyListeners();
      } else {
        // Auto-Unlock time reached!
        _unlockInternal();
      }
    } else if (_state.isTimerEnabled && !_state.isLocked) {
      // Active watching session countdown
      if (_state.sessionRemainingSeconds > 0) {
        _state = _state.copyWith(
          sessionRemainingSeconds: _state.sessionRemainingSeconds - 1,
        );
        notifyListeners();
      } else {
        // Time limit reached -> Lock the app
        _lockInternal();
      }
    }
  }

  void _lockInternal() {
    final now = DateTime.now();
    final unlockTime = now.add(Duration(minutes: _state.breakDurationMinutes));
    _state = _state.copyWith(
      isLocked: true,
      lockedAt: now,
      unlockAt: unlockTime,
      breakRemainingSeconds: _state.breakDurationMinutes * 60,
    );
    storage.saveTimerState(_state);
    notifyListeners();
  }

  void _unlockInternal() {
    _state = _state.copyWith(
      isLocked: false,
      isScheduleLocked: false,
      lockedAt: null,
      unlockAt: null,
      sessionRemainingSeconds: _state.sessionDurationMinutes * 60,
    );
    storage.saveTimerState(_state);
    notifyListeners();
  }

  // --- Public Control APIs ---

  /// Toggle Auto-Lock Timer ON/OFF
  void setTimerEnabled(bool enabled) {
    if (enabled) {
      _state = _state.copyWith(
        isTimerEnabled: true,
        sessionRemainingSeconds: _state.sessionDurationMinutes * 60,
      );
      _startTicker();
    } else {
      _state = _state.copyWith(isTimerEnabled: false);
      if (!_state.isLocked && !_state.isScheduleEnabled) {
        _ticker?.cancel();
      }
    }
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Update Session Limit (minutes)
  void setSessionDuration(int minutes) {
    _state = _state.copyWith(
      sessionDurationMinutes: minutes,
      sessionRemainingSeconds: minutes * 60,
    );
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Update Break / Auto-Unlock Duration (minutes)
  void setBreakDuration(int minutes) {
    _state = _state.copyWith(
      breakDurationMinutes: minutes,
      breakRemainingSeconds: minutes * 60,
    );
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Toggle Master Usage Schedule ON/OFF
  void setScheduleEnabled(bool isEnabled) {
    _state = _state.copyWith(isScheduleEnabled: isEnabled);
    if (isEnabled) {
      _startTicker();
    }
    _recalculateFromTimestamps();
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Add a New Schedule Window
  void addScheduleWindow(ScheduleWindow window) {
    final updated = [..._state.scheduleWindows, window];
    _state = _state.copyWith(scheduleWindows: updated);
    _recalculateFromTimestamps();
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Update an existing Schedule Window
  void updateScheduleWindow(ScheduleWindow window) {
    final updated = _state.scheduleWindows.map((w) {
      return w.id == window.id ? window : w;
    }).toList();
    _state = _state.copyWith(scheduleWindows: updated);
    _recalculateFromTimestamps();
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Remove a Schedule Window
  void removeScheduleWindow(String windowId) {
    final updated = _state.scheduleWindows.where((w) => w.id != windowId).toList();
    _state = _state.copyWith(scheduleWindows: updated);
    _recalculateFromTimestamps();
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Toggle individual Schedule Window ON/OFF
  void toggleScheduleWindow(String windowId, bool isEnabled) {
    final updated = _state.scheduleWindows.map((w) {
      return w.id == windowId ? w.copyWith(isEnabled: isEnabled) : w;
    }).toList();
    _state = _state.copyWith(scheduleWindows: updated);
    _recalculateFromTimestamps();
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Emergency Manual Unlock with PIN
  bool unlockWithPin(String pin) {
    if (_state.pinCode.isEmpty || _state.pinCode == pin) {
      _unlockInternal();
      return true;
    }
    return false;
  }

  /// Set / Update PIN Code
  void setPinCode(String pin, bool isRequired) {
    _state = _state.copyWith(
      pinCode: pin,
      isPinRequired: isRequired,
    );
    storage.saveTimerState(_state);
    notifyListeners();
  }

  /// Reset Timer Session manually
  void resetSession() {
    _state = _state.copyWith(
      isLocked: false,
      isScheduleLocked: false,
      sessionRemainingSeconds: _state.sessionDurationMinutes * 60,
      breakRemainingSeconds: _state.breakDurationMinutes * 60,
      lockedAt: null,
      unlockAt: null,
    );
    storage.saveTimerState(_state);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
