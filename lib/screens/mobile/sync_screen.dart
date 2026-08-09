import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _conflictSimulated = false;

  void _triggerSimulatedConflict() {
    setState(() => _conflictSimulated = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Mô phỏng xung đột dữ liệu: Bản ghi địa phương có thời gian mới hơn Firebase!'),
        backgroundColor: accentYellow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    // Collect all pending records across all children
    final pendingItems = <_SyncItem>[];

    for (final child in store.children) {
      for (final v in child.vaccinations) {
        if (v.syncStatus == VaccinationSyncStatus.pending) {
          pendingItems.add(_SyncItem(
            childName: child.fullName,
            description: 'Tiêm vắc-xin ${v.vaccineName} Mũi ${v.doseNumber}',
            administeredBy: v.administeredBy,
          ));
        }
      }
      for (final m in child.medications) {
        if (m.syncStatus == VaccinationSyncStatus.pending) {
          pendingItems.add(_SyncItem(
            childName: child.fullName,
            description: 'Cho uống ${m.medicationName}',
            administeredBy: m.administeredBy,
          ));
        }
      }
    }

    final count = pendingItems.isNotEmpty ? pendingItems.length : store.pendingCount;

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── Top Offline Alert Banner (Brown/Orange) ────────
          Container(
            color: const Color(0xFFB06000),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  store.isOnline
                      ? 'CHẾ ĐỘ TRỰC TUYẾN • ĐÃ ĐỒNG BỘ'
                      : 'CHẾ ĐỘ NGOẠI TUYẾN • ${count > 0 ? "$count bản ghi chờ đồng bộ" : "Sẵn sàng đồng bộ"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),

          // ── Header Title Bar ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 40, bottom: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Đồng bộ dữ liệu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: gray900),
                        ),
                      ),
                      // Refresh / sync trigger icon button
                      GestureDetector(
                        onTap: () async {
                          if (store.isOnline && count > 0) {
                            await store.syncPending();
                            setState(() {});
                          } else {
                            store.setOnline(!store.isOnline);
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: blueLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.refresh_rounded, color: primaryBlue, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: gray200),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Yellow Warning Card ────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // Light yellow bg
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, height: 1.4),
                      children: [
                        const TextSpan(text: 'Phát hiện ', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: '$count bản ghi ', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(text: 'chưa được đồng bộ lên Firebase Cloud.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Section 1: BẢN GHI CHỜ ĐỒNG BỘ ─────────────
                const SectionLabel('BẢN GHI CHỜ ĐỒNG BỘ'),
                if (pendingItems.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gray200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tiêm vắc-xin DPT Mũi 3',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: gray900),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Chờ đẩy',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Trẻ: Nguyễn Minh An • Người thực hiện: Y sĩ Lê Thu',
                                style: TextStyle(color: gray500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...pendingItems.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: gray200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.description,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: gray900),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Chờ đẩy',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trẻ: ${item.childName} • Người thực hiện: ${item.administeredBy}',
                                    style: const TextStyle(color: gray500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 12),

                // ── Dual Action Buttons ────────────────────────
                // Button 1: Green Sync Button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: store.isSyncing
                        ? null
                        : () async {
                            await store.syncPending();
                            setState(() {});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Đồng bộ dữ liệu thành công!'),
                                  backgroundColor: Color(0xFF059669),
                                ),
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669), // Solid green
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: store.isSyncing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded, size: 20, color: Colors.white),
                    label: Text(
                      store.isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ dữ liệu thường',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Button 2: Blue Simulation Button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _triggerSimulatedConflict,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Solid blue
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.science_outlined, size: 20, color: Colors.white),
                    label: const Text(
                      'Mô phỏng Xung đột (Demo)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Section 2: NHẬT KÝ DUYỆT XUNG ĐỘT (AUDIT LOG) ─
                const SectionLabel('NHẬT KÝ DUYỆT XUNG ĐỘT (AUDIT LOG)'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gray200),
                  ),
                  child: Center(
                    child: Text(
                      _conflictSimulated
                          ? '⚠️ [Xung đột đã ghi nhận]: Bản ghi local #REC-001 được chọn giữ nguyên.'
                          : 'Chưa phát hiện và duyệt xung đột nào.',
                      style: TextStyle(
                        color: _conflictSimulated ? const Color(0xFFD97706) : gray400,
                        fontSize: 12.5,
                        fontWeight: _conflictSimulated ? FontWeight.w700 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Section 3: LỊCH SỬ ĐỒNG BỘ THÀNH CÔNG ──────
                const SectionLabel('LỊCH SỬ ĐỒNG BỘ THÀNH CÔNG'),

                // Hardcoded demo history cards matching prototype + dynamic batches
                _buildHistoryCard('Lô Batch-BG-002 (3 trẻ)', 'Thời gian: 08/08/2026 05:00'),
                const SizedBox(height: 10),
                _buildHistoryCard('Lô Batch-BG-001 (5 trẻ)', 'Thời gian: 07/08/2026 14:00'),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left green border stripe
              Container(width: 5, color: const Color(0xFF059669)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: gray900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(color: gray500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Thành công',
                        style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncItem {
  const _SyncItem({required this.childName, required this.description, required this.administeredBy});
  final String childName;
  final String description;
  final String administeredBy;
}
