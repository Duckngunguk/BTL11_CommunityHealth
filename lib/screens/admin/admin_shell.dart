import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'coverage_screen.dart';
import 'epidemic_map_screen.dart';
import 'plan_screen.dart';
import 'system_logs_screen.dart';
import 'user_management_screen.dart';
import 'vaccine_catalog_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  String _userFilter = 'Tất cả';

  static const titles = [
    'Tổng quan Hệ thống',
    'Bản đồ cảnh báo dịch tễ',
    'Tỷ lệ phủ vaccine',
    'Kế hoạch tiêm lưu động',
    'Danh mục vaccine',
    'Quản lý Người dùng & Phân quyền',
    'Nhật ký Hoạt động Hệ thống',
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pages = [
      const AdminDashboardScreen(),
      const EpidemicMapScreen(),
      const CoverageScreen(),
      const PlanScreen(),
      const VaccineCatalogScreen(),
      UserManagementScreen(initialStatusFilter: _userFilter),
      const SystemLogsScreen(),
    ];

    final extended = MediaQuery.sizeOf(context).width >= 1180;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_rounded, color: primaryGreen, size: 34),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    const Text('CommunityHealth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Tổng quan'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.crisis_alert_outlined),
                selectedIcon: Icon(Icons.crisis_alert_rounded),
                label: Text('Bản đồ dịch tễ'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: Text('Tỷ lệ phủ'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: Text('Kế hoạch'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.vaccines_outlined),
                selectedIcon: Icon(Icons.vaccines_rounded),
                label: Text('Danh mục'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: store.pendingUserApprovals > 0,
                  label: Text('${store.pendingUserApprovals}'),
                  child: const Icon(Icons.manage_accounts_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: store.pendingUserApprovals > 0,
                  label: Text('${store.pendingUserApprovals}'),
                  child: const Icon(Icons.manage_accounts_rounded),
                ),
                label: const Text('Người dùng'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: Text('Nhật ký'),
              ),
            ],
            groupAlignment: -0.55,
            trailing: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (extended)
                    const Text(
                      'admin.demo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
                    ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: widget.onLogout,
                    tooltip: 'Đăng xuất',
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titles[_index],
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      // Banner thông báo tài khoản chờ phê duyệt
                      if (store.pendingUserApprovals > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _userFilter = 'Chờ duyệt';
                              _index = 5;
                            }),
                            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFB42318)),
                            label: Text(
                              '${store.pendingUserApprovals} tài khoản chờ duyệt',
                              style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      const Icon(Icons.notifications_none_rounded),
                      const SizedBox(width: 18),
                      const CircleAvatar(child: Text('AD')),
                      const SizedBox(width: 10),
                      const Text('Trung tâm Y tế Sa Pa', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
