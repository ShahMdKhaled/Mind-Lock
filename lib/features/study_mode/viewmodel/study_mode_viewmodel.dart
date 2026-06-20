import 'dart:async';
import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';
import '../../../data/services/study_mode_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/study_stats_repository.dart';
import '../../../core/di/service_locator.dart';

class StudyModeViewModel extends BaseViewModel {
  final StudyModeService _studyModeService;
  final NotificationService _notificationService;
  final SettingsRepository _settingsRepo;
  final StudyStatsRepository _studyStatsRepo;

  Timer? _timer;
  int _selectedMinutes = 30;
  int _elapsedSeconds = 0;
  bool _isActive = false;

  int get selectedMinutes => _selectedMinutes;
  int get secondsRemaining {
    int remaining = (_selectedMinutes * 60) - _elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  int get overtimeSeconds {
    int overtime = _elapsedSeconds - (_selectedMinutes * 60);
    return overtime > 0 ? overtime : 0;
  }

  bool get isActive => _isActive;

  double get progress {
    if (_selectedMinutes == 0) return 0;
    double p = _elapsedSeconds / (_selectedMinutes * 60);
    return p > 1.0 ? 1.0 : p;
  }

  String get formattedTime {
    if (overtimeSeconds > 0) {
      int mins = overtimeSeconds ~/ 60;
      int secs = overtimeSeconds % 60;
      return '+${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      int mins = secondsRemaining ~/ 60;
      int secs = secondsRemaining % 60;
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  StudyModeViewModel({
    StudyModeService? studyModeService,
    NotificationService? notificationService,
    SettingsRepository? settingsRepo,
    StudyStatsRepository? studyStatsRepo,
  })  : _studyModeService = studyModeService ?? getIt<StudyModeService>(),
        _notificationService =
            notificationService ?? getIt<NotificationService>(),
        _settingsRepo = settingsRepo ?? getIt<SettingsRepository>(),
        _studyStatsRepo = studyStatsRepo ?? getIt<StudyStatsRepository>() {
    _init();
  }

  void _init() {
    // Reset study mode to false on startup to prevent being stuck in a blocked state
    _settingsRepo.setStudyModeEnabled(false);
  }

  void setDuration(int minutes) {
    if (minutes >= 30 && !_isActive) {
      _selectedMinutes = minutes;
      notifyListeners();
    }
  }

  Future<bool> checkPermission() async {
    return await _studyModeService.checkNotificationPolicyPermission();
  }

  void toggleSession() {
    if (_isActive) {
      _stopSession();
    } else {
      _startSession();
    }
  }

  Future<void> _startSession() async {
    setState(ViewState.busy);
    try {
      _isActive = true;
      _elapsedSeconds = 0;
      await _studyModeService.activate();
      try {
        await _notificationService.showStudyModeNotification();
      } catch (_) {}
      await _settingsRepo.setStudyModeEnabled(true);

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        notifyListeners();
      });
      setState(ViewState.idle);
    } catch (e) {
      _isActive = false;
      setError(e.toString());
    }
  }

  Future<void> _stopSession() async {
    _timer?.cancel();
    _isActive = false;

    try {
      // Save the session to stats
      int minutesSpent = _elapsedSeconds ~/ 60;
      if (minutesSpent > 0) {
        await _studyStatsRepo.saveSession(minutesSpent);
      }

      _elapsedSeconds = 0;
      await _studyModeService.deactivate();
      try {
        await _notificationService.cancelStudyModeNotification();
      } catch (_) {}
      await _settingsRepo.setStudyModeEnabled(false);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
