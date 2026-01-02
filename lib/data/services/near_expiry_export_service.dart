import 'dart:convert';

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/excel_exporter.dart';
import '../repositories/near_expiry_repository.dart';

class NearExpiryExportService {
  final NearExpiryRepository repo;

  NearExpiryExportService(this.repo);

  /// ✅ Save Excel (System Save Dialog) - MERGED
  /// ✅ Save Excel (System Save Dialog) - EXACT SAME AS EMAIL
  Future<void> exportAndSaveExcel({
    required String projectId,
    required String projectName,
  }) async {
    final data = await repo.buildMergedNearExpiryExcelData(projectId);

    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final safeName = projectName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    await ExcelExporter.saveNearExpiryExcel(
      data,
      fileName: 'NearExpiry_$safeName.xlsx',
    );
  }

  /// ✅ Share Excel (system share) - MERGED
  Future<void> exportAndShareExcel({
    required String projectId,
    required String projectName,
  }) async {
    final data = await repo.buildMergedNearExpiryExcelData(projectId);

    if (data.isEmpty) {
      throw Exception('No data to share');
    }

    final bytes = await ExcelExporter.buildNearExpiryExcelBytes(data);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'NearExpiry_$projectName.xlsx',
          ),
        ],
        subject: 'Near Expiry Report',
        text: 'Please find attached near expiry report.',
      ),
    );
  }

  /// ✅ Send Excel via Email (Supabase Function) - MERGED
  Future<void> sendExcelByEmail({
    required String projectId,
    required String projectName,
    required String toEmail,
  }) async {
    final data = await repo.buildMergedNearExpiryExcelData(projectId);

    if (data.isEmpty) {
      throw Exception('No data to send');
    }

    final bytes = await ExcelExporter.buildNearExpiryExcelBytes(data);
    final fileBase64 = base64Encode(bytes);

    final safeName = projectName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    final response = await Supabase.instance.client.functions.invoke(
      'send-stock-email',
      body: {
        'to': toEmail,
        'subject': 'Near Expiry Report - $safeName',
        'text': 'Please find attached near expiry report.',
        'fileName': 'NearExpiry_$safeName.xlsx',
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
