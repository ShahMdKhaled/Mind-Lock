// Data model representing all user-configurable settings and features in MindLock
class AppSettings {
  bool reelsBlockerEnabled;
  List<String> reelsBlockedPackages;
  bool scrollLimitEnabled;
  int scrollLimitMinutes;
  bool breakEnabled;
  int breakIntervalMinutes;
  int breakDurationSeconds;
  bool dailyLimitEnabled;
  int dailyLimitMinutes;
  bool uninstallProtectionEnabled;
  DateTime? uninstallProtectionStartDate;
  int uninstallProtectionDurationDays;
  bool studyModeEnabled;
  String? studyModeStartTime;
  String? studyModeEndTime;
  List<String> blockedApps;
  bool appLimitsEnabled;
  Map<String, int> appLimits;
  bool strictModeEnabled;
  int strictModeDelayMinutes;
  DateTime? strictModeCountdownStart;
  String? targetFeatureToDisable;
  DateTime? strictModeDelayLockedUntil;

  AppSettings({
    this.reelsBlockerEnabled = false,
    List<String>? reelsBlockedPackages,
    this.scrollLimitEnabled = false,
    this.scrollLimitMinutes = 30,
    this.breakEnabled = false,
    this.breakIntervalMinutes = 20,
    this.breakDurationSeconds = 5,
    this.dailyLimitEnabled = false,
    this.dailyLimitMinutes = 120,
    this.uninstallProtectionEnabled = false,
    this.uninstallProtectionStartDate,
    this.uninstallProtectionDurationDays = 30,
    this.studyModeEnabled = false,
    this.studyModeStartTime,
    this.studyModeEndTime,
    List<String>? blockedApps,
    this.appLimitsEnabled = false,
    Map<String, int>? appLimits,
    this.strictModeEnabled = false,
    this.strictModeDelayMinutes = 10,
    this.strictModeCountdownStart,
    this.targetFeatureToDisable,
    this.strictModeDelayLockedUntil,
  })  : reelsBlockedPackages = reelsBlockedPackages ?? [],
        blockedApps = blockedApps ?? [],
        appLimits = appLimits ?? {};

  DateTime? get uninstallProtectionEndDate {
    if (uninstallProtectionStartDate == null) return null;
    return uninstallProtectionStartDate!
        .add(Duration(days: uninstallProtectionDurationDays));
  }

  // Checks if the custom-day uninstall protection feature is currently active
  bool get isUninstallProtectionActive {
    if (!uninstallProtectionEnabled || uninstallProtectionStartDate == null) {
      return false;
    }
    final protectionEnd = uninstallProtectionEndDate;
    if (protectionEnd == null) return false;
    return DateTime.now().isBefore(protectionEnd);
  }

  // Checks if the strict mode delay countdown is currently running
  bool get isStrictModeDelayActive {
    if (!strictModeEnabled || strictModeCountdownStart == null) return false;
    final delayEnd = strictModeCountdownStart!
        .add(Duration(minutes: strictModeDelayMinutes));
    return DateTime.now().isBefore(delayEnd);
  }

  bool get isStrictModeDelayCompleted {
    if (!strictModeEnabled || strictModeCountdownStart == null) return false;
    return !isStrictModeDelayActive;
  }

  Duration get strictModeDelayRemaining {
    if (!isStrictModeDelayActive) return Duration.zero;
    final delayEnd = strictModeCountdownStart!
        .add(Duration(minutes: strictModeDelayMinutes));
    return delayEnd.difference(DateTime.now());
  }

  // Helper getters
  Duration get uninstallProtectionRemaining {
    if (!isUninstallProtectionActive) return Duration.zero;
    final protectionEnd = uninstallProtectionEndDate;
    if (protectionEnd == null) return Duration.zero;
    final diff = protectionEnd.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  AppSettings copyWith({
    bool? reelsBlockerEnabled,
    List<String>? reelsBlockedPackages,
    bool? scrollLimitEnabled,
    int? scrollLimitMinutes,
    bool? breakEnabled,
    int? breakIntervalMinutes,
    int? breakDurationSeconds,
    bool? dailyLimitEnabled,
    int? dailyLimitMinutes,
    bool? uninstallProtectionEnabled,
    DateTime? uninstallProtectionStartDate,
    int? uninstallProtectionDurationDays,
    bool? studyModeEnabled,
    String? studyModeStartTime,
    String? studyModeEndTime,
    List<String>? blockedApps,
    bool? appLimitsEnabled,
    Map<String, int>? appLimits,
    bool? strictModeEnabled,
    int? strictModeDelayMinutes,
    DateTime? strictModeCountdownStart,
    String? targetFeatureToDisable,
    DateTime? strictModeDelayLockedUntil,
    bool clearStrictModeState = false,
  }) {
    return AppSettings(
      reelsBlockerEnabled: reelsBlockerEnabled ?? this.reelsBlockerEnabled,
      reelsBlockedPackages: reelsBlockedPackages ?? this.reelsBlockedPackages,
      scrollLimitEnabled: scrollLimitEnabled ?? this.scrollLimitEnabled,
      scrollLimitMinutes: scrollLimitMinutes ?? this.scrollLimitMinutes,
      breakEnabled: breakEnabled ?? this.breakEnabled,
      breakIntervalMinutes: breakIntervalMinutes ?? this.breakIntervalMinutes,
      breakDurationSeconds: breakDurationSeconds ?? this.breakDurationSeconds,
      dailyLimitEnabled: dailyLimitEnabled ?? this.dailyLimitEnabled,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      uninstallProtectionEnabled:
          uninstallProtectionEnabled ?? this.uninstallProtectionEnabled,
      uninstallProtectionStartDate:
          uninstallProtectionStartDate ?? this.uninstallProtectionStartDate,
      uninstallProtectionDurationDays: uninstallProtectionDurationDays ??
          this.uninstallProtectionDurationDays,
      studyModeEnabled: studyModeEnabled ?? this.studyModeEnabled,
      studyModeStartTime: studyModeStartTime ?? this.studyModeStartTime,
      studyModeEndTime: studyModeEndTime ?? this.studyModeEndTime,
      blockedApps: blockedApps ?? this.blockedApps,
      appLimitsEnabled: appLimitsEnabled ?? this.appLimitsEnabled,
      appLimits: appLimits ?? this.appLimits,
      strictModeEnabled: strictModeEnabled ?? this.strictModeEnabled,
      strictModeDelayMinutes:
          strictModeDelayMinutes ?? this.strictModeDelayMinutes,
      strictModeCountdownStart: clearStrictModeState
          ? null
          : (strictModeCountdownStart ?? this.strictModeCountdownStart),
      targetFeatureToDisable: clearStrictModeState
          ? null
          : (targetFeatureToDisable ?? this.targetFeatureToDisable),
      strictModeDelayLockedUntil:
          strictModeDelayLockedUntil ?? this.strictModeDelayLockedUntil,
    );
  }
}
