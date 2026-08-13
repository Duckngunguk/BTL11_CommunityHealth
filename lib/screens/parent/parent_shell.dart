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
  bool _initialCloudRefreshRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialCloudRefreshRequested) return;
    _initialCloudRefreshRequested = true;
    Future<void>.microtask(() async {
      if (!mounted) return;
      await AppScope.of(context).refreshFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final children = store.currentUserChildren;

    final pages = [
      const ParentHomeScreen(),
      _ParentVaccinationBookTab(children: children),
      const ParentNotificationsScreen(),
      ParentSettingsScreen(onLogout: widget.onLogout),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        if (isDesktop) {
          return Scaffold(
            backgroundColor: pageBackground,
            body: Row(
              children: [
                _ParentDesktopNavigation(
                  selectedIndex: _index,
                  userName: store.currentUser?.fullName ?? 'Phụ huynh',
                  childCount: children.length,
                  onSelected: (value) => setState(() => _index = value),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Trang chủ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.child_care_outlined),
                  selectedIcon: Icon(Icons.child_care_rounded),
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
      },
    );
  }
}

class _ParentDesktopNavigation extends StatelessWidget {
  const _ParentDesktopNavigation({
    required this.selectedIndex,
    required this.userName,
    required this.childCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final String userName;
  final int childCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Tổng quan'),
      (Icons.child_care_outlined, Icons.child_care_rounded, 'Sổ tiêm của con'),
      (
        Icons.notifications_none_rounded,
        Icons.notifications_rounded,
        'Thông báo'
      ),
      (Icons.settings_outlined, Icons.settings_rounded, 'Cài đặt'),
    ];

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
              'KHÔNG GIAN GIA ĐÌNH',
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
            final selected = selectedIndex == index;
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
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryLight,
                  child: Icon(Icons.person_outline_rounded,
                      color: primaryDark, size: 19),
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
                        '$childCount hồ sơ trẻ đã liên kết',
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
      return ParentChildDetailScreen(
          childId: children.first.id, showAppBar: false);
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
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6)
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: blueLight, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      child.fullName.characters.first,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue),
                    ),
                  ),
                ),
                title: Text(child.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: gray900,
                        fontSize: 13.5)),
                subtitle: Text('Mã hồ sơ: ${child.id}',
                    style: const TextStyle(fontSize: 11.5, color: gray500)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: gray400, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          ParentChildDetailScreen(childId: child.id)),
                ),
              ),
            )),
      ],
    );
  }
}
