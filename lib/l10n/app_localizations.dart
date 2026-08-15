import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_id.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('fa'),
    Locale('id'),
    Locale('tr'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'eQuran'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// No description provided for @duas.
  ///
  /// In en, this message translates to:
  /// **'Duas'**
  String get duas;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @qibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qibla;

  /// No description provided for @tasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbih;

  /// No description provided for @asmaUlHusna.
  ///
  /// In en, this message translates to:
  /// **'Asma ul Husna'**
  String get asmaUlHusna;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @farsi.
  ///
  /// In en, this message translates to:
  /// **'Farsi'**
  String get farsi;

  /// No description provided for @quranScriptStyle.
  ///
  /// In en, this message translates to:
  /// **'Quran Script Style'**
  String get quranScriptStyle;

  /// No description provided for @uthmaniMadinah.
  ///
  /// In en, this message translates to:
  /// **'Uthmani (Madinah)'**
  String get uthmaniMadinah;

  /// No description provided for @qpcV4Tajweed.
  ///
  /// In en, this message translates to:
  /// **'QPC V4 (Tajweed)'**
  String get qpcV4Tajweed;

  /// No description provided for @indoPak.
  ///
  /// In en, this message translates to:
  /// **'IndoPak'**
  String get indoPak;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable haptic feedback when navigating.'**
  String get vibrationSubtitle;

  /// No description provided for @showReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Show reading history'**
  String get showReadingHistory;

  /// No description provided for @showReadingHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows you up to 7 last read Surahs.'**
  String get showReadingHistorySubtitle;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @generalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App behavior and history'**
  String get generalSubtitle;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @readingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quran display and translation'**
  String get readingSubtitle;

  /// No description provided for @cardView.
  ///
  /// In en, this message translates to:
  /// **'Card View'**
  String get cardView;

  /// No description provided for @cardViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Displays each verse separately, or all in one page.'**
  String get cardViewSubtitle;

  /// No description provided for @displayTranslation.
  ///
  /// In en, this message translates to:
  /// **'Display Translation'**
  String get displayTranslation;

  /// No description provided for @displayTranslationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display translation for each verse in card view.'**
  String get displayTranslationSubtitle;

  /// No description provided for @displayTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Display Transliteration'**
  String get displayTransliteration;

  /// No description provided for @displayTransliterationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show transliteration for each verse in card view.'**
  String get displayTransliterationSubtitle;

  /// No description provided for @dailyQuranGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Quran goal'**
  String get dailyQuranGoal;

  /// No description provided for @dailyQuranGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs per day'**
  String dailyQuranGoalSubtitle(int count);

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciter;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @audioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reciter and playback'**
  String get audioSubtitle;

  /// No description provided for @downloadableResources.
  ///
  /// In en, this message translates to:
  /// **'Downloadable Resources'**
  String get downloadableResources;

  /// No description provided for @downloadableResourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tafsir and audio timing packs'**
  String get downloadableResourcesSubtitle;

  /// No description provided for @prayerTimesSettings.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times Settings'**
  String get prayerTimesSettings;

  /// No description provided for @prayerTimesSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage location, method, Asr, time format, and offsets.'**
  String get prayerTimesSettingsSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, color, and display mode'**
  String get appearanceSubtitle;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @colorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color scheme'**
  String get colorScheme;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @dataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup, restore, or clear saved local data'**
  String get dataSubtitle;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get backupData;

  /// No description provided for @backupDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exports favourites, reading history, reciter, text sizes, and all settings.'**
  String get backupDataSubtitle;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore data'**
  String get restoreData;

  /// No description provided for @restoreDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restores favourites, reading history, reciter, text sizes, and saved settings from a backup file.'**
  String get restoreDataSubtitle;

  /// No description provided for @clearReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear reading history'**
  String get clearReadingHistory;

  /// No description provided for @clearReadingHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes last read, resume positions, and Quran reading progress.'**
  String get clearReadingHistorySubtitle;

  /// No description provided for @clearFavourites.
  ///
  /// In en, this message translates to:
  /// **'Clear Favourites'**
  String get clearFavourites;

  /// No description provided for @clearFavouritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes saved ayahs, folders, notes, tags, and favourites.'**
  String get clearFavouritesSubtitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @lastRead.
  ///
  /// In en, this message translates to:
  /// **'Last Read'**
  String get lastRead;

  /// No description provided for @beginWithQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran Reading'**
  String get beginWithQuran;

  /// No description provided for @startReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start reading and your place will appear here.'**
  String get startReadingSubtitle;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// No description provided for @beginListeningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to the recitation and your place will appear here.'**
  String get beginListeningSubtitle;

  /// No description provided for @startReadingRoutine.
  ///
  /// In en, this message translates to:
  /// **'Start a reading routine'**
  String get startReadingRoutine;

  /// No description provided for @buildDailyQuranHabit.
  ///
  /// In en, this message translates to:
  /// **'Build a daily Quran habit'**
  String get buildDailyQuranHabit;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @readingRoutine.
  ///
  /// In en, this message translates to:
  /// **'Reading Routine'**
  String get readingRoutine;

  /// No description provided for @continueRoutine.
  ///
  /// In en, this message translates to:
  /// **'Continue Routine'**
  String get continueRoutine;

  /// No description provided for @dailyQuranCompanion.
  ///
  /// In en, this message translates to:
  /// **'Daily Quran Companion'**
  String get dailyQuranCompanion;

  /// No description provided for @dailyQuranCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up your recitation and daily tools'**
  String get dailyQuranCompanionSubtitle;

  /// No description provided for @dailyTools.
  ///
  /// In en, this message translates to:
  /// **'Daily Tools'**
  String get dailyTools;

  /// No description provided for @dailyToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast access to the essentials'**
  String get dailyToolsSubtitle;

  /// No description provided for @exploreAllFeatures.
  ///
  /// In en, this message translates to:
  /// **'Explore all features'**
  String get exploreAllFeatures;

  /// No description provided for @dailyAyah.
  ///
  /// In en, this message translates to:
  /// **'Daily Ayah'**
  String get dailyAyah;

  /// No description provided for @dailyDua.
  ///
  /// In en, this message translates to:
  /// **'Daily Dua'**
  String get dailyDua;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @quranJourney.
  ///
  /// In en, this message translates to:
  /// **'Quran Journey'**
  String get quranJourney;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// No description provided for @exploreQibla.
  ///
  /// In en, this message translates to:
  /// **'Explore Qibla'**
  String get exploreQibla;

  /// No description provided for @tasbihCounter.
  ///
  /// In en, this message translates to:
  /// **'Tasbih Counter'**
  String get tasbihCounter;

  /// No description provided for @duasAndAzkar.
  ///
  /// In en, this message translates to:
  /// **'Duas & Azkar'**
  String get duasAndAzkar;

  /// No description provided for @readingPlans.
  ///
  /// In en, this message translates to:
  /// **'Reading Plans'**
  String get readingPlans;

  /// No description provided for @quranStatistics.
  ///
  /// In en, this message translates to:
  /// **'Quran Statistics'**
  String get quranStatistics;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @dua.
  ///
  /// In en, this message translates to:
  /// **'Dua'**
  String get dua;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @searchQuran.
  ///
  /// In en, this message translates to:
  /// **'Search Quran'**
  String get searchQuran;

  /// No description provided for @searchHintSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah name or number...'**
  String get searchHintSurah;

  /// No description provided for @searchHintJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz number or surah name...'**
  String get searchHintJuz;

  /// No description provided for @searchHintPage.
  ///
  /// In en, this message translates to:
  /// **'Page number, surah, or juz...'**
  String get searchHintPage;

  /// No description provided for @searchHintSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved ayah, surah, note, or number...'**
  String get searchHintSaved;

  /// No description provided for @searchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search Quran Arabic or translation...'**
  String get searchHintText;

  /// No description provided for @savedAyahs.
  ///
  /// In en, this message translates to:
  /// **'Saved Ayahs'**
  String get savedAyahs;

  /// No description provided for @ayahNumber.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String ayahNumber(int number);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @audioOptions.
  ///
  /// In en, this message translates to:
  /// **'Audio Options'**
  String get audioOptions;

  /// No description provided for @dismissPlayer.
  ///
  /// In en, this message translates to:
  /// **'Dismiss player'**
  String get dismissPlayer;

  /// No description provided for @playbackOptions.
  ///
  /// In en, this message translates to:
  /// **'Playback options'**
  String get playbackOptions;

  /// No description provided for @previousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get previousAyah;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get nextAyah;

  /// No description provided for @autoPlayback.
  ///
  /// In en, this message translates to:
  /// **'Auto Playback'**
  String get autoPlayback;

  /// No description provided for @repeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Repeat Interval'**
  String get repeatInterval;

  /// No description provided for @downloadSurahAudio.
  ///
  /// In en, this message translates to:
  /// **'Download Surah Audio'**
  String get downloadSurahAudio;

  /// No description provided for @deleteDownloadedAudio.
  ///
  /// In en, this message translates to:
  /// **'Delete Downloaded Audio'**
  String get deleteDownloadedAudio;

  /// No description provided for @deleteDownloadQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Download?'**
  String get deleteDownloadQuestion;

  /// No description provided for @removeDownloadFromOffline.
  ///
  /// In en, this message translates to:
  /// **'Remove {title} from offline storage?'**
  String removeDownloadFromOffline(String title);

  /// No description provided for @deletedDownload.
  ///
  /// In en, this message translates to:
  /// **'Deleted {title}'**
  String deletedDownload(String title);

  /// No description provided for @deleteAllDownloadsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete All Downloads?'**
  String get deleteAllDownloadsQuestion;

  /// No description provided for @deleteAllDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove {count} downloaded audio files ({size}).'**
  String deleteAllDownloadsBody(int count, String size);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @deletedAllDownloadedAudio.
  ///
  /// In en, this message translates to:
  /// **'Deleted all downloaded audio.'**
  String get deletedAllDownloadedAudio;

  /// No description provided for @offlineAudio.
  ///
  /// In en, this message translates to:
  /// **'Offline Audio'**
  String get offlineAudio;

  /// No description provided for @surahAyahSummary.
  ///
  /// In en, this message translates to:
  /// **'{surahCount} surahs • {ayahCount} ayahs'**
  String surahAyahSummary(int surahCount, int ayahCount);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @cleanupPreview.
  ///
  /// In en, this message translates to:
  /// **'Cleanup preview'**
  String get cleanupPreview;

  /// No description provided for @downloadedSurahs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded surahs'**
  String get downloadedSurahs;

  /// No description provided for @downloadedAyahs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded ayahs'**
  String get downloadedAyahs;

  /// No description provided for @potentialSpaceToFree.
  ///
  /// In en, this message translates to:
  /// **'Potential space to free'**
  String get potentialSpaceToFree;

  /// No description provided for @cleanupDoesNotRemoveData.
  ///
  /// In en, this message translates to:
  /// **'Cleanup never removes favourites, notes, reading plans, Quran text, or settings.'**
  String get cleanupDoesNotRemoveData;

  /// No description provided for @reviewDeletion.
  ///
  /// In en, this message translates to:
  /// **'Review deletion'**
  String get reviewDeletion;

  /// No description provided for @noDownloadedAudioYet.
  ///
  /// In en, this message translates to:
  /// **'No downloaded audio yet.'**
  String get noDownloadedAudioYet;

  /// No description provided for @downloadedAudioEmpty.
  ///
  /// In en, this message translates to:
  /// **'Downloaded surahs and ayahs will appear here grouped by reciter.'**
  String get downloadedAudioEmpty;

  /// No description provided for @ayahs.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get ayahs;

  /// No description provided for @deleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Delete download'**
  String get deleteDownload;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @unableToReconnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to reconnect'**
  String get unableToReconnect;

  /// No description provided for @reciterOptions.
  ///
  /// In en, this message translates to:
  /// **'Reciter Options'**
  String get reciterOptions;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeModeSystem;

  /// No description provided for @themeModeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeDialogTitle;

  /// No description provided for @themeModeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use night mode.'**
  String get themeModeDarkSubtitle;

  /// No description provided for @themeModeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use light mode.'**
  String get themeModeLightSubtitle;

  /// No description provided for @themeModeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow the system theme.'**
  String get themeModeSystemSubtitle;

  /// No description provided for @colorSchemeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
  String get colorSchemeDialogTitle;

  /// No description provided for @translationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translation language'**
  String get translationLanguage;

  /// No description provided for @notDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get notDownloaded;

  /// No description provided for @playbackRate.
  ///
  /// In en, this message translates to:
  /// **'Playback Rate'**
  String get playbackRate;

  /// No description provided for @arabicTextSize.
  ///
  /// In en, this message translates to:
  /// **'Arabic text size'**
  String get arabicTextSize;

  /// No description provided for @translationTextSize.
  ///
  /// In en, this message translates to:
  /// **'Translation text size'**
  String get translationTextSize;

  /// No description provided for @resourcesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Resources unavailable'**
  String get resourcesUnavailable;

  /// No description provided for @resourcesManifestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the resource manifest.'**
  String get resourcesManifestUnavailable;

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @audioTimings.
  ///
  /// In en, this message translates to:
  /// **'Audio Timings'**
  String get audioTimings;

  /// No description provided for @translations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get translations;

  /// No description provided for @refreshManifest.
  ///
  /// In en, this message translates to:
  /// **'Refresh manifest'**
  String get refreshManifest;

  /// No description provided for @checkGithubReleases.
  ///
  /// In en, this message translates to:
  /// **'Check GitHub releases for changes'**
  String get checkGithubReleases;

  /// No description provided for @noResourcesListed.
  ///
  /// In en, this message translates to:
  /// **'No resources listed in the manifest.'**
  String get noResourcesListed;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @translationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This translation is not supported yet.'**
  String get translationUnsupported;

  /// No description provided for @translationNotInManifest.
  ///
  /// In en, this message translates to:
  /// **'This translation is not in the resource manifest.'**
  String get translationNotInManifest;

  /// No description provided for @downloadTranslationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Download {name}?'**
  String downloadTranslationQuestion(String name);

  /// No description provided for @translationNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'This translation is not installed on this device. {size}'**
  String translationNotInstalled(String size);

  /// No description provided for @installedResource.
  ///
  /// In en, this message translates to:
  /// **'Installed {name}.'**
  String installedResource(String name);

  /// No description provided for @unableInstallResource.
  ///
  /// In en, this message translates to:
  /// **'Unable to install this resource.'**
  String get unableInstallResource;

  /// No description provided for @deleteResourceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteResourceQuestion(String name);

  /// No description provided for @deleteResourceBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the downloaded files from this device.'**
  String get deleteResourceBody;

  /// No description provided for @deletedResource.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}.'**
  String deletedResource(String name);

  /// No description provided for @ayahsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Ayahs per day'**
  String get ayahsPerDay;

  /// No description provided for @enterGoalRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a goal from 1 to 1000 ayahs'**
  String get enterGoalRange;

  /// No description provided for @clearReadingHistoryWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: This will clear last read, resume positions, statistics, and routine day progress.'**
  String get clearReadingHistoryWarning;

  /// No description provided for @clearFavouritesWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: This will clear every saved ayah, folder, note, tag, and favourite.'**
  String get clearFavouritesWarning;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yes;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current favourites, reading history, and saved settings with the contents of the backup file.'**
  String get restoreBackupWarning;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backupReadyToShare.
  ///
  /// In en, this message translates to:
  /// **'Backup file ready to share.'**
  String get backupReadyToShare;

  /// No description provided for @backupSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path}'**
  String backupSavedTo(String path);

  /// No description provided for @unableCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the backup file.'**
  String get unableCreateBackup;

  /// No description provided for @restoredBackupSummary.
  ///
  /// In en, this message translates to:
  /// **'Restored {favouritesCount} favourites, {readingHistoryCount} history entries, and {settingsCount} settings.'**
  String restoredBackupSummary(
    int favouritesCount,
    int readingHistoryCount,
    int settingsCount,
  );

  /// No description provided for @unableRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore the selected backup.'**
  String get unableRestoreBackup;

  /// No description provided for @locationAndCalculationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location and calculation settings'**
  String get locationAndCalculationSettings;

  /// No description provided for @quranSearch.
  ///
  /// In en, this message translates to:
  /// **'Quran Search'**
  String get quranSearch;

  /// No description provided for @searchArabicAndTranslation.
  ///
  /// In en, this message translates to:
  /// **'Search Arabic and translation'**
  String get searchArabicAndTranslation;

  /// No description provided for @recitationsAndAudioControls.
  ///
  /// In en, this message translates to:
  /// **'Recitations and audio controls'**
  String get recitationsAndAudioControls;

  /// No description provided for @compassAndDirection.
  ///
  /// In en, this message translates to:
  /// **'Compass and direction'**
  String get compassAndDirection;

  /// No description provided for @offlineAudioAndCleanup.
  ///
  /// In en, this message translates to:
  /// **'Offline audio and cleanup'**
  String get offlineAudioAndCleanup;

  /// No description provided for @plansGoalsProgress.
  ///
  /// In en, this message translates to:
  /// **'Plans, goals, and progress'**
  String get plansGoalsProgress;

  /// No description provided for @calmDhikrCounter.
  ///
  /// In en, this message translates to:
  /// **'Calm dhikr counter'**
  String get calmDhikrCounter;

  /// No description provided for @the99BeautifulNames.
  ///
  /// In en, this message translates to:
  /// **'The 99 Beautiful Names'**
  String get the99BeautifulNames;

  /// No description provided for @worshipTrendsAndStreaks.
  ///
  /// In en, this message translates to:
  /// **'Worship trends and streaks'**
  String get worshipTrendsAndStreaks;

  /// No description provided for @fontsReciterAppBehavior.
  ///
  /// In en, this message translates to:
  /// **'Fonts, reciter, app behavior'**
  String get fontsReciterAppBehavior;

  /// No description provided for @switchLightOrNightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch light or night mode'**
  String get switchLightOrNightMode;

  /// No description provided for @yourIslamicCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your Islamic Companion'**
  String get yourIslamicCompanion;

  /// No description provided for @moreHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla, downloads, settings, plans, and tools gathered in one quiet place.'**
  String get moreHeroSubtitle;

  /// No description provided for @openRoutine.
  ///
  /// In en, this message translates to:
  /// **'Open routine'**
  String get openRoutine;

  /// No description provided for @aboutAppBody.
  ///
  /// In en, this message translates to:
  /// **'eQuran is a modern Quran companion designed for focused reading, listening, and daily reflection.'**
  String get aboutAppBody;

  /// No description provided for @supportProject.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportProject;

  /// No description provided for @supportProjectDescription.
  ///
  /// In en, this message translates to:
  /// **'If eQuran helps you, you can support its development with a crypto donation.'**
  String get supportProjectDescription;

  /// No description provided for @bitcoin.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin (BTC)'**
  String get bitcoin;

  /// No description provided for @ethereum.
  ///
  /// In en, this message translates to:
  /// **'Ethereum (ETH)'**
  String get ethereum;

  /// No description provided for @solana.
  ///
  /// In en, this message translates to:
  /// **'Solana (SOL)'**
  String get solana;

  /// No description provided for @usdcErc20.
  ///
  /// In en, this message translates to:
  /// **'USDC (ERC-20)'**
  String get usdcErc20;

  /// No description provided for @litecoin.
  ///
  /// In en, this message translates to:
  /// **'Litecoin (LTC)'**
  String get litecoin;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get addressCopied;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @downloadEquran.
  ///
  /// In en, this message translates to:
  /// **'Download eQuran'**
  String get downloadEquran;

  /// No description provided for @downloadEquranShareText.
  ///
  /// In en, this message translates to:
  /// **'Download eQuran on F-Droid: {url}'**
  String downloadEquranShareText(String url);

  /// No description provided for @unableOpenShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the share sheet.'**
  String get unableOpenShareSheet;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutThisApp;

  /// No description provided for @appDetailsAndVersion.
  ///
  /// In en, this message translates to:
  /// **'App details and version'**
  String get appDetailsAndVersion;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get shareApp;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send eQuran to others'**
  String get shareAppSubtitle;

  /// No description provided for @feedbackContact.
  ///
  /// In en, this message translates to:
  /// **'Feedback / Contact'**
  String get feedbackContact;

  /// No description provided for @feedbackContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report issues or email support'**
  String get feedbackContactSubtitle;

  /// No description provided for @reportIssues.
  ///
  /// In en, this message translates to:
  /// **'Report issues'**
  String get reportIssues;

  /// No description provided for @reportIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the GitHub issue tracker.'**
  String get reportIssuesSubtitle;

  /// No description provided for @unableOpenIssueTracker.
  ///
  /// In en, this message translates to:
  /// **'Unable to open issue tracker.'**
  String get unableOpenIssueTracker;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get emailSupport;

  /// No description provided for @unableOpenEmailClient.
  ///
  /// In en, this message translates to:
  /// **'Unable to open email client.'**
  String get unableOpenEmailClient;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your feedback and suggestions.'**
  String get feedbackThanks;

  /// No description provided for @browseBySurah.
  ///
  /// In en, this message translates to:
  /// **'Browse by Surah'**
  String get browseBySurah;

  /// No description provided for @browseByJuz.
  ///
  /// In en, this message translates to:
  /// **'Browse by Juz'**
  String get browseByJuz;

  /// No description provided for @browseByPage.
  ///
  /// In en, this message translates to:
  /// **'Browse by page'**
  String get browseByPage;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @noSurahsFound.
  ///
  /// In en, this message translates to:
  /// **'No surahs found.'**
  String get noSurahsFound;

  /// No description provided for @ayahRange.
  ///
  /// In en, this message translates to:
  /// **'Ayah {start}-{end}'**
  String ayahRange(int start, int end);

  /// No description provided for @juzNumber.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzNumber(int number);

  /// No description provided for @prayerNameFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerNameFajr;

  /// No description provided for @prayerNameSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerNameSunrise;

  /// No description provided for @prayerNameDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerNameDhuhr;

  /// No description provided for @prayerNameAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerNameAsr;

  /// No description provided for @prayerNameMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerNameMaghrib;

  /// No description provided for @prayerNameIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerNameIsha;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @middleOfNight.
  ///
  /// In en, this message translates to:
  /// **'Middle of night'**
  String get middleOfNight;

  /// No description provided for @lastThirdStarts.
  ///
  /// In en, this message translates to:
  /// **'Last third starts'**
  String get lastThirdStarts;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// No description provided for @enterCoordinatesManually.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get enterCoordinatesManually;

  /// No description provided for @locationUseNotice.
  ///
  /// In en, this message translates to:
  /// **'Your location is only used for prayer time calculation.'**
  String get locationUseNotice;

  /// No description provided for @timesCalculatedLocally.
  ///
  /// In en, this message translates to:
  /// **'Times are calculated locally on your device.'**
  String get timesCalculatedLocally;

  /// No description provided for @prayerTimesNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Prayer times need a location'**
  String get prayerTimesNeedLocation;

  /// No description provided for @prayerTimesLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate Fajr, Dhuhr, Asr, Maghrib and Isha for your exact location.'**
  String get prayerTimesLocationSubtitle;

  /// No description provided for @setUpLocation.
  ///
  /// In en, this message translates to:
  /// **'Set up location'**
  String get setUpLocation;

  /// No description provided for @chooseLocationForNextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Choose a location to show the next prayer time here.'**
  String get chooseLocationForNextPrayer;

  /// No description provided for @prayerTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Time'**
  String prayerTimeTitle(String prayer);

  /// No description provided for @prayerBeginsIn.
  ///
  /// In en, this message translates to:
  /// **'{prayer} begins in {countdown}'**
  String prayerBeginsIn(String prayer, String countdown);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @hoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String hoursMinutesShort(int hours, int minutes);

  /// No description provided for @exactAlarmPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission is off. Prayer reminders may be delayed.'**
  String get exactAlarmPermissionOff;

  /// No description provided for @zawal.
  ///
  /// In en, this message translates to:
  /// **'Zawal'**
  String get zawal;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @prohibitedTimeEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Prohibited time ends in {countdown}'**
  String prohibitedTimeEndsIn(String countdown);

  /// No description provided for @selectPrayerDate.
  ///
  /// In en, this message translates to:
  /// **'Select prayer date'**
  String get selectPrayerDate;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettings;

  /// No description provided for @unableGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to get location.'**
  String get unableGetLocation;

  /// No description provided for @qiblaBearingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current location coordinates are unavailable.'**
  String get qiblaBearingUnavailable;

  /// No description provided for @currentLocationTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Current location timed out. Check location services and try again.'**
  String get currentLocationTimedOut;

  /// No description provided for @compassUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Compass unavailable. Use the bearing shown.'**
  String get compassUnavailable;

  /// No description provided for @qiblaCalibrationHint.
  ///
  /// In en, this message translates to:
  /// **'For best accuracy, hold your phone flat and move it in a figure-8 to calibrate.'**
  String get qiblaCalibrationHint;

  /// No description provided for @compassAccuracyLow.
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy may be low.'**
  String get compassAccuracyLow;

  /// No description provided for @compassAccuracyLowWithDegrees.
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy may be low ({degrees}°).'**
  String compassAccuracyLowWithDegrees(int degrees);

  /// No description provided for @qiblaLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use Qibla.'**
  String get qiblaLocationServicesDisabled;

  /// No description provided for @qiblaLocationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to calculate Qibla from your current device location.'**
  String get qiblaLocationPermissionNeeded;

  /// No description provided for @qiblaLocationPermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Enable it from app settings to use Qibla.'**
  String get qiblaLocationPermissionBlocked;

  /// No description provided for @qiblaLocationUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not read your current location. Check location services and try again.'**
  String get qiblaLocationUnavailableMessage;

  /// No description provided for @bearingDegrees.
  ///
  /// In en, this message translates to:
  /// **'Bearing {degrees}°'**
  String bearingDegrees(String degrees);

  /// No description provided for @targetDegrees.
  ///
  /// In en, this message translates to:
  /// **'Target {degrees}°'**
  String targetDegrees(String degrees);

  /// No description provided for @headingDegrees.
  ///
  /// In en, this message translates to:
  /// **'Heading {degrees}°'**
  String headingDegrees(String degrees);

  /// No description provided for @heading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get heading;

  /// No description provided for @facingQibla.
  ///
  /// In en, this message translates to:
  /// **'Facing Qibla'**
  String get facingQibla;

  /// No description provided for @turnRightDegrees.
  ///
  /// In en, this message translates to:
  /// **'Turn right {degrees}°'**
  String turnRightDegrees(int degrees);

  /// No description provided for @turnLeftDegrees.
  ///
  /// In en, this message translates to:
  /// **'Turn left {degrees}°'**
  String turnLeftDegrees(int degrees);

  /// No description provided for @refreshCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh current location'**
  String get refreshCurrentLocation;

  /// No description provided for @findingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location'**
  String get findingYourLocation;

  /// No description provided for @currentLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Current location required'**
  String get currentLocationRequired;

  /// No description provided for @qiblaRequiresLocation.
  ///
  /// In en, this message translates to:
  /// **'Qibla requires live current location from this device. Enable location services and permission to continue.'**
  String get qiblaRequiresLocation;

  /// No description provided for @findingLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding location'**
  String get findingLocation;

  /// No description provided for @currentLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current location unavailable'**
  String get currentLocationUnavailable;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @distanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable'**
  String get distanceUnavailable;

  /// No description provided for @kilometersToKaaba.
  ///
  /// In en, this message translates to:
  /// **'{distance} km to Kaaba'**
  String kilometersToKaaba(String distance);

  /// No description provided for @resetCounter.
  ///
  /// In en, this message translates to:
  /// **'Reset counter'**
  String get resetCounter;

  /// No description provided for @recentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get recentSessions;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @countSomeDhikrFirst.
  ///
  /// In en, this message translates to:
  /// **'Count some dhikr first'**
  String get countSomeDhikrFirst;

  /// No description provided for @dhikrSessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Dhikr session saved'**
  String get dhikrSessionSaved;

  /// No description provided for @postPrayerDhikr.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer dhikr'**
  String get postPrayerDhikr;

  /// No description provided for @postPrayerDhikrComplete.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer dhikr complete'**
  String get postPrayerDhikrComplete;

  /// No description provided for @dhikrComplete.
  ///
  /// In en, this message translates to:
  /// **'{label} complete'**
  String dhikrComplete(String label);

  /// No description provided for @todayMetric.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayMetric;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @savedDhikrSessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Saved dhikr sessions will appear here.'**
  String get savedDhikrSessionsEmpty;

  /// No description provided for @dhikrSessionCounted.
  ///
  /// In en, this message translates to:
  /// **'{count} of {target} counted • {time}'**
  String dhikrSessionCounted(int count, int target, String time);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used only for prayer time calculations'**
  String get locationSubtitle;

  /// No description provided for @useCurrentLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Save this device\'s location for prayer calculations.'**
  String get useCurrentLocationDescription;

  /// No description provided for @moveMapUnderPin.
  ///
  /// In en, this message translates to:
  /// **'Move the map under a centered pin.'**
  String get moveMapUnderPin;

  /// No description provided for @enterLatitudeAndLongitude.
  ///
  /// In en, this message translates to:
  /// **'Enter latitude and longitude.'**
  String get enterLatitudeAndLongitude;

  /// No description provided for @clearSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Clear saved location'**
  String get clearSavedLocation;

  /// No description provided for @clearSavedLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times will pause until you choose again.'**
  String get clearSavedLocationSubtitle;

  /// No description provided for @calculation.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get calculation;

  /// No description provided for @calculationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Method, Asr, high latitude, and time format'**
  String get calculationSubtitle;

  /// No description provided for @calculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get calculationMethod;

  /// No description provided for @asrMethod.
  ///
  /// In en, this message translates to:
  /// **'Asr method'**
  String get asrMethod;

  /// No description provided for @highLatitudeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'High latitude adjustment'**
  String get highLatitudeAdjustment;

  /// No description provided for @highLatitudeAdjustmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used when Fajr or Isha are difficult to calculate in far northern or southern locations.'**
  String get highLatitudeAdjustmentSubtitle;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get timeFormat;

  /// No description provided for @useLocationTimezone.
  ///
  /// In en, this message translates to:
  /// **'Use location timezone'**
  String get useLocationTimezone;

  /// No description provided for @locationTimezoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the timezone of the saved location instead of this device\'s timezone.'**
  String get locationTimezoneSubtitle;

  /// No description provided for @customMethod.
  ///
  /// In en, this message translates to:
  /// **'Custom Method'**
  String get customMethod;

  /// No description provided for @fajrAngle.
  ///
  /// In en, this message translates to:
  /// **'Fajr angle'**
  String get fajrAngle;

  /// No description provided for @ishaMode.
  ///
  /// In en, this message translates to:
  /// **'Isha mode'**
  String get ishaMode;

  /// No description provided for @maghribAngle.
  ///
  /// In en, this message translates to:
  /// **'Maghrib angle'**
  String get maghribAngle;

  /// No description provided for @leaveBlankToUseSunset.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use sunset.'**
  String get leaveBlankToUseSunset;

  /// No description provided for @fixedIshaTime.
  ///
  /// In en, this message translates to:
  /// **'Fixed Isha time'**
  String get fixedIshaTime;

  /// No description provided for @latestIshaTime.
  ///
  /// In en, this message translates to:
  /// **'Latest Isha time'**
  String get latestIshaTime;

  /// No description provided for @baseIshaAngle.
  ///
  /// In en, this message translates to:
  /// **'Base Isha angle'**
  String get baseIshaAngle;

  /// No description provided for @baseIshaInterval.
  ///
  /// In en, this message translates to:
  /// **'Base Isha interval'**
  String get baseIshaInterval;

  /// No description provided for @ishaAngle.
  ///
  /// In en, this message translates to:
  /// **'Isha angle'**
  String get ishaAngle;

  /// No description provided for @ishaInterval.
  ///
  /// In en, this message translates to:
  /// **'Isha interval'**
  String get ishaInterval;

  /// No description provided for @leaveBlankToUseBaseIshaAngle.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use the base Isha angle.'**
  String get leaveBlankToUseBaseIshaAngle;

  /// No description provided for @useIshaAngle.
  ///
  /// In en, this message translates to:
  /// **'Use Isha angle'**
  String get useIshaAngle;

  /// No description provided for @minutesAfterMaghrib.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes after Maghrib'**
  String minutesAfterMaghrib(int minutes);

  /// No description provided for @prohibitedTimes.
  ///
  /// In en, this message translates to:
  /// **'Prohibited Times'**
  String get prohibitedTimes;

  /// No description provided for @prohibitedTimesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sunrise, Zawal and Sunset windows'**
  String get prohibitedTimesSubtitle;

  /// No description provided for @sunriseProhibitedTime.
  ///
  /// In en, this message translates to:
  /// **'Sunrise prohibited time'**
  String get sunriseProhibitedTime;

  /// No description provided for @sunriseProhibitedTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes after Sunrise'**
  String sunriseProhibitedTimeMinutes(int minutes);

  /// No description provided for @zawalProhibitedTime.
  ///
  /// In en, this message translates to:
  /// **'Zawal prohibited time'**
  String get zawalProhibitedTime;

  /// No description provided for @zawalProhibitedTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before Dhuhr'**
  String zawalProhibitedTimeMinutes(int minutes);

  /// No description provided for @sunsetProhibitedTime.
  ///
  /// In en, this message translates to:
  /// **'Sunset prohibited time'**
  String get sunsetProhibitedTime;

  /// No description provided for @sunsetProhibitedTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before Maghrib'**
  String sunsetProhibitedTimeMinutes(int minutes);

  /// No description provided for @prayerReminders.
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminders'**
  String get prayerReminders;

  /// No description provided for @prayerRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications before each prayer'**
  String get prayerRemindersSubtitle;

  /// No description provided for @prayerRemindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders'**
  String get prayerRemindersEnabled;

  /// No description provided for @prayerRemindersEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified before each prayer time.'**
  String get prayerRemindersEnabledSubtitle;

  /// No description provided for @notificationsPermission.
  ///
  /// In en, this message translates to:
  /// **'Notifications permission'**
  String get notificationsPermission;

  /// No description provided for @exactAlarmPermission.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm / alarms & reminders permission'**
  String get exactAlarmPermission;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @notificationPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is off.'**
  String get notificationPermissionOff;

  /// No description provided for @exactAlarmPermissionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission is disabled. Prayer reminders may be delayed.'**
  String get exactAlarmPermissionDisabled;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get requestPermission;

  /// No description provided for @openAlarmPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Open alarm permission settings'**
  String get openAlarmPermissionSettings;

  /// No description provided for @chooseLocationBeforeReminders.
  ///
  /// In en, this message translates to:
  /// **'Choose a location before reminders can be scheduled.'**
  String get chooseLocationBeforeReminders;

  /// No description provided for @notifyAtSavedPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'Notify at the saved prayer time.'**
  String get notifyAtSavedPrayerTime;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @atPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'At prayer time'**
  String get atPrayerTime;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String minutesBefore(int minutes);

  /// No description provided for @schedule1MinuteExactTest.
  ///
  /// In en, this message translates to:
  /// **'Schedule 1-minute exact test'**
  String get schedule1MinuteExactTest;

  /// No description provided for @schedule1MinuteExactTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the prayer reminder scheduler.'**
  String get schedule1MinuteExactTestSubtitle;

  /// No description provided for @offsetsAreAppliedAfterBaseCalculation.
  ///
  /// In en, this message translates to:
  /// **'Offsets are applied after the base calculation. Use positive or negative minutes only when you need to match a trusted local timetable.'**
  String get offsetsAreAppliedAfterBaseCalculation;

  /// No description provided for @manualOffsets.
  ///
  /// In en, this message translates to:
  /// **'Manual Offsets'**
  String get manualOffsets;

  /// No description provided for @manualOffsetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fine tune calculated times'**
  String get manualOffsetsSubtitle;

  /// No description provided for @noManualAdjustment.
  ///
  /// In en, this message translates to:
  /// **'No manual adjustment'**
  String get noManualAdjustment;

  /// No description provided for @positiveOrNegativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{value} minutes'**
  String positiveOrNegativeMinutes(int value);

  /// No description provided for @prayerTimesExperimental.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are currently experimental and may differ from local mosque or official timetables. Please verify before relying on them.'**
  String get prayerTimesExperimental;

  /// No description provided for @bestMethodAfterLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Best method after location is saved'**
  String get bestMethodAfterLocationSaved;

  /// No description provided for @minutesBeforePrayer.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before prayer'**
  String minutesBeforePrayer(int minutes);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @enablePrayerTracking.
  ///
  /// In en, this message translates to:
  /// **'Enable prayer tracking'**
  String get enablePrayerTracking;

  /// No description provided for @trackYourDailyPrayers.
  ///
  /// In en, this message translates to:
  /// **'Track your daily prayers'**
  String get trackYourDailyPrayers;

  /// No description provided for @trackYourDailyPrayersDescription.
  ///
  /// In en, this message translates to:
  /// **'Log each prayer privately on your device. Your data never leaves your phone.'**
  String get trackYourDailyPrayersDescription;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @logEachPrayerPrivately.
  ///
  /// In en, this message translates to:
  /// **'Log each prayer privately on your device. Your data never leaves your phone.'**
  String get logEachPrayerPrivately;

  /// No description provided for @enablePrayerTrackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable prayer tracking →'**
  String get enablePrayerTrackingLabel;

  /// No description provided for @somePrayersNotYetAvailable.
  ///
  /// In en, this message translates to:
  /// **'Some prayers were not yet available and were not saved.'**
  String get somePrayersNotYetAvailable;

  /// No description provided for @prayerLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Prayer log saved'**
  String get prayerLogSaved;

  /// No description provided for @addNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get addNewFolder;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get moveToFolder;

  /// No description provided for @editTags.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get editTags;

  /// No description provided for @savedAyah.
  ///
  /// In en, this message translates to:
  /// **'Saved ayah'**
  String get savedAyah;

  /// No description provided for @removeSavedAyah.
  ///
  /// In en, this message translates to:
  /// **'Remove saved ayah?'**
  String get removeSavedAyah;

  /// No description provided for @removeSavedAyahBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the ayah from your saved library.'**
  String get removeSavedAyahBody;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @personalLibrary.
  ///
  /// In en, this message translates to:
  /// **'Personal Library'**
  String get personalLibrary;

  /// No description provided for @savedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String savedCount(int count);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @manageFolders.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageFolders;

  /// No description provided for @surahLabel.
  ///
  /// In en, this message translates to:
  /// **'{surahName} • Ayah {ayah}'**
  String surahLabel(String surahName, Object ayah);

  /// No description provided for @showTafsir.
  ///
  /// In en, this message translates to:
  /// **'Show tafsir'**
  String get showTafsir;

  /// No description provided for @saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to library'**
  String get saveToLibrary;

  /// No description provided for @folderTagsAndNote.
  ///
  /// In en, this message translates to:
  /// **'Folder, tags, and private note'**
  String get folderTagsAndNote;

  /// No description provided for @ayahDetails.
  ///
  /// In en, this message translates to:
  /// **'Ayah details'**
  String get ayahDetails;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @translationOption.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationOption;

  /// No description provided for @showAyahTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show ayah translation'**
  String get showAyahTranslation;

  /// No description provided for @transliterationOption.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get transliterationOption;

  /// No description provided for @showAyahTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Show ayah transliteration'**
  String get showAyahTransliteration;

  /// No description provided for @cardViewOption.
  ///
  /// In en, this message translates to:
  /// **'Card View'**
  String get cardViewOption;

  /// No description provided for @readOneAyahPerCard.
  ///
  /// In en, this message translates to:
  /// **'Read one ayah per card'**
  String get readOneAyahPerCard;

  /// No description provided for @chooseAnAction.
  ///
  /// In en, this message translates to:
  /// **'Choose an action'**
  String get chooseAnAction;

  /// No description provided for @playThisAyah.
  ///
  /// In en, this message translates to:
  /// **'Play this ayah'**
  String get playThisAyah;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get shareImage;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @noMatchingCategories.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get noMatchingCategories;

  /// No description provided for @trySearchingArabicWord.
  ///
  /// In en, this message translates to:
  /// **'Try searching with another Arabic word or phrase.'**
  String get trySearchingArabicWord;

  /// No description provided for @duasUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Duas unavailable'**
  String get duasUnavailable;

  /// No description provided for @hisnAlMuslimNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Hisn al Muslim could not be loaded from the offline asset.'**
  String get hisnAlMuslimNotLoaded;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @noDuasFound.
  ///
  /// In en, this message translates to:
  /// **'No duas found'**
  String get noDuasFound;

  /// No description provided for @offlineHisnAlMuslimEmpty.
  ///
  /// In en, this message translates to:
  /// **'The offline Hisn al Muslim file did not contain any duas.'**
  String get offlineHisnAlMuslimEmpty;

  /// No description provided for @hisnAlMuslim.
  ///
  /// In en, this message translates to:
  /// **'Hisn al Muslim'**
  String get hisnAlMuslim;

  /// No description provided for @arabicCategoriesDuasOffline.
  ///
  /// In en, this message translates to:
  /// **'{categoryCount} Arabic categories - {duaCount} duas offline'**
  String arabicCategoriesDuasOffline(int categoryCount, int duaCount);

  /// No description provided for @favouriteDuas.
  ///
  /// In en, this message translates to:
  /// **'Favourite duas'**
  String get favouriteDuas;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @removeFavourite.
  ///
  /// In en, this message translates to:
  /// **'Remove favourite'**
  String get removeFavourite;

  /// No description provided for @saveDuasHere.
  ///
  /// In en, this message translates to:
  /// **'Save duas here for quick access'**
  String get saveDuasHere;

  /// No description provided for @savedDuasCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved {label}'**
  String savedDuasCount(int count, String label);

  /// No description provided for @tasbihAndDhikr.
  ///
  /// In en, this message translates to:
  /// **'Tasbih and dhikr'**
  String get tasbihAndDhikr;

  /// No description provided for @calmCounterDailyPresets.
  ///
  /// In en, this message translates to:
  /// **'A calm counter with daily presets'**
  String get calmCounterDailyPresets;

  /// No description provided for @duaCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {label}'**
  String duaCount(int count, Object label);

  /// No description provided for @favouriteDuasPage.
  ///
  /// In en, this message translates to:
  /// **'Favourite duas'**
  String get favouriteDuasPage;

  /// No description provided for @favouritesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Favourites unavailable'**
  String get favouritesUnavailable;

  /// No description provided for @savedDuasNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Saved duas could not be loaded right now.'**
  String get savedDuasNotLoaded;

  /// No description provided for @noFavouriteDuasYet.
  ///
  /// In en, this message translates to:
  /// **'No favourite duas yet.'**
  String get noFavouriteDuasYet;

  /// No description provided for @tapHeartToSave.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any dua card to save it here.'**
  String get tapHeartToSave;

  /// No description provided for @categoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Category unavailable'**
  String get categoryUnavailable;

  /// No description provided for @categoryNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'This Hisn al Muslim category could not be loaded.'**
  String get categoryNotLoaded;

  /// No description provided for @categoryNoDuas.
  ///
  /// In en, this message translates to:
  /// **'No duas found'**
  String get categoryNoDuas;

  /// No description provided for @categoryDoesNotContainDuas.
  ///
  /// In en, this message translates to:
  /// **'This category does not contain any duas.'**
  String get categoryDoesNotContainDuas;

  /// No description provided for @downloadTimings.
  ///
  /// In en, this message translates to:
  /// **'Download timings?'**
  String get downloadTimings;

  /// No description provided for @reciterNeedsTimings.
  ///
  /// In en, this message translates to:
  /// **'This reciter needs audio timings before synced ayah text can be shown. {size}'**
  String reciterNeedsTimings(String size);

  /// No description provided for @timingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Timings unavailable for this reciter.'**
  String get timingsUnavailable;

  /// No description provided for @timingsUnavailableSurah.
  ///
  /// In en, this message translates to:
  /// **'Timings unavailable for this surah.'**
  String get timingsUnavailableSurah;

  /// No description provided for @unableToInstallTimings.
  ///
  /// In en, this message translates to:
  /// **'Unable to install timings.'**
  String get unableToInstallTimings;

  /// No description provided for @installedLabel.
  ///
  /// In en, this message translates to:
  /// **'Installed {name}.'**
  String installedLabel(String name);

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @noTafsirSourcesSelected.
  ///
  /// In en, this message translates to:
  /// **'No Tafsir sources selected'**
  String get noTafsirSourcesSelected;

  /// No description provided for @chooseTafsirSourcesFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more Tafsir sources first.'**
  String get chooseTafsirSourcesFirst;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @deleteDownloadedMp3.
  ///
  /// In en, this message translates to:
  /// **'Delete downloaded MP3'**
  String get deleteDownloadedMp3;

  /// No description provided for @deleteDownloadedAyah.
  ///
  /// In en, this message translates to:
  /// **'Delete Downloaded Ayah?'**
  String get deleteDownloadedAyah;

  /// No description provided for @downloadAllAyahs.
  ///
  /// In en, this message translates to:
  /// **'Download All Ayahs?'**
  String get downloadAllAyahs;

  /// No description provided for @downloadAllAyahsConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will download audio for all {count} ayahs in this surah ({size}).'**
  String downloadAllAyahsConfirm(int count, String size);

  /// No description provided for @surahOption.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surahOption;

  /// No description provided for @reciterOption.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciterOption;

  /// No description provided for @sleepTimerOption.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerOption;

  /// No description provided for @shuffleOption.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleOption;

  /// No description provided for @shuffleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Randomize after surah ends'**
  String get shuffleSubtitle;

  /// No description provided for @loopCurrentSurah.
  ///
  /// In en, this message translates to:
  /// **'Loop current surah'**
  String get loopCurrentSurah;

  /// No description provided for @loopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat the current surah'**
  String get loopSubtitle;

  /// No description provided for @downloadTimingsResource.
  ///
  /// In en, this message translates to:
  /// **'Download timings'**
  String get downloadTimingsResource;

  /// No description provided for @timingsNeedToBeDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This reciter needs audio timings before synced ayah text can be shown. {size}'**
  String timingsNeedToBeDownloaded(String size);

  /// No description provided for @intervalOption.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get intervalOption;

  /// No description provided for @intervalRepeatOption.
  ///
  /// In en, this message translates to:
  /// **'Interval repeat'**
  String get intervalRepeatOption;

  /// No description provided for @repeatEachAyahOption.
  ///
  /// In en, this message translates to:
  /// **'Repeat each ayah'**
  String get repeatEachAyahOption;

  /// No description provided for @resetPlaybackOptions.
  ///
  /// In en, this message translates to:
  /// **'Reset playback options'**
  String get resetPlaybackOptions;

  /// No description provided for @surahOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surahOptionLabel;

  /// No description provided for @searchCategoriesDua.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategoriesDua;

  /// No description provided for @savedAyahLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved Ayah'**
  String get savedAyahLibrary;

  /// No description provided for @autoAdvancesToNextPreset.
  ///
  /// In en, this message translates to:
  /// **'Auto-advances to {nextPreset}'**
  String autoAdvancesToNextPreset(String nextPreset);

  /// No description provided for @counts33To33To34.
  ///
  /// In en, this message translates to:
  /// **'{target} counts • 33 → 33 → 34'**
  String counts33To33To34(int target);

  /// No description provided for @assalamuAlaikum.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaikum'**
  String get assalamuAlaikum;

  /// No description provided for @continueYourJourneyToday.
  ///
  /// In en, this message translates to:
  /// **'Continue your journey today'**
  String get continueYourJourneyToday;

  /// No description provided for @onStreakDay.
  ///
  /// In en, this message translates to:
  /// **'You\'re on a {streak}-day streak — keep going'**
  String onStreakDay(int streak);

  /// No description provided for @todaysWorship.
  ///
  /// In en, this message translates to:
  /// **'Today\'s worship'**
  String get todaysWorship;

  /// No description provided for @ayahsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get ayahsLabel;

  /// No description provided for @dhikrLabel.
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get dhikrLabel;

  /// No description provided for @duasLabel.
  ///
  /// In en, this message translates to:
  /// **'Duas'**
  String get duasLabel;

  /// No description provided for @salahLabel.
  ///
  /// In en, this message translates to:
  /// **'Salah'**
  String get salahLabel;

  /// No description provided for @dayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get dayStreakLabel;

  /// No description provided for @dailyQuranGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'DAILY QURAN GOAL'**
  String get dailyQuranGoalLabel;

  /// No description provided for @salah.
  ///
  /// In en, this message translates to:
  /// **'Salah'**
  String get salah;

  /// No description provided for @quranLabel.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranLabel;

  /// No description provided for @tasbihLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihLabel;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activityHistory;

  /// No description provided for @streaksLabel.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaksLabel;

  /// No description provided for @weekRange.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekRange;

  /// No description provided for @monthRange.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthRange;

  /// No description provided for @yearRange.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearRange;

  /// No description provided for @allTimeRange.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTimeRange;

  /// No description provided for @noPrayerYet.
  ///
  /// In en, this message translates to:
  /// **'No prayer yet'**
  String get noPrayerYet;

  /// No description provided for @noDayYet.
  ///
  /// In en, this message translates to:
  /// **'No day yet'**
  String get noDayYet;

  /// No description provided for @noSurahYet.
  ///
  /// In en, this message translates to:
  /// **'No surah yet'**
  String get noSurahYet;

  /// No description provided for @noDhikrYet.
  ///
  /// In en, this message translates to:
  /// **'No dhikr yet'**
  String get noDhikrYet;

  /// No description provided for @noCategoryYet.
  ///
  /// In en, this message translates to:
  /// **'No category yet'**
  String get noCategoryYet;

  /// No description provided for @dhikrLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get dhikrLabelSimple;

  /// No description provided for @readingOptions.
  ///
  /// In en, this message translates to:
  /// **'Reading options'**
  String get readingOptions;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @goToAyah.
  ///
  /// In en, this message translates to:
  /// **'Go to ayah'**
  String get goToAyah;

  /// No description provided for @jumpToAyahIn.
  ///
  /// In en, this message translates to:
  /// **'Jump to ayah in {surahName}'**
  String jumpToAyahIn(String surahName);

  /// No description provided for @displayAndSharing.
  ///
  /// In en, this message translates to:
  /// **'Display and sharing'**
  String get displayAndSharing;

  /// No description provided for @showLatinTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Show Latin transliteration'**
  String get showLatinTransliteration;

  /// No description provided for @chooseTranslationShownOnCards.
  ///
  /// In en, this message translates to:
  /// **'Choose the translation shown on cards'**
  String get chooseTranslationShownOnCards;

  /// No description provided for @chooseDownloadedExplanations.
  ///
  /// In en, this message translates to:
  /// **'Choose downloaded explanations'**
  String get chooseDownloadedExplanations;

  /// No description provided for @shareCurrentAyah.
  ///
  /// In en, this message translates to:
  /// **'Share current ayah'**
  String get shareCurrentAyah;

  /// No description provided for @createImageForThisAyah.
  ///
  /// In en, this message translates to:
  /// **'Create an image for this ayah'**
  String get createImageForThisAyah;

  /// No description provided for @tafsirSources.
  ///
  /// In en, this message translates to:
  /// **'Tafsir Sources'**
  String get tafsirSources;

  /// No description provided for @setPrayerLocation.
  ///
  /// In en, this message translates to:
  /// **'Set prayer location'**
  String get setPrayerLocation;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String ayahLabel(int number);

  /// No description provided for @versesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String versesCount(int count);

  /// No description provided for @surahVerseCount.
  ///
  /// In en, this message translates to:
  /// **'{surahName} • {count} verses'**
  String surahVerseCount(String surahName, int count);

  /// No description provided for @noJuzResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No juz results found.'**
  String get noJuzResultsFound;

  /// No description provided for @surahCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 surah} other{{count} surahs}}'**
  String surahCount(num count);

  /// No description provided for @surahRange.
  ///
  /// In en, this message translates to:
  /// **'{startSurah} {startVerse} - {endSurah} {endVerse}'**
  String surahRange(
    Object endSurah,
    Object endVerse,
    Object startSurah,
    Object startVerse,
  );

  /// No description provided for @recentQuranTextSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Quran text searches'**
  String get recentQuranTextSearches;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String searchResultCount(num count);

  /// No description provided for @searchQuranText.
  ///
  /// In en, this message translates to:
  /// **'Search Quran text'**
  String get searchQuranText;

  /// No description provided for @searchQuranTextEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Use this tab for Arabic words or translation text. Surah search stays in the Surahs tab.'**
  String get searchQuranTextEmptyMessage;

  /// No description provided for @noQuranTextResults.
  ///
  /// In en, this message translates to:
  /// **'No Quran text results'**
  String get noQuranTextResults;

  /// No description provided for @noAyahSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No ayahs matched \"{query}\". Try another Arabic word or phrase.'**
  String noAyahSearchResults(Object query);

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note...'**
  String get optionalNote;

  /// No description provided for @ayahOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Ayah {current} of {total}'**
  String ayahOfTotal(Object current, Object total);

  /// No description provided for @noMatchingSavedAyahs.
  ///
  /// In en, this message translates to:
  /// **'No matching saved ayahs.'**
  String get noMatchingSavedAyahs;

  /// No description provided for @saveAyahsNotesHere.
  ///
  /// In en, this message translates to:
  /// **'Save ayahs, notes, and reflections here.'**
  String get saveAyahsNotesHere;

  /// No description provided for @savedAyahLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Favourite ayahs quickly, or add folders, tags, and private notes from the reading options.'**
  String get savedAyahLibraryHint;

  /// No description provided for @privateNote.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get privateNote;

  /// No description provided for @writeReflectionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reflection...'**
  String get writeReflectionHint;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get createFolder;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'gratitude, duas'**
  String get tagsHint;

  /// No description provided for @unsorted.
  ///
  /// In en, this message translates to:
  /// **'Unsorted'**
  String get unsorted;

  /// No description provided for @removeSavedAyahDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the note, tags, folder, and favourite state for this ayah.'**
  String get removeSavedAyahDetailsBody;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Reflections'**
  String get folderNameHint;

  /// No description provided for @libraryFolders.
  ///
  /// In en, this message translates to:
  /// **'Library folders'**
  String get libraryFolders;

  /// No description provided for @defaultSavedAyahDestination.
  ///
  /// In en, this message translates to:
  /// **'Default destination for saved ayahs'**
  String get defaultSavedAyahDestination;

  /// No description provided for @savedAyahCollection.
  ///
  /// In en, this message translates to:
  /// **'Saved ayah collection'**
  String get savedAyahCollection;

  /// No description provided for @renameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get renameFolder;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteFolderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {folder}?'**
  String deleteFolderQuestion(Object folder);

  /// No description provided for @deleteFolderBody.
  ///
  /// In en, this message translates to:
  /// **'Saved ayahs in this folder will be moved to Unsorted.'**
  String get deleteFolderBody;

  /// No description provided for @quranRecitation.
  ///
  /// In en, this message translates to:
  /// **'Quran Player'**
  String get quranRecitation;

  /// No description provided for @openPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open Player'**
  String get openPlayer;

  /// No description provided for @resumeRecitation.
  ///
  /// In en, this message translates to:
  /// **'Resume recitation{progress}'**
  String resumeRecitation(Object progress);

  /// No description provided for @ayahsToday.
  ///
  /// In en, this message translates to:
  /// **'ayahs today'**
  String get ayahsToday;

  /// No description provided for @lettersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} letters'**
  String lettersCount(Object count);

  /// No description provided for @dayStreakCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String dayStreakCount(num count);

  /// No description provided for @ayahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String ayahsCount(num count);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(num count);

  /// No description provided for @todaysPortionComplete.
  ///
  /// In en, this message translates to:
  /// **'Today\'s portion complete'**
  String get todaysPortionComplete;

  /// No description provided for @catchUpAyahsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes {count} catch-up ayahs'**
  String catchUpAyahsIncluded(Object count);

  /// No description provided for @ayahsRemainingToday.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs remaining today'**
  String ayahsRemainingToday(Object count);

  /// No description provided for @todaysPortion.
  ///
  /// In en, this message translates to:
  /// **'Today\'s portion: {count} ayahs'**
  String todaysPortion(Object count);

  /// No description provided for @surahIntroMeta.
  ///
  /// In en, this message translates to:
  /// **'{revelation} · {verseCount} VERSES · JUZ\' {juz}'**
  String surahIntroMeta(Object juz, Object revelation, Object verseCount);

  /// No description provided for @makkah.
  ///
  /// In en, this message translates to:
  /// **'MAKKAH'**
  String get makkah;

  /// No description provided for @madinah.
  ///
  /// In en, this message translates to:
  /// **'MADINAH'**
  String get madinah;

  /// No description provided for @currentAyahOnly.
  ///
  /// In en, this message translates to:
  /// **'Current ayah only'**
  String get currentAyahOnly;

  /// No description provided for @surahAyahRange.
  ///
  /// In en, this message translates to:
  /// **'{surahName} {startAyah} → {endAyah}'**
  String surahAyahRange(Object endAyah, Object startAyah, Object surahName);

  /// No description provided for @intervalEndBeforeStartError.
  ///
  /// In en, this message translates to:
  /// **'Choose an end ayah that is the same as or after the start ayah.'**
  String get intervalEndBeforeStartError;

  /// No description provided for @intervalRange.
  ///
  /// In en, this message translates to:
  /// **'Interval range'**
  String get intervalRange;

  /// No description provided for @intervalRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Select a start and end ayah. Ranges can cross surahs.'**
  String get intervalRangeHint;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @customizeRecitationBehavior.
  ///
  /// In en, this message translates to:
  /// **'Customize recitation behavior'**
  String get customizeRecitationBehavior;

  /// No description provided for @recitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get recitation;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @ayahDelay.
  ///
  /// In en, this message translates to:
  /// **'Ayah delay'**
  String get ayahDelay;

  /// No description provided for @audioDownloads.
  ///
  /// In en, this message translates to:
  /// **'Audio downloads'**
  String get audioDownloads;

  /// No description provided for @surahAudioDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Surah audio downloaded'**
  String get surahAudioDownloaded;

  /// No description provided for @allAyahsAvailableOffline.
  ///
  /// In en, this message translates to:
  /// **'All ayahs are available offline'**
  String get allAyahsAvailableOffline;

  /// No description provided for @downloadEveryAyahInSurah.
  ///
  /// In en, this message translates to:
  /// **'Download every ayah in this surah'**
  String get downloadEveryAyahInSurah;

  /// No description provided for @downloadingCurrentAyah.
  ///
  /// In en, this message translates to:
  /// **'Downloading current ayah'**
  String get downloadingCurrentAyah;

  /// No description provided for @deleteCurrentAyahAudio.
  ///
  /// In en, this message translates to:
  /// **'Delete current ayah audio'**
  String get deleteCurrentAyahAudio;

  /// No description provided for @downloadCurrentAyah.
  ///
  /// In en, this message translates to:
  /// **'Download current ayah'**
  String get downloadCurrentAyah;

  /// No description provided for @intervalPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'{position} {kind}'**
  String intervalPickerTitle(Object kind, Object position);

  /// No description provided for @noDelay.
  ///
  /// In en, this message translates to:
  /// **'No delay'**
  String get noDelay;

  /// No description provided for @secondsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String secondsCount(num count);

  /// No description provided for @tafsirNeedsDownload.
  ///
  /// In en, this message translates to:
  /// **'This Tafsir needs to be downloaded first. {size}'**
  String tafsirNeedsDownload(Object size);

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @noTafsirTextForAyah.
  ///
  /// In en, this message translates to:
  /// **'No tafsir text available for this ayah.'**
  String get noTafsirTextForAyah;

  /// No description provided for @noTafsirResourcesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Tafsir resources available'**
  String get noTafsirResourcesAvailable;

  /// No description provided for @enterAyahRange.
  ///
  /// In en, this message translates to:
  /// **'Enter an ayah number from 1 to {total}'**
  String enterAyahRange(Object total);

  /// No description provided for @ayahNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Ayah number'**
  String get ayahNumberHint;

  /// No description provided for @downloadingSurahAyahs.
  ///
  /// In en, this message translates to:
  /// **'Downloading {surahName} ayahs'**
  String downloadingSurahAyahs(Object surahName);

  /// No description provided for @downloadedSurahAyahs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {surahName} ayahs'**
  String downloadedSurahAyahs(Object surahName);

  /// No description provided for @downloadedAllAyahsFor.
  ///
  /// In en, this message translates to:
  /// **'Downloaded all ayahs for {surahName}'**
  String downloadedAllAyahsFor(Object surahName);

  /// No description provided for @failedDownloadSurahAyahs.
  ///
  /// In en, this message translates to:
  /// **'Failed to download {surahName} ayahs.'**
  String failedDownloadSurahAyahs(Object surahName);

  /// No description provided for @downloadAllAyahsForSurah.
  ///
  /// In en, this message translates to:
  /// **'Download all ayah audio for {surahName} for offline listening?'**
  String downloadAllAyahsForSurah(Object surahName);

  /// No description provided for @removedFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites.'**
  String get removedFromFavourites;

  /// No description provided for @savedAyahsOrganizedHint.
  ///
  /// In en, this message translates to:
  /// **'Saved ayahs can be organized into folders and tags.'**
  String get savedAyahsOrganizedHint;

  /// No description provided for @playerOptions.
  ///
  /// In en, this message translates to:
  /// **'Player options'**
  String get playerOptions;

  /// No description provided for @chooseSurah.
  ///
  /// In en, this message translates to:
  /// **'Choose Surah'**
  String get chooseSurah;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @downloadMp3.
  ///
  /// In en, this message translates to:
  /// **'Download MP3'**
  String get downloadMp3;

  /// No description provided for @availableOffline.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get availableOffline;

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get notSaved;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @sleepTimerOptions.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer options'**
  String get sleepTimerOptions;

  /// No description provided for @endOfSurah.
  ///
  /// In en, this message translates to:
  /// **'End of surah'**
  String get endOfSurah;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @sleepingSoon.
  ///
  /// In en, this message translates to:
  /// **'sleeping soon'**
  String get sleepingSoon;

  /// No description provided for @sleepingInMinutes.
  ///
  /// In en, this message translates to:
  /// **'sleeping in {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String sleepingInMinutes(num minutes);

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} pending'**
  String pendingLabel(Object label);

  /// No description provided for @loadingSyncedAyah.
  ///
  /// In en, this message translates to:
  /// **'Loading synced ayah'**
  String get loadingSyncedAyah;

  /// No description provided for @syncedAyahUnavailableReciter.
  ///
  /// In en, this message translates to:
  /// **'Synced ayah display is unavailable for this reciter'**
  String get syncedAyahUnavailableReciter;

  /// No description provided for @syncedAyahUnavailableSurah.
  ///
  /// In en, this message translates to:
  /// **'Synced ayah display is unavailable for this surah'**
  String get syncedAyahUnavailableSurah;

  /// No description provided for @downloadTimingsToSyncAyahs.
  ///
  /// In en, this message translates to:
  /// **'Download timings to sync ayahs for this reciter'**
  String get downloadTimingsToSyncAyahs;

  /// No description provided for @unableToPlaySurahAudio.
  ///
  /// In en, this message translates to:
  /// **'Unable to play surah audio.'**
  String get unableToPlaySurahAudio;

  /// No description provided for @downloadingName.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String downloadingName(Object name);

  /// No description provided for @downloadedName.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {name}'**
  String downloadedName(Object name);

  /// No description provided for @failedDownloadName.
  ///
  /// In en, this message translates to:
  /// **'Failed to download {name}'**
  String failedDownloadName(Object name);

  /// No description provided for @failedDownloadSurahAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to download surah audio.'**
  String get failedDownloadSurahAudio;

  /// No description provided for @deletedMp3Name.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name} MP3'**
  String deletedMp3Name(Object name);

  /// No description provided for @failedDeleteDownloadedSurah.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete downloaded surah.'**
  String get failedDeleteDownloadedSurah;

  /// No description provided for @deleteDownloadedMp3Question.
  ///
  /// In en, this message translates to:
  /// **'Delete Downloaded MP3?'**
  String get deleteDownloadedMp3Question;

  /// No description provided for @removeSurahFromOffline.
  ///
  /// In en, this message translates to:
  /// **'This will remove {name} from offline storage.'**
  String removeSurahFromOffline(Object name);

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline ready'**
  String get offlineReady;

  /// No description provided for @streaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get streaming;

  /// No description provided for @showAyahText.
  ///
  /// In en, this message translates to:
  /// **'Show ayah text'**
  String get showAyahText;

  /// No description provided for @hideAyahText.
  ///
  /// In en, this message translates to:
  /// **'Hide ayah text'**
  String get hideAyahText;

  /// No description provided for @themeSchemeEmeraldGreen.
  ///
  /// In en, this message translates to:
  /// **'Emerald Green'**
  String get themeSchemeEmeraldGreen;

  /// No description provided for @themeSchemeEmeraldGreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The original calm eQuran palette.'**
  String get themeSchemeEmeraldGreenSubtitle;

  /// No description provided for @themeSchemeSapphireBlue.
  ///
  /// In en, this message translates to:
  /// **'Sapphire Blue'**
  String get themeSchemeSapphireBlue;

  /// No description provided for @themeSchemeSapphireBlueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deep navy with sapphire and muted cyan accents.'**
  String get themeSchemeSapphireBlueSubtitle;

  /// No description provided for @themeSchemeRoyalPurple.
  ///
  /// In en, this message translates to:
  /// **'Royal Purple'**
  String get themeSchemeRoyalPurple;

  /// No description provided for @themeSchemeRoyalPurpleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Midnight purple with royal violet highlights.'**
  String get themeSchemeRoyalPurpleSubtitle;

  /// No description provided for @themeSchemeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSchemeSepia;

  /// No description provided for @themeSchemeSepiaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warm parchment, brown, and soft gold tones.'**
  String get themeSchemeSepiaSubtitle;

  /// No description provided for @themeSchemeBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get themeSchemeBlack;

  /// No description provided for @themeSchemeBlackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black with restrained teal accents.'**
  String get themeSchemeBlackSubtitle;

  /// No description provided for @themeSchemeRubyRed.
  ///
  /// In en, this message translates to:
  /// **'Ruby Red'**
  String get themeSchemeRubyRed;

  /// No description provided for @themeSchemeRubyRedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deep maroon surfaces with elegant ruby highlights.'**
  String get themeSchemeRubyRedSubtitle;

  /// No description provided for @enterLatitudeLongitude.
  ///
  /// In en, this message translates to:
  /// **'Enter latitude and longitude.'**
  String get enterLatitudeLongitude;

  /// No description provided for @chooseLocationBeforeCalculating.
  ///
  /// In en, this message translates to:
  /// **'Choose a location before calculating'**
  String get chooseLocationBeforeCalculating;

  /// No description provided for @usingDeviceTimezone.
  ///
  /// In en, this message translates to:
  /// **'Using this device timezone.'**
  String get usingDeviceTimezone;

  /// No description provided for @usingDeviceTimezoneUntilLocationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Using device timezone until the location timezone is available.'**
  String get usingDeviceTimezoneUntilLocationAvailable;

  /// No description provided for @displayPrayerTimesUsingTimezone.
  ///
  /// In en, this message translates to:
  /// **'Display prayer times using {timezone}.'**
  String displayPrayerTimesUsingTimezone(Object timezone);

  /// No description provided for @remindersOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders off'**
  String get remindersOff;

  /// No description provided for @remindersOnWaitingLocation.
  ///
  /// In en, this message translates to:
  /// **'On, waiting for location'**
  String get remindersOnWaitingLocation;

  /// No description provided for @allPrayerRemindersOn.
  ///
  /// In en, this message translates to:
  /// **'All prayer reminders on'**
  String get allPrayerRemindersOn;

  /// No description provided for @remindersEnabledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reminders enabled'**
  String remindersEnabledCount(Object count);

  /// No description provided for @checkingNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Checking notification permission...'**
  String get checkingNotificationPermission;

  /// No description provided for @permissionStatusNeedsRetry.
  ///
  /// In en, this message translates to:
  /// **'Permission status needs a retry.'**
  String get permissionStatusNeedsRetry;

  /// No description provided for @localNotificationsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Local notifications are scheduled on this device.'**
  String get localNotificationsScheduled;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Notification permission granted.'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionOffEnable.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is off. Enable it to receive prayer reminders.'**
  String get notificationPermissionOffEnable;

  /// No description provided for @prayerRemindersUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders are not supported on this platform.'**
  String get prayerRemindersUnsupported;

  /// No description provided for @checkingExactAlarmPermission.
  ///
  /// In en, this message translates to:
  /// **'Checking exact alarm permission...'**
  String get checkingExactAlarmPermission;

  /// No description provided for @exactAlarmStatusNeedsRetry.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm status needs a retry.'**
  String get exactAlarmStatusNeedsRetry;

  /// No description provided for @alarmPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Alarms & reminders permission granted.'**
  String get alarmPermissionGranted;

  /// No description provided for @exactAlarmPermissionNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission is not required on this platform.'**
  String get exactAlarmPermissionNotRequired;

  /// No description provided for @hisnCategoryCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'This Hisn al Muslim category could not be loaded.'**
  String get hisnCategoryCouldNotLoad;

  /// No description provided for @categoryContainsNoDuas.
  ///
  /// In en, this message translates to:
  /// **'This category does not contain any duas.'**
  String get categoryContainsNoDuas;

  /// No description provided for @couldNotUpdateDua.
  ///
  /// In en, this message translates to:
  /// **'Could not update dua favourite.'**
  String get couldNotUpdateDua;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @duaCopied.
  ///
  /// In en, this message translates to:
  /// **'Dua copied.'**
  String get duaCopied;

  /// No description provided for @hisnAlMuslimDua.
  ///
  /// In en, this message translates to:
  /// **'Hisn al Muslim dua'**
  String get hisnAlMuslimDua;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Share text'**
  String get shareText;

  /// No description provided for @prayerStats.
  ///
  /// In en, this message translates to:
  /// **'Prayer Stats'**
  String get prayerStats;

  /// No description provided for @quranStats.
  ///
  /// In en, this message translates to:
  /// **'Quran Stats'**
  String get quranStats;

  /// No description provided for @tasbihStats.
  ///
  /// In en, this message translates to:
  /// **'Tasbih Stats'**
  String get tasbihStats;

  /// No description provided for @duaStats.
  ///
  /// In en, this message translates to:
  /// **'Dua Stats'**
  String get duaStats;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get onTime;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @onTimeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'On time this week'**
  String get onTimeThisWeek;

  /// No description provided for @lateThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Late this week'**
  String get lateThisWeek;

  /// No description provided for @bestPrayer.
  ///
  /// In en, this message translates to:
  /// **'Best prayer'**
  String get bestPrayer;

  /// No description provided for @currentFajrStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Fajr streak'**
  String get currentFajrStreak;

  /// No description provided for @startLoggingFajr.
  ///
  /// In en, this message translates to:
  /// **'Start logging Fajr to track your progress.'**
  String get startLoggingFajr;

  /// No description provided for @fajrVeryConsistent.
  ///
  /// In en, this message translates to:
  /// **'Mashallah, your Fajr is very consistent.'**
  String get fajrVeryConsistent;

  /// No description provided for @fajrGettingStronger.
  ///
  /// In en, this message translates to:
  /// **'Good effort, Fajr is getting stronger.'**
  String get fajrGettingStronger;

  /// No description provided for @fajrEveryAttemptCounts.
  ///
  /// In en, this message translates to:
  /// **'Fajr is a challenge, every attempt counts.'**
  String get fajrEveryAttemptCounts;

  /// No description provided for @fajrConsistency.
  ///
  /// In en, this message translates to:
  /// **'Fajr consistency'**
  String get fajrConsistency;

  /// No description provided for @todaysPrayers.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Prayers'**
  String get todaysPrayers;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @availableAfter.
  ///
  /// In en, this message translates to:
  /// **'Available after {time}'**
  String availableAfter(Object time);

  /// No description provided for @quranActivity.
  ///
  /// In en, this message translates to:
  /// **'Quran activity'**
  String get quranActivity;

  /// No description provided for @ayahsRead.
  ///
  /// In en, this message translates to:
  /// **'Ayahs Read'**
  String get ayahsRead;

  /// No description provided for @lettersRead.
  ///
  /// In en, this message translates to:
  /// **'Letters Read'**
  String get lettersRead;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get activeDays;

  /// No description provided for @mostActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Most active day'**
  String get mostActiveDay;

  /// No description provided for @ayahsReadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs read'**
  String ayahsReadCount(Object count);

  /// No description provided for @recitationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recitations'**
  String recitationsCount(Object count);

  /// No description provided for @surahProgress.
  ///
  /// In en, this message translates to:
  /// **'Surah Progress'**
  String get surahProgress;

  /// No description provided for @surahsComplete.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} Surahs complete'**
  String surahsComplete(Object completed, Object total);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showAllSurahs.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} surahs'**
  String showAllSurahs(Object count);

  /// No description provided for @quranCompletions.
  ///
  /// In en, this message translates to:
  /// **'Quran Completions'**
  String get quranCompletions;

  /// No description provided for @fullCompletions.
  ///
  /// In en, this message translates to:
  /// **'Full completions'**
  String get fullCompletions;

  /// No description provided for @completeAllSurahsForFirstKhatm.
  ///
  /// In en, this message translates to:
  /// **'Complete all {count} Surahs to record your first Khatm'**
  String completeAllSurahsForFirstKhatm(Object count);

  /// No description provided for @khatmDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Khatm {number} · {date}'**
  String khatmDateLabel(Object date, Object number);

  /// No description provided for @startFirstTasbihSession.
  ///
  /// In en, this message translates to:
  /// **'Start your first Tasbih session'**
  String get startFirstTasbihSession;

  /// No description provided for @totalDhikr.
  ///
  /// In en, this message translates to:
  /// **'Total dhikr'**
  String get totalDhikr;

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily average'**
  String get dailyAverage;

  /// No description provided for @openDuaToBeginHistory.
  ///
  /// In en, this message translates to:
  /// **'Open a dua to begin your Duas history'**
  String get openDuaToBeginHistory;

  /// No description provided for @duasViewed.
  ///
  /// In en, this message translates to:
  /// **'Duas viewed'**
  String get duasViewed;

  /// No description provided for @viewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String viewsCount(Object count);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @activeDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active day} other{{count} active days}}'**
  String activeDaysCount(num count);

  /// No description provided for @monthlyActivitySummary.
  ///
  /// In en, this message translates to:
  /// **'{activeDays} · Best day: {bestDay} · {totalActions} total actions'**
  String monthlyActivitySummary(
    Object activeDays,
    Object bestDay,
    Object totalActions,
  );

  /// No description provided for @dhikrCount.
  ///
  /// In en, this message translates to:
  /// **'{count} dhikr'**
  String dhikrCount(Object count);

  /// No description provided for @duasCount.
  ///
  /// In en, this message translates to:
  /// **'{count} duas'**
  String duasCount(Object count);

  /// No description provided for @quranStreak.
  ///
  /// In en, this message translates to:
  /// **'Quran streak'**
  String get quranStreak;

  /// No description provided for @tasbihStreak.
  ///
  /// In en, this message translates to:
  /// **'Tasbih streak'**
  String get tasbihStreak;

  /// No description provided for @overallStreak.
  ///
  /// In en, this message translates to:
  /// **'Overall streak'**
  String get overallStreak;

  /// No description provided for @dayWorshipStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day worship streak'**
  String dayWorshipStreak(Object count);

  /// No description provided for @weekShortLabel.
  ///
  /// In en, this message translates to:
  /// **'W{week}'**
  String weekShortLabel(Object week);

  /// No description provided for @youReadMostOn.
  ///
  /// In en, this message translates to:
  /// **'You read most on {day}'**
  String youReadMostOn(Object day);

  /// No description provided for @startReadingToUnlockInsights.
  ///
  /// In en, this message translates to:
  /// **'Start reading to unlock insights'**
  String get startReadingToUnlockInsights;

  /// No description provided for @readingUpFromLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Reading up {percent}% from last week'**
  String readingUpFromLastWeek(Object percent);

  /// No description provided for @readingDownFromLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Reading down {percent}% from last week'**
  String readingDownFromLastWeek(Object percent);

  /// No description provided for @youVisitSurahMostOften.
  ///
  /// In en, this message translates to:
  /// **'You visit {surahName} most often'**
  String youVisitSurahMostOften(Object surahName);

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @mondayInitial.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get mondayInitial;

  /// No description provided for @tuesdayInitial.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tuesdayInitial;

  /// No description provided for @wednesdayInitial.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wednesdayInitial;

  /// No description provided for @thursdayInitial.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get thursdayInitial;

  /// No description provided for @fridayInitial.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get fridayInitial;

  /// No description provided for @saturdayInitial.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get saturdayInitial;

  /// No description provided for @sundayInitial.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sundayInitial;

  /// No description provided for @mondays.
  ///
  /// In en, this message translates to:
  /// **'Mondays'**
  String get mondays;

  /// No description provided for @tuesdays.
  ///
  /// In en, this message translates to:
  /// **'Tuesdays'**
  String get tuesdays;

  /// No description provided for @wednesdays.
  ///
  /// In en, this message translates to:
  /// **'Wednesdays'**
  String get wednesdays;

  /// No description provided for @thursdays.
  ///
  /// In en, this message translates to:
  /// **'Thursdays'**
  String get thursdays;

  /// No description provided for @fridays.
  ///
  /// In en, this message translates to:
  /// **'Fridays'**
  String get fridays;

  /// No description provided for @saturdays.
  ///
  /// In en, this message translates to:
  /// **'Saturdays'**
  String get saturdays;

  /// No description provided for @sundays.
  ///
  /// In en, this message translates to:
  /// **'Sundays'**
  String get sundays;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @januaryShort.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get januaryShort;

  /// No description provided for @februaryShort.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get februaryShort;

  /// No description provided for @marchShort.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get marchShort;

  /// No description provided for @aprilShort.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get aprilShort;

  /// No description provided for @mayShort.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayShort;

  /// No description provided for @juneShort.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get juneShort;

  /// No description provided for @julyShort.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get julyShort;

  /// No description provided for @augustShort.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get augustShort;

  /// No description provided for @septemberShort.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get septemberShort;

  /// No description provided for @octoberShort.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get octoberShort;

  /// No description provided for @novemberShort.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get novemberShort;

  /// No description provided for @decemberShort.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get decemberShort;

  /// No description provided for @dailyQuoteSmallDeeds.
  ///
  /// In en, this message translates to:
  /// **'Small deeds, sincerely done, grow beautifully.'**
  String get dailyQuoteSmallDeeds;

  /// No description provided for @dailyQuoteBeginAgain.
  ///
  /// In en, this message translates to:
  /// **'Begin again with remembrance and gratitude.'**
  String get dailyQuoteBeginAgain;

  /// No description provided for @dailyQuoteSteadyHeart.
  ///
  /// In en, this message translates to:
  /// **'A steady heart returns to Allah each day.'**
  String get dailyQuoteSteadyHeart;

  /// No description provided for @dailyQuoteGentleConsistent.
  ///
  /// In en, this message translates to:
  /// **'Let today\'s worship be gentle and consistent.'**
  String get dailyQuoteGentleConsistent;

  /// No description provided for @dailyQuoteEveryAyah.
  ///
  /// In en, this message translates to:
  /// **'Every ayah read is light for the journey.'**
  String get dailyQuoteEveryAyah;

  /// No description provided for @dailyWorshipComplete.
  ///
  /// In en, this message translates to:
  /// **'Mashallah! Daily worship complete'**
  String get dailyWorshipComplete;

  /// No description provided for @greatProgressKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Great progress, keep going'**
  String get greatProgressKeepGoing;

  /// No description provided for @everyDeedCountsKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Every deed counts, keep going'**
  String get everyDeedCountsKeepGoing;

  /// No description provided for @startYourWorshipForToday.
  ///
  /// In en, this message translates to:
  /// **'Start your worship for today'**
  String get startYourWorshipForToday;

  /// No description provided for @totalRead.
  ///
  /// In en, this message translates to:
  /// **'Total read'**
  String get totalRead;

  /// No description provided for @estimatedLettersRead.
  ///
  /// In en, this message translates to:
  /// **'Estimated letters read'**
  String get estimatedLettersRead;

  /// No description provided for @rewardIsWithAllah.
  ///
  /// In en, this message translates to:
  /// **'Reward is with Allah.'**
  String get rewardIsWithAllah;

  /// No description provided for @totalZakahWealth.
  ///
  /// In en, this message translates to:
  /// **'Total wealth must be at least 200 to calculate Zakah.'**
  String get totalZakahWealth;

  /// No description provided for @hifzTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get hifzTitle;

  /// No description provided for @hifzJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Hifz Journey'**
  String get hifzJourneyTitle;

  /// No description provided for @hifzNewTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} new today'**
  String hifzNewTodayLabel(int count, int max);

  /// No description provided for @hifzMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get hifzMemorized;

  /// No description provided for @hifzDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get hifzDueToday;

  /// No description provided for @hifzInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get hifzInReview;

  /// No description provided for @hifzAyahsMemorized.
  ///
  /// In en, this message translates to:
  /// **'{count} / 6,236 ayahs memorized'**
  String hifzAyahsMemorized(int count);

  /// No description provided for @hifzDueForReview.
  ///
  /// In en, this message translates to:
  /// **'Due for Review'**
  String get hifzDueForReview;

  /// No description provided for @hifzAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up — no reviews due'**
  String get hifzAllCaughtUp;

  /// No description provided for @hifzAyahsReady.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs ready'**
  String hifzAyahsReady(int count);

  /// No description provided for @hifzStartYourSession.
  ///
  /// In en, this message translates to:
  /// **'Start your review session'**
  String get hifzStartYourSession;

  /// No description provided for @hifzStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get hifzStart;

  /// No description provided for @hifzDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get hifzDueNow;

  /// No description provided for @hifzOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue {days}d'**
  String hifzOverdueDays(int days);

  /// No description provided for @hifzShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} →'**
  String hifzShowAll(int count);

  /// No description provided for @hifzAddToMemorize.
  ///
  /// In en, this message translates to:
  /// **'Add to Memorize'**
  String get hifzAddToMemorize;

  /// No description provided for @hifzQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get hifzQuickAdd;

  /// No description provided for @hifzQuickAlFatiha.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatiha'**
  String get hifzQuickAlFatiha;

  /// No description provided for @hifzQuickAlKahf.
  ///
  /// In en, this message translates to:
  /// **'Al-Kahf'**
  String get hifzQuickAlKahf;

  /// No description provided for @hifzQuickJuzAmma.
  ///
  /// In en, this message translates to:
  /// **'Juz Amma'**
  String get hifzQuickJuzAmma;

  /// No description provided for @hifzQuickLast10.
  ///
  /// In en, this message translates to:
  /// **'Last 10 Surahs'**
  String get hifzQuickLast10;

  /// No description provided for @hifzOrChooseSurah.
  ///
  /// In en, this message translates to:
  /// **'Or choose a surah'**
  String get hifzOrChooseSurah;

  /// No description provided for @hifzFromAyah.
  ///
  /// In en, this message translates to:
  /// **'From ayah'**
  String get hifzFromAyah;

  /// No description provided for @hifzToAyah.
  ///
  /// In en, this message translates to:
  /// **'To ayah'**
  String get hifzToAyah;

  /// No description provided for @hifzAddAyahsButton.
  ///
  /// In en, this message translates to:
  /// **'Add {count} ayahs to Hifz'**
  String hifzAddAyahsButton(int count);

  /// No description provided for @hifzAyahsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs added'**
  String hifzAyahsAdded(int count);

  /// No description provided for @hifzSurahProgress.
  ///
  /// In en, this message translates to:
  /// **'Surah Progress'**
  String get hifzSurahProgress;

  /// No description provided for @hifzShowAllSurahs.
  ///
  /// In en, this message translates to:
  /// **'Show all 114 surahs'**
  String get hifzShowAllSurahs;

  /// No description provided for @hifzShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get hifzShowLess;

  /// No description provided for @hifzSurahsMastered.
  ///
  /// In en, this message translates to:
  /// **'{count} / 114 Surahs mastered'**
  String hifzSurahsMastered(int count);

  /// No description provided for @hifzSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz Settings'**
  String get hifzSettingsTitle;

  /// No description provided for @hifzTrackNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get hifzTrackNew;

  /// No description provided for @hifzTrackRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get hifzTrackRevision;

  /// No description provided for @hifzTrackMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get hifzTrackMaintenance;

  /// No description provided for @hifzSessionProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String hifzSessionProgress(int current, int total);

  /// No description provided for @hifzExitSession.
  ///
  /// In en, this message translates to:
  /// **'Exit session?'**
  String get hifzExitSession;

  /// No description provided for @hifzExitSessionBody.
  ///
  /// In en, this message translates to:
  /// **'You have reviewed {count} of {total} ayahs.\nProgress so far will be saved.'**
  String hifzExitSessionBody(int count, int total);

  /// No description provided for @hifzExitCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get hifzExitCancel;

  /// No description provided for @hifzExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get hifzExitConfirm;

  /// No description provided for @hifzImReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get hifzImReady;

  /// No description provided for @hifzRevealAll.
  ///
  /// In en, this message translates to:
  /// **'Reveal all'**
  String get hifzRevealAll;

  /// No description provided for @hifzToggleTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get hifzToggleTransliteration;

  /// No description provided for @hifzToggleTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get hifzToggleTranslation;

  /// No description provided for @hifzToggleListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get hifzToggleListen;

  /// No description provided for @hifzRatingAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get hifzRatingAgain;

  /// No description provided for @hifzRatingHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hifzRatingHard;

  /// No description provided for @hifzRatingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get hifzRatingGood;

  /// No description provided for @hifzRatingEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get hifzRatingEasy;

  /// No description provided for @hifzSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get hifzSessionComplete;

  /// No description provided for @hifzCompletedUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'Completed in under a minute'**
  String get hifzCompletedUnderMinute;

  /// No description provided for @hifzCompletedInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Completed in {minutes} minute{plural}'**
  String hifzCompletedInMinutes(int minutes, String plural);

  /// No description provided for @hifzSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get hifzSummaryTitle;

  /// No description provided for @hifzTotalReviewed.
  ///
  /// In en, this message translates to:
  /// **'Total reviewed'**
  String get hifzTotalReviewed;

  /// No description provided for @hifzTotalReviewedValue.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String hifzTotalReviewedValue(int count);

  /// No description provided for @hifzRetentionRate.
  ///
  /// In en, this message translates to:
  /// **'Retention rate'**
  String get hifzRetentionRate;

  /// No description provided for @hifzNextReviewDue.
  ///
  /// In en, this message translates to:
  /// **'Next review due'**
  String get hifzNextReviewDue;

  /// No description provided for @hifzNextReviewToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get hifzNextReviewToday;

  /// No description provided for @hifzNextReviewTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get hifzNextReviewTomorrow;

  /// No description provided for @hifzNextReviewInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String hifzNextReviewInDays(int days);

  /// No description provided for @hifzAllCaughtUpDue.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get hifzAllCaughtUpDue;

  /// No description provided for @hifzHadithQuote.
  ///
  /// In en, this message translates to:
  /// **'\"The best of you are those who learn the Quran and teach it.\" — Al-Bukhari'**
  String get hifzHadithQuote;

  /// No description provided for @hifzBackToHifz.
  ///
  /// In en, this message translates to:
  /// **'Back to Hifz'**
  String get hifzBackToHifz;

  /// No description provided for @hifzKeepReviewing.
  ///
  /// In en, this message translates to:
  /// **'Keep reviewing ({count} left)'**
  String hifzKeepReviewing(int count);

  /// No description provided for @hifzDueReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs due for Hifz review'**
  String hifzDueReminderTitle(int count);

  /// No description provided for @hifzSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Hifz Settings — coming soon'**
  String get hifzSettingsComingSoon;

  /// No description provided for @hifzStatsSection.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get hifzStatsSection;

  /// No description provided for @hifzStatsTotalMemorized.
  ///
  /// In en, this message translates to:
  /// **'Total memorized'**
  String get hifzStatsTotalMemorized;

  /// No description provided for @hifzStatsDailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily streak'**
  String get hifzStatsDailyStreak;

  /// No description provided for @hifzStatsRetentionRate.
  ///
  /// In en, this message translates to:
  /// **'Retention rate'**
  String get hifzStatsRetentionRate;

  /// No description provided for @hifzStatsTotalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total reviews'**
  String get hifzStatsTotalReviews;

  /// No description provided for @hifzStatsNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next review'**
  String get hifzStatsNextDue;

  /// No description provided for @hifzStatsNextDueValue.
  ///
  /// In en, this message translates to:
  /// **'{surah} · Ayah {ayah}'**
  String hifzStatsNextDueValue(String surah, int ayah);

  /// No description provided for @hifzStatsNextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String hifzStatsNextDueDate(String date);

  /// No description provided for @hifzStatsNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Start memorizing to see your Hifz stats'**
  String get hifzStatsNoEntries;

  /// No description provided for @hifzStatsSurahProgress.
  ///
  /// In en, this message translates to:
  /// **'Surah Progress'**
  String get hifzStatsSurahProgress;

  /// No description provided for @hifzStatsRetentionSuffix.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String hifzStatsRetentionSuffix(String value);

  /// No description provided for @hifzStatsPill.
  ///
  /// In en, this message translates to:
  /// **'{count} memorized'**
  String hifzStatsPill(int count);

  /// No description provided for @hifzReminderDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs due for Hifz review'**
  String hifzReminderDueCount(int count);

  /// No description provided for @hifzReminderReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get hifzReminderReview;

  /// No description provided for @hifzSettingsNewPerDay.
  ///
  /// In en, this message translates to:
  /// **'New ayahs per day'**
  String get hifzSettingsNewPerDay;

  /// No description provided for @hifzSettingsReviewsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Reviews per day'**
  String get hifzSettingsReviewsPerDay;

  /// No description provided for @hifzSettingsShowTranslit.
  ///
  /// In en, this message translates to:
  /// **'Show transliteration by default'**
  String get hifzSettingsShowTranslit;

  /// No description provided for @hifzSettingsShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation by default'**
  String get hifzSettingsShowTranslation;

  /// No description provided for @hifzSettingsAutoPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Auto-play audio on learn phase'**
  String get hifzSettingsAutoPlayAudio;

  /// No description provided for @hifzSettingsBlankingLevel.
  ///
  /// In en, this message translates to:
  /// **'Blanking level'**
  String get hifzSettingsBlankingLevel;

  /// No description provided for @hifzSettingsBlankingAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get hifzSettingsBlankingAuto;

  /// No description provided for @hifzSettingsBlankingEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get hifzSettingsBlankingEasy;

  /// No description provided for @hifzSettingsBlankingMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get hifzSettingsBlankingMedium;

  /// No description provided for @hifzSettingsBlankingHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hifzSettingsBlankingHard;

  /// No description provided for @hifzSettingsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get hifzSettingsDone;

  /// No description provided for @hifzActiveUnits.
  ///
  /// In en, this message translates to:
  /// **'Active units'**
  String get hifzActiveUnits;

  /// No description provided for @hifzInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get hifzInProgress;

  /// No description provided for @hifzActiveUnitsSection.
  ///
  /// In en, this message translates to:
  /// **'Active Units'**
  String get hifzActiveUnitsSection;

  /// No description provided for @hifzNoActiveUnits.
  ///
  /// In en, this message translates to:
  /// **'No active units — add one below'**
  String get hifzNoActiveUnits;

  /// No description provided for @hifzUnitTypeSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get hifzUnitTypeSurah;

  /// No description provided for @hifzUnitTypeJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get hifzUnitTypeJuz;

  /// No description provided for @hifzUnitNextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next: {surah} · Ayah {ayah}'**
  String hifzUnitNextAyah(String surah, int ayah);

  /// No description provided for @hifzUnitProgress.
  ///
  /// In en, this message translates to:
  /// **'{introduced}/{total}'**
  String hifzUnitProgress(int introduced, int total);

  /// No description provided for @hifzUnitReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get hifzUnitReview;

  /// No description provided for @hifzUnitUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get hifzUnitUpToDate;

  /// No description provided for @hifzDueNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String hifzDueNew(int count);

  /// No description provided for @hifzDueRevision.
  ///
  /// In en, this message translates to:
  /// **'{count} revision'**
  String hifzDueRevision(int count);

  /// No description provided for @hifzDueMaintenance.
  ///
  /// In en, this message translates to:
  /// **'{count} maintenance'**
  String hifzDueMaintenance(int count);

  /// No description provided for @hifzDueAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get hifzDueAllCaughtUp;

  /// No description provided for @hifzAddUnitSection.
  ///
  /// In en, this message translates to:
  /// **'Add a Unit'**
  String get hifzAddUnitSection;

  /// No description provided for @hifzSearchSurahs.
  ///
  /// In en, this message translates to:
  /// **'Search surahs...'**
  String get hifzSearchSurahs;

  /// No description provided for @hifzSearchJuz.
  ///
  /// In en, this message translates to:
  /// **'Search juz...'**
  String get hifzSearchJuz;

  /// No description provided for @hifzSelectAbove.
  ///
  /// In en, this message translates to:
  /// **'Select a unit above'**
  String get hifzSelectAbove;

  /// No description provided for @hifzStartMemorizingSurah.
  ///
  /// In en, this message translates to:
  /// **'Start memorizing {name}'**
  String hifzStartMemorizingSurah(String name);

  /// No description provided for @hifzStartMemorizingJuz.
  ///
  /// In en, this message translates to:
  /// **'Start memorizing Juz {number}'**
  String hifzStartMemorizingJuz(int number);

  /// No description provided for @hifzUnitAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'Already in progress'**
  String get hifzUnitAlreadyActive;

  /// No description provided for @hifzUnitAyahCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String hifzUnitAyahCount(int count);

  /// No description provided for @hifzSurahsMasteredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / 114 Surahs mastered'**
  String hifzSurahsMasteredCount(int count);

  /// No description provided for @hifzTrackNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get hifzTrackNewLabel;

  /// No description provided for @hifzTrackRevisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get hifzTrackRevisionLabel;

  /// No description provided for @hifzTrackMaintenanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get hifzTrackMaintenanceLabel;

  /// No description provided for @hifzListenPhaseButton.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get hifzListenPhaseButton;

  /// No description provided for @hifzRevealAllButton.
  ///
  /// In en, this message translates to:
  /// **'Reveal all'**
  String get hifzRevealAllButton;

  /// No description provided for @hifzAudioDisabledTooltip.
  ///
  /// In en, this message translates to:
  /// **'Audio disabled during recall'**
  String get hifzAudioDisabledTooltip;

  /// No description provided for @hifzPrevAyahCueLabel.
  ///
  /// In en, this message translates to:
  /// **'...previous ayah...'**
  String get hifzPrevAyahCueLabel;

  /// No description provided for @hifzRatingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hifzRatingTryAgain;

  /// No description provided for @hifzRatingGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get hifzRatingGotIt;

  /// No description provided for @hifzEmptySessionTitle.
  ///
  /// In en, this message translates to:
  /// **'All done for today!'**
  String get hifzEmptySessionTitle;

  /// No description provided for @hifzEmptySessionBody.
  ///
  /// In en, this message translates to:
  /// **'No new or due ayahs for {unit} today.'**
  String hifzEmptySessionBody(String unit);

  /// No description provided for @hifzEmptySessionButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Hifz'**
  String get hifzEmptySessionButton;

  /// No description provided for @hifzExitSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit session?'**
  String get hifzExitSessionTitle;

  /// No description provided for @hifzCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get hifzCompleteTitle;

  /// No description provided for @hifzCompleteSubtitleUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'Completed in under a minute'**
  String get hifzCompleteSubtitleUnderMinute;

  /// No description provided for @hifzCompleteSubtitleMinutes.
  ///
  /// In en, this message translates to:
  /// **'Completed in {minutes} minutes'**
  String hifzCompleteSubtitleMinutes(int minutes);

  /// No description provided for @hifzCompleteSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get hifzCompleteSummaryTitle;

  /// No description provided for @hifzCompleteTotalReviewed.
  ///
  /// In en, this message translates to:
  /// **'Total reviewed'**
  String get hifzCompleteTotalReviewed;

  /// No description provided for @hifzCompleteTotalReviewedValue.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String hifzCompleteTotalReviewedValue(int count);

  /// No description provided for @hifzCompleteRetentionRate.
  ///
  /// In en, this message translates to:
  /// **'Retention rate'**
  String get hifzCompleteRetentionRate;

  /// No description provided for @hifzCompleteNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next review due'**
  String get hifzCompleteNextDue;

  /// No description provided for @hifzCompleteNextDueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get hifzCompleteNextDueToday;

  /// No description provided for @hifzCompleteNextDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get hifzCompleteNextDueTomorrow;

  /// No description provided for @hifzCompleteNextDueInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String hifzCompleteNextDueInDays(int days);

  /// No description provided for @hifzCompleteAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get hifzCompleteAllCaughtUp;

  /// No description provided for @hifzCompleteGraduated.
  ///
  /// In en, this message translates to:
  /// **'Graduated to review'**
  String get hifzCompleteGraduated;

  /// No description provided for @hifzCompleteGraduatedValue.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String hifzCompleteGraduatedValue(int count);

  /// No description provided for @hifzCompleteHadith.
  ///
  /// In en, this message translates to:
  /// **'\"The best of you are those who learn the Quran and teach it.\" — Al-Bukhari'**
  String get hifzCompleteHadith;

  /// No description provided for @hifzCompleteBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Hifz'**
  String get hifzCompleteBackButton;

  /// No description provided for @hifzCompleteKeepReviewing.
  ///
  /// In en, this message translates to:
  /// **'Keep reviewing ({count} left)'**
  String hifzCompleteKeepReviewing(int count);

  /// No description provided for @hifzUnitCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You have introduced all ayahs in {unit}!'**
  String hifzUnitCompleteTitle(String unit);

  /// No description provided for @hifzUnitCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue revising to fully master them.'**
  String get hifzUnitCompleteSubtitle;

  /// No description provided for @hifzSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz Settings'**
  String get hifzSettingsSheetTitle;

  /// No description provided for @hifzMorePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get hifzMorePageTitle;

  /// No description provided for @hifzMorePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Memorize the Quran with smart review'**
  String get hifzMorePageSubtitle;

  /// No description provided for @hifzReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs due for Hifz review'**
  String hifzReminderTitle(int count);

  /// No description provided for @hifzReminderButton.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get hifzReminderButton;

  /// No description provided for @hifz.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get hifz;

  /// No description provided for @hifzSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Memorize the Quran with smart review'**
  String get hifzSubtitle;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @buildQuranRoutine.
  ///
  /// In en, this message translates to:
  /// **'Build a Quran routine'**
  String get buildQuranRoutine;

  /// No description provided for @chooseGentlePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a gentle plan and let today have a clear portion.'**
  String get chooseGentlePlan;

  /// No description provided for @routineCompletedAyahs.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} ayahs completed'**
  String routineCompletedAyahs(int completed, int total);

  /// No description provided for @plansReadyNotice.
  ///
  /// In en, this message translates to:
  /// **'7-day, 30-day, and 60-day plans are ready.'**
  String get plansReadyNotice;

  /// No description provided for @finishTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Finish target: {date}'**
  String finishTargetDate(String date);

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @ongoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoingLabel;

  /// No description provided for @skippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedLabel;

  /// No description provided for @noActiveRoutine.
  ///
  /// In en, this message translates to:
  /// **'No active routine'**
  String get noActiveRoutine;

  /// No description provided for @startBalancedPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Start with a balanced 30-day plan, or choose a faster or gentler routine below.'**
  String get startBalancedPlanDescription;

  /// No description provided for @start30DayPlan.
  ///
  /// In en, this message translates to:
  /// **'Start 30-day plan'**
  String get start30DayPlan;

  /// No description provided for @todayReading.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reading'**
  String get todayReading;

  /// No description provided for @todayCompleted.
  ///
  /// In en, this message translates to:
  /// **'Today completed'**
  String get todayCompleted;

  /// No description provided for @todaysPortionAyahs.
  ///
  /// In en, this message translates to:
  /// **'Today\'s portion: {count} ayahs'**
  String todaysPortionAyahs(int count);

  /// No description provided for @includesCatchUpAyahs.
  ///
  /// In en, this message translates to:
  /// **'Includes {count} catch-up ayahs'**
  String includesCatchUpAyahs(int count);

  /// No description provided for @ayahRangeConnector.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String ayahRangeConnector(String start, String end);

  /// No description provided for @dailyPercentCompleteRemaining.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete • {remaining} ayahs remaining today'**
  String dailyPercentCompleteRemaining(int percent, int remaining);

  /// No description provided for @routineHistory.
  ///
  /// In en, this message translates to:
  /// **'Routine history'**
  String get routineHistory;

  /// No description provided for @currentRoutine.
  ///
  /// In en, this message translates to:
  /// **'Current routine'**
  String get currentRoutine;

  /// No description provided for @noCurrentRoutine.
  ///
  /// In en, this message translates to:
  /// **'No current routine.'**
  String get noCurrentRoutine;

  /// No description provided for @pastRoutines.
  ///
  /// In en, this message translates to:
  /// **'Past routines'**
  String get pastRoutines;

  /// No description provided for @pastRoutine.
  ///
  /// In en, this message translates to:
  /// **'Past routine'**
  String get pastRoutine;

  /// No description provided for @deleteRoutineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete routine'**
  String get deleteRoutineTooltip;

  /// No description provided for @deleteCurrentRoutineQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete current routine?'**
  String get deleteCurrentRoutineQuestion;

  /// No description provided for @deleteRoutineQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete routine?'**
  String get deleteRoutineQuestion;

  /// No description provided for @deleteRoutineWarning.
  ///
  /// In en, this message translates to:
  /// **'This removes \"{title}\" from your routine history.'**
  String deleteRoutineWarning(String title);

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get choosePlan;

  /// No description provided for @preset7DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Quran in 7 days'**
  String get preset7DaysTitle;

  /// No description provided for @preset7DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A focused weekly routine'**
  String get preset7DaysSubtitle;

  /// No description provided for @preset30DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Quran in 30 days'**
  String get preset30DaysTitle;

  /// No description provided for @preset30DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced daily portions'**
  String get preset30DaysSubtitle;

  /// No description provided for @preset60DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Quran in 60 days'**
  String get preset60DaysTitle;

  /// No description provided for @preset60DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle long-form reading'**
  String get preset60DaysSubtitle;

  /// No description provided for @routineStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} started'**
  String routineStartedMessage(String title);

  /// No description provided for @prayerTimesDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated locally. Verify with your local mosque if needed.'**
  String get prayerTimesDisclaimer;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved.'**
  String get locationSaved;

  /// No description provided for @notificationPermissionOffWarning.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is off. Reminders were disabled.'**
  String get notificationPermissionOffWarning;

  /// No description provided for @exactAlarmPermissionOffWarning.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission is disabled. Prayer reminders may be delayed.'**
  String get exactAlarmPermissionOffWarning;

  /// No description provided for @locationDetails.
  ///
  /// In en, this message translates to:
  /// **'Location details'**
  String get locationDetails;

  /// No description provided for @updateCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Update current location'**
  String get updateCurrentLocation;

  /// No description provided for @useThisDeviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this device location'**
  String get useThisDeviceLocation;

  /// No description provided for @moveMapPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Move the map pin to a place'**
  String get moveMapPinDescription;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @advancedCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Advanced coordinates'**
  String get advancedCoordinates;

  /// No description provided for @advancedCoordinatesEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit only if you need precise coordinates'**
  String get advancedCoordinatesEditSubtitle;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location label'**
  String get locationLabel;

  /// No description provided for @locationLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Home, work, or city name'**
  String get locationLabelHint;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @latitudeHelperText.
  ///
  /// In en, this message translates to:
  /// **'Use a value between -90 and 90.'**
  String get latitudeHelperText;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @longitudeHelperText.
  ///
  /// In en, this message translates to:
  /// **'Use a value between -180 and 180.'**
  String get longitudeHelperText;

  /// No description provided for @savedLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Saved location'**
  String get savedLocationFallback;

  /// No description provided for @coordinatesPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Used locally for prayer-time calculation. Coordinates are stored on this device.{timezoneText}'**
  String coordinatesPrivacyDescription(String timezoneText);

  /// No description provided for @countdownNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get countdownNow;

  /// No description provided for @countdownVerySoon.
  ///
  /// In en, this message translates to:
  /// **'Very soon'**
  String get countdownVerySoon;

  /// No description provided for @countdownInHours.
  ///
  /// In en, this message translates to:
  /// **'In {hours}h'**
  String countdownInHours(int hours);

  /// No description provided for @countdownInHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {hours}h {minutes}m'**
  String countdownInHoursMinutes(int hours, int minutes);

  /// No description provided for @countdownInMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {minutes}m'**
  String countdownInMinutes(int minutes);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @routineComplete.
  ///
  /// In en, this message translates to:
  /// **'Routine complete'**
  String get routineComplete;

  /// No description provided for @routineDeleted.
  ///
  /// In en, this message translates to:
  /// **'Routine deleted'**
  String get routineDeleted;

  /// No description provided for @chooseLocationManually.
  ///
  /// In en, this message translates to:
  /// **'Choose location manually'**
  String get chooseLocationManually;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get saveLocation;

  /// No description provided for @coordinatesForPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Coordinates for prayer times'**
  String get coordinatesForPrayerTimes;

  /// No description provided for @manualLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the latitude and longitude for the city, area, or address you want to use.'**
  String get manualLocationDescription;

  /// No description provided for @manualLocationPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device and used only for local prayer-time calculation.'**
  String get manualLocationPrivacyNotice;

  /// No description provided for @manualLocation.
  ///
  /// In en, this message translates to:
  /// **'Manual location'**
  String get manualLocation;

  /// No description provided for @savedLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved location'**
  String get savedLocation;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @openStreetMapContributors.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get openStreetMapContributors;

  /// No description provided for @validationEnterField.
  ///
  /// In en, this message translates to:
  /// **'Enter {field}.'**
  String validationEnterField(String field);

  /// No description provided for @validationShouldBeNumber.
  ///
  /// In en, this message translates to:
  /// **'{field} should be a number.'**
  String validationShouldBeNumber(String field);

  /// No description provided for @validationMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'{field} must be between {min} and {max}.'**
  String validationMustBeBetween(String field, String min, String max);

  /// No description provided for @completedTodayQuota.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} ayahs today'**
  String completedTodayQuota(int completed, int total);

  /// No description provided for @completedAyahsRatio.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} ayahs'**
  String completedAyahsRatio(int completed, int total);

  /// No description provided for @the99BeautifulNamesOfAllah.
  ///
  /// In en, this message translates to:
  /// **'The 99 Beautiful Names of Allah'**
  String get the99BeautifulNamesOfAllah;

  /// No description provided for @allNamesCount.
  ///
  /// In en, this message translates to:
  /// **'All Names · {count}'**
  String allNamesCount(int count);

  /// No description provided for @reciteThisNameInDua.
  ///
  /// In en, this message translates to:
  /// **'Recite this name in your dua'**
  String get reciteThisNameInDua;

  /// No description provided for @searchNames.
  ///
  /// In en, this message translates to:
  /// **'Search names'**
  String get searchNames;

  /// No description provided for @searchNamesHint.
  ///
  /// In en, this message translates to:
  /// **'Search names...'**
  String get searchNamesHint;

  /// No description provided for @namesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Names unavailable'**
  String get namesUnavailable;

  /// No description provided for @unableLoadAsmaUlHusna.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Asma ul Husna right now.'**
  String get unableLoadAsmaUlHusna;

  /// No description provided for @noNamesFound.
  ///
  /// In en, this message translates to:
  /// **'No names found'**
  String get noNamesFound;

  /// No description provided for @tryAnotherAsmaSearch.
  ///
  /// In en, this message translates to:
  /// **'Try another Arabic name, transliteration, or meaning.'**
  String get tryAnotherAsmaSearch;

  /// No description provided for @duaGroupDailyAthkar.
  ///
  /// In en, this message translates to:
  /// **'Daily Athkar'**
  String get duaGroupDailyAthkar;

  /// No description provided for @duaGroupPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get duaGroupPrayer;

  /// No description provided for @duaGroupHajjUmrah.
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah'**
  String get duaGroupHajjUmrah;

  /// No description provided for @duaGroupTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get duaGroupTravel;

  /// No description provided for @duaGroupProtectionHardship.
  ///
  /// In en, this message translates to:
  /// **'Protection & Hardship'**
  String get duaGroupProtectionHardship;

  /// No description provided for @duaGroupHealthIllness.
  ///
  /// In en, this message translates to:
  /// **'Health & Illness'**
  String get duaGroupHealthIllness;

  /// No description provided for @duaGroupDeathFunerals.
  ///
  /// In en, this message translates to:
  /// **'Death & Funerals'**
  String get duaGroupDeathFunerals;

  /// No description provided for @duaGroupRepentance.
  ///
  /// In en, this message translates to:
  /// **'Repentance'**
  String get duaGroupRepentance;

  /// No description provided for @duaGroupNatureWeather.
  ///
  /// In en, this message translates to:
  /// **'Nature & Weather'**
  String get duaGroupNatureWeather;

  /// No description provided for @duaGroupMarriageFamily.
  ///
  /// In en, this message translates to:
  /// **'Marriage & Family'**
  String get duaGroupMarriageFamily;

  /// No description provided for @duaGroupRemembrancePraise.
  ///
  /// In en, this message translates to:
  /// **'Remembrance & Praise'**
  String get duaGroupRemembrancePraise;

  /// No description provided for @duaGroupSocialEtiquette.
  ///
  /// In en, this message translates to:
  /// **'Social Etiquette'**
  String get duaGroupSocialEtiquette;

  /// No description provided for @duaGroupMisc.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get duaGroupMisc;

  /// No description provided for @highLatitudeMosqueNotice.
  ///
  /// In en, this message translates to:
  /// **'Some high-latitude mosque timetables use fixed or capped Isha times during summer.'**
  String get highLatitudeMosqueNotice;

  /// No description provided for @latestIshaTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Use calculated Isha, but do not allow it later than {time}.'**
  String latestIshaTimeHelp(String time);

  /// No description provided for @zakatCalculator.
  ///
  /// In en, this message translates to:
  /// **'Zakat Calculator'**
  String get zakatCalculator;

  /// No description provided for @zakatCalculatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wealth & Nisab evaluations'**
  String get zakatCalculatorSubtitle;

  /// No description provided for @islamicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Islamic Calendar'**
  String get islamicCalendar;

  /// No description provided for @islamicCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronized Hijri timeline'**
  String get islamicCalendarSubtitle;

  /// No description provided for @customizeNavigation.
  ///
  /// In en, this message translates to:
  /// **'Customize Navigation'**
  String get customizeNavigation;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @meccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No description provided for @appearanceTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, light/dark mode, and color accent settings'**
  String get appearanceTileSubtitle;

  /// No description provided for @navigationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rearrange and swap bottom navigation tabs'**
  String get navigationSettingsSubtitle;

  /// No description provided for @downloadQpcFontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Download QPC V4 Tajweed fonts?'**
  String get downloadQpcFontsTitle;

  /// No description provided for @downloadQpcFontsBody.
  ///
  /// In en, this message translates to:
  /// **'Tajweed needs one TTF for each of the 604 Quran pages. Download the font package{size} before enabling it.'**
  String downloadQpcFontsBody(String size);

  /// No description provided for @locationCleared.
  ///
  /// In en, this message translates to:
  /// **'Location cleared.'**
  String get locationCleared;

  /// No description provided for @useSunset.
  ///
  /// In en, this message translates to:
  /// **'Use sunset'**
  String get useSunset;

  /// No description provided for @failedDownloadAyahAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to download ayah audio.'**
  String get failedDownloadAyahAudio;

  /// No description provided for @failedDeleteDownloadedAyah.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete downloaded ayah.'**
  String get failedDeleteDownloadedAyah;

  /// No description provided for @unablePlayAudioWeb.
  ///
  /// In en, this message translates to:
  /// **'Unable to play audio on web. Try downloading the app for better experience.'**
  String get unablePlayAudioWeb;

  /// No description provided for @failedPlayAudioConnection.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio. Please check your internet connection.'**
  String get failedPlayAudioConnection;

  /// No description provided for @failedToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio: {error}'**
  String failedToPlayAudio(String error);

  /// No description provided for @ishaModeAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get ishaModeAngle;

  /// No description provided for @ishaModeAngleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the custom Isha angle.'**
  String get ishaModeAngleSubtitle;

  /// No description provided for @ishaModeInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval after Maghrib'**
  String get ishaModeInterval;

  /// No description provided for @ishaModeIntervalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set Isha a fixed number of minutes after Maghrib.'**
  String get ishaModeIntervalSubtitle;

  /// No description provided for @ishaModeFixedTime.
  ///
  /// In en, this message translates to:
  /// **'Fixed time'**
  String get ishaModeFixedTime;

  /// No description provided for @ishaModeFixedTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the same clock time on each selected prayer date.'**
  String get ishaModeFixedTimeSubtitle;

  /// No description provided for @ishaModeLatestCap.
  ///
  /// In en, this message translates to:
  /// **'Latest time cap'**
  String get ishaModeLatestCap;

  /// No description provided for @ishaModeLatestCapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use calculated Isha unless it goes later than a cap.'**
  String get ishaModeLatestCapSubtitle;

  /// No description provided for @bestMethodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a method from the saved country when available.'**
  String get bestMethodSubtitle;

  /// No description provided for @highLatitudeRuleAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply a rule only for high-latitude locations.'**
  String get highLatitudeRuleAutoSubtitle;

  /// No description provided for @highLatitudeRuleNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Do not apply a high-latitude rule.'**
  String get highLatitudeRuleNoneSubtitle;

  /// No description provided for @highLatitudeRuleMiddleOfTheNightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cap Fajr and Isha using the middle of the night.'**
  String get highLatitudeRuleMiddleOfTheNightSubtitle;

  /// No description provided for @highLatitudeRuleOneSeventhSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use one seventh of the night.'**
  String get highLatitudeRuleOneSeventhSubtitle;

  /// No description provided for @highLatitudeRuleAngleBasedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the Fajr and Isha angles as the night fraction.'**
  String get highLatitudeRuleAngleBasedSubtitle;

  /// No description provided for @twelveHour.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get twelveHour;

  /// No description provided for @twentyFourHour.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get twentyFourHour;

  /// No description provided for @notificationPermissionOffRemindersNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is off. Prayer reminders were not enabled.'**
  String get notificationPermissionOffRemindersNotEnabled;

  /// No description provided for @notificationPermissionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Notification permission request timed out.'**
  String get notificationPermissionTimeout;

  /// No description provided for @notificationPermissionTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification permission request timed out. Try reopening the app or enabling notifications in system settings.'**
  String get notificationPermissionTimeoutMessage;

  /// No description provided for @notificationPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Could not request notification permission.'**
  String get notificationPermissionError;

  /// No description provided for @notificationPermissionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not request notification permission. Try again or enable notifications in system settings.'**
  String get notificationPermissionErrorMessage;

  /// No description provided for @openNotificationSettingsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Opening notification settings timed out. Open Android app settings manually and enable notifications.'**
  String get openNotificationSettingsTimeout;

  /// No description provided for @openNotificationSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open notification settings. Open Android app settings manually and enable notifications.'**
  String get openNotificationSettingsError;

  /// No description provided for @openExactAlarmSettingsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Opening alarm permission settings timed out. Open Android alarms & reminders settings manually and enable exact alarms.'**
  String get openExactAlarmSettingsTimeout;

  /// No description provided for @openExactAlarmSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open alarm permission settings. Open Android alarms & reminders settings manually and enable exact alarms.'**
  String get openExactAlarmSettingsError;

  /// No description provided for @debugReminderScheduled.
  ///
  /// In en, this message translates to:
  /// **'Debug prayer reminder scheduled for {time}.'**
  String debugReminderScheduled(String time);

  /// No description provided for @debugReminderCouldNotBeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Debug prayer reminder could not be scheduled.'**
  String get debugReminderCouldNotBeScheduled;

  /// No description provided for @degrees.
  ///
  /// In en, this message translates to:
  /// **'degrees'**
  String get degrees;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @prayerOffsetTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayerName} offset'**
  String prayerOffsetTitle(String prayerName);

  /// No description provided for @steppedIntOffsetHelper.
  ///
  /// In en, this message translates to:
  /// **'Type minutes as digits only. Use the sign button for before or after the calculated time.'**
  String get steppedIntOffsetHelper;

  /// No description provided for @enterValueBetweenMinMaxSuffix.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between {min} and {max} {suffix}.'**
  String enterValueBetweenMinMaxSuffix(String min, String max, String suffix);

  /// No description provided for @steppedIntSuffixHelper.
  ///
  /// In en, this message translates to:
  /// **'Type {suffix} as digits only. Use - and + to adjust the value.'**
  String steppedIntSuffixHelper(String suffix);

  /// No description provided for @optionalSteppedIntHelper.
  ///
  /// In en, this message translates to:
  /// **'{emptyLabel} Blank saves 0. Type digits only and use - or + to adjust.'**
  String optionalSteppedIntHelper(String emptyLabel);

  /// No description provided for @enterValueFromMinToMax.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from {min} to {max}.'**
  String enterValueFromMinToMax(String min, String max);

  /// No description provided for @enterValidValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get enterValidValue;

  /// No description provided for @prayerRemindersCouldNotBeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders could not be scheduled.'**
  String get prayerRemindersCouldNotBeScheduled;

  /// No description provided for @qpcFontsDownloadError.
  ///
  /// In en, this message translates to:
  /// **'The Tajweed font download did not include all 604 pages.'**
  String get qpcFontsDownloadError;

  /// No description provided for @sysDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System default / لغة النظام'**
  String get sysDefaultSubtitle;

  /// No description provided for @enSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get enSubtitle;

  /// No description provided for @arSubtitle.
  ///
  /// In en, this message translates to:
  /// **'العربية / Arabic'**
  String get arSubtitle;

  /// No description provided for @idSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia / Indonesian'**
  String get idSubtitle;

  /// No description provided for @urSubtitle.
  ///
  /// In en, this message translates to:
  /// **'اردو / Urdu'**
  String get urSubtitle;

  /// No description provided for @trSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Türkçe / Turkish'**
  String get trSubtitle;

  /// No description provided for @bnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'বাংলা / Bengali'**
  String get bnSubtitle;

  /// No description provided for @faSubtitle.
  ///
  /// In en, this message translates to:
  /// **'فارسی / Farsi'**
  String get faSubtitle;

  /// No description provided for @subhanAllah.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllah'**
  String get subhanAllah;

  /// No description provided for @alhamdulillah.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah'**
  String get alhamdulillah;

  /// No description provided for @allahuAkbar.
  ///
  /// In en, this message translates to:
  /// **'Allahu Akbar'**
  String get allahuAkbar;

  /// No description provided for @astaghfirullah.
  ///
  /// In en, this message translates to:
  /// **'Astaghfirullah'**
  String get astaghfirullah;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @previousDhikr.
  ///
  /// In en, this message translates to:
  /// **'Previous dhikr'**
  String get previousDhikr;

  /// No description provided for @nextDhikr.
  ///
  /// In en, this message translates to:
  /// **'Next dhikr'**
  String get nextDhikr;

  /// No description provided for @zakatAlMal.
  ///
  /// In en, this message translates to:
  /// **'Zakat al-Māl'**
  String get zakatAlMal;

  /// No description provided for @purifyWealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Purify your wealth. Grow your blessings.'**
  String get purifyWealthSubtitle;

  /// No description provided for @liveMarketRates.
  ///
  /// In en, this message translates to:
  /// **'Live Market Rates'**
  String get liveMarketRates;

  /// No description provided for @fetchingLiveRates.
  ///
  /// In en, this message translates to:
  /// **'Fetching live market rates...'**
  String get fetchingLiveRates;

  /// No description provided for @ratesSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Live metal rates synchronized successfully'**
  String get ratesSyncSuccess;

  /// No description provided for @ratesSyncOffline.
  ///
  /// In en, this message translates to:
  /// **'Market offline. Using standard cached values.'**
  String get ratesSyncOffline;

  /// No description provided for @zakatDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Rates and Nisab assumptions are estimates; verify with a trusted scholar and applicable guidance.'**
  String get zakatDisclaimer;

  /// No description provided for @overridePrices.
  ///
  /// In en, this message translates to:
  /// **'Override Prices'**
  String get overridePrices;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @silverDefault.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silverDefault;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @nisabThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'NISAB THRESHOLD'**
  String get nisabThresholdLabel;

  /// No description provided for @yourWealth.
  ///
  /// In en, this message translates to:
  /// **'YOUR WEALTH'**
  String get yourWealth;

  /// No description provided for @cashHint.
  ///
  /// In en, this message translates to:
  /// **'Bank, cash, digital wallets, money owed to you'**
  String get cashHint;

  /// No description provided for @goldHint.
  ///
  /// In en, this message translates to:
  /// **'Investment gold + jewelry (check your madhhab)'**
  String get goldHint;

  /// No description provided for @investmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Stocks, ETFs, crypto, funds — current market value'**
  String get investmentsHint;

  /// No description provided for @businessHint.
  ///
  /// In en, this message translates to:
  /// **'Inventory & trade goods at current value'**
  String get businessHint;

  /// No description provided for @agricultureHint.
  ///
  /// In en, this message translates to:
  /// **'Crops & produce (5-10% rate applied)'**
  String get agricultureHint;

  /// No description provided for @otherHint.
  ///
  /// In en, this message translates to:
  /// **'Any other Zakatable assets'**
  String get otherHint;

  /// No description provided for @liabilitiesDeduct.
  ///
  /// In en, this message translates to:
  /// **'Liabilities (Deduct)'**
  String get liabilitiesDeduct;

  /// No description provided for @liabilitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Loans, credit cards, due payments you must settle'**
  String get liabilitiesHint;

  /// No description provided for @netZakatableWealth.
  ///
  /// In en, this message translates to:
  /// **'Net Zakatable Wealth'**
  String get netZakatableWealth;

  /// No description provided for @eligible.
  ///
  /// In en, this message translates to:
  /// **'ELIGIBLE'**
  String get eligible;

  /// No description provided for @belowNisab.
  ///
  /// In en, this message translates to:
  /// **'BELOW NISAB'**
  String get belowNisab;

  /// No description provided for @zakatDueLabel.
  ///
  /// In en, this message translates to:
  /// **'ZAKAT DUE (2.5%)'**
  String get zakatDueLabel;

  /// No description provided for @resetCalculator.
  ///
  /// In en, this message translates to:
  /// **'Reset Calculator'**
  String get resetCalculator;

  /// No description provided for @goldPriceGram.
  ///
  /// In en, this message translates to:
  /// **'Gold price per gram (USD)'**
  String get goldPriceGram;

  /// No description provided for @silverPriceGram.
  ///
  /// In en, this message translates to:
  /// **'Silver price per gram (USD)'**
  String get silverPriceGram;

  /// No description provided for @zakatSavedLedger.
  ///
  /// In en, this message translates to:
  /// **'Zakat calculation saved to your personal ledger'**
  String get zakatSavedLedger;

  /// No description provided for @zakatPaidDistributed.
  ///
  /// In en, this message translates to:
  /// **'Zakat Paid/Distributed:'**
  String get zakatPaidDistributed;

  /// No description provided for @updateZakatPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Update Zakat Paid Amount'**
  String get updateZakatPaidAmount;

  /// No description provided for @enterPaidAmountUsd.
  ///
  /// In en, this message translates to:
  /// **'Enter paid amount in USD'**
  String get enterPaidAmountUsd;

  /// No description provided for @calculatorTab.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @fastingReminder.
  ///
  /// In en, this message translates to:
  /// **'Fasting Reminder'**
  String get fastingReminder;

  /// No description provided for @dateNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not locate that date in the near future'**
  String get dateNotFound;

  /// No description provided for @customizeCalendar.
  ///
  /// In en, this message translates to:
  /// **'Customize calendar'**
  String get customizeCalendar;

  /// No description provided for @shareDate.
  ///
  /// In en, this message translates to:
  /// **'Share this date'**
  String get shareDate;

  /// No description provided for @dateCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Date details copied to clipboard'**
  String get dateCopiedClipboard;

  /// No description provided for @moonSighting.
  ///
  /// In en, this message translates to:
  /// **'Moon Sighting'**
  String get moonSighting;

  /// No description provided for @fastingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Fasting Alerts'**
  String get fastingAlerts;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @daysPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysPlural(int count);

  /// No description provided for @daySingular.
  ///
  /// In en, this message translates to:
  /// **'{count} day'**
  String daySingular(int count);

  /// No description provided for @calendarSettings.
  ///
  /// In en, this message translates to:
  /// **'Calendar Settings'**
  String get calendarSettings;

  /// No description provided for @calendarSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust for local moon sighting and fasting reminders'**
  String get calendarSettingsSubtitle;

  /// No description provided for @sightingOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Moon Sighting Offset'**
  String get sightingOffsetLabel;

  /// No description provided for @fastingRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified the evening before recommended fasts'**
  String get fastingRemindersSubtitle;

  /// No description provided for @hijriDateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Note: Hijri dates are approximate and depend on local moon sighting. The offset lets you align the calendar with your community’s observation.'**
  String get hijriDateDisclaimer;

  /// No description provided for @recommendedFast.
  ///
  /// In en, this message translates to:
  /// **'Recommended Fast'**
  String get recommendedFast;

  /// No description provided for @recommendedForThisDay.
  ///
  /// In en, this message translates to:
  /// **'Recommended for this day'**
  String get recommendedForThisDay;

  /// No description provided for @todayLegend.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLegend;

  /// No description provided for @eidLegend.
  ///
  /// In en, this message translates to:
  /// **'Eid'**
  String get eidLegend;

  /// No description provided for @ramadanLegend.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadanLegend;

  /// No description provided for @blessedNightLegend.
  ///
  /// In en, this message translates to:
  /// **'Blessed Night'**
  String get blessedNightLegend;

  /// No description provided for @fastLegend.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fastLegend;

  /// No description provided for @keyDatesInYear.
  ///
  /// In en, this message translates to:
  /// **'Key Dates in {year}'**
  String keyDatesInYear(int year);

  /// No description provided for @fastingAlertsActive.
  ///
  /// In en, this message translates to:
  /// **'Fasting Alerts Active'**
  String get fastingAlertsActive;

  /// No description provided for @quranFonts.
  ///
  /// In en, this message translates to:
  /// **'Quran Fonts'**
  String get quranFonts;

  /// No description provided for @allReciters.
  ///
  /// In en, this message translates to:
  /// **'All Reciters'**
  String get allReciters;

  /// No description provided for @tapToAdjust.
  ///
  /// In en, this message translates to:
  /// **'Tap to adjust'**
  String get tapToAdjust;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @sleepTimerSettings.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer Settings'**
  String get sleepTimerSettings;

  /// No description provided for @numericMinutesDuration.
  ///
  /// In en, this message translates to:
  /// **'Numeric Minutes Duration'**
  String get numericMinutesDuration;

  /// No description provided for @endOfSurahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-kill the stream exactly when the current track finishes'**
  String get endOfSurahSubtitle;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get turnOff;

  /// No description provided for @setTimer.
  ///
  /// In en, this message translates to:
  /// **'Set Timer'**
  String get setTimer;

  /// No description provided for @decreaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String decreaseLabel(String label);

  /// No description provided for @increaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String increaseLabel(String label);

  /// No description provided for @exampleCoordinate.
  ///
  /// In en, this message translates to:
  /// **'Example: {value}'**
  String exampleCoordinate(String value);

  /// No description provided for @filterAndSort.
  ///
  /// In en, this message translates to:
  /// **'Filter & sort'**
  String get filterAndSort;

  /// No description provided for @deleteDownloadsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete downloads?'**
  String get deleteDownloadsQuestion;

  /// No description provided for @searchRecitationsOrSurahs.
  ///
  /// In en, this message translates to:
  /// **'Search recitations or surahs...'**
  String get searchRecitationsOrSurahs;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoal;

  /// No description provided for @readingPlan.
  ///
  /// In en, this message translates to:
  /// **'Reading plan'**
  String get readingPlan;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @bookmarksAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks and notes'**
  String get bookmarksAndNotes;

  /// No description provided for @hideSettings.
  ///
  /// In en, this message translates to:
  /// **'Hide settings'**
  String get hideSettings;

  /// No description provided for @showSettings.
  ///
  /// In en, this message translates to:
  /// **'Show settings'**
  String get showSettings;

  /// No description provided for @zakatCategoryCash.
  ///
  /// In en, this message translates to:
  /// **'Cash & Receivables'**
  String get zakatCategoryCash;

  /// No description provided for @zakatCategoryGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get zakatCategoryGold;

  /// No description provided for @zakatCategorySilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get zakatCategorySilver;

  /// No description provided for @zakatCategoryInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments & Securities'**
  String get zakatCategoryInvestments;

  /// No description provided for @zakatCategoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business Inventory'**
  String get zakatCategoryBusiness;

  /// No description provided for @zakatCategoryLivestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock (Traditional)'**
  String get zakatCategoryLivestock;

  /// No description provided for @zakatCategoryAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Produce'**
  String get zakatCategoryAgriculture;

  /// No description provided for @zakatCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other Assets'**
  String get zakatCategoryOther;

  /// No description provided for @zakatBelowNisabExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your wealth is below the Nisab of {nisab}. No Zakat is due yet.'**
  String zakatBelowNisabExplanation(String nisab);

  /// No description provided for @saveToHistory.
  ///
  /// In en, this message translates to:
  /// **'Save to History'**
  String get saveToHistory;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// No description provided for @enterAmountInCurrency.
  ///
  /// In en, this message translates to:
  /// **'Enter amount in {currency}'**
  String enterAmountInCurrency(String currency);

  /// No description provided for @amountInCurrency.
  ///
  /// In en, this message translates to:
  /// **'Amount in {currency}'**
  String amountInCurrency(String currency);

  /// No description provided for @livestockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sheep/Goats, Cows, Camels — simplified modern values'**
  String get livestockSubtitle;

  /// No description provided for @livestockSheepGoats.
  ///
  /// In en, this message translates to:
  /// **'Sheep & Goats'**
  String get livestockSheepGoats;

  /// No description provided for @livestockCowsBuffalo.
  ///
  /// In en, this message translates to:
  /// **'Cows / Buffalo'**
  String get livestockCowsBuffalo;

  /// No description provided for @livestockCamels.
  ///
  /// In en, this message translates to:
  /// **'Camels'**
  String get livestockCamels;

  /// No description provided for @noHistoricalCalculations.
  ///
  /// In en, this message translates to:
  /// **'No historical calculations'**
  String get noHistoricalCalculations;

  /// No description provided for @savedRecordsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Saved records will appear here.'**
  String get savedRecordsAppearHere;

  /// No description provided for @calculationOnDate.
  ///
  /// In en, this message translates to:
  /// **'Calculation on {date}'**
  String calculationOnDate(String date);

  /// No description provided for @historyLiquidCash.
  ///
  /// In en, this message translates to:
  /// **'Liquid Cash:'**
  String get historyLiquidCash;

  /// No description provided for @historyInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments:'**
  String get historyInvestments;

  /// No description provided for @historyGoldGrams.
  ///
  /// In en, this message translates to:
  /// **'Gold ({grams}g):'**
  String historyGoldGrams(String grams);

  /// No description provided for @historySilverGrams.
  ///
  /// In en, this message translates to:
  /// **'Silver ({grams}g):'**
  String historySilverGrams(String grams);

  /// No description provided for @historyLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities:'**
  String get historyLiabilities;

  /// No description provided for @historyZakatDue.
  ///
  /// In en, this message translates to:
  /// **'Zakat Due:'**
  String get historyZakatDue;

  /// No description provided for @moonPhaseNew.
  ///
  /// In en, this message translates to:
  /// **'New Moon'**
  String get moonPhaseNew;

  /// No description provided for @moonPhaseWaxingCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waxing Crescent'**
  String get moonPhaseWaxingCrescent;

  /// No description provided for @moonPhaseFull.
  ///
  /// In en, this message translates to:
  /// **'Full Moon'**
  String get moonPhaseFull;

  /// No description provided for @moonPhaseWaningCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waning Crescent'**
  String get moonPhaseWaningCrescent;

  /// No description provided for @moonPhaseCrescent.
  ///
  /// In en, this message translates to:
  /// **'Crescent'**
  String get moonPhaseCrescent;

  /// No description provided for @moonPhaseContextNew.
  ///
  /// In en, this message translates to:
  /// **'Time for new beginnings'**
  String get moonPhaseContextNew;

  /// No description provided for @moonPhaseContextWaxing.
  ///
  /// In en, this message translates to:
  /// **'Growing light'**
  String get moonPhaseContextWaxing;

  /// No description provided for @moonPhaseContextFull.
  ///
  /// In en, this message translates to:
  /// **'Peak illumination'**
  String get moonPhaseContextFull;

  /// No description provided for @moonPhaseContextWaning.
  ///
  /// In en, this message translates to:
  /// **'Gentle release'**
  String get moonPhaseContextWaning;

  /// No description provided for @occasionRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get occasionRamadan;

  /// No description provided for @occasionEidAlFitr.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get occasionEidAlFitr;

  /// No description provided for @occasionDayOfArafah.
  ///
  /// In en, this message translates to:
  /// **'Day of Arafah'**
  String get occasionDayOfArafah;

  /// No description provided for @occasionDayOfArafahFasting.
  ///
  /// In en, this message translates to:
  /// **'Day of Arafah (Fasting)'**
  String get occasionDayOfArafahFasting;

  /// No description provided for @occasionEidAlAdha.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get occasionEidAlAdha;

  /// No description provided for @occasionDayOfAshura.
  ///
  /// In en, this message translates to:
  /// **'Day of Ashura'**
  String get occasionDayOfAshura;

  /// No description provided for @occasionDayOfAshuraFasting.
  ///
  /// In en, this message translates to:
  /// **'Day of Ashura (Fasting)'**
  String get occasionDayOfAshuraFasting;

  /// No description provided for @occasionIsraAndMiraj.
  ///
  /// In en, this message translates to:
  /// **'Isra\' & Mi\'raj'**
  String get occasionIsraAndMiraj;

  /// No description provided for @occasionRamadanBegins.
  ///
  /// In en, this message translates to:
  /// **'Ramadan begins'**
  String get occasionRamadanBegins;

  /// No description provided for @occasionRamadanFastingDay.
  ///
  /// In en, this message translates to:
  /// **'Ramadan Fasting Day'**
  String get occasionRamadanFastingDay;

  /// No description provided for @occasionLaylatAlQadr.
  ///
  /// In en, this message translates to:
  /// **'Laylat al-Qadr'**
  String get occasionLaylatAlQadr;

  /// No description provided for @occasionLaylatAlQadrBlessed.
  ///
  /// In en, this message translates to:
  /// **'Laylat al-Qadr (Blessed Night)'**
  String get occasionLaylatAlQadrBlessed;

  /// No description provided for @occasionIslamicNewYear.
  ///
  /// In en, this message translates to:
  /// **'Islamic New Year'**
  String get occasionIslamicNewYear;

  /// No description provided for @occasionShabEBarat.
  ///
  /// In en, this message translates to:
  /// **'Shab-e-Barat'**
  String get occasionShabEBarat;

  /// No description provided for @occasionShabEBaratBlessed.
  ///
  /// In en, this message translates to:
  /// **'Shab-e-Barat (Blessed Night)'**
  String get occasionShabEBaratBlessed;

  /// No description provided for @occasionTasuaFast.
  ///
  /// In en, this message translates to:
  /// **'Tasua Fast'**
  String get occasionTasuaFast;

  /// No description provided for @occasionAyyamAlBid.
  ///
  /// In en, this message translates to:
  /// **'Ayyam al-Bid (White Day)'**
  String get occasionAyyamAlBid;

  /// No description provided for @occasionAyyamAlBidFasting.
  ///
  /// In en, this message translates to:
  /// **'Ayyam al-Bid (White Day - Fasting)'**
  String get occasionAyyamAlBidFasting;

  /// No description provided for @occasionRecommendedFastingDay.
  ///
  /// In en, this message translates to:
  /// **'Recommended Fasting Day'**
  String get occasionRecommendedFastingDay;

  /// No description provided for @occasionFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get occasionFast;

  /// No description provided for @fastingNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is {date} ({reason}). Prepare your intention and Suhoor.'**
  String fastingNotificationBody(String date, String reason);

  /// No description provided for @shareIslamicDate.
  ///
  /// In en, this message translates to:
  /// **'Islamic Date: {date}'**
  String shareIslamicDate(String date);

  /// No description provided for @shareGregorianDate.
  ///
  /// In en, this message translates to:
  /// **'Gregorian: {date}'**
  String shareGregorianDate(String date);

  /// No description provided for @shareOccasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion: {occasion}'**
  String shareOccasion(String occasion);

  /// No description provided for @shareMoonPhase.
  ///
  /// In en, this message translates to:
  /// **'Moon Phase: {phase}'**
  String shareMoonPhase(String phase);

  /// No description provided for @shareRecommendedFasting.
  ///
  /// In en, this message translates to:
  /// **'Recommended: Fasting'**
  String get shareRecommendedFasting;

  /// No description provided for @moonPhase.
  ///
  /// In en, this message translates to:
  /// **'Moon Phase'**
  String get moonPhase;

  /// No description provided for @recActionQuran.
  ///
  /// In en, this message translates to:
  /// **'Increase recitation of the Qur\'an'**
  String get recActionQuran;

  /// No description provided for @recActionCharity.
  ///
  /// In en, this message translates to:
  /// **'Give charity and help those in need'**
  String get recActionCharity;

  /// No description provided for @recActionLaylatAlQadr.
  ///
  /// In en, this message translates to:
  /// **'Seek Laylat al-Qadr in the odd nights'**
  String get recActionLaylatAlQadr;

  /// No description provided for @recActionEidFitr.
  ///
  /// In en, this message translates to:
  /// **'Perform Eid prayer + Zakat al-Fitr'**
  String get recActionEidFitr;

  /// No description provided for @recActionEidFitrSocial.
  ///
  /// In en, this message translates to:
  /// **'Visit family and share food'**
  String get recActionEidFitrSocial;

  /// No description provided for @recActionFastArafah.
  ///
  /// In en, this message translates to:
  /// **'Fast the Day of Arafah'**
  String get recActionFastArafah;

  /// No description provided for @recActionDua.
  ///
  /// In en, this message translates to:
  /// **'Make abundant du\'a'**
  String get recActionDua;

  /// No description provided for @recActionEidAdha.
  ///
  /// In en, this message translates to:
  /// **'Perform Eid al-Adha prayer'**
  String get recActionEidAdha;

  /// No description provided for @recActionQurbani.
  ///
  /// In en, this message translates to:
  /// **'Sacrifice an animal if able (Qurbani)'**
  String get recActionQurbani;

  /// No description provided for @recActionFastAshura.
  ///
  /// In en, this message translates to:
  /// **'Fast Ashura (before/after)'**
  String get recActionFastAshura;

  /// No description provided for @recActionVoluntaryFast.
  ///
  /// In en, this message translates to:
  /// **'Observe voluntary fast if able'**
  String get recActionVoluntaryFast;

  /// No description provided for @recActionFastAyyamAlBid.
  ///
  /// In en, this message translates to:
  /// **'Fast one of the Ayyam al-Bid (White Days)'**
  String get recActionFastAyyamAlBid;

  /// No description provided for @recActionGeneralWorship.
  ///
  /// In en, this message translates to:
  /// **'Engage in dhikr, prayer, and good deeds'**
  String get recActionGeneralWorship;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @useLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get useLiveLocation;

  /// No description provided for @usePinLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Pin Location'**
  String get usePinLocation;

  /// No description provided for @confirmLiveLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Live Location'**
  String get confirmLiveLocationTitle;

  /// No description provided for @confirmLiveLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to lock prayer times to your device\'s live location? The app will automatically update times as you travel.'**
  String get confirmLiveLocationMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'fa',
    'id',
    'tr',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'id':
      return AppLocalizationsId();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
