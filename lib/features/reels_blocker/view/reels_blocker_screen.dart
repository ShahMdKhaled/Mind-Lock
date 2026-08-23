import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/strict_mode_dialog.dart';
import '../viewmodel/reels_blocker_viewmodel.dart';

class ReelsBlockerScreen extends StatelessWidget {
  const ReelsBlockerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReelsBlockerViewModel(),
      child: const _ReelsBlockerScreenContent(),
    );
  }
}

class _ReelsBlockerScreenContent extends StatelessWidget {
  const _ReelsBlockerScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReelsBlockerViewModel>();
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Reels Blocker'),
          elevation: 0,
          backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: [
              _buildMasterToggle(context, vm, settings),
              const SizedBox(height: 32),
              if (settings.reelsBlockerEnabled) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 16),
                  child: Text('SELECT APPS TO PROTECT',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                ...AppConstants.reelsPackages.map((package) {
                  final name = AppConstants.socialMediaApps[package] ?? package;
                  return _buildAppToggle(
                      context, name, package, vm.isPackageBlocked(package), vm);
                }),
              ] else
                _buildDisabledState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterToggle(
      BuildContext context, ReelsBlockerViewModel vm, dynamic settings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: settings.reelsBlockerEnabled
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.cardBorder),
        boxShadow: [
          if (settings.reelsBlockerEnabled)
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Master Shield',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              Text('Enable/Disable all blocking',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
          Switch.adaptive(
            value: settings.reelsBlockerEnabled,
            onChanged: (v) {
              if (!v && settings.reelsBlockerEnabled) {
                if (settings.strictModeEnabled) {
                  if (settings.targetFeatureToDisable == 'reels_blocker' &&
                      !settings.isStrictModeDelayActive &&
                      settings.strictModeCountdownStart != null) {
                    vm.toggleMasterShield(false);
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => ChangeNotifierProvider.value(
                        value: vm,
                        child: Consumer<ReelsBlockerViewModel>(
                          builder: (context, vm, child) => StrictModeDialog(
                            featureKey: 'reels_blocker',
                            featureName: 'Reels Blocker',
                            settings: vm.settings,
                            onStartCountdown: () =>
                                vm.requestDisableFeature('reels_blocker'),
                            onDisableConfirmed: () =>
                                vm.toggleMasterShield(false),
                          ),
                        ),
                      ),
                    );
                  }
                } else {
                  vm.toggleMasterShield(false);
                }
              } else {
                vm.toggleMasterShield(v);
              }
            },
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAppToggle(BuildContext context, String name, String package,
      bool value, ReelsBlockerViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: _getAppIcon(package),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(value ? 'Blocking active' : 'Blocking off',
            style: TextStyle(
                color: value ? AppColors.success : AppColors.textMuted,
                fontSize: 12)),
        trailing: Switch.adaptive(
            value: value,
            onChanged: (v) {
              final settings = vm.settings;
              if (!v && value) {
                if (settings.strictModeEnabled) {
                  if (settings.targetFeatureToDisable ==
                          'reels_blocker_$package' &&
                      !settings.isStrictModeDelayActive &&
                      settings.strictModeCountdownStart != null) {
                    vm.togglePackage(package, false);
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => ChangeNotifierProvider.value(
                        value: vm,
                        child: Consumer<ReelsBlockerViewModel>(
                          builder: (context, vm, child) => StrictModeDialog(
                            featureKey: 'reels_blocker_$package',
                            featureName: 'Reels Blocker ($name)',
                            settings: vm.settings,
                            onStartCountdown: () => vm.requestDisableFeature(
                                'reels_blocker_$package'),
                            onDisableConfirmed: () =>
                                vm.togglePackage(package, false),
                          ),
                        ),
                      ),
                    );
                  }
                } else {
                  vm.togglePackage(package, false);
                }
              } else {
                vm.togglePackage(package, v);
              }
            },
            activeTrackColor: AppColors.primary),
      ),
    );
  }

  Widget _buildDisabledState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(Icons.shield_outlined,
            size: 80, color: AppColors.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 24),
        const Text('Reels Blocker is OFF',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted)),
        const SizedBox(height: 8),
        const Text(
            'Turn on the Master Shield to configure\nindividual app blocking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _getAppIcon(String package) {
    IconData iconData = Icons.apps;
    Color color = AppColors.primary;

    if (package.contains('instagram')) {
      iconData = Icons.camera_alt;
      color = Colors.pink;
    } else if (package.contains('facebook')) {
      iconData = Icons.facebook;
      color = Colors.blue;
    } else if (package.contains('youtube')) {
      iconData = Icons.play_arrow_rounded;
      color = Colors.red;
    } else if (package.contains('snapchat')) {
      iconData = Icons.snapchat;
      color = Colors.yellow;
    } else if (package.contains('tiktok') || package.contains('musically')) {
      iconData = Icons.music_note;
      color = Colors.cyan;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(iconData, color: color, size: 24),
    );
  }
}
