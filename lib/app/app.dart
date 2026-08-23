import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../features/home/view/home_screen.dart';
import '../features/home/viewmodel/home_viewmodel.dart';
import '../features/stats/view/stats_screen.dart';
import '../features/stats/viewmodel/stats_viewmodel.dart';
import '../features/study_mode/view/study_mode_screen.dart';
import '../features/study_mode/viewmodel/study_mode_viewmodel.dart';
import '../features/study_mode/viewmodel/study_stats_viewmodel.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/reels_blocker/view/reels_block_overlay.dart';
import '../features/app_limits/viewmodel/app_limits_viewmodel.dart';

import '../features/settings/viewmodel/settings_viewmodel.dart';

class MindLockApp extends StatelessWidget {
  const MindLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => StatsViewModel()),
        ChangeNotifierProvider(create: (_) => StudyModeViewModel()),
        ChangeNotifierProvider(
            create: (_) => StudyStatsViewModel()..loadStats()),
        ChangeNotifierProvider(create: (_) => AppLimitsViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: MaterialApp(
        title: 'MindLock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routes: {
          '/': (context) => const MainNavigation(),
          '/reels_block': (context) => const ReelsBlockOverlay(),
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const StudyModeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Study Mode'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
