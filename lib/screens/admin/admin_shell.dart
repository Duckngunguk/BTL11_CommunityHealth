import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'epidemic_map_screen.dart';
import 'plan_screen.dart';
import 'settings_screen.dart';
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
    'Tổng quan',
    'Bản đồ và tỷ lệ bao phủ',
    'Kế hoạch tiêm lưu động',
    'Danh mục vắc-xin',
    'Người dùng và phân quyền',
    'Nhật ký hoạt động',
    'Cấu hình hệ thống',
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pages = [
      const AdminDashboardScreen(),
      const EpidemicMapScreen(),
      const PlanScreen(),
      const VaccineCatalogScreen(),
      UserManagementScreen(initialStatusFilter: _userFilter),
      const SystemLogsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: gray100,
      body: Row(
        children: [
          // ── Custom Left Sidebar (Matching Prototype) ──
          _AdminSidebar(
            selectedIndex: _index,
            pendingApprovals: store.pendingUserApprovals,
            onSelected: (index) {
              setState(() {
                _index = index;
                if (index == 4) {
                  _userFilter = 'Tất cả';
                }
              });
            },
            onLogout: widget.onLogout,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titles[_index],
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: gray900,
                              letterSpacing: -.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Trung tâm Y tế thị xã Sa Pa',
                            style: TextStyle(color: gray500, fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Approvals Alert Badge/Banner
                      if (store.pendingUserApprovals > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _userFilter = 'Chờ duyệt';
                              _index = 4;
                            }),
                            icon: const Icon(Icons.person_add_alt_1_rounded,
                                color: accentRed, size: 16),
                            label: Text(
                              '${store.pendingUserApprovals} tài khoản chờ duyệt',
                              style: const TextStyle(
                                  color: accentRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: gray700),
                        tooltip: 'Thông báo',
                        offset: const Offset(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        elevation: 4,
                        itemBuilder: (context) {
                          final list = <PopupMenuEntry<String>>[];

                          // Header title (non-interactive)
                          list.add(
                            const PopupMenuItem(
                              enabled: false,
                              child: Text(
                                'Thông báo hệ thống',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: gray900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                          list.add(const PopupMenuDivider());

                          if (store.pendingUserApprovals > 0) {
                            list.add(
                              PopupMenuItem(
                                value: 'approvals',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_add_alt_1_rounded,
                                        color: Color(0xFFB42318), size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${store.pendingUserApprovals} tài khoản chờ duyệt',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFFB42318)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final activeOutbreaks = store.diseaseReports
                              .where((r) => r.status != 'Đã khỏi')
                              .length;
                          if (activeOutbreaks > 0) {
                            if (store.pendingUserApprovals > 0) {
                              list.add(const PopupMenuDivider());
                            }
                            list.add(
                              PopupMenuItem(
                                value: 'outbreaks',
                                child: Row(
                                  children: [
                                    const Icon(Icons.crisis_alert_rounded,
                                        color: Colors.orange, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Có $activeOutbreaks ca dịch đang cảnh báo',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (store.pendingUserApprovals == 0 &&
                              activeOutbreaks == 0) {
                            list.add(
                              const PopupMenuItem(
                                enabled: false,
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_off_outlined,
                                        color: Colors.grey, size: 18),
                                    SizedBox(width: 10),
                                    Text(
                                      'Không có thông báo mới',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return list;
                        },
                        onSelected: (value) {
                          if (value == 'approvals') {
                            setState(() {
                              _userFilter = 'Chờ duyệt';
                              _index = 4; // Quản lý người dùng
                            });
                          } else if (value == 'outbreaks') {
                            setState(() {
                              _index = 1; // Bản đồ dịch tễ
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor: primaryLight,
                        child: Text(
                          'AD',
                          style: TextStyle(
                              color: primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Quản trị viên',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: gray900),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: gray200),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: pages[_index],
                    ),
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

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
    required this.pendingApprovals,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;
  final int pendingApprovals;

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Tổng quan'),
      (
        Icons.crisis_alert_outlined,
        Icons.crisis_alert_rounded,
        'Bản đồ & Tỷ lệ phủ'
      ),
      (Icons.event_note_outlined, Icons.event_note_rounded, 'Kế hoạch'),
      (Icons.vaccines_outlined, Icons.vaccines_rounded, 'Danh mục'),
      (
        Icons.manage_accounts_outlined,
        Icons.manage_accounts_rounded,
        'Người dùng'
      ),
      (Icons.history_outlined, Icons.history_rounded, 'Nhật ký'),
      (Icons.settings_outlined, Icons.settings_rounded, 'Cài đặt'),
    ];

    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 22, 20, 20),
            child: Row(
              children: [
                AppLogo(size: 42, compact: true),
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
          const Divider(height: 1, color: gray200),
          const SizedBox(height: 18),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'QUẢN TRỊ HỆ THỐNG',
                style: TextStyle(
                  color: gray400,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Menu Navigation
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == index;
                final isUserManagement = index == 4;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.$2 : item.$1,
                            color: isSelected ? primaryDark : gray500,
                            size: 19,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.$3,
                              style: TextStyle(
                                color: isSelected ? primaryDark : gray700,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          if (isUserManagement && pendingApprovals > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingApprovals',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: gray200),

          // Profile & Logout Card (at the bottom)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gray200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryBlue.withValues(alpha: 0.12),
                        child: const Text(
                          'AD',
                          style: TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'admin.demo',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: gray900),
                            ),
                            Text(
                              'admin@ttyt-sapa.vn',
                              style: TextStyle(fontSize: 10, color: gray500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 13),
                      label: const Text('Đăng xuất',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentRed,
                        side: const BorderSide(color: accentRed, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
