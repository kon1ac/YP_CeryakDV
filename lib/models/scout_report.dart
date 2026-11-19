import '../core/id_codec.dart';
import 'list_query.dart';

class ScoutReport implements Identifiable {
  const ScoutReport({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.scoutUserId,
    required this.rating,
    required this.verdict,
    required this.summary,
    this.deletedAt,
  });

  @override
  final String id;
  final String playerId;
  final String playerName;
  final String scoutUserId;
  final int rating;
  final String verdict;
  final String summary;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => '$playerName ($rating/10)';

  factory ScoutReport.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'];
    final expandMap = expand is Map
        ? Map<String, dynamic>.from(expand)
        : const <String, dynamic>{};
    final player = json['player'] ?? expandMap['player'];
    final scout = json['scout'] ?? expandMap['scout'];
    final playerMap =
        player is Map ? Map<String, dynamic>.from(player) : const {};
    return ScoutReport(
      id: readId(json['id']),
      playerId: readId(json['playerId'] ?? json['player'] ?? playerMap['id']),
      playerName:
          json['playerName'] as String? ?? playerMap['name'] as String? ?? '',
      scoutUserId: readId(
        json['scoutUserId'] ?? json['scout'] ?? (scout is Map ? scout['id'] : scout),
      ),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      verdict: json['verdict'] as String? ?? 'watch',
      summary: json['summary'] as String? ?? '',
      deletedAt: readDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'player': playerId,
        'scout': scoutUserId,
        'rating': rating,
        'verdict': verdict,
        'summary': summary,
      };
}
