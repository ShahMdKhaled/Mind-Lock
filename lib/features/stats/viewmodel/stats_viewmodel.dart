import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';
import '../../../data/models/app_usage_info.dart';
import '../../../data/repositories/usage_repository.dart';
import '../../../core/di/service_locator.dart';

class StatsViewModel extends BaseViewModel {
  final UsageRepository _usageRepo;

  DailyUsageSummary? _summary;

  DailyUsageSummary? get summary => _summary;

  StatsViewModel({UsageRepository? usageRepo}) : _usageRepo = usageRepo ?? getIt<UsageRepository>();

  Future<void> refreshUsage() async {
    setState(ViewState.loading);
    try {
      _summary = await _usageRepo.getUsageSummary();
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  List<MindLockUsageInfo> get topApps => _summary?.appUsages.take(10).toList() ?? [];
}