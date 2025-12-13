import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class CreateProjectEvent extends ProjectEvent {
  final String name;

  const CreateProjectEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class LoadSavedProjectEvent extends ProjectEvent {}

class ClearProjectEvent extends ProjectEvent {}

class LoadProjectsEvent extends ProjectEvent {}

class DeleteProjectEvent extends ProjectEvent {
  final String id;
  const DeleteProjectEvent(this.id);
}

class LogoutRequested extends ProjectEvent {}
