import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/settings_viewmodel.dart';

class DailyScrollLimitScreen extends StatelessWidget {
  const DailyScrollLimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Daily Scroll Limit'),
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
                    color: settings.scrollLimitEnabled
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    if (settings.scrollLimitEnabled)
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
                              Text('Set maximum daily browsing time',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.scrollLimitEnabled,
                          onChanged: (v) => vm.toggleScrollLimit(v),
                          activeTrackColor: AppColors.warning,
                        ),
                      ],
                    ),
                    if (settings.scrollLimitEnabled) ...[
                      const Divider(height: 32, color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Scroll Limit',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    size: 24, color: AppColors.warning),
                                onPressed: settings.scrollLimitMinutes > 5
                                    ? () => vm.updateScrollLimitMinutes(
                                        settings.scrollLimitMinutes - 5)
                                    : null,
                              ),
                              Text('${settings.scrollLimitMinutes} min',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    size: 24, color: AppColors.warning),
                                onPressed: () => vm.updateScrollLimitMinutes(
                                    settings.scrollLimitMinutes + 5),
                              ),
                            ],
                          ),
                        ],
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
                'Once enabled, this tracks your continuous scrolling across social media. When the limit is reached, it blocks further scrolling to help you regain focus.',
                Icons.hourglass_bottom,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Healthy Habits',
                'Setting a daily limit for scrolling helps prevent doomscrolling and improves your daily productivity.',
                Icons.spa,
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
}
