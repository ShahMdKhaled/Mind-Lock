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
  bool studyModeEnabled;
  String? studyModeStartTime;
  String? studyModeEndTime;
  List<String> blockedApps;
  bool appLimitsEnabled;
  Map<String, int> appLimits;

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
    this.studyModeEnabled = false,
    this.studyModeStartTime,
    this.studyModeEndTime,
    List<String>? blockedApps,
    this.appLimitsEnabled = false,
    Map<String, int>? appLimits,
  })  : reelsBlockedPackages = reelsBlockedPackages ?? [],
        blockedApps = blockedApps ?? [],
        appLimits = appLimits ?? {};

  bool get isUninstallProtectionActive {
    if (!uninstallProtectionEnabled || uninstallProtectionStartDate == null) {
      return false;
    }
    final protectionEnd = uninstallProtectionStartDate!.add(const Duration(days: 30));
    return DateTime.now().isBefore(protectionEnd);
  }

  // Helper getters
  Duration get uninstallProtectionRemaining {
    if (!isUninstallProtectionActive) return Duration.zero;
    final protectionEnd = uninstallProtectionStartDate!.add(const Duration(days: 30));
    return protectionEnd.difference(DateTime.now());
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
    bool? studyModeEnabled,
    String? studyModeStartTime,
    String? studyModeEndTime,
    List<String>? blockedApps,
    bool? appLimitsEnabled,
    Map<String, int>? appLimits,
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
      uninstallProtectionEnabled: uninstallProtectionEnabled ?? this.uninstallProtectionEnabled,
      uninstallProtectionStartDate: uninstallProtectionStartDate ?? this.uninstallProtectionStartDate,
      studyModeEnabled: studyModeEnabled ?? this.studyModeEnabled,
      studyModeStartTime: studyModeStartTime ?? this.studyModeStartTime,
      studyModeEndTime: studyModeEndTime ?? this.studyModeEndTime,
      blockedApps: blockedApps ?? this.blockedApps,
      appLimitsEnabled: appLimitsEnabled ?? this.appLimitsEnabled,
      appLimits: appLimits ?? this.appLimits,
    );
  }
}