class TravelFolder {
  String id;
  String name;
  DateTime creationDate;

  TravelFolder({
    required this.id,
    required this.name,
    required this.creationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creationDate': creationDate.toIso8601String(),
    };
  }

  factory TravelFolder.fromJson(Map<String, dynamic> json) {
    return TravelFolder(
      id: json['id'],
      name: json['name'],
      creationDate: DateTime.parse(json['creationDate']),
    );
  }

  @override
  String toString() {
    return 'TravelFolder(id: $id, name: $name, creationDate: $creationDate)';
  }
}
