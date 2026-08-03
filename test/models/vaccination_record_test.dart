import 'package:flutter_test/flutter_test.dart';
import 'package:community_health/models/models.dart';

void main() {
  group('VaccinationRecord Unit Tests', () {
    test('Test 1: Initialize VaccinationRecord with constructor', () {
      final administeredAt = DateTime(2024, 1, 17);
      final record = VaccinationRecord(
        id: 'VR-CH001-0',
        childId: 'CH001',
        vaccineId: 'BCG-1',
        vaccineName: 'BCG',
        doseNumber: 1,
        lotNumber: 'BCG2401',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: administeredAt,
        syncStatus: VaccinationSyncStatus.pending,
      );

      expect(record.id, 'VR-CH001-0');
      expect(record.childId, 'CH001');
      expect(record.vaccineName, 'BCG');
      expect(record.doseNumber, 1);
      expect(record.syncStatus, VaccinationSyncStatus.pending);
    });

    test('Test 2: Test copyWith syncStatus in VaccinationRecord', () {
      final record = VaccinationRecord(
        id: 'VR-CH001-0',
        childId: 'CH001',
        vaccineId: 'BCG-1',
        vaccineName: 'BCG',
        doseNumber: 1,
        lotNumber: 'BCG2401',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime(2024, 1, 17),
        syncStatus: VaccinationSyncStatus.pending,
      );

      final updatedRecord = record.copyWith(syncStatus: VaccinationSyncStatus.synced);

      expect(updatedRecord.id, 'VR-CH001-0');
      expect(updatedRecord.syncStatus, VaccinationSyncStatus.synced);
    });

    test('Test 3: Test properties mapping integrity', () {
      final record = VaccinationRecord(
        id: 'VR-CH001-0',
        childId: 'CH001',
        vaccineId: 'BCG-1',
        vaccineName: 'BCG',
        doseNumber: 1,
        lotNumber: 'BCG2401',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime(2024, 1, 17),
        syncStatus: VaccinationSyncStatus.synced,
        reactions: 'Sốt nhẹ',
      );

      expect(record.reactions, 'Sốt nhẹ');
      expect(record.lotNumber, 'BCG2401');
    });
  });
}
