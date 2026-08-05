import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import '../data/demo_data.dart';
import '../models/models.dart';
import '../data/sqlite_helper.dart';
import '../services/firebase_sync_service.dart';

class AppStore extends ChangeNotifier {
  AppStore() {
    _initData();
    _initConnectivity();
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      setOnline(hasConnection);
      if (hasConnection && pendingCount > 0) {
        debugPrint('📶 Connection restored! Auto-triggering pending sync...');
        syncPending();
      }
    });
  }

  final _secureStorage = const FlutterSecureStorage();

  List<ChildProfile> children = [];
  List<DiseaseReport> diseaseReports = [];
  List<UserModel> users = [];
  List<SystemAuditLog> auditLogs = [];
  List<VaccineSchedule> vaccineSchedules = List<VaccineSchedule>.from(demoSchedules);
  List<MedicationSchedule> medicationSchedules = List<MedicationSchedule>.from(demoMedicationSchedules);
  
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? value) {
    _currentUser = value;
    if (value != null && value.token != null) {
      _secureStorage.write(key: 'auth_token', value: value.token!);
      debugPrint('🔒 Token stored in Secure Storage: ${value.token}');
    } else {
      _secureStorage.delete(key: 'auth_token');
      debugPrint('🔒 Token cleared from Secure Storage');
    }
    notifyListeners();
  }

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

      // Try loading securely stored token on startup
      final storedToken = await _secureStorage.read(key: 'auth_token');
      if (storedToken != null) {
        debugPrint('🔒 Stored Token found in Secure Storage: $storedToken');
        final matchingUser = users.where((u) => u.token == storedToken).firstOrNull;
        if (matchingUser != null) {
          _currentUser = matchingUser;
          debugPrint('🔒 Auto-logged in user: ${_currentUser?.username}');
        }
      }

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

    final initialStatus = role == UserRole.healthWorker
        ? UserAccountStatus.pendingApproval
        : UserAccountStatus.active;

    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: initialStatus,
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

    final successMsg = role == UserRole.healthWorker
        ? 'Đăng ký tài khoản Cán bộ Y tế thành công! Tài khoản đang ở trạng thái Chờ phê duyệt từ Quản trị viên (Admin).'
        : 'Đăng ký tài khoản Phụ huynh thành công! Bạn có thể đăng nhập ngay bây giờ.';

    return ApiResponse.created(newUser, message: successMsg);
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
      // 1. Gather all pending vaccination records across all children
      final pendingVaccinations = children
          .expand((child) => child.vaccinations)
          .where((v) => v.syncStatus == VaccinationSyncStatus.pending)
          .toList();

      if (pendingVaccinations.isNotEmpty) {
        final batch = SyncBatch(
          id: 'BATCH-${DateTime.now().millisecondsSinceEpoch}',
          deviceId: 'device-sapa-01',
          healthworkerId: currentUser?.id ?? 'worker-anonymous',
          vaccinationIds: pendingVaccinations.map((v) => v.id).toList(),
          status: SyncBatchStatus.uploaded,
          uploadedAt: DateTime.now(),
        );

        // Save batch log to SQLite
        await SqliteHelper.instance.insertSyncBatch(batch);

        // Upload batch metadata and records to Firestore atomically
        final batchSuccess = await FirebaseSyncService.instance
            .syncBatchUpload(batch, pendingVaccinations);

        if (batchSuccess) {
          // Update SQLite records
          for (var record in pendingVaccinations) {
            await SqliteHelper.instance.updateVaccinationSyncStatus(
                record.id, VaccinationSyncStatus.synced.name);
          }
          
          // Mark batch as processed
          final processedBatch = SyncBatch(
            id: batch.id,
            deviceId: batch.deviceId,
            healthworkerId: batch.healthworkerId,
            vaccinationIds: batch.vaccinationIds,
            status: SyncBatchStatus.processed,
            uploadedAt: batch.uploadedAt,
          );
          await SqliteHelper.instance.updateSyncBatch(processedBatch);
          debugPrint('SyncBatch ${batch.id} completed and updated to SQLite.');
        } else {
          // Mark batch as error
          final errorBatch = SyncBatch(
            id: batch.id,
            deviceId: batch.deviceId,
            healthworkerId: batch.healthworkerId,
            vaccinationIds: batch.vaccinationIds,
            status: SyncBatchStatus.error,
            uploadedAt: batch.uploadedAt,
            errorMessage: 'Firestore transaction batch commit failed.',
          );
          await SqliteHelper.instance.updateSyncBatch(errorBatch);
          throw Exception('Failed to upload sync batch.');
        }
      }

      // 2. Simulated sync for pending medications
      for (var child in children) {
        for (var record in child.medications) {
          if (record.syncStatus == VaccinationSyncStatus.pending) {
            await SqliteHelper.instance.updateMedicationSyncStatus(
                record.id, VaccinationSyncStatus.synced.name);
          }
        }
      }

      // 3. Sync pending disease reports
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

  // SQLite FTS Offline Search
  Future<void> searchChildren(String query) async {
    try {
      final results = await SqliteHelper.instance.searchChildrenOffline(query);
      children = results;
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching children offline: $e');
    }
  }
}

final appStoreProvider = ChangeNotifierProvider<AppStore>((ref) {
  return AppStore();
});

class _AppScopeInherited extends InheritedNotifier<AppStore> {
  const _AppScopeInherited({
    required super.notifier,
    required super.child,
  });
}

class AppScope extends ConsumerWidget {
  const AppScope({
    super.key,
    required this.child,
    this.notifier,
  });

  final Widget child;
  final AppStore? notifier;

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScopeInherited>();
    assert(scope != null, 'Không tìm thấy AppScope trong widget tree.');
    return scope!.notifier!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = notifier ?? ref.watch(appStoreProvider);
    return _AppScopeInherited(
      notifier: store,
      child: child,
    );
  }
}
