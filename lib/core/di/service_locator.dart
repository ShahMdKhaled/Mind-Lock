import 'package:get_it/get_it.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/usage_repository.dart';
import '../../data/repositories/permission_repository.dart';
import '../../data/repositories/study_stats_repository.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/usage_data_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/study_mode_service.dart';
import '../../data/services/notification_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final localStorage = LocalStorageService.instance;
  await localStorage.init();

  getIt.registerSingleton<LocalStorageService>(localStorage);
  getIt.registerSingleton<UsageDataService>(UsageDataService.instance);
  getIt.registerSingleton<PermissionService>(PermissionService());
  getIt.registerSingleton<StudyModeService>(StudyModeService.instance);
  getIt.registerSingleton<NotificationService>(NotificationService.instance);

  getIt.registerSingleton<SettingsRepository>(
    SettingsRepository(localStorage: getIt<LocalStorageService>()),
  );
  getIt.registerSingleton<UsageRepository>(
    UsageRepository(usageDataService: getIt<UsageDataService>()),
  );
  getIt.registerSingleton<PermissionRepository>(
    PermissionRepository(permissionService: getIt<PermissionService>()),
  );
  getIt.registerSingleton<StudyStatsRepository>(
    StudyStatsRepository(),
  );
}
