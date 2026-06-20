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
      _installedApps = apps
          .where((app) => app.packageName != 'com.example.mindlock')
          .toList();
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

  Future<void> toggleMasterShield(bool enabled) async {
    _settings = _settings.copyWith(appLimitsEnabled: enabled);
    await _settingsRepo.saveSettings(_settings);
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
