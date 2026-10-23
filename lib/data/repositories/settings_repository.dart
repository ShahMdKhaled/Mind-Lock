import '../models/app_settings.dart';
import '../services/local_storage_service.dart';

// Repository responsible for saving and retrieving all user configurations and app states
class SettingsRepository {
  final LocalStorageService _localStorage;

  SettingsRepository({required LocalStorageService localStorage})
      : _localStorage = localStorage;

  // Loads all app settings asynchronously from the underlying local storage
  Future<AppSettings> loadSettings() async {
    return await _localStorage.loadSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _localStorage.saveSettings(settings);
  }

  Future<void> setReelsBlockerEnabled(bool enabled) async {
    await _localStorage.setBool('reels_blocker_enabled', enabled);
  }

  Future<void> setReelsBlockedPackages(List<String> packages) async {
    await _localStorage.prefs.setStringList('reels_blocked_packages', packages);
  }

  Future<void> setUninstallProtectionDurationDays(int days) async {
    await _localStorage.setInt('uninstall_protection_duration_days', days);
  }

  Future<void> setUninstallProtection(bool enabled, [int? durationDays]) async {
    await _localStorage.setBool('uninstall_protection_enabled', enabled);
    if (enabled) {
      await _localStorage.setString(
          'uninstall_protection_start_date', DateTime.now().toIso8601String());
      if (durationDays != null) {
        await _localStorage.setInt('uninstall_protection_duration_days', durationDays);
      }
    }
  }

  Future<void> setStudyModeEnabled(bool enabled) async {
    await _localStorage.setBool('study_mode_enabled', enabled);
  }

  Future<void> setScrollLimitEnabled(bool enabled) async {
    await _localStorage.setBool('scroll_limit_enabled', enabled);
  }

  Future<void> setScrollLimitMinutes(int minutes) async {
    await _localStorage.setInt('scroll_limit_minutes', minutes);
  }

  Future<void> setBreakEnabled(bool enabled) async {
    await _localStorage.setBool('break_enabled', enabled);
  }

  Future<void> setBreakIntervalMinutes(int minutes) async {
    await _localStorage.setInt('break_interval_minutes', minutes);
  }

  Future<void> setDailyLimitEnabled(bool enabled) async {
    await _localStorage.setBool('daily_limit_enabled', enabled);
  }

  Future<void> setDailyLimitMinutes(int minutes) async {
    await _localStorage.setInt('daily_limit_minutes', minutes);
  }

  Future<void> setAppLimitsEnabled(bool enabled) async {
    await _localStorage.setBool('app_limits_enabled', enabled);
  }

  Future<void> setStrictModeEnabled(bool enabled) async {
    await _localStorage.setBool('strict_mode_enabled', enabled);
  }

  Future<void> setStrictModeDelayMinutes(int minutes) async {
    await _localStorage.setInt('strict_mode_delay_minutes', minutes);
  }

  Future<void> setStrictModeCountdownStart(DateTime? dateTime) async {
    if (dateTime != null) {
      await _localStorage.setString(
          'strict_mode_countdown_start', dateTime.toIso8601String());
    } else {
      await _localStorage.prefs.remove('strict_mode_countdown_start');
    }
  }

  Future<void> setTargetFeatureToDisable(String? feature) async {
    if (feature != null) {
      await _localStorage.setString('target_feature_to_disable', feature);
    } else {
      await _localStorage.prefs.remove('target_feature_to_disable');
    }
  }

  Future<void> setStrictModeDelayLockedUntil(DateTime? dateTime) async {
    if (dateTime != null) {
      await _localStorage.setString(
          'strict_mode_delay_locked_until', dateTime.toIso8601String());
    } else {
      await _localStorage.prefs.remove('strict_mode_delay_locked_until');
    }
  }

  Future<bool> isSetupComplete() async {
    return await _localStorage.isSetupComplete();
  }

  Future<void> setSetupComplete() async {
    await _localStorage.setSetupComplete();
  }

  Future<DateTime?> getLastBreakTime() async {
    return await _localStorage.getLastBreakTime();
  }

  Future<void> setLastBreakTime(DateTime time) async {
    await _localStorage.setLastBreakTime(time);
  }

  int getDailyBreaksCount() {
    return _localStorage.getDailyBreaksCount();
  }
}
