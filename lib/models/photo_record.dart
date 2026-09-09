class PhotoRecord {
  final String id;
  final String path;
  final String description;
  final DateTime createdAt;

  PhotoRecord({
    required this.id,
    required this.path,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PhotoRecord.fromMap(Map<String, dynamic> map) {
    return PhotoRecord(
      id: map['id'],
      path: map['path'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
