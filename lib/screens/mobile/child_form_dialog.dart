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
  late final TextEditingController _villageController;
  late final TextEditingController _communeController;
  late final TextEditingController _districtController;
  late final TextEditingController _qrCodeController;

  late DateTime _dob;
  late String _gender;

  bool get _isEditing => widget.childToEdit != null;

  @override
  void initState() {
    super.initState();
    final child = widget.childToEdit;
    _fullNameController = TextEditingController(text: child?.fullName ?? '');
    _motherNameController = TextEditingController(text: child?.motherName ?? '');
    _motherPhoneController = TextEditingController(text: child?.motherPhone ?? '');
    _villageController = TextEditingController(text: child?.village ?? 'Bản Nậm Lùng');
    _communeController = TextEditingController(text: child?.commune ?? 'Tả Phìn');
    _districtController = TextEditingController(text: child?.district ?? 'Sa Pa');
    _qrCodeController = TextEditingController(text: child?.qrCode ?? '');

    _dob = child?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 90));
    _gender = child?.gender ?? 'Nam';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _villageController.dispose();
    _communeController.dispose();
    _districtController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final store = AppScope.of(context);
    final fullName = _fullNameController.text.trim();
    final motherName = _motherNameController.text.trim();
    final motherPhone = _motherPhoneController.text.trim();
    final village = _villageController.text.trim();
    final commune = _communeController.text.trim();
    final district = _districtController.text.trim();
    String qrCode = _qrCodeController.text.trim();

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
        qrCode: qrCode.isEmpty ? widget.childToEdit!.qrCode : qrCode,
      );
      store.updateChild(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin trẻ thành công.')),
      );
    } else {
      final newIndex = (store.children.length + 1).toString().padLeft(3, '0');
      final newId = 'CH$newIndex';
      if (qrCode.isEmpty) {
        qrCode = 'CH-QR-$newIndex';
      }

      final newChild = ChildProfile(
        id: newId,
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
        const SnackBar(content: Text('Đã thêm trẻ mới vào sổ theo dõi.')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Thông tin cá nhân của trẻ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên trẻ *',
                prefixIcon: Icon(Icons.child_care_rounded),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập họ tên trẻ' : null,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _qrCodeController,
              decoration: const InputDecoration(
                labelText: 'Mã QR / Mã định danh',
                hintText: 'Tự động tạo nếu để trống',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Text('Thông tin người nuôi dưỡng / Phụ huynh', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motherNameController,
              decoration: const InputDecoration(
                labelText: 'Họ tên mẹ / Người giám hộ *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên mẹ / giám hộ' : null,
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
            Text('Địa chỉ cư trú', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _villageController,
              decoration: const InputDecoration(
                labelText: 'Thôn / Bản *',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập thôn/bản' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _communeController,
                    decoration: const InputDecoration(
                      labelText: 'Xã *',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập xã' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      labelText: 'Huyện / Thị xã *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập huyện' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
