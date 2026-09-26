import 'package:flutter/foundation.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/di/service_locator.dart';

import '../../../data/repositories/permission_repository.dart';
import '../../../data/services/study_mode_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepo;
  final PermissionRepository _permissionRepo;

  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  bool _isUsageGranted = false;
  bool _isAccessibilityEnabled = false;
  bool _isOverlayGranted = false;
  bool _isNotificationGranted = false;
  bool _isDndGranted = false;
  bool _isBatteryIgnored = false;
  bool _isDeviceAdminEnabled = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  bool get isUsageGranted => _isUsageGranted;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isOverlayGranted => _isOverlayGranted;
  bool get isNotificationGranted => _isNotificationGranted;
  bool get isDndGranted => _isDndGranted;
  bool get isBatteryIgnored => _isBatteryIgnored;
  bool get isDeviceAdminEnabled => _isDeviceAdminEnabled;

  SettingsViewModel(
      {SettingsRepository? settingsRepo, PermissionRepository? permissionRepo})
      : _settingsRepo = settingsRepo ?? getIt<SettingsRepository>(),
        _permissionRepo = permissionRepo ?? getIt<PermissionRepository>() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepo.loadSettings();
    await checkPermissions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _isUsageGranted = await _permissionRepo.isUsageAccessGranted();
    _isAccessibilityEnabled =
        await _permissionRepo.isAccessibilityServiceEnabled();
    _isOverlayGranted = await _permissionRepo.isOverlayPermissionGranted();
    _isNotificationGranted =
        await _permissionRepo.isNotificationPermissionGranted();
    _isDndGranted =
        await getIt<StudyModeService>().checkNotificationPolicyPermission();
    _isBatteryIgnored = await _permissionRepo.isBatteryOptimizationIgnored();
    _isDeviceAdminEnabled = await _permissionRepo.isDeviceAdminEnabled();
    notifyListeners();
  }

  Future<void> requestUsage() async {
    await _permissionRepo.openUsageAccessSettings();
  }

  Future<void> requestAccessibility() async {
    await _permissionRepo.openAccessibilitySettings();
  }

  Future<void> requestOverlay() async {
    await _permissionRepo.requestOverlayPermission();
    await checkPermissions();
  }

  Future<void> requestNotification() async {
    await _permissionRepo.requestNotificationPermission();
    await checkPermissions();
  }

  Future<void> requestDnd() async {
    await getIt<StudyModeService>().requestNotificationPolicyPermission();
    await checkPermissions();
  }

  Future<void> requestBatteryIgnore() async {
    await _permissionRepo.requestIgnoreBatteryOptimization();
    // Poll for status since system dialog might not trigger lifecycle events
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final isIgnored = await _permissionRepo.isBatteryOptimizationIgnored();
      if (isIgnored && !_isBatteryIgnored) {
        await checkPermissions();
        break;
      }
    }
    await checkPermissions();
  }

  Future<void> requestDeviceAdmin() async {
    await _permissionRepo.requestDeviceAdmin();
    // Use a delay to check later since standard lifecycle methods might not catch it perfectly.
    await Future.delayed(const Duration(seconds: 2));
    await checkPermissions();
  }

  Future<bool> requestDisableFeature(String feature) async {
    if (!_settings.strictModeEnabled) return true;

    if (_settings.targetFeatureToDisable == feature &&
        !_settings.isStrictModeDelayActive) {
      _settings = _settings.copyWith(
        clearStrictModeState: true,
      );
      await _settingsRepo.setStrictModeCountdownStart(null);
      await _settingsRepo.setTargetFeatureToDisable(null);
      notifyListeners();
      return true;
    }

    if (_settings.targetFeatureToDisable == null) {
      final now = DateTime.now();
      _settings = _settings.copyWith(
        strictModeCountdownStart: now,
        targetFeatureToDisable: feature,
      );
      await _settingsRepo.setStrictModeCountdownStart(now);
      await _settingsRepo.setTargetFeatureToDisable(feature);
      notifyListeners();
    }
    return false;
  }

  Future<void> toggleUninstallProtection(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('uninstall_protection');
      if (!allowed) return;
    }
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
    if (enabled) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
    _settings = _settings.copyWith(scrollLimitEnabled: enabled);
    await _settingsRepo.setScrollLimitEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleBreakEnabled(bool enabled) async {
    if (enabled) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
    _settings = _settings.copyWith(breakEnabled: enabled);
    await _settingsRepo.setBreakEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleDailyLimit(bool enabled) async {
    if (enabled) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
    _settings = _settings.copyWith(dailyLimitEnabled: enabled);
    await _settingsRepo.setDailyLimitEnabled(enabled);
    notifyListeners();
  }

  Future<void> updateDailyLimitMinutes(int minutes) async {
    _settings = _settings.copyWith(dailyLimitMinutes: minutes);
    await _settingsRepo.setDailyLimitMinutes(minutes);
    notifyListeners();
  }

  Future<void> toggleStrictMode(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('strict_mode');
      if (!allowed) return;
    } else {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
    _settings = _settings.copyWith(strictModeEnabled: enabled);
    await _settingsRepo.setStrictModeEnabled(enabled);
    if (!enabled) {
      _settings = _settings.copyWith(
        clearStrictModeState: true,
      );
      await _settingsRepo.setStrictModeCountdownStart(null);
      await _settingsRepo.setTargetFeatureToDisable(null);
    }
    notifyListeners();
  }

  Future<void> updateStrictModeDelay(int minutes) async {
    _settings = _settings.copyWith(strictModeDelayMinutes: minutes);
    // Don't save to repository here yet; it requires the user to click Save.
    notifyListeners();
  }

  bool isStrictModeDelayLocked() {
    if (_settings.strictModeDelayLockedUntil == null) return false;
    return DateTime.now().isBefore(_settings.strictModeDelayLockedUntil!);
  }

  Future<void> saveStrictModeDelay() async {
    if (isStrictModeDelayLocked()) return;

    // Lock for 15 days
    final lockedUntil = DateTime.now().add(const Duration(days: 15));
    _settings = _settings.copyWith(strictModeDelayLockedUntil: lockedUntil);

    await _settingsRepo
        .setStrictModeDelayMinutes(_settings.strictModeDelayMinutes);
    await _settingsRepo.setStrictModeDelayLockedUntil(lockedUntil);
    notifyListeners();
  }

  Future<void> startDisableCountdown(String feature) async {
    final now = DateTime.now();
    _settings = _settings.copyWith(
      strictModeCountdownStart: now,
      targetFeatureToDisable: feature,
    );
    await _settingsRepo.setStrictModeCountdownStart(now);
    await _settingsRepo.setTargetFeatureToDisable(feature);
    notifyListeners();
  }

  Future<void> clearDisableCountdown() async {
    _settings = _settings.copyWith(
      clearStrictModeState: true,
    );
    await _settingsRepo.setStrictModeCountdownStart(null);
    await _settingsRepo.setTargetFeatureToDisable(null);
    notifyListeners();
  }
}
