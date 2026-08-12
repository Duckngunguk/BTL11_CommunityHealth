import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _activeSubTab = 0; // 0: Facility, 1: Sync, 2: Target, 3: Database

  final _facilityNameController = TextEditingController(text: 'Trung tâm Y tế huyện Sa Pa');
  final _addressController = TextEditingController(text: 'Số 12 Đường Điện Biên Phủ, Sa Pa, Lào Cai');
  final _phoneController = TextEditingController(text: '0214 3871 115');
  final _emailController = TextEditingController(text: 'ttyt-sapa@laocai.gov.vn');

  bool _isAutoSync = true;
  String _syncInterval = '15 phút';

  @override
  void dispose() {
    _facilityNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return Scaffold(
      backgroundColor: gray100,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Cấu hình & Cài đặt hệ thống',
            subtitle: 'Quản lý thông tin đơn vị y tế, tần suất đồng bộ và thiết lập chỉ tiêu bao phủ vắc-xin địa phương.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 850;

              if (wide) {
                // ── Web-like Widescreen Panel Layout ──
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: SizedBox(
                    height: 520,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Settings Sidebar Menu (240px width)
                        Container(
                          width: 240,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSidebarTab(0, Icons.business_outlined, 'Thông tin cơ sở'),
                              const SizedBox(height: 4),
                              _buildSidebarTab(1, Icons.sync_outlined, 'Cấu hình đồng bộ'),
                              const SizedBox(height: 4),
                              _buildSidebarTab(2, Icons.track_changes_outlined, 'Chỉ tiêu tiêm chủng'),
                              const SizedBox(height: 4),
                              _buildSidebarTab(3, Icons.storage_outlined, 'Sao lưu & Khôi phục'),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1, color: gray200),
                        // Right Settings Content Form
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: _buildActiveForm(store),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ── Mobile Compact Layout (Vertical List) ──
              return Column(
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(value: 0, icon: Icon(Icons.business_outlined), label: Text('Cơ sở')),
                      ButtonSegment<int>(value: 1, icon: Icon(Icons.sync_outlined), label: Text('Đồng bộ')),
                      ButtonSegment<int>(value: 2, icon: Icon(Icons.track_changes_outlined), label: Text('Chỉ tiêu')),
                      ButtonSegment<int>(value: 3, icon: Icon(Icons.storage_outlined), label: Text('CSDL')),
                    ],
                    selected: {_activeSubTab},
                    onSelectionChanged: (val) => setState(() => _activeSubTab = val.first),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildActiveForm(store),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTab(int tabIndex, IconData icon, String title) {
    final isActive = _activeSubTab == tabIndex;
    return InkWell(
      onTap: () => setState(() => _activeSubTab = tabIndex),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? primaryBlue : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? primaryBlue : Colors.grey.shade800,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveForm(AppStore store) {
    switch (_activeSubTab) {
      case 0:
        return _buildFacilityForm();
      case 1:
        return _buildSyncForm();
      case 2:
        return _buildCoverageForm(store);
      case 3:
        return _buildDatabaseForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFacilityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business_outlined, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            const Text('Thông tin Cơ sở Y tế', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Cập nhật thông tin hành chính, đầu mối liên hệ của đơn vị y tế chủ quản.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        const SizedBox(height: 24),
        TextField(
          controller: _facilityNameController,
          decoration: const InputDecoration(
            labelText: 'Tên Cơ sở Chủ quản *',
            prefixIcon: Icon(Icons.health_and_safety_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ hành chính *',
            prefixIcon: Icon(Icons.map_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại liên hệ *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _facilityNameController.text = 'Trung tâm Y tế huyện Sa Pa';
                  _addressController.text = 'Số 12 Đường Điện Biên Phủ, Sa Pa, Lào Cai';
                  _phoneController.text = '0214 3871 115';
                  _emailController.text = 'ttyt-sapa@laocai.gov.vn';
                });
              },
              child: const Text('Đặt lại mặc định'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã lưu thông tin cơ sở y tế thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sync_outlined, color: Colors.purple.shade700, size: 24),
            const SizedBox(width: 12),
            const Text('Cấu hình Đồng bộ hóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Tùy chỉnh tần suất và thiết lập đồng bộ đám mây (Cloud) để duy trì chia sẻ dữ liệu liên thông.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        const SizedBox(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Đồng bộ tự động Cloud', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          subtitle: const Text('Tự động đồng bộ lịch tiêm chủng, danh sách trẻ em và ca bệnh lên máy chủ Firestore.', style: TextStyle(fontSize: 12)),
          value: _isAutoSync,
          activeColor: Colors.purple.shade700,
          onChanged: (val) {
            setState(() => _isAutoSync = val);
          },
        ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tần suất đồng bộ nền', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Thời gian giữa các lần tự động kiểm tra thay đổi ngoại tuyến.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            DropdownButton<String>(
              value: _syncInterval,
              underline: const SizedBox(),
              items: const ['5 phút', '15 phút', '30 phút', '60 phút']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _syncInterval = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã cập nhật cấu hình đồng bộ hóa Cloud thành công!'),
                    backgroundColor: Colors.purple.shade700,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Áp dụng cấu hình', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoverageForm(AppStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes_outlined, color: Colors.teal.shade700, size: 24),
            const SizedBox(width: 12),
            const Text('Chỉ tiêu Bao phủ Vắc-xin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Tùy chỉnh ngưỡng tỷ lệ hoàn thành tiêm chủng mục tiêu toàn huyện.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.teal.shade50.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ngưỡng chỉ tiêu hiện tại: ${store.districtCoverageTarget.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Các địa bàn xã có tỷ lệ phủ vắc-xin thực địa thấp hơn ngưỡng này sẽ được đánh dấu cảnh báo màu vàng/đỏ trên bảng theo dõi và sơ đồ dịch tễ để ưu tiên lập kế hoạch tiêm lưu động.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Slider(
          value: store.districtCoverageTarget,
          min: 50.0,
          max: 98.0,
          divisions: 48,
          label: '${store.districtCoverageTarget.toStringAsFixed(1)}%',
          activeColor: Colors.teal.shade700,
          inactiveColor: Colors.teal.shade100,
          onChanged: (val) {
            store.updateCoverageTarget(val);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thấp (50%)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text('Tiêu chuẩn (80%)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Mục tiêu cao (98%)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDatabaseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.storage_outlined, color: Colors.blueGrey.shade700, size: 24),
            const SizedBox(width: 12),
            const Text('Quản trị Cơ sở dữ liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Sao lưu cơ sở dữ liệu SQLite cục bộ sang tệp tin dự phòng hoặc tiến hành dọn dẹp bộ nhớ đệm.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        const SizedBox(height: 32),
        const Text('Các tác vụ khôi phục và bảo trì dữ liệu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDbActionCard(
                Icons.backup_outlined,
                Colors.blue.shade700,
                Colors.blue.shade50,
                'Sao lưu dữ liệu (Backup)',
                'Tạo tệp sao lưu CSDL sqlite sang tệp dự phòng backup_community_health.db',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao lưu cơ sở dữ liệu SQLite thành công sang thư mục AppData Local!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDbActionCard(
                Icons.cleaning_services_outlined,
                Colors.red.shade700,
                Colors.red.shade50,
                'Dọn dẹp bộ nhớ đệm',
                'Giải phóng các dữ liệu hình ảnh, tệp tin và thông tin rác đã tải về thiết bị.',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã dọn dẹp bộ nhớ đệm cục bộ thành công!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDbActionCard(IconData icon, Color color, Color bgColor, String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
