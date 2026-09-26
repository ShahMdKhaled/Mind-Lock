import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/services/usage_data_service.dart';
import '../../../data/services/app_cache_service.dart' as import_app_cache;
import 'package:permission_handler/permission_handler.dart';

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

  final Map<String, AppInfo> _limitedAppsCache = {};

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepo.loadSettings();

    // Cache limited apps for instant display
    final futures = _settings.appLimits.keys.map((pkg) async {
      try {
        final info =
            await import_app_cache.AppCacheService.instance.getAppInfo(pkg);
        if (info != null) {
          _limitedAppsCache[pkg] = info;
        }
      } catch (_) {}
    });
    await Future.wait(futures);

    _isLoading = false;
    notifyListeners();
  }

  AppInfo? getCachedAppInfo(String packageName) {
    if (_limitedAppsCache.containsKey(packageName)) {
      return _limitedAppsCache[packageName];
    }
    try {
      return _installedApps.firstWhere((app) => app.packageName == packageName);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadInstalledApps() async {
    _isAppsLoading = true;
    notifyListeners();

    try {
      final allAppsRaw = await InstalledApps.getInstalledApps(false, false);
      final userAppsRaw = await InstalledApps.getInstalledApps(true, false);
      final userAppPackages = userAppsRaw.map((a) => a.packageName).toSet();

      final List<AppInfo> allApps = [];
      for (var app in allAppsRaw) {
        final cachedApp = await import_app_cache.AppCacheService.instance
            .getAppInfo(app.packageName);
        if (cachedApp != null) {
          allApps.add(cachedApp);
        } else {
          allApps.add(app);
        }
      }

      final usageInfos = await UsageDataService.instance.getDailyUsage();
      final usageMap = {
        for (var info in usageInfos) info.packageName: info.usage.inMilliseconds
      };

      _installedApps = allApps.where((app) {
        if (app.packageName == 'com.noorsoft.mindlock') return false;

        final pkg = app.packageName.toLowerCase();
        final isUserApp = userAppPackages.contains(app.packageName);
        final hasUsage = (usageMap[app.packageName] ?? 0) > 0;

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

        if (isUserApp) return true;
        if (allowedSystemApps.contains(pkg)) return true;

        if (hasUsage) {
          if (pkg == 'android' ||
              pkg == 'com.android.systemui' ||
              pkg.contains('launcher')) {
            return false;
          }
          return true;
        }

        return false;
      }).toList();

      _installedApps.sort((a, b) {
        final usageA = usageMap[a.packageName] ?? 0;
        final usageB = usageMap[b.packageName] ?? 0;
        if (usageA != usageB) {
          return usageB.compareTo(usageA);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
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

  Future<void> toggleMasterShield(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('app_limits');
      if (!allowed) return;
    } else {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
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
