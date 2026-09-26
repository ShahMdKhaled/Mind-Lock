import '../services/permission_service.dart';

class PermissionRepository {
  final PermissionService _permissionService;

  PermissionRepository({required PermissionService permissionService}) : _permissionService = permissionService;

  Future<bool> isUsageAccessGranted() async {
    return await _permissionService.isUsageAccessGranted();
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    return await _permissionService.isAccessibilityServiceEnabled();
  }

  Future<bool> isOverlayPermissionGranted() async {
    return await _permissionService.isOverlayPermissionGranted();
  }

  Future<bool> isNotificationPermissionGranted() async {
    return await _permissionService.isNotificationPermissionGranted();
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    return await _permissionService.isBatteryOptimizationIgnored();
  }

  Future<void> openUsageAccessSettings() async {
    await _permissionService.openUsageAccessSettings();
  }

  Future<void> openAccessibilitySettings() async {
    await _permissionService.openAccessibilitySettings();
  }

  Future<void> requestOverlayPermission() async {
    await _permissionService.requestOverlayPermission();
  }

  Future<void> requestNotificationPermission() async {
    await _permissionService.requestNotificationPermission();
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    await _permissionService.requestIgnoreBatteryOptimization();
  }
}