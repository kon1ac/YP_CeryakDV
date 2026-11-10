import 'list_query.dart';

class Arena implements Identifiable {
  @override
  final int id;

  final String name;

  final String city;

  final int capacity;

  final int teamCount;

  @override
  final DateTime? deletedAt;

  const Arena({
    required this.id,
    required this.name,
    required this.city,
    this.capacity = 0,
    this.teamCount = 0,
    this.deletedAt,
  });

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => name;

  Arena copyWith({
    String? name,
    String? city,
    int? capacity,
    int? teamCount,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Arena(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      capacity: capacity ?? this.capacity,
      teamCount: teamCount ?? this.teamCount,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'capacity': capacity,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Arena.fromJson(Map<String, dynamic> json) => Arena(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        capacity: json['capacity'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  @override
  String toString() => 'Arena($id, $name)';
}
