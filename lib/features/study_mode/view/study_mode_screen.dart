import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme.dart';
import '../viewmodel/study_mode_viewmodel.dart';
import '../viewmodel/study_stats_viewmodel.dart';
import '../../../data/services/permission_service.dart';
import 'study_report_screen.dart';

/// Modern, intuitive UI Screen for Study Mode.
/// Compact and elegant timer box, presets (30m, 1h, 2h ★, 3h, 5h),
/// customizable default duration, session extensions, and continuous overtime.
class StudyModeScreen extends StatelessWidget {
  const StudyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudyModeScreenContent();
  }
}

class _StudyModeScreenContent extends StatelessWidget {
  const _StudyModeScreenContent();

  static const List<Map<String, dynamic>> _quickPresets = [
    {'label': '30 min', 'minutes': 30, 'isStarred': false},
    {'label': '1h', 'minutes': 60, 'isStarred': false},
    {'label': '2h', 'minutes': 120, 'isStarred': true},
    {'label': '3h', 'minutes': 180, 'isStarred': false},
    {'label': '5h', 'minutes': 300, 'isStarred': false},
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudyModeViewModel>();
    final statsVm = context.watch<StudyStatsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mode'),
        actions: [
          IconButton(
            tooltip: 'Study Analytics & Report',
            icon: const Icon(Icons.insights_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudyReportScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh Stats',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              context.read<StudyStatsViewModel>().loadStats();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // 1. COMPACT CIRCULAR TIMER DISPLAY
              _buildTimerSection(context, vm),
              const SizedBox(height: 20),

              // 2. CONTROLS SECTION (Stepper & Presets when idle, Extend options when active)
              if (!vm.isActive) ...[
                _buildDurationStepperCard(context, vm),
                const SizedBox(height: 14),
                _buildPresetChips(vm),
              ] else ...[
                if (vm.isOvertime) ...[
                  _buildOvertimeBanner(vm),
                  const SizedBox(height: 14),
                ],
                _buildExtendSection(context, vm),
              ],
              const SizedBox(height: 24),

              // 3. PRIMARY ACTION BUTTON (Start / Stop & Save)
              _buildActionButton(context, vm),
              const SizedBox(height: 28),

              // 4. FOCUS FEATURES CARD
              _buildFeatureOverviewCard(),
              const SizedBox(height: 20),

              // 5. QUICK TODAY / YESTERDAY STATS & LINK TO REPORT
              _buildQuickStatsSection(context, statsVm),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact, sleek Circular Timer matching full width of other cards with reduced height
  Widget _buildTimerSection(BuildContext context, StudyModeViewModel vm) {
    final Color progressColor = vm.isOvertime
        ? AppColors.warning
        : (vm.isActive ? AppColors.primary : AppColors.primaryLight);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: vm.isOvertime
              ? AppColors.warning.withValues(alpha: 0.4)
              : (vm.isActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.cardBorder),
          width: vm.isOvertime ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (vm.isActive)
            BoxShadow(
              color: (vm.isOvertime ? AppColors.warning : AppColors.primary)
                  .withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Badge above timer
          _buildStatusBadge(vm),
          const SizedBox(height: 8),

          // Compact circular countdown / countup indicator
          CircularPercentIndicator(
            radius: 76.0,
            lineWidth: 8.0,
            percent: vm.isOvertime ? 1.0 : vm.progress.clamp(0.0, 1.0),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: progressColor,
            backgroundColor: const Color(0xFF1B1A35),
            animation: false,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  vm.formattedTime,
                  style: TextStyle(
                    fontSize: vm.formattedTime.length > 5 ? 24 : 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: vm.isOvertime ? AppColors.warning : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSubTimerText(vm),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: vm.isOvertime
                        ? AppColors.warning.withValues(alpha: 0.9)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge above the circular timer
  Widget _buildStatusBadge(StudyModeViewModel vm) {
    if (vm.isOvertime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded,
                color: AppColors.warning, size: 14),
            SizedBox(width: 5),
            Text(
              'OVERTIME COUNTING',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (vm.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'DEEP WORK ACTIVE',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 14),
            SizedBox(width: 5),
            Text(
              'READY TO FOCUS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getSubTimerText(StudyModeViewModel vm) {
    if (vm.isOvertime) {
      return 'Total: ${vm.totalFormattedTime}';
    } else if (vm.isActive) {
      if (vm.selectedMinutes >= 60) {
        int h = vm.selectedMinutes ~/ 60;
        int m = vm.selectedMinutes % 60;
        return 'Target: ${h}h${m > 0 ? ' ${m}m' : ''}';
      }
      return 'Target: ${vm.selectedMinutes}m';
    } else {
      if (vm.selectedMinutes >= 60) {
        int h = vm.selectedMinutes ~/ 60;
        int m = vm.selectedMinutes % 60;
        return '${h}h${m > 0 ? ' ${m}m' : ''} Goal';
      }
      return '${vm.selectedMinutes} Min Goal';
    }
  }

  /// Stepper card allowing users to increase or decrease duration
  Widget _buildDurationStepperCard(
      BuildContext context, StudyModeViewModel vm) {
    final String durationText = _formatStepperDuration(vm.selectedMinutes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target Duration',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Auto-saved as default',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: vm.selectedMinutes > 15
                    ? () => vm.setDuration(vm.selectedMinutes - 15)
                    : (vm.selectedMinutes > 5
                        ? () => vm.setDuration(5)
                        : null),
              ),
              const SizedBox(width: 18),
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 18),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: vm.selectedMinutes < 300
                    ? () => vm.setDuration(vm.selectedMinutes + 15)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatStepperDuration(int minutes) {
    if (minutes >= 60) {
      int h = minutes ~/ 60;
      int m = minutes % 60;
      if (m == 0) {
        return '$h Hour${h > 1 ? 's' : ''}';
      }
      return '${h}h ${m}m';
    }
    return '$minutes Minutes';
  }

  /// Preset chips: 30 min, 1h, 2h ★, 3h, 5h
  Widget _buildPresetChips(StudyModeViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _quickPresets.map((preset) {
          final int mins = preset['minutes'] as int;
          final String label = preset['label'] as String;
          final bool isStarred = preset['isStarred'] as bool;
          final bool isSelected = vm.selectedMinutes == mins;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isStarred) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: isSelected ? Colors.white : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isStarred
                          ? AppColors.warning.withValues(alpha: 0.6)
                          : AppColors.cardBorder),
                  width: isStarred ? 1.4 : 1.0,
                ),
              ),
              onSelected: (_) => vm.setDuration(mins),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Informative banner shown when target time is completed and overtime is running
  Widget _buildOvertimeBanner(StudyModeViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              color: AppColors.warning, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal Reached! Overtime Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Timer continues counting your focus. Extend target below or tap Stop when done.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Session extension chips (+5m, +10m, +15m, +30m) when active
  Widget _buildExtendSection(BuildContext context, StudyModeViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.more_time_rounded,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Extend Focus Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep your momentum going without restarting your timer.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExtendChip(context, vm, 5),
              _buildExtendChip(context, vm, 10),
              _buildExtendChip(context, vm, 15),
              _buildExtendChip(context, vm, 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtendChip(
      BuildContext context, StudyModeViewModel vm, int minutes) {
    return InkWell(
      onTap: () {
        vm.extendDuration(minutes);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary),
            ),
            content: Text(
              'Extended focus by +$minutes minutes!',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          '+$minutes m',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Start Focus / Stop & Save session CTA button
  Widget _buildActionButton(BuildContext context, StudyModeViewModel vm) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: vm.isActive ? null : AppColors.primaryGradient,
          color: vm.isActive ? const Color(0xFF2C1E2E) : null,
          borderRadius: BorderRadius.circular(18),
          border: vm.isActive
              ? Border.all(color: AppColors.danger.withValues(alpha: 0.6))
              : null,
          boxShadow: [
            if (!vm.isActive)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () async {
            if (!vm.isActive) {
              final bool granted = await vm.checkPermission();
              if (!granted) {
                if (context.mounted) {
                  _showPermissionDialog(context);
                }
                return;
              }
              await vm.toggleSession();
            } else {
              final int? minutesSpent = await vm.toggleSession();
              if (context.mounted) {
                context.read<StudyStatsViewModel>().loadStats();
                if (minutesSpent != null && minutesSpent > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceVariant,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.success),
                      ),
                      content: Row(
                        children: [
                          const Icon(Icons.celebration_rounded,
                              color: AppColors.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Fantastic work! You completed $minutesSpent minutes of focus time.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vm.isActive
                    ? Icons.stop_circle_rounded
                    : Icons.play_arrow_rounded,
                color: vm.isActive ? AppColors.danger : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                vm.isActive ? 'Stop & Save Session' : 'Start Focus Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: vm.isActive ? AppColors.danger : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Informational card outlining Study Mode behavior
  Widget _buildFeatureOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Mode Features',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            Icons.do_not_disturb_on_rounded,
            AppColors.primary,
            'Do Not Disturb Active',
            'Notifications and vibrations are muted to keep you in flow.',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            Icons.block_rounded,
            AppColors.danger,
            'Distraction Defense',
            'Reels, Shorts, and blacklisted apps stay blocked during study.',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            Icons.update_rounded,
            AppColors.success,
            'Continuous Overtime',
            'Timer never stops abruptly—counts your extra focus automatically.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      IconData icon, Color color, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Summary cards for Today and Yesterday with direct navigation to the full 30-day StudyReportScreen
  Widget _buildQuickStatsSection(
      BuildContext context, StudyStatsViewModel statsVm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Focus Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudyReportScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Full Report',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.primary, size: 11),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Today',
                  '${statsVm.todayMinutes}m',
                  AppColors.primary,
                  isHighlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  'Yesterday',
                  '${statsVm.yesterdayMinutes}m',
                  AppColors.surfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color accentColor,
      {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.primary : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permission Required',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'To silence notifications and vibrations during Study Mode, MindLock needs "Do Not Disturb" (Notification Policy) permission. Please enable it in system settings.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              PermissionService().openNotificationPolicySettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
