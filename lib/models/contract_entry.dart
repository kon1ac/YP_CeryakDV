import '../core/id_codec.dart';
import 'list_query.dart';

class ContractEntry implements Identifiable {
  const ContractEntry({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.number,
    required this.email,
    required this.salary,
    required this.signedAt,
    this.expiresAt,
    this.deletedAt,
  });

  @override
  final String id;

  final String playerId;

  final String playerName;

  final int number;

  final String email;

  final double salary;

  final DateTime signedAt;

  final DateTime? expiresAt;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => email;

  bool get isOpenEnded => expiresAt == null;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  ContractEntry copyWith({
    String? playerId,
    String? playerName,
    int? number,
    String? email,
    double? salary,
    DateTime? signedAt,
    DateTime? expiresAt,
    DateTime? deletedAt,
    bool clearExpiresAt = false,
    bool clearDeletedAt = false,
  }) {
    return ContractEntry(
      id: id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      number: number ?? this.number,
      email: email ?? this.email,
      salary: salary ?? this.salary,
      signedAt: signedAt ?? this.signedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'number': number,
        'email': email,
        'salary': salary,
        'signedAt': signedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory ContractEntry.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'];
    final expandMap = expand is Map
        ? Map<String, dynamic>.from(expand)
        : const <String, dynamic>{};
    final player = json['player'] ?? expandMap['player'];
    final playerMap = player is Map
        ? Map<String, dynamic>.from(player)
        : const <String, dynamic>{};
    return ContractEntry(
      id: readId(json['id']),
      playerId: readId(json['playerId'] ?? json['player'] ?? playerMap['id']),
      playerName:
          json['playerName'] as String? ?? playerMap['name'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      signedAt: readDate(json['signedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: readDate(json['expiresAt']),
      deletedAt: readDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'player': playerId,
        'number': number,
        'email': email,
        'salary': salary,
        'signedAt': signedAt.toIso8601String().split('T').first,
        if (expiresAt != null)
          'expiresAt': expiresAt!.toIso8601String().split('T').first,
      };

  @override
  String toString() => 'ContractEntry($id, $number, $email)';
}
