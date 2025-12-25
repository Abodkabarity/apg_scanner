import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelExporter {
  // ===================================================================
  // 🟦 STOCK TAKING EXCEL
  // ===================================================================
  static Future<Uint8List> buildStockTakingExcelBytes(
    List<Map<String, dynamic>> data,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stock Taking'];

    // ---------------- Header ----------------
    sheet.appendRow([
      TextCellValue('Branch'),
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('Unit'),
      TextCellValue('Quantity'),
    ]);

    for (final row in data) {
      sheet.appendRow([
        TextCellValue(row['branch']?.toString() ?? ''),
        TextCellValue(row['item_code']?.toString() ?? ''),
        TextCellValue(row['item_name']?.toString() ?? ''),
        TextCellValue(row['unit_type']?.toString() ?? ''),
        TextCellValue(row['sub_quantity']?.toString() ?? '0'),
      ]);
    }

    excel.delete('Sheet1');
    excel.setDefaultSheet('Stock Taking');

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<bool> saveStockTakingExcel(
    List<Map<String, dynamic>> data, {
    required String fileName,
  }) async {
    final bytes = await buildStockTakingExcelBytes(data);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Stock Taking Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );

    return path != null;
  }

  // ===================================================================
  // 🟧 NEAR EXPIRY EXCEL
  // ===================================================================
  static Future<Uint8List> buildNearExpiryExcelBytes(
    List<Map<String, dynamic>> data,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Near Expiry'];

    // ---------------- Header ----------------
    sheet.appendRow([
      TextCellValue('Branch'),
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('Unit'),
      TextCellValue('Quantity'),
      TextCellValue('Near Expiry Date'),
    ]);

    for (final row in data) {
      sheet.appendRow([
        TextCellValue(row['branch']?.toString() ?? ''),
        TextCellValue(row['item_code']?.toString() ?? ''),
        TextCellValue(row['item_name']?.toString() ?? ''),
        TextCellValue(row['unit_type']?.toString() ?? ''),
        TextCellValue(row['quantity']?.toString() ?? '0'),
        TextCellValue(row['near_expiry']?.toString() ?? ''),
      ]);
    }

    excel.delete('Sheet1');
    excel.setDefaultSheet('Near Expiry');

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<bool> saveNearExpiryExcel(
    List<Map<String, dynamic>> data, {
    required String fileName,
  }) async {
    final bytes = await buildNearExpiryExcelBytes(data);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Near Expiry Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );

    return path != null;
  }
}
