import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/constants.dart';
import 'core/di/service_locator.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final packageInfo = await PackageInfo.fromPlatform();
  AppConstants.appVersion = packageInfo.version;
  AppConstants.appBuildNumber = packageInfo.buildNumber;

  await setupServiceLocator();
  runApp(const MindLockApp());
}
