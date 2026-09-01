/// Model representing an individual allowed daily usage schedule window
class ScheduleWindow {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isEnabled;

  const ScheduleWindow({
    required this.id,
    this.name = 'Usage Window',
    this.startHour = 15,
    this.startMinute = 0,
    this.endHour = 20,
    this.endMinute = 0,
    this.isEnabled = true,
  });

  String get timeFormatted {
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final startH = startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour);
    final startM = startMinute.toString().padLeft(2, '0');

    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final endH = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
    final endM = endMinute.toString().padLeft(2, '0');

    return '$startH:$startM $startPeriod – $endH:$endM $endPeriod';
  }

  /// Check if a given DateTime falls within this window
  bool isTimeInside(DateTime dt) {
    final currentMinutes = dt.hour * 60 + dt.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight window (e.g. 21:00 PM to 06:00 AM)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  ScheduleWindow copyWith({
    String? id,
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? isEnabled,
  }) {
    return ScheduleWindow(
      id: id ?? this.id,
      name: name ?? this.name,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isEnabled': isEnabled,
    };
  }

  factory ScheduleWindow.fromJson(Map<String, dynamic> json) {
    return ScheduleWindow(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Usage Window',
      startHour: json['startHour'] as int? ?? 15,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 20,
      endMinute: json['endMinute'] as int? ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}

/// Model representing digital wellbeing timer, custom limits, multiple schedules, and lock state
class TimerModel {
  final bool isTimerEnabled;
  final int sessionDurationMinutes;
  final int breakDurationMinutes;
  final int sessionRemainingSeconds;
  final int breakRemainingSeconds;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime? unlockAt;
  final String pinCode;
  final bool isPinRequired;

  // Multiple Usage Schedule Windows
  final bool isScheduleEnabled;
  final List<ScheduleWindow> scheduleWindows;
  final bool isScheduleLocked;

  const TimerModel({
    this.isTimerEnabled = false,
    this.sessionDurationMinutes = 30,
    this.breakDurationMinutes = 15,
    this.sessionRemainingSeconds = 1800,
    this.breakRemainingSeconds = 900,
    this.isLocked = false,
    this.lockedAt,
    this.unlockAt,
    this.pinCode = '',
    this.isPinRequired = false,
    this.isScheduleEnabled = false,
    this.scheduleWindows = const [
      ScheduleWindow(
        id: 'default_afternoon',
        name: 'Afternoon / Evening',
        startHour: 15,
        startMinute: 0,
        endHour: 20,
        endMinute: 0,
        isEnabled: true,
      ),
    ],
    this.isScheduleLocked = false,
  });

  String get sessionRemainingFormatted {
    final minutes = sessionRemainingSeconds ~/ 60;
    final seconds = sessionRemainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get breakRemainingFormatted {
    final minutes = breakRemainingSeconds ~/ 60;
    final seconds = breakRemainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get allScheduleWindowsFormatted {
    final active = scheduleWindows.where((w) => w.isEnabled).toList();
    if (active.isEmpty) return 'No active schedule windows';
    return active.map((w) => w.timeFormatted).join(', ');
  }

  /// Returns true if currently outside all enabled schedule windows
  bool isOutsideSchedule(DateTime dt) {
    if (!isScheduleEnabled) return false;
    final active = scheduleWindows.where((w) => w.isEnabled).toList();
    if (active.isEmpty) return false;
    return !active.any((w) => w.isTimeInside(dt));
  }

  TimerModel copyWith({
    bool? isTimerEnabled,
    int? sessionDurationMinutes,
    int? breakDurationMinutes,
    int? sessionRemainingSeconds,
    int? breakRemainingSeconds,
    bool? isLocked,
    DateTime? lockedAt,
    DateTime? unlockAt,
    String? pinCode,
    bool? isPinRequired,
    bool? isScheduleEnabled,
    List<ScheduleWindow>? scheduleWindows,
    bool? isScheduleLocked,
  }) {
    return TimerModel(
      isTimerEnabled: isTimerEnabled ?? this.isTimerEnabled,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      sessionRemainingSeconds: sessionRemainingSeconds ?? this.sessionRemainingSeconds,
      breakRemainingSeconds: breakRemainingSeconds ?? this.breakRemainingSeconds,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      unlockAt: unlockAt ?? this.unlockAt,
      pinCode: pinCode ?? this.pinCode,
      isPinRequired: isPinRequired ?? this.isPinRequired,
      isScheduleEnabled: isScheduleEnabled ?? this.isScheduleEnabled,
      scheduleWindows: scheduleWindows ?? this.scheduleWindows,
      isScheduleLocked: isScheduleLocked ?? this.isScheduleLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isTimerEnabled': isTimerEnabled,
      'sessionDurationMinutes': sessionDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'sessionRemainingSeconds': sessionRemainingSeconds,
      'breakRemainingSeconds': breakRemainingSeconds,
      'isLocked': isLocked,
      'lockedAt': lockedAt?.toIso8601String(),
      'unlockAt': unlockAt?.toIso8601String(),
      'pinCode': pinCode,
      'isPinRequired': isPinRequired,
      'isScheduleEnabled': isScheduleEnabled,
      'scheduleWindows': scheduleWindows.map((w) => w.toJson()).toList(),
      'isScheduleLocked': isScheduleLocked,
    };
  }

  factory TimerModel.fromJson(Map<String, dynamic> json) {
    List<ScheduleWindow> windows = [];
    if (json['scheduleWindows'] is List) {
      windows = (json['scheduleWindows'] as List)
          .map((item) => ScheduleWindow.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (windows.isEmpty) {
      final startH = json['scheduleStartHour'] as int? ?? 15;
      final startM = json['scheduleStartMinute'] as int? ?? 0;
      final endH = json['scheduleEndHour'] as int? ?? 20;
      final endM = json['scheduleEndMinute'] as int? ?? 0;
      windows = [
        ScheduleWindow(
          id: 'default_afternoon',
          name: 'Afternoon / Evening',
          startHour: startH,
          startMinute: startM,
          endHour: endH,
          endMinute: endM,
          isEnabled: true,
        ),
      ];
    }

    return TimerModel(
      isTimerEnabled: json['isTimerEnabled'] as bool? ?? false,
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 30,
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 15,
      sessionRemainingSeconds: json['sessionRemainingSeconds'] as int? ?? 1800,
      breakRemainingSeconds: json['breakRemainingSeconds'] as int? ?? 900,
      isLocked: json['isLocked'] as bool? ?? false,
      lockedAt: json['lockedAt'] != null ? DateTime.tryParse(json['lockedAt'] as String) : null,
      unlockAt: json['unlockAt'] != null ? DateTime.tryParse(json['unlockAt'] as String) : null,
      pinCode: json['pinCode'] as String? ?? '',
      isPinRequired: json['isPinRequired'] as bool? ?? false,
      isScheduleEnabled: json['isScheduleEnabled'] as bool? ?? false,
      scheduleWindows: windows,
      isScheduleLocked: json['isScheduleLocked'] as bool? ?? false,
    );
  }
}
