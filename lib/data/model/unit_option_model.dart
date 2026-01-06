class UnitOptionModel {
  final String name;

  const UnitOptionModel({required this.name});

  factory UnitOptionModel.fromMap(Map<String, dynamic> map) {
    final raw =
        (map['unit'] ?? map['name'] ?? map['unit_name'] ?? map['title'] ?? '')
            .toString()
            .trim();

    return UnitOptionModel(name: raw);
  }
}
