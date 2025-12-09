import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/project_model.dart';

class LocalStorageService {
  static const String _key = "projects_data";

  Future<void> saveProjects(List<ProjectModel> projects) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());

    await prefs.setString(_key, encoded);
  }

  Future<List<ProjectModel>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((e) => ProjectModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
