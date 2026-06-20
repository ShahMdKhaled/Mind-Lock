import '../models/app_settings.dart';
import '../services/local_storage_service.dart';

class SettingsRepository {
  final LocalStorageService _localStorage;

  SettingsRepository({required LocalStorageService localStorage}) : _localStorage = localStorage;

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

  Future<void> setUninstallProtection(bool enabled) async {
    await _localStorage.setBool('uninstall_protection_enabled', enabled);
    if (enabled) {
      await _localStorage.setString('uninstall_protection_start_date', DateTime.now().toIso8601String());
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
}