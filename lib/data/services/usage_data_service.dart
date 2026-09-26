import 'dart:io';
import 'package:flutter/services.dart';
import 'package:app_usage/app_usage.dart' as pkg;
import '../models/app_usage_info.dart';
import '../../core/constants.dart';
import 'app_cache_service.dart';
import 'package:installed_apps/installed_apps.dart' as import_installed_apps;

class UsageDataService {
  static const MethodChannel _channel =
      MethodChannel('com.noorsoft.mindlock/permissions');
  static UsageDataService? _instance;
  static UsageDataService get instance => _instance ??= UsageDataService._();
  UsageDataService._();

  static Set<String>? _validPackagesCache;

  Future<Set<String>> _getValidPackages() async {
    if (_validPackagesCache != null) return _validPackagesCache!;

    try {
      final userApps =
          await import_installed_apps.InstalledApps.getInstalledApps(
              true, false);
      _validPackagesCache = userApps.map((a) => a.packageName).toSet();
    } catch (_) {
      _validPackagesCache = {};
    }

    final allowedSystemApps = {
      'com.google.android.youtube',
      'com.android.chrome',
      'com.google.android.gm',
      'com.google.android.apps.maps',
      'com.google.android.apps.photos',
      'com.google.android.apps.docs',
      'com.google.android.calculator',
      'com.google.android.calendar',
      'com.google.android.keep',
    };

    _validPackagesCache!.addAll(allowedSystemApps);
    return _validPackagesCache!;
  }

  Future<List<MindLockUsageInfo>> getDailyUsage({DateTime? targetDate}) async {
    try {
      DateTime now = targetDate ?? DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day);
      DateTime endDate =
          targetDate == null ? now : startDate.add(const Duration(days: 1));

      List<MindLockUsageInfo> infos = [];
      final validPackages = await _getValidPackages();

      if (Platform.isAndroid) {
        final Map<dynamic, dynamic> usageMap =
            await _channel.invokeMethod('getPreciseUsage', {
          'start': startDate.millisecondsSinceEpoch,
          'end': endDate.millisecondsSinceEpoch,
        });

        for (var entry in usageMap.entries) {
          String packageName = entry.key.toString();
          int durationMs = (entry.value as num).toInt();

          if (durationMs > 0 && packageName != 'com.noorsoft.mindlock') {
            if (!validPackages.contains(packageName)) continue;

            final appInfo =
                await AppCacheService.instance.getAppInfo(packageName);
            if (appInfo != null) {
              infos.add(MindLockUsageInfo(
                packageName: packageName,
                appName: appInfo.name,
                usage: Duration(milliseconds: durationMs),
                date: startDate,
                icon: appInfo.icon,
              ));
            }
          }
        }
      } else {
        // Fallback or iOS logic if ever needed
        List<pkg.AppUsageInfo> usageStats =
            await pkg.AppUsage().getAppUsage(startDate, endDate);

        for (var usage in usageStats) {
          if (usage.packageName == 'com.noorsoft.mindlock') {
            continue;
          }
          if (!validPackages.contains(usage.packageName)) continue;

          final appInfo =
              await AppCacheService.instance.getAppInfo(usage.packageName);
          if (appInfo == null) continue;

          infos.add(MindLockUsageInfo(
            packageName: usage.packageName,
            appName: appInfo.name,
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
