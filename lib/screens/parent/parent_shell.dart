import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'parent_home_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_child_detail_screen.dart';

import 'parent_settings_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;

    // Filter children strictly for the logged-in parent
    final children = store.children.where((child) {
      if (user == null) return true;
      if (user.username == 'parent.demo') {
        return child.motherName.contains('Giàng A Sáng') || child.motherName.contains('Giàng');
      }
      final parentName = user.fullName.toLowerCase().trim();
      final motherName = child.motherName.toLowerCase().trim();
      return (parentName.isNotEmpty && motherName.contains(parentName)) ||
          (user.phone.isNotEmpty && child.motherPhone == user.phone);
    }).toList();

    final pages = [
      const ParentHomeScreen(),
      _ParentVaccinationBookTab(children: children),
      const ParentNotificationsScreen(),
      ParentSettingsScreen(onLogout: widget.onLogout),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Sổ tiêm',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Thông báo',
            ),
            NavigationDestination(
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

class _ParentVaccinationBookTab extends StatelessWidget {
  const _ParentVaccinationBookTab({required this.children});
  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Chưa có hồ sơ con liên kết.\nVui lòng liên hệ cán bộ y tế để đăng ký.',
            textAlign: TextAlign.center,
            style: TextStyle(color: gray500, height: 1.4),
          ),
        ),
      );
    }

    if (children.length == 1) {
      return ParentChildDetailScreen(childId: children.first.id, showAppBar: false);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionLabel('Chọn sổ tiêm của con'),
        const SizedBox(height: 4),
        ...children.map((child) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gray200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: blueLight, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      child.fullName.characters.first,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryBlue),
                    ),
                  ),
                ),
                title: Text(child.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: gray900, fontSize: 13.5)),
                subtitle: Text('Mã hồ sơ: ${child.id}',
                    style: const TextStyle(fontSize: 11.5, color: gray500)),
                trailing: const Icon(Icons.chevron_right_rounded, color: gray400, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ParentChildDetailScreen(childId: child.id)),
                ),
              ),
            )),
      ],
    );
  }
}
