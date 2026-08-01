import 'package:flutter_test/flutter_test.dart';
import 'package:community_health/models/models.dart';

void main() {
  group('ChildProfile Model Unit Tests', () {
    final testChild = ChildProfile(
      id: 'CH999',
      qrCode: 'SP-TPH-26-9999',
      fullName: 'Nguyễn Văn Test',
      dateOfBirth: DateTime(2026, 1, 1),
      gender: 'Nam',
      motherName: 'Nguyễn Thị Mẹ',
      motherPhone: '0909090909',
      village: 'Bản Séo Mý Tỷ',
      commune: 'Tả Van',
      district: 'Sa Pa',
      status: ChildVaccinationStatus.dueSoon,
      nextVaccine: 'Sởi - Mũi 1',
      nextDue: DateTime(2026, 10, 1),
      lateDays: 0,
      vaccinations: [],
      medications: [],
    );

    test('Test 1: Khởi tạo thực thể ChildProfile thành công', () {
      expect(testChild.fullName, 'Nguyễn Văn Test');
      expect(testChild.gender, 'Nam');
      expect(testChild.commune, 'Tả Van');
    });

    test('Test 2: Hàm copyWith hoạt động chính xác', () {
      final updated = testChild.copyWith(
        status: ChildVaccinationStatus.late,
        lateDays: 15,
      );
      expect(updated.id, testChild.id);
      expect(updated.status, ChildVaccinationStatus.late);
      expect(updated.lateDays, 15);
    });

    test('Test 3: Kiểm tra cấu trúc QR code y tế chuẩn', () {
      final code = generateStructuredQrCode(
        district: 'Sa Pa',
        commune: 'Tả Phìn',
        dateOfBirth: DateTime(2024, 1, 1),
        counter: 12,
      );
      expect(code, 'SP-TPP-24-0012');
    });
  });
}
