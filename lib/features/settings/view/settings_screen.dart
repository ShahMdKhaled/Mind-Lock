import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/strict_mode_dialog.dart';
import '../../permissions/view/permission_screen.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../reels_blocker/view/reels_blocker_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  String _version = AppConstants.appVersion;
  String _buildNumber = AppConstants.appBuildNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsViewModel>().checkPermissions();
      }
    });
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<SettingsViewModel>().checkPermissions();
    }
  }

  bool _checkPermissions(SettingsViewModel vm) {
    if (!vm.isAccessibilityEnabled ||
        !vm.isOverlayGranted ||
        !vm.isUsageGranted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const PermissionScreen()));
      return false;
    }
    return true;
  }

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
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReelsBlockerScreen())),
            ),
            _buildConfigurableSettingTile(
              title: 'Uninstall Protection',
              subtitle: 'Prevent app removal for 30 days',
              icon: Icons.security,
              value: settings.uninstallProtectionEnabled,
              onChanged: (v) {
                if (v && !_checkPermissions(vm)) return;
                if (!v && settings.uninstallProtectionEnabled) {
                  if (settings.isUninstallProtectionActive) {
                    final remaining = settings.uninstallProtectionRemaining;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                      _showCountdownOrStartDialog(context, vm,
                          'uninstall_protection', 'Uninstall Protection');
                    }
                  } else {
                    vm.toggleUninstallProtection(false);
                  }
                } else {
                  vm.toggleUninstallProtection(v);
                }
              },
              children: [],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Strict Protection'),
            _buildConfigurableSettingTile(
              title: 'Strict Mode (Lock Delay)',
              subtitle: 'Prevent turning off limits without a delay timer',
              icon: Icons.lock_clock,
              value: settings.strictModeEnabled,
              onChanged: (v) {
                if (v && !_checkPermissions(vm)) return;
                if (!v && settings.strictModeEnabled) {
                  if (settings.targetFeatureToDisable == 'strict_mode' &&
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delay Duration',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                    Row(
                      children: [
                        Text('${settings.strictModeDelayMinutes} mins',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Limits & Breaks'),
            _buildConfigurableSettingTile(
              title: 'App Time Breaks',
              subtitle: 'Get reminders to take a break',
              icon: Icons.av_timer,
              value: settings.breakEnabled,
              onChanged: (v) {
                if (v && !_checkPermissions(vm)) return;
                vm.toggleBreakEnabled(v);
              },
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Break Interval',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                    Row(
                      children: [
                        Text('${settings.breakIntervalMinutes} min',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Permissions Status'),
            _buildPermissionsCard(context, vm),
            const SizedBox(height: 24),
            _buildSectionHeader('Advanced Settings (Optional)'),
            Container(
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
                      'Enable Device Admin for advanced protection against uninstallation and tampering. Note: To uninstall later, you must disable this first.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildPermissionItem('Device Admin App',
                      vm.isDeviceAdminEnabled, () => vm.requestDeviceAdmin()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: AppColors.primary),
                    title: const Text('About Us',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'MindLock',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.lock,
                            size: 48, color: AppColors.primary),
                        applicationLegalese: '© 2026 MindLock',
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                              'MindLock is your digital wellness guardian. Control social media usage, stop doomscrolling, and protect your focus.'),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: AppColors.primary),
                    title: const Text('Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () async {
                      final Uri url = Uri.parse(
                          'https://sites.google.com/view/mind-lock/home');
                      if (!await launchUrl(url)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not open Privacy Policy')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.code, color: AppColors.primary),
                    title: const Text('Version',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(
                      '$_version ($_buildNumber)',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }

  Widget _buildConfigurableSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: Switch(value: value, onChanged: onChanged),
          ),
          if (value && children.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile(
      String title, String value, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context, SettingsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildPermissionItem(
              'Usage Access', vm.isUsageGranted, () => vm.requestUsage()),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildPermissionItem('Accessibility Service',
              vm.isAccessibilityEnabled, () => vm.requestAccessibility()),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildPermissionItem('Display Over Other Apps', vm.isOverlayGranted,
              () => vm.requestOverlay()),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildPermissionItem('Notifications', vm.isNotificationGranted,
              () => vm.requestNotification()),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildPermissionItem('Do Not Disturb (Study Mode)', vm.isDndGranted,
              () => vm.requestDnd()),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildPermissionItem('Background Execution', vm.isBatteryIgnored,
              () => vm.requestBatteryIgnore()),
          const Divider(height: 24, color: AppColors.cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OEM Advanced Settings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text(
                      'Required for Xiaomi/Realme/Oppo',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => AppSettings.openAppSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Open', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
      String name, bool isGranted, VoidCallback onRequest) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isGranted ? Icons.check_circle : Icons.cancel,
                    color: isGranted ? AppColors.success : AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGranted ? 'Granted' : 'Missing',
                    style: TextStyle(
                      color:
                          isGranted ? AppColors.success : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isGranted)
          ElevatedButton(
            onPressed: onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Grant',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
      ],
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
            onDisableConfirmed: () {
              if (featureKey == 'uninstall_protection') {
                vm.toggleUninstallProtection(false);
              } else if (featureKey == 'strict_mode') {
                vm.toggleStrictMode(false);
              }
            },
            onCancelCountdown: () => vm.clearDisableCountdown(),
          ),
        ),
      ),
    );
  }
}
