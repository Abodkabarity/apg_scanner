import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/project_model.dart';

class LocalStorageService {
  // ================= SAVE =================
  Future<void> saveProjects(String key, List<ProjectModel> projects) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());

    await prefs.setString(key, encoded);
  }

  // ================= LOAD =================
  Future<List<ProjectModel>> loadProjects(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded
          .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ================= CLEAR =================
  Future<void> clearProjects(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
