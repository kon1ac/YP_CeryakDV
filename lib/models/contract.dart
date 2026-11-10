class Contract {
  const Contract({
    required this.id,
    required this.number,
    required this.email,
    required this.salary,
    required this.signedAt,
    this.expiresAt,
  });

  final int id;

  final int number;

  final String email;

  final double salary;

  final DateTime signedAt;

  final DateTime? expiresAt;

  bool get isOpenEnded => expiresAt == null;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  Contract copyWith({
    int? number,
    String? email,
    double? salary,
    DateTime? signedAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return Contract(
      id: id,
      number: number ?? this.number,
      email: email ?? this.email,
      salary: salary ?? this.salary,
      signedAt: signedAt ?? this.signedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'email': email,
        'salary': salary,
        'signedAt': signedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        id: json['id'] as int? ?? 0,
        number: json['number'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        salary: (json['salary'] as num?)?.toDouble() ?? 0,
        signedAt: DateTime.tryParse(json['signedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is Contract &&
      other.id == id &&
      other.number == number &&
      other.email == email &&
      other.salary == salary &&
      other.signedAt == signedAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(id, number, email, salary, signedAt, expiresAt);

  @override
  String toString() => 'Contract($id, $number, $email)';
}
