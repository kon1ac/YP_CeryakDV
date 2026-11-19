import '../core/id_codec.dart';
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
  final String id;
  final String playerId;
  final String playerName;
  final String teamId;
  final String teamName;
  final String sponsorUserId;
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
    final expand = json['expand'];
    final expandMap = expand is Map
        ? Map<String, dynamic>.from(expand)
        : const <String, dynamic>{};
    final player = json['player'] ?? expandMap['player'];
    final team = json['team'] ?? expandMap['team'];
    final sponsor = json['sponsor'] ?? expandMap['sponsor'];
    final playerMap =
        player is Map ? Map<String, dynamic>.from(player) : const {};
    final teamMap = team is Map ? Map<String, dynamic>.from(team) : const {};
    return TransferOffer(
      id: readId(json['id']),
      playerId: readId(json['playerId'] ?? json['player'] ?? playerMap['id']),
      playerName:
          json['playerName'] as String? ?? playerMap['name'] as String? ?? '',
      teamId: readId(json['teamId'] ?? json['team'] ?? teamMap['id']),
      teamName: json['teamName'] as String? ?? teamMap['name'] as String? ?? '',
      sponsorUserId: readId(
        json['sponsorUserId'] ?? json['sponsor'] ?? (sponsor is Map ? sponsor['id'] : sponsor),
      ),
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      deletedAt: readDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'player': playerId,
        'team': teamId,
        'sponsor': sponsorUserId,
        'salary': salary,
        'message': message,
        'status': status,
      };
}
