import 'package:flutter/foundation.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/di/service_locator.dart';

class ReelsBlockerViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepo;

  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isMasterEnabled => _settings.reelsBlockerEnabled;
  List<String> get blockedPackages => _settings.reelsBlockedPackages;

  ReelsBlockerViewModel({SettingsRepository? settingsRepo}) : _settingsRepo = settingsRepo ?? getIt<SettingsRepository>() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepo.loadSettings();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> requestDisableFeature(String feature) async {
    if (!_settings.strictModeEnabled) return true;

    if (_settings.targetFeatureToDisable == feature && !_settings.isStrictModeDelayActive) {
      _settings = _settings.copyWith(
        strictModeCountdownStart: null,
        targetFeatureToDisable: null,
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
    }
    _settings = _settings.copyWith(reelsBlockerEnabled: enabled);
    await _settingsRepo.setReelsBlockerEnabled(enabled);
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