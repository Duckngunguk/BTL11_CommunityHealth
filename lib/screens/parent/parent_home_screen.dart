import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'parent_child_detail_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final children = store.children;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header chào mừng
        _WelcomeBanner(totalChildren: children.length),
        const SizedBox(height: 20),

        // Thống kê nhanh
        _QuickStats(children: children),
        const SizedBox(height: 24),

        // Danh sách hồ sơ con
        const Text(
          'Hồ sơ tiêm chủng của con',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Nhấn vào hồ sơ để xem chi tiết lịch sử tiêm chủng.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),

        if (children.isEmpty)
          const EmptyState(
            title: 'Chưa có hồ sơ nào',
            description: 'Liên hệ cán bộ y tế để được tạo hồ sơ tiêm chủng cho con.',
          )
        else
          ...children.map((child) => _ParentChildCard(child: child)),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.totalChildren});
  final int totalChildren;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào, Phụ huynh! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bạn đang theo dõi sức khỏe cho $totalChildren trẻ.\nHãy luôn giữ lịch tiêm đúng hạn!',
                  style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.children});
  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    final late = children.where((c) => c.status == ChildVaccinationStatus.late).length;
    final dueSoon = children.where((c) => c.status == ChildVaccinationStatus.dueSoon).length;
    final complete = children.where((c) => c.status == ChildVaccinationStatus.complete).length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.warning_amber_rounded,
            value: '$late',
            label: 'Trễ lịch',
            color: const Color(0xFFB42318),
            background: const Color(0xFFFFE9E7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_rounded,
            value: '$dueSoon',
            label: 'Sắp đến hạn',
            color: const Color(0xFF8A5D00),
            background: const Color(0xFFFFF3CD),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_rounded,
            value: '$complete',
            label: 'Đã đủ',
            color: const Color(0xFF18794E),
            background: const Color(0xFFE5F5EC),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ParentChildCard extends StatelessWidget {
  const _ParentChildCard({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final isLate = child.status == ChildVaccinationStatus.late;
    final isDueSoon = child.status == ChildVaccinationStatus.dueSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ParentChildDetailScreen(childId: child.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar trẻ
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        child.fullName.characters.first,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${child.gender} • ${child.village}, ${child.commune}',
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(status: child.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Mũi tiêm tiếp theo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mũi tiêm tiếp theo',
                          style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          child.nextVaccine,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ngày hẹn
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Ngày hẹn',
                        style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatDate(child.nextDue),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isLate
                              ? const Color(0xFFB42318)
                              : isDueSoon
                                  ? const Color(0xFF8A5D00)
                                  : const Color(0xFF18794E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isLate) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB42318)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trễ ${child.lateDays} ngày! Hãy đưa con đến trạm y tế sớm nhất có thể.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${child.vaccinations.length} mũi tiêm • ${child.medications.length} lần uống thuốc',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const Row(
                    children: [
                      Text('Xem chi tiết', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32), size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
