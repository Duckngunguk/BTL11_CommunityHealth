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
      backgroundColor: gray100,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 48, bottom: 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Giám sát dịch bệnh',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: gray900),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AddDiseaseReportScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: redLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, color: accentRed, size: 14),
                              SizedBox(width: 4),
                              Text('Khai báo mới', style: TextStyle(color: accentRed, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: gray200),
              ],
            ),
          ),

          // Chip filter
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: _diseases.map((disease) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: disease,
                      selected: _selectedFilter == disease,
                      onTap: () => setState(() => _selectedFilter = disease),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(height: 1, color: gray200),

          // List
          Expanded(
            child: reports.isEmpty
                ? const EmptyState(
                    title: 'Không có ca bệnh nghi ngờ',
                    description: 'Chưa có báo cáo dịch bệnh nào cho loại bệnh này.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _DiseaseReportCard(report: reports[index]),
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
    final isConfirmed = report.status == 'Đã xác minh';
    final Color borderColor = isConfirmed ? accentRed : accentYellow;
    final Color pillBg = isConfirmed ? redLight : yellowLight;
    final Color pillFg = isConfirmed ? accentRed : accentYellow;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gray200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color stripe
              Container(width: 4, color: borderColor),
              // Body
              Expanded(
                child: Padding(padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nghi ổ dịch ${report.diseaseType}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: gray900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${report.village} · ${formatDate(report.reportedAt)} · ${report.reportedBy}',
                              style: const TextStyle(fontSize: 11.5, color: gray500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(report.status, style: TextStyle(color: pillFg, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddDiseaseReportScreen extends StatefulWidget {
  const AddDiseaseReportScreen({super.key});

  @override
  State<AddDiseaseReportScreen> createState() => _AddDiseaseReportScreenState();
}

class _AddDiseaseReportScreenState extends State<AddDiseaseReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseCountController = TextEditingController(text: '1');
  final _symptomsController = TextEditingController();

  String _selectedVillage = 'Bản Sapa';
  String _diseaseType = 'Sởi';
  final _diseases = ['Sởi', 'Tả', 'Sốt xuất huyết', 'Thuỷ đậu', 'Bệnh Dại', 'Khác'];

  @override
  void dispose() {
    _caseCountController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.of(context);

    final isOnline = store.isOnline;
    final newReport = DiseaseReport(
      id: 'RPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      patientName: 'Ổ dịch ${formatDate(DateTime.now())}',
      diseaseType: _diseaseType,
      village: _selectedVillage,
      commune: 'Tả Phìn',
      district: 'Sa Pa',
      reportedAt: DateTime.now(),
      reportedBy: store.currentUser?.fullName ?? 'Y sĩ Lê Thu',
      symptoms: _symptomsController.text.trim(),
      syncStatus: isOnline ? VaccinationSyncStatus.synced : VaccinationSyncStatus.pending,
      status: 'Nghi ngờ',
      severity: DiseaseSeverity.moderate,
      notes: 'Số ca ghi nhận: ${_caseCountController.text}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gray100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left_rounded, color: primaryBlue, size: 22),
                        Text('Danh sách', style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Báo cáo ca dịch',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: gray900),
                  ),
                ),
                TextButton(
                  onPressed: _submit,
                  child: const Text('Gửi', style: TextStyle(color: accentRed, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: gray200)),
        ),
        child: SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Gửi báo cáo khẩn cấp về xã',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _diseaseType,
              decoration: const InputDecoration(labelText: 'Loại bệnh truyền nhiễm nghi ngờ *'),
              items: _diseases.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _diseaseType = val);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _caseCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số ca mắc nghi ngờ ghi nhận *'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập số ca' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedVillage,
              decoration: const InputDecoration(labelText: 'Ổ dịch xảy ra tại bản nào *'),
              items: const [
                DropdownMenuItem(value: 'Bản Nậm Lùng', child: Text('Bản Nậm Lùng')),
                DropdownMenuItem(value: 'Bản Sapa', child: Text('Bản Sapa')),
                DropdownMenuItem(value: 'Bản Cát Cát', child: Text('Bản Cát Cát')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedVillage = val);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _symptomsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Triệu chứng / Ghi chú thực tế *',
                alignLabelWithHint: true,
                hintText: 'Mô tả các triệu chứng lâm sàng quan sát được...',
              ),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng mô tả triệu chứng thực tế' : null,
            ),
          ],
        ),
      ),
    );
  }
}

