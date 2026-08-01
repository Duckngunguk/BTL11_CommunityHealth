import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'children_screen.dart';
import 'disease_report_list_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sync_screen.dart';

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
      const DiseaseReportListScreen(),
      const SyncScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.health_and_safety_rounded, color: primaryGreen),
            const SizedBox(width: 8),
            Text(['Tổng quan', 'Trẻ em', 'Dịch tễ', 'Đồng bộ', 'Cài đặt'][_index]),
          ],
        ),
        actions: [
          // Badge hiển thị số ca khẩn cấp
          if (store.emergencyDiseaseCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: () => setState(() => _index = 2),
                tooltip: '${store.emergencyDiseaseCount} ca khẩn cấp',
                icon: Badge(
                  label: Text('${store.emergencyDiseaseCount}'),
                  backgroundColor: const Color(0xFFB42318),
                  child: const Icon(Icons.coronavirus_rounded, color: Color(0xFFB42318)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: store.isOnline ? 'Đang có mạng' : 'Đang ngoại tuyến',
              child: CircleAvatar(
                backgroundColor: store.isOnline ? const Color(0xFFE5F5EC) : const Color(0xFFFFF3CD),
                child: Icon(
                  store.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: store.isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          const NavigationDestination(icon: Icon(Icons.child_care_outlined), selectedIcon: Icon(Icons.child_care_rounded), label: 'Trẻ em'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: store.pendingDiseaseReportCount > 0,
              label: Text('${store.pendingDiseaseReportCount}'),
              child: const Icon(Icons.coronavirus_outlined),
            ),
            selectedIcon: const Icon(Icons.coronavirus_rounded),
            label: 'Dịch tễ',
          ),
          const NavigationDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync_rounded), label: 'Đồng bộ'),
          const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
