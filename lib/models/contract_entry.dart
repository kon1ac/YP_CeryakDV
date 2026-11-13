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
  final int id;

  final int playerId;

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

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  ContractEntry copyWith({
    int? playerId,
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
    final player = json['player'];
    final playerMap = player is Map
        ? Map<String, dynamic>.from(player)
        : const <String, dynamic>{};
    return ContractEntry(
      id: json['id'] as int? ?? 0,
      playerId: json['playerId'] as int? ?? playerMap['id'] as int? ?? 0,
      playerName:
          json['playerName'] as String? ?? playerMap['name'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      signedAt: DateTime.tryParse(json['signedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'number': number,
        'email': email,
        'salary': salary,
        'signedAt': signedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  @override
  String toString() => 'ContractEntry($id, $number, $email)';
}
