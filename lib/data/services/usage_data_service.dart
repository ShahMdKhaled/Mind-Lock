import 'dart:io';
import 'package:flutter/services.dart';
import 'package:app_usage/app_usage.dart' as pkg;
import '../models/app_usage_info.dart';
import '../../core/constants.dart';

import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class UsageDataService {
  static const MethodChannel _channel =
      MethodChannel('com.noorsoft.mindlock/permissions');
  static UsageDataService? _instance;
  static UsageDataService get instance => _instance ??= UsageDataService._();
  UsageDataService._();

  final Map<String, AppInfo> _appInfoCache = {};
  final Set<String> _validPackages = {};
  bool _isCacheInitialized = false;

  Future<void> _ensureCache() async {
    if (_isCacheInitialized) return;

    List<AppInfo> rawInstalledApps =
        await InstalledApps.getInstalledApps(false, true);
    List<AppInfo> userApps =
        await InstalledApps.getInstalledApps(true, false);
    Set<String> userAppPackages = userApps.map((a) => a.packageName).toSet();

    final allowedSystemApps = [
      'com.google.android.youtube',
      'com.android.chrome',
      'com.google.android.gm',
      'com.google.android.apps.maps',
      'com.google.android.apps.photos',
      'com.google.android.apps.docs',
      'com.google.android.calculator',
      'com.google.android.calendar',
      'com.google.android.keep',
    ];

    for (var app in rawInstalledApps) {
      _appInfoCache[app.packageName] = app;
      final pkg = app.packageName.toLowerCase();
      if (userAppPackages.contains(app.packageName) || allowedSystemApps.contains(pkg)) {
        _validPackages.add(app.packageName);
      }
    }
    _isCacheInitialized = true;
  }

  Future<List<MindLockUsageInfo>> getDailyUsage({DateTime? targetDate}) async {
    try {
      DateTime now = targetDate ?? DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day);
      DateTime endDate = targetDate == null ? now : startDate.add(const Duration(days: 1));

      List<MindLockUsageInfo> infos = [];
      await _ensureCache();

      if (Platform.isAndroid) {
        final Map<dynamic, dynamic> usageMap =
            await _channel.invokeMethod('getPreciseUsage', {
          'start': startDate.millisecondsSinceEpoch,
          'end': endDate.millisecondsSinceEpoch,
        });

        usageMap.forEach((key, value) {
          String packageName = key.toString();
          int durationMs = (value as num).toInt();

          if (durationMs > 0 && packageName != 'com.noorsoft.mindlock') {
            if (!_validPackages.contains(packageName)) return;
            
            final appInfo = _appInfoCache[packageName];
            if (appInfo != null) {
              String appName = appInfo.name;
              infos.add(MindLockUsageInfo(
                packageName: packageName,
                appName: appName,
                usage: Duration(milliseconds: durationMs),
                date: startDate,
                icon: appInfo.icon,
              ));
            }
          }
        });
      } else {
        // Fallback or iOS logic if ever needed
        List<pkg.AppUsageInfo> usageStats =
            await pkg.AppUsage().getAppUsage(startDate, endDate);

        for (var usage in usageStats) {
          if (!_validPackages.contains(usage.packageName)) continue;
          
          final appInfo = _appInfoCache[usage.packageName];
          if (appInfo == null || usage.packageName == 'com.noorsoft.mindlock') {
            continue;
          }

          String appName = appInfo.name;

          infos.add(MindLockUsageInfo(
            packageName: usage.packageName,
            appName: appName,
            usage: usage.usage,
            date: startDate,
            icon: appInfo.icon,
          ));
        }
      }

      infos.sort((a, b) => b.usage.compareTo(a.usage));
      return infos;
    } catch (exception) {
      return [];
    }
  }

  Future<DailyUsageSummary> getUsageSummary({DateTime? targetDate}) async {
    final usages = await getDailyUsage(targetDate: targetDate);

    Duration totalSocial = Duration.zero;
    Duration totalScreen = Duration.zero;

    for (var usage in usages) {
      totalScreen += usage.usage;
      if (AppConstants.socialMediaApps.containsKey(usage.packageName)) {
        totalSocial += usage.usage;
      }
    }

    return DailyUsageSummary(
      date: targetDate ?? DateTime.now(),
      totalSocialMedia: totalSocial,
      totalScreen: totalScreen,
      appUsages: usages,
    );
  }
}
