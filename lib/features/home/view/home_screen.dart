import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/home_viewmodel.dart';
import '../../../features/reels_blocker/view/reels_blocker_screen.dart';
import '../../../features/permissions/view/permission_screen.dart';
import '../../study_mode/viewmodel/study_mode_viewmodel.dart';
import '../../../data/services/permission_service.dart';
import '../../study_mode/view/study_mode_screen.dart';
import '../../study_mode/viewmodel/study_stats_viewmodel.dart';
import '../../../features/app_limits/view/app_limits_screen.dart';

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
                child: const Text('+12% from yesterday',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
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
              _buildUsageStatItem('Study Mode', '${context.watch<StudyStatsViewModel>().todayMinutes}m', Icons.menu_book),
              _buildUsageStatItem('Breaks', '4', Icons.coffee),
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
    final vm = context.watch<HomeViewModel>();
    final studyVm = context.watch<StudyModeViewModel>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildToggleCard(
                    'Reels Blocker',
                    vm.settings.reelsBlockerEnabled,
                    (v) => vm.toggleReelsBlocker(v),
                    AppColors.danger,
                    Icons.block)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildToggleCard('Study Mode', studyVm.isActive, (v) async {
              if (v && !studyVm.isActive) {
                bool granted = await studyVm.checkPermission();
                if (!granted) {
                  if (context.mounted) {
                    _showPermissionDialog(context);
                  }
                  return;
                }
                studyVm.toggleSession();
              } else if (!v && studyVm.isActive) {
                studyVm.toggleSession();
              }
            }, AppColors.secondary, Icons.school)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                  'Uninstall Protect',
                  vm.settings.uninstallProtectionEnabled,
                  (v) => vm.toggleUninstallProtection(v),
                  AppColors.primary,
                  Icons.security),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToggleCard(
                  'App Use Limit',
                  vm.settings.appLimitsEnabled,
                  (v) => vm.toggleAppLimits(v),
                  AppColors.warning,
                  Icons.hourglass_top),
            ),
          ],
        ),
      ],
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
                style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(String title, bool value, Function(bool) onChanged,
      Color accent, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == 'Reels Blocker') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReelsBlockerScreen()));
        } else if (title == 'Study Mode') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const StudyModeScreen()));
        } else if (title == 'App Use Limit') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AppLimitsScreen()));
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
                Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: accent),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value ? 'Active' : 'Disabled',
                    style: TextStyle(
                        color: value ? accent : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (title == 'Reels Blocker' || title == 'App Use Limit')
                  const Icon(Icons.arrow_forward_ios,
                      size: 10, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optimization Tools',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildFeatureItem('App Time Breaks', 'Get reminders every 20 mins',
            Icons.av_timer, AppColors.primary),
        _buildFeatureItem('Daily Scroll Limit', '30m remaining for today',
            Icons.hourglass_bottom, AppColors.warning),
      ],
    );
  }

  Widget _buildFeatureItem(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
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
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    if (vm.permissionsGranted) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Permissions Required',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('Some features may not work correctly.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PermissionScreen())),
            child: const Text('Resolve',
                style: TextStyle(
                    color: AppColors.warning, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
