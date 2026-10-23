import '../models/app_usage_info.dart';
import '../services/usage_data_service.dart';

// Repository that fetches formatted daily app usage summaries and statistics
class UsageRepository {
  final UsageDataService _usageDataService;

  UsageRepository({required UsageDataService usageDataService})
      : _usageDataService = usageDataService;

  Future<DailyUsageSummary> getUsageSummary({DateTime? targetDate}) async {
    return await _usageDataService.getUsageSummary(targetDate: targetDate);
  }

  Future<List<MindLockUsageInfo>> getDailyUsage({DateTime? targetDate}) async {
    return await _usageDataService.getDailyUsage(targetDate: targetDate);
  }
}
