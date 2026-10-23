import 'dart:async';
import '../../../core/viewmodel/base_viewmodel.dart';
import '../../../core/viewmodel/view_state.dart';
import '../../../data/services/study_mode_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/study_stats_repository.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../core/di/service_locator.dart';

// ViewModel for handling the Study Mode timer, focus sessions, and saving study statistics
class StudyModeViewModel extends BaseViewModel {
  final StudyModeService _studyModeService;
  final NotificationService _notificationService;
  final SettingsRepository _settingsRepo;
  final StudyStatsRepository _studyStatsRepo;

  Timer? _timer;

  // Standard recommended deep focus time (2 hours / 120 minutes)
  static const int recommendedMinutes = 120;

  int _selectedMinutes = recommendedMinutes;
  int _elapsedSeconds = 0;
  bool _isActive = false;

  int get selectedMinutes => _selectedMinutes;
  int get recommendedDuration => recommendedMinutes;
  bool get isRecommendedSelected => _selectedMinutes == recommendedMinutes;

  int get secondsRemaining {
    int remaining = (_selectedMinutes * 60) - _elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  int get overtimeSeconds {
    int overtime = _elapsedSeconds - (_selectedMinutes * 60);
    return overtime > 0 ? overtime : 0;
  }

  bool get isOvertime => overtimeSeconds > 0;
  bool get isActive => _isActive;
  int get elapsedSeconds => _elapsedSeconds;

  double get progress {
    if (_selectedMinutes == 0) return 0;
    double p = _elapsedSeconds / (_selectedMinutes * 60);
    return p > 1.0 ? 1.0 : p;
  }

  // Formats the remaining or overtime focus duration into MM:SS or HH:MM:SS
  String get formattedTime {
    if (overtimeSeconds > 0) {
      int hours = overtimeSeconds ~/ 3600;
      int mins = (overtimeSeconds % 3600) ~/ 60;
      int secs = overtimeSeconds % 60;
      if (hours > 0) {
        return '+${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      }
      return '+${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      int hours = secondsRemaining ~/ 3600;
      int mins = (secondsRemaining % 3600) ~/ 60;
      int secs = secondsRemaining % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      }
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Total session time formatted (e.g., "28:15" or "01:05:20")
  String get totalFormattedTime {
    int hours = _elapsedSeconds ~/ 3600;
    int mins = (_elapsedSeconds % 3600) ~/ 60;
    int secs = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

  void _init() async {
    // Reset study mode to false on startup to prevent being stuck in a blocked state
    _settingsRepo.setStudyModeEnabled(false);

    try {
      final prefs = LocalStorageService.instance.prefs;
      final savedMins = prefs.getInt('study_mode_target_minutes');
      if (savedMins != null && savedMins >= 5 && savedMins <= 360) {
        _selectedMinutes = savedMins;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Updates the target duration for a focus session before it starts (min 5, max 360 mins / 6h)
  void setDuration(int minutes) {
    if (minutes >= 5 && minutes <= 360 && !_isActive) {
      _selectedMinutes = minutes;
      try {
        LocalStorageService.instance.prefs
            .setInt('study_mode_target_minutes', minutes);
      } catch (_) {}
      notifyListeners();
    }
  }

  void resetToRecommended() {
    setDuration(recommendedMinutes);
  }

  // Extends the current active focus session by a specified number of minutes
  void extendDuration(int addMinutes) {
    if (_isActive && addMinutes > 0) {
      _selectedMinutes += addMinutes;
      notifyListeners();
    }
  }

  Future<bool> checkPermission() async {
    return await _studyModeService.checkNotificationPolicyPermission();
  }

  Future<int?> toggleSession() async {
    if (_isActive) {
      return await _stopSession();
    } else {
      await _startSession();
      return null;
    }
  }

  // Starts a new focus session by activating DND and starting the timer
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

      _timer?.cancel();
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

  Future<int> _stopSession() async {
    _timer?.cancel();
    _isActive = false;
    final int minutesSpent = _elapsedSeconds ~/ 60;

    try {
      // Save the session to stats (including any overtime!)
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
    return minutesSpent;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
