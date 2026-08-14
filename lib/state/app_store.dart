import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import '../data/master_data.dart';
import '../models/models.dart';
import '../data/sqlite_helper.dart';
import '../services/firebase_sync_service.dart';
import '../services/google_auth_service.dart';
import '../utils/id_generator.dart';
import '../utils/password_hasher.dart';

class AppStore extends ChangeNotifier {
  AppStore() {
    ready = _initData().whenComplete(() {
      isInitializing = false;
      notifyListeners();
      if (isOnline &&
          pendingCount > 0 &&
          currentUser?.role != UserRole.parent) {
        syncPending();
      }
    });
    _initConnectivity();
  }

  AppStore.forTesting({
    List<UserModel>? initialUsers,
    List<ChildProfile>? initialChildren,
    List<DiseaseReport>? initialDiseaseReports,
    UserModel? initialCurrentUser,
  }) {
    _isTesting = true;
    _cloudDataDirty = false;
    users = List<UserModel>.from(initialUsers ?? demoUsers);
    children = List<ChildProfile>.from(initialChildren ?? demoChildren);
    diseaseReports =
        List<DiseaseReport>.from(initialDiseaseReports ?? const []);
    _currentUser = initialCurrentUser;
    isInitializing = false;
    ready = Future<void>.value();
  }

  late final Future<void> ready;
  bool isInitializing = true;
  bool _isTesting = false;

  Future<void> _initConnectivity() async {
    try {
      final initialResults = await Connectivity().checkConnectivity();
      final initiallyOnline =
          initialResults.any((result) => result != ConnectivityResult.none);
      setOnline(initiallyOnline);
      if (!isInitializing &&
          initiallyOnline &&
          pendingCount > 0 &&
          currentUser?.role != UserRole.parent) {
        await syncPending();
      }
    } catch (e) {
      debugPrint('Unable to determine initial connectivity: $e');
    }

    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection =
          results.any((result) => result != ConnectivityResult.none);
      setOnline(hasConnection);
      if (!isInitializing &&
          hasConnection &&
          currentUser?.role == UserRole.parent) {
        refreshFromCloud();
      } else if (!isInitializing && hasConnection && pendingCount > 0) {
        debugPrint('Connection restored; syncing pending data...');
        syncPending();
      }
    });
  }

  final _secureStorage = const FlutterSecureStorage();

  List<ChildProfile> children = [];
  List<DiseaseReport> diseaseReports = [];
  List<UserModel> users = [];
  List<SystemAuditLog> auditLogs = [];
  List<VaccineSchedule> vaccineSchedules =
      List<VaccineSchedule>.from(demoSchedules);
  List<MedicationSchedule> medicationSchedules =
      List<MedicationSchedule>.from(demoMedicationSchedules);
  List<VaccinePlan> vaccinePlans = [];
  double districtCoverageTarget = 80.0;

  static const _childrenStorageKey = 'storage_children';
  static const _diseaseReportsStorageKey = 'storage_disease_reports';
  static const _auditLogsStorageKey = 'storage_audit_logs';
  static const _syncStateStorageKey = 'storage_sync_state';

  bool _cloudDataDirty = false;
  final Set<String> _pendingDeletedChildIds = <String>{};
  final Map<String, String> _pendingDeletedChildCommunes = <String, String>{};

  bool get isCloudConnected => FirebaseSyncService.instance.isInitialized;
  String? get cloudSyncError => FirebaseSyncService.instance.lastError;
  bool isRefreshingFromCloud = false;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? value) {
    _currentUser = value;
    if (_isTesting) {
      notifyListeners();
      return;
    }
    if (value != null && value.token != null) {
      _secureStorage.write(key: 'auth_token', value: value.token!);
      debugPrint('🔒 Session token stored in Secure Storage');
    } else {
      _secureStorage.delete(key: 'auth_token');
      debugPrint('🔒 Token cleared from Secure Storage');
    }
    notifyListeners();
  }

  bool isOnline = false;
  bool isSyncing = false;
  DateTime lastSyncAt = DateTime(2026, 7, 23, 16, 40);

  List<ChildProfile> get currentUserChildren {
    final user = currentUser;
    if (user == null) return const [];
    if (user.role == UserRole.admin) return children;
    if (user.role == UserRole.healthWorker) {
      final commune = currentHealthWorkerCommune;
      if (commune == null) return const [];
      return children
          .where((child) => _sameCommune(child.commune, commune))
          .toList(growable: false);
    }

    final linkedIds = user.linkedChildIds.toSet();
    final parentPhone = _normalizePhone(user.phone);
    return children
        .where(
          (child) =>
              linkedIds.contains(child.id) ||
              (parentPhone.isNotEmpty &&
                  _normalizePhone(child.motherPhone) == parentPhone),
        )
        .toList(growable: false);
  }

  bool canCurrentUserAccessChild(String childId) {
    return currentUserChildren.any((child) => child.id == childId);
  }

  String? get currentHealthWorkerCommune {
    final user = currentUser;
    if (user?.role != UserRole.healthWorker) return null;
    final commune = user?.assignedCommune?.trim();
    return commune == null || commune.isEmpty ? null : commune;
  }

  List<DiseaseReport> get currentUserDiseaseReports {
    final user = currentUser;
    if (user == null) return const [];
    if (user.role == UserRole.admin) return diseaseReports;
    if (user.role != UserRole.healthWorker) return const [];
    final commune = currentHealthWorkerCommune;
    if (commune == null) return const [];
    return diseaseReports
        .where((report) => _sameCommune(report.commune, commune))
        .toList(growable: false);
  }

  List<VaccinePlan> get currentUserVaccinePlans {
    final user = currentUser;
    if (user == null) return const [];
    if (user.role == UserRole.admin) return vaccinePlans;
    if (user.role != UserRole.healthWorker) return const [];
    final commune = currentHealthWorkerCommune;
    if (commune == null) return const [];
    return vaccinePlans
        .where((plan) => _sameCommune(plan.communeName, commune))
        .toList(growable: false);
  }

  bool _canHealthWorkerAccessCommune(String commune) {
    final assignedCommune = currentHealthWorkerCommune;
    return assignedCommune != null && _sameCommune(commune, assignedCommune);
  }

  static bool _sameCommune(String left, String right) =>
      left.trim().toLowerCase() == right.trim().toLowerCase();

  static String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Giữ tài khoản Admin cấu hình trong mã nguồn nhất quán trên SQLite,
  /// Secure Storage và dữ liệu lấy về từ Firestore của các bản cũ.
  bool _ensureConfiguredAdminAccount() {
    final configuredAdmin = demoUsers.firstWhere(
      (user) => user.id == defaultAdminId,
    );
    final index = users.indexWhere(
      (user) => user.id == defaultAdminId || user.role == UserRole.admin,
    );
    if (index == -1) {
      users.insert(0, configuredAdmin);
      return true;
    }

    final currentAdmin = users[index];
    if (currentAdmin.username.toLowerCase() == defaultAdminEmail &&
        currentAdmin.email.toLowerCase() == defaultAdminEmail) {
      return false;
    }
    users[index] = currentAdmin.copyWith(
      username: defaultAdminEmail,
      email: defaultAdminEmail,
    );
    return true;
  }

  // Initialize data from SQLite, fallback to empty data if it fails
  Future<void> _initData() async {
    // Load local schedules and plans from secure storage first
    await _loadSchedules();
    await _loadPlans();
    await _loadSettings();
    await _loadSyncState();

    try {
      final dbUsers = await SqliteHelper.instance.getUsers();
      final dbChildren = await SqliteHelper.instance.getChildren();
      final dbReports = await SqliteHelper.instance.getDiseaseReports();
      final dbLogs = await SqliteHelper.instance.getAuditLogs();

      users = dbUsers;
      children = dbChildren;
      diseaseReports = dbReports;
      auditLogs = dbLogs;

      // Local data is loaded first. Firestore is applied last so an old
      // browser/device snapshot cannot overwrite a newly synchronized record.
      await _loadCoreDataFromStorage();
      await syncFromStorage();
      _ensureConfiguredAdminAccount();
      if (children.isEmpty) {
        children = List<ChildProfile>.from(demoChildren);
      }

      // Restore the session before deciding how cloud data should be merged.
      // In particular, a parent device must pull instead of uploading an old
      // local snapshot left by a previous application version.
      final storedToken = await _secureStorage.read(key: 'auth_token');
      if (storedToken != null) {
        debugPrint('🔒 Stored Token found in Secure Storage: $storedToken');
        final matchingUser =
            users.where((u) => u.token == storedToken).firstOrNull;
        if (matchingUser != null) {
          _currentUser = matchingUser;
          debugPrint('🔒 Auto-logged in user: ${_currentUser?.username}');
        }
      }

      if (kIsWeb || isOnline) {
        await refreshFromCloud(notify: false);
      }

      // Seed/update the cross-platform snapshot after a successful startup.
      await _saveCoreDataToStorage();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data from SQLite: $e');
      // Fallback: only demo users for login, everything else starts empty
      children = List<ChildProfile>.from(demoChildren);
      diseaseReports = [];
      users = List<UserModel>.from(demoUsers);
      auditLogs = [];
      await _loadCoreDataFromStorage();
      await syncFromStorage();
      _ensureConfiguredAdminAccount();

      // Reload schedules and plans in fallback
      await _loadSchedules();
      await _loadPlans();
      await _loadSettings();
      await _loadSyncState();

      notifyListeners();
    }
  }

  Future<void> _loadCoreDataFromStorage() async {
    try {
      final childrenJson = await _secureStorage.read(key: _childrenStorageKey);
      if (childrenJson != null && childrenJson.isNotEmpty) {
        final raw = jsonDecode(childrenJson) as List;
        children = raw
            .map((item) => ChildProfile.fromStorageMap(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }

      final reportsJson =
          await _secureStorage.read(key: _diseaseReportsStorageKey);
      if (reportsJson != null && reportsJson.isNotEmpty) {
        final raw = jsonDecode(reportsJson) as List;
        diseaseReports = raw
            .map((item) => DiseaseReport.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }

      final logsJson = await _secureStorage.read(key: _auditLogsStorageKey);
      if (logsJson != null && logsJson.isNotEmpty) {
        final raw = jsonDecode(logsJson) as List;
        auditLogs = raw
            .map((item) => SystemAuditLog.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading persistent application data: $e');
    }
  }

  Future<void> _saveCoreDataToStorage() async {
    if (_isTesting) return;
    try {
      await Future.wait([
        _secureStorage.write(
          key: _childrenStorageKey,
          value: jsonEncode(
            children.map((child) => child.toStorageMap()).toList(),
          ),
        ),
        _secureStorage.write(
          key: _diseaseReportsStorageKey,
          value: jsonEncode(
            diseaseReports.map((report) => report.toMap()).toList(),
          ),
        ),
        _secureStorage.write(
          key: _auditLogsStorageKey,
          value: jsonEncode(auditLogs.map((log) => log.toMap()).toList()),
        ),
      ]);
    } catch (e) {
      debugPrint('Error saving persistent application data: $e');
    }
  }

  Future<void> _loadSyncState() async {
    if (_isTesting) return;
    try {
      final jsonStr = await _secureStorage.read(key: _syncStateStorageKey);
      if (jsonStr == null || jsonStr.isEmpty) return;
      final map = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
      _cloudDataDirty = map['cloudDataDirty'] as bool? ?? false;
      _pendingDeletedChildIds
        ..clear()
        ..addAll(
          ((map['pendingDeletedChildIds'] as List?) ?? const [])
              .map((id) => id.toString()),
        );
      _pendingDeletedChildCommunes
        ..clear()
        ..addAll(
          ((map['pendingDeletedChildCommunes'] as Map?) ?? const {}).map(
              (id, commune) => MapEntry(id.toString(), commune.toString())),
        );
    } catch (e) {
      _cloudDataDirty = false;
      debugPrint('Error loading sync state: $e');
    }
  }

  Future<void> _saveSyncState() async {
    if (_isTesting) return;
    try {
      await _secureStorage.write(
        key: _syncStateStorageKey,
        value: jsonEncode({
          'cloudDataDirty': _cloudDataDirty,
          'pendingDeletedChildIds': _pendingDeletedChildIds.toList(),
          'pendingDeletedChildCommunes': _pendingDeletedChildCommunes,
        }),
      );
    } catch (e) {
      debugPrint('Error saving sync state: $e');
    }
  }

  Future<void> _markCloudDataDirty() async {
    _cloudDataDirty = true;
    await _saveSyncState();
  }

  Future<void> _loadSchedules() async {
    try {
      final vacsJson =
          await _secureStorage.read(key: 'storage_vaccine_schedules');
      if (vacsJson != null && vacsJson.isNotEmpty) {
        final List raw = jsonDecode(vacsJson) as List;
        vaccineSchedules = raw
            .map((item) =>
                VaccineSchedule.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
      final medsJson =
          await _secureStorage.read(key: 'storage_medication_schedules');
      if (medsJson != null && medsJson.isNotEmpty) {
        final List raw = jsonDecode(medsJson) as List;
        medicationSchedules = raw
            .map((item) =>
                MedicationSchedule.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading schedules from storage: $e');
    }
  }

  Future<void> _saveSchedulesToStorage() async {
    try {
      final vacsJson =
          jsonEncode(vaccineSchedules.map((e) => e.toMap()).toList());
      final medsJson =
          jsonEncode(medicationSchedules.map((e) => e.toMap()).toList());
      await _secureStorage.write(
          key: 'storage_vaccine_schedules', value: vacsJson);
      await _secureStorage.write(
          key: 'storage_medication_schedules', value: medsJson);
    } catch (e) {
      debugPrint('Error saving schedules to storage: $e');
    }
  }

  Future<void> _loadPlans() async {
    try {
      final jsonStr = await _secureStorage.read(key: 'storage_vaccine_plans');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List raw = jsonDecode(jsonStr) as List;
        vaccinePlans = raw.map((item) {
          final map = Map<String, dynamic>.from(item);
          final rawDoses = map['estimatedDoses'] as Map;
          return VaccinePlan(
            id: map['id'] as String,
            communeName: map['communeName'] as String,
            date: DateTime.parse(map['date'] as String),
            location: map['location'] as String,
            workerName: map['workerName'] as String,
            estimatedDoses: rawDoses
                .map((k, v) => MapEntry(k as String, (v as num).toInt())),
            createdAt: DateTime.parse(map['createdAt'] as String),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading plans from storage: $e');
    }
  }

  Future<void> _savePlansToStorage() async {
    try {
      final jsonList = vaccinePlans
          .map((p) => {
                'id': p.id,
                'communeName': p.communeName,
                'date': p.date.toIso8601String(),
                'location': p.location,
                'workerName': p.workerName,
                'estimatedDoses': p.estimatedDoses,
                'createdAt': p.createdAt.toIso8601String(),
              })
          .toList();
      await _secureStorage.write(
          key: 'storage_vaccine_plans', value: jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving plans to storage: $e');
    }
  }

  Future<void> addVaccinePlan(VaccinePlan plan) async {
    if (currentUser?.role != UserRole.admin) return;
    vaccinePlans.insert(0, plan);
    notifyListeners();
    await _savePlansToStorage();

    final dateStr =
        '${plan.date.day.toString().padLeft(2, '0')}/${plan.date.month.toString().padLeft(2, '0')}/${plan.date.year}';
    await addAuditLog('Lập kế hoạch tiêm chủng',
        'Tạo kế hoạch tiêm chủng tại xã ${plan.communeName} ngày $dateStr');
  }

  Future<void> _loadSettings() async {
    try {
      final targetStr =
          await _secureStorage.read(key: 'settings_coverage_target');
      if (targetStr != null) {
        districtCoverageTarget = double.tryParse(targetStr) ?? 80.0;
      }
    } catch (e) {
      debugPrint('Error loading settings from storage: $e');
    }
  }

  Future<void> updateCoverageTarget(double val) async {
    districtCoverageTarget = val;
    notifyListeners();
    try {
      await _secureStorage.write(
          key: 'settings_coverage_target', value: val.toString());
      await addAuditLog('Thay đổi cấu hình',
          'Cập nhật chỉ tiêu bao phủ vắc-xin toàn huyện thành ${val.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('Error saving settings to storage: $e');
    }
  }

  List<CommuneCoverage> get communeCoverage {
    final list = <CommuneCoverage>[];
    final communes = [
      'Tả Phìn',
      'Hầu Thào',
      'San Sả Hồ',
      'Tả Van',
      'Lao Chải',
      'Bản Hồ'
    ];

    for (var name in communes) {
      final communeChildren = children.where((c) => c.commune == name).toList();
      final total = communeChildren.length;

      final fully = communeChildren
          .where((c) => c.status == ChildVaccinationStatus.complete)
          .length;
      final coverage = total > 0 ? (fully / total * 100.0) : 0.0;

      int bcg = 0;
      int dpt1 = 0;
      int dpt2 = 0;
      int dpt3 = 0;

      for (var c in communeChildren) {
        final vacNames =
            c.vaccinations.map((v) => v.vaccineName.toLowerCase()).toList();
        if (vacNames.any((v) => v.contains('bcg'))) {
          bcg++;
        }
        if (vacNames.any((v) => v.contains('dpt 1') || v.contains('dpt1'))) {
          dpt1++;
        }
        if (vacNames.any((v) => v.contains('dpt 2') || v.contains('dpt2'))) {
          dpt2++;
        }
        if (vacNames.any((v) => v.contains('dpt 3') || v.contains('dpt3'))) {
          dpt3++;
        }
      }

      list.add(CommuneCoverage(
        name: name,
        total: total,
        fully: fully,
        coverage: coverage,
        bcg: total > 0 ? ((bcg / total) * 100.0).round() : 0,
        dpt1: total > 0 ? ((dpt1 / total) * 100.0).round() : 0,
        dpt2: total > 0 ? ((dpt2 / total) * 100.0).round() : 0,
        dpt3: total > 0 ? ((dpt3 / total) * 100.0).round() : 0,
      ));
    }

    return list;
  }

  int get pendingCount {
    final scopedChildren = currentUserChildren;
    final scopedReports = currentUserDiseaseReports;
    final pendingVaccines = scopedChildren
        .expand((child) => child.vaccinations)
        .where((record) => record.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final pendingMedications = scopedChildren
        .expand((child) => child.medications)
        .where((record) => record.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final pendingDiseaseReports = scopedReports
        .where((report) => report.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final pendingCloudChanges = _cloudDataDirty ? 1 : 0;
    final pendingDeletions = currentUser?.role == UserRole.admin
        ? _pendingDeletedChildIds.length
        : currentUser?.role == UserRole.healthWorker
            ? _pendingDeletedChildIds.where((childId) {
                final commune = _pendingDeletedChildCommunes[childId];
                return commune != null &&
                    _canHealthWorkerAccessCommune(commune);
              }).length
            : 0;
    return pendingVaccines +
        pendingMedications +
        pendingDiseaseReports +
        pendingCloudChanges +
        pendingDeletions;
  }

  int get lateCount => currentUserChildren
      .where((child) => child.status == ChildVaccinationStatus.late)
      .length;

  int get dueSoonCount => currentUserChildren
      .where((child) => child.status == ChildVaccinationStatus.dueSoon)
      .length;

  int get suspectedDiseaseCount => currentUserDiseaseReports
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
    await _saveCoreDataToStorage();

    try {
      await SqliteHelper.instance.insertAuditLog(newLog);
    } catch (e) {
      debugPrint('Error inserting audit log: $e');
    }

    try {
      final synced = await FirebaseSyncService.instance.syncAuditLog(newLog);
      if (!synced) await _markCloudDataDirty();
    } catch (e) {
      debugPrint('Error syncing audit log to Firestore: $e');
    }
  }

  Future<ApiResponse<UserModel>> authenticate({
    required String email,
    required String password,
  }) async {
    await ready;
    _ensureConfiguredAdminAccount();
    final normalizedEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      return ApiResponse.error(422, 'Vui lòng nhập một địa chỉ email hợp lệ.');
    }
    final index = users.indexWhere(
      (user) => user.email.trim().toLowerCase() == normalizedEmail,
    );
    if (index == -1) {
      return ApiResponse.error(404, 'Email không tồn tại trong hệ thống.');
    }

    final user = users[index];
    final storedHash = user.passwordHash;
    if (storedHash == null || !PasswordHasher.verify(password, storedHash)) {
      return ApiResponse.error(401, 'Mật khẩu không chính xác.');
    }
    if (user.status == UserAccountStatus.pendingApproval) {
      return ApiResponse.error(
        403,
        'Tài khoản đang chờ quản trị viên phê duyệt.',
      );
    }
    if (user.status == UserAccountStatus.rejected) {
      return ApiResponse.error(
        403,
        'Yêu cầu đăng ký tài khoản đã bị quản trị viên từ chối.',
      );
    }
    if (user.status == UserAccountStatus.locked) {
      return ApiResponse.error(
        423,
        'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
      );
    }

    final sessionUser = user.copyWith(
      token: IdGenerator.uuidV4(prefix: 'SESSION'),
      passwordHash: PasswordHasher.hash(password),
    );
    users[index] = sessionUser;
    currentUser = sessionUser;
    if (!_isTesting) {
      await SqliteHelper.instance.updateUserSession(sessionUser);
      await _saveUsersToStorage();
      await addAuditLog('Đăng nhập hệ thống', 'Đăng nhập thành công');
    }
    return ApiResponse.ok(sessionUser, message: 'Đăng nhập thành công.');
  }

  Future<ApiResponse<UserModel>> authenticateWithGoogle() async {
    await ready;

    try {
      final credential = await GoogleAuthService.instance.signIn();
      final googleUser = credential.user;
      final email = googleUser?.email?.trim().toLowerCase();
      if (googleUser == null || email == null || email.isEmpty) {
        await GoogleAuthService.instance.signOut();
        return ApiResponse.error(
          422,
          'Tài khoản Google không cung cấp địa chỉ email.',
        );
      }

      final existingIndex = users.indexWhere(
        (user) => user.email.trim().toLowerCase() == email,
      );
      UserModel account;

      if (existingIndex != -1) {
        account = users[existingIndex];
        if (account.status == UserAccountStatus.pendingApproval) {
          await GoogleAuthService.instance.signOut();
          return ApiResponse.error(
            403,
            'Tài khoản đang chờ quản trị viên phê duyệt.',
          );
        }
        if (account.status == UserAccountStatus.rejected) {
          await GoogleAuthService.instance.signOut();
          return ApiResponse.error(
            403,
            'Yêu cầu đăng ký tài khoản đã bị quản trị viên từ chối.',
          );
        }
        if (account.status == UserAccountStatus.locked) {
          await GoogleAuthService.instance.signOut();
          return ApiResponse.error(
            423,
            'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
          );
        }
      } else {
        final baseUsername = email.split('@').first;
        final usernameExists = users.any(
          (user) => user.username.toLowerCase() == baseUsername.toLowerCase(),
        );
        final uidSuffix = googleUser.uid.length > 6
            ? googleUser.uid.substring(0, 6)
            : googleUser.uid;
        account = UserModel(
          id: 'GOOGLE-${googleUser.uid}',
          username:
              usernameExists ? '${baseUsername}_$uidSuffix' : baseUsername,
          fullName: googleUser.displayName?.trim().isNotEmpty == true
              ? googleUser.displayName!.trim()
              : baseUsername,
          email: email,
          phone: '',
          role: UserRole.parent,
          status: UserAccountStatus.active,
          createdAt: DateTime.now(),
        );
        users.insert(0, account);
        _cloudDataDirty = true;
      }

      final sessionUser = account.copyWith(
        token: IdGenerator.uuidV4(prefix: 'GOOGLE-SESSION'),
      );
      final accountIndex = users.indexWhere((user) => user.id == account.id);
      if (accountIndex == -1) {
        users.insert(0, sessionUser);
      } else {
        users[accountIndex] = sessionUser;
      }
      currentUser = sessionUser;

      if (!_isTesting) {
        await SqliteHelper.instance.insertUser(sessionUser);
        await _saveUsersToStorage();
        await _saveSyncState();
        final synced = await FirebaseSyncService.instance.syncUser(sessionUser);
        if (!synced) await _markCloudDataDirty();
        await addAuditLog(
          'Đăng nhập Google',
          'Đăng nhập thành công bằng tài khoản $email',
        );
      }

      return ApiResponse.ok(
        sessionUser,
        message: existingIndex == -1
            ? 'Đã tạo tài khoản phụ huynh từ Google.'
            : 'Đăng nhập Google thành công.',
      );
    } on GoogleAuthCancelled {
      return ApiResponse.error(499, 'Bạn đã hủy đăng nhập Google.');
    } on GoogleAuthFailure catch (error) {
      return ApiResponse.error(503, error.message);
    } catch (error) {
      debugPrint('Google authentication error: $error');
      return ApiResponse.error(500, 'Đăng nhập Google không thành công.');
    }
  }

  Future<void> logout() async {
    if (currentUser != null && !_isTesting) {
      await addAuditLog(
        'Đăng xuất hệ thống',
        'Người dùng đã kết thúc phiên làm việc',
      );
    }
    await GoogleAuthService.instance.signOut();
    currentUser = null;
  }

  /// Public registration endpoint. The role is intentionally not accepted
  /// from the UI: every public account is always a parent (BR-01/BR-02).
  Future<ApiResponse<UserModel>> registerParent({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final validation = _validateNewAccount(
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    if (validation != null) return ApiResponse.error(422, validation);
    final duplicate = _duplicateAccountMessage(
      username: username,
      email: email,
      phone: phone,
    );
    if (duplicate != null) return ApiResponse.error(409, duplicate);

    final parent = UserModel(
      id: IdGenerator.uuidV4(prefix: 'USR'),
      username: username.trim(),
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: UserRole.parent,
      status: UserAccountStatus.active,
      createdAt: DateTime.now(),
      passwordHash: PasswordHasher.hash(password),
    );
    await _persistNewUser(
      parent,
      auditAction: 'Đăng ký tài khoản phụ huynh',
      auditDetails:
          'Tạo tài khoản phụ huynh "${parent.username}" từ màn hình public',
    );
    return ApiResponse.created(
      parent,
      message: 'Đăng ký tài khoản Phụ huynh thành công!',
    );
  }

  /// Administrative creation endpoint for health staff (BR-03).
  /// The caller cannot submit a role; this method always assigns healthWorker.
  Future<ApiResponse<UserModel>> createHealthStaffByAdmin({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String assignedCommune,
    required String staffCode,
    required String healthFacility,
    required String professionalTitle,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (currentUser?.role != UserRole.admin) {
      return ApiResponse.error(
        403,
        'Bạn không có quyền tạo tài khoản Cán bộ Y tế.',
      );
    }

    final validation = _validateNewAccount(
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    if (validation != null) return ApiResponse.error(422, validation);
    if (assignedCommune.trim().isEmpty ||
        staffCode.trim().isEmpty ||
        healthFacility.trim().isEmpty ||
        professionalTitle.trim().isEmpty) {
      return ApiResponse.error(422, 'Vui lòng nhập đầy đủ thông tin cán bộ.');
    }
    final duplicate = _duplicateAccountMessage(
      username: username,
      email: email,
      phone: phone,
      staffCode: staffCode,
    );
    if (duplicate != null) return ApiResponse.error(409, duplicate);

    final healthStaff = UserModel(
      id: IdGenerator.uuidV4(prefix: 'STAFF'),
      username: username.trim(),
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: UserRole.healthWorker,
      status: UserAccountStatus.active,
      createdAt: DateTime.now(),
      assignedCommune: assignedCommune.trim(),
      passwordHash: PasswordHasher.hash(password),
      dateOfBirth: dateOfBirth,
      gender: gender?.trim(),
      staffCode: staffCode.trim(),
      healthFacility: healthFacility.trim(),
      professionalTitle: professionalTitle.trim(),
    );
    await _persistNewUser(
      healthStaff,
      auditAction: 'Tạo tài khoản cán bộ y tế',
      auditDetails:
          'Admin tạo cán bộ "${healthStaff.fullName}" (${healthStaff.staffCode}) phụ trách xã ${healthStaff.assignedCommune}',
    );
    return ApiResponse.created(
      healthStaff,
      message: 'Đã tạo tài khoản Cán bộ Y tế thành công.',
    );
  }

  String? _validateNewAccount({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    if (username.trim().length < 4 ||
        fullName.trim().isEmpty ||
        email.trim().isEmpty ||
        phone.trim().isEmpty ||
        password.length < 6) {
      return 'Thông tin không hợp lệ. Username tối thiểu 4 ký tự và mật khẩu tối thiểu 6 ký tự.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Email không hợp lệ.';
    }
    if (_normalizePhone(phone).length < 9) {
      return 'Số điện thoại không hợp lệ.';
    }
    return null;
  }

  String? _duplicateAccountMessage({
    required String username,
    required String email,
    required String phone,
    String? staffCode,
  }) {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _normalizePhone(phone);
    for (final user in users) {
      if (user.username.trim().toLowerCase() == normalizedUsername) {
        return 'Tên đăng nhập đã tồn tại.';
      }
      if (user.email.trim().toLowerCase() == normalizedEmail) {
        return 'Email đã tồn tại.';
      }
      if (_normalizePhone(user.phone) == normalizedPhone) {
        return 'Số điện thoại đã tồn tại.';
      }
      if (staffCode != null &&
          staffCode.trim().isNotEmpty &&
          user.staffCode?.trim().toLowerCase() ==
              staffCode.trim().toLowerCase()) {
        return 'Mã cán bộ đã tồn tại.';
      }
    }
    return null;
  }

  Future<void> _persistNewUser(
    UserModel newUser, {
    required String auditAction,
    required String auditDetails,
  }) async {
    _cloudDataDirty = true;
    users.insert(0, newUser);
    notifyListeners();
    if (_isTesting) return;
    await _saveUsersToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.insertUser(newUser);
    } catch (e) {
      debugPrint('Error saving registered user: $e');
    }

    try {
      await FirebaseSyncService.instance.syncUser(newUser);
    } catch (e) {
      debugPrint('Error syncing registered user to Firestore: $e');
    }

    await addAuditLog(auditAction, auditDetails);
  }

  Future<void> _saveUsersToStorage() async {
    try {
      final jsonStr = jsonEncode(users.map((u) => u.toMap()).toList());
      await _secureStorage.write(key: 'storage_users', value: jsonStr);
    } catch (e) {
      debugPrint('Error saving users to storage: $e');
    }
  }

  Future<void> syncFromStorage() async {
    try {
      final jsonStr = await _secureStorage.read(key: 'storage_users');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List raw = jsonDecode(jsonStr) as List;
        final loaded = raw
            .map((item) =>
                UserModel.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (loaded.isNotEmpty) {
          for (final lu in loaded) {
            final idx = users
                .indexWhere((u) => u.id == lu.id || u.username == lu.username);
            if (idx != -1) {
              users[idx] = lu;
            } else {
              users.insert(0, lu);
            }
          }
          _ensureConfiguredAdminAccount();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing from storage: $e');
    }
  }

  Future<void> approveUser(String userId) async {
    if (currentUser?.role != UserRole.admin) return;
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    final updatedUser = u.copyWith(status: UserAccountStatus.active);
    _cloudDataDirty = true;
    users[index] = updatedUser;
    notifyListeners();
    if (_isTesting) return;
    await _saveUsersToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance
          .updateUserStatus(userId, UserAccountStatus.active.name);
    } catch (e) {
      debugPrint('Error approving user: $e');
    }

    try {
      await FirebaseSyncService.instance.syncUser(updatedUser);
    } catch (e) {
      debugPrint('Error syncing approved user to Firestore: $e');
    }

    await addAuditLog('Phê duyệt tài khoản',
        'Admin đã phê duyệt tài khoản Cán bộ Y tế "${u.fullName}" (${u.username})');
  }

  Future<void> rejectUser(String userId) async {
    if (currentUser?.role != UserRole.admin) return;
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    final rejectedUser = u.copyWith(status: UserAccountStatus.rejected);
    _cloudDataDirty = true;
    users[index] = rejectedUser;
    notifyListeners();
    if (_isTesting) return;
    await _saveUsersToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance
          .updateUserStatus(userId, UserAccountStatus.rejected.name);
    } catch (e) {
      debugPrint('Error rejecting user: $e');
    }

    try {
      await FirebaseSyncService.instance.syncUser(rejectedUser);
    } catch (e) {
      debugPrint('Error syncing rejected user to Firestore: $e');
    }

    await addAuditLog('Từ chối tài khoản',
        'Admin đã từ chối đơn đăng ký tài khoản "${u.fullName}" (${u.username})');
  }

  Future<void> toggleUserStatus(String userId) async {
    if (currentUser?.role != UserRole.admin) return;
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    final u = users[index];
    final newStatus = u.status == UserAccountStatus.active
        ? UserAccountStatus.locked
        : UserAccountStatus.active;
    final updatedUser = u.copyWith(status: newStatus);
    _cloudDataDirty = true;
    users[index] = updatedUser;
    notifyListeners();
    await _saveUsersToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.updateUserStatus(userId, newStatus.name);
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }

    try {
      await FirebaseSyncService.instance.syncUser(updatedUser);
    } catch (e) {
      debugPrint('Error syncing toggled user to Firestore: $e');
    }

    await addAuditLog('Thay đổi trạng thái tài khoản',
        'Chuyển tài khoản "${u.username}" sang trạng thái ${newStatus.name}');
  }

  Future<void> addChild(ChildProfile child) async {
    if (currentUser?.role != UserRole.healthWorker ||
        !_canHealthWorkerAccessCommune(child.commune)) {
      return;
    }
    _cloudDataDirty = true;
    children.insert(0, child);
    await _linkChildToParentByPhone(child);
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.insertChild(child);
    } catch (e) {
      debugPrint('Error adding child to SQLite: $e');
    }

    try {
      await FirebaseSyncService.instance.syncChild(child);
    } catch (e) {
      debugPrint('Error syncing new child to Firestore: $e');
    }

    await addAuditLog('Thêm hồ sơ trẻ',
        'Tạo hồ sơ mới cho trẻ "${child.fullName}" tại ${child.village}');
  }

  Future<void> updateChild(ChildProfile child) async {
    if (currentUser?.role != UserRole.healthWorker) return;
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1 ||
        !_canHealthWorkerAccessCommune(children[index].commune) ||
        !_canHealthWorkerAccessCommune(child.commune)) {
      return;
    }
    _cloudDataDirty = true;
    children[index] = child;
    await _linkChildToParentByPhone(child);
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.updateChild(child);
    } catch (e) {
      debugPrint('Error updating child in SQLite: $e');
    }

    try {
      await FirebaseSyncService.instance.syncChild(child);
    } catch (e) {
      debugPrint('Error syncing updated child to Firestore: $e');
    }

    await addAuditLog(
        'Chỉnh sửa hồ sơ trẻ', 'Cập nhật thông tin trẻ "${child.fullName}"');
  }

  Future<void> _linkChildToParentByPhone(ChildProfile child) async {
    final childContact = _normalizePhone(child.motherPhone);
    if (childContact.isEmpty) return;

    for (var index = 0; index < users.length; index++) {
      final user = users[index];
      if (user.role != UserRole.parent ||
          _normalizePhone(user.phone) != childContact ||
          user.linkedChildIds.contains(child.id)) {
        continue;
      }

      final linkedUser = user.copyWith(
        linkedChildIds: {...user.linkedChildIds, child.id}.toList(),
      );
      users[index] = linkedUser;
      if (_currentUser?.id == linkedUser.id) {
        _currentUser = linkedUser.copyWith(token: _currentUser?.token);
      }

      if (!_isTesting) {
        await SqliteHelper.instance.insertUser(linkedUser);
        await FirebaseSyncService.instance.syncUser(linkedUser);
      }
    }
    if (!_isTesting) await _saveUsersToStorage();
  }

  Future<void> deleteChild(String childId) async {
    if (currentUser?.role != UserRole.healthWorker) return;
    final childIndex = children.indexWhere((item) => item.id == childId);
    if (childIndex == -1 ||
        !_canHealthWorkerAccessCommune(children[childIndex].commune)) {
      return;
    }
    final child = children[childIndex];
    _cloudDataDirty = true;
    _pendingDeletedChildIds.add(childId);
    _pendingDeletedChildCommunes[childId] = child.commune;
    children.removeAt(childIndex);
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.deleteChild(childId);
    } catch (e) {
      debugPrint('Error deleting child in SQLite: $e');
    }

    try {
      final deleted = await FirebaseSyncService.instance.deleteChild(childId);
      if (deleted) {
        _pendingDeletedChildIds.remove(childId);
        _pendingDeletedChildCommunes.remove(childId);
        await _saveSyncState();
      }
    } catch (e) {
      debugPrint('Error deleting child from Firestore: $e');
    }

    await addAuditLog('Xóa hồ sơ trẻ', 'Đã xóa hồ sơ trẻ "${child.fullName}"');
  }

  Future<void> addVaccination(String childId, VaccinationRecord record) async {
    if (currentUser?.role != UserRole.healthWorker) return;
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1 ||
        !_canHealthWorkerAccessCommune(children[index].commune)) {
      return;
    }
    _cloudDataDirty = true;
    children[index] = children[index].copyWith(
      vaccinations: [...children[index].vaccinations, record],
    );
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

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
    if (currentUser?.role != UserRole.healthWorker) return;
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1 ||
        !_canHealthWorkerAccessCommune(children[index].commune)) {
      return;
    }
    _cloudDataDirty = true;
    children[index] = children[index].copyWith(
      medications: [...children[index].medications, record],
    );
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.insertMedication(record);
      await SqliteHelper.instance.updateChild(children[index]);
    } catch (e) {
      debugPrint('Error adding medication: $e');
    }

    await addAuditLog(
        'Ghi nhận thuốc uống', 'Cho trẻ uống bổ sung ${record.medicationName}');
  }

  Future<void> addVaccineSchedule(VaccineSchedule schedule) async {
    if (currentUser?.role != UserRole.admin) return;
    _cloudDataDirty = true;
    vaccineSchedules.add(schedule);
    notifyListeners();
    await _saveSchedulesToStorage();
    await _saveSyncState();

    try {
      await FirebaseSyncService.instance.syncVaccineSchedule(schedule);
    } catch (e) {
      debugPrint('Error syncing vaccine schedule to Firestore: $e');
    }

    await addAuditLog('Thêm lịch vaccine',
        'Thêm vaccine "${schedule.vaccineName}" Mũi ${schedule.doseNumber} vào danh mục chuẩn');
  }

  Future<void> addMedicationSchedule(MedicationSchedule schedule) async {
    if (currentUser?.role != UserRole.admin) return;
    _cloudDataDirty = true;
    medicationSchedules.add(schedule);
    notifyListeners();
    await _saveSchedulesToStorage();
    await _saveSyncState();

    try {
      await FirebaseSyncService.instance.syncMedicationSchedule(schedule);
    } catch (e) {
      debugPrint('Error syncing medication schedule to Firestore: $e');
    }

    await addAuditLog('Thêm danh mục thuốc uống',
        'Thêm "${schedule.medicationName}" vào danh mục thuốc uống & bổ sung');
  }

  Future<void> addDiseaseReport(DiseaseReport report) async {
    if (currentUser?.role != UserRole.healthWorker ||
        !_canHealthWorkerAccessCommune(report.commune)) {
      return;
    }
    _cloudDataDirty = true;
    final pendingReport = report.copyWith(
      syncStatus: VaccinationSyncStatus.pending,
    );
    diseaseReports.insert(0, pendingReport);
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance.insertDiseaseReport(pendingReport);
    } catch (e) {
      debugPrint('Error adding disease report: $e');
    }

    try {
      await FirebaseSyncService.instance.syncDiseaseReport(pendingReport);
    } catch (e) {
      debugPrint('Error syncing disease report to Firestore: $e');
    }

    await addAuditLog('Khai báo dịch bệnh',
        'Báo cáo ca bệnh nghi ngờ ${report.diseaseType} tại ${report.village}');
  }

  Future<void> updateDiseaseReportStatus(
      String reportId, String newStatus) async {
    if (currentUser?.role != UserRole.admin) return;
    final index = diseaseReports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;
    _cloudDataDirty = true;
    diseaseReports[index] = diseaseReports[index].copyWith(
      status: newStatus,
      syncStatus: VaccinationSyncStatus.pending,
    );
    final updatedReport = diseaseReports[index];
    notifyListeners();
    await _saveCoreDataToStorage();
    await _saveSyncState();

    try {
      await SqliteHelper.instance
          .updateDiseaseReportStatus(reportId, newStatus);
    } catch (e) {
      debugPrint('Error updating disease report status: $e');
    }

    try {
      await FirebaseSyncService.instance.syncDiseaseReport(updatedReport);
    } catch (e) {
      debugPrint('Error syncing disease report status to Firestore: $e');
    }

    await addAuditLog('Cập nhật khoanh vùng dịch',
        'Chuyển trạng thái ca bệnh ${diseaseReports[index].diseaseType} sang "$newStatus"');
  }

  /// Pulls the newest server data into the parent/device view.
  ///
  /// Cloud data is only applied after every required Firestore collection was
  /// read successfully, so a temporary error never replaces usable local data.
  Future<bool> refreshFromCloud({bool notify = true}) async {
    if (_isTesting || isRefreshingFromCloud || (!kIsWeb && !isOnline)) {
      return false;
    }

    isRefreshingFromCloud = true;
    if (notify) notifyListeners();

    try {
      final snapshot = await FirebaseSyncService.instance.fetchCloudSnapshot();
      if (snapshot == null) return false;

      // A brand-new Firebase project has no documents yet. Keep the local demo
      // accounts so a health worker can still sign in and seed Firestore.
      if (!snapshot.hasAnyData) {
        lastSyncAt = DateTime.now();
        return true;
      }

      final localUsers = <String, UserModel>{
        for (final user in users) user.id: user,
      };
      final sessionUser = _currentUser;
      users = snapshot.users.map((remoteUser) {
        final localUser = localUsers[remoteUser.id];
        return remoteUser.copyWith(
          token: localUser?.token,
          passwordHash: remoteUser.passwordHash ?? localUser?.passwordHash,
        );
      }).toList();
      final adminConfigurationChanged = _ensureConfiguredAdminAccount();
      children = snapshot.children;
      diseaseReports = snapshot.diseaseReports;
      auditLogs = snapshot.auditLogs;
      vaccineSchedules = snapshot.vaccineSchedules;
      medicationSchedules = snapshot.medicationSchedules;

      if (sessionUser != null) {
        final remoteIndex = users.indexWhere(
          (user) =>
              user.id == sessionUser.id ||
              user.username == sessionUser.username,
        );
        if (remoteIndex != -1) {
          final refreshedSession = users[remoteIndex].copyWith(
            token: sessionUser.token,
            passwordHash:
                users[remoteIndex].passwordHash ?? sessionUser.passwordHash,
          );
          users[remoteIndex] = refreshedSession;
          _currentUser = refreshedSession;
        }
      }

      // Parent devices are read-only for clinical data. Clear a stale dirty
      // marker from older builds so it cannot upload old data over Firestore.
      if (_currentUser?.role == UserRole.parent) {
        _cloudDataDirty = false;
        _pendingDeletedChildIds.clear();
        _pendingDeletedChildCommunes.clear();
      }

      lastSyncAt = DateTime.now();
      await _saveCoreDataToStorage();
      await _saveUsersToStorage();
      await _saveSchedulesToStorage();
      await _saveSyncState();
      await _cacheCloudSnapshotLocally(snapshot);
      if (adminConfigurationChanged) {
        final admin = users.firstWhere(
          (user) => user.id == defaultAdminId || user.role == UserRole.admin,
        );
        final synced = await FirebaseSyncService.instance.syncUser(admin);
        if (!synced) _cloudDataDirty = true;
      }
      return true;
    } catch (e) {
      debugPrint('Error refreshing data from Firestore: $e');
      return false;
    } finally {
      isRefreshingFromCloud = false;
      notifyListeners();
    }
  }

  Future<void> _cacheCloudSnapshotLocally(
      FirebaseCloudSnapshot snapshot) async {
    try {
      for (final user in users) {
        await SqliteHelper.instance.insertUser(user);
      }
      for (final child in snapshot.children) {
        await SqliteHelper.instance.insertChild(child);
        for (final record in child.vaccinations) {
          await SqliteHelper.instance.insertVaccination(record);
        }
        for (final record in child.medications) {
          await SqliteHelper.instance.insertMedication(record);
        }
      }
      for (final report in snapshot.diseaseReports) {
        await SqliteHelper.instance.insertDiseaseReport(report);
      }
      for (final log in snapshot.auditLogs) {
        await SqliteHelper.instance.insertAuditLog(log);
      }
    } catch (e) {
      debugPrint('Error caching Firestore snapshot locally: $e');
    }
  }

  Future<bool> syncPending() async {
    if (currentUser?.role == UserRole.parent) {
      return refreshFromCloud();
    }
    if (!isOnline || pendingCount == 0 || isSyncing) return false;
    isSyncing = true;
    notifyListeners();

    try {
      final syncService = FirebaseSyncService.instance;
      if (!await syncService.initialize()) return false;

      var allSucceeded = true;
      final scopedChildren = currentUserChildren;
      final scopedReports = currentUserDiseaseReports;

      // Apply offline deletions before uploading the current local snapshot.
      final deletionsToSync = currentUser?.role == UserRole.admin
          ? _pendingDeletedChildIds.toList()
          : _pendingDeletedChildIds.where((childId) {
              final commune = _pendingDeletedChildCommunes[childId];
              return commune != null && _canHealthWorkerAccessCommune(commune);
            }).toList();
      for (final childId in deletionsToSync) {
        final deleted = await syncService.deleteChild(childId);
        if (deleted) {
          _pendingDeletedChildIds.remove(childId);
          _pendingDeletedChildCommunes.remove(childId);
        } else {
          allSucceeded = false;
        }
      }

      // A full local snapshot upload also migrates records that were created
      // before Firebase was configured or were previously marked synced by the
      // old simulated implementation.
      if (_cloudDataDirty) {
        for (final child in scopedChildren) {
          if (!await syncService.syncChild(child)) allSucceeded = false;
        }
        if (currentUser?.role == UserRole.admin) {
          for (final user in users) {
            if (!await syncService.syncUser(user)) allSucceeded = false;
          }
          for (final schedule in vaccineSchedules) {
            if (!await syncService.syncVaccineSchedule(schedule)) {
              allSucceeded = false;
            }
          }
          for (final schedule in medicationSchedules) {
            if (!await syncService.syncMedicationSchedule(schedule)) {
              allSucceeded = false;
            }
          }
        }
        final logsToSync = currentUser?.role == UserRole.admin
            ? auditLogs
            : auditLogs
                .where((log) => log.performedBy == currentUser?.username)
                .toList();
        for (final log in logsToSync) {
          if (!await syncService.syncAuditLog(log)) allSucceeded = false;
        }
      }

      final syncedVaccinationIds = <String>{};
      final syncedMedicationIds = <String>{};
      final syncedDiseaseReportIds = <String>{};
      // 1. Gather all pending vaccination records across all children
      final allVaccinations =
          scopedChildren.expand((child) => child.vaccinations).toList();
      final pendingVaccinations = _cloudDataDirty
          ? allVaccinations
          : allVaccinations
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
            syncedVaccinationIds.add(record.id);
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
          allSucceeded = false;
        }
      }

      // 2. Sync pending medication records before changing local status.
      for (var child in scopedChildren) {
        for (var record in child.medications) {
          if (_cloudDataDirty ||
              record.syncStatus == VaccinationSyncStatus.pending) {
            final success =
                await FirebaseSyncService.instance.syncMedicationRecord(record);
            if (success) {
              await SqliteHelper.instance.updateMedicationSyncStatus(
                  record.id, VaccinationSyncStatus.synced.name);
              syncedMedicationIds.add(record.id);
            } else {
              allSucceeded = false;
            }
          }
        }
      }

      // 3. Sync pending disease reports
      for (var report in scopedReports) {
        if (_cloudDataDirty ||
            report.syncStatus == VaccinationSyncStatus.pending) {
          final success =
              await FirebaseSyncService.instance.syncDiseaseReport(report);
          if (success) {
            await SqliteHelper.instance.updateDiseaseReportSyncStatus(
                report.id, VaccinationSyncStatus.synced.name);
            syncedDiseaseReportIds.add(report.id);
          } else {
            allSucceeded = false;
          }
        }
      }

      // Reload only when SQLite exists. Web must keep its in-memory data.
      if (await SqliteHelper.instance.database != null) {
        children = await SqliteHelper.instance.getChildren();
        diseaseReports = await SqliteHelper.instance.getDiseaseReports();
      } else {
        children = children
            .map(
              (child) => child.copyWith(
                vaccinations: child.vaccinations
                    .map(
                      (record) => record.copyWith(
                        syncStatus: syncedVaccinationIds.contains(record.id)
                            ? VaccinationSyncStatus.synced
                            : record.syncStatus,
                      ),
                    )
                    .toList(),
                medications: child.medications
                    .map(
                      (record) => record.copyWith(
                        syncStatus: syncedMedicationIds.contains(record.id)
                            ? VaccinationSyncStatus.synced
                            : record.syncStatus,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
        diseaseReports = diseaseReports
            .map(
              (report) => report.copyWith(
                syncStatus: syncedDiseaseReportIds.contains(report.id)
                    ? VaccinationSyncStatus.synced
                    : report.syncStatus,
              ),
            )
            .toList();
      }

      await _saveCoreDataToStorage();
      await _saveSyncState();
      if (!allSucceeded) return false;

      _cloudDataDirty = false;
      lastSyncAt = DateTime.now();
      await _saveSyncState();
      await addAuditLog('Đồng bộ dữ liệu',
          'Đồng bộ thành công dữ liệu ngoại tuyến lên Firestore Server');
      return !_cloudDataDirty;
    } catch (e) {
      debugPrint('Error syncing data: $e');
      return false;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  // SQLite FTS Offline Search. Không thay thế snapshot toàn huyện trong bộ nhớ;
  // kết quả trả về luôn được giới hạn theo quyền của người dùng hiện tại.
  Future<List<ChildProfile>> searchChildren(String query) async {
    try {
      final results = await SqliteHelper.instance.searchChildrenOffline(query);
      final accessibleIds =
          currentUserChildren.map((child) => child.id).toSet();
      return results
          .where((child) => accessibleIds.contains(child.id))
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error searching children offline: $e');
      return const [];
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
    final scope =
        context.dependOnInheritedWidgetOfExactType<_AppScopeInherited>();
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
