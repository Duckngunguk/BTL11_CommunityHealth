import 'package:flutter/material.dart';

import 'parent_home_screen.dart';
import 'parent_notifications_screen.dart';

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
    final pages = [
      const ParentHomeScreen(),
      ParentNotificationsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              ['Hồ sơ con tôi', 'Thông báo'][_index],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 15, color: Color(0xFF2E7D32)),
                  SizedBox(width: 4),
                  Text(
                    'Phụ huynh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.child_care_outlined),
            selectedIcon: Icon(Icons.child_care_rounded),
            label: 'Hồ sơ con',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Thông báo',
          ),
        ],
      ),
    );
  }
}
