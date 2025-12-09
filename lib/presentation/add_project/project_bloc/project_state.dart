import 'package:equatable/equatable.dart';

import '../../../data/model/project_model.dart';

class ProjectState extends Equatable {
  final bool loading;
  final bool success;
  final String? error;
  final ProjectModel? project;
  final List<ProjectModel> projects;

  const ProjectState({
    this.loading = false,
    this.success = false,
    this.error,
    this.project,
    this.projects = const [],
  });

  ProjectState copyWith({
    bool? loading,
    bool? success,
    String? error,
    ProjectModel? project,
    List<ProjectModel>? projects,
  }) {
    return ProjectState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error,
      project: project ?? this.project,
      projects: projects ?? this.projects,
    );
  }

  @override
  List<Object?> get props => [loading, success, error, project, projects];
}
