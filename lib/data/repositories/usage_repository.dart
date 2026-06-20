import '../models/app_usage_info.dart';
import '../services/usage_data_service.dart';

class UsageRepository {
  final UsageDataService _usageDataService;

  UsageRepository({required UsageDataService usageDataService}) : _usageDataService = usageDataService;

  Future<DailyUsageSummary> getUsageSummary() async {
    return await _usageDataService.getUsageSummary();
  }

  Future<List<MindLockUsageInfo>> getDailyUsage() async {
    return await _usageDataService.getDailyUsage();
  }
}