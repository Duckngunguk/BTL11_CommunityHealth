import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'children_screen.dart';
import 'disease_report_screen.dart';
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
    final navigationItems = [
      (Icons.home_outlined, Icons.home_rounded, 'Tổng quan'),
      (Icons.people_outline_rounded, Icons.people_rounded, 'Hồ sơ trẻ'),
      (
        Icons.health_and_safety_outlined,
        Icons.health_and_safety_rounded,
        'Báo dịch'
      ),
      (Icons.sync_outlined, Icons.sync_rounded, 'Đồng bộ'),
      (Icons.settings_outlined, Icons.settings_rounded, 'Cài đặt'),
    ];
    final pages = [
      HomeScreen(onOpenChildren: () => setState(() => _index = 1)),
      const ChildrenScreen(),
      const DiseaseReportScreen(),
      const SyncScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        if (isDesktop) {
          return Scaffold(
            backgroundColor: pageBackground,
            body: Row(
              children: [
                _DesktopRoleNavigation(
                  userName: store.currentUser?.fullName ?? 'Cán bộ y tế',
                  subtitle: store.currentUser?.assignedCommune ?? 'Tả Phìn',
                  items: navigationItems,
                  selectedIndex: _index,
                  pendingCount: store.pendingCount,
                  isOnline: store.isOnline,
                  onSelected: (value) => setState(() => _index = value),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

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
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Trang chủ',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Hồ sơ trẻ',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.health_and_safety_outlined),
                  selectedIcon: Icon(Icons.health_and_safety_rounded),
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
      },
    );
  }
}

class _DesktopRoleNavigation extends StatelessWidget {
  const _DesktopRoleNavigation({
    required this.userName,
    required this.subtitle,
    required this.items,
    required this.selectedIndex,
    required this.pendingCount,
    required this.isOnline,
    required this.onSelected,
  });

  final String userName;
  final String subtitle;
  final List<(IconData, IconData, String)> items;
  final int selectedIndex;
  final int pendingCount;
  final bool isOnline;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                AppLogo(size: 40, compact: true),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CommunityHealth',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gray900,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'KHÔNG GIAN CÁN BỘ',
              style: TextStyle(
                color: gray400,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: selected ? primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        Icon(
                          selected ? item.$2 : item.$1,
                          color: selected ? primaryDark : gray500,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$3,
                            style: TextStyle(
                              color: selected ? primaryDark : gray700,
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (index == 3 && pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentYellow,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gray100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gray200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryLight,
                  child: Text(
                    userName.trim().isEmpty ? 'YT' : userName.trim()[0],
                    style: const TextStyle(
                      color: primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: gray900,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$subtitle • ${isOnline ? "Trực tuyến" : "Ngoại tuyến"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: gray500, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
