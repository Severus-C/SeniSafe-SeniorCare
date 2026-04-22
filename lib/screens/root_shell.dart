import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/senisafe_app_state.dart';
import 'emergency/emergency_screen.dart';
import 'home/home_screen.dart';
import 'medication/medication_assistant_screen.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final SeniSafeAppState appState = context.watch<SeniSafeAppState>();

    final List<Widget> screens = <Widget>[
      const HomeScreen(),
      const MedicationAssistantScreen(),
      const EmergencyScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(
          key: ValueKey<AppTab>(appState.currentTab),
          child: screens[appState.currentTab.index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.currentTab.index,
        onDestinationSelected: (int index) {
          appState.switchTab(AppTab.values[index]);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: AppStrings.homeTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_liquid_outlined),
            selectedIcon: Icon(Icons.medication_liquid),
            label: AppStrings.medicationTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos),
            label: AppStrings.emergencyTab,
          ),
        ],
      ),
    );
  }
}
