import '../core/id_codec.dart';
import 'contract.dart';
import 'list_query.dart';

class HockeyPlayer implements Identifiable {
  @override
  final String id;

  final String name;
  final String description;
  final double price;

  final String category;

  final String teamId;

  final String teamName;

  final List<String> achievementIds;

  final List<String> achievementNames;

  final Contract? contract;

  final int? jerseyNumber;

  /// in_roster | injured | suspended | free_agent
  final String status;

  final String notes;

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
    this.status = 'in_roster',
    this.notes = '',
    this.deletedAt,
  });

  static const statusLabels = <String, String>{
    'in_roster': 'В строю',
    'injured': 'Травмирован',
    'suspended': 'Дисквалифицирован',
    'free_agent': 'Свободный агент',
  };

  String get statusLabel => statusLabels[status] ?? status;

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
    String? teamId,
    String? teamName,
    List<String>? achievementIds,
    List<String>? achievementNames,
    Contract? contract,
    int? jerseyNumber,
    String? status,
    String? notes,
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
      status: status ?? this.status,
      notes: notes ?? this.notes,
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
        'status': status,
        'notes': notes,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory HockeyPlayer.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'];
    final expandMap = expand is Map
        ? Map<String, dynamic>.from(expand)
        : const <String, dynamic>{};
    final team = json['team'] ?? expandMap['team'];
    final teamMap =
        team is Map ? Map<String, dynamic>.from(team) : const <String, dynamic>{};
    final achievementsRaw =
        json['achievements'] ?? expandMap['achievements_via_player'];
    final achievementMaps = achievementsRaw is List
        ? [
            for (final item in achievementsRaw)
              if (item is Map) Map<String, dynamic>.from(item),
          ]
        : const <Map<String, dynamic>>[];
    final idsFromExpanded = [
      for (final item in achievementMaps)
        readId(item['achievement'] ?? item['id']),
    ].where((id) => id.isNotEmpty).toList();
    final namesFromExpanded = [
      for (final item in achievementMaps)
        if (item['expand'] is Map &&
            (item['expand'] as Map)['achievement'] is Map)
          '${((item['expand'] as Map)['achievement'] as Map)['name'] ?? ''}'
        else
          item['name'] as String? ?? '',
    ].where((name) => name.isNotEmpty).toList();

    Contract? contract;
    final contractRaw = json['contract'] ?? expandMap['contracts_via_player'];
    if (contractRaw is Map) {
      contract = Contract.fromJson(Map<String, dynamic>.from(contractRaw));
    } else if (contractRaw is List && contractRaw.isNotEmpty) {
      final first = contractRaw.first;
      if (first is Map) {
        contract = Contract.fromJson(Map<String, dynamic>.from(first));
      }
    }

    return HockeyPlayer(
      id: readId(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      teamId: readId(json['teamId'] ?? json['team'] ?? teamMap['id']),
      teamName: json['teamName'] as String? ?? teamMap['name'] as String? ?? '',
      achievementIds: json['achievementIds'] is List
          ? readIdList(json['achievementIds'])
          : idsFromExpanded,
      achievementNames: json['achievementNames'] is List
          ? [
              for (final n in json['achievementNames'] as List) '$n',
            ]
          : namesFromExpanded,
      contract: contract,
      jerseyNumber: (json['jerseyNumber'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'in_roster',
      notes: json['notes'] as String? ?? '',
      deletedAt: readDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'team': teamId,
        'jerseyNumber': jerseyNumber,
        'status': status,
        'notes': notes,
      };

  @override
  String toString() => 'HockeyPlayer($id, $name, $teamName)';
}
