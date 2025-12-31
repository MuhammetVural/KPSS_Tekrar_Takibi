import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tekrar_takibi/app/router/app_router.dart';
import 'package:kpss_tekrar_takibi/core/theme/app_theme.dart';
import 'package:kpss_tekrar_takibi/l10n/app_localizations.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/db/app_database.dart';
import 'core/db/seed.dart';
import 'features/home/application/selected_subject_provider.dart';


final notificationsInitProvider = FutureProvider<void>((ref) async {
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
});

/// Started konular değiştikçe (başlatma / tekrar yapma / arşivleme),
/// kritik eşik bildirimlerini otomatik senkronlar.
final memoryThresholdNotificationsSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<HomeTopicItem>>>(
    startedHomeTopicsProvider,
        (prev, next) async {
      final prevItems = prev?.asData?.value;
      final nextItems = next.asData?.value;
      if (nextItems == null) return;

      try {
        await NotificationService.instance.syncMemoryThresholdNotifications(
          items: nextItems,
          previousItems: prevItems,
        );
      } catch (e, st) {
        debugPrint('syncMemoryThresholdNotifications ERROR: $e');
        debugPrint('$st');
      }
    },
  );
});

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background isolate: burada ağır iş yapma.
  // İstersen payload'ı storage'a yazıp app açılınca okuyabilirsin.
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'review_reminders';
  static const String _channelName = 'Review Reminders';
  static const String _channelDesc = 'Scheduled reminders for topic reviews';

  Future<void> init() async {
    if (_initialized) return;

    // Timezone init (schedule için şart)
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // fallback: tz.local
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Foreground'da da göster
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        // App process ayaktayken tıklama (foreground/background).
        // resp.payload -> deep link amaçlı kullanılabilir.
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android channel oluştur
    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    // iOS izin
    final ios =
    _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ izin
    final android =
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  // ---- Memory-threshold notification logic ----

  /// Dart'ın String.hashCode'u process'e göre değişebildiği için stabil bir hash kullanıyoruz.
  int _fnv1a32(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;
    for (final c in input.codeUnits) {
      hash ^= c;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    // FlutterLocalNotificationsPlugin id için pozitif int bekliyoruz.
    return hash & 0x7FFFFFFF;
  }

  int _notifId(String topicId, int kind) => _fnv1a32('$kind:$topicId');

  String _formatRemaining(Duration d) {
    if (d.isNegative) return '0';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;

    if (days > 0) return '${days}g ${hours}s';
    if (d.inHours > 0) return '${d.inHours}s ${minutes}dk';
    if (d.inMinutes > 0) return '${d.inMinutes}dk';
    return '<1dk';
  }

  /// Her started topic için 2 bildirim planlar:
  /// - "Kritik" (strength ~ 0.35)
  /// - "Çok kritik" (strength ~ 0.15)
  ///
  /// lastReviewedAt ve nextReviewAt üzerinden hesaplanır.
  Future<void> syncMemoryThresholdNotifications({
    required List<HomeTopicItem> items,
    List<HomeTopicItem>? previousItems,
  }) async {
    await init();

    final now = DateTime.now();

    const note =
        'Kalıcı hafıza serisini devam ettirmek için konuyu tekrar edin.\n'
        '20–30 soru arası çözmeniz faydanıza.';

    // Listeden düşen konuların eski bildirimlerini temizle
    final prevIds = (previousItems ?? const <HomeTopicItem>[])
        .map((e) => e.topic.id)
        .toSet();
    final nextIds = items.map((e) => e.topic.id).toSet();
    final removed = prevIds.difference(nextIds);
    for (final tid in removed) {
      await cancel(_notifId(tid, 1)); // kritik
      await cancel(_notifId(tid, 2)); // çok kritik
    }

    for (final item in items) {
      final t = item.topic;

      // Başlamadıysa / arşivliyse -> bildirimleri kapat
      if (t.archived == true || t.lastReviewedAt == null || t.nextReviewAt == null) {
        await cancel(_notifId(t.id, 1));
        await cancel(_notifId(t.id, 2));
        continue;
      }

      final last = DateTime.fromMillisecondsSinceEpoch(t.lastReviewedAt!);
      final next = DateTime.fromMillisecondsSinceEpoch(t.nextReviewAt!);
      final total = next.difference(last);

      if (total <= Duration.zero) {
        await cancel(_notifId(t.id, 1));
        await cancel(_notifId(t.id, 2));
        continue;
      }

      final totalMs = total.inMilliseconds;

      // strength = 1 - elapsed/total
      // Kritik: strength ~= 0.35  -> elapsedRatio = 0.65
      // Çok kritik: strength ~= 0.15 -> elapsedRatio = 0.85
      final criticalAt = last.add(
        Duration(milliseconds: (totalMs * 0.65).round()),
      );
      final veryCriticalAt = last.add(
        Duration(milliseconds: (totalMs * 0.85).round()),
      );

      // Kritik bildirimi
      if (criticalAt.isAfter(now) && criticalAt.isBefore(next)) {
        final remaining = next.difference(criticalAt);
        await scheduleAt(
          id: _notifId(t.id, 1),
          title: 'Kritik eşik: ${t.title}',
          body: 'Kalan süre: ${_formatRemaining(remaining)}\n$note',
          at: criticalAt,
          payload: 'topic:${t.id}',
        );
      } else {
        await cancel(_notifId(t.id, 1));
      }

      // Çok kritik bildirimi
      if (veryCriticalAt.isAfter(now) && veryCriticalAt.isBefore(next)) {
        final remaining = next.difference(veryCriticalAt);
        await scheduleAt(
          id: _notifId(t.id, 2),
          title: 'Çok kritik: ${t.title}',
          body: 'Kalan süre: ${_formatRemaining(remaining)}\n$note',
          at: veryCriticalAt,
          payload: 'topic:${t.id}',
        );
      } else {
        await cancel(_notifId(t.id, 2));
      }
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await _plugin.show(id, title, body, _details(), payload: payload);
  }

  /// Scheduled local notification:
  /// - app açık / arkaplan / kapalı: hepsinde çalışır.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    await init();

    final when = tz.TZDateTime.from(at, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      payload: payload,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  await seedIfNeeded(db);

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    ref.watch(notificationsInitProvider);
    ref.watch(memoryThresholdNotificationsSyncProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KPSS Tekrar Takibi',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      routerConfig: router.config(),
    );
  }
}