import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class EpidemicMapScreen extends StatefulWidget {
  const EpidemicMapScreen({super.key});

  @override
  State<EpidemicMapScreen> createState() => _EpidemicMapScreenState();
}

class _EpidemicMapScreenState extends State<EpidemicMapScreen> {
  String _selectedDisease = 'Tất cả';
  String? _selectedCommune;

  final _diseases = ['Tất cả', 'Sởi', 'Tả', 'Sốt xuất huyết', 'Thuỷ đậu', 'Khác'];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final allReports = store.diseaseReports;

    // Lọc theo bệnh dịch
    final filteredReports = allReports.where((r) {
      if (_selectedDisease != 'Tất cả' && r.diseaseType != _selectedDisease) return false;
      if (_selectedCommune != null && r.commune != _selectedCommune) return false;
      return true;
    }).toList();

    // Thống kê nhanh
    final measleCount = allReports.where((r) => r.diseaseType == 'Sởi').length;
    final choleraCount = allReports.where((r) => r.diseaseType == 'Tả').length;
    final dengueCount = allReports.where((r) => r.diseaseType == 'Sốt xuất huyết').length;
    final pendingSync = allReports.where((r) => r.syncStatus == VaccinationSyncStatus.pending).length;

    // Danh sách các xã cần hiển thị bản đồ
    final communes = ['Tả Phìn', 'Hầu Thào', 'San Sả Hồ', 'Tả Van', 'Lao Chải', 'Bản Hồ'];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.crisis_alert_rounded, color: Color(0xFFB42318), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bản đồ cảnh báo dịch tễ theo Xã',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Giám sát ca bệnh nghi ngờ (Sởi, Tả, Sốt xuất huyết...) được báo cáo từ các cán bộ y tế cơ sở.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Thẻ KPI tổng quan dịch bệnh
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Tổng ca nghi ngờ',
                  value: '${allReports.length}',
                  subText: pendingSync > 0 ? '$pendingSync ca mới vừa đồng bộ' : 'Dữ liệu thời gian thực',
                  icon: Icons.coronavirus_rounded,
                  color: const Color(0xFFB42318),
                  bgColor: const Color(0xFFFFE9E7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Ca Sởi (Measles)',
                  value: '$measleCount',
                  subText: 'Nguy cơ bùng phát cao',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Ca Tả (Cholera)',
                  value: '$choleraCount',
                  subText: 'Cần xử lý nguồn nước',
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Sốt xuất huyết',
                  value: '$dengueCount',
                  subText: 'Diệt bọ gậy tại chỗ',
                  icon: Icons.bug_report_rounded,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bộ lọc bệnh & xã
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, color: Colors.black54),
                  const SizedBox(width: 8),
                  const Text('Lọc loại bệnh: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    children: _diseases.map((d) {
                      final isSelected = _selectedDisease == d;
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedDisease = d);
                        },
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  if (_selectedCommune != null)
                    ActionChip(
                      avatar: const Icon(Icons.clear_rounded, size: 16),
                      label: Text('Đang chọn: Xã $_selectedCommune'),
                      onPressed: () => setState(() => _selectedCommune = null),
                      backgroundColor: const Color(0xFFFFF3CD),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Phần Bản đồ lưới dạng sơ đồ địa bàn xã (Commune Epidemic Heatmap Grid)
          const Text(
            'Bản đồ khu vực dịch tễ huyện Sa Pa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bấm vào từng Xã trên bản đồ để xem chi tiết danh sách ca bệnh và cập nhật tình trạng khoanh vùng.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Lưới địa bàn các Xã
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: communes.length,
            itemBuilder: (context, index) {
              final communeName = communes[index];
              final communeReports = allReports.where((r) => r.commune == communeName).toList();
              final isSelected = _selectedCommune == communeName;

              return _CommuneMapTile(
                communeName: communeName,
                reports: communeReports,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCommune = isSelected ? null : communeName;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Danh sách ca bệnh tương ứng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCommune == null
                    ? 'Danh sách tất cả ca bệnh (${filteredReports.length})'
                    : 'Danh sách ca bệnh tại Xã $_selectedCommune (${filteredReports.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (_selectedCommune != null)
                TextButton(
                  onPressed: () => setState(() => _selectedCommune = null),
                  child: const Text('Xem toàn huyện'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredReports.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Không có ca bệnh nghi ngờ nào phù hợp với bộ lọc.'),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReports.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = filteredReports[index];
                  return _AdminDiseaseReportTile(report: r);
                },
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String title;
  final String value;
  final String subText;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(subText, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CommuneMapTile extends StatelessWidget {
  const _CommuneMapTile({
    required this.communeName,
    required this.reports,
    required this.isSelected,
    required this.onTap,
  });

  final String communeName;
  final List<DiseaseReport> reports;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severeCount = reports.where((r) => r.severity == DiseaseSeverity.severe || r.diseaseType == 'Tả' || r.diseaseType == 'Sởi').length;
    final totalCount = reports.length;

    // Xác định mức độ cảnh báo của Xã
    final (statusLabel, statusColor, bgColor, borderColor) = switch ((severeCount, totalCount)) {
      ( > 0, _) => ('BÁO ĐỘNG ĐỎ', const Color(0xFFB42318), const Color(0xFFFFE9E7), const Color(0xFFFCA5A5)),
      (0, > 0) => ('CẢNH BÁO', const Color(0xFFD97706), const Color(0xFFFEF3C7), const Color(0xFFFCD34D)),
      _ => ('AN TOÀN', const Color(0xFF059669), const Color(0xFFD1FAE5), const Color(0xFF6EE7B7)),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF167D5A) : borderColor,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF167D5A).withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: Colors.black87),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Xã $communeName',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCount ca dịch',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                      Text(
                        severeCount > 0 ? '$severeCount ca nặng/Sởi/Tả' : 'Không có ca bùng phát',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                  color: isSelected ? const Color(0xFF167D5A) : Colors.black38,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDiseaseReportTile extends StatelessWidget {
  const _AdminDiseaseReportTile({required this.report});
  final DiseaseReport report;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final isPending = report.syncStatus == VaccinationSyncStatus.pending;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.coronavirus_rounded, color: Color(0xFFB42318), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      report.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9E7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.diseaseType,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB42318), fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('Offline Sync', style: TextStyle(fontSize: 10, color: Color(0xFF8A5D00), fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Địa bàn: ${report.village}, Xã ${report.commune} • Khai báo bởi: ${report.reportedBy} (${formatDate(report.reportedAt)})',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Triệu chứng: ${report.symptoms}',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                if ((report.notes ?? '').isNotEmpty)
                  Text(
                    'Xử lý: ${report.notes}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: report.status,
                underline: const SizedBox(),
                items: ['Nghi ngờ', 'Đã xác minh', 'Đã khoanh vùng', 'Đã khỏi']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))
                    .toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    store.updateDiseaseReportStatus(report.id, newVal);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã cập nhật trạng thái ca bệnh thành "$newVal"')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
