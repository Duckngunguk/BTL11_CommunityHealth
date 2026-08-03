import 'package:flutter/widgets.dart';

import '../data/api/api_client.dart';
import '../data/demo_data.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  AppStore()
      : children = List<ChildProfile>.from(demoChildren),
        diseaseReports = List<DiseaseReport>.from(demoDiseaseReports),
        users = List<UserModel>.from(demoUsers),
        auditLogs = List<SystemAuditLog>.from(demoAuditLogs),
        vaccineSchedules = List<VaccineSchedule>.from(demoSchedules),
        medicationSchedules = List<MedicationSchedule>.from(demoMedicationSchedules),
        lastSyncAt = DateTime(2026, 7, 23, 16, 40);

  final List<ChildProfile> children;
  final List<DiseaseReport> diseaseReports;
  final List<UserModel> users;
  final List<SystemAuditLog> auditLogs;
  final List<VaccineSchedule> vaccineSchedules;
  final List<MedicationSchedule> medicationSchedules;
  
  UserModel? currentUser;
  bool isOnline = false;
  bool isSyncing = false;
  DateTime lastSyncAt;

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

  int get pendingUserApprovals => users
      .where((u) => u.status == UserAccountStatus.pendingApproval)
      .length;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void addAuditLog(String action, String details) {
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
    final exists = users.any((u) => u.username.toLowerCase() == username.toLowerCase() || u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      return ApiResponse.error(400, 'Tên đăng nhập hoặc email đã tồn tại trên hệ thống!');
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
    addAuditLog('Đăng ký tài khoản', 'Đăng ký tài khoản mới "${newUser.username}" với vai trò ${role.name}');
    notifyListeners();

    return ApiResponse.created(newUser, message: 'Đăng ký tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ.');
  }

  void approveUser(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    users[index] = u.copyWith(status: UserAccountStatus.active);
    addAuditLog('Phê duyệt tài khoản', 'Admin đã phê duyệt tài khoản Cán bộ Y tế "${u.fullName}" (${u.username})');
    notifyListeners();
  }

  void rejectUser(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    users.removeAt(index);
    addAuditLog('Từ chối tài khoản', 'Admin đã từ chối đơn đăng ký tài khoản "${u.fullName}" (${u.username})');
    notifyListeners();
  }

  void toggleUserStatus(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    final newStatus = u.status == UserAccountStatus.active ? UserAccountStatus.locked : UserAccountStatus.active;
    users[index] = u.copyWith(status: newStatus);
    addAuditLog('Thay đổi trạng thái tài khoản', 'Chuyển tài khoản "${u.username}" sang trạng thái ${newStatus.name}');
    notifyListeners();
  }

  void addChild(ChildProfile child) {
    children.insert(0, child);
    addAuditLog('Thêm hồ sơ trẻ', 'Tạo hồ sơ mới cho trẻ "${child.fullName}" tại ${child.village}');
    notifyListeners();
  }

  void updateChild(ChildProfile child) {
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1) return;
    children[index] = child;
    addAuditLog('Chỉnh sửa hồ sơ trẻ', 'Cập nhật thông tin trẻ "${child.fullName}"');
    notifyListeners();
  }

  void deleteChild(String childId) {
    final child = children.firstWhere((item) => item.id == childId);
    children.removeWhere((item) => item.id == childId);
    addAuditLog('Xóa hồ sơ trẻ', 'Đã xóa hồ sơ trẻ "${child.fullName}"');
    notifyListeners();
  }

  void addVaccination(String childId, VaccinationRecord record) {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      vaccinations: [...children[index].vaccinations, record],
    );
    addAuditLog('Ghi nhận tiêm chủng', 'Thêm mũi tiêm ${record.vaccineName} cho trẻ');
    notifyListeners();
  }

  void addMedication(String childId, MedicationRecord record) {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      medications: [...children[index].medications, record],
    );
    addAuditLog('Ghi nhận thuốc uống', 'Cho trẻ uống bổ sung ${record.medicationName}');
    notifyListeners();
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

  void addDiseaseReport(DiseaseReport report) {
    diseaseReports.insert(0, report);
    addAuditLog('Khai báo dịch bệnh', 'Báo cáo ca bệnh nghi ngờ ${report.diseaseType} tại ${report.village}');
    notifyListeners();
  }

  void updateDiseaseReportStatus(String reportId, String newStatus) {
    final index = diseaseReports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;
    diseaseReports[index] = diseaseReports[index].copyWith(status: newStatus);
    addAuditLog('Cập nhật khoanh vùng dịch', 'Chuyển trạng thái ca bệnh ${diseaseReports[index].diseaseType} sang "$newStatus"');
    notifyListeners();
  }

  Future<void> syncPending() async {
    if (!isOnline || pendingCount == 0) return;
    isSyncing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    for (var i = 0; i < children.length; i++) {
      final updatedVaccinations = children[i].vaccinations.map((record) {
        return record.syncStatus == VaccinationSyncStatus.pending
            ? record.copyWith(syncStatus: VaccinationSyncStatus.synced)
            : record;
      }).toList();

      final updatedMedications = children[i].medications.map((record) {
        return record.syncStatus == VaccinationSyncStatus.pending
            ? record.copyWith(syncStatus: VaccinationSyncStatus.synced)
            : record;
      }).toList();

      children[i] = children[i].copyWith(
        vaccinations: updatedVaccinations,
        medications: updatedMedications,
      );
    }

    for (var i = 0; i < diseaseReports.length; i++) {
      if (diseaseReports[i].syncStatus == VaccinationSyncStatus.pending) {
        diseaseReports[i] = diseaseReports[i].copyWith(syncStatus: VaccinationSyncStatus.synced);
      }
    }

    lastSyncAt = DateTime.now();
    isSyncing = false;
    addAuditLog('Đồng bộ dữ liệu', 'Đồng bộ thành công dữ liệu ngoại tuyến lên Firestore Server');
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

