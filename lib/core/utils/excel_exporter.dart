import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelExporter {
  static Future<Uint8List> buildExcelBytes(
    List<Map<String, dynamic>> data,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stock'];

    // 🔹 Header
    sheet.appendRow([
      TextCellValue('Branch'),
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('Unit'),
      TextCellValue('Quantity'),
    ]);

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final row in data) {
      final branch = row['branch']?.toString() ?? '';
      final itemCode = row['item_code']?.toString() ?? '';
      final itemName = row['item_name']?.toString() ?? '';

      final key = '$branch|$itemCode';

      final double subQty =
          double.tryParse(row['sub_quantity']?.toString() ?? '0') ?? 0;

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'branch': branch,
          'item_code': itemCode,
          'item_name': itemName,
          'total_qty': subQty,
        };
      } else {
        grouped[key]!['total_qty'] =
            (grouped[key]!['total_qty'] as double) + subQty;
      }
    }

    for (final g in grouped.values) {
      sheet.appendRow([
        TextCellValue(g['branch']),
        TextCellValue(g['item_code']),
        TextCellValue(g['item_name']),
        TextCellValue('Box'),
        TextCellValue((g['total_qty'] as double).toStringAsFixed(2)),
      ]);
    }

    excel.delete('Sheet1');
    excel.setDefaultSheet('Stock');

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<bool> saveExcelWithSystemPicker(
    List<Map<String, dynamic>> data, {
    required String fileName,
  }) async {
    final bytes = await buildExcelBytes(data);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Stock Taking Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );

    return path != null;
  }
}
