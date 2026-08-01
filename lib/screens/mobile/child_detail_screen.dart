import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'child_form_dialog.dart';
import 'record_medication_screen.dart';
import 'record_vaccination_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  int _selectedTab = 0; // 0: Tiêm chủng, 1: Uống thuốc

  void _editChild(ChildProfile child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChildFormScreen(childToEdit: child)),
    );
  }

  Future<void> _deleteChild(ChildProfile child) async {
    final store = AppScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318), size: 36),
        title: const Text('Xóa hồ sơ trẻ'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ của trẻ "${child.fullName}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa hồ sơ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      store.deleteChild(child.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa trẻ "${child.fullName}".')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final childExists = store.children.any((item) => item.id == widget.childId);

    if (!childExists) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ sức khỏe')),
        body: const Center(child: Text('Không tìm thấy thông tin trẻ.')),
      );
    }

    final child = store.children.firstWhere((item) => item.id == widget.childId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ sức khỏe trẻ'),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa hồ sơ',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editChild(child),
          ),
          IconButton(
            tooltip: 'Xóa hồ sơ',
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB42318)),
            onPressed: () => _deleteChild(child),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => RecordVaccinationScreen(childId: child.id)),
                ),
                icon: const Icon(Icons.vaccines_rounded, size: 20),
                label: const Text('Ghi nhận tiêm', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => RecordMedicationScreen(childId: child.id)),
                ),
                icon: const Icon(Icons.medication_rounded, size: 20),
                label: const Text('Ghi nhận thuốc', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: softGreen,
                    child: Text(
                      child.fullName.characters.first,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 7),
                        StatusPill(status: child.status),
                        const SizedBox(height: 12),
                        _InfoLine(icon: Icons.cake_outlined, text: '${formatDate(child.dateOfBirth)} • ${child.gender}'),
                        _InfoLine(icon: Icons.place_outlined, text: '${child.village}, ${child.commune}, ${child.district}'),
                        _InfoLine(icon: Icons.qr_code_rounded, text: child.qrCode),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: child.status == ChildVaccinationStatus.late ? const Color(0xFFFFF0EF) : const Color(0xFFF0F8FF),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    child.status == ChildVaccinationStatus.late ? Icons.warning_amber_rounded : Icons.event_available_rounded,
                    color: child.status == ChildVaccinationStatus.late ? const Color(0xFFB42318) : primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mũi tiêm tiếp theo', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(child.nextVaccine, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(child.lateDays > 0 ? 'Đã trễ ${child.lateDays} ngày' : 'Dự kiến ${formatDate(child.nextDue)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                label: Text('💉 Tiêm chủng (${child.vaccinations.length})'),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('💊 Thuốc uống (${child.medications.length})'),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
          ),
          const SizedBox(height: 16),
          if (_selectedTab == 0) ...[
            const SectionHeader(
              title: 'Lịch sử tiêm chủng',
              subtitle: 'Thông tin tiêm chủng được lưu cục bộ và đồng bộ server.',
            ),
            const SizedBox(height: 12),
            if (child.vaccinations.isEmpty)
              const EmptyState(title: 'Chưa có bản ghi tiêm chủng', description: 'Trẻ chưa có dữ liệu tiêm chủng.')
            else
              ...child.vaccinations.reversed.map((record) => _VaccinationCard(record: record)),
          ] else ...[
            const SectionHeader(
              title: 'Lịch sử uống thuốc',
              subtitle: 'Thông tin cho uống Vitamin A, thuốc tẩy giun và các thuốc dạng uống.',
            ),
            const SizedBox(height: 12),
            if (child.medications.isEmpty)
              const EmptyState(title: 'Chưa có bản ghi thuốc uống', description: 'Trẻ chưa có dữ liệu uống thuốc bổ sung.')
            else
              ...child.medications.reversed.map((record) => _MedicationCard(record: record)),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin phụ huynh', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _InfoLine(icon: Icons.person_outline, text: child.motherName),
                  _InfoLine(icon: Icons.phone_outlined, text: child.motherPhone),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccinationCard extends StatelessWidget {
  const _VaccinationCard({required this.record});

  final VaccinationRecord record;

  String get _reactionLabel => switch (record.reactionSeverity) {
    ReactionSeverity.none => 'Không phản ứng',
    ReactionSeverity.mild => 'Phản ứng nhẹ',
    ReactionSeverity.moderate => 'Phản ứng trung bình',
    ReactionSeverity.severe => 'Phản ứng NẶNG',
  };

  Color get _reactionColor => switch (record.reactionSeverity) {
    ReactionSeverity.none => const Color(0xFF18794E),
    ReactionSeverity.mild => const Color(0xFF8A5D00),
    ReactionSeverity.moderate => const Color(0xFFE67E22),
    ReactionSeverity.severe => const Color(0xFFB42318),
  };

  @override
  Widget build(BuildContext context) {
    final pending = record.syncStatus == VaccinationSyncStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.vaccines_rounded, color: primaryGreen),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${record.vaccineName} - Mũi ${record.doseNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pending ? const Color(0xFFFFF3CD) : const Color(0xFFE5F5EC),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          pending ? 'Chờ đồng bộ' : 'Đã đồng bộ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text('Ngày tiêm: ${formatDate(record.administeredAt)}'),
                  Text('Số lô: ${record.lotNumber}'),
                  Text('Cán bộ tiêm: ${record.administeredBy}'),
                  if (record.storageTemperature != null)
                    Row(
                      children: [
                        Text('Nhiệt độ: ${record.storageTemperature!.toStringAsFixed(1)}°C'),
                        const SizedBox(width: 6),
                        if (record.isColdChainValid)
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF18794E))
                        else
                          const Icon(Icons.warning_rounded, size: 14, color: Color(0xFFB42318)),
                      ],
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _reactionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_reactionLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _reactionColor)),
                  ),
                  if ((record.reactions ?? '').isNotEmpty) Text('Ghi chú: ${record.reactions}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.record});

  final MedicationRecord record;

  @override
  Widget build(BuildContext context) {
    final pending = record.syncStatus == VaccinationSyncStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.medication_rounded, color: Color(0xFF8A5D00)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.medicationName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pending ? const Color(0xFFFFF3CD) : const Color(0xFFE5F5EC),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          pending ? 'Chờ đồng bộ' : 'Đã đồng bộ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text('Liều dùng: ${record.dosage}'),
                  Text('Ngày uống: ${formatDate(record.administeredAt)}'),
                  Text('Cán bộ cho uống: ${record.administeredBy}'),
                  if ((record.notes ?? '').isNotEmpty) Text('Ghi chú: ${record.notes}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
