class DashboardStats {
  const DashboardStats({
    required this.playersByStatus,
    required this.offersByStatus,
    required this.playersByCategory,
    required this.playersByTeam,
    required this.averagePrice,
    required this.medianPrice,
    required this.totalPlayers,
    required this.totalOffers,
  });

  final Map<String, int> playersByStatus;
  final Map<String, int> offersByStatus;
  final Map<String, int> playersByCategory;
  final Map<String, int> playersByTeam;
  final double averagePrice;
  final double medianPrice;
  final int totalPlayers;
  final int totalOffers;

  static const empty = DashboardStats(
    playersByStatus: {},
    offersByStatus: {},
    playersByCategory: {},
    playersByTeam: {},
    averagePrice: 0,
    medianPrice: 0,
    totalPlayers: 0,
    totalOffers: 0,
  );
}
