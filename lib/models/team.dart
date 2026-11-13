import 'list_query.dart';

class Team implements Identifiable {
  @override
  final int id;
  final String name;
  final String city;
  final int foundedYear;

  final int arenaId;

  final String arenaName;

  final int rosterSize;

  @override
  final DateTime? deletedAt;

  const Team({
    required this.id,
    required this.name,
    required this.city,
    this.foundedYear = 0,
    this.arenaId = 0,
    this.arenaName = '',
    this.rosterSize = 0,
    this.deletedAt,
  });

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => name;

  Team copyWith({
    String? name,
    String? city,
    int? foundedYear,
    int? arenaId,
    String? arenaName,
    int? rosterSize,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      foundedYear: foundedYear ?? this.foundedYear,
      arenaId: arenaId ?? this.arenaId,
      arenaName: arenaName ?? this.arenaName,
      rosterSize: rosterSize ?? this.rosterSize,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'foundedYear': foundedYear,
        'arenaId': arenaId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Team.fromJson(Map<String, dynamic> json) {
    final arena = json['arena'];
    final arenaMap = arena is Map
        ? Map<String, dynamic>.from(arena)
        : const <String, dynamic>{};
    return Team(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      foundedYear: json['foundedYear'] as int? ?? 0,
      arenaId: json['arenaId'] as int? ?? arenaMap['id'] as int? ?? 0,
      arenaName:
          json['arenaName'] as String? ?? arenaMap['name'] as String? ?? '',
      rosterSize: json['rosterSize'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'name': name,
        'city': city,
        'foundedYear': foundedYear,
        'arenaId': arenaId,
      };

  @override
  String toString() => 'Team($id, $name, $city)';
}
