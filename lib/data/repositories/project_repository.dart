import 'package:uuid/uuid.dart';

import '../../core/constant/project_type.dart';
import '../../core/session/user_session.dart';
import '../model/project_model.dart';
import '../services/local_storage_service.dart';

class ProjectRepository {
  final LocalStorageService local;
  final UserSession session;

  List<ProjectModel> _projects = [];

  ProjectRepository(this.local, this.session);

  // ================= KEY =================
  String _userKey() {
    final userId = session.userId;
    if (userId == null) {
      throw Exception("User not logged in");
    }
    return 'projects_$userId';
  }

  // ================= LOAD =================
  Future<List<ProjectModel>> loadAllProjects() async {
    final userId = session.userId;
    if (userId == null) {
      _projects = [];
      return [];
    }

    final loaded = await local.loadProjects(_userKey());
    _projects = List<ProjectModel>.from(loaded); // 🔥 NEW LIST
    return List<ProjectModel>.from(_projects);
  }

  // ================= GET =================
  List<ProjectModel> getByType(ProjectType type) {
    return List<ProjectModel>.from(
      _projects.where((p) => p.projectType == type),
    );
  }

  List<ProjectModel> getAll() {
    return List<ProjectModel>.from(_projects);
  }

  // ================= CREATE =================
  Future<ProjectModel> createProject(
    String name,
    ProjectType projectType,
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

    _projects = [..._projects, newProject]; // 🔥 NEW LIST
    await local.saveProjects(_userKey(), _projects);

    return newProject;
  }

  // ================= DELETE =================
  Future<List<ProjectModel>> deleteProject(String id) async {
    _projects = _projects.where((p) => p.id != id).toList(); // 🔥 NEW LIST
    await local.saveProjects(_userKey(), _projects);

    return List<ProjectModel>.from(_projects);
  }

  // ================= CLEAR =================
  void clearCache() {
    _projects = [];
  }
}
