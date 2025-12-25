class Subject {
  final String id;
  final String name;

  const Subject({
    required this.id,
    required this.name,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  Subject copyWith({String? id, String? name}) => Subject(
    id: id ?? this.id,
    name: name ?? this.name,
  );
}