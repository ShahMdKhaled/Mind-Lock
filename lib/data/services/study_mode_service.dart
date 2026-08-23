import 'package:volume_controller/volume_controller.dart';
import 'package:flutter/services.dart';

class StudyModeService {
  static StudyModeService? _instance;
  static StudyModeService get instance => _instance ??= StudyModeService._();
  StudyModeService._();

  static const MethodChannel _channel =
      MethodChannel('com.noorsoft.mindlock/permissions');
  final VolumeController _volumeController = VolumeController.instance;
  double _originalVolume = 0.5;

  Future<void> activate() async {
    try {
      _originalVolume = await _volumeController.getVolume();
      _volumeController.setVolume(0);
      _volumeController.showSystemUI = false;
    } catch (e) {
      // Ignore volume control errors
    }

    try {
      await _channel
          .invokeMethod('setNotificationPolicyControl', {'enabled': true});
    } catch (e) {
      // Ignored
    }
  }

  Future<void> deactivate() async {
    try {
      _volumeController.setVolume(_originalVolume);
      _volumeController.showSystemUI = true;
    } catch (e) {
      // Ignore volume control errors
    }

    try {
      await _channel
          .invokeMethod('setNotificationPolicyControl', {'enabled': false});
    } catch (e) {
      // Ignored
    }
  }

  Future<bool> checkNotificationPolicyPermission() async {
    try {
      final bool? result = await _channel
          .invokeMethod<bool>('isNotificationPolicyAccessGranted');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
