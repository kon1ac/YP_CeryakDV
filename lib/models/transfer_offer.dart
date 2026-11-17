import 'list_query.dart';

class TransferOffer implements Identifiable {
  const TransferOffer({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.teamId,
    required this.teamName,
    required this.sponsorUserId,
    required this.salary,
    required this.message,
    required this.status,
    this.deletedAt,
  });

  @override
  final int id;
  final int playerId;
  final String playerName;
  final int teamId;
  final String teamName;
  final int sponsorUserId;
  final double salary;
  final String message;
  final String status;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => '$playerName → $teamName';

  factory TransferOffer.fromJson(Map<String, dynamic> json) {
    return TransferOffer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      playerId: (json['playerId'] as num?)?.toInt() ?? 0,
      playerName: json['playerName'] as String? ?? '',
      teamId: (json['teamId'] as num?)?.toInt() ?? 0,
      teamName: json['teamName'] as String? ?? '',
      sponsorUserId: (json['sponsorUserId'] as num?)?.toInt() ?? 0,
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'playerId': playerId,
        'teamId': teamId,
        'salary': salary,
        'message': message,
        'status': status,
      };
}
