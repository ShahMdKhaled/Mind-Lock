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
                _buildChartCard(),
                const SizedBox(height: 24),
                Text('Most Used Apps', style: Theme.of(context).textTheme.headlineSmall),
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

  Widget _buildChartCard() {
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
          const Text('Weekly Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[value.toInt() % 7], style: const TextStyle(color: AppColors.textMuted));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 4, AppColors.primary),
                  _makeGroupData(1, 6, AppColors.primary),
                  _makeGroupData(2, 3, AppColors.primary),
                  _makeGroupData(3, 8, AppColors.danger),
                  _makeGroupData(4, 5, AppColors.primary),
                  _makeGroupData(5, 7, AppColors.primary),
                  _makeGroupData(6, 4, AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: AppColors.surfaceVariant),
        ),
      ],
    );
  }

  Widget _buildAppUsageItem(dynamic usage) {
    final bool isSocial = AppConstants.socialMediaApps.containsKey(usage.packageName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSocial ? AppColors.danger.withValues(alpha: 0.3) : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Text(usage.appName[0], style: const TextStyle(color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usage.appName, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (isSocial) const Text('Social Media', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(usage.formattedUsage, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${((usage.usage.inMinutes / 1440) * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
