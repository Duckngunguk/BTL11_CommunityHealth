import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'disease_report_screen.dart';

class DiseaseReportListScreen extends StatelessWidget {
  const DiseaseReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final reports = store.diseaseReports;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DiseaseReportScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Khai báo mới'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: reports.isEmpty
          ? const EmptyState(
              title: 'Chưa có báo cáo dịch tễ',
              description: 'Nhấn nút "Khai báo mới" để tạo báo cáo ca bệnh nghi ngờ.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // ── Tổng quan nhanh ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        store.emergencyDiseaseCount > 0 ? const Color(0xFFB42318) : primaryGreen,
                        store.emergencyDiseaseCount > 0 ? const Color(0xFFD94A3D) : const Color(0xFF24A875),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            store.emergencyDiseaseCount > 0 ? Icons.warning_rounded : Icons.analytics_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            store.emergencyDiseaseCount > 0
                                ? '${store.emergencyDiseaseCount} ca KHẨN CẤP'
                                : 'Tình hình dịch tễ ổn định',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tổng: ${reports.length} báo cáo • Chờ đồng bộ: ${store.pendingDiseaseReportCount}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Danh sách báo cáo ──
                ...reports.map((report) => _DiseaseReportCard(report: report)),
              ],
            ),
    );
  }
}

class _DiseaseReportCard extends StatelessWidget {
  const _DiseaseReportCard({required this.report});

  final DiseaseReport report;

  @override
  Widget build(BuildContext context) {
    final pending = report.syncStatus == SyncStatus.pending;
    final (urgencyLabel, urgencyColor, urgencyBg) = switch (report.urgency) {
      DiseaseUrgency.routine => ('Thường', const Color(0xFF18794E), const Color(0xFFE5F5EC)),
      DiseaseUrgency.elevated => ('Nâng cao', const Color(0xFF8A5D00), const Color(0xFFFFF3CD)),
      DiseaseUrgency.emergency => ('Khẩn cấp', const Color(0xFFB42318), const Color(0xFFFFE9E7)),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: urgencyBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.coronavirus_rounded, color: urgencyColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.diseaseName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('${report.patientName} • ${report.patientAge} tháng tuổi',
                            style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
                  // Urgency pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: urgencyBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(urgencyLabel, style: TextStyle(color: urgencyColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Location & date
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 15, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text('${report.village}, ${report.commune}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(formatDate(report.onsetDate), style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              // Symptoms preview
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: report.symptoms.take(3).map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                )).toList(),
              ),
              if (report.symptoms.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${report.symptoms.length - 3} triệu chứng khác', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ),
              const SizedBox(height: 8),
              // Sync status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pending ? const Color(0xFFFFF3CD) : const Color(0xFFE5F5EC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      pending ? 'Chờ đồng bộ' : 'Đã đồng bộ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E)),
                    ),
                  ),
                  const Spacer(),
                  Text('Báo cáo: ${report.reportedBy}', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.coronavirus_rounded, color: Color(0xFFB42318), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(report.diseaseName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const Divider(height: 28),
            _DetailRow(icon: Icons.person_outline, label: 'Bệnh nhân', value: '${report.patientName} (${report.patientGender})'),
            _DetailRow(icon: Icons.cake_outlined, label: 'Tuổi', value: '${report.patientAge} tháng'),
            _DetailRow(icon: Icons.place_outlined, label: 'Địa điểm', value: '${report.village}, ${report.commune}'),
            _DetailRow(icon: Icons.calendar_today, label: 'Ngày khởi phát', value: formatDate(report.onsetDate)),
            _DetailRow(icon: Icons.badge_outlined, label: 'Cán bộ báo cáo', value: report.reportedBy),
            _DetailRow(icon: Icons.access_time, label: 'Thời gian báo cáo', value: '${formatDate(report.reportedAt)} ${report.reportedAt.hour}:${report.reportedAt.minute.toString().padLeft(2, '0')}'),
            const Divider(height: 28),
            Text('Triệu chứng ghi nhận', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...report.symptoms.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFB42318), size: 18),
                  const SizedBox(width: 8),
                  Text(s),
                ],
              ),
            )),
            if ((report.notes ?? '').isNotEmpty) ...[
              const Divider(height: 28),
              Text('Ghi chú / Biện pháp', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(report.notes!, style: const TextStyle(height: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
