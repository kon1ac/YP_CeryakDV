import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb_client.dart';
import '../models/dashboard_stats.dart';
import '../models/hockey_player.dart';
import '../models/transfer_offer.dart';

class DashboardRepository {
  DashboardRepository(Dio dio) : _pb = PbClient(dio);

  final PbClient _pb;

  Future<DashboardStats> load({String? sponsorId}) => guard(() async {
        final playersData = await _pb.list(
          'players',
          perPage: 200,
          filter: pbActiveFilter(),
          expand: 'team',
          sort: 'name',
        );
        final offersFilter = joinFilters([
          pbActiveFilter(),
          if (sponsorId != null && sponsorId.isNotEmpty)
            'sponsor = ${pbQuote(sponsorId)}',
        ]);
        final offersData = await _pb.list(
          'transfer_offers',
          perPage: 200,
          filter: offersFilter,
          expand: 'player,team',
        );

        final players = <HockeyPlayer>[
          if (playersData['items'] is List)
            for (final item in playersData['items'] as List)
              if (item is Map)
                HockeyPlayer.fromJson(Map<String, dynamic>.from(item)),
        ];
        final offers = <TransferOffer>[
          if (offersData['items'] is List)
            for (final item in offersData['items'] as List)
              if (item is Map)
                TransferOffer.fromJson(Map<String, dynamic>.from(item)),
        ];

        final playersByStatus = <String, int>{};
        final playersByCategory = <String, int>{};
        final playersByTeam = <String, int>{};
        final prices = <double>[];
        for (final player in players) {
          playersByStatus.update(player.status, (v) => v + 1, ifAbsent: () => 1);
          playersByCategory.update(
            player.category.isEmpty ? '—' : player.category,
            (v) => v + 1,
            ifAbsent: () => 1,
          );
          final team = player.teamName.isEmpty ? 'Без команды' : player.teamName;
          playersByTeam.update(team, (v) => v + 1, ifAbsent: () => 1);
          prices.add(player.price);
        }

        final offersByStatus = <String, int>{};
        for (final offer in offers) {
          offersByStatus.update(offer.status, (v) => v + 1, ifAbsent: () => 1);
        }

        prices.sort();
        final average = prices.isEmpty
            ? 0.0
            : prices.reduce((a, b) => a + b) / prices.length;
        final median = prices.isEmpty
            ? 0.0
            : prices.length.isOdd
                ? prices[prices.length ~/ 2]
                : (prices[prices.length ~/ 2 - 1] + prices[prices.length ~/ 2]) /
                    2;

        return DashboardStats(
          playersByStatus: playersByStatus,
          offersByStatus: offersByStatus,
          playersByCategory: playersByCategory,
          playersByTeam: playersByTeam,
          averagePrice: average,
          medianPrice: median,
          totalPlayers: players.length,
          totalOffers: offers.length,
        );
      });

  Future<List<HockeyPlayer>> allPlayersForExport() => guard(() async {
        final data = await _pb.list(
          'players',
          perPage: 500,
          filter: pbActiveFilter(),
          expand: 'team',
          sort: 'name',
        );
        return [
          if (data['items'] is List)
            for (final item in data['items'] as List)
              if (item is Map)
                HockeyPlayer.fromJson(Map<String, dynamic>.from(item)),
        ];
      });
}
