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

  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(loading: true, success: false, error: null));

    try {
      final newProject = await repo.createProject(event.name);
      print("sucess");

      emit(
        state.copyWith(
          loading: false,
          success: true,
          projects: repo.getAll(),
          project: newProject,
        ),
      );
    } catch (e) {
      print("erre");
      emit(state.copyWith(loading: false, success: false, error: e.toString()));
    }
  }

  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    try {
      await repo.loadAllProjects();

      emit(state.copyWith(loading: false, projects: repo.getAll()));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await repo.deleteProject(event.id);

      emit(state.copyWith(projects: repo.getAll()));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
