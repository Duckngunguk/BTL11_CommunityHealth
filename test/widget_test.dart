import 'package:community_health/main.dart';
import 'package:community_health/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Future<void> pumpDesktopApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
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
  });

  testWidgets('Màn đăng nhập desktop không bị kéo tràn hoặc overflow',
      (tester) async {
    await pumpDesktopApp(tester);

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Không gian cán bộ hiển thị đúng bố cục desktop', (tester) async {
    await pumpDesktopApp(tester);
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.text('KHÔNG GIAN CÁN BỘ'), findsOneWidget);
    expect(find.text('Tổng quan'), findsOneWidget);
  });

  testWidgets('Không gian phụ huynh hiển thị đúng bố cục desktop',
      (tester) async {
    await pumpDesktopApp(tester);
    await tester.enterText(find.byType(TextField).first, 'parent.demo');
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.text('KHÔNG GIAN GIA ĐÌNH'), findsOneWidget);
    expect(find.text('Sổ tiêm của con'), findsOneWidget);
  });

  testWidgets('Không gian quản trị hiển thị đúng bố cục desktop',
      (tester) async {
    await pumpDesktopApp(tester);
    await tester.enterText(find.byType(TextField).first, 'admin.demo');
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.text('QUẢN TRỊ HỆ THỐNG'), findsOneWidget);
    expect(find.text('Trung tâm Y tế thị xã Sa Pa'), findsWidgets);
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
