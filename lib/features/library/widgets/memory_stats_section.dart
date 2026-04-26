import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/stats_service.dart';

class MemoryStatsSection extends StatelessWidget {
  const MemoryStatsSection({super.key, required this.stats});

  final MemoryStats stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasData) {
      return _EmptyState(
        icon: Icons.insights_outlined,
        title: '還沒有記憶資料',
        subtitle: '開始複習這個字庫，即可看到穩定性分布、可提取性與正確率趨勢。',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(stats: stats),
        const SizedBox(height: 20),
        _SectionTitle(title: '穩定性分布', subtitle: '每張卡距離遺忘的天數'),
        const SizedBox(height: 10),
        _StabilityChart(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle(title: '近 30 天正確率', subtitle: '每天複習的累計正確率'),
        const SizedBox(height: 10),
        _CorrectnessChart(stats: stats),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});
  final MemoryStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avgText = stats.avgRetrievability.isNaN
        ? '—'
        : '${(stats.avgRetrievability * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: '已複習',
              value: '${stats.reviewedCount} / ${stats.totalWords}',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: cs.onSurface.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _SummaryItem(
              label: '平均可提取性',
              value: avgText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _StabilityChart extends StatelessWidget {
  const _StabilityChart({required this.stats});
  final MemoryStats stats;

  static const _labels = ['1-3', '4-7', '8-14', '15-30', '30+'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!stats.hasStabilityData) {
      return _EmptyState(
        icon: Icons.trending_up_outlined,
        title: '尚無穩定性資料',
        subtitle: 'SM-2 模式不會計算穩定性，切換至 FSRS 後即可累積。',
        compact: true,
      );
    }

    final values = _labels
        .map((k) => stats.stabilityBuckets[k] ?? 0)
        .toList();
    final maxY = values.fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final chartMaxY = maxY == 0 ? 1.0 : maxY * 1.25;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMaxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.primary,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              getTooltipItem: (group, groupIdx, rod, rodIdx) =>
                  BarTooltipItem(
                '${rod.toY.toInt()} 張',
                TextStyle(
                  color: cs.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 16,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _labels.length) {
                    return const SizedBox.shrink();
                  }
                  final v = values[i];
                  if (v <= 0) return const SizedBox.shrink();
                  return Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < _labels.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    color: cs.primary,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CorrectnessChart extends StatelessWidget {
  const _CorrectnessChart({required this.stats});
  final MemoryStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daily = stats.dailyCorrectness;

    if (daily.length < 2) {
      return _EmptyState(
        icon: Icons.show_chart_outlined,
        title: '資料不足',
        subtitle: '至少需要兩天以上的複習紀錄才能畫出趨勢。',
        compact: true,
      );
    }

    final firstDay = daily.first.date;
    final spots = [
      for (final d in daily)
        FlSpot(
          d.date.difference(firstDay).inDays.toDouble(),
          d.correctRate * 100,
        ),
    ];
    final lastX = spots.last.x;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lastX == 0 ? 1 : lastX,
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: cs.onSurface.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: lastX <= 6 ? 1 : (lastX / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final date = firstDay.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final date = firstDay.add(Duration(days: spot.x.toInt()));
                return LineTooltipItem(
                  '${date.month}/${date.day}  ${spot.y.round()}%',
                  TextStyle(
                    color: cs.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: cs.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: cs.primary,
                  strokeColor: cs.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 22 : 40,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: compact ? 28 : 36,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
