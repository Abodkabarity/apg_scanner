import 'package:uuid/uuid.dart';

import '../../core/constant/project_type.dart';
import '../../core/session/user_session.dart';
import '../model/project_model.dart';
import '../services/local_storage_service.dart';

class ProjectRepository {
  final LocalStorageService local;
  final UserSession session;

  List<ProjectModel> projects = [];

  ProjectRepository(this.local, this.session);

  List<ProjectModel> getByType(ProjectType type) {
    return projects.where((p) => p.projectType == type).toList();
  }

  String _userKey() {
    final userId = session.userId;
    if (userId == null) {
      throw Exception("User not logged in");
    }
    return 'projects_$userId';
  }

  // ================= LOAD =================
  Future<void> loadAllProjects() async {
    final userId = session.userId;
    if (userId == null) {
      projects = [];
      return;
    }

    projects = await local.loadProjects(_userKey());
  }

  // ================= CREATE =================
  Future<ProjectModel> createProject(
    String name,
    ProjectType projectType, // 🔥 NEW
  ) async {
    final userId = session.userId;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    final newProject = ProjectModel(
      id: const Uuid().v4(),
      name: name,
      branch: session.branch!,
      createdAt: DateTime.now(),
      userId: userId,
      projectType: projectType,
    );

    projects.add(newProject);

    await local.saveProjects(_userKey(), projects);

    return newProject;
  }

  // ================= DELETE =================
  Future<void> deleteProject(String id) async {
    projects.removeWhere((p) => p.id == id);

    await local.saveProjects(_userKey(), projects);
  }

  // ================= OTHERS =================
  void clearCache() {
    projects.clear();
  }

  List<ProjectModel> getAll() => projects;
}
