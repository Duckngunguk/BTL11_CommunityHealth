import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text('Y sĩ Lê Thu', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('Phụ trách xã Tả Phìn • Thiết bị CH-DEV-001'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile.adaptive(value: true, onChanged: (_) {}, title: const Text('Tự động đồng bộ'), subtitle: const Text('Khi thiết bị có Wi-Fi hoặc dữ liệu di động')),
              const Divider(height: 1),
              SwitchListTile.adaptive(value: true, onChanged: (_) {}, title: const Text('Nhắc lịch tiêm'), subtitle: const Text('Hiển thị nhắc lịch trên thiết bị')),
              const Divider(height: 1),
              const ListTile(leading: Icon(Icons.lock_outline_rounded), title: Text('Mã hóa dữ liệu cục bộ'), trailing: Icon(Icons.check_circle, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('Phiên bản'), trailing: Text('1.0.0 Demo')),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Đăng xuất'), onTap: onLogout),
            ],
          ),
        ),
      ],
    );
  }
}
