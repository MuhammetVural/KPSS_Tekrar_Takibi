import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/app/router/app_router.dart';
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';
import 'package:kpss_tekrar_takibi/core/theme/app_theme.dart';

import '../../../main.dart';

@RoutePage()
class ExamListPage extends ConsumerWidget {
  const ExamListPage({super.key});

  _ExamStyle _styleFor(Exam e, Brightness b) {
    // Lively gradients per exam id (fallback is blue).
    final bool dark = b == Brightness.dark;

    switch (e.id) {
      case 'kpss':
        return _ExamStyle(
          title: 'KPSS',
          subtitle: 'Derslere geç',
          icon: Icons.school_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF0E2F2A), Color(0xFF1FB5A2)]
                : const [Color(0xFF18C6B5), Color(0xFF6EE7D8)],
          ),
          accent: dark ? const Color(0xFF6EE7D8) : const Color(0xFF0A6B60),
        );
      case 'ales':
        return _ExamStyle(
          title: 'ALES',
          subtitle: 'Derslere geç',
          icon: Icons.psychology_alt_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF23124E), Color(0xFF8B5CF6)]
                : const [Color(0xFF7C3AED), Color(0xFFC4B5FD)],
          ),
          accent: dark ? const Color(0xFFC4B5FD) : const Color(0xFF4C1D95),
        );
      case 'dgs':
        return _ExamStyle(
          title: 'DGS',
          subtitle: 'Derslere geç',
          icon: Icons.route_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF3C2100), Color(0xFFF59E0B)]
                : const [Color(0xFFFFB703), Color(0xFFFFD166)],
          ),
          accent: dark ? const Color(0xFFFFD166) : const Color(0xFF7C4A00),
        );
      case 'tyt':
        return _ExamStyle(
          title: 'TYT',
          subtitle: 'Derslere geç',
          icon: Icons.calculate_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF001F3D), Color(0xFF3B82F6)]
                : const [Color(0xFF2F80ED), Color(0xFF86B7FF)],
          ),
          accent: dark ? const Color(0xFF86B7FF) : const Color(0xFF0B3A78),
        );
      default:
        return _ExamStyle(
          title: (e.name.trim().isEmpty ? e.id : e.name).toUpperCase(),
          subtitle: 'Derslere geç',
          icon: Icons.book_rounded,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF0B1020), Color(0xFF475569)]
                : const [Color(0xFF334155), Color(0xFFCBD5E1)],
          ),
          accent: dark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 74,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: overlay.copyWith(statusBarColor: Colors.transparent),
          title: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sınav Seç',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Devam etmek istediğin sınavı seç',
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
              onTap: () async {
                try {
                  await NotificationService.instance.init();
                  await NotificationService.instance.requestPermissions();

                  final at = DateTime.now().add(const Duration(seconds: 10));

                  await NotificationService.instance.scheduleAt(
                    id: 999, // her testte farklı ver istersen
                    title: 'Test',
                    body: '10 saniye sonra geldi',
                    at: at,
                  );

                  debugPrint('scheduled OK at=$at');
                } catch (e, st) {
                  debugPrint('schedule ERROR: $e');
                  debugPrint('$st');
                }

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
        ),
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
          child: FutureBuilder<List<Exam>>(
            future: db.select(db.exams).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('DB okuma hatası: ${snapshot.error}'),
                  ),
                );
              }

              final exams = snapshot.data ?? const <Exam>[];
              if (exams.isEmpty) {
                return const Center(child: Text('Sınav bulunamadı (DB boş).'));
              }

              // “Ekranı bölen” görünüm: 4 satır varsa her biri ekranın bir bölümünü kaplar.
              // Daha çok sınav olursa otomatik listeye düşer.
              final useSplitLayout = exams.length <= 5;

              if (useSplitLayout) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < exams.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: i == exams.length - 1 ? 0 : 12,
                              ),
                              child: _ExamPanel(
                                exam: exams[i],
                                style: _styleFor(exams[i], b),
                                onTap: () => context.router
                                    .push(SubjectsRoute(examId: exams[i].id)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              // Fallback: çok sınav olursa scroll.
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: exams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final e = exams[i];
                  return SizedBox(
                    height: 96,
                    child: _ExamPanel(
                      exam: e,
                      style: _styleFor(e, b),
                      onTap: () => context.router
                          .push(SubjectsRoute(examId: e.id)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
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

class _ExamStyle {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accent;

  const _ExamStyle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accent,
  });
}

class _ExamPanel extends StatelessWidget {
  final Exam exam;
  final _ExamStyle style;
  final VoidCallback onTap;

  const _ExamPanel({
    required this.exam,
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
              // soft highlight blobs
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                left: -70,
                bottom: -70,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(style.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  style.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surface.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 24,
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