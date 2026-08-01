import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
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
  final _tempController = TextEditingController(text: '4.5');
  final _reactionNotesController = TextEditingController();
  VaccineSchedule? _schedule;
  DateTime _administeredAt = DateTime.now();
  ReactionSeverity _reactionSeverity = ReactionSeverity.none;

  @override
  void dispose() {
    _lotController.dispose();
    _tempController.dispose();
    _reactionNotesController.dispose();
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

  /// Cảnh báo nếu nhiệt độ bảo quản ngoài chuỗi lạnh 2–8°C (B4).
  Future<bool> _confirmColdChain() async {
    final temp = double.tryParse(_tempController.text.trim());
    if (temp == null) return true; // Không nhập → bỏ qua
    if (temp >= 2.0 && temp <= 8.0) return true; // Hợp lệ

    final warning = temp < 2.0
        ? 'Nhiệt độ ${temp.toStringAsFixed(1)}°C quá thấp – vaccine có thể bị đóng băng và mất hiệu lực!'
        : 'Nhiệt độ ${temp.toStringAsFixed(1)}°C quá cao – vaccine có thể bị phân huỷ và mất hiệu lực!';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.thermostat_rounded, color: Color(0xFFB42318), size: 38),
        title: const Text('Cảnh báo chuỗi lạnh'),
        content: Text('$warning\n\nKhoảng an toàn: 2°C – 8°C.\nBạn có chắc muốn tiếp tục tiêm?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Dừng lại')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vẫn tiêm'),
          ),
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

    final coldChainOk = await _confirmColdChain();
    if (!coldChainOk || !mounted) return;

    final temp = double.tryParse(_tempController.text.trim());

    final record = VaccinationRecord(
      id: 'LOCAL-${DateTime.now().microsecondsSinceEpoch}',
      childId: child.id,
      vaccineId: _schedule!.id,
      vaccineName: _schedule!.vaccineName,
      doseNumber: _schedule!.doseNumber,
      lotNumber: _lotController.text.trim(),
      administeredBy: store.currentUser.fullName, // B5: Tự động gán y sĩ đăng nhập
      reactions: _reactionNotesController.text.trim().isEmpty ? null : _reactionNotesController.text.trim(),
      reactionSeverity: _reactionSeverity,
      storageTemperature: temp,
      administeredAt: _administeredAt,
      syncStatus: SyncStatus.pending,
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
            // ── Thông tin trẻ ──
            Card(
              color: softGreen,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.child_care_rounded, color: primaryGreen)),
                title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Lịch đề xuất: ${child.nextVaccine}'),
              ),
            ),
            const SizedBox(height: 18),

            // ── Chọn vaccine ──
            DropdownButtonFormField<VaccineSchedule>(
              initialValue: _schedule,
              decoration: const InputDecoration(labelText: 'Vaccine đang tiêm *', prefixIcon: Icon(Icons.vaccines_outlined)),
              items: demoSchedules.map((schedule) => DropdownMenuItem(value: schedule, child: Text(schedule.displayName))).toList(),
              onChanged: (value) => setState(() => _schedule = value),
              validator: (value) => value == null ? 'Vui lòng chọn vaccine' : null,
            ),
            const SizedBox(height: 14),

            // ── Số lô ──
            TextFormField(
              controller: _lotController,
              decoration: const InputDecoration(labelText: 'Số lô vaccine *', prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập số lô' : null,
            ),
            const SizedBox(height: 14),

            // ── B4: Nhiệt độ bảo quản ──
            TextFormField(
              controller: _tempController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Nhiệt độ bảo quản (°C)',
                prefixIcon: const Icon(Icons.thermostat_outlined),
                suffixText: '°C',
                helperText: 'Chuỗi lạnh hợp lệ: 2°C – 8°C',
                helperStyle: TextStyle(
                  color: _isTempWarning ? const Color(0xFFB42318) : Colors.black38,
                  fontWeight: _isTempWarning ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            // Hiển thị cảnh báo trực quan nếu nhiệt độ ngoài ngưỡng
            if (_isTempWarning)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Color(0xFFB42318), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_tempWarningText, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // ── B5: Cán bộ tiêm – tự động từ user đăng nhập ──
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Cán bộ tiêm',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(store.currentUser.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Tự động', style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Ngày tiêm ──
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
            const SizedBox(height: 20),

            // ── B6: Phản ứng sau tiêm – CheckboxListTile chuẩn y tế ──
            Text('Phản ứng sau tiêm', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _ReactionOption(
                    title: 'Không phản ứng',
                    subtitle: 'Trẻ hoàn toàn bình thường sau tiêm',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF18794E),
                    isSelected: _reactionSeverity == ReactionSeverity.none,
                    onTap: () => setState(() => _reactionSeverity = ReactionSeverity.none),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ReactionOption(
                    title: 'Nhẹ',
                    subtitle: 'Sốt < 38.5°C, sưng đỏ < 2cm, quấy nhẹ',
                    icon: Icons.sentiment_neutral,
                    color: const Color(0xFF8A5D00),
                    isSelected: _reactionSeverity == ReactionSeverity.mild,
                    onTap: () => setState(() => _reactionSeverity = ReactionSeverity.mild),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ReactionOption(
                    title: 'Trung bình',
                    subtitle: 'Sốt 38.5–39.5°C, quấy khóc kéo dài, sưng > 2cm',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE67E22),
                    isSelected: _reactionSeverity == ReactionSeverity.moderate,
                    onTap: () => setState(() => _reactionSeverity = ReactionSeverity.moderate),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ReactionOption(
                    title: 'Nặng – Cần chuyển viện',
                    subtitle: 'Sốt > 39.5°C, co giật, khó thở, sốc phản vệ',
                    icon: Icons.emergency_rounded,
                    color: const Color(0xFFB42318),
                    isSelected: _reactionSeverity == ReactionSeverity.severe,
                    onTap: () => setState(() => _reactionSeverity = ReactionSeverity.severe),
                  ),
                ],
              ),
            ),
            if (_reactionSeverity == ReactionSeverity.severe) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: Color(0xFFB42318)),
                    SizedBox(width: 8),
                    Expanded(child: Text('CẢNH BÁO: Phản ứng NẶNG. Chuyển trẻ đến cơ sở y tế gần nhất ngay lập tức!', style: TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _reactionNotesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú chi tiết phản ứng (nếu có)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 18),

            // ── Offline notice ──
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

  // Helpers nhiệt độ
  bool get _isTempWarning {
    final temp = double.tryParse(_tempController.text.trim());
    if (temp == null) return false;
    return temp < 2.0 || temp > 8.0;
  }

  String get _tempWarningText {
    final temp = double.tryParse(_tempController.text.trim());
    if (temp == null) return '';
    if (temp < 2.0) return 'Nhiệt độ quá thấp (${temp.toStringAsFixed(1)}°C) – Vaccine có thể bị đóng băng!';
    if (temp > 8.0) return 'Nhiệt độ quá cao (${temp.toStringAsFixed(1)}°C) – Vaccine có thể bị phân huỷ!';
    return '';
  }
}

/// Widget chọn mức độ phản ứng – thay thế TextField tự do (B6).
class _ReactionOption extends StatelessWidget {
  const _ReactionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.black38,
              size: 22,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? color : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isSelected ? color.withValues(alpha: 0.7) : Colors.black38)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
