import '../models/hockey_player.dart';

String _escape(Object? value) {
  final text = '${value ?? ''}';
  if (text.contains(',') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

String playersToCsv(List<HockeyPlayer> players) {
  final buffer = StringBuffer();
  buffer.writeln(
    [
      'id',
      'name',
      'category',
      'status',
      'team',
      'price',
      'jerseyNumber',
      'notes',
    ].join(','),
  );
  for (final player in players) {
    buffer.writeln(
      [
        _escape(player.id),
        _escape(player.name),
        _escape(player.category),
        _escape(player.status),
        _escape(player.teamName),
        _escape(player.price),
        _escape(player.jerseyNumber ?? ''),
        _escape(player.notes),
      ].join(','),
    );
  }
  return buffer.toString();
}
