import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class RecordMedicationScreen extends StatefulWidget {
  const RecordMedicationScreen({super.key, required this.childId});

  final String childId;

  @override
  State<RecordMedicationScreen> createState() => _RecordMedicationScreenState();
}

class _RecordMedicationScreenState extends State<RecordMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dosageController = TextEditingController();
  late final TextEditingController _staffController;
  final _notesController = TextEditingController();
  MedicationSchedule? _medicationSchedule;
  DateTime _administeredAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _staffController = TextEditingController();
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _staffController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onScheduleChanged(MedicationSchedule? value) {
    setState(() {
      _medicationSchedule = value;
      if (value != null) {
        _dosageController.text = value.defaultDosage;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _medicationSchedule == null) return;

    final store = AppScope.of(context);
    final child = store.children.firstWhere((item) => item.id == widget.childId);

    final record = MedicationRecord(
      id: 'LOCAL-MED-${DateTime.now().microsecondsSinceEpoch}',
      childId: child.id,
      medicationId: _medicationSchedule!.id,
      medicationName: _medicationSchedule!.medicationName,
      dosage: _dosageController.text.trim(),
      administeredBy: _staffController.text.trim(),
      administeredAt: _administeredAt,
      syncStatus: VaccinationSyncStatus.pending,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    store.addMedication(child.id, record);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã ghi nhận cho uống thuốc ngoại tuyến. Đang chờ đồng bộ.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final child = store.children.firstWhere((item) => item.id == widget.childId);
    if (_staffController.text.isEmpty && store.currentUser != null) {
      _staffController.text = store.currentUser!.fullName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi nhận uống thuốc')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu bản ghi ngoại tuyến'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: softGreen,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.medication_rounded, color: primaryGreen),
                ),
                title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${child.village}, ${child.commune}'),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<MedicationSchedule>(
              initialValue: _medicationSchedule,
              decoration: const InputDecoration(
                labelText: 'Thuốc / Bổ sung đường uống *',
                prefixIcon: Icon(Icons.medication_liquid_outlined),
              ),
              items: store.medicationSchedules
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text('${item.medicationName} (${item.recommendedAge})'),
                      ))
                  .toList(),
              onChanged: _onScheduleChanged,
              validator: (v) => v == null ? 'Vui lòng chọn thuốc uống' : null,
            ),
            if (_medicationSchedule != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Mô tả: ${_medicationSchedule!.description}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Liều dùng *',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập liều dùng' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _staffController,
              decoration: const InputDecoration(
                labelText: 'Cán bộ thực hiện *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên cán bộ' : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final value = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: _administeredAt,
                );
                if (value != null) setState(() => _administeredAt = value);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày uống',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(formatDate(_administeredAt)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / Phản ứng / Dặn dò phụ huynh',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Color(0xFF8A5D00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Bản ghi uống thuốc được lưu cục bộ với trạng thái pending. Hãy thực hiện đồng bộ khi có kết nối mạng.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
