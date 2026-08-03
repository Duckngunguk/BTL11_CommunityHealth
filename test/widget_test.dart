import 'package:community_health/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hiển thị màn hình đăng nhập', (tester) async {
    await tester.pumpWidget(const CommunityHealthApp());
    expect(find.text('Đăng nhập CommunityHealth'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}
