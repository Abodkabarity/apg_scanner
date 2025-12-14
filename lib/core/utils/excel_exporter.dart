import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelExporter {
  static Future<Uint8List> buildExcelBytes(
    List<Map<String, dynamic>> data,
  ) async {
    final excel = Excel.createExcel();

    final sheet = excel['Stock'];

    sheet.appendRow([
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('Unit'),
      TextCellValue('Quantity'),
      TextCellValue('Branch'),
    ]);

    for (final row in data) {
      sheet.appendRow([
        TextCellValue(row['item_code']?.toString() ?? ''),
        TextCellValue(row['item_name']?.toString() ?? ''),
        TextCellValue(row['unit_type']?.toString() ?? ''),
        IntCellValue(int.tryParse(row['quantity']?.toString() ?? '0') ?? 0),
        TextCellValue(row['branch']?.toString() ?? ''),
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
