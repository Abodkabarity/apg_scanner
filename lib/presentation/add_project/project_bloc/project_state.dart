import 'package:equatable/equatable.dart';

import '../../../data/model/project_model.dart';

class ProjectState extends Equatable {
  final bool loading;

  final bool createSuccess;

  final bool deleteSuccess;

  final String? error;

  final ProjectModel? project;

  final List<ProjectModel> projects;

  const ProjectState({
    this.loading = false,
    this.createSuccess = false,
    this.deleteSuccess = false,
    this.error,
    this.project,
    this.projects = const [],
  });

  ProjectState copyWith({
    bool? loading,
    bool? createSuccess,
    bool? deleteSuccess,
    String? error,
    ProjectModel? project,
    List<ProjectModel>? projects,
  }) {
    return ProjectState(
      loading: loading ?? this.loading,

      createSuccess: createSuccess ?? this.createSuccess,
      deleteSuccess: deleteSuccess ?? this.deleteSuccess,

      error: error,
      project: project ?? this.project,
      projects: projects ?? this.projects,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    createSuccess,
    deleteSuccess,
    error,
    project,
    projects,
  ];
}
