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
      MaterialPageRoute<void>(
          builder: (_) => ChildFormScreen(childToEdit: child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scopedChildren = store.currentUserChildren;
    final childExists = scopedChildren.any((item) => item.id == widget.childId);

    if (!childExists) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ sức khỏe')),
        body: const Center(child: Text('Không tìm thấy thông tin trẻ.')),
      );
    }

    final child =
        scopedChildren.firstWhere((item) => item.id == widget.childId);
    final isLate = child.lateDays > 0;

    return Scaffold(
      backgroundColor: gray100,
      // ── App Bar theo style HTML ────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left_rounded,
                            color: primaryBlue, size: 22),
                        Text('Phụ huynh',
                            style: TextStyle(
                                color: primaryBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Chi tiết hồ sơ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: gray900),
                  ),
                ),
                // Sửa
                TextButton(
                  onPressed: () => _editChild(child),
                  child: const Text('Sửa',
                      style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Profile Card ────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gray200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: blueLight, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      child.fullName.characters.first,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  child.fullName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: gray900),
                ),
                const SizedBox(height: 2),
                Text(
                  isLate ? 'Trễ lịch tiêm chủng' : 'Đủ lịch tiêm chủng',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isLate ? accentRed : primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: gray200),
                const SizedBox(height: 10),
                // Info rows
                _infoRow('Ngày sinh',
                    '${formatDate(child.dateOfBirth)} (${child.gender})'),
                const SizedBox(height: 6),
                _infoRow('Thôn bản', '${child.village}, xã ${child.commune}'),
                const SizedBox(height: 6),
                _infoRow('QR Code', child.qrCode, isMono: true),
              ],
            ),
          ),

          // ── Late Vaccine Alert ───────────────────────────────
          if (isLate)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: redLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: accentRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Trễ ${child.lateDays} ngày • Mũi tiếp theo: ${child.nextVaccine} • Dự kiến: ${formatDate(child.nextDue)}',
                      style: const TextStyle(
                          color: accentRed, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // ── Segment Tabs ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: gray200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildTab(0, 'Tiêm chủng (${child.vaccinations.length})'),
                _buildTab(1, 'Thuốc uống (${child.medications.length})'),
              ],
            ),
          ),

          // ── Tab Content ──────────────────────────────────────
          if (_selectedTab == 0) ...[
            if (child.vaccinations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: EmptyState(
                  title: 'Chưa có bản ghi tiêm chủng',
                  description: 'Trẻ chưa có dữ liệu tiêm chủng.',
                ),
              )
            else
              ...child.vaccinations.reversed.map((v) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: TimelineItem(
                      title: '${v.vaccineName} – Mũi ${v.doseNumber}',
                      subtitle:
                          'Ngày tiêm: ${formatDate(v.administeredAt)} · Lô: ${v.lotNumber} · ${v.administeredBy}',
                      isSynced: v.syncStatus == VaccinationSyncStatus.synced,
                    ),
                  )),
          ] else ...[
            if (child.medications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: EmptyState(
                  title: 'Chưa có bản ghi thuốc uống',
                  description: 'Trẻ chưa có dữ liệu uống thuốc bổ sung.',
                ),
              )
            else
              ...child.medications.reversed.map((m) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: TimelineItem(
                      title: m.medicationName,
                      subtitle:
                          'Ngày uống: ${formatDate(m.administeredAt)} · Liều: ${m.dosage} · ${m.administeredBy}',
                      isSynced: m.syncStatus == VaccinationSyncStatus.synced,
                    ),
                  )),
          ],

          const SizedBox(height: 8),

          // ── Bottom action button (cập nhật trạng thái) ───────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: gray100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gray200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 16, color: gray600),
                    SizedBox(width: 6),
                    Text(
                      'Cập nhật trạng thái y tế (Chuyển vùng, tạm vắng...)',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: gray700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Row ────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: gray200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            RecordVaccinationScreen(childId: child.id)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ghi tiêm',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            RecordMedicationScreen(childId: child.id)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: gray100,
                    side: const BorderSide(color: gray200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ghi thuốc',
                      style: TextStyle(
                          color: gray800, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int tabIndex, String label) {
    final isActive = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 1))
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isActive ? gray900 : gray600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isMono = false}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child:
              Text(label, style: const TextStyle(color: gray500, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: gray900,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: isMono ? 'monospace' : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
