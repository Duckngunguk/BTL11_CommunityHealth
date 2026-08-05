import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    // Collect all pending/synced records across all children
    final pendingItems = <_SyncItem>[];
    final syncedItems = <_SyncItem>[];

    for (final child in store.children) {
      for (final v in child.vaccinations) {
        final item = _SyncItem(
          childName: child.fullName,
          description: '💉 ${v.vaccineName} — Mũi ${v.doseNumber}',
          date: v.administeredAt,
        );
        if (v.syncStatus == VaccinationSyncStatus.pending) {
          pendingItems.add(item);
        } else {
          syncedItems.add(item);
        }
      }
      for (final m in child.medications) {
        final item = _SyncItem(
          childName: child.fullName,
          description: '💊 ${m.medicationName}',
          date: m.administeredAt,
        );
        if (m.syncStatus == VaccinationSyncStatus.pending) {
          pendingItems.add(item);
        } else {
          syncedItems.add(item);
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Status header card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: store.isOnline
                  ? [const Color(0xFFE8F5E9), const Color(0xFFF0FDF4)]
                  : [const Color(0xFFFFF8E7), const Color(0xFFFFFBEB)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: store.isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: store.isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      store.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 32,
                      color: store.isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.isOnline ? 'Đang kết nối mạng' : 'Thiết bị ngoại tuyến',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: store.isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          store.isOnline
                              ? '${pendingItems.length} bản ghi đang chờ đồng bộ'
                              : 'Dữ liệu được lưu an toàn trên thiết bị',
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mô phỏng kết nối mạng', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(store.isOnline ? 'Trạng thái: Online' : 'Trạng thái: Offline'),
                value: store.isOnline,
                activeColor: primaryGreen,
                onChanged: store.setOnline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Stats row ───────────────────────────────────────────────
        Row(
          children: [
            _StatCard(icon: Icons.child_care_rounded, label: 'Hồ sơ trẻ', value: '${store.children.length}', color: primaryGreen),
            const SizedBox(width: 10),
            _StatCard(icon: Icons.cloud_upload_outlined, label: 'Chờ sync', value: '${pendingItems.length}', color: const Color(0xFFD97706)),
            const SizedBox(width: 10),
            _StatCard(icon: Icons.check_circle_outline_rounded, label: 'Đã sync', value: '${syncedItems.length}', color: const Color(0xFF3B82F6)),
          ],
        ),
        const SizedBox(height: 14),

        // ── Progress bar (syncing) ──────────────────────────────────
        if (store.isSyncing) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryGreen),
                      ),
                      const SizedBox(width: 12),
                      const Text('Đang đồng bộ dữ liệu lên máy chủ...', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Color(0xFFE2E8F0),
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Sync button ─────────────────────────────────────────────
        FilledButton.icon(
          onPressed: !store.isOnline || pendingItems.isEmpty || store.isSyncing
              ? null
              : () async {
                  await store.syncPending();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đồng bộ thành công!'),
                        backgroundColor: Color(0xFF18794E),
                      ),
                    );
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: primaryGreen,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: store.isSyncing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync_rounded),
          label: Text(
            store.isSyncing
                ? 'Đang đồng bộ...'
                : pendingItems.isEmpty
                    ? 'Không có bản ghi cần đồng bộ'
                    : 'Đồng bộ ${pendingItems.length} bản ghi ngay',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Đồng bộ gần nhất: ${formatDate(store.lastSyncAt)} ${store.lastSyncAt.hour}:${store.lastSyncAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),

        // ── Pending list ────────────────────────────────────────────
        if (pendingItems.isNotEmpty) ...[
          const SectionHeader(
            title: '📋 Bản ghi chờ đồng bộ',
            subtitle: 'Sẽ được gửi lên máy chủ khi kết nối mạng.',
          ),
          const SizedBox(height: 10),
          ...pendingItems.map((item) => _SyncItemTile(item: item, isPending: true)),
          const SizedBox(height: 20),
        ],

        // ── Synced list ─────────────────────────────────────────────
        if (syncedItems.isNotEmpty) ...[
          const SectionHeader(
            title: '✅ Đã đồng bộ thành công',
            subtitle: 'Dữ liệu đã được xác nhận trên máy chủ.',
          ),
          const SizedBox(height: 10),
          ...syncedItems.take(10).map((item) => _SyncItemTile(item: item, isPending: false)),
          if (syncedItems.length > 10)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Và ${syncedItems.length - 10} bản ghi khác...',
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────

class _SyncItem {
  const _SyncItem({required this.childName, required this.description, required this.date});
  final String childName;
  final String description;
  final DateTime date;
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SyncItemTile extends StatelessWidget {
  const _SyncItemTile({required this.item, required this.isPending});
  final _SyncItem item;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.sync_rounded : Icons.check_circle_rounded,
            color: isPending ? const Color(0xFFD97706) : const Color(0xFF18794E),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${item.childName} • ${formatDate(item.date)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isPending ? 'Chờ sync' : 'Đã sync',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPending ? const Color(0xFF92400E) : const Color(0xFF14532D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


