import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class DiseaseReportScreen extends StatefulWidget {
  const DiseaseReportScreen({super.key});

  @override
  State<DiseaseReportScreen> createState() => _DiseaseReportScreenState();
}

class _DiseaseReportScreenState extends State<DiseaseReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _notesController = TextEditingController();

  DiseaseType? _diseaseType;
  String _patientGender = 'Nam';
  String? _selectedCommune;
  String? _selectedVillage;
  DiseaseUrgency _urgency = DiseaseUrgency.routine;
  DateTime _onsetDate = DateTime.now();
  final Set<String> _selectedSymptoms = {};
  String? _relatedChildId;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDiseaseChanged(DiseaseType? value) {
    setState(() {
      _diseaseType = value;
      _selectedSymptoms.clear();
    });
  }

  void _onCommuneChanged(String? value) {
    setState(() {
      _selectedCommune = value;
      _selectedVillage = null;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _diseaseType == null) return;
    if (_selectedCommune == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn xã và thôn/bản.'), backgroundColor: Color(0xFFB42318)),
      );
      return;
    }
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 triệu chứng.'), backgroundColor: Color(0xFFB42318)),
      );
      return;
    }

    final store = AppScope.of(context);
    final report = DiseaseReport(
      id: 'DR-LOCAL-${DateTime.now().microsecondsSinceEpoch}',
      diseaseTypeId: _diseaseType!.id,
      diseaseName: _diseaseType!.name,
      patientName: _patientNameController.text.trim(),
      patientAge: int.tryParse(_patientAgeController.text.trim()) ?? 0,
      patientGender: _patientGender,
      village: _selectedVillage!,
      commune: _selectedCommune!,
      symptoms: _selectedSymptoms.toList(),
      onsetDate: _onsetDate,
      reportedBy: store.currentUser.fullName,
      reportedAt: DateTime.now(),
      urgency: _urgency,
      syncStatus: SyncStatus.pending,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      relatedChildId: _relatedChildId,
    );

    store.addDiseaseReport(report);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu báo cáo dịch tễ ngoại tuyến. Đang chờ đồng bộ.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final villages = _selectedCommune != null ? (kVillagesByCommune[_selectedCommune] ?? <String>[]) : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Khai báo ca nghi nhiễm')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.report_outlined),
          label: const Text('Gửi báo cáo dịch tễ'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Thông tin cán bộ báo cáo ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.badge_rounded, color: primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cán bộ báo cáo', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        Text(store.currentUser.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('Phụ trách: ${store.currentUser.assignedCommune}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Chọn loại bệnh ──
            Text('Loại bệnh nghi ngờ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<DiseaseType>(
              initialValue: _diseaseType,
              decoration: const InputDecoration(
                labelText: 'Bệnh truyền nhiễm *',
                prefixIcon: Icon(Icons.coronavirus_outlined),
              ),
              items: demoDiseaseTypes.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
              onChanged: _onDiseaseChanged,
              validator: (v) => v == null ? 'Vui lòng chọn loại bệnh' : null,
            ),
            if (_diseaseType != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Thời gian ủ bệnh: ${_diseaseType!.incubationDays}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Mức độ khẩn cấp ──
            Text('Mức độ khẩn cấp', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SegmentedButton<DiseaseUrgency>(
              segments: const [
                ButtonSegment(value: DiseaseUrgency.routine, label: Text('Thường', style: TextStyle(fontSize: 12)), icon: Icon(Icons.check_circle_outline, size: 18)),
                ButtonSegment(value: DiseaseUrgency.elevated, label: Text('Nâng cao', style: TextStyle(fontSize: 12)), icon: Icon(Icons.warning_amber, size: 18)),
                ButtonSegment(value: DiseaseUrgency.emergency, label: Text('Khẩn cấp', style: TextStyle(fontSize: 12)), icon: Icon(Icons.emergency, size: 18)),
              ],
              selected: {_urgency},
              onSelectionChanged: (set) => setState(() => _urgency = set.first),
            ),
            if (_urgency == DiseaseUrgency.emergency) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Color(0xFFB42318)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Ca KHẨN CẤP sẽ được ưu tiên xử lý ngay khi đồng bộ lên hệ thống huyện.', style: TextStyle(color: Color(0xFFB42318), fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Thông tin bệnh nhân ──
            Text('Thông tin bệnh nhân', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _patientNameController,
              decoration: const InputDecoration(labelText: 'Họ tên bệnh nhân *', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên bệnh nhân' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _patientAgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tuổi (tháng tuổi) *', prefixIcon: Icon(Icons.cake_outlined)),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Nhập tuổi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _patientGender,
                    decoration: const InputDecoration(labelText: 'Giới tính', prefixIcon: Icon(Icons.wc_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _patientGender = v); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Liên kết với trẻ trong sổ (tuỳ chọn) ──
            DropdownButtonFormField<String>(
              initialValue: _relatedChildId,
              decoration: const InputDecoration(
                labelText: 'Liên kết hồ sơ trẻ (nếu có)',
                prefixIcon: Icon(Icons.child_care_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('— Không liên kết —')),
                ...store.children.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.fullName} (${c.village})'))),
              ],
              onChanged: (v) => setState(() => _relatedChildId = v),
            ),
            const SizedBox(height: 20),

            // ── Địa điểm phát hiện ──
            Text('Địa điểm phát hiện', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCommune,
                    decoration: const InputDecoration(labelText: 'Xã *', prefixIcon: Icon(Icons.location_city_outlined)),
                    items: kCommuneList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: _onCommuneChanged,
                    validator: (v) => v == null ? 'Chọn xã' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('village-$_selectedCommune'),
                    initialValue: _selectedVillage,
                    decoration: const InputDecoration(labelText: 'Thôn/Bản *', prefixIcon: Icon(Icons.home_outlined)),
                    items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _selectedVillage = v),
                    validator: (v) => v == null ? 'Chọn thôn' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Ngày khởi phát ──
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                  initialDate: _onsetDate,
                );
                if (picked != null) setState(() => _onsetDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ngày khởi phát triệu chứng', prefixIcon: Icon(Icons.calendar_month_outlined)),
                child: Text(formatDate(_onsetDate)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Triệu chứng (checkbox) ──
            if (_diseaseType != null) ...[
              Text('Triệu chứng quan sát được *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: _diseaseType!.symptoms.map((symptom) {
                    return CheckboxListTile(
                      title: Text(symptom, style: const TextStyle(fontSize: 14)),
                      value: _selectedSymptoms.contains(symptom),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── Ghi chú ──
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / Biện pháp đã xử lý',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 18),

            // ── Cảnh báo offline ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Color(0xFF8A5D00)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Báo cáo được lưu cục bộ và đồng bộ lên Trung tâm Y tế huyện khi có kết nối mạng.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
