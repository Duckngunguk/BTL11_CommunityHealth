import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: store.isOnline ? softGreen : const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(store.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, size: 54, color: store.isOnline ? primaryGreen : const Color(0xFF8A5D00)),
              const SizedBox(height: 12),
              Text(store.isOnline ? 'Sẵn sàng đồng bộ' : 'Thiết bị đang ngoại tuyến', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(store.isOnline ? 'Có ${store.pendingCount} bản ghi đang chờ tải lên.' : 'Dữ liệu mới vẫn được lưu an toàn trên thiết bị.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mô phỏng kết nối mạng'),
                subtitle: Text(store.isOnline ? 'Online' : 'Offline'),
                value: store.isOnline,
                onChanged: store.setOnline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Trạng thái dữ liệu'),
                const SizedBox(height: 16),
                _SyncRow(icon: Icons.download_done_rounded, label: 'Trẻ em đã tải về', value: '${store.children.length}'),
                _SyncRow(icon: Icons.cloud_upload_outlined, label: 'Bản ghi chờ đồng bộ', value: '${store.pendingCount}'),
                _SyncRow(icon: Icons.coronavirus_outlined, label: 'Báo cáo dịch tễ chờ', value: '${store.pendingDiseaseReportCount}'),
                _SyncRow(icon: Icons.schedule_rounded, label: 'Đồng bộ gần nhất', value: '${formatDate(store.lastSyncAt)} ${store.lastSyncAt.hour}:${store.lastSyncAt.minute.toString().padLeft(2, '0')}'),
                _SyncRow(icon: Icons.tag_rounded, label: 'Phiên bản dữ liệu', value: 'v${store.localVersion}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: !store.isOnline || store.pendingCount == 0 || store.isSyncing
              ? null
              : () async {
                  await store.syncPending();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đồng bộ thành công.')));
                  }
                },
          icon: store.isSyncing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync_rounded),
          label: Text(store.isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Batch sync chỉ đánh dấu synced sau khi toàn bộ lô được xử lý thành công.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _SyncRow extends StatelessWidget {
  const _SyncRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
