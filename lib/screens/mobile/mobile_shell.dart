import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'children_screen.dart';
import 'disease_report_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sync_screen.dart';

import 'child_form_dialog.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pages = [
      HomeScreen(onOpenChildren: () => setState(() => _index = 1)),
      const ChildrenScreen(),
      const DiseaseReportScreen(),
      const SyncScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: gray100,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: gray200, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          height: 64,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Phụ huynh',
            ),
            const NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_amber_rounded),
              label: 'Báo dịch',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: store.pendingCount > 0,
                label: Text('${store.pendingCount}'),
                child: const Icon(Icons.sync_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: store.pendingCount > 0,
                label: Text('${store.pendingCount}'),
                child: const Icon(Icons.sync_rounded),
              ),
              label: 'Đồng bộ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}
