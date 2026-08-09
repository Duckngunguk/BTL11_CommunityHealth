import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class ReportExportService {
  ReportExportService._internal();
  static final ReportExportService instance = ReportExportService._internal();

  // ─────────────────────────────────────────────────────────────────
  // Xuất CSV / Excel
  // ─────────────────────────────────────────────────────────────────

  /// Xuất danh sách trẻ em + trạng thái tiêm chủng dạng CSV
  Future<String?> exportChildrenToCsv(
    List<ChildProfile> children, {
    String? filterStatus,
  }) async {
    final List<List<dynamic>> rows = [
      // Header
      [
        'Mã trẻ', 'Họ và tên', 'Ngày sinh', 'Giới tính',
        'Tên mẹ', 'SĐT mẹ', 'Thôn bản', 'Xã', 'Huyện',
        'Trạng thái tiêm', 'Mũi tiêm tiếp theo', 'Hạn tiêm', 'Trễ (ngày)',
      ],
    ];

    final filtered = filterStatus != null
        ? children.where((c) {
            if (filterStatus == 'late') return c.status == ChildVaccinationStatus.late;
            if (filterStatus == 'dueSoon') return c.status == ChildVaccinationStatus.dueSoon;
            return true;
          }).toList()
        : children;

    for (final c in filtered) {
      rows.add([
        c.id,
        c.fullName,
        '${c.dateOfBirth.day}/${c.dateOfBirth.month}/${c.dateOfBirth.year}',
        c.gender,
        c.motherName,
        c.motherPhone,
        c.village,
        c.commune,
        c.district,
        _statusLabel(c.status),
        c.nextVaccine,
        '${c.nextDue.day}/${c.nextDue.month}/${c.nextDue.year}',
        c.lateDays.toString(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Trên Web: dùng Printing để tải file trực tiếp
      debugPrint('📥 [Export CSV - Web] Xuất ${filtered.length} bản ghi');
      return csv;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/bao_cao_tiem_chung_$timestamp.csv');
      await file.writeAsString(csv);
      debugPrint('📥 [Export CSV] Đã lưu: ${file.path}');
      return file.path;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Xuất PDF
  // ─────────────────────────────────────────────────────────────────

  /// Xuất báo cáo danh sách trẻ trễ tiêm ra PDF
  Future<void> exportLatePdfReport({
    required List<ChildProfile> children,
    required String reporterName,
    required String commune,
  }) async {
    final pdf = pw.Document();
    final lateChildren = children
        .where((c) => c.status == ChildVaccinationStatus.late)
        .toList();
    final dueSoonChildren = children
        .where((c) => c.status == ChildVaccinationStatus.dueSoon)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(commune, reporterName),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Tóm tắt số liệu
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryCell('Tổng số trẻ', '${children.length}', PdfColors.blue700),
                _summaryCell('Trễ tiêm (Đỏ)', '${lateChildren.length}', PdfColors.red700),
                _summaryCell('Sắp tiêm (Vàng)', '${dueSoonChildren.length}', PdfColors.orange700),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Bảng trẻ TRỄ tiêm
          if (lateChildren.isNotEmpty) ...[
            pw.Text(
              '⚠️ DANH SÁCH TRẺ TRỄ LỊCH TIÊM CHỦNG (${lateChildren.length} trẻ)',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfColors.red700,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildChildTable(lateChildren),
            pw.SizedBox(height: 16),
          ],

          // Bảng trẻ SẮP tiêm
          if (dueSoonChildren.isNotEmpty) ...[
            pw.Text(
              '🔔 DANH SÁCH TRẺ SẮP ĐẾN LỊCH TIÊM (${dueSoonChildren.length} trẻ)',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfColors.orange700,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildChildTable(dueSoonChildren),
          ],

          pw.SizedBox(height: 24),
          pw.Text(
            'Báo cáo được tạo tự động bởi Hệ thống CommunityHealth vào lúc '
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} '
            'ngày ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'BaoCaoTiemChung_$commune.pdf',
    );
  }

  /// Xuất báo cáo tình hình dịch bệnh PDF
  Future<void> exportDiseaseReportPdf({
    required List<DiseaseReport> reports,
    required String commune,
    required String reporterName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(commune, reporterName, title: 'Báo cáo Giám sát Dịch bệnh'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Text(
            'DANH SÁCH BÁO CÁO CA BỆNH NGÃ – ${reports.length} ca',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['STT', 'Bệnh nhân', 'Loại bệnh', 'Thôn/Xã', 'Ngày báo', 'Trạng thái', 'Mức độ'],
            data: List.generate(reports.length, (i) {
              final r = reports[i];
              return [
                '${i + 1}',
                r.patientName,
                r.diseaseType,
                '${r.village}, ${r.commune}',
                '${r.reportedAt.day}/${r.reportedAt.month}/${r.reportedAt.year}',
                r.status,
                r.severity.name,
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red50),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'BaoCaoDichBenh_$commune.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  pw.Widget _buildPdfHeader(String commune, String reporter,
      {String title = 'Báo cáo Tiêm chủng & Theo dõi Sức khoẻ Trẻ em'}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TRUNG TÂM Y TẾ HUYỆN SA PA',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.grey600)),
                pw.Text('TRẠM Y TẾ XÃ ${commune.toUpperCase()}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.green700)),
              ],
            ),
            pw.Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 15,
              color: PdfColors.green800,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Người lập báo cáo: $reporter • Xã $commune • Năm ${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.green700, thickness: 2),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('CommunityHealth System',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.Text('Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    );
  }

  pw.Widget _buildChildTable(List<ChildProfile> children) {
    return pw.TableHelper.fromTextArray(
      headers: ['STT', 'Họ và tên', 'Ngày sinh', 'Thôn bản', 'Tên mẹ', 'SĐT mẹ', 'Mũi tiêm cần', 'Trễ (ngày)'],
      data: List.generate(children.length, (i) {
        final c = children[i];
        return [
          '${i + 1}',
          c.fullName,
          '${c.dateOfBirth.day}/${c.dateOfBirth.month}/${c.dateOfBirth.year}',
          c.village,
          c.motherName,
          c.motherPhone,
          c.nextVaccine ?? '—',
          c.lateDays > 0 ? '${c.lateDays} ngày' : 'Sắp đến',
        ];
      }),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
      cellAlignments: {0: pw.Alignment.center},
    );
  }

  pw.Widget _summaryCell(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  String _statusLabel(ChildVaccinationStatus s) {
    switch (s) {
      case ChildVaccinationStatus.late:
        return 'Trễ tiêm';
      case ChildVaccinationStatus.dueSoon:
        return 'Sắp tiêm';
      case ChildVaccinationStatus.complete:
        return 'Hoàn thành';
    }
  }

  /// Tạo PDF dạng bytes (dùng cho Web download / share)
  Future<Uint8List> buildChildrenPdfBytes({
    required List<ChildProfile> children,
    required String commune,
    required String reporterName,
  }) async {
    final pdf = pw.Document();
    final lateChildren = children.where((c) => c.status == ChildVaccinationStatus.late).toList();
    final dueSoonChildren = children.where((c) => c.status == ChildVaccinationStatus.dueSoon).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildPdfHeader(commune, reporterName),
        footer: (ctx) => _buildPdfFooter(ctx),
        build: (ctx) => [
          if (lateChildren.isNotEmpty) ...[
            pw.Text('⚠️ DANH SÁCH TRẺ TRỄ LỊCH TIÊM CHỦNG',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.red700)),
            pw.SizedBox(height: 8),
            _buildChildTable(lateChildren),
            pw.SizedBox(height: 16),
          ],
          if (dueSoonChildren.isNotEmpty) ...[
            pw.Text('🔔 DANH SÁCH TRẺ SẮP ĐẾN LỊCH TIÊM',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.orange700)),
            pw.SizedBox(height: 8),
            _buildChildTable(dueSoonChildren),
          ],
        ],
      ),
    );
    return pdf.save();
  }
}
