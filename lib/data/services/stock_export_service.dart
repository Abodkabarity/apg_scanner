import 'dart:convert';

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/excel_exporter.dart';
import '../repositories/stock_taking_repository.dart';

class StockExportService {
  final StockRepository repo;

  StockExportService(this.repo);

  /// ✅ Save Excel (System Save Dialog – SAF)
  Future<void> exportAndSaveExcel(String projectId) async {
    final data = await repo.fetchUploadedItems(projectId);

    final saved = await ExcelExporter.saveExcelWithSystemPicker(
      data,
      fileName: 'StockTaking_$projectId.xlsx',
    );

    if (!saved) {
      return;
    }
  }

  /// ✅ Share Excel (system share)
  Future<void> exportAndShareExcel(String projectId) async {
    final data = await repo.fetchUploadedItems(projectId);

    final bytes = await ExcelExporter.buildExcelBytes(data);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'StockTaking_$projectId.xlsx',
          ),
        ],
        subject: 'Stock Taking Report',
        text: 'Please find attached stock taking report.',
      ),
    );
  }

  /// Send Excel directly via Email
  Future<void> sendExcelByEmail({
    required String projectId,
    required String projectName,
    required String toEmail,
  }) async {
    final data = await repo.fetchUploadedItems(projectId);

    if (data.isEmpty) {
      throw Exception('No data to send');
    }
    final safeName = projectName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final bytes = await ExcelExporter.buildExcelBytes(data);
    final fileBase64 = base64Encode(bytes);

    final response = await Supabase.instance.client.functions.invoke(
      'send-stock-email',
      body: {
        'to': toEmail,
        'subject': 'Stock Taking Report - $safeName',
        'text': 'Please find attached stock taking report.',
        'fileName': 'StockTaking_$safeName.xlsx',
        'fileBase64': fileBase64,
      },
    );

    final resData = response.data;

    if (resData == null) {
      throw Exception('Email sending failed');
    }

    if (resData is Map) {
      final success = resData['success'] ?? resData['ok'];
      if (success != true) {
        throw Exception(resData['error'] ?? 'Email sending failed');
      }
    }
  }
}
