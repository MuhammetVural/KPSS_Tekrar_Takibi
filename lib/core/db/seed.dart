import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import 'package:kpss_tekrar_takibi/core/db/app_database.dart';


// KPSS konu başına yaklaşık soru sayısı (tek sayı – yön bulmak için)
// Not: Buradaki başlıklar DB’ye insert ettiğin Topic.title ile birebir aynı olmalı.
// KPSS konu başına yaklaşık soru sayısı (tek sayı – yön bulmak için)
// Not: Anahtarlar DB'deki `Subjects.id` ve `Topics.title` ile eşleşmeli.
// Bazı başlıklar için alternatif yazımları da ekledik.
const _kpssCountsBySubjectId = <String, Map<String, int>>{
  // =========================
  // KPSS - Türkçe (kpss_tr)
  // =========================
  'kpss_tr': {
    'Sözcükte Anlam': 1,
    'Cümlede Anlam': 3,
    'Paragraf': 14,
    'Anlatım Bozukluğu': 1,
    'Ses Bilgisi': 1,
    'Yazım Kuralları': 1,
    'Noktalama İşaretleri': 1,
    'Sözcük Türleri': 2,
    'Cümle Bilgisi': 1,
    'Fiil Bilgisi (Kip–Kişi–Çatı)': 1,
  },

  // =========================
  // KPSS - Matematik (kpss_mat)
  // =========================
  'kpss_mat': {
    'Temel Kavramlar': 3,
    'Sayı Basamakları': 2,
    'Bölme–Bölünebilme': 1,
    'EBOB–EKOK': 1,
    'Rasyonel Sayılar': 2,
    'Üslü–Köklü Sayılar': 3,
    'Oran–Orantı': 2,
    'Denklemler': 1,
    'Eşitsizlik–Mutlak Değer': 2,
    // 'Problemler': 30, // seed'de zaten 30 verdin; overwrite istemiyorsan yorumda kalsın
    'Kümeler': 1,
    'Fonksiyonlar': 1,
    'Permütasyon–Kombinasyon–Olasılık': 1,
    'Tablo–Grafik–Veri Yorumlama': 1,
  },

  // =========================
  // KPSS - Tarih (kpss_tarih)
  // =========================
  'kpss_tarih': {
    'İslamiyet Öncesi Türk Tarihi': 1,
    'İlk Türk-İslam Devletleri': 2,
    'Osmanlı Devleti Kuruluş Dönemi': 2,
    'Osmanlı Devleti Yükselme Dönemi': 2,
    'Osmanlı Devleti Duraklama Dönemi': 2,
    'Osmanlı Devleti Gerileme ve Dağılma': 3,
    '19. Yüzyıl Islahatları': 1,
    'Trablusgarp ve Balkan Savaşları': 1,
    'I. Dünya Savaşı ve Cepheler': 2,
    'Mondros–İşgaller–Cemiyetler': 2,
    'Kongreler Dönemi ve Mustafa Kemal': 2,
    'TBMM Dönemi ve Düzenli Ordu': 2,
    'Kurtuluş Savaşı Cepheleri': 3,
    'Lozan ve Atatürk Dönemi Dış Politika': 2,
    // 'Atatürk İnkılapları': 30, // seed'de 30 verdin; overwrite istemiyorsan yorumda kalsın
    'Atatürk İlkeleri ve Çağdaşlaşma': 2,
  },

  // =========================
  // KPSS - Coğrafya (kpss_cog)
  // =========================
  'kpss_cog': {
    'Harita Bilgisi': 2,
    'Dünya’nın Şekli ve Hareketleri': 1,
    'Türkiye’nin Coğrafi Konumu': 2,
    'İklim Bilgisi ve Hava Olayları': 2,
    'Yer Şekilleri': 3,
    'Sular (Akarsular–Göller–Denizler)': 2,
    'Toprak ve Bitki Örtüsü': 3,
    'Nüfus ve Yerleşme': 3,
    'Göç': 1,
    'Ekonomik Faaliyetler (Genel)': 2,
    'Tarım ve Hayvancılık': 1,
    'Madenler–Enerji–Sanayi': 3,
    'Ulaşım–Ticaret–Turizm': 1,
    'Türkiye’nin Bölgeleri': 2,
    'Çevre ve Doğal Afetler': 1,
  },

  // =========================
  // KPSS - Vatandaşlık (kpss_vat)
  // =========================
  'kpss_vat': {
    'Hukukun Temel Kavramları': 1,
    'Devlet Biçimleri–Demokrasi–Kuvvetler Ayrılığı': 1,
    'Anayasa Hukukuna Giriş–Türk Anayasa Tarihi': 1,
    '1982 Anayasası Temel İlkeler': 1,
    'Yasama': 3,
    'Yürütme': 3,
    'Yargı': 1,
    // 'Temel Hak ve Hürriyetler': 30, // seed'de 30 verdin; overwrite istemiyorsan yorumda kalsın
    'İdare Hukuku': 4,
    'Uluslararası Kuruluşlar': 1,
  },

  // =========================
  // KPSS - Güncel Bilgiler (kpss_guncel)
  // =========================
  'kpss_guncel': {
    'Güncel Olaylar': 1,
    'Kültür–Sanat–Spor Gündemi': 1,
    'Ekonomi–Bilim–Teknoloji Gündemi': 1,
  },
};

// subjectId’lerin seed’de farklıysa diye küçük fallback
const _kpssCountsFallbackByTitle = <String, int>{
  'Paragraf': 14,
  'Sayısal Mantık': 6,
  'Sözel Muhakeme ve Mantık': 4,
};

int _kpssQuestionCount(String subjectId, String title) {
  return _kpssCountsBySubjectId[subjectId]?[title] ??
      _kpssCountsFallbackByTitle[title] ??
      0;
}

/// KPSS için placeholder / boş kalan questionCount değerlerini gerçek KPSS dağılımına çevirir.
/// - Sadece `questionCount == 0` (boş) veya geçmiş sürümlerden kalan `== 20` olanları günceller.
/// - Kullanıcının sonradan verdiği değerleri (0/20 dışı) EZMEZ.
/// - Map'te karşılığı yoksa 0 bırakır (UI'da sayı görünmesin).
Future<void> _applyKpssQuestionCountsIfMissing(AppDatabase db) async {
  const kpssSubjectIds = <String>{
    'kpss_tr',
    'kpss_mat',
    'kpss_tarih',
    'kpss_cog',
    'kpss_vat',
    'kpss_guncel',
  };

  final rows = await (db.select(db.topics)
    ..where((t) =>
    t.subjectId.isIn(kpssSubjectIds.toList()) &
    t.questionCount.isIn(const [0, 20])))
      .get();

  if (rows.isEmpty) return;

  await db.batch((b) {
    for (final r in rows) {
      final newCount = _kpssQuestionCount(r.subjectId, r.title);
      b.update(
        db.topics,
        TopicsCompanion(questionCount: Value(newCount),),
        where: (t) => t.id.equals(r.id),
      );
    }
  });
}

Future<void> seedIfNeeded(AppDatabase db) async {
  // Seed exams if empty
  final examsExisting = await db.select(db.exams).get();
  if (examsExisting.isEmpty) {
    await db.batch((b) {
      b.insertAll(db.exams, const [
        ExamsCompanion(id: Value('kpss'), name: Value('KPSS')),
        ExamsCompanion(id: Value('ales'), name: Value('ALES')),
        ExamsCompanion(id: Value('dgs'), name: Value('DGS')),
        ExamsCompanion(id: Value('tyt'), name: Value('TYT')),
      ]);
    });
  }


  // Seed subjects if empty
  final subjectsExisting = await db.select(db.subjects).get();
  if (subjectsExisting.isEmpty) {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.batch((b) {
      b.insertAll(db.subjects, [
        SubjectsCompanion(
          id: const Value('kpss_guncel'),
          examId: const Value('kpss'),
          name: const Value('Güncel Bilgiler'),
          sortOrder: const Value(6),
        ),
        // KPSS
        SubjectsCompanion(id: const Value('kpss_tr'), examId: const Value('kpss'), name: const Value('Türkçe'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('kpss_mat'), examId: const Value('kpss'), name: const Value('Matematik'), sortOrder: const Value(2)),
        SubjectsCompanion(id: const Value('kpss_tarih'), examId: const Value('kpss'), name: const Value('Tarih'), sortOrder: const Value(3)),
        SubjectsCompanion(id: const Value('kpss_cog'), examId: const Value('kpss'), name: const Value('Coğrafya'), sortOrder: const Value(4)),
        SubjectsCompanion(id: const Value('kpss_vat'), examId: const Value('kpss'), name: const Value('Vatandaşlık'), sortOrder: const Value(5)),

        // ALES (başlangıç)
        SubjectsCompanion(id: const Value('ales_say'), examId: const Value('ales'), name: const Value('Sayısal'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('ales_soz'), examId: const Value('ales'), name: const Value('Sözel'), sortOrder: const Value(2)),

        // DGS (başlangıç)
        SubjectsCompanion(id: const Value('dgs_say'), examId: const Value('dgs'), name: const Value('Sayısal'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('dgs_soz'), examId: const Value('dgs'), name: const Value('Sözel'), sortOrder: const Value(2)),

        // TYT (başlangıç)
        SubjectsCompanion(id: const Value('tyt_tr'), examId: const Value('tyt'), name: const Value('Türkçe'), sortOrder: const Value(1)),
        SubjectsCompanion(id: const Value('tyt_mat'), examId: const Value('tyt'), name: const Value('Matematik'), sortOrder: const Value(2)),
        SubjectsCompanion(id: const Value('tyt_fen'), examId: const Value('tyt'), name: const Value('Fen'), sortOrder: const Value(3)),
        SubjectsCompanion(id: const Value('tyt_sos'), examId: const Value('tyt'), name: const Value('Sosyal'), sortOrder: const Value(4)),
      ]);

      // Not: createdAt alanı Subjects tablosunda yok; now şu an kullanılmıyor.
      // İleride Topics seed ederken createdAt set edeceğiz.
      // ignore: unused_local_variable
      // final _ = now;
    });
  }

  // Seed topics if empty
  final topicsExisting = await db.select(db.topics).get();
  if (topicsExisting.isEmpty) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Varsayılan tekrar görevi: 20 soru (sonradan kullanıcı değiştirebilir)
    const qc20 = Value(20);

    await db.batch((b) {
      b.insertAll(db.topics, [
        // =========================
        // KPSS - Türkçe (kpss_tr)
        // =========================
        TopicsCompanion(id: const Value('kpss_tr_sozcukte_anlam'), subjectId: const Value('kpss_tr'), title: const Value('Sözcükte Anlam'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Sözcükte Anlam alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_sozcukte_anlam_gercek_mecaz_terim'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcukte_anlam'), title: const Value('Gerçek–Mecaz–Terim Anlam'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcukte_anlam_es_anlam_zit_anlam'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcukte_anlam'), title: const Value('Eş Anlam–Zıt Anlam'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcukte_anlam_sestes'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcukte_anlam'), title: const Value('Sesteş (Eş Sesli) Sözcükler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcukte_anlam_deyim_atasozu'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcukte_anlam'), title: const Value('Deyim–Atasözü'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcukte_anlam_soz_sanatlari'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcukte_anlam'), title: const Value('Söz Sanatları (Temel)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam'), subjectId: const Value('kpss_tr'), title: const Value('Cümlede Anlam'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Cümlede Anlam alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam_amac_sonuc'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumlede_anlam'), title: const Value('Amaç–Sonuç'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam_neden_sonuc'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumlede_anlam'), title: const Value('Neden–Sonuç'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam_kosul_sonuc'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumlede_anlam'), title: const Value('Koşul–Sonuç'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam_karsilastirma'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumlede_anlam'), title: const Value('Karşılaştırma'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam_cikarim'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumlede_anlam'), title: const Value('Çıkarım (Sonuç Çıkarma)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumlede_anlam_oznel_nesnel'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumlede_anlam'), title: const Value('Öznel–Nesnel Yargı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_paragraf'), subjectId: const Value('kpss_tr'), title: const Value('Paragraf'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Paragraf alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_paragraf_konu_ana_dusunce'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_paragraf'), title: const Value('Konu–Ana Düşünce'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_paragraf_yardimci_dusunce'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_paragraf'), title: const Value('Yardımcı Düşünce'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_paragraf_yapi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_paragraf'), title: const Value('Paragrafın Yapısı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_paragraf_anlatim_bicimleri'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_paragraf'), title: const Value('Anlatım Biçimleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_paragraf_dusunceyi_gelistirme'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_paragraf'), title: const Value('Düşünceyi Geliştirme Yolları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_paragraf_soru_tipleri'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_paragraf'), title: const Value('Soru Tipleri ve Çözüm Teknikleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_anlatim_bozuklugu'), subjectId: const Value('kpss_tr'), title: const Value('Anlatım Bozukluğu'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Anlatım Bozukluğu alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_anlatim_bozuklugu_anlam'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_anlatim_bozuklugu'), title: const Value('Anlam Bozuklukları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_anlatim_bozuklugu_dil_bilgisi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_anlatim_bozuklugu'), title: const Value('Dil Bilgisi Bozuklukları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_anlatim_bozuklugu_gereksiz_sozcuk'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_anlatim_bozuklugu'), title: const Value('Gereksiz Sözcük Kullanımı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_anlatim_bozuklugu_celiski'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_anlatim_bozuklugu'), title: const Value('Çelişkili İfade'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi'), subjectId: const Value('kpss_tr'), title: const Value('Ses Bilgisi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Ses Bilgisi alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unlu_uyumlari'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünlü Uyumları (Büyük/Küçük)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unlu_dusmesi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünlü Düşmesi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unlu_turemesi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünlü Türemesi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unlu_daralmasi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünlü Daralması'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unsuz_benzesmesi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünsüz Benzeşmesi (Sertleşme)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unsuz_yumusamasi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünsüz Yumuşaması'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unsuz_dusmesi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünsüz Düşmesi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_ses_bilgisi_unsuz_turemesi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_ses_bilgisi'), title: const Value('Ünsüz Türemesi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_kurallari'), subjectId: const Value('kpss_tr'), title: const Value('Yazım Kuralları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Yazım Kuralları alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_yazim_buyuk_harf'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('Büyük Harflerin Yazımı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_birlesik_kelimeler'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('Birleşik Kelimelerin Yazımı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_de_da'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('-de/-da (Bağlaç mı Ek mi?)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_ki'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('-ki (Bağlaç mı Ek mi?)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_mi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('Soru Eki -mi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_sayilar'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('Sayıların Yazımı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_yazim_kisaltmalar'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_yazim_kurallari'), title: const Value('Kısaltmaların Yazımı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama'), subjectId: const Value('kpss_tr'), title: const Value('Noktalama İşaretleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Noktalama İşaretleri alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_noktalama_nokta'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Nokta (.)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_virgul'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Virgül (,)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_noktali_virgul'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Noktalı Virgül (;)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_iki_nokta'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('İki Nokta (:)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_soru'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Soru İşareti (?)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_unlem'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Ünlem (!)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_kesme'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Kesme İşareti (\' )'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_tirnak_parantez'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Tırnak / Parantez'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_noktalama_cizgi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_noktalama'), title: const Value('Kısa Çizgi (-) / Uzun Çizgi (—)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcuk_turleri'), subjectId: const Value('kpss_tr'), title: const Value('Sözcük Türleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Sözcük Türleri alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_sozcuk_turleri_isim'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcuk_turleri'), title: const Value('İsim (Ad)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcuk_turleri_sifat'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcuk_turleri'), title: const Value('Sıfat'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcuk_turleri_zamir'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcuk_turleri'), title: const Value('Zamir'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcuk_turleri_zarf'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcuk_turleri'), title: const Value('Zarf'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_sozcuk_turleri_edat_baglac_unlem'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_sozcuk_turleri'), title: const Value('Edat–Bağlaç–Ünlem'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumle_bilgisi'), subjectId: const Value('kpss_tr'), title: const Value('Cümle Bilgisi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Cümle Bilgisi alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_cumle_bilgisi_ogeler'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumle_bilgisi'), title: const Value('Cümlenin Ögeleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_cumle_bilgisi_cumle_turleri'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_cumle_bilgisi'), title: const Value('Cümle Türleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_fiil_ekler'), subjectId: const Value('kpss_tr'), title: const Value('Fiil Bilgisi (Kip–Kişi–Çatı)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Fiil Bilgisi alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_tr_fiil_kip_kisi'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_fiil_ekler'), title: const Value('Kip–Kişi Ekleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_fiil_birlesik_zaman'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_fiil_ekler'), title: const Value('Birleşik Zamanlar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_fiil_fiilimsiler'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_fiil_ekler'), title: const Value('Fiilimsiler (İsim/ Sıfat/ Zarf-Fiil)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tr_fiil_cati'), subjectId: const Value('kpss_tr'), parentTopicId: const Value('kpss_tr_fiil_ekler'), title: const Value('Çatı (Etken/Edilgen/Dönüşlü/İşteş)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),

        // =========================
        // KPSS - Matematik (kpss_mat)
        // =========================
        TopicsCompanion(id: const Value('kpss_mat_temsayilar_temelkavramlar'), subjectId: const Value('kpss_mat'), title: const Value('Temel Kavramlar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_sayibasamaklari'), subjectId: const Value('kpss_mat'), title: const Value('Sayı Basamakları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_bolme_bolunebilme'), subjectId: const Value('kpss_mat'), title: const Value('Bölme–Bölünebilme'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_ebob_ekok'), subjectId: const Value('kpss_mat'), title: const Value('EBOB–EKOK'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_rasyonel_sayilar'), subjectId: const Value('kpss_mat'), title: const Value('Rasyonel Sayılar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_uslu_koklu'), subjectId: const Value('kpss_mat'), title: const Value('Üslü–Köklü Sayılar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_oran_oranti'), subjectId: const Value('kpss_mat'), title: const Value('Oran–Orantı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_denklemler'), subjectId: const Value('kpss_mat'), title: const Value('Denklemler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_esitsizlik_mutlak'), subjectId: const Value('kpss_mat'), title: const Value('Eşitsizlik–Mutlak Değer'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_problemler'), subjectId: const Value('kpss_mat'), title: const Value('Problemler'), questionCount: const Value(30), intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        // --- Problemler alt başlıkları ---
        TopicsCompanion(id: const Value('kpss_mat_prob_sayi'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Sayı Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_yas'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Yaş Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_isci_havuz'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('İşçi–Havuz Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_hareket'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Hareket Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_oran_oranti'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Oran–Orantı Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_yuzde'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Yüzde Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_kar_zarar'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Kâr–Zarar Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_faiz'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Faiz Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_prob_karisim'), subjectId: const Value('kpss_mat'), parentTopicId: const Value('kpss_mat_problemler'), title: const Value('Karışım Problemleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_kumeler'), subjectId: const Value('kpss_mat'), title: const Value('Kümeler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_fonksiyonlar'), subjectId: const Value('kpss_mat'), title: const Value('Fonksiyonlar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_perm_kom_olas'), subjectId: const Value('kpss_mat'), title: const Value('Permütasyon–Kombinasyon–Olasılık'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_mat_grafik_tablo'), subjectId: const Value('kpss_mat'), title: const Value('Tablo–Grafik–Veri Yorumlama'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),

        // =========================
        // KPSS - Tarih (kpss_tarih)
        // =========================
        TopicsCompanion(id: const Value('kpss_tarih_islamiyet_oncesi'), subjectId: const Value('kpss_tarih'), title: const Value('İslamiyet Öncesi Türk Tarihi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_ilk_turk_islam'), subjectId: const Value('kpss_tarih'), title: const Value('İlk Türk-İslam Devletleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_osmanli_kurulus'), subjectId: const Value('kpss_tarih'), title: const Value('Osmanlı Devleti Kuruluş Dönemi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_osmanli_yukselme'), subjectId: const Value('kpss_tarih'), title: const Value('Osmanlı Devleti Yükselme Dönemi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_osmanli_duraklama'), subjectId: const Value('kpss_tarih'), title: const Value('Osmanlı Devleti Duraklama Dönemi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_osmanli_gerileme_dagilma'), subjectId: const Value('kpss_tarih'), title: const Value('Osmanlı Devleti Gerileme ve Dağılma'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_19yy_islahatlar'), subjectId: const Value('kpss_tarih'), title: const Value('19. Yüzyıl Islahatları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_trablusgarp_balkan'), subjectId: const Value('kpss_tarih'), title: const Value('Trablusgarp ve Balkan Savaşları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_birinci_dunya'), subjectId: const Value('kpss_tarih'), title: const Value('I. Dünya Savaşı ve Cepheler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_mondros_isgaller'), subjectId: const Value('kpss_tarih'), title: const Value('Mondros–İşgaller–Cemiyetler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_kongreler_mustafa_kemal'), subjectId: const Value('kpss_tarih'), title: const Value('Kongreler Dönemi ve Mustafa Kemal'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_tbmm_donemi'), subjectId: const Value('kpss_tarih'), title: const Value('TBMM Dönemi ve Düzenli Ordu'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_kurtulus_savasi'), subjectId: const Value('kpss_tarih'), title: const Value('Kurtuluş Savaşı Cepheleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_lozan_dis_politika'), subjectId: const Value('kpss_tarih'), title: const Value('Lozan ve Atatürk Dönemi Dış Politika'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_inkilaplar'), subjectId: const Value('kpss_tarih'), title: const Value('Atatürk İnkılapları'), questionCount: const Value(30), intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_tarih_ilkeler_ve_cagdaslasma'), subjectId: const Value('kpss_tarih'), title: const Value('Atatürk İlkeleri ve Çağdaşlaşma'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),

        // =========================
        // KPSS - Coğrafya (kpss_cog)
        // =========================
        TopicsCompanion(id: const Value('kpss_cog_harita_bilgisi'), subjectId: const Value('kpss_cog'), title: const Value('Harita Bilgisi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_dunya_sekli_hareketleri'), subjectId: const Value('kpss_cog'), title: const Value('Dünya’nın Şekli ve Hareketleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_konum'), subjectId: const Value('kpss_cog'), title: const Value('Türkiye’nin Coğrafi Konumu'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_iklim_ve_hava'), subjectId: const Value('kpss_cog'), title: const Value('İklim Bilgisi ve Hava Olayları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_yersekilleri'), subjectId: const Value('kpss_cog'), title: const Value('Yer Şekilleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_sular'), subjectId: const Value('kpss_cog'), title: const Value('Sular (Akarsular–Göller–Denizler)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_toprak_bitki'), subjectId: const Value('kpss_cog'), title: const Value('Toprak ve Bitki Örtüsü'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_nufus_yerlesme'), subjectId: const Value('kpss_cog'), title: const Value('Nüfus ve Yerleşme'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_goc'), subjectId: const Value('kpss_cog'), title: const Value('Göç'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_ekonomik_faaliyetler'), subjectId: const Value('kpss_cog'), title: const Value('Ekonomik Faaliyetler (Genel)'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_tarim_hayvancilik'), subjectId: const Value('kpss_cog'), title: const Value('Tarım ve Hayvancılık'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_maden_enerji_sanayi'), subjectId: const Value('kpss_cog'), title: const Value('Madenler–Enerji–Sanayi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_ulasim_ticaret_turizm'), subjectId: const Value('kpss_cog'), title: const Value('Ulaşım–Ticaret–Turizm'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_bolgeler'), subjectId: const Value('kpss_cog'), title: const Value('Türkiye’nin Bölgeleri'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_cog_cevre_sorunlari'), subjectId: const Value('kpss_cog'), title: const Value('Çevre ve Doğal Afetler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),

        // =========================
        // KPSS - Vatandaşlık (kpss_vat)
        // =========================
        TopicsCompanion(id: const Value('kpss_vat_hukukun_temel_kavramlari'), subjectId: const Value('kpss_vat'), title: const Value('Hukukun Temel Kavramları'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_devlet_sekilleri'), subjectId: const Value('kpss_vat'), title: const Value('Devlet Biçimleri–Demokrasi–Kuvvetler Ayrılığı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_anayasa_giris'), subjectId: const Value('kpss_vat'), title: const Value('Anayasa Hukukuna Giriş–Türk Anayasa Tarihi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_1982_ilkeler'), subjectId: const Value('kpss_vat'), title: const Value('1982 Anayasası Temel İlkeler'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_yasama'), subjectId: const Value('kpss_vat'), title: const Value('Yasama'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_yurutme'), subjectId: const Value('kpss_vat'), title: const Value('Yürütme'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_yargi'), subjectId: const Value('kpss_vat'), title: const Value('Yargı'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_temm_haklar'), subjectId: const Value('kpss_vat'), title: const Value('Temel Hak ve Hürriyetler'), questionCount: const Value(30), intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_idare_hukuku'), subjectId: const Value('kpss_vat'), title: const Value('İdare Hukuku'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_vat_uluslararasi_kuruluslar'), subjectId: const Value('kpss_vat'), title: const Value('Uluslararası Kuruluşlar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),

        // =========================
        // KPSS - Güncel Bilgiler (kpss_guncel)
        // =========================
        TopicsCompanion(id: const Value('kpss_guncel_guncel_olaylar'), subjectId: const Value('kpss_guncel'), title: const Value('Güncel Olaylar'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_guncel_kultur_sanat_spor'), subjectId: const Value('kpss_guncel'), title: const Value('Kültür–Sanat–Spor Gündemi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
        TopicsCompanion(id: const Value('kpss_guncel_ekonomi_bilim_teknoloji'), subjectId: const Value('kpss_guncel'), title: const Value('Ekonomi–Bilim–Teknoloji Gündemi'), questionCount: qc20, intervalIndex: const Value(0), lastReviewedAt: const Value(null), nextReviewAt: const Value(null), archived: const Value(false), createdAt: Value(now)),
      ]);
    });
  }

  // Daha önce seed'lenmiş (questionCount=20) KPSS konularını gerçek KPSS dağılımına çevir.
  // KPSS için placeholder olarak kalan questionCount=20 değerlerini gerçek dağılıma çevirir.
// (Sadece == 20 olanları günceller, kullanıcı değişikliklerini ezmez.)
  await _applyKpssQuestionCountsIfMissing(db);

}

Future<void> applyQuestionCounts(AppDatabase db) async {
  // subjectId -> (topicTitle -> questionCount)
  const counts = <String, Map<String, int>>{
    // KPSS - Türkçe
    'kpss_tr': {
      'Paragraf': 14,
      'Sözel Muhakeme ve Mantık': 4,
      'Cümlenin Anlamı, Yorumu': 3,
      'Sözcük Türleri': 2,
      'Paragrafta Anlatım Yolları, Biçimleri': 2,
      'Ses Olayları': 1,
      'Yazım Kuralları': 1,
      'Cümlenin Ögeleri': 1,
      'Sözcüğün Yapısı, Ekler': 1,
      'Sözcüğün, Söz gruplarının Anlamı': 1,
    },

    // KPSS - Matematik (başlıklar seed'deki title ile birebir aynı olmalı)
    'kpss_mat': {
      'Temel Kavramlar': 2,
      'Sayı Basamakları': 1,
      'Bölme ve Bölünebilme': 1,
      'OBEB - OKEK': 1,
      'Rasyonel Sayılar': 1,
      'Basit Eşitsizlikler': 1,
      'Mutlak Değer': 1,
      'Üslü Sayılar': 1,
      'Köklü Sayılar': 1,
      'Çarpanlara Ayırma': 1,
      'Oran - Orantı': 1,
      'Denklem Çözme': 1,
      'Problemler': 12,
      'Kümeler': 1,
      'Fonksiyonlar': 1,
      'Permütasyon - Kombinasyon - Olasılık': 1,
      'Tablo ve Grafik': 2,
    },

    // KPSS - Tarih
    'kpss_tarih': {
      'Tarih Bilimine Giriş': 1,
      'İlk Çağ Uygarlıkları': 1,
      'İslamiyet Öncesi Türk Tarihi': 1,
      'İslam Tarihi': 1,
      'Türk-İslam Devletleri': 2,
      'Osmanlı Kuruluş ve Yükselme': 4,
      'Osmanlı Kültür ve Medeniyet': 3,
      'Osmanlı Duraklama - Gerileme - Dağılma': 5,
      'Kurtuluş Savaşı': 4,
      'Atatürk Dönemi İç Politika': 2,
      'Lozan ve Atatürk Dönemi Dış Politika': 2,
      'Atatürk İnkılapları': 1,
      'Atatürk İlkeleri ve Çağdaşlaşma': 1,
    },

    // KPSS - Coğrafya
    'kpss_cog': {
      'Harita Bilgisi': 2,
      'Dünya’nın Şekli ve Hareketleri': 1,
      'Türkiye’nin Coğrafi Konumu': 1,
      'İklim Bilgisi ve Hava Olayları': 2,
      'Yer Şekilleri': 3,
      'Sular (Akarsular–Göller–Denizler)': 2,
      'Toprak ve Bitki Örtüsü': 2,
      'Nüfus ve Yerleşme': 2,
      'Göç': 1,
      'Ekonomik Faaliyetler (Genel)': 2,
      'Tarım ve Hayvancılık': 1,
      'Madenler–Enerji–Sanayi': 1,
      'Ulaşım–Ticaret–Turizm': 1,
      'Türkiye’nin Bölgeleri': 1,
      'Çevre ve Doğal Afetler': 1,
    },

    // KPSS - Vatandaşlık
    'kpss_vat': {
      'Hukukun Temel Kavramları': 2,
      'Devlet Biçimleri–Demokrasi–Kuvvetler Ayrılığı': 2,
      'Anayasa Hukukuna Giriş–Türk Anayasa Tarihi': 2,
      '1982 Anayasası Temel İlkeler': 3,
      'Yasama': 3,
      'Yürütme': 3,
      'Yargı': 2,
      'Temel Hak ve Hürriyetler': 5,
      'İdare Hukuku': 3,
      'Uluslararası Kuruluşlar': 2,
    },

    // KPSS - Güncel Bilgiler
    'kpss_guncel': {
      'Güncel Olaylar': 3,
      'Kültür–Sanat–Spor Gündemi': 2,
      'Ekonomi–Bilim–Teknoloji Gündemi': 1,
    },
  };

  for (final entry in counts.entries) {
    final subjectId = entry.key;
    final topicMap = entry.value;

    for (final t in topicMap.entries) {
      final title = t.key;
      final qc = t.value;

      await (db.update(db.topics)
        ..where((row) =>
        row.subjectId.equals(subjectId) &
        row.title.equals(title) &
        row.archived.equals(false)))
          .write(TopicsCompanion(questionCount: drift.Value(qc)));
    }
  }
}