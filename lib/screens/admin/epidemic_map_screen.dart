import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class EpidemicMapScreen extends StatefulWidget {
  const EpidemicMapScreen({super.key});

  @override
  State<EpidemicMapScreen> createState() => _EpidemicMapScreenState();
}

class _EpidemicMapScreenState extends State<EpidemicMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  String _selectedDisease = 'Tất cả';
  String? _selectedCommune;
  final _diseases = [
    'Tất cả',
    'Sởi',
    'Tả',
    'Sốt xuất huyết',
    'Thuỷ đậu',
    'Khác'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(double value) {
    if (value >= 80) return const Color(0xFF27AE60);
    if (value >= 60) return const Color(0xFFF2C94C);
    return const Color(0xFFEB5757);
  }

  void _showCoverageDetail(BuildContext context, CommuneCoverage item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tỷ lệ vaccine chi tiết: Xã ${item.name}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VaccineProgressRow(
                  label: 'BCG (Mũi sơ sinh)',
                  value: item.bcg,
                  color: Colors.blue),
              _VaccineProgressRow(
                  label: 'DPT Mũi 1 (2 tháng)',
                  value: item.dpt1,
                  color: Colors.green),
              _VaccineProgressRow(
                  label: 'DPT Mũi 2 (3 tháng)',
                  value: item.dpt2,
                  color: Colors.orange),
              _VaccineProgressRow(
                  label: 'DPT Mũi 3 (4 tháng)',
                  value: item.dpt3,
                  color: Colors.purple),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng',
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final allReports = store.diseaseReports;
    final coverageList = store.communeCoverage;

    // Filter reports
    final filteredReports = allReports.where((r) {
      if (_selectedDisease != 'Tất cả' && r.diseaseType != _selectedDisease) {
        return false;
      }
      if (_selectedCommune != null && r.commune != _selectedCommune) {
        return false;
      }
      return true;
    }).toList();

    // Stats
    final measleCount = allReports.where((r) => r.diseaseType == 'Sởi').length;
    final choleraCount = allReports.where((r) => r.diseaseType == 'Tả').length;
    final dengueCount =
        allReports.where((r) => r.diseaseType == 'Sốt xuất huyết').length;
    final pendingSync = allReports
        .where((r) => r.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final communes = [
      'Tả Phìn',
      'Hầu Thào',
      'San Sả Hồ',
      'Tả Van',
      'Lao Chải',
      'Bản Hồ'
    ];

    // Overall District Stats
    final totalChildren = coverageList.fold<int>(0, (sum, c) => sum + c.total);
    final fullyVaccinated =
        coverageList.fold<int>(0, (sum, c) => sum + c.fully);
    final overallCoverage =
        totalChildren > 0 ? (fullyVaccinated / totalChildren * 100) : 0.0;

    return Column(
      children: [
        // TabBar Header
        Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9E7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.crisis_alert_rounded,
                          color: Color(0xFFB42318), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeTab == 0
                                ? 'Bản đồ cảnh báo dịch tễ'
                                : 'Thống kê phủ Vaccine',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: gray900),
                          ),
                          Text(
                            _activeTab == 0
                                ? 'Giám sát ca bệnh nghi ngờ báo cáo từ cán bộ y tế thực địa.'
                                : 'Tỷ lệ trẻ được tiêm chủng đầy đủ theo từng địa bàn xã.',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: primaryBlue,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: primaryBlue,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                        child: Text('Sơ đồ vùng dịch',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Tab(
                        child: Text('Tỷ lệ bao phủ vắc-xin',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),

        // Main Tab Content View
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_activeTab == 0) ...[
                // TAB 1: Epidemic Warning Map
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        title: 'Tổng ca nghi ngờ',
                        value: '${allReports.length}',
                        subText: pendingSync > 0
                            ? '$pendingSync ca chờ đồng bộ'
                            : 'Dữ liệu thời gian thực',
                        icon: Icons.coronavirus_rounded,
                        color: const Color(0xFFB42318),
                        bgColor: const Color(0xFFFFE9E7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'Ca Sởi',
                        value: '$measleCount',
                        subText: 'Cần theo dõi bùng phát',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'Ca Tả',
                        value: '$choleraCount',
                        subText: 'Sát sao nguồn nước',
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
                        subText: 'Diệt bọ gậy khu dân cư',
                        icon: Icons.bug_report_rounded,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Filters
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined,
                            color: Colors.black54),
                        const SizedBox(width: 8),
                        const Text('Lọc loại bệnh: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
                          children: _diseases.map((d) {
                            final isSelected = _selectedDisease == d;
                            return ChoiceChip(
                              label: Text(d),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedDisease = d);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                        if (_selectedCommune != null)
                          ActionChip(
                            avatar: const Icon(Icons.clear_rounded, size: 14),
                            label: Text('Xã $_selectedCommune'),
                            onPressed: () =>
                                setState(() => _selectedCommune = null),
                            backgroundColor: const Color(0xFFFEF3C7),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Grid mapping
                const Text(
                  'Bản đồ khu vực dịch tễ huyện Sa Pa',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhấp vào từng Xã trên bản đồ để xem chi tiết danh sách ca bệnh và cập nhật trạng thái khoanh vùng.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: communes.length,
                  itemBuilder: (context, index) {
                    final communeName = communes[index];
                    final communeReports = allReports
                        .where((r) => r.commune == communeName)
                        .toList();
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

                // Reports list
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Danh sách ca bệnh báo cáo (${filteredReports.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const Divider(height: 1),
                      if (filteredReports.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Không phát hiện ca bệnh nghi ngờ nào phù hợp bộ lọc.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReports.length,
                          separatorBuilder: (context, i) =>
                              const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            return _DiseaseReportItem(
                                report: filteredReports[idx], store: store);
                          },
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // TAB 2: Vaccine Coverage Statistics & charts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Circle Card
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text('TỶ LỆ PHỦ TOÀN HUYỆN SA PA',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey)),
                              const SizedBox(height: 18),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 120,
                                    width: 120,
                                    child: CircularProgressIndicator(
                                      value: overallCoverage / 100,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.grey.shade100,
                                      color: _statusColor(overallCoverage),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${overallCoverage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$fullyVaccinated/$totalChildren trẻ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                overallCoverage >= 80
                                    ? 'Đạt chỉ tiêu tiêm chủng mở rộng'
                                    : 'Cần tăng cường các buổi tiêm chủng lưu động',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: overallCoverage >= 80
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Bar Comparison Card
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SO SÁNH TỶ LỆ BAO PHỦ GIỮA CÁC XÃ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey)),
                              const SizedBox(height: 18),
                              ...coverageList.map((item) {
                                final color = _statusColor(item.coverage);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: 80,
                                          child: Text(item.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: item.coverage / 100,
                                            minHeight: 10,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        '${item.coverage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: color),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Data Table Grid
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Chi tiết số liệu tiêm chủng',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Nhấp vào từng hàng để xem biểu đồ chi tiết từng loại vaccine phòng bệnh của xã.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(
                                label: Text('Xã',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Tổng trẻ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                numeric: true),
                            DataColumn(
                                label: Text('Đã tiêm đủ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                numeric: true),
                            DataColumn(
                                label: Text('Còn thiếu',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                numeric: true),
                            DataColumn(
                                label: Text('Tỷ lệ phủ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Mức ưu tiên',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: coverageList.map((item) {
                            final color = _statusColor(item.coverage);
                            final priority = item.coverage < 60
                                ? 'Rất cao'
                                : item.coverage < 80
                                    ? 'Cần theo dõi'
                                    : 'Ổn định';
                            return DataRow(
                              onSelectChanged: (_) =>
                                  _showCoverageDetail(context, item),
                              cells: [
                                DataCell(Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                                DataCell(Text('${item.total}')),
                                DataCell(Text('${item.fully}')),
                                DataCell(Text('${item.missing}')),
                                DataCell(Text(
                                    '${item.coverage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color))),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(priority,
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subText,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
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
    final activeCount = reports.where((r) => r.status != 'Đã khỏi').length;
    final color = activeCount > 2
        ? Colors.red
        : (activeCount > 0 ? Colors.orange : Colors.green);
    final statusText = activeCount > 2
        ? 'BÁO ĐỘNG ĐỎ'
        : (activeCount > 0 ? 'CẢNH BÁO' : 'BÌNH THƯỜNG');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  'Xã $communeName',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              activeCount > 0 ? '$activeCount ca dịch' : 'An toàn dịch tễ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      activeCount > 0 ? Colors.black87 : Colors.green.shade800),
            ),
            const SizedBox(height: 2),
            Text(
              activeCount > 0
                  ? 'Phát hiện ca bệnh hoạt động'
                  : 'Không có ca bệnh nghi ngờ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseReportItem extends StatelessWidget {
  const _DiseaseReportItem({required this.report, required this.store});

  final DiseaseReport report;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final isPending = report.syncStatus == VaccinationSyncStatus.pending;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.coronavirus_rounded,
                color: Color(0xFFB42318), size: 22),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9E7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.diseaseType,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB42318),
                            fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('Chờ đồng bộ',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8A5D00),
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Địa bàn: ${report.village}, Xã ${report.commune} • Khai báo bởi: ${report.reportedBy} (${formatDate(report.reportedAt)})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Triệu chứng: ${report.symptoms}',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                if ((report.notes ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Xử lý: ${report.notes}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          DropdownButton<String>(
            value: report.status,
            underline: const SizedBox(),
            items: const [
              'Nghi ngờ',
              'Đã xác minh',
              'Đã khoanh vùng',
              'Đã khỏi'
            ]
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold))))
                .toList(),
            onChanged: (newVal) async {
              if (newVal != null) {
                await store.updateDiseaseReportStatus(report.id, newVal);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Đã cập nhật trạng thái ca bệnh thành "$newVal"'),
                    backgroundColor: Colors.blue.shade700,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _VaccineProgressRow extends StatelessWidget {
  const _VaccineProgressRow(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13))),
              Text('$value%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
