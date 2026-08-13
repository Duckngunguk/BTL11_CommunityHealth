import 'package:community_health/data/master_data.dart';
import 'package:community_health/models/models.dart';
import 'package:community_health/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('đăng nhập từ chối sai mật khẩu và trả đúng vai trò', () async {
    final store = AppStore.forTesting(initialUsers: demoUsers);

    final denied = await store.authenticate(
      username: 'admin.demo',
      password: 'sai-mat-khau',
    );
    expect(denied.success, isFalse);
    expect(store.currentUser, isNull);

    final accepted = await store.authenticate(
      username: 'admin.demo',
      password: '123456',
    );
    expect(accepted.success, isTrue);
    expect(accepted.data?.role.name, 'admin');
    expect(store.currentUser?.username, 'admin.demo');
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
    final store = AppStore.forTesting(initialUsers: demoUsers);
    final pending = store.users.firstWhere(
      (user) => user.status.name == 'pendingApproval',
    );
    final before = store.pendingUserApprovals;

    await store.rejectUser(pending.id);

    final rejected = store.users.firstWhere((user) => user.id == pending.id);
    expect(rejected.status.name, 'rejected');
    expect(store.pendingUserApprovals, before - 1);

    final login = await store.authenticate(
      username: rejected.username,
      password: '123456',
    );
    expect(login.success, isFalse);
    expect(login.statusCode, 403);
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
    final store = AppStore.forTesting(initialChildren: [child]);
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
