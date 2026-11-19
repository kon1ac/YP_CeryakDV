import '../core/id_codec.dart';

class Contract {
  const Contract({
    required this.id,
    required this.number,
    required this.email,
    required this.salary,
    required this.signedAt,
    this.expiresAt,
    this.playerId = '',
  });

  final String id;

  final int number;

  final String email;

  final double salary;

  final DateTime signedAt;

  final DateTime? expiresAt;

  final String playerId;

  bool get isOpenEnded => expiresAt == null;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  Contract copyWith({
    int? number,
    String? email,
    double? salary,
    DateTime? signedAt,
    DateTime? expiresAt,
    String? playerId,
    bool clearExpiresAt = false,
  }) {
    return Contract(
      id: id,
      number: number ?? this.number,
      email: email ?? this.email,
      salary: salary ?? this.salary,
      signedAt: signedAt ?? this.signedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      playerId: playerId ?? this.playerId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'email': email,
        'salary': salary,
        'signedAt': signedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'playerId': playerId,
      };

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        id: readId(json['id']),
        number: (json['number'] as num?)?.toInt() ?? 0,
        email: json['email'] as String? ?? '',
        salary: (json['salary'] as num?)?.toDouble() ?? 0,
        signedAt: readDate(json['signedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        expiresAt: readDate(json['expiresAt']),
        playerId: readId(json['playerId'] ?? json['player']),
      );

  Map<String, dynamic> toApiBody() => {
        if (playerId.isNotEmpty) 'player': playerId,
        'number': number,
        'email': email,
        'salary': salary,
        'signedAt': signedAt.toIso8601String().split('T').first,
        if (expiresAt != null)
          'expiresAt': expiresAt!.toIso8601String().split('T').first,
      };

  @override
  String toString() => 'Contract($id, $number, $email)';
}
