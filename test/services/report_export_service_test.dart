import 'package:community_health/data/master_data.dart';
import 'package:community_health/services/report_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF dùng font Unicode và tạo được báo cáo tiếng Việt', () async {
    final bytes = await ReportExportService.instance.buildChildrenPdfBytes(
      children: demoChildren,
      commune: 'Tả Phìn',
      reporterName: 'Nguyễn Văn Quản Trị',
    );

    expect(bytes, isNotEmpty);
    expect(bytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]);
  });
}
