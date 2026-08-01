import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ChildFormScreen extends StatefulWidget {
  const ChildFormScreen({super.key, this.childToEdit});

  final ChildProfile? childToEdit;

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _motherNameController;
  late final TextEditingController _motherPhoneController;

  late DateTime _dob;
  late String _gender;
  String? _selectedCommune;
  String? _selectedVillage;
  late String _district;

  bool get _isEditing => widget.childToEdit != null;

  @override
  void initState() {
    super.initState();
    final child = widget.childToEdit;
    _fullNameController = TextEditingController(text: child?.fullName ?? '');
    _motherNameController =
        TextEditingController(text: child?.motherName ?? '');
    _motherPhoneController =
        TextEditingController(text: child?.motherPhone ?? '');
    _district = child?.district ?? 'Sa Pa';

    // Đặt giá trị xã và thôn/bản từ dữ liệu cũ (nếu đang sửa)
    if (child != null) {
      _selectedCommune = kCommuneList.contains(child.commune) ? child.commune : null;
      if (_selectedCommune != null) {
        final villages = kVillagesByCommune[_selectedCommune] ?? <String>[];
        _selectedVillage = villages.contains(child.village) ? child.village : null;
      }
    } else {
      // Mặc định xã phụ trách của y sĩ đăng nhập
      _selectedCommune = null;
      _selectedVillage = null;
    }

    _dob =
        child?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 90));
    _gender = child?.gender ?? 'Nam';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    super.dispose();
  }

  void _onCommuneChanged(String? value) {
    setState(() {
      _selectedCommune = value;
      _selectedVillage = null; // Reset thôn/bản khi đổi xã
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCommune == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn xã và thôn/bản.'), backgroundColor: Color(0xFFB42318)),
      );
      return;
    }

    final store = AppScope.of(context);
    final fullName = _fullNameController.text.trim();
    final motherName = _motherNameController.text.trim();
    final motherPhone = _motherPhoneController.text.trim();
    final village = _selectedVillage!;
    final commune = _selectedCommune!;
    final district = _district;

    if (_isEditing) {
      final updated = widget.childToEdit!.copyWith(
        fullName: fullName,
        dateOfBirth: _dob,
        gender: _gender,
        motherName: motherName,
        motherPhone: motherPhone,
        village: village,
        commune: commune,
        district: district,
      );
      store.updateChild(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin trẻ thành công.')),
      );
    } else {
      final newIndex = (store.children.length + 1);

      // Sinh mã QR có cấu trúc chuẩn y tế (B2)
      final qrCode = generateStructuredQrCode(
        district: district,
        commune: commune,
        dateOfBirth: _dob,
        counter: newIndex,
      );

      final newChild = ChildProfile(
        id: 'CH${newIndex.toString().padLeft(3, '0')}',
        qrCode: qrCode,
        fullName: fullName,
        dateOfBirth: _dob,
        gender: _gender,
        motherName: motherName,
        motherPhone: motherPhone,
        village: village,
        commune: commune,
        district: district,
        status: ChildVaccinationStatus.dueSoon,
        nextVaccine: 'DPT - Mũi 1',
        nextDue: DateTime.now().add(const Duration(days: 7)),
        lateDays: 0,
        vaccinations: [],
        medications: [],
      );

      store.addChild(newChild);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm trẻ mới. Mã QR: $qrCode')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final villages = _selectedCommune != null
        ? (kVillagesByCommune[_selectedCommune] ?? <String>[])
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thông tin trẻ' : 'Thêm trẻ mới'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(_isEditing ? 'Lưu thay đổi' : 'Tạo hồ sơ trẻ'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Thông tin cá nhân của trẻ',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên trẻ *',
                prefixIcon: Icon(Icons.child_care_rounded),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Vui lòng nhập họ tên trẻ' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                        initialDate: _dob,
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày sinh *',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(formatDate(_dob)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Giới tính *',
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _gender = v);
                    },
                  ),
                ),
              ],
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_rounded, color: primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mã QR sẽ được tự động tạo theo cấu trúc chuẩn: Huyện-Xã-NămSinh-SốTT',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Thông tin người nuôi dưỡng / Phụ huynh',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motherNameController,
              decoration: const InputDecoration(
                labelText: 'Họ tên mẹ / Người giám hộ *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Vui lòng nhập tên mẹ / giám hộ'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motherPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên hệ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Text('Địa chỉ cư trú',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ── B1: Xã → Dropdown cố định thay vì nhập tay ──
            DropdownButtonFormField<String>(
              initialValue: _selectedCommune,
              decoration: const InputDecoration(
                labelText: 'Xã *',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: kCommuneList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _onCommuneChanged,
              validator: (v) => v == null ? 'Vui lòng chọn xã' : null,
            ),
            const SizedBox(height: 12),

            // ── B1: Thôn/Bản → Dropdown theo xã đã chọn ──
            DropdownButtonFormField<String>(
              key: ValueKey('village-$_selectedCommune'),
              initialValue: _selectedVillage,
              decoration: const InputDecoration(
                labelText: 'Thôn / Bản *',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _selectedVillage = v),
              validator: (v) => v == null ? 'Vui lòng chọn thôn/bản' : null,
            ),
            const SizedBox(height: 12),

            // Huyện – readonly vì chỉ quản lý 1 huyện
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Huyện / Thị xã',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              child: Text(_district, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
