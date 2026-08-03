import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class RecordVaccinationScreen extends StatefulWidget {
  const RecordVaccinationScreen({super.key, required this.childId});

  final String childId;

  @override
  State<RecordVaccinationScreen> createState() => _RecordVaccinationScreenState();
}

class _RecordVaccinationScreenState extends State<RecordVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lotController = TextEditingController(text: 'DPT2607-A12');
  final _staffController = TextEditingController(text: 'Y sĩ Lê Thu');
  final _reactionController = TextEditingController();
  VaccineSchedule? _schedule;
  DateTime _administeredAt = DateTime.now();

  @override
  void dispose() {
    _lotController.dispose();
    _staffController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  Future<bool> _confirmScheduleMismatch(String recommended) async {
    if (_schedule == null || recommended.contains(_schedule!.displayName)) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318), size: 38),
        title: const Text('Tiêm không đúng lịch đề xuất'),
        content: Text('Trẻ này nên tiêm $recommended trước. Bạn có chắc muốn ghi nhận ${_schedule!.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Kiểm tra lại')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vẫn tiếp tục')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _schedule == null) return;
    final store = AppScope.of(context);
    final child = store.children.firstWhere((item) => item.id == widget.childId);
    final confirmed = await _confirmScheduleMismatch(child.nextVaccine);
    if (!confirmed || !mounted) return;

    final record = VaccinationRecord(
      id: 'LOCAL-${DateTime.now().microsecondsSinceEpoch}',
      childId: child.id,
      vaccineId: _schedule!.id,
      vaccineName: _schedule!.vaccineName,
      doseNumber: _schedule!.doseNumber,
      lotNumber: _lotController.text.trim(),
      administeredBy: _staffController.text.trim(),
      reactions: _reactionController.text.trim().isEmpty ? null : _reactionController.text.trim(),
      administeredAt: _administeredAt,
      syncStatus: VaccinationSyncStatus.pending,
    );

    store.addVaccination(child.id, record);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu ngoại tuyến. Bản ghi đang chờ đồng bộ.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final child = store.children.firstWhere((item) => item.id == widget.childId);

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi nhận mũi tiêm')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Lưu bản ghi ngoại tuyến')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: softGreen,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.child_care_rounded, color: primaryGreen)),
                title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Lịch đề xuất: ${child.nextVaccine}'),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<VaccineSchedule>(
              initialValue: _schedule,
              decoration: const InputDecoration(labelText: 'Vaccine đang tiêm *', prefixIcon: Icon(Icons.vaccines_outlined)),
              items: store.vaccineSchedules.map((schedule) => DropdownMenuItem(value: schedule, child: Text(schedule.displayName))).toList(),
              onChanged: (value) => setState(() => _schedule = value),
              validator: (value) => value == null ? 'Vui lòng chọn vaccine' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lotController,
              decoration: const InputDecoration(labelText: 'Số lô vaccine *', prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập số lô' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _staffController,
              decoration: const InputDecoration(labelText: 'Cán bộ tiêm *', prefixIcon: Icon(Icons.badge_outlined)),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập tên cán bộ' : null,
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
                decoration: const InputDecoration(labelText: 'Ngày tiêm', prefixIcon: Icon(Icons.calendar_month_outlined)),
                child: Text(formatDate(_administeredAt)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reactionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ghi chú phản ứng sau tiêm', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Color(0xFF8A5D00)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Bản ghi được lưu cục bộ với trạng thái pending. Không tắt ứng dụng trong lúc đang lưu.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
