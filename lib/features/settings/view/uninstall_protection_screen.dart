import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/strict_mode_dialog.dart';
import '../viewmodel/settings_viewmodel.dart';

/// UI Screen for enabling a custom duration lock that prevents the user
/// from uninstalling the MindLock app or disabling protection until the duration expires.
class UninstallProtectionScreen extends StatefulWidget {
  const UninstallProtectionScreen({super.key});

  @override
  State<UninstallProtectionScreen> createState() =>
      _UninstallProtectionScreenState();
}

class _UninstallProtectionScreenState extends State<UninstallProtectionScreen> {
  int _selectedDays = 30;
  bool _initialized = false;

  final List<int> _presetDays = const [7, 15, 30, 60, 90, 180];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = context.read<SettingsViewModel>().settings;
      _selectedDays = settings.uninstallProtectionDurationDays > 0
          ? settings.uninstallProtectionDurationDays
          : 30;
      _initialized = true;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final settings = vm.settings;
    final isEnabled = settings.uninstallProtectionEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uninstall Protection'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: [
              // 1. Master Switch Card
              _buildMasterCard(context, vm, settings),

              const SizedBox(height: 20),

              // 2. Either Active Status Card OR Duration Selector Card
              if (isEnabled)
                _buildActiveStatusCard(context, settings)
              else
                _buildDurationSelectorCard(context, vm),

              const SizedBox(height: 24),

              // 3. Info & Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'INFO & DETAILS',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'What it does',
                'Blocks access to MindLock\'s App Info in Android Settings to prevent force stopping or clearing data. In Google Play Store, it allows you to view and update MindLock, but strictly intercepts any attempt to uninstall it.',
                Icons.shield,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Custom Lock Period',
                'You choose exactly how many days the protection stays locked. Once turned on, this option cannot be switched off until the selected duration ends.',
                Icons.lock_clock,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Disabling After Expiry',
                'Once the lock duration expires, you can toggle protection off. If Strict Mode is enabled, you will still need to complete the delay timer before it turns off.',
                Icons.hourglass_bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterCard(
      BuildContext context, SettingsViewModel vm, dynamic settings) {
    final isEnabled = settings.uninstallProtectionEnabled;
    final isActive = settings.isUninstallProtectionActive;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          if (isEnabled)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 3,
            )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Master Shield',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.warning,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isActive ? 'LOCKED' : 'EXPIRED',
                          style: TextStyle(
                            color: isActive
                                ? AppColors.primaryLight
                                : AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Protected against uninstallation'
                      : 'Set days & activate protection',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (v) {
              if (v) {
                _promptActivationDialog(context, vm);
              } else {
                _handleTurnOff(context, vm, settings);
              }
            },
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatusCard(BuildContext context, dynamic settings) {
    final remaining = settings.uninstallProtectionRemaining as Duration;
    final totalDays = settings.uninstallProtectionDurationDays as int;
    final startDate = settings.uninstallProtectionStartDate as DateTime?;
    final endDate = settings.uninstallProtectionEndDate as DateTime?;
    final isActive = settings.isUninstallProtectionActive as bool;

    double progress = 1.0;
    if (startDate != null && endDate != null && totalDays > 0) {
      final totalMs = endDate.difference(startDate).inMilliseconds;
      final elapsedMs =
          DateTime.now().difference(startDate).inMilliseconds.clamp(0, totalMs);
      progress = totalMs > 0 ? (elapsedMs / totalMs).clamp(0.0, 1.0) : 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Lock Period Active' : 'Lock Period Expired',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Configured for $totalDays days',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Big countdown display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      isActive ? '${remaining.inDays}' : '0',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const Text(
                      'DAYS REMAINING',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.cardBorder,
                ),
                Column(
                  children: [
                    Text(
                      isActive ? '${remaining.inHours % 24}h ${remaining.inMinutes % 60}m' : '0h 0m',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'HOURS & MINS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isActive ? AppColors.primary : AppColors.success,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),

          // Dates info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startDate != null ? 'Started: ${_formatDate(startDate)}' : '',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                endDate != null ? 'Unlocks: ${_formatDate(endDate)}' : '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (isActive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Locked until ${endDate != null ? _formatDate(endDate) : 'expiry'}. Cannot be disabled before then.',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationSelectorCard(
      BuildContext context, SettingsViewModel vm) {
    final projectedUnlock =
        DateTime.now().add(Duration(days: _selectedDays));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'SET LOCK DURATION',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select how many days protection will remain locked and unchangeable once turned on.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // Stepper Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.primaryLight, size: 28),
                  onPressed: _selectedDays > 1
                      ? () {
                          setState(() {
                            _selectedDays--;
                          });
                        }
                      : null,
                ),
                Column(
                  children: [
                    Text(
                      '$_selectedDays',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _selectedDays == 1 ? 'DAY' : 'DAYS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primaryLight, size: 28),
                  onPressed: _selectedDays < 365
                      ? () {
                          setState(() {
                            _selectedDays++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetDays.map((days) {
              final isSelected = _selectedDays == days;
              final isRecommended = days == 30;
              return ChoiceChip(
                label: Text(
                  isRecommended ? '$days Days ★' : '$days Days',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isRecommended
                            ? AppColors.primaryLight
                            : AppColors.textSecondary),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isRecommended
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.cardBorder),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDays = days;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Projected Date Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Will remain locked until ${_formatDate(projectedUnlock)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Activate Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock, size: 20),
              label: Text(
                'Lock for $_selectedDays ${_selectedDays == 1 ? 'Day' : 'Days'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              onPressed: () => _promptActivationDialog(context, vm),
            ),
          ),
        ],
      ),
    );
  }

  void _promptActivationDialog(BuildContext context, SettingsViewModel vm) {
    final projectedUnlock =
        DateTime.now().add(Duration(days: _selectedDays));
    final formattedDate = _formatDate(projectedUnlock);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lock for $_selectedDays Days?',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Once enabled, Uninstall Protection will be strictly locked on your device for $_selectedDays days (until $formattedDate).',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildBulletPoint('You CANNOT turn off this protection early.'),
            _buildBulletPoint('You CANNOT uninstall MindLock from Settings.'),
            _buildBulletPoint('Play Store viewing & updates remain active.'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Are you sure you want to commit to this lock period?',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.toggleUninstallProtection(true, _selectedDays);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Uninstall Protection activated for $_selectedDays days!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Confirm & Lock ($_selectedDays d)'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTurnOff(
      BuildContext context, SettingsViewModel vm, dynamic settings) {
    if (settings.isUninstallProtectionActive) {
      final remaining = settings.uninstallProtectionRemaining as Duration;
      final endDate = settings.uninstallProtectionEndDate as DateTime?;
      final formattedEnd =
          endDate != null ? _formatDate(endDate) : 'expiry';
      final days = settings.uninstallProtectionDurationDays;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Row(
            children: const [
              Icon(Icons.lock_clock, color: AppColors.danger),
              SizedBox(width: 10),
              Text(
                'Protection Locked',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Uninstall Protection is locked for $days days. There are ${remaining.inDays} days and ${remaining.inHours % 24} hours remaining (until $formattedEnd).\n\nIt cannot be turned off before this period expires.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(color: AppColors.primaryLight)),
            ),
          ],
        ),
      );
      return;
    }

    if (settings.strictModeEnabled) {
      if (settings.targetFeatureToDisable == 'uninstall_protection' &&
          !settings.isStrictModeDelayActive &&
          settings.strictModeCountdownStart != null) {
        vm.toggleUninstallProtection(false);
      } else {
        _showCountdownOrStartDialog(
          context,
          vm,
          'uninstall_protection',
          'Uninstall Protection',
        );
      }
    } else {
      vm.toggleUninstallProtection(false);
    }
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
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
