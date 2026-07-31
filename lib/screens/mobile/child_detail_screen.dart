import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'record_vaccination_screen.dart';

class ChildDetailScreen extends StatelessWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final child = store.children.firstWhere((item) => item.id == childId);

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ tiêm chủng')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => RecordVaccinationScreen(childId: child.id)),
          ),
          icon: const Icon(Icons.vaccines_rounded),
          label: const Text('Ghi nhận mũi tiêm mới'),
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
                    child: Text(child.fullName.characters.first, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: primaryGreen)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                  Icon(child.status == ChildVaccinationStatus.late ? Icons.warning_amber_rounded : Icons.event_available_rounded, color: child.status == ChildVaccinationStatus.late ? const Color(0xFFB42318) : primaryGreen),
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
          const SizedBox(height: 22),
          const SectionHeader(title: 'Lịch sử tiêm chủng', subtitle: 'Thông tin được lưu trên thiết bị và đồng bộ với máy chủ.'),
          const SizedBox(height: 12),
          if (child.vaccinations.isEmpty)
            const EmptyState(title: 'Chưa có bản ghi', description: 'Trẻ chưa có dữ liệu tiêm chủng trên thiết bị.')
          else
            ...child.vaccinations.reversed.map((record) => _VaccinationCard(record: record)),
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
                      Expanded(child: Text('${record.vaccineName} - Mũi ${record.doseNumber}', style: const TextStyle(fontWeight: FontWeight.w800))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pending ? const Color(0xFFFFF3CD) : const Color(0xFFE5F5EC),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(pending ? 'Chờ đồng bộ' : 'Đã đồng bộ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pending ? const Color(0xFF8A5D00) : const Color(0xFF18794E))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text('Ngày tiêm: ${formatDate(record.administeredAt)}'),
                  Text('Số lô: ${record.lotNumber}'),
                  Text('Cán bộ tiêm: ${record.administeredBy}'),
                  if ((record.reactions ?? '').isNotEmpty) Text('Phản ứng: ${record.reactions}'),
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
