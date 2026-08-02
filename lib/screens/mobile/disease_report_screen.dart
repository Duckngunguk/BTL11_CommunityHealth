import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class DiseaseReportScreen extends StatefulWidget {
  const DiseaseReportScreen({super.key});

  @override
  State<DiseaseReportScreen> createState() => _DiseaseReportScreenState();
}

class _DiseaseReportScreenState extends State<DiseaseReportScreen> {
  String _selectedFilter = 'Tất cả';

  final _diseases = ['Tất cả', 'Sởi', 'Tả', 'Sốt xuất huyết', 'Thuỷ đậu', 'Khác'];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final reports = store.diseaseReports.where((r) {
      if (_selectedFilter == 'Tất cả') return true;
      return r.diseaseType == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318)),
            SizedBox(width: 8),
            Text('Giám sát dịch bệnh', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: store.isOnline ? 'Đang có mạng' : 'Đang ngoại tuyến',
              child: CircleAvatar(
                backgroundColor: store.isOnline ? const Color(0xFFE5F5EC) : const Color(0xFFFFF3CD),
                child: Icon(
                  store.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: store.isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Hướng dẫn
          _OfflineBanner(isOnline: store.isOnline),
          const SizedBox(height: 16),

          // Bộ lọc loại bệnh
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _diseases.map((disease) {
                final isSelected = _selectedFilter == disease;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(disease),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = disease);
                    },
                    selectedColor: const Color(0xFFE5F5EC),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF18794E) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề & Nút báo cáo mới
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách ca bệnh (${reports.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              FilledButton.icon(
                onPressed: () => _showAddReportDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Báo ca bệnh'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (reports.isEmpty)
            const EmptyState(
              title: 'Không có ca bệnh nghi ngờ',
              description: 'Chưa có báo cáo dịch bệnh nào cho loại bệnh này.',
            )
          else
            ...reports.map((report) => _DiseaseReportCard(report: report)),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReportDialog(context),
        backgroundColor: const Color(0xFFB42318),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text('Khai báo ca bệnh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddReportDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddDiseaseReportSheet(),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFE5F5EC) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? const Color(0xFFA3E2C3) : const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Hệ thống trực tuyến' : 'Đang hoạt động ngoại tuyến (Offline)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Báo cáo ca bệnh sẽ được gửi lên hệ thống và hiển thị ngay trên Bản đồ cảnh báo dịch tễ.'
                      : 'Báo cáo sẽ được lưu cục bộ trên máy và tự động đồng bộ khi cán bộ có kết nối mạng.',
                  style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.black87),
                ),
              ],
            ),
          ),
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
    final isPending = report.syncStatus == VaccinationSyncStatus.pending;
    final (statusBg, statusColor) = switch (report.status) {
      'Nghi ngờ' => (const Color(0xFFFFE9E7), const Color(0xFFB42318)),
      'Đã xác minh' => (const Color(0xFFFFF3CD), const Color(0xFF8A5D00)),
      'Đã khoanh vùng' => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      _ => (const Color(0xFFE5F5EC), const Color(0xFF18794E)),
    };

    final (severityLabel, severityColor) = switch (report.severity) {
      DiseaseSeverity.severe => ('Nặng (Cấp cứu)', const Color(0xFFB42318)),
      DiseaseSeverity.moderate => ('Trung bình', const Color(0xFF8A5D00)),
      DiseaseSeverity.mild => ('Nhẹ', const Color(0xFF18794E)),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.coronavirus_rounded, size: 16, color: Color(0xFFB42318)),
                      const SizedBox(width: 4),
                      Text(
                        report.diseaseType,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB42318), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? const Color(0xFFFFF3CD) : const Color(0xFFE5F5EC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isPending ? 'Chờ đồng bộ' : 'Đã đồng bộ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPending ? const Color(0xFF8A5D00) : const Color(0xFF18794E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.patientName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  '${report.village}, ${report.commune}, ${report.district}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        const TextSpan(text: 'Triệu chứng: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: report.symptoms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Mức độ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                      Text(severityLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: severityColor)),
                      const Spacer(),
                      Text('Báo lúc: ${formatDate(report.reportedAt)}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
            if ((report.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ghi chú xử lý: ${report.notes}',
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDiseaseReportSheet extends StatefulWidget {
  const _AddDiseaseReportSheet();

  @override
  State<_AddDiseaseReportSheet> createState() => _AddDiseaseReportSheetState();
}

class _AddDiseaseReportSheetState extends State<_AddDiseaseReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController(text: 'Bản Tả Phìn 1');
  final _communeController = TextEditingController(text: 'Tả Phìn');
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();

  String _diseaseType = 'Sởi';
  DiseaseSeverity _severity = DiseaseSeverity.moderate;
  ChildProfile? _selectedChild;

  final _diseases = ['Sởi', 'Tả', 'Sốt xuất huyết', 'Thuỷ đậu', 'Bệnh Dại', 'Cúm A/H5N1', 'Khác'];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.coronavirus_rounded, color: Color(0xFFB42318)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khai báo ca bệnh nghi ngờ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Tự động ghi nhận offline khi chưa có mạng',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Chọn từ danh sách trẻ (nếu có)
              DropdownButtonFormField<ChildProfile?>(
                initialValue: _selectedChild,
                decoration: const InputDecoration(
                  labelText: 'Chọn trẻ từ hồ sơ (Không bắt buộc)',
                  prefixIcon: Icon(Icons.child_care_rounded),
                ),
                items: [
                  const DropdownMenuItem<ChildProfile?>(
                    value: null,
                    child: Text('-- Nhập tên bệnh nhân tự do --'),
                  ),
                  ...store.children.map(
                    (child) => DropdownMenuItem<ChildProfile?>(
                      value: child,
                      child: Text('${child.fullName} (${child.village})'),
                    ),
                  ),
                ],
                onChanged: (child) {
                  setState(() {
                    _selectedChild = child;
                    if (child != null) {
                      _nameController.text = child.fullName;
                      _villageController.text = child.village;
                      _communeController.text = child.commune;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // Tên bệnh nhân
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên bệnh nhân *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập tên bệnh nhân' : null,
              ),
              const SizedBox(height: 14),

              // Loại bệnh dịch
              DropdownButtonFormField<String>(
                initialValue: _diseaseType,
                decoration: const InputDecoration(
                  labelText: 'Loại bệnh nghi ngờ *',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                ),
                items: _diseases
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _diseaseType = val);
                },
              ),
              const SizedBox(height: 14),

              // Địa chỉ: Thôn/Bản & Xã
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _villageController,
                      decoration: const InputDecoration(
                        labelText: 'Thôn / Bản *',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _communeController,
                      decoration: const InputDecoration(
                        labelText: 'Xã / Phường *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Triệu chứng lâm sàng
              TextFormField(
                controller: _symptomsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Triệu chứng lâm sàng quan sát *',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  hintText: 'Ví dụ: Sốt 39°C, phát ban đỏ, tiêu chảy...',
                ),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng mô tả triệu chứng' : null,
              ),
              const SizedBox(height: 14),

              // Mức độ nghiêm trọng
              DropdownButtonFormField<DiseaseSeverity>(
                initialValue: _severity,
                decoration: const InputDecoration(
                  labelText: 'Mức độ nghiêm trọng',
                  prefixIcon: Icon(Icons.speed_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: DiseaseSeverity.mild, child: Text('Nhẹ (Theo dõi tại nhà)')),
                  DropdownMenuItem(value: DiseaseSeverity.moderate, child: Text('Trung bình (Cách ly y tế)')),
                  DropdownMenuItem(value: DiseaseSeverity.severe, child: Text('Nặng (Chuyển tuyến khẩn cấp)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _severity = val);
                },
              ),
              const SizedBox(height: 14),

              // Ghi chú xử lý
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Biện pháp xử lý ban đầu',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  hintText: 'Hướng dẫn gia đình cách ly, phát thuốc...',
                ),
              ),
              const SizedBox(height: 20),

              // Nút lưu báo cáo
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final isOnline = store.isOnline;
                    final newReport = DiseaseReport(
                      id: 'RPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      childId: _selectedChild?.id,
                      patientName: _nameController.text.trim(),
                      diseaseType: _diseaseType,
                      village: _villageController.text.trim(),
                      commune: _communeController.text.trim(),
                      district: 'Sa Pa',
                      reportedAt: DateTime.now(),
                      reportedBy: 'Y sĩ Lê Thu',
                      symptoms: _symptomsController.text.trim(),
                      syncStatus: isOnline ? VaccinationSyncStatus.synced : VaccinationSyncStatus.pending,
                      status: 'Nghi ngờ',
                      severity: _severity,
                      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                    );

                    store.addDiseaseReport(newReport);
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isOnline
                              ? 'Đã gửi báo cáo ca bệnh "${newReport.diseaseType}" lên hệ thống thành công!'
                              : 'Đã lưu báo cáo offline (Ngoại tuyến). Dữ liệu sẽ tự động đồng bộ khi có mạng.',
                        ),
                        backgroundColor: isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  store.isOnline ? 'Gửi báo cáo ngay' : 'Lưu báo cáo Offline',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
