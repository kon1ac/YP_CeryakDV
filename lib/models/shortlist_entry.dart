import 'list_query.dart';

class ShortlistEntry implements Identifiable {
  const ShortlistEntry({
    required this.id,
    required this.scoutUserId,
    required this.playerId,
    required this.playerName,
    required this.note,
    this.deletedAt,
  });

  @override
  final int id;
  final int scoutUserId;
  final int playerId;
  final String playerName;
  final String note;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => playerName;

  factory ShortlistEntry.fromJson(Map<String, dynamic> json) {
    return ShortlistEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      scoutUserId: (json['scoutUserId'] as num?)?.toInt() ?? 0,
      playerId: (json['playerId'] as num?)?.toInt() ?? 0,
      playerName: json['playerName'] as String? ?? '',
      note: json['note'] as String? ?? '',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'playerId': playerId,
        'note': note,
      };
}
