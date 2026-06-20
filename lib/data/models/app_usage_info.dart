class MindLockUsageInfo {
  final String packageName;
  final String appName;
  final Duration usage;
  final DateTime date;
  final String? iconPath;

  const MindLockUsageInfo({
    required this.packageName,
    required this.appName,
    required this.usage,
    required this.date,
    this.iconPath,
  });

  String get formattedUsage {
    if (usage.inMinutes < 1) return '< 1 min';
    if (usage.inHours < 1) return '${usage.inMinutes} min';
    final hours = usage.inHours;
    final mins = usage.inMinutes.remainder(60);
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'usage_seconds': usage.inSeconds,
      'date': date.toIso8601String(),
    };
  }

  factory MindLockUsageInfo.fromMap(Map<String, dynamic> map) {
    return MindLockUsageInfo(
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      usage: Duration(seconds: map['usage_seconds'] as int),
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class DailyUsageSummary {
  final DateTime date;
  final Duration totalSocialMedia;
  final Duration totalScreen;
  final List<MindLockUsageInfo> appUsages;
  final int breaksTaken;

  const DailyUsageSummary({
    required this.date,
    required this.totalSocialMedia,
    required this.totalScreen,
    required this.appUsages,
    this.breaksTaken = 0,
  });

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}