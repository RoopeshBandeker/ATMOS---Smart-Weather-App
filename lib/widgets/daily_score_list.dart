import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_score.dart';
import '../utils/weather_score.dart';
import '../utils/weather_icons.dart' as weather_icons;

class DailyScoreList extends StatefulWidget {
  final List<DailyScore> items;

  const DailyScoreList({
    required this.items,
    super.key,
  });

  @override
  State<DailyScoreList> createState() => _DailyScoreListState();
}

class _DailyScoreListState extends State<DailyScoreList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Daily scores not available'),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == widget.items.length - 1 ? 0 : 10),
          child: ExpandableDailyScoreCard(
            score: item,
            isExpanded: _expandedIndex == index,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedIndex = expanded ? index : null;
              });
            },
          ),
        );
      },
    );
  }
}

class ExpandableDailyScoreCard extends StatelessWidget {
  final DailyScore score;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const ExpandableDailyScoreCard({
    required this.score,
    required this.isExpanded,
    required this.onExpansionChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final weatherScore = WeatherScore(score.score);

    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: weatherScore.color.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onExpansionChanged(!isExpanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: weatherScore.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: weather_icons.weatherIconWidget(
                        score.condition,
                        score.icon,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE').format(score.date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          WeatherScore(score.score).label,
                          style: TextStyle(
                            color: weatherScore.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${score.minTemperature.toStringAsFixed(1)} / ${score.maxTemperature.toStringAsFixed(1)} C',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.score}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: weatherScore.color,
                            ),
                      ),
                      Text(
                        '/100',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Min / Max temperature',
                        value:
                            '${score.minTemperature.toStringAsFixed(1)} / ${score.maxTemperature.toStringAsFixed(1)} C',
                      ),
                      _DetailRow(
                        label: 'Average humidity',
                        value: '${score.averageHumidity}%',
                      ),
                      _DetailRow(
                        label: 'Wind speed',
                        value: '${score.averageWindSpeed.toStringAsFixed(1)} m/s',
                      ),
                      _DetailRow(
                        label: 'AQI',
                        value: '${score.aqi}',
                      ),
                      _DetailRow(
                        label: 'Condition',
                        value: score.condition,
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
