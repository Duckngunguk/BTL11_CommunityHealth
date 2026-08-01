import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'coverage_screen.dart';
import 'plan_screen.dart';
import 'surveillance_screen.dart';
import 'vaccine_catalog_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const titles = ['Tổng quan', 'Tỷ lệ phủ vaccine', 'Giám sát dịch tễ', 'Kế hoạch tiêm lưu động', 'Danh mục vaccine'];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    const pages = [AdminDashboardScreen(), CoverageScreen(), SurveillanceScreen(), PlanScreen(), VaccineCatalogScreen()];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1180,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_rounded, color: primaryGreen, size: 34),
                  if (MediaQuery.sizeOf(context).width >= 1180) ...[
                    const SizedBox(width: 10),
                    const Text('CommunityHealth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
            destinations: [
              const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Tổng quan')),
              const NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: Text('Tỷ lệ phủ')),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: store.emergencyDiseaseCount > 0,
                  label: Text('${store.emergencyDiseaseCount}'),
                  backgroundColor: const Color(0xFFB42318),
                  child: const Icon(Icons.coronavirus_outlined),
                ),
                selectedIcon: const Icon(Icons.coronavirus_rounded),
                label: const Text('Dịch tễ'),
              ),
              const NavigationRailDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: Text('Kế hoạch tiêm')),
              const NavigationRailDestination(icon: Icon(Icons.vaccines_outlined), selectedIcon: Icon(Icons.vaccines_rounded), label: Text('Danh mục vaccine')),
            ],
            groupAlignment: -0.55,
            trailing: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: IconButton(
                onPressed: widget.onLogout,
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout_rounded),
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
                      Expanded(child: Text(titles[_index], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                      if (store.emergencyDiseaseCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE9E7),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_rounded, size: 16, color: Color(0xFFB42318)),
                              const SizedBox(width: 4),
                              Text('${store.emergencyDiseaseCount} ca khẩn cấp',
                                  style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
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
