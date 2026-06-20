import 'package:flutter/foundation.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/di/service_locator.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepo;

  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsViewModel({SettingsRepository? settingsRepo}) : _settingsRepo = settingsRepo ?? getIt<SettingsRepository>() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepo.loadSettings();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleUninstallProtection(bool enabled) async {
    if (enabled) {
      _settings.uninstallProtectionStartDate = DateTime.now();
    }
    _settings = _settings.copyWith(uninstallProtectionEnabled: enabled);
    await _settingsRepo.setUninstallProtection(enabled);
    notifyListeners();
  }

  Future<void> updateScrollLimitMinutes(int minutes) async {
    _settings = _settings.copyWith(scrollLimitMinutes: minutes);
    await _settingsRepo.setScrollLimitMinutes(minutes);
    notifyListeners();
  }

  Future<void> updateBreakIntervalMinutes(int minutes) async {
    _settings = _settings.copyWith(breakIntervalMinutes: minutes);
    await _settingsRepo.setBreakIntervalMinutes(minutes);
    notifyListeners();
  }

  Future<void> toggleScrollLimit(bool enabled) async {
    _settings = _settings.copyWith(scrollLimitEnabled: enabled);
    await _settingsRepo.setScrollLimitEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleBreakEnabled(bool enabled) async {
    _settings = _settings.copyWith(breakEnabled: enabled);
    await _settingsRepo.setBreakEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleDailyLimit(bool enabled) async {
    _settings = _settings.copyWith(dailyLimitEnabled: enabled);
    await _settingsRepo.setDailyLimitEnabled(enabled);
    notifyListeners();
  }

  Future<void> updateDailyLimitMinutes(int minutes) async {
    _settings = _settings.copyWith(dailyLimitMinutes: minutes);
    await _settingsRepo.setDailyLimitMinutes(minutes);
    notifyListeners();
  }
}