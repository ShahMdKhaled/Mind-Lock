import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/settings_viewmodel.dart';

class AppTimeBreaksScreen extends StatelessWidget {
  const AppTimeBreaksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('App Time Breaks'), elevation: 0, backgroundColor: Colors.transparent),
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
                    color: settings.breakEnabled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    if (settings.breakEnabled)
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)
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
                              Text('Master Shield', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              SizedBox(height: 4),
                              Text('Remind you to take screen breaks', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.breakEnabled,
                          onChanged: (v) => vm.toggleBreakEnabled(v),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (settings.breakEnabled) ...[
                      const Divider(height: 32, color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Break Interval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 24, color: AppColors.primary),
                                onPressed: settings.breakIntervalMinutes > 1
                                    ? () => vm.updateBreakIntervalMinutes(settings.breakIntervalMinutes - 1)
                                    : null,
                              ),
                              Text('${settings.breakIntervalMinutes} min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 24, color: AppColors.primary),
                                onPressed: () => vm.updateBreakIntervalMinutes(settings.breakIntervalMinutes + 1),
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
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'What it does',
                'Once enabled, this tracks your continuous screen usage. After the selected interval is reached, a 10-second break overlay pops up, encouraging you to rest your eyes.',
                Icons.av_timer,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Healthy Habits',
                'Regular short breaks reduce eye strain, prevent headaches, and help you maintain better cognitive focus during work or study sessions.',
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
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
