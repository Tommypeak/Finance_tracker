import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction_model.dart';

// Для Web-скачивания CSV
// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;

class ExportService {
  static String _escape(String s) {
    final needsQuotes =
        s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    if (!needsQuotes) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  static String _type(TransactionType t) =>
      t == TransactionType.income ? 'income' : 'expense';

  static String buildCsv({
    required List<TransactionModel> transactions,
    required String datePattern,
  }) {
    final dateFmt = DateFormat(datePattern);
    final b = StringBuffer();

    b.writeln('date,type,category,amount,note');

    for (final t in transactions) {
      final date = dateFmt.format(t.date);
      final type = _type(t.type);
      final category = _escape(t.category);
      final amount = t.amount.toString();
      final note = _escape(t.note);

      b.writeln('$date,$type,$category,$amount,$note');
    }

    return b.toString();
  }

  static Future<void> exportCsv({
    required List<TransactionModel> transactions,
    required String datePattern,
    String filePrefix = 'finance_report',
  }) async {
    final csv = buildCsv(
      transactions: transactions,
      datePattern: datePattern,
    );

    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = '${filePrefix}_$stamp.csv';

    if (kIsWeb) {
      // ✅ WEB: скачать файл
      final bytes = Uint8List.fromList(csv.codeUnits);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);
      return;
    }

    // ✅ Mobile/Desktop: share dialog
    final xfile = XFile.fromData(
      Uint8List.fromList(csv.codeUnits), // ✅ теперь Uint8List
      mimeType: 'text/csv',
      name: fileName,
    );

    await Share.shareXFiles([xfile], text: 'CSV report');
  }
}
