import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';

import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/application/selected_subject_provider.dart';
import '../../topics/application/topics_controller.dart';

class _SubjectsVm {
  final String examName;
  final List<Subject> subjects;

  const _SubjectsVm({
    required this.examName,
    required this.subjects,
  });
}

@RoutePage()
class SubjectsPage extends ConsumerWidget {
  final String examId;

  const SubjectsPage({
    super.key,
    required this.examId,
  });

  Future<_SubjectsVm> _load(AppDatabase db) async {
    final exam = await (db.select(db.exams)..where((e) => e.id.equals(examId)))
        .getSingleOrNull();

    final subjects = await (db.select(db.subjects)
          ..where((t) => t.examId.equals(examId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
        .get();

    final name = (exam?.name.trim().isNotEmpty ?? false) ? exam!.name : examId;
    return _SubjectsVm(examName: name, subjects: subjects);
  }

  _SubjectStyle _styleFor(Subject s, Brightness b) {
    final dark = b == Brightness.dark;

    switch (s.id) {
      case 'kpss_tr':
      case 'tyt_tr':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.menu_book_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF0E2F2A), Color(0xFF1FB5A2)]
                : const [Color(0xFF18C6B5), Color(0xFF6EE7D8)],
          ),
        );

      case 'kpss_mat':
      case 'tyt_mat':
      case 'ales_say':
      case 'dgs_say':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.calculate_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF001F3D), Color(0xFF3B82F6)]
                : const [Color(0xFF2F80ED), Color(0xFF86B7FF)],
          ),
        );

      case 'kpss_tarih':
      case 'tyt_sos':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.history_edu_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF23124E), Color(0xFF8B5CF6)]
                : const [Color(0xFF7C3AED), Color(0xFFC4B5FD)],
          ),
        );

      case 'kpss_cog':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.public_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF0A2A18), Color(0xFF34D399)]
                : const [Color(0xFF22C55E), Color(0xFF86EFAC)],
          ),
        );

      case 'kpss_vat':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.gavel_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF3C2100), Color(0xFFF59E0B)]
                : const [Color(0xFFFFB703), Color(0xFFFFD166)],
          ),
        );

      case 'kpss_guncel':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.newspaper_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF3B0A18), Color(0xFFF43F5E)]
                : const [Color(0xFFFB7185), Color(0xFFFDA4AF)],
          ),
        );

      case 'ales_soz':
      case 'dgs_soz':
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.psychology_alt_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF1B1B1F), Color(0xFF64748B)]
                : const [Color(0xFF334155), Color(0xFFCBD5E1)],
          ),
        );

      default:
        return _SubjectStyle(
          title: s.name,
          subtitle: 'Konulara git',
          icon: Icons.book_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF0B1020), Color(0xFF475569)]
                : const [Color(0xFF334155), Color(0xFFCBD5E1)],
          ),
        );
    }
  }

  PreferredSizeWidget _modernAppBar(BuildContext context, WidgetRef ref, String title) {
    final b = Theme.of(context).brightness;

    final overlay =
    (b == Brightness.dark) ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    final appBarBg = (b == Brightness.dark)
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.72);

    final appBarBorder = (b == Brightness.dark)
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final iconBg = (b == Brightness.dark)
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    final iconBorder = (b == Brightness.dark)
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return AppBar(
      toolbarHeight: 74,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: overlay.copyWith(statusBarColor: Colors.transparent),
      title: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dersi seç ve konulara devam et',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        _AppBarIconButton(
          icon: Icons.brightness_6,
          tooltip: 'Tema',
          bg: iconBg,
          border: iconBorder,
          onTap: () {
            final current = ref.read(themeModeProvider);
            ref.read(themeModeProvider.notifier).state = switch (current) {
              ThemeMode.system => ThemeMode.light,
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark => ThemeMode.system,
            };
          },
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          icon: Icons.language,
          tooltip: 'TR/EN',
          bg: iconBg,
          border: iconBorder,
          onTap: () {
            final current = ref.read(localeProvider);
            ref.read(localeProvider.notifier).state =
            (current?.languageCode == 'tr') ? const Locale('en') : const Locale('tr');
          },
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: appBarBg,
              border: Border(
                bottom: BorderSide(color: appBarBorder, width: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    final startedAsync = ref.watch(startedHomeTopicsByExamProvider(examId));
    final now = DateTime.now();

    return FutureBuilder<_SubjectsVm>(
      future: _load(db),
      builder: (context, snapshot) {
        final examTitle = '${snapshot.data?.examName ?? 'Dersler'} Dersleri';
        final b = Theme.of(context).brightness;

        final overlay = (b == Brightness.dark)
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

        Widget wrapScaffold({required Widget body}) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay.copyWith(statusBarColor: Colors.transparent),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: Colors.transparent,
              appBar: _modernAppBar(context, ref, examTitle),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: b == Brightness.dark
                        ? const [Color(0xFF0B1020), Color(0xFF0B1020)]
                        : const [Color(0xFFF6F7FB), Color(0xFFF6F7FB)],
                  ),
                ),
                child: body,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return wrapScaffold(body: const Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return wrapScaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('DB okuma hatası: ${snapshot.error}'),
              ),
            ),
          );
        }

        final subjects = snapshot.data?.subjects ?? const <Subject>[];

        if (subjects.isEmpty) {
          return wrapScaffold(
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 12),
              children: [
                const Text('Bu sınav için ders bulunamadı.'),
                const SizedBox(height: 16),
                _StartedTopicsCard(now: now, startedAsync: startedAsync),
              ],
            ),
          );
        }

        return wrapScaffold(
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (ctx, i) {
                  final s = subjects[i];
                  return _SubjectTile(
                    subject: s,
                    style: _styleFor(s, b),
                    onTap: () {
                      context.router.push(
                        TopicsRoute(subjectId: s.id, subjectName: s.name),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              SafeArea(
                top: false,
                child: _StartedTopicsCard(now: now, startedAsync: startedAsync),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _SubjectStyle {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _SubjectStyle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final _SubjectStyle style;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.subject,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: style.gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(style.icon, color: Colors.white, size: 24),
                        ),
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: surface.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,

                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      style.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(

                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        style.subtitle,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(

                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartedTopicsCard extends StatelessWidget {
  final DateTime now;
  final AsyncValue<List<HomeTopicItem>> startedAsync;

  const _StartedTopicsCard({
    required this.now,
    required this.startedAsync,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = cs.outlineVariant.withValues(alpha: isDark ? 0.40 : 0.55);
    final subtleText = cs.onSurfaceVariant.withValues(alpha: isDark ? 0.80 : 0.70);
    final pillBg = cs.surfaceContainerHighest;
    final pillBorder = cs.outlineVariant.withValues(alpha: isDark ? 0.60 : 0.50);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: border),
      ),
      child: startedAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(14),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text('Başlatılan konular okunamadı: $e'),
        ),
        data: (items) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Başlatılan Konular',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: pillBorder),
                        color: pillBg,
                      ),
                      child: Text(
                        '${items.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'En yakındaki tekrarlar üstte.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtleText,                  ),
                ),
                const SizedBox(height: 10),

                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Henüz başlatılan konu yok.'),
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return _TopicPreviewCard(now: now, item: item);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopicPreviewCard extends StatelessWidget {
  final DateTime now;
  final HomeTopicItem item;

  const _TopicPreviewCard({
    required this.now,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.topic;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = cs.outlineVariant.withValues(alpha: isDark ? 0.40 : 0.55);
    final subtleText = cs.onSurfaceVariant.withValues(alpha: isDark ? 0.80 : 0.70);
    final pillBg = cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.45 : 0.70);
    final pillBorder = cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.60);

    final label = MemoryUtils.stateLabel(now, t.lastReviewedAt, t.nextReviewAt);
    final dot = MemoryUtils.stateColor(context, now, t.lastReviewedAt, t.nextReviewAt);
    final tint = MemoryUtils.cardTint(context, now, t.lastReviewedAt, t.nextReviewAt);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final t = item.topic;

        context.router.push(
          TopicsRoute(
            subjectId: t.subjectId,
            subjectName: item.subjectName,

            // Alt konu ise doğrudan alt konular sayfasına götürür
            parentTopicId: t.parentTopicId,

            // Scroll + highlight hedefi
            focusTopicId: t.id,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          color: tint ?? cs.surfaceContainerHighest,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.subjectName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtleText,                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: pillBorder),
                          color: pillBg,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.85),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CountdownWithRemaining(
              now: now,
              intervalIndex: t.intervalIndex,
              lastReviewedAt: t.lastReviewedAt,
              nextReviewAt: t.nextReviewAt,
            ),
          ],
        ),
      ),
    );
  }
}