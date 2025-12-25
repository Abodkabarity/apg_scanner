import 'package:equatable/equatable.dart';

import '../../../core/constant/project_type.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class CreateProjectEvent extends ProjectEvent {
  final String name;
  final ProjectType projectType;
  const CreateProjectEvent(this.name, this.projectType);

  @override
  List<Object?> get props => [name];
}

class LoadSavedProjectEvent extends ProjectEvent {}

class ClearProjectEvent extends ProjectEvent {}

class LoadProjectsEvent extends ProjectEvent {
  final ProjectType projectType;

  const LoadProjectsEvent(this.projectType);

  @override
  List<Object?> get props => [projectType];
}

class DeleteProjectEvent extends ProjectEvent {
  final String id;
  final ProjectType projectType;
  const DeleteProjectEvent(this.id, this.projectType);
}

class LogoutRequested extends ProjectEvent {}
