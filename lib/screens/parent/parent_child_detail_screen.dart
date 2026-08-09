import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ParentChildDetailScreen extends StatefulWidget {
  const ParentChildDetailScreen({super.key, required this.childId, this.showAppBar = true});

  final String childId;
  final bool showAppBar;

  @override
  State<ParentChildDetailScreen> createState() => _ParentChildDetailScreenState();
}

class _ParentChildDetailScreenState extends State<ParentChildDetailScreen> {
  int _selectedTab = 0; // 0: Tiêm chủng, 1: Uống thuốc

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final childExists = store.children.any((item) => item.id == widget.childId);

    if (!childExists) {
      return Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Sổ tiêm của con')) : null,
        body: const Center(child: Text('Không tìm thấy thông tin trẻ.')),
      );
    }

    final child = store.children.firstWhere((item) => item.id == widget.childId);
    final isLate = child.lateDays > 0;

    final mainContent = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Profile Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gray200),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: blueLight, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    child.fullName.characters.first,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                child.fullName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: gray900),
              ),
              const SizedBox(height: 2),
              Text(
                isLate ? 'Trễ lịch tiêm chủng' : 'Đủ lịch tiêm chủng',
                style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700,
                  color: isLate ? accentRed : primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: gray200),
              const SizedBox(height: 10),
              _infoRow('Ngày sinh', '${formatDate(child.dateOfBirth)} · ${child.gender}'),
              const SizedBox(height: 5),
              _infoRow('Thôn bản', '${child.village}, xã ${child.commune}'),
              const SizedBox(height: 5),
              _infoRow('Phụ huynh', '${child.motherName} · ${child.motherPhone}'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── QR Code Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gray200),
          ),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 120, color: gray900),
              const SizedBox(height: 6),
              Text(
                'Mã hồ sơ: ${child.qrCode}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: gray600),
              ),
              const SizedBox(height: 2),
              const Text(
                'Mã định danh cá nhân của trẻ để quét khi đến điểm tiêm.',
                textAlign: TextAlign.center,
                style: TextStyle(color: gray400, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Next Vaccine Alert ────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLate ? redLight : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLate ? accentRed.withValues(alpha: 0.3) : gray200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: isLate ? accentRed : gray500,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: isLate ? accentRed : gray700, height: 1.4),
                    children: [
                      const TextSpan(text: 'Mũi tiếp theo: ', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: '${child.nextVaccine}\n', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                        text: isLate
                            ? 'Đã trễ ${child.lateDays} ngày (Dự kiến: ${formatDate(child.nextDue)})'
                            : 'Dự kiến: ${formatDate(child.nextDue)}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Segment Tabs ──────────────────────────────────────
        Container(
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
        const SizedBox(height: 14),

        // ── Tab Content ───────────────────────────────────────
        if (_selectedTab == 0) ...[
          if (child.vaccinations.isEmpty)
            const EmptyState(
              title: 'Chưa có bản ghi tiêm chủng',
              description: 'Trẻ chưa có dữ liệu tiêm chủng.',
            )
          else
            ...child.vaccinations.reversed.map((v) => TimelineItem(
                  title: '${v.vaccineName} – Mũi ${v.doseNumber}',
                  subtitle:
                      'Ngày tiêm: ${formatDate(v.administeredAt)} · Lô: ${v.lotNumber} · ${v.administeredBy}',
                  isSynced: v.syncStatus == VaccinationSyncStatus.synced,
                )),
        ] else ...[
          if (child.medications.isEmpty)
            const EmptyState(
              title: 'Chưa có bản ghi thuốc uống',
              description: 'Trẻ chưa có dữ liệu uống thuốc bổ sung.',
            )
          else
            ...child.medications.reversed.map((m) => TimelineItem(
                  title: m.medicationName,
                  subtitle:
                      'Ngày uống: ${formatDate(m.administeredAt)} · Liều: ${m.dosage} · ${m.administeredBy}',
                  isSynced: m.syncStatus == VaccinationSyncStatus.synced,
                )),
        ],

        const SizedBox(height: 24),
      ],
    );

    if (!widget.showAppBar) {
      return mainContent;
    }

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
                        Text('Trở về',
                            style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Sổ tiêm của con',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: gray900),
                  ),
                ),
                // Role badge
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Phụ huynh',
                    style: TextStyle(color: primaryDark, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: mainContent,
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
                ? [const BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
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

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(color: gray500, fontSize: 11.5)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: gray900, fontSize: 11.5, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
