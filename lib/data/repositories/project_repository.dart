import 'package:uuid/uuid.dart';

import '../../core/session/user_session.dart';
import '../model/project_model.dart';
import '../services/local_storage_service.dart';

class ProjectRepository {
  final LocalStorageService local;
  final UserSession session;

  List<ProjectModel> projects = [];

  ProjectRepository(this.local, this.session);

  Future<void> loadAllProjects() async {
    projects = await local.loadProjects();
  }

  Future<ProjectModel> createProject(String name) async {
    final newProject = ProjectModel(
      id: const Uuid().v4(),
      name: name,
      branch: session.branch!,
      createdAt: DateTime.now(),
    );
    projects.add(newProject);

    await local.saveProjects(projects);

    return newProject;
  }

  Future<void> deleteProject(String id) async {
    projects.removeWhere((p) => p.id == id);
    await local.saveProjects(projects);
  }

  List<ProjectModel> getAll() => projects;
}
