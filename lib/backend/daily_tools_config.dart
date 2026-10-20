import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

enum DailyToolType {
  quran,
  prayer,
  qibla,
  tasbih,
  dua,
  downloads,
  search,
  readingPlans,
  hifz,
  asmaUlHusna,
  statistics,
  calendar,
  zakah;

  static const List<DailyToolType> defaultTools = <DailyToolType>[
    quran,
    prayer,
    qibla,
    tasbih,
    dua,
    downloads,
    search,
  ];

  IconData get icon {
    return switch (this) {
      quran => Icons.menu_book_outlined,
      prayer => Icons.schedule_outlined,
      qibla => Icons.explore_outlined,
      tasbih => Icons.auto_awesome_outlined,
      dua => Icons.auto_stories_outlined,
      downloads => Icons.download_outlined,
      search => Icons.search_rounded,
      readingPlans => Icons.route_outlined,
      hifz => Icons.menu_book_rounded,
      asmaUlHusna => Icons.diamond_outlined,
      statistics => Icons.insights_outlined,
      calendar => Icons.calendar_month_outlined,
      zakah => Icons.calculate_outlined,
    };
  }

  String? get assetPath {
    const String base = 'assets/media/images/app';
    return switch (this) {
      quran => '$base/read.webp',
      prayer => '$base/prayer_time.webp',
      qibla => '$base/qiblah.webp',
      tasbih => '$base/tasbih.webp',
      dua => '$base/dua.webp',
      downloads => '$base/download.webp',
      search => '$base/quran.webp',
      readingPlans => null,
      hifz => '$base/hifz.webp',
      asmaUlHusna => '$base/dua.webp',
      statistics => '$base/last_read.webp',
      calendar => null,
      zakah => null,
    };
  }

  String getTitle(AppLocalizations localizations) {
    final String lang = localizations.localeName.split('_').first.toLowerCase();
    return switch (this) {
      quran => localizations.quran,
      prayer => localizations.prayer,
      qibla => localizations.qibla,
      tasbih => localizations.tasbih,
      dua => localizations.dua,
      downloads => localizations.downloads,
      search => localizations.search,
      readingPlans => localizations.readingRoutine,
      hifz => localizations.hifz,
      asmaUlHusna => localizations.asmaUlHusna,
      statistics => localizations.statistics,
      calendar => _translateCalendar(lang),
      zakah => _translateZakah(lang),
    };
  }

  String getSubtitle(AppLocalizations localizations) {
    final String lang = localizations.localeName.split('_').first.toLowerCase();
    return switch (this) {
      quran => localizations.dailyQuranCompanionSubtitle,
      prayer => localizations.prayerTimesSettings,
      qibla => localizations.compassAndDirection,
      tasbih => localizations.calmDhikrCounter,
      dua => localizations.duasAndAzkar,
      downloads => localizations.offlineAudioAndCleanup,
      search => localizations.searchArabicAndTranslation,
      readingPlans => localizations.plansGoalsProgress,
      hifz => localizations.hifzSubtitle,
      asmaUlHusna => localizations.the99BeautifulNames,
      statistics => localizations.worshipTrendsAndStreaks,
      calendar => _translateCalendarSubtitle(lang),
      zakah => _translateZakahSubtitle(lang),
    };
  }

  String _translateCalendar(String lang) {
    return switch (lang) {
      'ar' => 'التقويم الهجري',
      'fa' => 'تقویم هجری',
      'de' => 'Hijri-Kalender',
      'bn' => 'হিজরি ক্যালেন্ডার',
      'id' => 'Kalender Hijriah',
      'tr' => 'Hicri Takvim',
      'ur' => 'ہجری کیلنڈر',
      _ => 'Hijri Calendar',
    };
  }

  String _translateCalendarSubtitle(String lang) {
    return switch (lang) {
      'ar' => 'عرض التواريخ والمناسبات الهجرية',
      'fa' => 'مشاهده تاریخ‌های هجری و مناسبت‌های اسلامی',
      'de' => 'Hijri-Daten und islamische Ereignisse anzeigen',
      'bn' => 'হিজরি তারিখ ও ঘটনাবলী দেখুন',
      'id' => 'Lihat tanggal dan hari penting Hijriah',
      'tr' => 'Hicri tarihleri ve önemli günleri görün',
      'ur' => 'ہجری تاریخیں اور اہم ایام دیکھیں',
      _ => 'View Hijri dates and Islamic events',
    };
  }

  String _translateZakah(String lang) {
    return switch (lang) {
      'ar' => 'حساب الزكاة',
      'fa' => 'محاسبه زکات',
      'de' => 'Zakat-Rechner',
      'bn' => 'যাকাত ক্যালকুলেটর',
      'id' => 'Kalkulator Zakat',
      'tr' => 'Zekat Hesaplama',
      'ur' => 'زکوٰۃ کیلکولیٹر',
      _ => 'Zakah Calculator',
    };
  }

  String _translateZakahSubtitle(String lang) {
    return switch (lang) {
      'ar' => 'احسب زكاة مالك بسهولة',
      'fa' => 'محاسبه آسان زکات مال خود',
      'de' => 'Berechnen Sie Ihre fällige Zakat ganz einfach',
      'bn' => 'সহজেই যাকাত হিসাব করুন',
      'id' => 'Hitung zakat harta Anda dengan mudah',
      'tr' => 'Malınızın zekatını kolayca hesaplayın',
      'ur' => 'اپنے مال کی زکوٰۃ کا آسان حساب',
      _ => 'Calculate your zakah due easily',
    };
  }
}
