import 'dart:convert';
import '../services/local_storage_service.dart';

// Repository for storing and retrieving user's daily study mode focus statistics
class StudyStatsRepository {
  final LocalStorageService _storageService = LocalStorageService.instance;

  static const String _keyDailyStats = 'study_daily_stats_json';

  // Retrieves the complete history of daily study times recorded in local storage
  Future<Map<String, int>> getDailyStats() async {
    await _storageService.init();
    final jsonStr = _storageService.get(_keyDailyStats, null) as String?;
    if (jsonStr == null) return {};

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  // Saves a completed study session's duration (in minutes) to today's log
  Future<void> saveSession(int minutes) async {
    final stats = await getDailyStats();
    final today = _getDateString(DateTime.now());

    final currentMinutes = stats[today] ?? 0;
    stats[today] = currentMinutes + minutes;

    await _saveStats(stats);
  }

  Future<void> _saveStats(Map<String, int> stats) async {
    // Keep only last 30 days
    if (stats.length > 30) {
      final sortedKeys = stats.keys.toList()..sort();
      final keysToRemove = sortedKeys.take(stats.length - 30);
      for (var key in keysToRemove) {
        stats.remove(key);
      }
    }

    final jsonStr = jsonEncode(stats);
    await _storageService.setString(_keyDailyStats, jsonStr);
  }

  Future<int> getTodayStudyMinutes() async {
    final stats = await getDailyStats();
    final today = _getDateString(DateTime.now());
    return stats[today] ?? 0;
  }

  Future<int> getYesterdayStudyMinutes() async {
    final stats = await getDailyStats();
    final yesterday =
        _getDateString(DateTime.now().subtract(const Duration(days: 1)));
    return stats[yesterday] ?? 0;
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
