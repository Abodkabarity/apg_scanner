import 'package:uuid/uuid.dart';

import '../../core/session/user_session.dart';
import '../model/project_model.dart';
import '../services/local_storage_service.dart';

class ProjectRepository {
  final LocalStorageService local;
  final UserSession session;

  List<ProjectModel> projects = [];

  ProjectRepository(this.local, this.session);

  // 🔑 مفتاح التخزين حسب المستخدم
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

    // 🔥 تحميل مشاريع هذا المستخدم فقط
    projects = await local.loadProjects(_userKey());
  }

  // ================= CREATE =================
  Future<ProjectModel> createProject(String name) async {
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
    );

    projects.add(newProject);

    // 🔥 حفظ مشاريع هذا المستخدم فقط
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
