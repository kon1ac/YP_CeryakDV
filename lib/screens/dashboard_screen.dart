import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/app_role.dart';
import '../models/dashboard_stats.dart';
import '../models/hockey_player.dart';
import '../repositories/dashboard_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/format.dart';
import '../utils/players_csv.dart';
import '../utils/web_download.dart';
import '../widgets/auth_menu_button.dart';
import '../widgets/list_nav_bar.dart';
import '../widgets/list_states.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  DashboardStats _stats = DashboardStats.empty;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthNotifier>();
      final repo = context.read<DashboardRepository>();
      final sponsorOnly = auth.user?.role == AppRole.sponsor;
      final stats = await repo.load(
        sponsorId: sponsorOnly ? auth.user?.id : null,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final players =
          await context.read<DashboardRepository>().allPlayersForExport();
      final csv = playersToCsv(players);
      downloadTextFile(csv, 'players_catalog.csv');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV: ${players.length} игроков')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось экспортировать: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);
    final auth = context.watch<AuthNotifier>();
    final isSponsor = auth.user?.role == AppRole.sponsor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSponsor ? 'Сводка спонсора' : 'Дашборд'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const AuthMenuButton(),
        ],
      ),
      body: Column(
        children: [
          const ListNavBar(active: ListDestination.dashboard),
          Expanded(
            child: _loading
                ? const ListLoadingState()
                : _error != null
                    ? ListErrorState(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: EdgeInsets.all(compact ? 12 : 20),
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _StatCard(
                                  title: 'Игроки',
                                  value: '${_stats.totalPlayers}',
                                  subtitle: 'в каталоге',
                                ),
                                _StatCard(
                                  title: 'Офферы',
                                  value: '${_stats.totalOffers}',
                                  subtitle: isSponsor ? 'ваши' : 'всего',
                                ),
                                _StatCard(
                                  title: 'Средняя цена',
                                  value: Format.price(_stats.averagePrice),
                                  subtitle: 'по игрокам',
                                ),
                                _StatCard(
                                  title: 'Медиана цены',
                                  value: Format.price(_stats.medianPrice),
                                  subtitle: 'по игрокам',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: _exporting ? null : _exportCsv,
                                icon: _exporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: const Text('Скачать CSV игроков'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Игроки по статусам',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _StatusChips(
                              map: _stats.playersByStatus,
                              labels: HockeyPlayer.statusLabels,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Офферы по статусам',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _StatusChips(
                              map: _stats.offersByStatus,
                              labels: const {
                                'pending': 'Ожидает',
                                'accepted': 'Принят',
                                'rejected': 'Отклонён',
                                'withdrawn': 'Отозван',
                              },
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Распределение по амплуа',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 240,
                              child: _BarChartPanel(
                                data: _stats.playersByCategory,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Распределение по командам',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 280,
                              child: _BarChartPanel(
                                data: _stats.playersByTeam,
                                rotateLabels: true,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.map, required this.labels});

  final Map<String, int> map;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) {
      return Text(
        'Нет данных',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in map.entries)
          Chip(
            label: Text('${labels[entry.key] ?? entry.key}: ${entry.value}'),
          ),
      ],
    );
  }
}

class _BarChartPanel extends StatelessWidget {
  const _BarChartPanel({
    required this.data,
    this.rotateLabels = false,
  });

  final Map<String, int> data;
  final bool rotateLabels;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Нет данных для диаграммы'));
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxY = entries
        .map((e) => e.value)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final scheme = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 1).clamp(1, double.infinity),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = entries[group.x.toInt()].key;
              return BarTooltipItem(
                '$label\n${rod.toY.toInt()}',
                TextStyle(color: scheme.onInverseSurface),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rotateLabels ? 64 : 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                final label = entries[index].key;
                final short =
                    label.length > 10 ? '${label.substring(0, 9)}…' : label;
                final child = Text(
                  short,
                  style: Theme.of(context).textTheme.labelSmall,
                );
                if (!rotateLabels) return child;
                return Transform.rotate(angle: -0.7, child: child);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: scheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
