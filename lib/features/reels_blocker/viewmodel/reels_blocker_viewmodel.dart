import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/permission_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class ReelsBlockerViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepo;
  final PermissionRepository _permissionRepo;

  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  final Map<String, Uint8List> _appIcons = {};

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isMasterEnabled => _settings.reelsBlockerEnabled;
  List<String> get blockedPackages => _settings.reelsBlockedPackages;
  Map<String, Uint8List> get appIcons => _appIcons;

  ReelsBlockerViewModel({SettingsRepository? settingsRepo, PermissionRepository? permissionRepo}) 
      : _settingsRepo = settingsRepo ?? getIt<SettingsRepository>(),
        _permissionRepo = permissionRepo ?? getIt<PermissionRepository>() {
    loadSettings();
  }

  Future<bool> checkPermissions() async {
    final usage = await _permissionRepo.isUsageAccessGranted();
    final access = await _permissionRepo.isAccessibilityServiceEnabled();
    final overlay = await _permissionRepo.isOverlayPermissionGranted();
    return usage && access && overlay;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepo.loadSettings();
    
    for (String pkg in AppConstants.reelsPackages) {
      try {
        final info = await InstalledApps.getAppInfo(pkg, null);
        if (info != null && info.icon != null) {
          _appIcons[pkg] = info.icon!;
        }
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> requestDisableFeature(String feature) async {
    if (!_settings.strictModeEnabled) return true;

    if (_settings.targetFeatureToDisable == feature && !_settings.isStrictModeDelayActive) {
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

  Future<void> toggleMasterShield(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('reels_blocker');
      if (!allowed) return;
    } else {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
    _settings = _settings.copyWith(reelsBlockerEnabled: enabled);
    await _settingsRepo.setReelsBlockerEnabled(enabled);
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

  Future<void> togglePackage(String packageName, bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('reels_blocker_$packageName');
      if (!allowed) return;
    }
    final updatedList = List<String>.from(_settings.reelsBlockedPackages);
    if (enabled) {
      if (!updatedList.contains(packageName)) updatedList.add(packageName);
    } else {
      updatedList.remove(packageName);
    }
    _settings = _settings.copyWith(reelsBlockedPackages: updatedList);
    await _settingsRepo.setReelsBlockedPackages(updatedList);
    notifyListeners();
  }

  bool isPackageBlocked(String packageName) {
    return _settings.reelsBlockedPackages.contains(packageName);
  }
}