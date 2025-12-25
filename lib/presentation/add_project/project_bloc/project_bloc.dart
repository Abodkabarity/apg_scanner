import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/model/project_model.dart';
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
    emit(
      state.copyWith(
        loading: true,
        createSuccess: false,
        deleteSuccess: false,
        error: null,
      ),
    );

    try {
      final newProject = await repo.createProject(
        event.name,
        event.projectType,
      );

      emit(
        state.copyWith(
          loading: false,
          createSuccess: true,
          deleteSuccess: false,
          projects: repo.getAll(),
          project: newProject,
        ),
      );

      emit(state.copyWith(createSuccess: false, deleteSuccess: false));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          createSuccess: false,
          deleteSuccess: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    try {
      await repo.loadAllProjects();

      emit(
        state.copyWith(
          loading: false,
          projects: List<ProjectModel>.from(repo.getAll()),
        ),
      );
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

      final updatedList = List<ProjectModel>.from(repo.getAll());

      emit(
        state.copyWith(
          loading: false,
          createSuccess: false,
          deleteSuccess: true,
          projects: updatedList,
        ),
      );

      emit(state.copyWith(deleteSuccess: false, createSuccess: false));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          deleteSuccess: false,
          error: e.toString(),
        ),
      );
    }
  }
}
