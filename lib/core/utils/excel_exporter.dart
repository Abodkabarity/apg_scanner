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

  // ✅ Near Expiry Excel Bytes
  static Future<Uint8List> buildNearExpiryExcelBytes(
    List<Map<String, dynamic>> data,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Near Expiry'];

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
        TextCellValue(row['unit_type']?.toString() ?? 'BOX'),
        TextCellValue(row['qty']?.toString() ?? '0'),
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

  // ------------------------------------------------------------
  // STOCK BATCH EXCEL BYTES
  // ------------------------------------------------------------
  static Future<Uint8List> buildStockBatchExcelBytes(
    List<Map<String, dynamic>> data,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stock Batch'];

    // HEADER
    sheet.appendRow([
      TextCellValue('Branch'),
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('Barcode'),
      TextCellValue('Unit'),
      TextCellValue('Quantity'),
      TextCellValue('Near Expiry'),
      TextCellValue('Batch'),
      TextCellValue('Created At'),
    ]);

    for (final row in data) {
      sheet.appendRow([
        TextCellValue(row['Branch']?.toString() ?? ''),
        TextCellValue(row['Item Code']?.toString() ?? ''),
        TextCellValue(row['Item Name']?.toString() ?? ''),
        TextCellValue(row['Barcode']?.toString() ?? ''),
        TextCellValue(row['Unit']?.toString() ?? ''),
        TextCellValue(row['Quantity']?.toString() ?? '0'),
        TextCellValue(row['Near Expiry']?.toString() ?? ''),
        TextCellValue(row['Batch']?.toString() ?? ''),
        TextCellValue(row['Created At']?.toString() ?? ''),
      ]);
    }

    excel.delete('Sheet1');
    excel.setDefaultSheet('Stock Batch');

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<void> saveStockBatchExcel(
    List<Map<String, dynamic>> data, {
    required String fileName,
  }) async {
    final bytes = await buildStockBatchExcelBytes(data);
    await saveExcel(bytes, fileName);
  }

  static Future<void> saveExcel(Uint8List bytes, String fileName) async {
    await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
  }
}
