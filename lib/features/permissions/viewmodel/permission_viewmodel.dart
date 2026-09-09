import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';
import '../../../data/repositories/permission_repository.dart';
import '../../../data/services/study_mode_service.dart';
import '../../../core/di/service_locator.dart';

class PermissionViewModel extends BaseViewModel {
  final PermissionRepository _permissionRepo;

  bool _isUsageGranted = false;
  bool _isAccessibilityEnabled = false;
  bool _isOverlayGranted = false;
  bool _isNotificationGranted = false;
  bool _isDndGranted = false;

  bool get isUsageGranted => _isUsageGranted;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isOverlayGranted => _isOverlayGranted;
  bool get isNotificationGranted => _isNotificationGranted;
  bool get isDndGranted => _isDndGranted;
  bool get allGranted => _isUsageGranted && _isAccessibilityEnabled && _isOverlayGranted && _isNotificationGranted && _isDndGranted;

  PermissionViewModel({PermissionRepository? permissionRepo}) : _permissionRepo = permissionRepo ?? getIt<PermissionRepository>() {
    checkAll();
  }

  Future<void> checkAll({bool delayed = false}) async {
    if (delayed) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    setState(ViewState.loading);
    try {
      _isUsageGranted = await _permissionRepo.isUsageAccessGranted();
      _isAccessibilityEnabled = await _permissionRepo.isAccessibilityServiceEnabled();
      _isOverlayGranted = await _permissionRepo.isOverlayPermissionGranted();
      _isNotificationGranted = await _permissionRepo.isNotificationPermissionGranted();
      _isDndGranted = await getIt<StudyModeService>().checkNotificationPolicyPermission();
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> requestUsage() async {
    await _permissionRepo.openUsageAccessSettings();
  }

  Future<void> requestAccessibility() async {
    await _permissionRepo.openAccessibilitySettings();
  }

  Future<void> requestOverlay() async {
    await _permissionRepo.requestOverlayPermission();
    await checkAll(delayed: true);
  }

  Future<void> requestNotification() async {
    await _permissionRepo.requestNotificationPermission();
    await checkAll(delayed: true);
  }

  Future<void> requestDnd() async {
    await getIt<StudyModeService>().requestNotificationPolicyPermission();
    await checkAll(delayed: true);
  }
}