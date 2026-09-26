import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/strict_mode_dialog.dart';
import '../viewmodel/app_limits_viewmodel.dart';

class AppLimitsScreen extends StatelessWidget {
  const AppLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppLimitsViewModel(),
      child: const _AppLimitsScreenContent(),
    );
  }
}

class _AppLimitsScreenContent extends StatefulWidget {
  const _AppLimitsScreenContent();

  @override
  State<_AppLimitsScreenContent> createState() =>
      _AppLimitsScreenContentState();
}

class _AppLimitsScreenContentState extends State<_AppLimitsScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatLimit(int minutes) {
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hrs hr${hrs > 1 ? 's' : ''}';
    }
    return '${hrs}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppLimitsViewModel>();
    final enabled = vm.appLimitsEnabled;
    final limitedApps = vm.appLimits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Use Limits'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  children: [
                    _buildMasterToggle(vm, enabled),
                    const SizedBox(height: 32),
                    if (enabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'ACTIVE LIMITS',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Text(
                            '${limitedApps.length} App${limitedApps.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (limitedApps.isEmpty)
                        _buildEmptyLimitsState(context)
                      else
                        ...limitedApps.entries.map((entry) {
                          final packageName = entry.key;
                          final minutes = entry.value;
                          return _buildActiveLimitTile(
                              context, vm, packageName, minutes);
                        }),
                    ] else
                      _buildDisabledState(),
                  ],
                ),
              ),
              if (enabled)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddAppsSheet(context, vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add App to Limit',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterToggle(AppLimitsViewModel vm, bool enabled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enabled
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Limit Shield',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'Lock apps when daily limit finishes',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: (v) {
              if (!v && enabled) {
                if (vm.settings.strictModeEnabled) {
                  if (vm.settings.targetFeatureToDisable == 'app_limits' &&
                      !vm.settings.isStrictModeDelayActive &&
                      vm.settings.strictModeCountdownStart != null) {
                    vm.toggleMasterShield(false);
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => ChangeNotifierProvider.value(
                        value: vm,
                        child: Consumer<AppLimitsViewModel>(
                          builder: (context, vm, child) => StrictModeDialog(
                            featureKey: 'app_limits',
                            featureName: 'App Limits',
                            settings: vm.settings,
                            onStartCountdown: () =>
                                vm.requestDisableFeature('app_limits'),
                            onDisableConfirmed: () =>
                                vm.toggleMasterShield(false),
                            onCancelCountdown: () => vm.clearDisableCountdown(),
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
            activeTrackColor: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLimitsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty,
              size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text(
            'No limits set yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add apps and define their daily usage limits.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLimitTile(
    BuildContext context,
    AppLimitsViewModel vm,
    String packageName,
    int minutes,
  ) {
    AppInfo? matchingApp = vm.getCachedAppInfo(packageName);

    final appName = matchingApp?.name ?? packageName.split('.').last;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: matchingApp?.icon != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  matchingApp!.icon!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.apps, color: AppColors.warning, size: 24),
              ),
        title: Text(
          appName,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.access_time, size: 12, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              _formatLimit(minutes),
              style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary, size: 20),
              onPressed: () =>
                  _handleEditLimit(context, vm, packageName, appName, minutes),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 20),
              onPressed: () =>
                  _handleDeleteLimit(context, vm, packageName, appName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(Icons.hourglass_disabled_outlined,
            size: 80, color: AppColors.textMuted.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
        const Text(
          'App Limits are Disabled',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        const Text(
          'Turn on the Limit Shield to customize and enforce daily time limits for your applications.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _handleEditLimit(BuildContext context, AppLimitsViewModel vm,
      String packageName, String appName, int minutes) {
    if (vm.settings.strictModeEnabled) {
      final featureKey = 'edit_limit_$packageName';
      if (vm.settings.targetFeatureToDisable == featureKey &&
          !vm.settings.isStrictModeDelayActive &&
          vm.settings.strictModeCountdownStart != null) {
        _showLimitDialog(context, vm, packageName, appName,
            currentLimit: minutes);
        vm.clearDisableCountdown();
      } else {
        showDialog(
          context: context,
          builder: (ctx) => ChangeNotifierProvider.value(
            value: vm,
            child: Consumer<AppLimitsViewModel>(
              builder: (context, vm, child) => StrictModeDialog(
                featureKey: featureKey,
                featureName: 'Edit Limit for $appName',
                settings: vm.settings,
                onStartCountdown: () => vm.requestDisableFeature(featureKey),
                onDisableConfirmed: () {
                  _showLimitDialog(context, vm, packageName, appName,
                      currentLimit: minutes);
                  vm.clearDisableCountdown();
                },
                onCancelCountdown: () => vm.clearDisableCountdown(),
              ),
            ),
          ),
        );
      }
    } else {
      _showLimitDialog(context, vm, packageName, appName,
          currentLimit: minutes);
    }
  }

  void _handleDeleteLimit(BuildContext context, AppLimitsViewModel vm,
      String packageName, String appName) {
    if (vm.settings.strictModeEnabled) {
      final featureKey = 'delete_limit_$packageName';
      if (vm.settings.targetFeatureToDisable == featureKey &&
          !vm.settings.isStrictModeDelayActive &&
          vm.settings.strictModeCountdownStart != null) {
        vm.removeAppLimit(packageName);
        vm.clearDisableCountdown();
      } else {
        showDialog(
          context: context,
          builder: (ctx) => ChangeNotifierProvider.value(
            value: vm,
            child: Consumer<AppLimitsViewModel>(
              builder: (context, vm, child) => StrictModeDialog(
                featureKey: featureKey,
                featureName: 'Delete Limit for $appName',
                settings: vm.settings,
                onStartCountdown: () => vm.requestDisableFeature(featureKey),
                onDisableConfirmed: () {
                  vm.removeAppLimit(packageName);
                  vm.clearDisableCountdown();
                },
                onCancelCountdown: () => vm.clearDisableCountdown(),
              ),
            ),
          ),
        );
      }
    } else {
      vm.removeAppLimit(packageName);
    }
  }

  void _showAddAppsSheet(BuildContext context, AppLimitsViewModel vm) {
    _searchController.clear();
    vm.setSearchQuery("");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              final sheetVm = context.watch<AppLimitsViewModel>();
              final apps = sheetVm.filteredApps;

              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Limit Applications',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.pagePadding),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          sheetVm.setSearchQuery(v);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search apps...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    sheetVm.setSearchQuery("");
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: sheetVm.isAppsLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.pagePadding),
                              itemCount: apps.length,
                              itemBuilder: (context, index) {
                                final app = apps[index];
                                final isAlreadyAdded =
                                    sheetVm.isAppLimited(app.packageName);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    leading: app.icon != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(
                                              app.icon!,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.apps,
                                                color: AppColors.primary,
                                                size: 20),
                                          ),
                                    title: Text(
                                      app.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      isAlreadyAdded
                                          ? 'Limit: ${_formatLimit(sheetVm.getLimitForApp(app.packageName)!)}'
                                          : 'No limit set',
                                      style: TextStyle(
                                        color: isAlreadyAdded
                                            ? AppColors.warning
                                            : AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: isAlreadyAdded
                                        ? IconButton(
                                            icon: const Icon(Icons.check_circle,
                                                color: AppColors.warning),
                                            onPressed: () {
                                              _handleDeleteLimit(
                                                  context,
                                                  sheetVm,
                                                  app.packageName,
                                                  app.name);
                                            },
                                          )
                                        : ElevatedButton(
                                            onPressed: () {
                                              _showLimitDialog(
                                                context,
                                                sheetVm,
                                                app.packageName,
                                                app.name,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                            child: const Text('Add',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12)),
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showLimitDialog(
    BuildContext context,
    AppLimitsViewModel vm,
    String packageName,
    String appName, {
    int? currentLimit,
  }) {
    final controller =
        TextEditingController(text: currentLimit?.toString() ?? '30');
    int selectedMinutes = currentLimit ?? 30;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Daily Limit for $appName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specify how long you can use this app every day.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                            hintText: 'e.g. 45',
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              setDialogState(() {
                                selectedMinutes = parsed;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('PRESETS',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 45, 60, 120].map((mins) {
                      final isSelected = selectedMinutes == mins;
                      return ChoiceChip(
                        label: Text(
                          mins < 60 ? '$mins m' : '${mins ~/ 60} h',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedMinutes = mins;
                              controller.text = mins.toString();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                TextButton(
                  onPressed: () {
                    final mins = int.tryParse(controller.text);
                    if (mins != null && mins > 0) {
                      vm.setAppLimit(packageName, mins);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Set Limit',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
