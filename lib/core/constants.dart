class AppConstants {
  AppConstants._();

  static const String appName = 'MindLock';
  static const String appVersion = '1.0.0';

  static const String keyReelsBlockerEnabled = 'reels_blocker_enabled';
  static const String keyReelsBlockedPackages = 'reels_blocked_packages';
  static const String keyScrollLimitEnabled = 'scroll_limit_enabled';
  static const String keyScrollLimitMinutes = 'scroll_limit_minutes';
  static const String keyBreakEnabled = 'break_enabled';
  static const String keyBreakIntervalMinutes = 'break_interval_minutes';
  static const String keyBreakDurationSeconds = 'break_duration_seconds';
  static const String keyDailyLimitEnabled = 'daily_limit_enabled';
  static const String keyDailyLimitMinutes = 'daily_limit_minutes';
  static const String keyUninstallProtectionEnabled = 'uninstall_protection_enabled';
  static const String keyUninstallProtectionStartDate = 'uninstall_protection_start_date';
  static const String keyStudyModeEnabled = 'study_mode_enabled';
  static const String keyStudyModeStartTime = 'study_mode_start_time';
  static const String keyStudyModeEndTime = 'study_mode_end_time';
  static const String keyBlockedApps = 'blocked_apps';
  static const String keySetupComplete = 'setup_complete';
  static const String keyLastBreakTime = 'last_break_time';
  static const String keyTodayUsage = 'today_usage';
  static const String keyAppLimitsEnabled = 'app_limits_enabled';
  static const String keyAppLimitPackages = 'app_limit_packages';
  static const String keyAppLimitMinsPrefix = 'app_limit_mins_';
  static const String keyStrictModeEnabled = 'strict_mode_enabled';
  static const String keyStrictModeDelayMinutes = 'strict_mode_delay_minutes';
  static const String keyStrictModeCountdownStart = 'strict_mode_countdown_start';
  static const String keyTargetFeatureToDisable = 'target_feature_to_disable';
  static const String keyStrictModeDelayLockedUntil = 'strict_mode_delay_locked_until';

  static const int defaultScrollLimitMinutes = 30;
  static const int defaultBreakIntervalMinutes = 20;
  static const int defaultBreakDurationSeconds = 5;
  static const int defaultDailyLimitMinutes = 120;
  static const int minBreakDurationSeconds = 5;
  static const int maxBreakDurationSeconds = 60;
  static const int uninstallProtectionDays = 30;

  static const List<String> reelsPackages = [
    'com.instagram.android',
    'com.facebook.katana',
    'com.zhiliaoapp.musically',
    'com.ss.android.ugc.trill',
    'com.snapchat.android',
    'com.google.android.youtube',
  ];

  static const Map<String, String> socialMediaApps = {
    'com.instagram.android': 'Instagram',
    'com.facebook.katana': 'Facebook',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.snapchat.android': 'Snapchat',
    'com.google.android.youtube': 'YouTube',
    'com.twitter.android': 'Twitter/X',
    'com.pinterest': 'Pinterest',
    'com.reddit.frontpage': 'Reddit',
    'com.linkedin.android': 'LinkedIn',
  };

  static const int notifBreakId = 1001;
  static const int notifDailyLimitId = 1002;
  static const int notifStudyModeId = 1003;
  static const int notifUsageSummaryId = 1004;
  static const String notifChannelBreak = 'mindlock_break';
  static const String notifChannelLimit = 'mindlock_limit';
  static const String notifChannelStudy = 'mindlock_study';

  static const String dbName = 'mindlock.db';
  static const int dbVersion = 1;
  static const String tableUsageHistory = 'usage_history';
  static const String tableDailyStats = 'daily_stats';

  static const double cardRadius = 20.0;
  static const double smallRadius = 12.0;
  static const double largeRadius = 28.0;
  static const double pagePadding = 20.0;
}
