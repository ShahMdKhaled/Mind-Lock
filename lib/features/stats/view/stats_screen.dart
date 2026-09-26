import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/stats_viewmodel.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<StatsViewModel>().refreshUsage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatsViewModel>();
    final summary = vm.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Usage Analysis')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: RefreshIndicator(
          onRefresh: () => vm.refreshUsage(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartCard(vm),
                const SizedBox(height: 24),
                Text('Most Used Apps',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (summary != null)
                  ...vm.topApps.map((usage) => _buildAppUsageItem(usage))
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(StatsViewModel vm) {
    final weeklyData = vm.weeklyData;

    double maxHours = 2.0;
    List<BarChartGroupData> barGroups = [];

    if (weeklyData.isNotEmpty) {
      for (int i = 0; i < weeklyData.length; i++) {
        final hours = weeklyData[i].totalScreen.inMinutes / 60.0;
        if (hours > maxHours) maxHours = hours;

        final color = (hours > 6) ? AppColors.danger : AppColors.primary;
        barGroups.add(_makeGroupData(i, hours, color, maxHours));
      }
    } else {
      // Fallback empty state
      for (int i = 0; i < 7; i++) {
        barGroups.add(_makeGroupData(i, 0, AppColors.primary, 2.0));
      }
    }

    // Add some padding to maxY
    maxHours = maxHours * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Overview (Hours)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxHours,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.surfaceVariant,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hours = rod.toY.toInt();
                      final mins = ((rod.toY - hours) * 60).round();
                      return BarTooltipItem(
                        '${hours}h ${mins}m',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (weeklyData.isEmpty) return const Text('');
                        final date = weeklyData[value.toInt()].date;
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[date.weekday - 1],
                            style: const TextStyle(color: AppColors.textMuted));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY == 0 ? 10 : maxY,
              color: AppColors.surfaceVariant),
        ),
      ],
    );
  }

  Widget _buildAppUsageItem(dynamic usage) {
    final bool isSocial =
        AppConstants.socialMediaApps.containsKey(usage.packageName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSocial
                ? AppColors.danger.withValues(alpha: 0.3)
                : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: usage.icon != null
                ? Image.memory(usage.icon, fit: BoxFit.cover)
                : Center(
                    child: Text(usage.appName[0],
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usage.appName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (isSocial)
                  const Text('Social Media',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(usage.formattedUsage,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '${((usage.usage.inMinutes / 1440) * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
