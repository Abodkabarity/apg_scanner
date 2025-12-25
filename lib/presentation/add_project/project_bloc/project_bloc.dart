import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/project_repository.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository repo;

  ProjectBloc(this.repo) : super(const ProjectState()) {
    on<CreateProjectEvent>(_onCreateProject);
    on<LoadProjectsEvent>(_onLoadProjects);
    on<DeleteProjectEvent>(_onDeleteProject);
  }

  // ================= CREATE =================
  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectState(loading: true));

    try {
      final newProject = await repo.createProject(
        event.name,
        event.projectType,
      );

      final all = await repo.loadAllProjects();
      final filtered = all
          .where((p) => p.projectType == event.projectType)
          .toList();

      emit(
        ProjectState(
          loading: false,
          projects: filtered,
          project: newProject,
          createSuccess: true,
        ),
      );
    } catch (e) {
      emit(ProjectState(error: e.toString()));
    }
  }

  // ================= LOAD =================
  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectState(loading: true));

    try {
      final all = await repo.loadAllProjects();
      final filtered = all
          .where((p) => p.projectType == event.projectType)
          .toList();

      emit(ProjectState(loading: false, projects: filtered));
    } catch (e) {
      emit(ProjectState(error: e.toString()));
    }
  }

  // ================= DELETE (🔥 الحل هنا) =================
  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectState(loading: true));

    try {
      final allAfterDelete = await repo.deleteProject(event.id);

      final filtered = allAfterDelete
          .where((p) => p.projectType == event.projectType)
          .toList();

      emit(
        ProjectState(loading: false, projects: filtered, deleteSuccess: true),
      );
    } catch (e) {
      emit(ProjectState(error: e.toString()));
    }
  }
}
