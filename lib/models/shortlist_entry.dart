import '../core/id_codec.dart';
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
  final String id;
  final String scoutUserId;
  final String playerId;
  final String playerName;
  final String note;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  @override
  String get label => playerName;

  factory ShortlistEntry.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'];
    final expandMap = expand is Map
        ? Map<String, dynamic>.from(expand)
        : const <String, dynamic>{};
    final player = json['player'] ?? expandMap['player'];
    final scout = json['scout'] ?? expandMap['scout'];
    final playerMap =
        player is Map ? Map<String, dynamic>.from(player) : const {};
    return ShortlistEntry(
      id: readId(json['id']),
      scoutUserId: readId(
        json['scoutUserId'] ?? json['scout'] ?? (scout is Map ? scout['id'] : scout),
      ),
      playerId: readId(json['playerId'] ?? json['player'] ?? playerMap['id']),
      playerName:
          json['playerName'] as String? ?? playerMap['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      deletedAt: readDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'scout': scoutUserId,
        'player': playerId,
        'note': note,
      };
}
