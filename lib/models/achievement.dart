import 'list_query.dart';

class Achievement implements Identifiable {
  @override
  final int id;

  final String name;

  final String description;

  final int year;

  final int holderCount;

  @override
  final DateTime? deletedAt;

  const Achievement({
    required this.id,
    required this.name,
    this.description = '',
    this.year = 0,
    this.holderCount = 0,
    this.deletedAt,
  });

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => name;

  Achievement copyWith({
    String? name,
    String? description,
    int? year,
    int? holderCount,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Achievement(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      year: year ?? this.year,
      holderCount: holderCount ?? this.holderCount,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'year': year,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        holderCount: json['holderCount'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  Map<String, dynamic> toApiBody() => {
        'name': name,
        'description': description,
        'year': year,
      };

  @override
  String toString() => 'Achievement($id, $name)';
}
