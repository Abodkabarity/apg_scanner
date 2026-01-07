import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/excel_exporter.dart';
import '../repositories/stock_batch_repository.dart';

class StockBatchExportService {
  final StockBatchRepository repo;

  StockBatchExportService(this.repo);

  // ---------------------------------------------------------------------------
  // 💾 SAVE EXCEL (DEVICE)
  // ---------------------------------------------------------------------------
  Future<void> exportAndSaveExcel({
    required String projectId,
    required String projectName,
  }) async {
    final data = await repo.buildStockBatchExcelData(projectId: projectId);

    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final safeName = projectName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    await ExcelExporter.saveStockBatchExcel(
      data,
      fileName: 'StockBatch_$safeName.xlsx',
    );
  }

  // ---------------------------------------------------------------------------
  // 🔗 SHARE EXCEL
  // ---------------------------------------------------------------------------
  Future<void> exportAndShareExcel({
    required String projectId,
    required String projectName,
  }) async {
    final data = await repo.buildStockBatchExcelData(projectId: projectId);

    if (data.isEmpty) {
      throw Exception('No data to share');
    }

    final bytes = await ExcelExporter.buildStockBatchExcelBytes(data);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes), // ✅ الحل هنا
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'StockBatch_$projectName.xlsx',
          ),
        ],
        subject: 'Stock Batch Report',
        text: 'Please find attached stock batch report.',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📧 SEND EXCEL BY EMAIL (SUPABASE FUNCTION)
  // ---------------------------------------------------------------------------
  Future<void> sendExcelByEmail({
    required String projectId,
    required String projectName,
    required String toEmail,
  }) async {
    final data = await repo.buildStockBatchExcelData(projectId: projectId);

    if (data.isEmpty) {
      throw Exception('No data to send');
    }

    final bytes = await ExcelExporter.buildStockBatchExcelBytes(data);
    final fileBase64 = base64Encode(bytes);

    final safeName = projectName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    final response = await Supabase.instance.client.functions.invoke(
      'send-stock-email',
      body: {
        'to': toEmail,
        'subject': 'Stock Batch Report - $safeName',
        'text': 'Please find attached stock batch report.',
        'fileName': 'StockBatch_$safeName.xlsx',
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
