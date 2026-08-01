import 'package:flutter/widgets.dart';

import '../data/demo_data.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  AppStore()
      : children = List<ChildProfile>.from(demoChildren),
        diseaseReports = List<DiseaseReport>.from(demoDiseaseReports),
        lastSyncAt = DateTime(2026, 7, 23, 16, 40);

  /// Người dùng đang đăng nhập – tự động gán khi login.
  UserProfile currentUser = const UserProfile(
    id: 'HW-001',
    fullName: 'Y sĩ Lê Thu',
    role: 'y_si',
    assignedCommune: 'Tả Phìn',
  );

  final List<ChildProfile> children;
  final List<DiseaseReport> diseaseReports;
  bool isOnline = false;
  bool isSyncing = false;
  DateTime lastSyncAt;

  /// Phiên bản dữ liệu cục bộ – dùng để phát hiện xung đột khi đồng bộ.
  int _localVersion = 1;
  int get localVersion => _localVersion;

  /// Phiên bản dữ liệu trên server – giả lập.
  int _serverVersion = 1;

  // ────────────────────────────
  // Computed properties
  // ────────────────────────────

  int get pendingCount {
    final pendingVaccines = children
        .expand((child) => child.vaccinations)
        .where((record) => record.syncStatus == SyncStatus.pending)
        .length;
    final pendingMedications = children
        .expand((child) => child.medications)
        .where((record) => record.syncStatus == SyncStatus.pending)
        .length;
    final pendingDiseaseReports = diseaseReports
        .where((report) => report.syncStatus == SyncStatus.pending)
        .length;
    return pendingVaccines + pendingMedications + pendingDiseaseReports;
  }

  int get lateCount => children
      .where((child) => child.status == ChildVaccinationStatus.late)
      .length;

  int get dueSoonCount => children
      .where((child) => child.status == ChildVaccinationStatus.dueSoon)
      .length;

  int get diseaseReportCount => diseaseReports.length;

  int get pendingDiseaseReportCount =>
      diseaseReports.where((r) => r.syncStatus == SyncStatus.pending).length;

  /// Số ca nghi nhiễm khẩn cấp chưa xử lý.
  int get emergencyDiseaseCount =>
      diseaseReports.where((r) => r.urgency == DiseaseUrgency.emergency).length;

  /// Thống kê số ca theo xã.
  Map<String, int> get diseaseCountByCommune {
    final map = <String, int>{};
    for (final report in diseaseReports) {
      map[report.commune] = (map[report.commune] ?? 0) + 1;
    }
    return map;
  }

  /// Thống kê số ca theo loại bệnh.
  Map<String, int> get diseaseCountByType {
    final map = <String, int>{};
    for (final report in diseaseReports) {
      map[report.diseaseName] = (map[report.diseaseName] ?? 0) + 1;
    }
    return map;
  }

  // ────────────────────────────
  // Quản lý kết nối
  // ────────────────────────────

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  // ────────────────────────────
  // Quản lý trẻ em
  // ────────────────────────────

  void addChild(ChildProfile child) {
    children.insert(0, child);
    _localVersion++;
    notifyListeners();
  }

  void updateChild(ChildProfile child) {
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1) return;
    children[index] = child;
    _localVersion++;
    notifyListeners();
  }

  void deleteChild(String childId) {
    children.removeWhere((item) => item.id == childId);
    _localVersion++;
    notifyListeners();
  }

  void addVaccination(String childId, VaccinationRecord record) {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      vaccinations: [...children[index].vaccinations, record],
    );
    _localVersion++;
    notifyListeners();
  }

  void addMedication(String childId, MedicationRecord record) {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      medications: [...children[index].medications, record],
    );
    _localVersion++;
    notifyListeners();
  }

  // ────────────────────────────
  // Quản lý báo cáo dịch tễ
  // ────────────────────────────

  void addDiseaseReport(DiseaseReport report) {
    diseaseReports.insert(0, report);
    _localVersion++;
    notifyListeners();
  }

  // ────────────────────────────
  // Đồng bộ dữ liệu
  // ────────────────────────────

  /// Kiểm tra xung đột version trước khi đồng bộ.
  bool get hasConflict => _localVersion != _serverVersion;

  Future<void> syncPending() async {
    if (!isOnline || pendingCount == 0) return;
    isSyncing = true;
    notifyListeners();

    // Giả lập kiểm tra xung đột version
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (hasConflict) {
      // Chiến lược giải quyết xung đột: Last-Write-Wins kèm ghi log
      // Trong thực tế, cần implement merge strategy phức tạp hơn.
      _serverVersion = _localVersion;
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Đồng bộ bản ghi tiêm chủng
    for (var i = 0; i < children.length; i++) {
      final updatedVaccinations = children[i].vaccinations.map((record) {
        return record.syncStatus == SyncStatus.pending
            ? record.copyWith(syncStatus: SyncStatus.synced)
            : record;
      }).toList();

      final updatedMedications = children[i].medications.map((record) {
        return record.syncStatus == SyncStatus.pending
            ? record.copyWith(syncStatus: SyncStatus.synced)
            : record;
      }).toList();

      children[i] = children[i].copyWith(
        vaccinations: updatedVaccinations,
        medications: updatedMedications,
      );
    }

    // Đồng bộ báo cáo dịch tễ
    for (var i = 0; i < diseaseReports.length; i++) {
      if (diseaseReports[i].syncStatus == SyncStatus.pending) {
        diseaseReports[i] = diseaseReports[i].copyWith(syncStatus: SyncStatus.synced);
      }
    }

    _serverVersion = _localVersion;
    lastSyncAt = DateTime.now();
    isSyncing = false;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({
    super.key,
    required AppStore notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Không tìm thấy AppScope trong widget tree.');
    return scope!.notifier!;
  }
}
