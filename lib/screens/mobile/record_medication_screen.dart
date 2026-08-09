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

    if (_medicationSchedule == null && store.medicationSchedules.isNotEmpty) {
      _medicationSchedule = store.medicationSchedules.first;
      _dosageController.text = _medicationSchedule!.defaultDosage;
    }

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.blueAccent, fontSize: 15)),
        ),
        title: const Text('Ghi nhận thuốc', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Lưu', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Lưu bản ghi (Lưu tạm Offline)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top banner child info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('👉 ', style: TextStyle(fontSize: 16)),
                  const Text(
                    'Trẻ uống: ',
                    style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    child.fullName,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            DropdownButtonFormField<MedicationSchedule>(
              value: _medicationSchedule,
              decoration: const InputDecoration(labelText: 'Loại Vitamin / Dược chất bổ sung *'),
              items: store.medicationSchedules
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text('${item.medicationName} (${item.recommendedAge})'),
                      ))
                  .toList(),
              onChanged: _onScheduleChanged,
              validator: (v) => v == null ? 'Vui lòng chọn thuốc uống' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Liều lượng được chỉ định *'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập liều dùng' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _staffController,
              decoration: const InputDecoration(labelText: 'Cán bộ phụ trách cho uống *'),
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
                decoration: const InputDecoration(labelText: 'Ngày uống *'),
                child: Text(formatDate(_administeredAt)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú lâm sàng',
                alignLabelWithHint: true,
                hintText: 'Bé khỏe mạnh, uống tốt...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

