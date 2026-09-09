import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/strict_mode_dialog.dart';
import '../viewmodel/settings_viewmodel.dart';

class StrictModeScreen extends StatelessWidget {
  const StrictModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Strict Mode'),
          elevation: 0,
          backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: settings.strictModeEnabled
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    if (settings.strictModeEnabled)
                      BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Master Shield',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              SizedBox(height: 4),
                              Text('Add a delay timer before disabling limits',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.strictModeEnabled,
                          onChanged: (v) {
                            if (!v && settings.strictModeEnabled) {
                              if (settings.targetFeatureToDisable ==
                                      'strict_mode' &&
                                  !settings.isStrictModeDelayActive &&
                                  settings.strictModeCountdownStart != null) {
                                vm.toggleStrictMode(false);
                              } else {
                                _showCountdownOrStartDialog(
                                    context, vm, 'strict_mode', 'Strict Mode');
                              }
                            } else {
                              vm.toggleStrictMode(v);
                            }
                          },
                          activeTrackColor: AppColors.warning,
                        ),
                      ],
                    ),
                    if (settings.strictModeEnabled) ...[
                      const Divider(height: 32, color: AppColors.cardBorder),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delay Duration',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${settings.strictModeDelayMinutes} mins',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: settings.strictModeDelayMinutes
                            .toDouble()
                            .clamp(1.0, 300.0),
                        min: 1,
                        max: 300,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.cardBorder,
                        onChanged: vm.isStrictModeDelayLocked()
                            ? null
                            : (val) => vm.updateStrictModeDelay(val.toInt()),
                      ),
                      if (vm.isStrictModeDelayLocked())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.lock,
                                  size: 16, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Locked until ${settings.strictModeDelayLockedUntil!.day}/${settings.strictModeDelayLockedUntil!.month}/${settings.strictModeDelayLockedUntil!.year}',
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: vm.isStrictModeDelayLocked()
                              ? null
                              : () async {
                                  await vm.saveStrictModeDelay();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Duration saved and locked for 15 days!')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Configuration',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'INFO & DETAILS',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'What it does',
                'Strict Mode prevents you from turning off Reels Blocker, App Limits, Uninstall Protection, or Strict Mode itself on impulse. You must wait out a delay timer before changes take effect.',
                Icons.lock_clock,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Impulse Control',
                'By setting a delay duration, you give yourself a cooling-off period. This helps break the cycle of immediate gratification when you feel tempted to remove your limits.',
                Icons.psychology,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warning, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCountdownOrStartDialog(BuildContext context, SettingsViewModel vm,
      String featureKey, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<SettingsViewModel>(
          builder: (context, vm, child) => StrictModeDialog(
            featureKey: featureKey,
            featureName: featureName,
            settings: vm.settings,
            onStartCountdown: () => vm.startDisableCountdown(featureKey),
            onDisableConfirmed: () => vm.toggleStrictMode(false),
            onCancelCountdown: () => vm.clearDisableCountdown(),
          ),
        ),
      ),
    );
  }
}
