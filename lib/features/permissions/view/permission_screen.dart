import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../viewmodel/permission_viewmodel.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  late final PermissionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PermissionViewModel();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _viewModel.checkAll(delayed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _PermissionScreenContent(),
    );
  }
}

class _PermissionScreenContent extends StatelessWidget {
  const _PermissionScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PermissionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Required Permissions'), elevation: 0, backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                child: Text(
                  'MindLock needs these permissions to work. Your data stays private.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                  children: [
                    _buildPermissionTile('Usage Access', 'Tracks social media time.', Icons.insights, vm.isUsageGranted, () => _showPermissionGuide(context, 'Usage Access', 'Look for "MindLock" in the list and allow usage tracking.', vm.requestUsage)),
                    _buildPermissionTile('Accessibility Service', 'Blocks reels & shorts.', Icons.accessibility_new, vm.isAccessibilityEnabled, () => _showPermissionGuide(context, 'Accessibility Service', 'Look for "MindLock" in the downloaded apps or installed services list and turn it ON.', vm.requestAccessibility)),
                    _buildPermissionTile('Display Over Other Apps', 'Shows blocking screen.', Icons.layers, vm.isOverlayGranted, () => _showPermissionGuide(context, 'Display Over Other Apps', 'Look for "MindLock" in the list and allow display over other apps.', vm.requestOverlay)),
                    _buildPermissionTile('Notifications', 'Sends reminders.', Icons.notifications, vm.isNotificationGranted, () => _showPermissionGuide(context, 'Notifications', 'Allow notifications for MindLock.', vm.requestNotification)),
                    _buildPermissionTile('Do Not Disturb', 'Used by Study Mode.', Icons.do_not_disturb_on, vm.isDndGranted, () => _showPermissionGuide(context, 'Do Not Disturb Access', 'Allow MindLock to manage Do Not Disturb so Study Mode can block interruptions.', vm.requestDnd)),
                  ],
                ),
              ),
              if (vm.allGranted)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Continue to App', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile(String title, String subtitle, IconData icon, bool isGranted, VoidCallback onRequest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGranted ? AppColors.success.withValues(alpha: 0.3) : AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isGranted ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isGranted ? AppColors.success : AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: AppColors.success, size: 28)
            : ElevatedButton(
                onPressed: onRequest,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Grant', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
      ),
    );
  }

  void _showPermissionGuide(BuildContext context, String title, String instruction, VoidCallback onProceed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instruction, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.touch_app, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text("Scroll down to find MindLock and toggle it ON", 
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onProceed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
