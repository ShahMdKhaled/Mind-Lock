import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';
import '../../../data/repositories/study_stats_repository.dart';
import '../../../core/di/service_locator.dart';

class StudyStatsViewModel extends BaseViewModel {
  final StudyStatsRepository _repository;

  Map<String, int> _dailyStats = {};
  int _todayMinutes = 0;
  int _yesterdayMinutes = 0;

  Map<String, int> get dailyStats => _dailyStats;
  int get todayMinutes => _todayMinutes;
  int get yesterdayMinutes => _yesterdayMinutes;

  StudyStatsViewModel({StudyStatsRepository? repository})
      : _repository = repository ?? getIt<StudyStatsRepository>();

  Future<void> loadStats() async {
    setState(ViewState.busy);
    try {
      _dailyStats = await _repository.getDailyStats();
      _todayMinutes = await _repository.getTodayStudyMinutes();
      _yesterdayMinutes = await _repository.getYesterdayStudyMinutes();
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }
}
