import 'contract.dart';
import 'list_query.dart';

class HockeyPlayer implements Identifiable {
  @override
  final int id;

  final String name;
  final String description;
  final double price;

  final String category;

  final int teamId;

  final String teamName;

  final List<int> achievementIds;

  final List<String> achievementNames;

  final Contract? contract;

  final int? jerseyNumber;

  @override
  final DateTime? deletedAt;

  const HockeyPlayer({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.teamId,
    this.teamName = '',
    this.achievementIds = const [],
    this.achievementNames = const [],
    this.contract,
    this.jerseyNumber,
    this.deletedAt,
  });

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => name;

  bool get hasContract => contract != null;

  HockeyPlayer copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    int? teamId,
    String? teamName,
    List<int>? achievementIds,
    List<String>? achievementNames,
    Contract? contract,
    int? jerseyNumber,
    DateTime? deletedAt,
    bool clearContract = false,
    bool clearDeletedAt = false,
  }) {
    return HockeyPlayer(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      achievementIds: achievementIds ?? this.achievementIds,
      achievementNames: achievementNames ?? this.achievementNames,
      contract: clearContract ? null : (contract ?? this.contract),
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'teamId': teamId,
        'achievementIds': achievementIds,
        'contract': contract?.toJson(),
        'jerseyNumber': jerseyNumber,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory HockeyPlayer.fromJson(Map<String, dynamic> json) => HockeyPlayer(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        category: json['category'] as String? ?? '',
        teamId: json['teamId'] as int? ?? 0,
        achievementIds:
            (json['achievementIds'] as List?)?.cast<int>() ?? const [],
        contract: json['contract'] == null
            ? null
            : Contract.fromJson(
                Map<String, dynamic>.from(json['contract'] as Map)),
        jerseyNumber: json['jerseyNumber'] as int?,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  @override
  String toString() => 'HockeyPlayer($id, $name, $teamName)';
}
