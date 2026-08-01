import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'child_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenChildren});

  final VoidCallback onOpenChildren;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final urgentChildren = store.children.where((child) => child.lateDays > 0).take(3).toList();

    return RefreshIndicator(
      onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryGreen, Color(0xFF24A875)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xin chào, Y sĩ Lê Thu', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text(
                  'Hôm nay có 2 trẻ cần được ưu tiên tiêm.',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: onOpenChildren,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Tìm kiếm trẻ em'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(label: 'Tổng số trẻ', value: '${store.children.length}', icon: Icons.groups_2_outlined, background: const Color(0xFFE7F0FF)),
              StatCard(label: 'Trễ lịch', value: '${store.lateCount}', icon: Icons.warning_amber_rounded, background: const Color(0xFFFFE9E7)),
              StatCard(label: 'Sắp đến lịch', value: '${store.dueSoonCount}', icon: Icons.event_available_outlined, background: const Color(0xFFFFF3CD)),
              StatCard(label: 'Chờ đồng bộ', value: '${store.pendingCount}', icon: Icons.cloud_upload_outlined, background: softGreen),
              StatCard(
                label: 'Ca nghi nhiễm',
                value: '${store.diseaseReportCount}',
                icon: Icons.coronavirus_outlined,
                background: store.emergencyDiseaseCount > 0 ? const Color(0xFFFFE9E7) : const Color(0xFFF0F8FF),
                caption: store.emergencyDiseaseCount > 0 ? '${store.emergencyDiseaseCount} ca khẩn cấp' : null,
              ),
              StatCard(label: 'Y sĩ phụ trách', value: store.currentUser.fullName.replaceFirst('Y sĩ ', ''), icon: Icons.badge_outlined, background: const Color(0xFFF0F0FF)),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Cần ưu tiên',
            subtitle: 'Các trẻ đang trễ lịch tiêm chủng.',
            trailing: TextButton(onPressed: onOpenChildren, child: const Text('Xem tất cả')),
          ),
          const SizedBox(height: 12),
          ...urgentChildren.map(
            (child) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE9E7),
                  child: Text(child.fullName.characters.first, style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.bold)),
                ),
                title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text('${child.village} • Trễ ${child.nextVaccine} ${child.lateDays} ngày'),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ChildDetailScreen(childId: child.id)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Icon(store.isOnline ? Icons.cloud_done : Icons.cloud_off, color: store.isOnline ? primaryGreen : const Color(0xFF8A5D00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.isOnline ? 'Thiết bị đang trực tuyến' : 'Thiết bị đang ngoại tuyến', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Đồng bộ gần nhất: ${formatDate(store.lastSyncAt)} ${store.lastSyncAt.hour}:${store.lastSyncAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.black54)),
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
