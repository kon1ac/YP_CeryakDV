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
  final int id;
  final int playerId;
  final String playerName;
  final int scoutUserId;
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
    return ScoutReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      playerId: (json['playerId'] as num?)?.toInt() ?? 0,
      playerName: json['playerName'] as String? ?? '',
      scoutUserId: (json['scoutUserId'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      verdict: json['verdict'] as String? ?? 'watch',
      summary: json['summary'] as String? ?? '',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'playerId': playerId,
        'rating': rating,
        'verdict': verdict,
        'summary': summary,
      };
}
