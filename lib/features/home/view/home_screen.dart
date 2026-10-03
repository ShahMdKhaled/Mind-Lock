import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/home_viewmodel.dart';
import '../../../features/reels_blocker/view/reels_blocker_screen.dart';
import '../../../features/permissions/view/permission_screen.dart';
import '../../study_mode/viewmodel/study_mode_viewmodel.dart';
import '../../study_mode/view/study_mode_screen.dart';
import '../../study_mode/viewmodel/study_stats_viewmodel.dart';
import '../../../features/app_limits/view/app_limits_screen.dart';
import '../../settings/viewmodel/settings_viewmodel.dart';
import '../../settings/view/uninstall_protection_screen.dart';
import '../../settings/view/strict_mode_screen.dart';
import '../../settings/view/app_time_breaks_screen.dart';

import '../../settings/view/daily_scroll_limit_screen.dart';

import 'package:in_app_update/in_app_update.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      context.read<HomeViewModel>().loadData();
    });
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // Ignore if update check fails (e.g. not installed via Play Store)
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeViewModel>().loadData(delayed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPermissionBanner(context),
                    _buildUsageSummary(context),
                    const SizedBox(height: 24),
                    _buildQuickToggles(context),
                    const SizedBox(height: 24),
                    _buildFeatureGrid(context),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Afternoon,',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Stay Focused',
                    style: Theme.of(context).textTheme.displayLarge),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none,
                    color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSummary(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final summary = vm.summary;
    final socialMins = summary?.totalSocialMedia.inMinutes ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Usage',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(vm.screenTimeChangeText,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(vm.formattedScreenTime,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700)),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 8),
                child: Text('total screen time',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUsageStatItem(
                  'Social Media', '${socialMins}m', Icons.share),
              _buildUsageStatItem(
                  'Study Mode',
                  '${context.watch<StudyStatsViewModel>().todayMinutes}m',
                  Icons.menu_book),
              _buildUsageStatItem(
                  'Breaks', '${vm.dailyBreaksCount}', Icons.coffee),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }

  Widget _buildQuickToggles(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final studyVm = context.watch<StudyModeViewModel>();
    final settings = settingsVm.settings;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildToggleCard(
                    'Reels Blocker',
                    settings.reelsBlockerEnabled,
                    AppColors.danger,
                    Icons.block)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildToggleCard('Study Mode', studyVm.isActive,
                    AppColors.secondary, Icons.school)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                  'Uninstall Protect',
                  settings.uninstallProtectionEnabled,
                  AppColors.primary,
                  Icons.security),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToggleCard(
                  'App Use Limit',
                  settings.appLimitsEnabled,
                  AppColors.warning,
                  Icons.hourglass_top),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToggleCard('Strict Mode', settings.strictModeEnabled,
                  AppColors.warning, Icons.lock_clock),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToggleCard('App Time Breaks', settings.breakEnabled,
                  AppColors.primary, Icons.coffee),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleCard(
      String title, bool value, Color accent, IconData icon) {
    return GestureDetector(
      onTap: () async {
        if (title == 'Reels Blocker') {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReelsBlockerScreen()));
        } else if (title == 'Study Mode') {
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => const StudyModeScreen()));
        } else if (title == 'App Use Limit') {
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AppLimitsScreen()));
        } else if (title == 'Uninstall Protect') {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UninstallProtectionScreen()));
        } else if (title == 'Strict Mode') {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const StrictModeScreen()));
        } else if (title == 'App Time Breaks') {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AppTimeBreaksScreen()));
        }

        if (mounted) {
          context.read<SettingsViewModel>().loadSettings();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
              color:
                  value ? accent.withValues(alpha: 0.5) : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: value ? accent : AppColors.textMuted),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(value ? 'Active' : 'Disabled',
                style: TextStyle(
                    color: value ? accent : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final settings = context.watch<SettingsViewModel>().settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optimization Tools',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildFeatureItem(
          'Daily Scroll Limit',
          settings.scrollLimitEnabled
              ? '${settings.scrollLimitMinutes}m limit set for today'
              : 'Not enabled',
          Icons.hourglass_bottom,
          AppColors.warning,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DailyScrollLimitScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    if (vm.permissionsGranted) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded,
                color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Permissions Required',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('App features are currently limited',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PermissionScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('FIX NOW',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
