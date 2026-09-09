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

  Future<List<MindLockUsageInfo>> getDailyUsage({DateTime? targetDate}) async {
    try {
      DateTime now = targetDate ?? DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day);
      DateTime endDate = targetDate == null ? now : startDate.add(const Duration(days: 1));

      List<MindLockUsageInfo> infos = [];

      if (Platform.isAndroid) {
        final Map<dynamic, dynamic> usageMap =
            await _channel.invokeMethod('getPreciseUsage', {
          'start': startDate.millisecondsSinceEpoch,
          'end': endDate.millisecondsSinceEpoch,
        });

        List<AppInfo> rawInstalledApps =
            await InstalledApps.getInstalledApps(true, true);
        
        List<AppInfo> installedApps = rawInstalledApps.where((app) {
          if (app.packageName == 'com.noorsoft.mindlock') return false;
          final pkg = app.packageName.toLowerCase();
          final allowedSystemApps = [
            'com.google.android.youtube', 'com.android.chrome', 'com.google.android.gm',
            'com.google.android.apps.maps', 'com.google.android.apps.photos', 'com.google.android.apps.docs',
            'com.google.android.calculator', 'com.google.android.calendar', 'com.google.android.keep',
          ];
          if (allowedSystemApps.contains(pkg)) {
            return true;
          }
          if (pkg.startsWith('com.android.') || pkg.startsWith('com.google.android.') ||
              pkg.startsWith('com.samsung.') || pkg.startsWith('com.sec.') ||
              pkg.startsWith('com.miui.') || pkg.startsWith('com.coloros.') ||
              pkg.startsWith('com.oplus.') || pkg.startsWith('com.vivo.') ||
              pkg.startsWith('com.huawei.') || pkg.startsWith('com.oneplus.') ||
              pkg.startsWith('android')) {
            return false;
          }
          return true;
        }).toList();

        Map<String, AppInfo> appInfoMap = {
          for (var app in installedApps) app.packageName: app
        };

        usageMap.forEach((key, value) {
          String packageName = key.toString();
          int durationMs = (value as num).toInt();

          if (durationMs > 0 && packageName != 'com.noorsoft.mindlock') {
            final appInfo = appInfoMap[packageName];
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

        List<AppInfo> installedApps =
            await InstalledApps.getInstalledApps(true, false);
        Map<String, AppInfo> appInfoMap = {
          for (var app in installedApps) app.packageName: app
        };

        for (var usage in usageStats) {
          final appInfo = appInfoMap[usage.packageName];
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
