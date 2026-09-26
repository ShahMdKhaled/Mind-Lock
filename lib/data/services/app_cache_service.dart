import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppCacheService {
  static AppCacheService? _instance;
  static AppCacheService get instance => _instance ??= AppCacheService._();
  AppCacheService._();

  Database? _db;
  final Map<String, AppInfo> _memoryCache = {};

  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_cache.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_apps (
            package_name TEXT PRIMARY KEY,
            app_name TEXT,
            icon BLOB
          )
        ''');
      },
    );

    // Fire and forget cache cleanup
    cleanUpCache();
  }

  Future<AppInfo?> getAppInfo(String packageName) async {
    if (_memoryCache.containsKey(packageName)) {
      return _memoryCache[packageName];
    }

    await init();

    final List<Map<String, dynamic>> maps = await _db!.query(
      'cached_apps',
      where: 'package_name = ?',
      whereArgs: [packageName],
    );

    if (maps.isNotEmpty) {
      final appName = maps.first['app_name'] as String;
      final icon = maps.first['icon'] as Uint8List?;
      final info = AppInfo(
        name: appName,
        icon: icon,
        packageName: packageName,
        versionName: "",
        versionCode: 0,
        builtWith: BuiltWith.native_or_others,
        installedTimestamp: 0,
      );
      _memoryCache[packageName] = info;
      return info;
    }

    // Not in DB, fetch from OS
    try {
      final appInfo = await InstalledApps.getAppInfo(packageName, null);
      if (appInfo != null) {
        await _db!.insert(
          'cached_apps',
          {
            'package_name': appInfo.packageName,
            'app_name': appInfo.name,
            'icon': appInfo.icon,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        _memoryCache[packageName] = appInfo;
        return appInfo;
      }
    } catch (_) {}

    return null;
  }

  /// Removes uninstalled apps from the cache database and memory.
  Future<void> cleanUpCache() async {
    await init();
    try {
      // Get all currently installed apps (extremely fast without icons)
      final installedApps = await InstalledApps.getInstalledApps(false, false);
      final installedPackageNames =
          installedApps.map((e) => e.packageName).toSet();

      // Get all cached package names from DB
      final List<Map<String, dynamic>> cachedMaps =
          await _db!.query('cached_apps', columns: ['package_name']);
      final List<String> packagesToDelete = [];

      for (var map in cachedMaps) {
        final pkg = map['package_name'] as String;
        if (!installedPackageNames.contains(pkg)) {
          packagesToDelete.add(pkg);
        }
      }

      // Delete from DB and memory
      if (packagesToDelete.isNotEmpty) {
        final batch = _db!.batch();
        for (var pkg in packagesToDelete) {
          batch.delete('cached_apps',
              where: 'package_name = ?', whereArgs: [pkg]);
          _memoryCache.remove(pkg);
        }
        await batch.commit(noResult: true);
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}
