import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../viewmodel/study_mode_viewmodel.dart';
import '../viewmodel/study_stats_viewmodel.dart';
import '../../../data/services/permission_service.dart';

class StudyModeScreen extends StatelessWidget {
  const StudyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudyModeScreenContent();
  }
}

class _StudyModeScreenContent extends StatelessWidget {
  const _StudyModeScreenContent();

  @override
  Widget build(BuildContext context) {
    // Uses global StudyModeViewModel from app.dart
    final vm = context.watch<StudyModeViewModel>();
    // Uses local StudyStatsViewModel
    final statsVm = context.watch<StudyStatsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StudyStatsViewModel>().loadStats();
            },
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // TIMER SECTION
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 120.0,
                      lineWidth: 12.0,
                      percent: vm.progress,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(vm.formattedTime,
                              style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: vm.overtimeSeconds > 0
                                      ? Colors.orangeAccent
                                      : Colors.white)),
                          Text(
                              vm.isActive
                                  ? (vm.overtimeSeconds > 0
                                      ? 'Overtime!'
                                      : 'Focusing...')
                                  : 'Ready?',
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: vm.overtimeSeconds > 0
                          ? Colors.orangeAccent
                          : AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      animation: true,
                      animateFromLastPercent: true,
                    ),
                    const SizedBox(height: 40),
                    if (!vm.isActive) ...[
                      const Text('Set Target Time',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.white, size: 30),
                            onPressed: () {
                              if (vm.selectedMinutes > 30) {
                                vm.setDuration(vm.selectedMinutes - 5);
                              }
                            },
                          ),
                          const SizedBox(width: 20),
                          Text('${vm.selectedMinutes} min',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 30),
                            onPressed: () =>
                                vm.setDuration(vm.selectedMinutes + 5),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text('Extend Time',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildExtendButton(context, vm, 5),
                          const SizedBox(width: 12),
                          _buildExtendButton(context, vm, 10),
                          const SizedBox(width: 12),
                          _buildExtendButton(context, vm, 20),
                        ],
                      ),
                    ],
                    const SizedBox(height: 40),
                    Text('Deep Work Session',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'During this session, notifications and vibrations are muted. Only calls will ring.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () async {
                        if (!vm.isActive) {
                          bool granted = await vm.checkPermission();
                          if (!granted) {
                            if (context.mounted) {
                              _showPermissionDialog(context);
                            }
                            return;
                          }
                        }
                        vm.toggleSession();

                        // If we just stopped the session, reload stats to show new data
                        if (vm.isActive == false && context.mounted) {
                          context.read<StudyStatsViewModel>().loadStats();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        decoration: BoxDecoration(
                          gradient:
                              vm.isActive ? null : AppColors.primaryGradient,
                          color: vm.isActive ? AppColors.surfaceVariant : null,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: vm.isActive
                              ? []
                              : [
                                  BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10))
                                ],
                        ),
                        child: Text(
                          vm.isActive ? 'Stop & Save' : 'Start Focus',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // DIVIDER
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: AppColors.cardBorder, thickness: 1),
              ),

              // REPORT SECTION
              Padding(
                padding: const EdgeInsets.all(20),
                child: statsVm.isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Progress',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 20),
                          _buildSummaryCards(statsVm),
                          const SizedBox(height: 30),
                          const Text('Last 30 Days',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 20),
                          _buildChart(statsVm),
                          const SizedBox(height: 30),
                          _buildHistoryList(statsVm),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(StudyStatsViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
              'Today', '${vm.todayMinutes}m', AppColors.surfaceVariant,
              isHighlight: true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
              'Yesterday', '${vm.yesterdayMinutes}m', AppColors.surfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color,
      {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: isHighlight
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: isHighlight ? AppColors.primary : Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart(StudyStatsViewModel vm) {
    if (vm.dailyStats.isEmpty) {
      return const Center(
          child: Text('No data yet',
              style: TextStyle(color: AppColors.textMuted)));
    }

    final sortedEntries = vm.dailyStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Oldest first

    final List<BarChartGroupData> barGroups = [];
    double maxVal = 0;

    for (int i = 0; i < sortedEntries.length; i++) {
      final val = sortedEntries[i].value.toDouble();
      if (val > maxVal) maxVal = val;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: AppColors.primary,
              width: 8,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal == 0 ? 60 : maxVal * 1.2,
                  color: AppColors.cardBorder.withValues(alpha: 0.3)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 16, left: 0, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal == 0 ? 60 : maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dateStr = sortedEntries[group.x.toInt()].key;
                return BarTooltipItem(
                  '$dateStr\n${rod.toY.toInt()} mins',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  // Show label every 5 days to avoid crowding
                  if (index % 5 != 0 || index >= sortedEntries.length) {
                    return const Text('');
                  }

                  final dateStr =
                      sortedEntries[index].key; // Format: 2026-08-20
                  final parts = dateStr.split('-');
                  if (parts.length == 3) {
                    final day = parts[2];
                    final month = parts[1];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('$day/$month',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) return const Text('');
                  return Text('${value.toInt()}m',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.cardBorder.withValues(alpha: 0.3),
                strokeWidth: 1),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildHistoryList(StudyStatsViewModel vm) {
    final sortedEntries = vm.dailyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.key, style: const TextStyle(color: Colors.white)),
          trailing: Text('${entry.value} mins',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Permission Required',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'To mute notifications and vibrations during Study Mode, MindLock needs "Do Not Disturb" (Notification Policy) access. Please enable it in the system settings.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              PermissionService().openNotificationPolicySettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendButton(
      BuildContext context, StudyModeViewModel vm, int minutes) {
    return InkWell(
      onTap: () => vm.extendDuration(minutes),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: Text('+$minutes min',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
