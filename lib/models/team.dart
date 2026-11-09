import 'list_query.dart';

class Team implements Identifiable {
  @override
  final int id;
  final String name;
  final String city;
  final int foundedYear;

  final int rosterSize;

  @override
  final DateTime? deletedAt;

  const Team({
    required this.id,
    required this.name,
    required this.city,
    this.foundedYear = 0,
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
    int? rosterSize,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      foundedYear: foundedYear ?? this.foundedYear,
      rosterSize: rosterSize ?? this.rosterSize,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  String toString() => 'Team($id, $name, $city)';
}
