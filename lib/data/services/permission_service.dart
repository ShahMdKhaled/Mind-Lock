import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.noorsoft.mindlock/permissions');

  Future<bool> isUsageAccessGranted() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isUsageAccessGranted');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isOverlayPermissionGranted() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  Future<bool> isNotificationPolicyAccessGranted() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isNotificationPolicyAccessGranted');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod('openUsageAccessSettings');
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (e) {
      await Permission.systemAlertWindow.request();
    }
  }

  Future<void> openNotificationPolicySettings() async {
    await _channel.invokeMethod('openNotificationPolicySettings');
  }

  Future<void> requestNotificationPermission() async {
    await Permission.notification.request();
  }
}