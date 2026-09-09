import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';
import '../../../data/models/app_usage_info.dart';
import '../../../data/repositories/usage_repository.dart';
import '../../../core/di/service_locator.dart';

class StatsViewModel extends BaseViewModel {
  final UsageRepository _usageRepo;

  DailyUsageSummary? _summary;
  List<DailyUsageSummary> _weeklyData = [];

  DailyUsageSummary? get summary => _summary;
  List<DailyUsageSummary> get weeklyData => _weeklyData;

  StatsViewModel({UsageRepository? usageRepo}) : _usageRepo = usageRepo ?? getIt<UsageRepository>();

  Future<void> refreshUsage() async {
    setState(ViewState.loading);
    try {
      _summary = await _usageRepo.getUsageSummary();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Fetch last 7 days including today
      List<Future<DailyUsageSummary>> futures = [];
      for (int i = 6; i >= 0; i--) {
        futures.add(_usageRepo.getUsageSummary(targetDate: today.subtract(Duration(days: i))));
      }
      _weeklyData = await Future.wait(futures);
      
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  List<MindLockUsageInfo> get topApps => _summary?.appUsages.take(10).toList() ?? [];
}