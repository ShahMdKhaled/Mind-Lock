import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../viewmodel/study_stats_viewmodel.dart';

class StudyReportScreen extends StatelessWidget {
  const StudyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudyStatsViewModel()..loadStats(),
      child: const _StudyReportScreenContent(),
    );
  }
}

class _StudyReportScreenContent extends StatelessWidget {
  const _StudyReportScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudyStatsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Study Report')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: vm.isBusy
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(vm),
                    const SizedBox(height: 30),
                    const Text('Last 30 Days',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 20),
                    _buildChart(vm),
                    const SizedBox(height: 30),
                    _buildHistoryList(vm),
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
          child: _buildCard('Today', '${vm.todayMinutes}m', AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
              'Yesterday', '${vm.yesterdayMinutes}m', AppColors.surfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
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
      ..sort((a, b) => a.key.compareTo(b.key));

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
              color: AppColors.secondary,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal == 0 ? 60 : maxVal * 1.2,
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
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
                  color: AppColors.secondary, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
