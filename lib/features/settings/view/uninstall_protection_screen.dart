import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/strict_mode_dialog.dart';
import '../viewmodel/settings_viewmodel.dart';

class UninstallProtectionScreen extends StatelessWidget {
  const UninstallProtectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Uninstall Protection'),
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
                    color: settings.uninstallProtectionEnabled
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    if (settings.uninstallProtectionEnabled)
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                              Text('Prevent app uninstallation',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.uninstallProtectionEnabled,
                          onChanged: (v) {
                            if (!v && settings.uninstallProtectionEnabled) {
                              if (settings.isUninstallProtectionActive) {
                                final remaining =
                                    settings.uninstallProtectionRemaining;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Locked for 30 days! ${remaining.inDays} days remaining.'),
                                  backgroundColor: AppColors.danger,
                                ));
                                return;
                              }
                              if (settings.strictModeEnabled) {
                                if (settings.targetFeatureToDisable ==
                                        'uninstall_protection' &&
                                    !settings.isStrictModeDelayActive &&
                                    settings.strictModeCountdownStart != null) {
                                  vm.toggleUninstallProtection(false);
                                } else {
                                  _showCountdownOrStartDialog(
                                      context,
                                      vm,
                                      'uninstall_protection',
                                      'Uninstall Protection');
                                }
                              } else {
                                vm.toggleUninstallProtection(false);
                              }
                            } else {
                              vm.toggleUninstallProtection(v);
                            }
                          },
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
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
                'This blocks access to the Android App Info page for MindLock, which prevents users from force stopping or uninstalling the app. It also intercepts the package installer uninstallation confirmation screen.',
                Icons.shield,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                '30-Day Lock',
                'Once enabled, Uninstall Protection is strictly locked for 30 days. You will not be able to disable this option before the 30-day period expires.',
                Icons.lock_clock,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'How to disable',
                'After the 30-day lock expires, if Strict Mode is enabled, you will need to start a delay countdown timer before you can switch this option off.',
                Icons.hourglass_bottom,
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
          Icon(icon, color: AppColors.primary, size: 24),
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
            onDisableConfirmed: () => vm.toggleUninstallProtection(false),
            onCancelCountdown: () => vm.clearDisableCountdown(),
          ),
        ),
      ),
    );
  }
}
