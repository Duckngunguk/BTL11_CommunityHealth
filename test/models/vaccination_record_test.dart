import 'package:flutter_test/flutter_test.dart';
import 'package:community_health/models/models.dart';

void main() {
  group('VaccinationRecord Model Unit Tests', () {
    test('Test 1: Chuỗi lạnh hợp lệ khi nhiệt độ nằm trong khoảng 2-8°C', () {
      final validRecord = VaccinationRecord(
        id: 'VR-001',
        childId: 'CH001',
        vaccineId: 'BCG-1',
        vaccineName: 'BCG',
        doseNumber: 1,
        lotNumber: 'LOT123',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        storageTemperature: 4.5, // 4.5°C -> Hợp lệ
      );

      expect(validRecord.isColdChainValid, isTrue);
      expect(validRecord.coldChainWarning, isNull);
    });

    test('Test 2: Cảnh báo chuỗi lạnh khi nhiệt độ dưới 2°C (nguy cơ đóng băng)', () {
      final coldRecord = VaccinationRecord(
        id: 'VR-002',
        childId: 'CH001',
        vaccineId: 'BCG-1',
        vaccineName: 'BCG',
        doseNumber: 1,
        lotNumber: 'LOT123',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        storageTemperature: 1.2, // 1.2°C -> Quá thấp
      );

      expect(coldRecord.isColdChainValid, isFalse);
      expect(coldRecord.coldChainWarning, contains('đóng băng'));
    });

    test('Test 3: Cảnh báo chuỗi lạnh khi nhiệt độ trên 8°C (mất hiệu lực)', () {
      final hotRecord = VaccinationRecord(
        id: 'VR-003',
        childId: 'CH001',
        vaccineId: 'BCG-1',
        vaccineName: 'BCG',
        doseNumber: 1,
        lotNumber: 'LOT123',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        storageTemperature: 9.0, // 9.0°C -> Quá cao
      );

      expect(hotRecord.isColdChainValid, isFalse);
      expect(hotRecord.coldChainWarning, contains('mất hiệu lực'));
    });

    test('Test 4: Đánh giá mức độ phản ứng sau tiêm chuẩn y tế', () {
      final severeRecord = VaccinationRecord(
        id: 'VR-004',
        childId: 'CH001',
        vaccineId: 'DPT-1',
        vaccineName: 'DPT',
        doseNumber: 1,
        lotNumber: 'LOT123',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        reactionSeverity: ReactionSeverity.severe,
      );

      expect(severeRecord.reactionSeverity, ReactionSeverity.severe);
    });
  });
}
