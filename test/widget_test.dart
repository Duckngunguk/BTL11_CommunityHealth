import 'package:community_health/main.dart';
import 'package:community_health/data/master_data.dart';
import 'package:community_health/models/models.dart';
import 'package:community_health/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Future<void> pumpDesktopApp(
    WidgetTester tester, {
    AppStore? store,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: AppScope(
          notifier: store ?? AppStore.forTesting(),
          child: const CommunityHealthApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Hiển thị màn hình đăng nhập', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: AppScope(
          notifier: AppStore.forTesting(),
          child: const CommunityHealthApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu ngay'), findsNothing);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Gmail đăng nhập'), findsOneWidget);
    expect(find.text('Tài khoản hoặc số điện thoại'), findsNothing);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
  });

  testWidgets('Màn đăng nhập desktop không bị kéo tràn hoặc overflow',
      (tester) async {
    await pumpDesktopApp(tester);

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('đăng ký public chỉ hiển thị form Phụ huynh', (tester) async {
    await pumpDesktopApp(tester);
    await tester.tap(find.text('Đăng ký').last);
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký tài khoản Phụ huynh'), findsOneWidget);
    expect(find.text('CHỌN VAI TRỜ TÀI KHOẢN ĐĂNG KÝ'), findsNothing);
    expect(find.text('Cán bộ Y tế'), findsNothing);
  });

  testWidgets('Không gian cán bộ hiển thị đúng bố cục desktop', (tester) async {
    await pumpDesktopApp(tester);
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.text('KHÔNG GIAN CÁN BỘ'), findsOneWidget);
    expect(find.text('Tổng quan'), findsOneWidget);
  });

  testWidgets('cán bộ chỉ nhìn thấy hồ sơ trẻ thuộc xã được phân công',
      (tester) async {
    final hauThaoWorker = demoUsers
        .firstWhere(
          (user) =>
              user.role == UserRole.healthWorker &&
              user.assignedCommune == 'Hầu Thào',
        )
        .copyWith(status: UserAccountStatus.active);
    final store = AppStore.forTesting(
      initialUsers: demoUsers,
      initialChildren: demoChildren,
      initialCurrentUser: hauThaoWorker,
    );

    await pumpDesktopApp(tester, store: store);

    expect(find.text('Lý Thị An'), findsOneWidget);
    expect(find.text('Vàng Thị Mai'), findsNothing);
    expect(find.text('Giàng A Minh'), findsNothing);
    expect(find.textContaining('XÃ HẦU THÀO'), findsOneWidget);
  });

  testWidgets('Không gian phụ huynh hiển thị đúng bố cục desktop',
      (tester) async {
    await pumpDesktopApp(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'giangasang.sapa@gmail.com',
    );
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.text('KHÔNG GIAN GIA ĐÌNH'), findsOneWidget);
    expect(find.text('Sổ tiêm của con'), findsOneWidget);
  });

  testWidgets('Không gian quản trị hiển thị đúng bố cục desktop',
      (tester) async {
    await pumpDesktopApp(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'admin123@gmail.com',
    );
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.text('QUẢN TRỊ HỆ THỐNG'), findsOneWidget);
    expect(find.text('Trung tâm Y tế thị xã Sa Pa'), findsWidgets);
  });

  testWidgets('admin có chức năng thêm cán bộ y tế', (tester) async {
    await pumpDesktopApp(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'admin123@gmail.com',
    );
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm cán bộ y tế'), findsOneWidget);
  });

  testWidgets('Không gian cán bộ không overflow trên điện thoại',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: AppScope(
          notifier: AppStore.forTesting(),
          child: const CommunityHealthApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
