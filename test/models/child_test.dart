import 'package:flutter_test/flutter_test.dart';
import 'package:community_health/models/models.dart';

void main() {
  group('ChildProfile Unit Tests', () {
    test('Test 1: Initialize ChildProfile with standard constructor', () {
      final dob = DateTime(2024, 1, 15);
      final nextDue = DateTime(2026, 7, 10);
      
      final child = ChildProfile(
        id: 'CH001',
        qrCode: 'CH-QR-0001',
        fullName: 'Nguyễn Minh An',
        dateOfBirth: dob,
        gender: 'Nam',
        motherName: 'Nguyễn Thị Hoa',
        motherPhone: '0986 123 456',
        village: 'Bản Nậm Lùng',
        commune: 'Tả Phìn',
        district: 'Sa Pa',
        status: ChildVaccinationStatus.late,
        nextVaccine: 'DPT - Mũi 3',
        nextDue: nextDue,
        lateDays: 14,
        vaccinations: const [],
      );

      expect(child.id, 'CH001');
      expect(child.fullName, 'Nguyễn Minh An');
      expect(child.dateOfBirth, dob);
      expect(child.status, ChildVaccinationStatus.late);
      expect(child.lateDays, 14);
    });

    test('Test 2: Test copyWith pattern of ChildProfile', () {
      final child = ChildProfile(
        id: 'CH001',
        qrCode: 'CH-QR-0001',
        fullName: 'Nguyễn Minh An',
        dateOfBirth: DateTime(2024, 1, 15),
        gender: 'Nam',
        motherName: 'Nguyễn Thị Hoa',
        motherPhone: '0986 123 456',
        village: 'Bản Nậm Lùng',
        commune: 'Tả Phìn',
        district: 'Sa Pa',
        status: ChildVaccinationStatus.late,
        nextVaccine: 'DPT - Mũi 3',
        nextDue: DateTime(2026, 7, 10),
        lateDays: 14,
        vaccinations: const [],
      );

      final updatedChild = child.copyWith(
        status: ChildVaccinationStatus.complete,
        lateDays: 0,
      );

      expect(updatedChild.id, 'CH001'); // remain same
      expect(updatedChild.fullName, 'Nguyễn Minh An'); // remain same
      expect(updatedChild.status, ChildVaccinationStatus.complete); // updated
      expect(updatedChild.lateDays, 0); // updated
    });

    test('Test 3: Test integrity of child properties after multiple copyWith calls', () {
      final child = ChildProfile(
        id: 'CH001',
        qrCode: 'CH-QR-0001',
        fullName: 'Nguyễn Minh An',
        dateOfBirth: DateTime(2024, 1, 15),
        gender: 'Nam',
        motherName: 'Nguyễn Thị Hoa',
        motherPhone: '0986 123 456',
        village: 'Bản Nậm Lùng',
        commune: 'Tả Phìn',
        district: 'Sa Pa',
        status: ChildVaccinationStatus.late,
        nextVaccine: 'DPT - Mũi 3',
        nextDue: DateTime(2026, 7, 10),
        lateDays: 14,
        vaccinations: const [],
      );

      final step1 = child.copyWith(fullName: 'Nguyễn Minh Bình');
      final step2 = step1.copyWith(gender: 'Nữ');

      expect(step2.id, 'CH001');
      expect(step2.fullName, 'Nguyễn Minh Bình');
      expect(step2.gender, 'Nữ');
      expect(step2.status, ChildVaccinationStatus.late);
    });

    test('local storage round-trip keeps nested vaccination and medication data', () {
      final child = ChildProfile(
        id: 'CH-PERSIST',
        qrCode: 'QR-PERSIST',
        fullName: 'Persistent Child',
        dateOfBirth: DateTime(2024, 1, 15),
        gender: 'Nam',
        motherName: 'Persistent Parent',
        motherPhone: '0986123456',
        village: 'Village',
        commune: 'Commune',
        district: 'District',
        status: ChildVaccinationStatus.dueSoon,
        nextVaccine: 'DPT 1',
        nextDue: DateTime(2026, 8, 20),
        lateDays: 0,
        vaccinations: [
          VaccinationRecord(
            id: 'VAC-PERSIST',
            childId: 'CH-PERSIST',
            vaccineId: 'DPT-1',
            vaccineName: 'DPT',
            doseNumber: 1,
            lotNumber: 'LOT-01',
            administeredBy: 'Worker',
            administeredAt: DateTime(2026, 8, 14),
            syncStatus: VaccinationSyncStatus.pending,
          ),
        ],
        medications: [
          MedicationRecord(
            id: 'MED-PERSIST',
            childId: 'CH-PERSIST',
            medicationId: 'VIT-A',
            medicationName: 'Vitamin A',
            dosage: '1 dose',
            administeredBy: 'Worker',
            administeredAt: DateTime(2026, 8, 14),
            syncStatus: VaccinationSyncStatus.pending,
          ),
        ],
      );

      final restored = ChildProfile.fromStorageMap(child.toStorageMap());

      expect(restored.id, child.id);
      expect(restored.fullName, child.fullName);
      expect(restored.vaccinations.single.id, 'VAC-PERSIST');
      expect(restored.medications.single.id, 'MED-PERSIST');
    });
  });
}
