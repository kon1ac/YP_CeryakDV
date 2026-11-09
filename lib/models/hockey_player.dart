import 'list_query.dart';

class HockeyPlayer implements Identifiable {
  @override
  final int id;

  final String name;
  final String description;
  final double price;

  final String category;

  final String team;

  final int? jerseyNumber;

  @override
  final DateTime? deletedAt;

  const HockeyPlayer({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.team,
    this.jerseyNumber,
    this.deletedAt,
  });

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => name;

  HockeyPlayer copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? team,
    int? jerseyNumber,
    DateTime? deletedAt,

    bool clearDeletedAt = false,
  }) {
    return HockeyPlayer(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      team: team ?? this.team,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  String toString() => 'HockeyPlayer($id, $name, $team)';
}
