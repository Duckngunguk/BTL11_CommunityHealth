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
              _VaccinationTimeline(vaccinations: child.vaccinations.toList()),
          ] else ...[
            const SectionHeader(
              title: 'Lịch sử uống thuốc',
              subtitle: 'Thông tin cho uống Vitamin A, thuốc tẩy giun và các thuốc dạng uống.',
            ),
            const SizedBox(height: 12),
            if (child.medications.isEmpty)
              const EmptyState(title: 'Chưa có bản ghi thuốc uống', description: 'Trẻ chưa có dữ liệu uống thuốc bổ sung.')
            else
              _MedicationTimeline(medications: child.medications.toList()),
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

class _VaccinationTimeline extends StatelessWidget {
  const _VaccinationTimeline({required this.vaccinations});
  final List<VaccinationRecord> vaccinations;

  @override
  Widget build(BuildContext context) {
    final synced = vaccinations.where((v) => v.syncStatus == VaccinationSyncStatus.synced).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary badge
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.vaccines_rounded, color: Color(0xFF18794E), size: 22),
              const SizedBox(width: 10),
              Text(
                'Đã tiêm $synced/${vaccinations.length} mũi đồng bộ thành công',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF18794E)),
              ),
            ],
          ),
        ),
        // Timeline
        ...vaccinations.reversed.toList().asMap().entries.map((entry) {
          final isLast = entry.key == vaccinations.length - 1;
          return _VaccinationTimelineItem(record: entry.value, isLast: isLast);
        }),
      ],
    );
  }
}

class _VaccinationTimelineItem extends StatefulWidget {
  const _VaccinationTimelineItem({required this.record, required this.isLast});
  final VaccinationRecord record;
  final bool isLast;

  @override
  State<_VaccinationTimelineItem> createState() => _VaccinationTimelineItemState();
}

class _VaccinationTimelineItemState extends State<_VaccinationTimelineItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pending = widget.record.syncStatus == VaccinationSyncStatus.pending;
    final dotColor = pending ? const Color(0xFFD97706) : const Color(0xFF18794E);
    final bgColor = pending ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4);
    final borderColor = pending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: dotColor.withAlpha(80), blurRadius: 6, spreadRadius: 2)],
                  ),
                  child: Icon(
                    pending ? Icons.sync_rounded : Icons.check_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.record.vaccineName} — Mũi ${widget.record.doseNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            pending ? '⏳ Chờ đồng bộ' : '✅ Đã đồng bộ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pending ? const Color(0xFF92400E) : const Color(0xFF14532D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDate(widget.record.administeredAt),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    // Expandable details
                    if (_expanded) ...[ 
                      const Divider(height: 16),
                      _DetailRow(label: 'Số lô vaccine', value: widget.record.lotNumber),
                      _DetailRow(label: 'Cán bộ tiêm', value: widget.record.administeredBy),
                      if ((widget.record.reactions ?? '').isNotEmpty)
                        _DetailRow(
                          label: 'Phản ứng sau tiêm',
                          value: widget.record.reactions!,
                          valueColor: const Color(0xFFB42318),
                        ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _expanded ? 'Thu gọn ▲' : 'Xem chi tiết ▼',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationTimeline extends StatelessWidget {
  const _MedicationTimeline({required this.medications});
  final List<MedicationRecord> medications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.medication_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 10),
              Text(
                'Tổng ${medications.length} lần uống thuốc được ghi nhận',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
            ],
          ),
        ),
        ...medications.reversed.toList().asMap().entries.map((entry) {
          final isLast = entry.key == medications.length - 1;
          return _MedicationTimelineItem(record: entry.value, isLast: isLast);
        }),
      ],
    );
  }
}

class _MedicationTimelineItem extends StatefulWidget {
  const _MedicationTimelineItem({required this.record, required this.isLast});
  final MedicationRecord record;
  final bool isLast;

  @override
  State<_MedicationTimelineItem> createState() => _MedicationTimelineItemState();
}

class _MedicationTimelineItemState extends State<_MedicationTimelineItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pending = widget.record.syncStatus == VaccinationSyncStatus.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    shape: BoxShape.circle,
                    boxShadow: [const BoxShadow(color: Color(0x40D97706), blurRadius: 6, spreadRadius: 2)],
                  ),
                  child: Icon(
                    pending ? Icons.sync_rounded : Icons.check_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.record.medicationName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            pending ? '⏳ Chờ đồng bộ' : '✅ Đã đồng bộ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pending ? const Color(0xFF92400E) : const Color(0xFF14532D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDate(widget.record.administeredAt),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (_expanded) ...[
                      const Divider(height: 16),
                      _DetailRow(label: 'Liều dùng', value: widget.record.dosage),
                      _DetailRow(label: 'Cán bộ cho uống', value: widget.record.administeredBy),
                      if ((widget.record.notes ?? '').isNotEmpty)
                        _DetailRow(label: 'Ghi chú', value: widget.record.notes!),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _expanded ? 'Thu gọn ▲' : 'Xem chi tiết ▼',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
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
