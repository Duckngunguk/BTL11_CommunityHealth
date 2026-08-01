import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class SurveillanceScreen extends StatelessWidget {
  const SurveillanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final reports = store.diseaseReports;
    final byCommune = store.diseaseCountByCommune;
    final byType = store.diseaseCountByType;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200 ? 4 : constraints.maxWidth >= 700 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader(
              title: 'Giám sát dịch tễ toàn huyện',
              subtitle: 'Bản đồ cảnh báo ca bệnh nghi ngờ theo từng xã.',
            ),
            const SizedBox(height: 18),

            // ── Thẻ thống kê tổng quan ──
            GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  label: 'Tổng ca nghi nhiễm',
                  value: '${reports.length}',
                  icon: Icons.coronavirus_outlined,
                  background: const Color(0xFFE7F0FF),
                  caption: 'Trong 30 ngày gần nhất',
                ),
                StatCard(
                  label: 'Ca khẩn cấp',
                  value: '${store.emergencyDiseaseCount}',
                  icon: Icons.emergency_outlined,
                  background: store.emergencyDiseaseCount > 0 ? const Color(0xFFFFE9E7) : const Color(0xFFE5F5EC),
                  caption: store.emergencyDiseaseCount > 0 ? 'Cần xử lý ngay' : 'Không có ca khẩn cấp',
                ),
                StatCard(
                  label: 'Chờ đồng bộ',
                  value: '${store.pendingDiseaseReportCount}',
                  icon: Icons.cloud_upload_outlined,
                  background: const Color(0xFFFFF3CD),
                  caption: 'Từ y sĩ đi bản',
                ),
                StatCard(
                  label: 'Xã có ca bệnh',
                  value: '${byCommune.length}',
                  icon: Icons.location_on_outlined,
                  background: softGreen,
                  caption: 'Trên tổng 6 xã',
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Hai cột: Bản đồ xã + Biểu đồ bệnh ──
            LayoutBuilder(
              builder: (context, inner) {
                final wide = inner.maxWidth >= 930;
                final communeMap = _CommuneMapCard(byCommune: byCommune);
                final diseaseChart = _DiseaseTypeCard(byType: byType);
                if (!wide) {
                  return Column(children: [communeMap, const SizedBox(height: 16), diseaseChart]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: communeMap),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: diseaseChart),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            // ── Danh sách chi tiết các ca gần nhất ──
            const SectionHeader(
              title: 'Báo cáo gần đây',
              subtitle: 'Các ca nghi nhiễm mới nhất từ y sĩ đi bản.',
            ),
            const SizedBox(height: 12),
            ...reports.map((r) => _ReportRow(report: r)),
          ],
        );
      },
    );
  }
}

// ─── Card: Bản đồ cảnh báo theo xã ───

class _CommuneMapCard extends StatelessWidget {
  const _CommuneMapCard({required this.byCommune});

  final Map<String, int> byCommune;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Phân bố ca bệnh theo xã',
              subtitle: '🔴 ≥ 3 ca • 🟡 1–2 ca • 🟢 0 ca',
            ),
            const SizedBox(height: 20),
            ...kCommuneList.map((commune) {
              final count = byCommune[commune] ?? 0;
              final (color, bg, icon) = count >= 3
                  ? (const Color(0xFFB42318), const Color(0xFFFFE9E7), Icons.warning_rounded)
                  : count >= 1
                      ? (const Color(0xFF8A5D00), const Color(0xFFFFF3CD), Icons.info_outlined)
                      : (const Color(0xFF18794E), const Color(0xFFE5F5EC), Icons.check_circle_outline);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: count >= 3 ? Border.all(color: color.withValues(alpha: 0.4)) : null,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(commune, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                          if (count > 0) Text('$count ca nghi nhiễm', style: TextStyle(fontSize: 12, color: color)),
                          if (count == 0) Text('Chưa ghi nhận ca bệnh', style: TextStyle(fontSize: 12, color: color)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Card: Phân bố theo loại bệnh ───

class _DiseaseTypeCard extends StatelessWidget {
  const _DiseaseTypeCard({required this.byType});

  final Map<String, int> byType;

  @override
  Widget build(BuildContext context) {
    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = byType.values.fold<int>(0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Phân bố theo bệnh', subtitle: 'Số ca nghi nhiễm theo từng loại bệnh.'),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.black38))),
              )
            else
              ...entries.map((e) {
                final percent = total > 0 ? e.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text('${e.value} ca', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE8ECEA),
                          color: percent > 0.4
                              ? const Color(0xFFEB5757)
                              : percent > 0.2
                                  ? const Color(0xFFF2C94C)
                                  : const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─── Dòng báo cáo chi tiết ───

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final DiseaseReport report;

  @override
  Widget build(BuildContext context) {
    final (urgencyLabel, urgencyColor) = switch (report.urgency) {
      DiseaseUrgency.routine => ('Thường', const Color(0xFF18794E)),
      DiseaseUrgency.elevated => ('Nâng cao', const Color(0xFF8A5D00)),
      DiseaseUrgency.emergency => ('KHẨN CẤP', const Color(0xFFB42318)),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: report.urgency == DiseaseUrgency.emergency
              ? const Color(0xFFFFE9E7)
              : report.urgency == DiseaseUrgency.elevated
                  ? const Color(0xFFFFF3CD)
                  : const Color(0xFFE5F5EC),
          child: Icon(Icons.coronavirus_rounded, color: urgencyColor),
        ),
        title: Row(
          children: [
            Expanded(child: Text(report.diseaseName, style: const TextStyle(fontWeight: FontWeight.w800))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(urgencyLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: urgencyColor)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${report.patientName} • ${report.village}, ${report.commune}\nBáo cáo: ${report.reportedBy} • ${formatDate(report.reportedAt)}'),
        ),
        trailing: Icon(
          report.syncStatus == SyncStatus.pending ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
          color: report.syncStatus == SyncStatus.pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E),
          size: 20,
        ),
      ),
    );
  }
}
