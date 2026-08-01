import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final total = demoCoverage.fold<int>(0, (sum, item) => sum + item.total);
    final fully = demoCoverage.fold<int>(0, (sum, item) => sum + item.fully);
    final coverage = fully / total * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200 ? 4 : constraints.maxWidth >= 700 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader(title: 'Tình hình tiêm chủng toàn huyện', subtitle: 'Dữ liệu demo cập nhật đến ngày 24/07/2026.'),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'Trẻ 0–5 tuổi', value: '$total', icon: Icons.groups_2_outlined, background: const Color(0xFFE7F0FF), caption: '6 xã đang theo dõi'),
                StatCard(label: 'Đã tiêm đầy đủ', value: '$fully', icon: Icons.verified_outlined, background: softGreen, caption: '${coverage.toStringAsFixed(1)}% toàn huyện'),
                StatCard(label: 'Trẻ trễ lịch', value: '${store.lateCount}', icon: Icons.warning_amber_rounded, background: const Color(0xFFFFE9E7), caption: 'Cần ưu tiên liên hệ'),
                StatCard(label: 'Ca nghi nhiễm', value: '${store.diseaseReportCount}', icon: Icons.coronavirus_outlined, background: store.emergencyDiseaseCount > 0 ? const Color(0xFFFFE9E7) : const Color(0xFFF0F8FF), caption: store.emergencyDiseaseCount > 0 ? '${store.emergencyDiseaseCount} ca khẩn cấp' : 'Chưa có ca khẩn cấp'),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, inner) {
                final wide = inner.maxWidth >= 930;
                final coverageCard = _CoverageOverviewCard();
                final alertCard = _AlertCard(store: store);
                if (!wide) {
                  return Column(children: [coverageCard, const SizedBox(height: 16), alertCard]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: coverageCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: alertCard),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CoverageOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Tỷ lệ phủ theo xã', subtitle: 'Xanh ≥ 80%, vàng 60–79%, đỏ < 60%.'),
            const SizedBox(height: 20),
            ...demoCoverage.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: item.coverage / 100,
                            minHeight: 13,
                            backgroundColor: const Color(0xFFE8ECEA),
                            color: item.coverage >= 80 ? const Color(0xFF27AE60) : item.coverage >= 60 ? const Color(0xFFF2C94C) : const Color(0xFFEB5757),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 52, child: Text('${item.coverage.toStringAsFixed(1)}%', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final late = store.children.where((child) => child.lateDays > 0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Cảnh báo trễ lịch', subtitle: 'Danh sách cần cán bộ xã xử lý sớm.'),
            const SizedBox(height: 14),
            ...late.map((child) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFFE9E7), child: Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318))),
                  title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${child.commune} • ${child.nextVaccine}'),
                  trailing: Text('${child.lateDays} ngày', style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w800)),
                )),
          ],
        ),
      ),
    );
  }
}
