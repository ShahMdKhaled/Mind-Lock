import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../../core/constants.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  LocalStorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    assert(_prefs != null, 'LocalStorageService not initialized. Call init() first.');
    return _prefs!;
  }

  Future<AppSettings> loadSettings() async {
    await init();
    final startDateStr = prefs.getString(AppConstants.keyUninstallProtectionStartDate);
    final blockedAppsJson = prefs.getStringList(AppConstants.keyBlockedApps) ?? [];
    final reelsBlockedJson = prefs.getStringList(AppConstants.keyReelsBlockedPackages) ?? AppConstants.reelsPackages;

    final appLimitsEnabled = prefs.getBool(AppConstants.keyAppLimitsEnabled) ?? false;
    final limitedPackages = prefs.getStringList(AppConstants.keyAppLimitPackages) ?? [];
    final Map<String, int> appLimits = {};
    for (final package in limitedPackages) {
      appLimits[package] = prefs.getInt('${AppConstants.keyAppLimitMinsPrefix}$package') ?? 0;
    }

    return AppSettings(
      reelsBlockerEnabled: prefs.getBool(AppConstants.keyReelsBlockerEnabled) ?? false,
      reelsBlockedPackages: reelsBlockedJson,
      scrollLimitEnabled: prefs.getBool(AppConstants.keyScrollLimitEnabled) ?? false,
      scrollLimitMinutes: prefs.getInt(AppConstants.keyScrollLimitMinutes) ?? AppConstants.defaultScrollLimitMinutes,
      breakEnabled: prefs.getBool(AppConstants.keyBreakEnabled) ?? false,
      breakIntervalMinutes: prefs.getInt(AppConstants.keyBreakIntervalMinutes) ?? AppConstants.defaultBreakIntervalMinutes,
      breakDurationSeconds: prefs.getInt(AppConstants.keyBreakDurationSeconds) ?? AppConstants.defaultBreakDurationSeconds,
      dailyLimitEnabled: prefs.getBool(AppConstants.keyDailyLimitEnabled) ?? false,
      dailyLimitMinutes: prefs.getInt(AppConstants.keyDailyLimitMinutes) ?? AppConstants.defaultDailyLimitMinutes,
      uninstallProtectionEnabled: prefs.getBool(AppConstants.keyUninstallProtectionEnabled) ?? false,
      uninstallProtectionStartDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
      studyModeEnabled: prefs.getBool(AppConstants.keyStudyModeEnabled) ?? false,
      studyModeStartTime: prefs.getString(AppConstants.keyStudyModeStartTime),
      studyModeEndTime: prefs.getString(AppConstants.keyStudyModeEndTime),
      blockedApps: blockedAppsJson,
      appLimitsEnabled: appLimitsEnabled,
      appLimits: appLimits,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await prefs.setBool(AppConstants.keyReelsBlockerEnabled, settings.reelsBlockerEnabled);
    await prefs.setBool(AppConstants.keyScrollLimitEnabled, settings.scrollLimitEnabled);
    await prefs.setInt(AppConstants.keyScrollLimitMinutes, settings.scrollLimitMinutes);
    await prefs.setBool(AppConstants.keyBreakEnabled, settings.breakEnabled);
    await prefs.setInt(AppConstants.keyBreakIntervalMinutes, settings.breakIntervalMinutes);
    await prefs.setInt(AppConstants.keyBreakDurationSeconds, settings.breakDurationSeconds);
    await prefs.setBool(AppConstants.keyDailyLimitEnabled, settings.dailyLimitEnabled);
    await prefs.setInt(AppConstants.keyDailyLimitMinutes, settings.dailyLimitMinutes);
    await prefs.setBool(AppConstants.keyUninstallProtectionEnabled, settings.uninstallProtectionEnabled);
    if (settings.uninstallProtectionStartDate != null) {
      await prefs.setString(AppConstants.keyUninstallProtectionStartDate, settings.uninstallProtectionStartDate!.toIso8601String());
    }
    await prefs.setBool(AppConstants.keyStudyModeEnabled, settings.studyModeEnabled);
    if (settings.studyModeStartTime != null) {
      await prefs.setString(AppConstants.keyStudyModeStartTime, settings.studyModeStartTime!);
    }
    if (settings.studyModeEndTime != null) {
      await prefs.setString(AppConstants.keyStudyModeEndTime, settings.studyModeEndTime!);
    }
    await prefs.setStringList(AppConstants.keyReelsBlockedPackages, settings.reelsBlockedPackages);
    await prefs.setStringList(AppConstants.keyBlockedApps, settings.blockedApps);
    
    await prefs.setBool(AppConstants.keyAppLimitsEnabled, settings.appLimitsEnabled);
    await prefs.setStringList(AppConstants.keyAppLimitPackages, settings.appLimits.keys.toList());
    for (final entry in settings.appLimits.entries) {
      await prefs.setInt('${AppConstants.keyAppLimitMinsPrefix}${entry.key}', entry.value);
    }
  }

  Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  dynamic get(String key, dynamic defaultValue) {
    return prefs.get(key) ?? defaultValue;
  }

  Future<bool> isSetupComplete() async {
    await init();
    return prefs.getBool(AppConstants.keySetupComplete) ?? false;
  }

  Future<void> setSetupComplete() async {
    await prefs.setBool(AppConstants.keySetupComplete, true);
  }

  Future<DateTime?> getLastBreakTime() async {
    final str = prefs.getString(AppConstants.keyLastBreakTime);
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> setLastBreakTime(DateTime time) async {
    await prefs.setString(AppConstants.keyLastBreakTime, time.toIso8601String());
  }
}