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

  Future<List<MindLockUsageInfo>> getDailyUsage() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);

      List<MindLockUsageInfo> infos = [];

      if (Platform.isAndroid) {
        final Map<dynamic, dynamic> usageMap =
            await _channel.invokeMethod('getPreciseUsage', {
          'start': startDate.millisecondsSinceEpoch,
          'end': endDate.millisecondsSinceEpoch,
        });

        List<AppInfo> installedApps =
            await InstalledApps.getInstalledApps(true, false);
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
          ));
        }
      }

      infos.sort((a, b) => b.usage.compareTo(a.usage));
      return infos;
    } catch (exception) {
      return [];
    }
  }

  Future<DailyUsageSummary> getUsageSummary() async {
    final usages = await getDailyUsage();

    Duration totalSocial = Duration.zero;
    Duration totalScreen = Duration.zero;

    for (var usage in usages) {
      totalScreen += usage.usage;
      if (AppConstants.socialMediaApps.containsKey(usage.packageName)) {
        totalSocial += usage.usage;
      }
    }

    return DailyUsageSummary(
      date: DateTime.now(),
      totalSocialMedia: totalSocial,
      totalScreen: totalScreen,
      appUsages: usages,
    );
  }
}
