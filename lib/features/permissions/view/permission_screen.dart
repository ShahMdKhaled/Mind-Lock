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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PermissionViewModel>().checkAll(delayed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionViewModel(),
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
                  'To work correctly, MindLock needs the following permissions. Your data stays private on your device.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                  children: [
                    _buildPermissionTile('Usage Access', 'Required to track time spent on social media apps.', Icons.insights, vm.isUsageGranted, () => vm.requestUsage()),
                    _buildPermissionTile('Accessibility Service', 'Required to detect and block reels/shorts in real-time.', Icons.accessibility_new, vm.isAccessibilityEnabled, () => vm.requestAccessibility()),
                    _buildPermissionTile('Display Over Other Apps', 'Required to show blocking screen over other apps.', Icons.layers, vm.isOverlayGranted, () => vm.requestOverlay()),
                    _buildPermissionTile('Notifications', 'Required to send break reminders and daily summaries.', Icons.notifications, vm.isNotificationGranted, () => vm.requestNotification()),
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
}
