import '../../../data/models/app_settings.dart';
import '../../../data/models/app_usage_info.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/usage_repository.dart';
import '../../../data/repositories/permission_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/services/study_mode_service.dart';
import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';

class HomeViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepo;
  final UsageRepository _usageRepo;
  final PermissionRepository _permissionRepo;

  AppSettings _settings = AppSettings();
  DailyUsageSummary? _summary;
  DailyUsageSummary? _yesterdaySummary;
  bool _permissionsGranted = false;

  AppSettings get settings => _settings;
  DailyUsageSummary? get summary => _summary;
  DailyUsageSummary? get yesterdaySummary => _yesterdaySummary;
  bool get permissionsGranted => _permissionsGranted;

  HomeViewModel({
    SettingsRepository? settingsRepo,
    UsageRepository? usageRepo,
    PermissionRepository? permissionRepo,
  })  : _settingsRepo = settingsRepo ?? getIt<SettingsRepository>(),
        _usageRepo = usageRepo ?? getIt<UsageRepository>(),
        _permissionRepo = permissionRepo ?? getIt<PermissionRepository>() {
    loadData();
  }

  Future<void> loadData({bool delayed = false}) async {
    if (delayed) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(ViewState.loading);
    try {
      _settings = await _settingsRepo.loadSettings();
      _permissionsGranted = await _checkPermissions();
      await refreshUsage();
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<bool> _checkPermissions() async {
    final usage = await _permissionRepo.isUsageAccessGranted();
    final accessibility = await _permissionRepo.isAccessibilityServiceEnabled();
    final overlay = await _permissionRepo.isOverlayPermissionGranted();
    final notification =
        await _permissionRepo.isNotificationPermissionGranted();
    final dnd =
        await getIt<StudyModeService>().checkNotificationPolicyPermission();
    return usage && accessibility && overlay && notification && dnd;
  }

  Future<void> refreshUsage() async {
    if (!_permissionsGranted) {
      if (state == ViewState.loading) setState(ViewState.idle);
      return;
    }
    _summary = await _usageRepo.getUsageSummary();
    final now = DateTime.now();
    _yesterdaySummary = await _usageRepo.getUsageSummary(
        targetDate: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1)));
    notifyListeners();
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

  Future<void> toggleReelsBlocker(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('reels_blocker');
      if (!allowed) return;
    }
    _settings = _settings.copyWith(reelsBlockerEnabled: enabled);
    await _settingsRepo.setReelsBlockerEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleStudyMode(bool enabled) async {
    _settings = _settings.copyWith(studyModeEnabled: enabled);
    await _settingsRepo.setStudyModeEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleUninstallProtection(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('uninstall_protection');
      if (!allowed) return;
    }
    _settings = _settings.copyWith(uninstallProtectionEnabled: enabled);
    await _settingsRepo.setUninstallProtection(enabled);
    notifyListeners();
  }

  Future<void> toggleAppLimits(bool enabled) async {
    if (!enabled) {
      final allowed = await requestDisableFeature('app_limits');
      if (!allowed) return;
    }
    _settings = _settings.copyWith(appLimitsEnabled: enabled);
    await _settingsRepo.setAppLimitsEnabled(enabled);
    notifyListeners();
  }

  int get totalScreenMinutes => _summary?.totalScreen.inMinutes ?? 0;
  int get yesterdayScreenMinutes =>
      _yesterdaySummary?.totalScreen.inMinutes ?? 0;

  int get socialMediaMinutes => _summary?.totalSocialMedia.inMinutes ?? 0;
  int get dailyBreaksCount => _settingsRepo.getDailyBreaksCount();

  String get formattedScreenTime {
    final mins = totalScreenMinutes;
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  String get screenTimeChangeText {
    if (_yesterdaySummary == null || _summary == null) return 'Calculating...';

    if (yesterdayScreenMinutes == 0) {
      if (totalScreenMinutes == 0) return 'Same as yesterday';
      return '+100% from yesterday';
    }

    final double change = ((totalScreenMinutes - yesterdayScreenMinutes) /
            yesterdayScreenMinutes) *
        100;

    if (change > 0) {
      return '+${change.toStringAsFixed(0)}% from yesterday';
    } else if (change < 0) {
      return '${change.toStringAsFixed(0)}% from yesterday';
    } else {
      return 'Same as yesterday';
    }
  }
}
