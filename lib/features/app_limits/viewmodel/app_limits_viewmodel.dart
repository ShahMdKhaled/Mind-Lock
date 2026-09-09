import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/di/service_locator.dart';

class AppLimitsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepo;

  AppSettings _settings = AppSettings();
  List<AppInfo> _installedApps = [];
  String _searchQuery = "";
  bool _isLoading = false;
  bool _isAppsLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isAppsLoading => _isAppsLoading;
  bool get appLimitsEnabled => _settings.appLimitsEnabled;
  Map<String, int> get appLimits => _settings.appLimits;
  String get searchQuery => _searchQuery;

  AppLimitsViewModel({SettingsRepository? settingsRepo})
      : _settingsRepo = settingsRepo ?? getIt<SettingsRepository>() {
    loadSettings();
    loadInstalledApps();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepo.loadSettings();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInstalledApps() async {
    _isAppsLoading = true;
    notifyListeners();

    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      _installedApps = apps.where((app) {
        if (app.packageName == 'com.noorsoft.mindlock') return false;
        
        final pkg = app.packageName.toLowerCase();

        // Allowed list of Google/Android apps that users typically want to limit
        final allowedSystemApps = [
          'com.google.android.youtube',
          'com.android.chrome',
          'com.google.android.gm', // Gmail
          'com.google.android.apps.maps',
          'com.google.android.apps.photos',
          'com.google.android.apps.docs',
          'com.google.android.calculator',
          'com.google.android.calendar',
          'com.google.android.keep',
        ];

        if (allowedSystemApps.contains(pkg)) {
          return true;
        }

        // Manually filter out common system/manufacturer packages that might bypass the plugin's FLAG_SYSTEM check
        if (pkg.startsWith('com.android.') ||
            pkg.startsWith('com.google.android.') ||
            pkg.startsWith('com.samsung.') ||
            pkg.startsWith('com.sec.') ||
            pkg.startsWith('com.miui.') ||
            pkg.startsWith('com.coloros.') ||
            pkg.startsWith('com.oplus.') ||
            pkg.startsWith('com.vivo.') ||
            pkg.startsWith('com.huawei.') ||
            pkg.startsWith('com.oneplus.') ||
            pkg.startsWith('android')) {
          return false;
        }
        return true;
      }).toList();
      _installedApps
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      if (kDebugMode) {
        print("Error loading installed apps: $e");
      }
    } finally {
      _isAppsLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<AppInfo> get filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps
        .where((app) =>
            app.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
      final allowed = await requestDisableFeature('app_limits_master');
      if (!allowed) return;
    }
    _settings = _settings.copyWith(appLimitsEnabled: enabled);
    await _settingsRepo.setAppLimitsEnabled(enabled);
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

  Future<void> setAppLimit(String packageName, int minutes) async {
    final updatedLimits = Map<String, int>.from(_settings.appLimits);
    updatedLimits[packageName] = minutes;

    _settings = _settings.copyWith(appLimits: updatedLimits);
    await _settingsRepo.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> removeAppLimit(String packageName) async {
    final updatedLimits = Map<String, int>.from(_settings.appLimits);
    updatedLimits.remove(packageName);

    _settings = _settings.copyWith(appLimits: updatedLimits);
    await _settingsRepo.saveSettings(_settings);
    notifyListeners();
  }

  bool isAppLimited(String packageName) {
    return _settings.appLimits.containsKey(packageName);
  }

  int? getLimitForApp(String packageName) {
    return _settings.appLimits[packageName];
  }
}
