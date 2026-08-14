import 'package:community_health/data/master_data.dart';
import 'package:community_health/models/models.dart';
import 'package:community_health/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('đăng nhập từ chối sai mật khẩu và trả đúng vai trò', () async {
    final store = AppStore.forTesting(initialUsers: demoUsers);

    final denied = await store.authenticate(
      email: 'admin123@gmail.com',
      password: 'sai-mat-khau',
    );
    expect(denied.success, isFalse);
    expect(store.currentUser, isNull);

    final accepted = await store.authenticate(
      email: 'admin123@gmail.com',
      password: '123456',
    );
    expect(accepted.success, isTrue);
    expect(accepted.data?.role.name, 'admin');
    expect(store.currentUser?.email, 'admin123@gmail.com');
    expect(store.currentUser?.username, 'admin123@gmail.com');

    final oldUsername = await store.authenticate(
      email: 'admin.demo',
      password: '123456',
    );
    expect(oldUsername.success, isFalse);
    expect(oldUsername.statusCode, 422);
  });

  test('phụ huynh chỉ truy cập hồ sơ trẻ được liên kết bằng ID', () {
    final parent = demoUsers.firstWhere(
      (user) => user.username == 'parent.demo',
    );
    final store = AppStore.forTesting(
      initialUsers: demoUsers,
      initialChildren: demoChildren,
      initialCurrentUser: parent,
    );

    expect(store.currentUserChildren.map((child) => child.id), ['CH002']);
    expect(store.canCurrentUserAccessChild('CH002'), isTrue);
    expect(store.canCurrentUserAccessChild('CH001'), isFalse);
  });

  test('phụ huynh nhận hồ sơ mới khi số điện thoại liên hệ trùng khớp', () {
    final parent = demoUsers.firstWhere(
      (user) => user.username == 'parent.demo',
    );
    final newChild = demoChildren.first.copyWith(
      motherPhone: '0912345678',
    );
    final store = AppStore.forTesting(
      initialUsers: demoUsers,
      initialChildren: [newChild],
      initialCurrentUser: parent,
    );

    expect(store.currentUserChildren.map((child) => child.id), [newChild.id]);
    expect(store.canCurrentUserAccessChild(newChild.id), isTrue);
  });

  test('từ chối tài khoản cập nhật trạng thái và loại khỏi danh sách chờ',
      () async {
    final admin = demoUsers.firstWhere((user) => user.role == UserRole.admin);
    final store = AppStore.forTesting(
      initialUsers: demoUsers,
      initialCurrentUser: admin,
    );
    final pending = store.users.firstWhere(
      (user) => user.status.name == 'pendingApproval',
    );
    final before = store.pendingUserApprovals;

    await store.rejectUser(pending.id);

    final rejected = store.users.firstWhere((user) => user.id == pending.id);
    expect(rejected.status.name, 'rejected');
    expect(store.pendingUserApprovals, before - 1);

    final login = await store.authenticate(
      email: rejected.email,
      password: '123456',
    );
    expect(login.success, isFalse);
    expect(login.statusCode, 403);
  });

  test('đăng ký public luôn tạo phụ huynh và không nhận role từ giao diện',
      () async {
    final store = AppStore.forTesting(initialUsers: demoUsers);

    final response = await store.registerParent(
      username: 'phuhuynh.moi',
      fullName: 'Phụ huynh mới',
      email: 'phuhuynh.moi@example.com',
      phone: '0901234567',
      password: '123456',
    );

    expect(response.success, isTrue);
    expect(response.data?.role, UserRole.parent);
    expect(response.data?.status, UserAccountStatus.active);
    expect(response.data?.assignedCommune, isNull);
  });

  test('đăng ký public từ chối email hoặc số điện thoại đã tồn tại', () async {
    final store = AppStore.forTesting(initialUsers: demoUsers);

    final response = await store.registerParent(
      username: 'parent.other',
      fullName: 'Phụ huynh trùng',
      email: 'giangasang.sapa@gmail.com',
      phone: '0912345678',
      password: '123456',
    );

    expect(response.success, isFalse);
    expect(response.statusCode, 409);
  });

  test('chỉ admin được tạo tài khoản cán bộ y tế', () async {
    final parent = demoUsers.firstWhere((user) => user.role == UserRole.parent);
    final deniedStore = AppStore.forTesting(
      initialUsers: demoUsers,
      initialCurrentUser: parent,
    );

    final denied = await deniedStore.createHealthStaffByAdmin(
      username: 'staff.new',
      fullName: 'Cán bộ mới',
      email: 'staff.new@example.com',
      phone: '0907654321',
      password: '123456',
      assignedCommune: 'Tả Phìn',
      staffCode: 'CBYT-100',
      healthFacility: 'Trạm Y tế xã Tả Phìn',
      professionalTitle: 'Y sĩ',
    );
    expect(denied.success, isFalse);
    expect(denied.statusCode, 403);

    final admin = demoUsers.firstWhere((user) => user.role == UserRole.admin);
    final adminStore = AppStore.forTesting(
      initialUsers: demoUsers,
      initialCurrentUser: admin,
    );
    final created = await adminStore.createHealthStaffByAdmin(
      username: 'staff.new',
      fullName: 'Cán bộ mới',
      email: 'staff.new@example.com',
      phone: '0907654321',
      password: '123456',
      assignedCommune: 'Tả Phìn',
      staffCode: 'CBYT-100',
      healthFacility: 'Trạm Y tế xã Tả Phìn',
      professionalTitle: 'Y sĩ',
    );

    expect(created.success, isTrue);
    expect(created.data?.role, UserRole.healthWorker);
    expect(created.data?.status, UserAccountStatus.active);
    expect(created.data?.staffCode, 'CBYT-100');
  });

  test('phụ huynh không thể thay đổi trạng thái tài khoản hoặc thêm hồ sơ trẻ',
      () async {
    final parent = demoUsers.firstWhere((user) => user.role == UserRole.parent);
    final target = demoUsers.firstWhere(
      (user) => user.role == UserRole.healthWorker,
    );
    final store = AppStore.forTesting(
      initialUsers: demoUsers,
      initialChildren: const [],
      initialCurrentUser: parent,
    );

    await store.toggleUserStatus(target.id);
    await store.addChild(demoChildren.first);

    expect(
      store.users.firstWhere((user) => user.id == target.id).status,
      target.status,
    );
    expect(store.children, isEmpty);
  });

  test('cán bộ y tế chỉ thấy và thao tác dữ liệu thuộc xã được phân công',
      () async {
    final taPhinWorker = demoUsers.firstWhere(
      (user) =>
          user.role == UserRole.healthWorker &&
          user.assignedCommune == 'Tả Phìn',
    );
    final hauThaoWorker = demoUsers.firstWhere(
      (user) =>
          user.role == UserRole.healthWorker &&
          user.assignedCommune == 'Hầu Thào',
    );
    final reports = [
      DiseaseReport(
        id: 'RPT-TA-PHIN',
        patientName: 'Ca Tả Phìn',
        diseaseType: 'Sởi',
        village: 'Tả Chải',
        commune: 'Tả Phìn',
        district: 'Sa Pa',
        reportedAt: DateTime(2026, 8, 15),
        reportedBy: 'Cán bộ A',
        symptoms: 'Sốt',
        syncStatus: VaccinationSyncStatus.synced,
      ),
      DiseaseReport(
        id: 'RPT-HAU-THAO',
        patientName: 'Ca Hầu Thào',
        diseaseType: 'Sởi',
        village: 'Hầu Chư Ngài',
        commune: 'Hầu Thào',
        district: 'Sa Pa',
        reportedAt: DateTime(2026, 8, 15),
        reportedBy: 'Cán bộ B',
        symptoms: 'Sốt',
        syncStatus: VaccinationSyncStatus.synced,
      ),
    ];
    final store = AppStore.forTesting(
      initialUsers: demoUsers,
      initialChildren: demoChildren,
      initialDiseaseReports: reports,
      initialCurrentUser: taPhinWorker,
    );

    expect(
        store.currentUserChildren.map((child) => child.id), ['CH001', 'CH002']);
    expect(store.canCurrentUserAccessChild('CH003'), isFalse);

    store.currentUser = hauThaoWorker;
    expect(store.currentUserChildren.map((child) => child.id), ['CH003']);
    expect(store.currentUserDiseaseReports.map((report) => report.id),
        ['RPT-HAU-THAO']);
    expect(store.canCurrentUserAccessChild('CH001'), isFalse);

    final originalCrossCommuneChild =
        store.children.firstWhere((child) => child.id == 'CH001');
    await store.updateChild(
      originalCrossCommuneChild.copyWith(fullName: 'Tên không được phép sửa'),
    );
    await store.deleteChild('CH001');
    await store.addChild(originalCrossCommuneChild);
    final vaccinationCount = originalCrossCommuneChild.vaccinations.length;
    await store.addVaccination(
      'CH001',
      VaccinationRecord(
        id: 'VAC-CROSS-COMMUNE',
        childId: 'CH001',
        vaccineId: 'DPT-3',
        vaccineName: 'DPT',
        doseNumber: 3,
        lotNumber: 'LOT-CROSS',
        administeredBy: hauThaoWorker.fullName,
        administeredAt: DateTime(2026, 8, 15),
        syncStatus: VaccinationSyncStatus.pending,
      ),
    );
    await store.addDiseaseReport(reports.first);

    expect(
      store.children.firstWhere((child) => child.id == 'CH001').fullName,
      originalCrossCommuneChild.fullName,
    );
    expect(store.children.where((child) => child.id == 'CH001'), hasLength(1));
    expect(
      store.children.firstWhere((child) => child.id == 'CH001').vaccinations,
      hasLength(vaccinationCount),
    );
    expect(store.diseaseReports, hasLength(2));
  });

  test('đồng bộ ngoại tuyến thất bại và giữ nguyên trạng thái pending',
      () async {
    final original = demoChildren.first;
    final pendingRecord = VaccinationRecord(
      id: 'VAC-OFFLINE-TEST',
      childId: original.id,
      vaccineId: 'DPT-TEST',
      vaccineName: 'DPT',
      doseNumber: 1,
      lotNumber: 'LOT-TEST',
      administeredBy: 'Test Worker',
      administeredAt: DateTime(2026, 8, 14),
      syncStatus: VaccinationSyncStatus.pending,
    );
    final child = original.copyWith(vaccinations: [pendingRecord]);
    final worker = demoUsers.firstWhere(
      (user) =>
          user.role == UserRole.healthWorker &&
          user.assignedCommune == child.commune,
    );
    final store = AppStore.forTesting(
      initialChildren: [child],
      initialCurrentUser: worker,
    );
    store.setOnline(false);

    final success = await store.syncPending();

    expect(success, isFalse);
    expect(store.pendingCount, 1);
    expect(
      store.children.single.vaccinations.single.syncStatus,
      VaccinationSyncStatus.pending,
    );
  });
}
