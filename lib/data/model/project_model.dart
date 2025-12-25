import '../../core/constant/project_type.dart';

class ProjectModel {
  final String id;
  final String name;
  final String branch;
  final DateTime createdAt;
  final String userId;

  final ProjectType projectType;

  ProjectModel({
    required this.id,
    required this.name,
    required this.branch,
    required this.createdAt,
    required this.userId,
    required this.projectType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'branch': branch,
    'created_at': createdAt.toIso8601String(),
    'user_id': userId,

    'project_type': projectType.name,
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      branch: json['branch'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],

      /// 🔥 restore project type
      projectType: ProjectType.values.firstWhere(
        (e) => e.name == json['project_type'],
        orElse: () => ProjectType.stockTaking,
      ),
    );
  }
}
