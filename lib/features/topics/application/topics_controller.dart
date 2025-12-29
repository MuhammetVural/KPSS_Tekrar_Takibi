


import 'dart:math' as math;
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
    if (s >= 0.15) return 'Kritik';
    return 'Çok kritik';
  }

  static Color baseColorForStrength(double s) {
    // MemoryDecayBar segmentleri ile birebir
    return switch (s) {
      >= 0.75 => const Color(0xFF43A047), // green
      >= 0.35 => const Color(0xFFFDD835), // yellow
      >= 0.15 => const Color(0xFFFB8C00), // orange
      _ => const Color(0xFFE53935),       // red
    };
  }

  static Color stateColor(
      BuildContext context,
      DateTime now,
      int? lastReviewedAt,
      int? nextReviewAt,
      ) {
    if (nextReviewAt == null) {
      return Colors.black.withValues(alpha: 0.28);
    }
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    if (next.isBefore(now)) {
      return Theme.of(context).colorScheme.error;
    }
    final s = strength(now, lastReviewedAt, nextReviewAt);
    return baseColorForStrength(s);
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

  static Color? cardTint(
      BuildContext context,
      DateTime now,
      int? lastReviewedAt,
      int? nextReviewAt,
      ) {
    if (lastReviewedAt == null || nextReviewAt == null) return null;

    final surface = Theme.of(context).colorScheme.surface;
    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt);
    if (next.isBefore(now)) {
      final base = const Color(0xFFE53935); // kırmızı
      return Color.lerp(base, surface, 0.88); // pastel
    }

    final s = strength(now, lastReviewedAt, nextReviewAt); // 1 taze -> 0 unutma

    // Aynı segment renkleri (MemoryDecayBar ile birebir)
    final Color base = switch (s) {
      >= 0.75 => const Color(0xFF43A047), // green
      >= 0.35 => const Color(0xFFFDD835), // yellow
      >= 0.15 => const Color(0xFFFB8C00), // orange
      _ => const Color(0xFFE53935),       // red
    };

    // Soft/pastel görünüm: rengi surface ile karıştır
    return Color.lerp(base, surface, 0.88);
  }
}

class MemoryHeader extends StatelessWidget {
  final DateTime now;
  final int? lastReviewedAt;
  final int? nextReviewAt;

  const MemoryHeader({
    super.key,
    required this.now,
    required this.lastReviewedAt,
    required this.nextReviewAt,
  });

  @override
  Widget build(BuildContext context) {
    final label = MemoryUtils.stateLabel(now, lastReviewedAt, nextReviewAt);
    final color = MemoryUtils.stateColor(context, now, lastReviewedAt, nextReviewAt);

    return Row(
      children: [
        Text(
          'Hafıza',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.70),
          ),
        ),
        const Spacer(),
        _MemoryStatePill(text: label, dotColor: color),
      ],
    );
  }
}

class _MemoryStatePill extends StatelessWidget {
  final String text;
  final Color dotColor;

  const _MemoryStatePill({
    required this.text,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Colors.black.withValues(alpha: 0.70),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class MemoryLegend extends StatelessWidget {
  const MemoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c),
          ),
          const SizedBox(width: 4),
          Text(
            t,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: Colors.black.withValues(alpha: 0.55),
              height: 1.0,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        item(const Color(0xFFE53935), 'Çok kritik'),
        item(const Color(0xFFFB8C00), 'Kritik'),
        item(const Color(0xFFFDD835), 'Azalıyor'),
        item(const Color(0xFF43A047), 'Taze'),
      ],
    );
  }
}

class IntervalHeader extends StatelessWidget {
  final int intervalIndex;
  final int difficulty;
  final bool started;

  const IntervalHeader({
    super.key,
    required this.intervalIndex,
    required this.difficulty,
    required this.started,
  });

  @override
  Widget build(BuildContext context) {
    final days = ReviewIntervals.daysForDifficulty(difficulty);
    final total = days.isEmpty ? 0 : days.length;
    final idx = ReviewIntervals.clampIndex(intervalIndex, length: total);

    final label = !started
        ? 'Başlamadı'
        : (total <= 0 ? '-' : 'Seviye ${idx + 1}/$total');

    final dotColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Text(
          'Tekrar planı',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.70),
          ),

        ),
        const SizedBox(width: 8),
        Text(
          '•',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 8),
        DifficultyPill(difficulty: difficulty),
        const Spacer(),
        _IntervalInfoPill(text: label, dotColor: dotColor),
      ],
    );
  }
}

class _IntervalInfoPill extends StatelessWidget {
  final String text;
  final Color dotColor;

  const _IntervalInfoPill({
    required this.text,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Colors.black.withValues(alpha: 0.70),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class MemoryDecayBar extends StatelessWidget {
  final DateTime now;
  final int? lastReviewedAt;
  final int? nextReviewAt;

  const MemoryDecayBar({
    super.key,
    required this.now,
    required this.lastReviewedAt,
    required this.nextReviewAt,
  });

  @override
  Widget build(BuildContext context) {
    final started = lastReviewedAt != null && nextReviewAt != null;
    if (!started) {
      // başlamadıysa soluk gri bar
      return Container(
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black.withValues(alpha: 0.06),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
      );
    }

    final next = DateTime.fromMillisecondsSinceEpoch(nextReviewAt!);
    final overdue = next.isBefore(now);

    // 1.0 (taze) -> 0.0 (unutma)
    final s = overdue ? 0.0 : MemoryUtils.strength(now, lastReviewedAt, nextReviewAt);
    final x = s.clamp(0.0, 1.0); // sağdan başlayacak

    // Segmentler: soldan sağa (kırmızı -> turuncu -> sarı -> yeşil)
    // Not: Top sağdan başladığı için taze bölge sağda (yeşil) oluyor.
    const seg = [
      (0.00, 0.15, Color(0xFFE53935)), // red
      (0.15, 0.35, Color(0xFFFB8C00)), // orange
      (0.35, 0.75, Color(0xFFFDD835)), // yellow
      (0.75, 1.00, Color(0xFF43A047)), // green
    ];

    Color thumbColor(double v) {
      for (final (a, b, c) in seg) {
        if (v >= a && v <= b) return c;
      }
      return seg.last.$3;
    }

    final tColor = overdue ? Theme.of(context).colorScheme.error : thumbColor(x);

    return LayoutBuilder(
      builder: (context, c) {
        final p = MemoryUtils.percent(now, lastReviewedAt, nextReviewAt); // 0-100
        final alignX = (x * 2) - 1; // 0..1 -> -1..1 (Align için)
        final w = c.maxWidth;
        final h = 16.0;
        final r = 10.0; // thumb radius
        final knobSize = 20.0;

        // knob center x: 0..w
        final cx = (x * w).clamp(0.0, w);
        // knob left
        final left = (cx - knobSize / 2).clamp(0.0, w - knobSize);

        // sağdaki gri (geçen süre): x..1.0
        final greyWidth = ((1.0 - x) * w).clamp(0.0, w);

        return SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // renkli segment bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: h,
                  child: Row(
                    children: [
                      Expanded(flex: 15, child: Container(color: seg[0].$3)),
                      Expanded(flex: 20, child: Container(color: seg[1].$3)),
                      Expanded(flex: 40, child: Container(color: seg[2].$3)),
                      Expanded(flex: 25, child: Container(color: seg[3].$3)),
                    ],
                  ),
                ),
              ),

              // sağ tarafı gri yap (bitmiş/harcanmış kısım)
              Positioned(
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: h,
                    width: greyWidth,
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // bar border (soft)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                ),
              ),

              // knob / top
              Positioned(
                left: left,
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: tColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // yüzde etiketi (topun altında)
              Align(
                alignment: Alignment(alignX, 1),
                child: Padding(
                  padding: const EdgeInsets.only(top: 22, left: 22), // bar(16) + boşluk
                  child: Text(
                    '%$p',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final days = ReviewIntervals.daysForDifficulty(difficulty);
    final idx = ReviewIntervals.clampIndex(intervalIndex, length: days.length);

    final activeIdx = started ? idx : -1;

    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Colors.black.withValues(alpha: 0.18);
    final tickInactive = Colors.black.withValues(alpha: 0.22);


    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        if (w <= 0 || days.isEmpty) return const SizedBox.shrink();

        // xs: nokta pozisyonları (0..w)
        // Etiketler sığsın diye her segment için min genişlik + kalan alanı yumuşatılmış oranla dağıt.
        final xs = <double>[0.0];

        // segment süreleri: iki nokta arası fark
        final gaps = <int>[];
        for (int i = 0; i < days.length - 1; i++) {
          gaps.add((days[i + 1] - days[i]).abs());
        }

        final segCount = gaps.length;

        if (segCount == 0) {
          // tek nokta varsa (days length 1)
          xs.add(w);
        } else {
          // 1) min segment genişliği (etiket sığsın diye)
          // Ekran dar olursa otomatik küçülür.
          double minSegPx = 48; // 44-52 arası oynatabilirsin
          final maxMin = w / segCount;
          if (minSegPx > maxMin) minSegPx = maxMin;

          // 2) ağırlıklar: log1p ile “çok orantısız” görünmeden dağıt
          final weights = gaps
              .map((g) => math.log(g.toDouble() + 1.0))
              .toList();

          final totalW = weights.fold<double>(0.0, (a, b) => a + b);
          final free = (w - (minSegPx * segCount)).clamp(0.0, w);

          double acc = 0.0;
          for (int i = 0; i < segCount; i++) {
            final share = (totalW <= 0)
                ? (free / segCount)
                : (free * (weights[i] / totalW));
            final segWidth = minSegPx + share;
            acc += segWidth;
            xs.add(acc.clamp(0.0, w));
          }
        }

        final knobX = (activeIdx < 0) ? null : xs[activeIdx].clamp(0.0, w);

        // IntervalStrip build -> LayoutBuilder içi

        const trackH = 2.0;
        const tickH = 10.0;
        const knobSize = 16.0;
        const labelW = 34.0;

        final trackTop = 22.0;
        final dayLabelTop = (trackTop - 18.0).clamp(0.0, trackTop);

        Widget buildTrack() {
          return SizedBox(
            height: 34, // <-- 26 yerine 34 yap
            child: Stack(
              children: [
                // base track
                Positioned(
                  left: 0,
                  right: 0,
                  top: trackTop,
                  child: Container(
                    height: trackH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: inactiveColor,
                    ),
                  ),
                ),

                // active track (0 -> knob)
                if (knobX != null)
                  Positioned(
                    left: 0,
                    top: trackTop,
                    child: Container(
                      height: trackH,
                      width: knobX,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: activeColor,
                      ),
                    ),
                  ),

                // ticks
                for (int i = 0; i < xs.length; i++)
                  Positioned(
                    left: (xs[i] - 0.5).clamp(0.0, w - 1),
                    top: trackTop - ((tickH - trackH) / 2),
                    child: Container(
                      width: 1,
                      height: tickH,
                      color: (activeIdx >= 0 && i <= activeIdx) ? activeColor : tickInactive,
                    ),
                  ),

                // ✅ day labels: çizginin ÜSTÜ
                if (started)
                  ...List.generate(xs.length, (i) {
                    final isFirst = i == 0;
                    final isLast = i == xs.length - 1;

                    final left = isFirst
                        ? 0.0
                        : isLast
                        ? (w - labelW)
                        : (xs[i] - (labelW / 2)).clamp(0.0, w - labelW);

                    final align = isFirst
                        ? TextAlign.left
                        : isLast
                        ? TextAlign.right
                        : TextAlign.center;

                    return Positioned(
                      left: left,
                      top: dayLabelTop,
                      width: labelW,
                      child: Text(
                        '${days[i]}.g',
                        textAlign: align,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          height: 1.0,
                          color: (activeIdx >= 0 && i <= activeIdx)
                              ? activeColor
                              : Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    );
                  }),

                // knob
                if (knobX != null)
                  Positioned(
                    left: (knobX - knobSize / 2).clamp(0.0, w - knobSize),
                    top: trackTop - (knobSize - trackH) / 2,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: activeColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        Widget buildLabels() {
          if (!started) return const SizedBox.shrink();

          return SizedBox(
            height: 20,
            child: Stack(
              children: [
                // ❌ BURADAKİ '${days[i]}.g' loop’unu SİL (artık üstte çiziyoruz)

                // segment labels (X Gün) - altta kalsın
                for (int i = 0; i < gaps.length; i++)
                  Positioned(
                    left: (((xs[i] + xs[i + 1]) / 2) - (labelW / 2)).clamp(0.0, w - labelW),
                    top: 0,
                    width: labelW,
                    child: Text(
                      '${gaps[i]} Gün',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        height: 1.0,
                        color: (activeIdx >= 0 && i < activeIdx)
                            ? activeColor
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }



        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTrack(),
            buildLabels(),
          ],
        );
      },
    );
  }
}

class DifficultyPill extends StatelessWidget {
  final int difficulty;

  const DifficultyPill({
    super.key,
    required this.difficulty,
  });

  String _labelTr() {
    return switch (difficulty) {
      0 => 'Kolay',
      2 => 'Zor',
      _ => 'Orta',
    };
  }

  Color _baseColor() {
    return switch (difficulty) {
      0 => const Color(0xFF459F47), // green
      2 => const Color(0xFF9C2B25), // red
      _ => const Color(0xFFA18A21), // yellow
    };
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseColor();
    final surface = Theme.of(context).colorScheme.surface;
    final bg = Color.lerp(base, surface, 0.86)!; // pastel

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: base.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        _labelTr(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          height: 1.0,
          fontWeight: FontWeight.w600,
          color: base,
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
    const dotSize = 10.0;

    final labelColor =
    active ? activeColor : Colors.black.withValues(alpha: 0.45);

    // Başlamadıysa sadece soluk hat + nokta (label yok)
    if (!showLabels) {
      return SizedBox(
        width: 18,
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
      width: 50,
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
                  title: Text(
                    items[i].questionCount > 0
                        ? '${items[i].title} (${items[i].questionCount})'
                        : items[i].title,
                  ),
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

class QuestionCountPill extends StatelessWidget {
  final int count;

  const QuestionCountPill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
      ),
      child: Text(
        'KPSS: ~$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: Colors.black.withValues(alpha: 0.70),
          height: 1.0,
        ),
      ),
    );
  }
}