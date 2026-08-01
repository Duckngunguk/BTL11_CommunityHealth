import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ParentChildDetailScreen extends StatefulWidget {
  const ParentChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  State<ParentChildDetailScreen> createState() => _ParentChildDetailScreenState();
}

class _ParentChildDetailScreenState extends State<ParentChildDetailScreen> {
  int _selectedTab = 0;

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
        title: const Text('Hồ sơ sức khỏe'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Chỉ xem', style: TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFF0F4F8),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin cơ bản
          _ChildInfoCard(child: child),
          const SizedBox(height: 16),

          // Cảnh báo nếu trễ lịch
          if (child.status == ChildVaccinationStatus.late)
            _LateWarningBanner(child: child),
          if (child.status == ChildVaccinationStatus.late) const SizedBox(height: 16),

          // Lịch tiêm tiếp theo
          _NextVaccineCard(child: child),
          const SizedBox(height: 20),

          // Tab chọn xem lịch sử
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
              subtitle: 'Thông tin các mũi đã tiêm.',
            ),
            const SizedBox(height: 12),
            if (child.vaccinations.isEmpty)
              const EmptyState(
                title: 'Chưa có bản ghi tiêm chủng',
                description: 'Trẻ chưa có thông tin tiêm chủng nào được ghi nhận.',
              )
            else
              ...child.vaccinations.reversed.map((r) => _ReadOnlyVaccinationCard(record: r)),
          ] else ...[
            const SectionHeader(
              title: 'Lịch sử uống thuốc',
              subtitle: 'Vitamin A, thuốc tẩy giun và các thuốc bổ sung.',
            ),
            const SizedBox(height: 12),
            if (child.medications.isEmpty)
              const EmptyState(
                title: 'Chưa có bản ghi thuốc uống',
                description: 'Trẻ chưa có thông tin uống thuốc bổ sung nào.',
              )
            else
              ...child.medications.reversed.map((r) => _ReadOnlyMedicationCard(record: r)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ChildInfoCard extends StatelessWidget {
  const _ChildInfoCard({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      child.fullName.characters.first,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      StatusPill(status: child.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.cake_outlined, label: 'Ngày sinh', value: formatDate(child.dateOfBirth)),
            _InfoRow(icon: Icons.wc_rounded, label: 'Giới tính', value: child.gender),
            _InfoRow(icon: Icons.location_on_outlined, label: 'Địa chỉ', value: '${child.village}, ${child.commune}, ${child.district}'),
            _InfoRow(icon: Icons.person_outline_rounded, label: 'Tên mẹ', value: child.motherName),
            _InfoRow(icon: Icons.phone_outlined, label: 'SĐT mẹ', value: child.motherPhone),
            _InfoRow(icon: Icons.qr_code_rounded, label: 'Mã QR', value: child.qrCode),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LateWarningBanner extends StatelessWidget {
  const _LateWarningBanner({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Con bạn đang trễ lịch tiêm!',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB42318), fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Trễ ${child.lateDays} ngày. Vui lòng đưa con đến trạm y tế sớm để được tiêm bổ sung.',
                  style: const TextStyle(color: Color(0xFFB42318), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextVaccineCard extends StatelessWidget {
  const _NextVaccineCard({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final isLate = child.status == ChildVaccinationStatus.late;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLate ? const Color(0xFFFFE9E7) : const Color(0xFFE5F5EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isLate ? Icons.warning_amber_rounded : Icons.event_available_rounded,
                color: isLate ? const Color(0xFFB42318) : const Color(0xFF18794E),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLate ? 'Lịch tiêm đã trễ' : 'Lịch tiêm tiếp theo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLate ? const Color(0xFFB42318) : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    child.nextVaccine,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  Text(
                    'Ngày: ${formatDate(child.nextDue)}',
                    style: TextStyle(
                      color: isLate ? const Color(0xFFB42318) : const Color(0xFF18794E),
                      fontWeight: FontWeight.w600,
                    ),
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

class _ReadOnlyVaccinationCard extends StatelessWidget {
  const _ReadOnlyVaccinationCard({required this.record});
  final VaccinationRecord record;

  @override
  Widget build(BuildContext context) {
    final pending = record.syncStatus == VaccinationSyncStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.vaccines_rounded, color: Color(0xFF18794E), size: 22),
            ),
            const SizedBox(width: 12),
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
                          pending ? 'Chờ đồng bộ' : 'Đã ghi nhận',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('Ngày tiêm: ${formatDate(record.administeredAt)}', style: const TextStyle(fontSize: 13)),
                  Text('Số lô: ${record.lotNumber}', style: const TextStyle(fontSize: 13)),
                  Text('Cán bộ tiêm: ${record.administeredBy}', style: const TextStyle(fontSize: 13)),
                  if (record.reactions.isNotEmpty)
                    Text('Phản ứng: ${record.reactions}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyMedicationCard extends StatelessWidget {
  const _ReadOnlyMedicationCard({required this.record});
  final MedicationRecord record;

  @override
  Widget build(BuildContext context) {
    final pending = record.syncStatus == VaccinationSyncStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.medication_rounded, color: Color(0xFF8A5D00), size: 22),
            ),
            const SizedBox(width: 12),
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
                          pending ? 'Chờ đồng bộ' : 'Đã ghi nhận',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('Liều dùng: ${record.dosage}', style: const TextStyle(fontSize: 13)),
                  Text('Ngày uống: ${formatDate(record.administeredAt)}', style: const TextStyle(fontSize: 13)),
                  Text('Cán bộ cho uống: ${record.administeredBy}', style: const TextStyle(fontSize: 13)),
                  if ((record.notes ?? '').isNotEmpty)
                    Text('Ghi chú: ${record.notes}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
