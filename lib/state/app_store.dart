import 'package:flutter/widgets.dart';

import '../data/api/api_client.dart';
import '../data/demo_data.dart';
import '../models/models.dart';
import '../data/sqlite_helper.dart';
import '../services/firebase_sync_service.dart';

class AppStore extends ChangeNotifier {
  AppStore() {
    _initData();
  }

  List<ChildProfile> children = [];
  List<DiseaseReport> diseaseReports = [];
  List<UserModel> users = [];
  List<SystemAuditLog> auditLogs = [];
  List<VaccineSchedule> vaccineSchedules = List<VaccineSchedule>.from(demoSchedules);
  List<MedicationSchedule> medicationSchedules = List<MedicationSchedule>.from(demoMedicationSchedules);
  UserModel? currentUser;
  bool isOnline = false;
  bool isSyncing = false;
  DateTime lastSyncAt = DateTime(2026, 7, 23, 16, 40);

  // Initialize data from SQLite, fallback to demo data if it fails
  Future<void> _initData() async {
    try {
      final dbUsers = await SqliteHelper.instance.getUsers();
      final dbChildren = await SqliteHelper.instance.getChildren();
      final dbReports = await SqliteHelper.instance.getDiseaseReports();
      final dbLogs = await SqliteHelper.instance.getAuditLogs();

      users = dbUsers;
      children = dbChildren;
      diseaseReports = dbReports;
      auditLogs = dbLogs;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data from SQLite: $e');
      // Fallback
      children = List<ChildProfile>.from(demoChildren);
      diseaseReports = List<DiseaseReport>.from(demoDiseaseReports);
      users = List<UserModel>.from(demoUsers);
      auditLogs = List<SystemAuditLog>.from(demoAuditLogs);
      notifyListeners();
    }
  }

  int get pendingCount {
    final pendingVaccines = children
        .expand((child) => child.vaccinations)
        .where((record) => record.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final pendingMedications = children
        .expand((child) => child.medications)
        .where((record) => record.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final pendingDiseaseReports = diseaseReports
        .where((report) => report.syncStatus == VaccinationSyncStatus.pending)
        .length;
    return pendingVaccines + pendingMedications + pendingDiseaseReports;
  }

  int get lateCount => children
      .where((child) => child.status == ChildVaccinationStatus.late)
      .length;

  int get dueSoonCount => children
      .where((child) => child.status == ChildVaccinationStatus.dueSoon)
      .length;

  int get suspectedDiseaseCount => diseaseReports
      .where((r) => r.status == 'Nghi ngờ' || r.status == 'Đã xác minh')
      .length;

  int get pendingUserApprovals =>
      users.where((u) => u.status == UserAccountStatus.pendingApproval).length;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  Future<void> addAuditLog(String action, String details) async {
    final newLog = SystemAuditLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      action: action,
      performedBy: currentUser?.username ?? 'Hệ thống',
      userRole: currentUser?.role == UserRole.admin
          ? 'Quản trị viên'
          : currentUser?.role == UserRole.parent
              ? 'Phụ huynh'
              : 'Cán bộ Y tế',
      timestamp: DateTime.now(),
      details: details,
    );
    auditLogs.insert(0, newLog);
    notifyListeners();

    try {
      await SqliteHelper.instance.insertAuditLog(newLog);
    } catch (e) {
      debugPrint('Error inserting audit log: $e');
    }
  }

  Future<ApiResponse<UserModel>> registerUser({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
    required String password,
    String? assignedCommune,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Check if username or email exists
    final exists = users.any((u) =>
        u.username.toLowerCase() == username.toLowerCase() ||
        u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      return ApiResponse.error(
          400, 'Tên đăng nhập hoặc email đã tồn tại trên hệ thống!');
    }

    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: UserAccountStatus.active,
      createdAt: DateTime.now(),
      assignedCommune: assignedCommune,
      password: password,
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    users.insert(0, newUser);
    notifyListeners();

    try {
      await SqliteHelper.instance.insertUser(newUser);
    } catch (e) {
      debugPrint('Error saving registered user: $e');
    }

    await addAuditLog('Đăng ký tài khoản',
        'Đăng ký tài khoản mới "${newUser.username}" với vai trò ${role.name}');

    return ApiResponse.created(newUser,
        message:
            'Đăng ký tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ.');
  }

  Future<void> approveUser(String userId) async {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    users[index] = u.copyWith(status: UserAccountStatus.active);
    notifyListeners();

    try {
      await SqliteHelper.instance
          .updateUserStatus(userId, UserAccountStatus.active.name);
    } catch (e) {
      debugPrint('Error approving user: $e');
    }

    await addAuditLog('Phê duyệt tài khoản',
        'Admin đã phê duyệt tài khoản Cán bộ Y tế "${u.fullName}" (${u.username})');
  }

  Future<void> rejectUser(String userId) async {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    users.removeAt(index);
    notifyListeners();

    try {
      await SqliteHelper.instance.deleteUser(userId);
    } catch (e) {
      debugPrint('Error rejecting user: $e');
    }

    await addAuditLog('Từ chối tài khoản',
        'Admin đã từ chối đơn đăng ký tài khoản "${u.fullName}" (${u.username})');
  }

  Future<void> toggleUserStatus(String userId) async {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    final newStatus = u.status == UserAccountStatus.active
        ? UserAccountStatus.locked
        : UserAccountStatus.active;
    users[index] = u.copyWith(status: newStatus);
    notifyListeners();

    try {
      await SqliteHelper.instance.updateUserStatus(userId, newStatus.name);
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }

    await addAuditLog('Thay đổi trạng thái tài khoản',
        'Chuyển tài khoản "${u.username}" sang trạng thái ${newStatus.name}');
  }

  Future<void> addChild(ChildProfile child) async {
    children.insert(0, child);
    notifyListeners();

    try {
      await SqliteHelper.instance.insertChild(child);
    } catch (e) {
      debugPrint('Error adding child to SQLite: $e');
    }

    await addAuditLog('Thêm hồ sơ trẻ',
        'Tạo hồ sơ mới cho trẻ "${child.fullName}" tại ${child.village}');
  }

  Future<void> updateChild(ChildProfile child) async {
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1) return;
    children[index] = child;
    notifyListeners();

    try {
      await SqliteHelper.instance.updateChild(child);
    } catch (e) {
      debugPrint('Error updating child in SQLite: $e');
    }

    await addAuditLog(
        'Chỉnh sửa hồ sơ trẻ', 'Cập nhật thông tin trẻ "${child.fullName}"');
  }

  Future<void> deleteChild(String childId) async {
    final childIndex = children.indexWhere((item) => item.id == childId);
    if (childIndex == -1) return;
    final child = children[childIndex];
    children.removeAt(childIndex);
    notifyListeners();

    try {
      await SqliteHelper.instance.deleteChild(childId);
    } catch (e) {
      debugPrint('Error deleting child in SQLite: $e');
    }

    await addAuditLog('Xóa hồ sơ trẻ', 'Đã xóa hồ sơ trẻ "${child.fullName}"');
  }

  Future<void> addVaccination(String childId, VaccinationRecord record) async {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      vaccinations: [...children[index].vaccinations, record],
    );
    notifyListeners();

    try {
      await SqliteHelper.instance.insertVaccination(record);
      await SqliteHelper.instance.updateChild(children[index]);
    } catch (e) {
      debugPrint('Error adding vaccination: $e');
    }

    await addAuditLog(
        'Ghi nhận tiêm chủng', 'Thêm mũi tiêm ${record.vaccineName} cho trẻ');
  }

  Future<void> addMedication(String childId, MedicationRecord record) async {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      medications: [...children[index].medications, record],
    );
    notifyListeners();

    try {
      await SqliteHelper.instance.insertMedication(record);
      await SqliteHelper.instance.updateChild(children[index]);
    } catch (e) {
      debugPrint('Error adding medication: $e');
    }

    await addAuditLog(
        'Ghi nhận thuốc uống', 'Cho trẻ uống bổ sung ${record.medicationName}');
  }

  void addVaccineSchedule(VaccineSchedule schedule) {
    vaccineSchedules.add(schedule);
    addAuditLog('Thêm lịch vaccine', 'Thêm vaccine "${schedule.vaccineName}" Mũi ${schedule.doseNumber} vào danh mục chuẩn');
    notifyListeners();
  }

  void addMedicationSchedule(MedicationSchedule schedule) {
    medicationSchedules.add(schedule);
    addAuditLog('Thêm danh mục thuốc uống', 'Thêm "${schedule.medicationName}" vào danh mục thuốc uống & bổ sung');
    notifyListeners();
  }

  Future<void> addDiseaseReport(DiseaseReport report) async {
    diseaseReports.insert(0, report);
    notifyListeners();

    try {
      await SqliteHelper.instance.insertDiseaseReport(report);
    } catch (e) {
      debugPrint('Error adding disease report: $e');
    }

    await addAuditLog('Khai báo dịch bệnh',
        'Báo cáo ca bệnh nghi ngờ ${report.diseaseType} tại ${report.village}');
  }

  Future<void> updateDiseaseReportStatus(
      String reportId, String newStatus) async {
    final index = diseaseReports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;
    diseaseReports[index] = diseaseReports[index].copyWith(status: newStatus);
    notifyListeners();

    try {
      await SqliteHelper.instance
          .updateDiseaseReportStatus(reportId, newStatus);
    } catch (e) {
      debugPrint('Error updating disease report status: $e');
    }

    await addAuditLog('Cập nhật khoanh vùng dịch',
        'Chuyển trạng thái ca bệnh ${diseaseReports[index].diseaseType} sang "$newStatus"');
  }

  Future<void> syncPending() async {
    if (!isOnline || pendingCount == 0) return;
    isSyncing = true;
    notifyListeners();

    try {
      // Find and sync pending vaccinations
      for (var child in children) {
        for (var record in child.vaccinations) {
          if (record.syncStatus == VaccinationSyncStatus.pending) {
            final success = await FirebaseSyncService.instance
                .syncVaccinationRecord(record);
            if (success) {
              await SqliteHelper.instance.updateVaccinationSyncStatus(
                  record.id, VaccinationSyncStatus.synced.name);
            }
          }
        }
        for (var record in child.medications) {
          if (record.syncStatus == VaccinationSyncStatus.pending) {
            // Simulated local sync update for medication records
            await SqliteHelper.instance.updateMedicationSyncStatus(
                record.id, VaccinationSyncStatus.synced.name);
          }
        }
      }

      // Find and sync pending disease reports
      for (var report in diseaseReports) {
        if (report.syncStatus == VaccinationSyncStatus.pending) {
          final success =
              await FirebaseSyncService.instance.syncDiseaseReport(report);
          if (success) {
            await SqliteHelper.instance.updateDiseaseReportSyncStatus(
                report.id, VaccinationSyncStatus.synced.name);
          }
        }
      }

      // Reload lists from SQLite database to pick up updated sync statuses
      final dbChildren = await SqliteHelper.instance.getChildren();
      final dbReports = await SqliteHelper.instance.getDiseaseReports();

      children = dbChildren;
      diseaseReports = dbReports;

      lastSyncAt = DateTime.now();
      await addAuditLog('Đồng bộ dữ liệu',
          'Đồng bộ thành công dữ liệu ngoại tuyến lên Firestore Server');
    } catch (e) {
      debugPrint('Error syncing data: $e');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
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
