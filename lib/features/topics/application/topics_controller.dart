

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';
import 'package:kpss_tekrar_takibi/features/topics/domain/review_intervals.dart';

/// UI widgets extracted from TopicsPage to keep the page file small.

class ChipInfo extends StatelessWidget {
  final String label;
  final String value;

  const ChipInfo({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withAlpha(31)),
        color: Colors.black.withAlpha(10),
      ),
      child: Text('$label: $value'),
    );
  }
}

class CountdownBadge extends StatelessWidget {
  final DateTime now;
  final int intervalIndex;
  final int? lastReviewedAt;
  final int? nextReviewAt;

  const CountdownBadge({
    super.key,
    required this.now,
    required this.intervalIndex,
    required this.lastReviewedAt,
    required this.nextReviewAt,
  });

  int _repeatNo() {
    if (nextReviewAt == null) return 0;
    final idx = ReviewIntervals.clampIndex(intervalIndex);
    return idx + 1;
  }

  int _remainingDays() {
    if (nextReviewAt == null) return -1;
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt!);
    final today = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(next.year, next.month, next.day);
    return nextDay.difference(today).inDays;
  }

  double _progress() {
    if (nextReviewAt == null || lastReviewedAt == null) return 0;

    final total = nextReviewAt! - lastReviewedAt!;
    if (total <= 0) return 0;

    final elapsed = now.millisecondsSinceEpoch - lastReviewedAt!;
    final ratio = (elapsed / total).clamp(0.0, 1.0);

    // Reverse countdown: starts full (1.0) and decreases to 0.0
    return (1.0 - ratio).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (nextReviewAt == null) {
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
        ),
        child: Text('-', style: Theme.of(context).textTheme.labelLarge),
      );
    }

    final remain = _remainingDays();
    final overdue = remain < 0;
    final rep = _repeatNo();

    final ringColor = overdue
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: overdue ? 1 : _progress(),
            strokeWidth: 3,
            backgroundColor: Colors.black.withValues(alpha: 0.08),
            color: ringColor,
          ),
          Text(rep.toString(), style: Theme.of(context).textTheme.labelSmall),
          if (overdue)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
                ),
                child: Text(
                  '!',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CountdownWithRemaining extends StatelessWidget {
  final DateTime now;
  final int intervalIndex;
  final int? lastReviewedAt;
  final int? nextReviewAt;

  const CountdownWithRemaining({
    super.key,
    required this.now,
    required this.intervalIndex,
    required this.lastReviewedAt,
    required this.nextReviewAt,
  });

  String _remainingText() {
    if (nextReviewAt == null) return '';

    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt!);
    final diff = next.difference(now);

    if (diff.isNegative) return 'Unuttun';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return '${days}g ${hours}s';
    if (diff.inHours > 0) return '${diff.inHours}s ${minutes}dk';

    final m = diff.inMinutes;
    if (m > 0) return '${m}dk';
    return '<1dk';
  }

  @override
  Widget build(BuildContext context) {
    final text = _remainingText();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CountdownBadge(
          now: now,
          intervalIndex: intervalIndex,
          lastReviewedAt: lastReviewedAt,
          nextReviewAt: nextReviewAt,
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class MemoryUtils {
  /// 1.0 = full (taze), 0.0 = empty (unutma noktası)
  static double strength(DateTime now, int? lastReviewedAt, int? nextReviewAt) {
    if (lastReviewedAt == null || nextReviewAt == null) return 0;

    final total = nextReviewAt - lastReviewedAt;
    if (total <= 0) return 0;

    final elapsed = now.millisecondsSinceEpoch - lastReviewedAt;
    final ratio = (elapsed / total).clamp(0.0, 1.0);

    return (1.0 - ratio).clamp(0.0, 1.0);
  }

  static int percent(DateTime now, int? lastReviewedAt, int? nextReviewAt) {
    return (strength(now, lastReviewedAt, nextReviewAt) * 100).round();
  }

  static String stateLabel(DateTime now, int? lastReviewedAt, int? nextReviewAt) {
    if (nextReviewAt == null) return 'Başlamadın';

    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    if (next.isBefore(now)) return 'Unuttun';

    final s = strength(now, lastReviewedAt, nextReviewAt);
    if (s >= 0.75) return 'Taze';
    if (s >= 0.35) return 'Azalıyor';
    return 'Kritik';
  }

  static String remainingShort(DateTime now, int? nextReviewAt) {
    if (nextReviewAt == null) return '-';
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    final diff = next.difference(now);

    if (diff.isNegative) return '0';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return '${days}g ${hours}s';
    if (diff.inHours > 0) return '${diff.inHours}s ${minutes}dk';

    final m = diff.inMinutes;
    if (m > 0) return '${m}dk';
    return '<1dk';
  }

  static String remainingLong(DateTime now, int? nextReviewAt) {
    if (nextReviewAt == null) return '-';
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    final diff = next.difference(now);

    if (diff.isNegative) return 'Unuttun';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return '${days} gün ${hours} saat';
    if (diff.inHours > 0) return '${diff.inHours} saat ${minutes} dk';

    final m = diff.inMinutes;
    if (m > 0) return '${m} dk';
    return '<1 dk';
  }

  static Color? cardTint(BuildContext context, DateTime now, int? lastReviewedAt, int? nextReviewAt) {
    if (lastReviewedAt == null || nextReviewAt == null) return null;

    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    if (next.isBefore(now)) {
      // Unuttun -> kırmızıya sabitle
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.14);
    }

    // s: 1.0 full (taze) -> 0.0 empty (unutma)
    final s = strength(now, lastReviewedAt, nextReviewAt);
    final risk = (1.0 - s).clamp(0.0, 1.0); // 0 taze, 1 kritik

    final green = Colors.green;
    final yellow = Colors.amber;
    final orange = Colors.orange;
    final red = Theme.of(context).colorScheme.error;

    Color base;
    if (risk <= 0.33) {
      // Yeşil -> Sarı
      base = Color.lerp(green, yellow, risk / 0.33)!;
    } else if (risk <= 0.66) {
      // Sarı -> Turuncu
      base = Color.lerp(yellow, orange, (risk - 0.33) / 0.33)!;
    } else {
      // Turuncu -> Kırmızı
      base = Color.lerp(orange, red, (risk - 0.66) / 0.34)!;
    }

    // Kartın tamamı boyanmasın diye hafif tint
    return base.withValues(alpha: 0.12);
  }
}

class IntervalStrip extends StatelessWidget {
  final int intervalIndex;
  final int difficulty;
  final bool started;

  const IntervalStrip({
    super.key,
    required this.intervalIndex,
    required this.difficulty,
    this.started = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = ReviewIntervals.daysForDifficulty(difficulty);
    final idx = ReviewIntervals.clampIndex(intervalIndex, length: items.length);
    final activeIdx = started ? idx : -1; // başlamadıysa tüm hat soluk

    final active = Theme.of(context).colorScheme.primary;
    final inactiveLine = Colors.black.withValues(alpha: 0.12);
    final inactiveBorder = Colors.black.withValues(alpha: 0.22);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              IntervalNode(
                level: i + 1,
                day: items[i],
                showLabels: started,
                active: i <= activeIdx,
                activeColor: active,
                inactiveBorderColor: inactiveBorder,
              ),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 5.5),
                  child: Container(
                    width: 22,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: (i < activeIdx) ? active : inactiveLine,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class IntervalNode extends StatelessWidget {
  final int level;
  final int day;
  final bool showLabels;
  final bool active;
  final Color activeColor;
  final Color inactiveBorderColor;

  const IntervalNode({
    super.key,
    required this.level,
    required this.day,
    required this.showLabels,
    required this.active,
    required this.activeColor,
    required this.inactiveBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    const dotSize = 14.0;

    final labelColor =
    active ? activeColor : Colors.black.withValues(alpha: 0.45);

    // Başlamadıysa sadece soluk hat + nokta (label yok)
    if (!showLabels) {
      return SizedBox(
        width: 22,
        height: dotSize,
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor : Colors.transparent,
              border: Border.all(
                color: active ? activeColor : inactiveBorderColor,
                width: 2,
              ),
            ),
          ),
        ),
      );
    }

    // Başladıysa: seviye + (gün)
    return SizedBox(
      width: 34,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor : Colors.transparent,
              border: Border.all(
                color: active ? activeColor : inactiveBorderColor,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontSize: 11,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '(${day}g)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontSize: 10,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class SubtopicsPanel extends StatelessWidget {
  final AsyncValue<List<Topic>> asyncValue;
  final DateTime now;
  final void Function(Topic topic) onTapTopic;
  final void Function(Topic topic) onOpenSheet;

  const SubtopicsPanel({
    super.key,
    required this.asyncValue,
    required this.now,
    required this.onTapTopic,
    required this.onOpenSheet,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Alt konular okunamadı: $e'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Alt konu yok.'),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
                  title: Text(items[i].title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountdownBadge(
                        now: now,
                        intervalIndex: items[i].intervalIndex,
                        lastReviewedAt: items[i].lastReviewedAt,
                        nextReviewAt: items[i].nextReviewAt,
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                  onTap: () => onOpenSheet(items[i]),
                ),
                if (i != items.length - 1)
                  Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
              ],
            ],
          ),
        );
      },
    );
  }
}