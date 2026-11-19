import '../core/id_codec.dart';
import 'list_query.dart';

class Team implements Identifiable {
  @override
  final String id;
  final String name;
  final String city;
  final int foundedYear;

  final String arenaId;

  final String arenaName;

  final String? sponsorId;

  final int rosterSize;

  @override
  final DateTime? deletedAt;

  const Team({
    required this.id,
    required this.name,
    required this.city,
    this.foundedYear = 0,
    this.arenaId = '',
    this.arenaName = '',
    this.sponsorId,
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
    String? arenaId,
    String? arenaName,
    String? sponsorId,
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
      sponsorId: sponsorId ?? this.sponsorId,
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
        'sponsorId': sponsorId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Team.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'];
    final expandMap = expand is Map
        ? Map<String, dynamic>.from(expand)
        : const <String, dynamic>{};
    final arena = json['arena'] ?? expandMap['arena'];
    final arenaMap = arena is Map
        ? Map<String, dynamic>.from(arena)
        : const <String, dynamic>{};
    final sponsor = json['sponsor'] ?? expandMap['sponsor'];
    return Team(
      id: readId(json['id']),
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      foundedYear: (json['foundedYear'] as num?)?.toInt() ?? 0,
      arenaId: readId(json['arenaId'] ?? json['arena'] ?? arenaMap['id']),
      arenaName:
          json['arenaName'] as String? ?? arenaMap['name'] as String? ?? '',
      sponsorId: () {
        final raw = json['sponsorId'] ?? json['sponsor'] ??
            (sponsor is Map ? sponsor['id'] : sponsor);
        final id = readId(raw);
        return id.isEmpty ? null : id;
      }(),
      rosterSize: (json['rosterSize'] as num?)?.toInt() ?? 0,
      deletedAt: readDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'name': name,
        'city': city,
        'foundedYear': foundedYear,
        'arena': arenaId,
        if (sponsorId != null && sponsorId!.isNotEmpty) 'sponsor': sponsorId,
      };

  @override
  String toString() => 'Team($id, $name, $city)';
}
