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
  final _lotController = TextEditingController(text: 'LOT-DPT-2026-03');
  late final TextEditingController _staffController;
  final _reactionController = TextEditingController();
  VaccineSchedule? _schedule;
  DateTime _administeredAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _staffController = TextEditingController();
  }

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
    if (_staffController.text.isEmpty && store.currentUser != null) {
      _staffController.text = store.currentUser!.fullName;
    }

    // Default select child's next recommended vaccine schedule if match
    if (_schedule == null) {
      final recommendedName = child.nextVaccine.split(' - ').first;
      for (final s in store.vaccineSchedules) {
        if (s.displayName.contains(recommendedName)) {
          _schedule = s;
          break;
        }
      }
      _schedule ??= store.vaccineSchedules.first;
    }

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.blueAccent, fontSize: 15)),
        ),
        title: const Text('Ghi nhận tiêm', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
                    'Trẻ thụ hưởng: ',
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

            DropdownButtonFormField<VaccineSchedule>(
              initialValue: _schedule,
              decoration: const InputDecoration(labelText: 'Loại vắc-xin *'),
              items: store.vaccineSchedules.map((schedule) => DropdownMenuItem(value: schedule, child: Text(schedule.displayName))).toList(),
              onChanged: (value) => setState(() => _schedule = value),
              validator: (value) => value == null ? 'Vui lòng chọn vaccine' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lotController,
              decoration: const InputDecoration(labelText: 'Số lô sản xuất (Lot number) *'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập số lô' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _staffController,
              decoration: const InputDecoration(labelText: 'Cán bộ thực hiện tiêm *'),
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
                decoration: const InputDecoration(labelText: 'Ngày tiêm *'),
                child: Text(formatDate(_administeredAt)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reactionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Phản ứng phụ sau tiêm (nếu có)',
                alignLabelWithHint: true,
                hintText: 'Ví dụ: Sốt nhẹ 38.2°C, sưng tấy vết tiêm...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

