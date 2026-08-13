import 'package:community_health/utils/id_generator.dart';
import 'package:community_health/utils/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mật khẩu được băm và xác minh đúng', () {
    final hash = PasswordHasher.hash('123456');
    expect(hash, isNot('123456'));
    expect(PasswordHasher.verify('123456', hash), isTrue);
    expect(PasswordHasher.verify('sai-mat-khau', hash), isFalse);
  });

  test('UUID phiên đăng nhập không trùng', () {
    final first = IdGenerator.uuidV4(prefix: 'SESSION');
    final second = IdGenerator.uuidV4(prefix: 'SESSION');
    expect(first, startsWith('SESSION-'));
    expect(first, isNot(second));
  });
}
