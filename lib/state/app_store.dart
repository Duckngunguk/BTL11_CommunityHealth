import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../data/demo_data.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  AppStore()
      : children = List<ChildProfile>.from(demoChildren),
        diseaseReports = List<DiseaseReport>.from(demoDiseaseReports),
        lastSyncAt = DateTime(2026, 7, 23, 16, 40) {
    _initLocalDatabase();
  }

  /// Người dùng đang đăng nhập – tự động gán khi login.
  UserProfile currentUser = const UserProfile(
    id: 'HW-001',
    fullName: 'Y sĩ Lê Thu',
    role: 'y_si',
    assignedCommune: 'Tả Phìn',
  );

  List<ChildProfile> children;
  List<DiseaseReport> diseaseReports;
  bool isOnline = false;
  bool isSyncing = false;
  DateTime lastSyncAt;

  /// Phiên bản dữ liệu cục bộ – dùng để phát hiện xung đột khi đồng bộ.
  int _localVersion = 1;
  int get localVersion => _localVersion;

  /// Phiên bản dữ liệu trên server – giả lập.
  int _serverVersion = 1;

  // ────────────────────────────
  // Khởi tạo Database SQLite & Seeding
  // ────────────────────────────

  Future<void> _initLocalDatabase() async {
    if (kIsWeb) return; // Bỏ qua nếu chạy trên Web

    try {
      final db = DatabaseHelper.instance;
      var dbChildren = await db.getAllChildren();
      var dbReports = await db.getAllDiseaseReports();

      if (dbChildren.isEmpty && dbReports.isEmpty) {
        // Database rỗng → Thực hiện Seeding dữ liệu mẫu vào SQLite
        debugPrint("SQLite rỗng. Đang seeding dữ liệu mẫu...");
        
        for (final child in demoChildren) {
          await db.insertChild(child);
          for (final vac in child.vaccinations) {
            await db.insertVaccination(vac);
          }
          for (final med in child.medications) {
            await db.insertMedication(med);
          }
        }
        
        for (final rep in demoDiseaseReports) {
          await db.insertDiseaseReport(rep);
        }

        // Tải lại sau khi seed
        dbChildren = await db.getAllChildren();
        dbReports = await db.getAllDiseaseReports();
      }

      children = dbChildren;
      diseaseReports = dbReports;
      _localVersion = children.length + diseaseReports.length;
      notifyListeners();
      debugPrint("Đã tải dữ liệu thành công từ SQLite.");
    } catch (e) {
      debugPrint("Lỗi khởi tạo SQLite local database: $e");
    }
  }

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

  Future<void> addChild(ChildProfile child) async {
    children.insert(0, child);
    _localVersion++;
    
    if (!kIsWeb) {
      await DatabaseHelper.instance.insertChild(child);
    }
    notifyListeners();
  }

  Future<void> updateChild(ChildProfile child) async {
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1) return;
    children[index] = child;
    _localVersion++;

    if (!kIsWeb) {
      await DatabaseHelper.instance.updateChild(child);
    }
    notifyListeners();
  }

  Future<void> deleteChild(String childId) async {
    children.removeWhere((item) => item.id == childId);
    _localVersion++;

    if (!kIsWeb) {
      await DatabaseHelper.instance.deleteChild(childId);
    }
    notifyListeners();
  }

  Future<void> addVaccination(String childId, VaccinationRecord record) async {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      vaccinations: [...children[index].vaccinations, record],
    );
    _localVersion++;

    if (!kIsWeb) {
      await DatabaseHelper.instance.insertVaccination(record);
    }
    notifyListeners();
  }

  Future<void> addMedication(String childId, MedicationRecord record) async {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      medications: [...children[index].medications, record],
    );
    _localVersion++;

    if (!kIsWeb) {
      await DatabaseHelper.instance.insertMedication(record);
    }
    notifyListeners();
  }

  // ────────────────────────────
  // Quản lý báo cáo dịch tễ
  // ────────────────────────────

  Future<void> addDiseaseReport(DiseaseReport report) async {
    diseaseReports.insert(0, report);
    _localVersion++;

    if (!kIsWeb) {
      await DatabaseHelper.instance.insertDiseaseReport(report);
    }
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
      _serverVersion = _localVersion;
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));

    final db = DatabaseHelper.instance;

    // Đồng bộ bản ghi tiêm chủng
    for (var i = 0; i < children.length; i++) {
      final updatedVaccinations = children[i].vaccinations.map((record) {
        if (record.syncStatus == SyncStatus.pending) {
          if (!kIsWeb) {
            db.updateVaccinationSyncStatus(record.id, SyncStatus.synced.name);
          }
          return record.copyWith(syncStatus: SyncStatus.synced);
        }
        return record;
      }).toList();

      final updatedMedications = children[i].medications.map((record) {
        if (record.syncStatus == SyncStatus.pending) {
          if (!kIsWeb) {
            db.updateMedicationSyncStatus(record.id, SyncStatus.synced.name);
          }
          return record.copyWith(syncStatus: SyncStatus.synced);
        }
        return record;
      }).toList();

      children[i] = children[i].copyWith(
        vaccinations: updatedVaccinations,
        medications: updatedMedications,
      );
    }

    // Đồng bộ báo cáo dịch tễ
    for (var i = 0; i < diseaseReports.length; i++) {
      if (diseaseReports[i].syncStatus == SyncStatus.pending) {
        if (!kIsWeb) {
          await db.updateDiseaseReportSyncStatus(diseaseReports[i].id, SyncStatus.synced.name);
        }
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
