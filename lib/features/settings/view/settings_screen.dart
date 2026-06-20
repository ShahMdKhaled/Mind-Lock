import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../reels_blocker/view/reels_blocker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          children: [
            _buildSectionHeader('Control & Blocking'),
            _buildActionTile(
              'Reels Blocker',
              settings.reelsBlockerEnabled ? 'Active' : 'Disabled',
              Icons.block,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReelsBlockerScreen())),
            ),
            _buildSettingTile(
              'Uninstall Protection',
              'Prevent app removal for 30 days',
              Icons.security,
              settings.uninstallProtectionEnabled,
              (v) => vm.toggleUninstallProtection(v),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Limits & Breaks'),
            _buildActionTile(
              'Daily Scroll Limit',
              '${settings.scrollLimitMinutes} minutes',
              Icons.hourglass_bottom,
              () => _showScrollLimitDialog(context, vm),
            ),
            _buildActionTile(
              'Break Intervals',
              'Every ${settings.breakIntervalMinutes} mins',
              Icons.coffee,
              () => _showBreakIntervalDialog(context, vm),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Permissions'),
            _buildPermissionTile('Usage Access', 'Required for usage tracking', Icons.insights),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  Widget _buildActionTile(String title, String value, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textMuted),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: TextButton(onPressed: () {}, child: const Text('GRANT')),
      ),
    );
  }

  void _showScrollLimitDialog(BuildContext context, SettingsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Scroll Limit'),
        content: Text('Current: ${vm.settings.scrollLimitMinutes} minutes'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showBreakIntervalDialog(BuildContext context, SettingsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Break Intervals'),
        content: Text('Current: Every ${vm.settings.breakIntervalMinutes} minutes'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save')),
        ],
      ),
    );
  }
}
