# Translation review hand-off

Machine-drafted translations that need a native-speaker review, generated from the ARB diff `git diff 9f00137~1..HEAD -- 'lib/l10n/app_*.arb'` (all keys added or changed in `ar bn de fa id tr ur` since that point), plus the strings added by the Zakat fixes in `fix/followups`. English (`app_en.arb`) is the source of truth. **Nothing here has been reviewed by a native speaker.**

Each language has its own section, so a reviewer can work through one language alone. Edit the value in `lib/l10n/app_<code>.arb`, then run `flutter gen-l10n` and `dart run tool/verify_localizations.dart`.

## Rules for reviewers

- Keep every `{placeholder}` exactly as written (`{count}`, `{currency}`, `{nisab}`...). Move it where the grammar needs it, never rename, translate or delete it.
- ICU plurals look like `{count, plural, one{...} other{...}}`. Keep the keywords (`one`, `other`, `=0`...) and braces untouched and translate only the text inside the braces. Arabic needs `zero`, `one`, `two`, `few`, `many`, `other`; Bengali, German, Indonesian, Persian, Turkish and Urdu need `one` and `other` (Indonesian and Turkish have a single form in practice, but the keys must stay).
- A single quote `'` is an ICU escape: write `''` for a literal apostrophe if one is ever needed, and avoid a lone `'` before `{`.
- Several English labels are upper-case on purpose (pills and eyebrows, e.g. `NISAB NOT CHECKED`). German, Indonesian and Turkish keep the upper-case style where the English is upper-case; the other languages use normal case. The app upper-cases some labels in code with locale rules (Turkish dotted/dotless i), so keep Turkish text in correct Turkish case.
- Arrows in the Downloads sort labels (`downloadsSort*`) point in reading direction: Arabic, Persian and Urdu use a left arrow.
- Keep numbers Western (0-9) as the rest of the app does, unless the existing neighbouring strings in that file use native digits (Bengali, Persian and Urdu files already do in some labels; follow the surrounding style).
- If a draft reads wrongly, change it; if a term should stay in English or transliterated (Nisab, Tola, Qari, Hifz), keep it consistent with the other strings of that file.

## Existing strings changed in this round (flagged)

| Language | Key | Before | After | Why |
|---|---|---|---|---|
| German | `cancel` | Stornieren | Abbrechen | "Stornieren" means cancelling an order or booking, not dismissing a dialog. Used on every Cancel button. |
| Indonesian | `reciter` | Tukang deklamasi | Qari | "Tukang deklamasi" is a literal "declaimer"; the rest of `app_id.arb` already says "Qari" (`allReciters`, `downloadsReciterCount`, `downloadsSortReciter*`). |

Same weakness left **unchanged** on purpose (only the two keys above were in scope); a reviewer may want to fix them for consistency:

- German `hifzExitCancel` is still "Stornieren" (`lib/l10n/app_de.arb`).
- Indonesian `reciterOption` is still "Tukang deklamasi".
- Older weak strings noted before and untouched: `clear` (German, Indonesian), `worshipTrendsAndStreaks` (German, Indonesian, Bengali), Indonesian `cancel` ("Membatalkan").

## Other strings whose wording changed in every language

| Key | English now | Where it appears | Change |
|---|---|---|---|
| `goldPriceGram` | Gold price per gram ({currency}) | `lib/zakat/zakat_page.dart` | The "(USD)" suffix became a `{currency}` placeholder: an override is stored in the selected currency, not USD. In the 7 languages only the "(USD)" / Arabic "(بالدولار)" suffix was replaced by `({currency})`; the rest of the sentence is the old translation. |
| `silverPriceGram` | Silver price per gram ({currency}) | `lib/zakat/zakat_page.dart` | Same as `goldPriceGram`. |

`saveDuasHere` (English "Saved for quick access", only the Duas tile caption) was re-drafted in all seven languages; it is listed in each language table below as `changed`.

## Keys that carry placeholders or plurals

| Key | English | Notes |
|---|---|---|
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | placeholders: `{currency}` |
| `repeatTimes` | {count} times | placeholders: `{count}` |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | placeholders: `{count}`, `{max}` |
| `navigationSlot` | Slot {number} | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | placeholders: `{displaced}`, `{item}` |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | placeholders: `{reciter}`, `{surah}` |
| `prayerNextIn` | {prayer} in {time} | placeholders: `{prayer}`, `{time}` |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |

## Contents

97 new keys per language, plus the changed ones and four older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`) that were added before the diff base and so are not in the diff itself; they are listed at the end of each table. Keys appear in the order of `app_en.arb`.

## Arabic (RTL) (`ar`)

File: `lib/l10n/app_ar.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | عكس الترتيب | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | النصاب غير محدد | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | لا تُحتسب زكاة الأنعام هنا، لذا لا تدخل في المجموع. يُرجى سؤال أحد أهل العلم. | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | أدخل المبلغ المدفوع بالـ {currency} | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | المجلد | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | إدارة المجلدات | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | أضف سعر الذهب والفضة لمعرفة النصاب. تعذّر تحميل الأسعار، لذا أدخلها يدويًا. | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | حذف هذا الحساب؟ | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | سيؤدي هذا إلى إزالة الحساب المحفوظ من السجل. | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | تولة | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | فشل | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | نجاح | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | تنسيق صورة المشاركة | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | قصة 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | مربع 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | كلاسيكي | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | تعذّرت مشاركة صورة الآية. | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | تجميع المنزَّلة | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | عرض بالترتيب الأبجدي | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | انقطع اتصال الصوت. تحقق من الإنترنت وحاول مرة أخرى. | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | أنت غير متصل بالإنترنت. نزّل هذه الآية أو أعد الاتصال لبثّها. | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | تعذّر تشغيل صوت الآية. | `lib/home/read.dart` |  |
| `repeatOnce` | Once | مرة واحدة | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count, plural, few{{count} مرات} other{{count} مرة}} | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | بلا حد | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0.5 ثانية | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | تحديث متاح | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | جارٍ البدء | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | جارٍ التحقق | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | جارٍ الاستخراج | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | جارٍ التثبيت | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | فشل | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | مورد | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | مضمّنة | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | التنزيل غير متاح | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | اسحب البطاقات لإعادة ترتيبها. اسحب عنصرًا متاحًا وأفلته على بطاقة نشطة لتبديلهما، أو اضغط على عنصر أدناه لتثبيته (يحلّ محل العنصر الأقل استخدامًا مؤخرًا). | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | خانات شريط التنقل النشطة ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | العناصر المتاحة غير المثبّتة | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | الخانة {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | الخانة {number} (مركز مقفل) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | تم تبديل {first} بـ{second} | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | تمت إزالة {item} من شريط التنقل | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | تم تثبيت {item} | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | تم تثبيت {item} (حلّ محل {displaced}) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | لوحة التحكم الرئيسية | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | اقرأ القرآن الكريم | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | مواقيت الصلاة والأذان | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | تفضيلات النظام | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | الزكاة | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | التقويم | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count, plural, =1{قارئ واحد} =2{قارئان} few{{count} قرّاء} other{{count} قارئًا}} | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count, plural, =1{عنصر واحد} =2{عنصران} few{{count} عناصر} other{{count} عنصرًا}} | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | هل تريد إزالة جميع تنزيلات {reciter} الخاصة بـ{surah}؟ | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | كل السور | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | تصفية التنزيلات وفرزها | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | تحكّم أكبر في التلاوات التي تظهر في مكتبتك | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | ابحث عن تلاوات أو سور... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | تجميع حسب | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | الفرز حسب | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | التصنيف | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | نوع المحتوى | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | القارئ (أ ← ي) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | القارئ (ي ← أ) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | الحجم (الأكبر أولًا) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | الحجم (الأصغر أولًا) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | السورة (1 ← 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | السورة (114 ← 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | تعيين قيمة موجبة | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | تعيين قيمة سالبة | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | انتهت مهلة التحقق من إذن الإشعارات. جرّب إعادة فتح التطبيق أو تفعيل الإشعارات من إعدادات النظام. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | تعذّر التحقق من إذن الإشعارات. حاول مرة أخرى أو فعّل الإشعارات من إعدادات النظام. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | انتهت مهلة التحقق من إذن المنبّه الدقيق. جرّب إعادة فتح التطبيق أو تفعيل «المنبهات والتذكيرات» من إعدادات النظام. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | تعذّر التحقق من إذن المنبّه الدقيق. حاول مرة أخرى أو فعّل «المنبهات والتذكيرات» من إعدادات النظام. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | الحنفي | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | تلقائي | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | بدون | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | منتصف الليل | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | سُبع الليل | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | حسب الزاوية | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | الأنسب للموقع | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | رابطة العالم الإسلامي | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | المصرية | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | أم القرى | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | دبي / الخليج | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | الكويت | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | قطر | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | كراتشي | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | لجنة رؤية الهلال | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | المغرب | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | سنغافورة | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | طهران | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | تركيا / ديانت | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | تلقائي | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | الرابطة | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | دبي | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | رؤية الهلال | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | تركيا | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | يجب أن تظل أداة واحدة على الأقل مثبتة. | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | محفوظة للوصول السريع | `lib/duas/duas_page.dart` | re-drafted (was: احفظ الأدعية هنا للوصول السريع) |
| `prayerNextIn` | {prayer} in {time} | {prayer} بعد {time} | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | عرض المزيد | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, other{{count} صلوات}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | ملاحظة | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |

## Bengali (`bn`)

File: `lib/l10n/app_bn.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | ক্রম উল্টান | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | নিসাব যাচাই হয়নি | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | গবাদি পশুর যাকাত এখানে হিসাব করা হয় না, তাই মোট অঙ্কে ধরা হয়নি। অনুগ্রহ করে একজন যোগ্য আলেমকে জিজ্ঞাসা করুন। | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | {currency}-এ পরিশোধিত পরিমাণ লিখুন | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | ফোল্ডার | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | ফোল্ডার পরিচালনা | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | নিসাব যাচাই করতে সোনা ও রুপার দাম যোগ করুন। দাম লোড করা যায়নি, তাই নিজে লিখুন। | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | এই হিসাব মুছবেন? | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | এতে সংরক্ষিত হিসাবটি ইতিহাস থেকে মুছে যাবে। | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | ভরি | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | ব্যর্থ | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | উত্তীর্ণ | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | শেয়ার করা ছবির ফরম্যাট | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | স্টোরি 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | বর্গাকার 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | ক্লাসিক | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | আয়াতের ছবি শেয়ার করা যায়নি। | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | ডাউনলোড করাগুলো একসাথে দেখান | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | বর্ণানুক্রমে দেখান | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | অডিও সংযোগ বিচ্ছিন্ন হয়েছে। আপনার ইন্টারনেট পরীক্ষা করে আবার চেষ্টা করুন। | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | আপনি অফলাইনে আছেন। এই আয়াতটি ডাউনলোড করুন অথবা স্ট্রিম করতে আবার সংযুক্ত হন। | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | আয়াতের অডিও চালানো যায়নি। | `lib/home/read.dart` |  |
| `repeatOnce` | Once | একবার | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count} বার | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | অসীম | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0.5 সেকেন্ড | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | আপডেট উপলব্ধ | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | শুরু হচ্ছে | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | যাচাই করা হচ্ছে | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | এক্সট্র্যাক্ট করা হচ্ছে | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | ইনস্টল হচ্ছে | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | ব্যর্থ হয়েছে | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | রিসোর্স | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | অন্তর্ভুক্ত | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | ডাউনলোড পাওয়া যাচ্ছে না | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | পুনর্বিন্যাস করতে টাইলগুলো টেনে আনুন। কোনো উপলব্ধ আইটেম টেনে একটি সক্রিয় টাইলের ওপর ছেড়ে দিলে দুটি অদলবদল হবে, অথবা নিচের কোনো আইটেমে ট্যাপ করে সেটি পিন করুন (সবচেয়ে কম সম্প্রতি ব্যবহৃত আইটেমটি সরে যাবে)। | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | সক্রিয় নেভবার স্লট ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | উপলব্ধ আনপিন করা আইটেম | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | স্লট {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | স্লট {number} (লক করা হাব) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | {first} ও {second} অদলবদল করা হয়েছে | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | নেভবার থেকে {item} সরানো হয়েছে | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | {item} পিন করা হয়েছে | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | {item} পিন করা হয়েছে ({displaced} সরে গেছে) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | প্রধান ড্যাশবোর্ড | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | পবিত্র কুরআন পড়ুন | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | নামাজের সময় ও আজান | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | সিস্টেম পছন্দসমূহ | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | যাকাত | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | ক্যালেন্ডার | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count} জন আবৃত্তিকারী | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count}টি আইটেম | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | {surah}-এর জন্য {reciter}-এর সব ডাউনলোড সরাবেন? | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | সব সূরা | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | ডাউনলোড ফিল্টার ও সাজান | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | আপনার লাইব্রেরিতে কোন তিলাওয়াতগুলো দেখা যাবে তার ওপর আরও নিয়ন্ত্রণ | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | তিলাওয়াত বা সূরা খুঁজুন... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | গ্রুপ করুন | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | সাজানোর ধরন | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | ক্যাটাগরি | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | কনটেন্টের ধরন | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | আবৃত্তিকারী (অ → হ) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | আবৃত্তিকারী (হ → অ) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | আকার (বড় আগে) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | আকার (ছোট আগে) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | সূরা (1 → 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | সূরা (114 → 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | ধনাত্মক করুন | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | ঋণাত্মক করুন | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | বিজ্ঞপ্তির অনুমতি যাচাই করতে সময় শেষ হয়ে গেছে। অ্যাপটি আবার খুলুন অথবা সিস্টেম সেটিংসে বিজ্ঞপ্তি চালু করুন। | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | বিজ্ঞপ্তির অনুমতি যাচাই করা যায়নি। আবার চেষ্টা করুন অথবা সিস্টেম সেটিংসে বিজ্ঞপ্তি চালু করুন। | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | সঠিক অ্যালার্মের অনুমতি যাচাই করতে সময় শেষ হয়ে গেছে। অ্যাপটি আবার খুলুন অথবা সিস্টেম সেটিংসে অ্যালার্ম ও রিমাইন্ডার চালু করুন। | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | সঠিক অ্যালার্মের অনুমতি যাচাই করা যায়নি। আবার চেষ্টা করুন অথবা সিস্টেম সেটিংসে অ্যালার্ম ও রিমাইন্ডার চালু করুন। | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | হানাফি | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | স্বয়ংক্রিয় | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | কোনোটিই নয় | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | মধ্যরাত | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | এক-সপ্তমাংশ | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | কোণভিত্তিক | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | অবস্থানের জন্য সেরা | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | মুসলিম ওয়ার্ল্ড লীগ | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | মিশরীয় | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | উম্মুল কুরা | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | দুবাই / উপসাগরীয় | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | কুয়েত | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | কাতার | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | করাচি | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | চাঁদ দেখা কমিটি | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | মরক্কো | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | সিঙ্গাপুর | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | তেহরান | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | তুরস্ক / দিয়ানেত | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | স্বয়ংক্রিয় | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | MWL | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | দুবাই | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | চাঁদ দেখা | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | তুরস্ক | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | অন্তত একটি টুল পিন করা থাকতে হবে। | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | দ্রুত অ্যাক্সেসের জন্য সংরক্ষিত | `lib/duas/duas_page.dart` | re-drafted (was: দ্রুত অ্যাক্সেসের জন্য এখানে দোয়া সংরক্ষণ করুন) |
| `prayerNextIn` | {prayer} in {time} | {prayer} {time} পরে | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | আরও দেখুন | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, other{{count}টি নামাজ}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | নোট | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |

## German (`de`)

File: `lib/l10n/app_de.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` and the flagged `cancel` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | Reihenfolge umkehren | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | NISAB NICHT GEPRÜFT | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | Die Zakat auf Vieh wird hier nicht berechnet und fehlt daher in der Summe. Bitte fragen Sie einen qualifizierten Gelehrten. | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | Gezahlten Betrag in {currency} eingeben | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | Ordner | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | Ordner verwalten | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | Gib die Gold- und Silberpreise ein, um den Nisab zu prüfen. Sie konnten nicht geladen werden, bitte manuell eintragen. | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | Diese Berechnung löschen? | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | Die gespeicherte Berechnung wird aus dem Verlauf entfernt. | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | Tola | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | Nicht bestanden | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | Bestanden | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | Bildformat zum Teilen | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | Story 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | Quadrat 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | Klassisch | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | Das Ayah-Bild konnte nicht geteilt werden. | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | Heruntergeladene gruppieren | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | Alphabetisch anzeigen | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | Die Audioverbindung wurde unterbrochen. Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut. | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | Sie sind offline. Laden Sie diesen Ayah herunter oder stellen Sie die Verbindung wieder her, um ihn zu streamen. | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | Die Ayah-Audiodatei konnte nicht abgespielt werden. | `lib/home/read.dart` |  |
| `repeatOnce` | Once | Einmal | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count}-mal | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | Unbegrenzt | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0,5 Sekunden | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | Update verfügbar | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | Wird gestartet | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | Wird überprüft | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | Wird entpackt | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | Wird installiert | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | Fehlgeschlagen | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | Ressource | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | Enthalten | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | Download nicht verfügbar | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | Ziehen Sie die Kacheln, um sie neu anzuordnen. Ziehen Sie ein verfügbares Element auf eine aktive Kachel, um sie zu tauschen, oder tippen Sie unten auf ein Element, um es anzuheften (ersetzt das am längsten nicht genutzte). | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | Aktive Navigationsplätze ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | Verfügbare nicht angeheftete Elemente | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | Platz {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | Platz {number} (gesperrter Hub) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | {first} mit {second} getauscht | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | {item} aus der Navigationsleiste entfernt | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | {item} angeheftet | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | {item} angeheftet ({displaced} ersetzt) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | Haupt-Dashboard | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | Den Heiligen Koran lesen | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | Gebetszeiten & Adhan | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | Systemeinstellungen | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | Zakat | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | Kalender | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count, plural, =1{1 Rezitator} other{{count} Rezitatoren}} | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count, plural, =1{1 Element} other{{count} Elemente}} | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | Alle Downloads von {reciter} für {surah} entfernen? | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | Alle Suren | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | Downloads filtern und sortieren | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | Mehr Kontrolle darüber, welche Rezitationen in Ihrer Bibliothek erscheinen | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | Rezitationen oder Suren suchen ... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | Gruppieren nach | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | Sortieren nach | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | Kategorie | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | Inhaltstyp | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | Rezitator (A → Z) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | Rezitator (Z → A) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | Größe (größte zuerst) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | Größe (kleinste zuerst) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | Sure (1 → 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | Sure (114 → 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | Positiv setzen | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | Negativ setzen | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | Die Prüfung der Benachrichtigungsberechtigung hat zu lange gedauert. Öffnen Sie die App erneut oder aktivieren Sie Benachrichtigungen in den Systemeinstellungen. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | Die Benachrichtigungsberechtigung konnte nicht geprüft werden. Versuchen Sie es erneut oder aktivieren Sie Benachrichtigungen in den Systemeinstellungen. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | Die Prüfung der Berechtigung für exakte Alarme hat zu lange gedauert. Öffnen Sie die App erneut oder aktivieren Sie „Alarme & Erinnerungen“ in den Systemeinstellungen. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | Die Berechtigung für exakte Alarme konnte nicht geprüft werden. Versuchen Sie es erneut oder aktivieren Sie „Alarme & Erinnerungen“ in den Systemeinstellungen. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | Hanafitisch | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | Automatisch | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | Keine | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | Mitte der Nacht | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | Ein Siebtel | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | Winkelbasiert | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | Beste für den Standort | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | Islamische Weltliga | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | Ägyptisch | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | Umm al-Qura | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | Dubai / Golfregion | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | Kuwait | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | Katar | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | Karatschi | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | Mondsichtungs-Komitee | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | Marokko | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | Singapur | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | Teheran | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | Türkei / Diyanet | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | Automatisch | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | MWL | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | Dubai | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | Mondsichtung | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | Türkei | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | Mindestens ein Werkzeug muss angeheftet bleiben. | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | Für schnellen Zugriff gespeichert | `lib/duas/duas_page.dart` | re-drafted (was: Speichern Sie Duas hier für einen schnellen Zugriff) |
| `prayerNextIn` | {prayer} in {time} | {prayer} in {time} | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | Mehr anzeigen | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, =1{1 Gebet} other{{count} Gebete}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | Notiz | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |

## Persian (RTL) (`fa`)

File: `lib/l10n/app_fa.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | معکوس کردن ترتیب | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | حد نصاب نامشخص | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | زکات دام در اینجا محاسبه نمی‌شود و در مجموع نیامده است. لطفاً از یک عالم صلاحیت‌دار بپرسید. | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | مبلغ پرداخت‌شده را به {currency} وارد کنید | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | پوشه | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | مدیریت پوشه‌ها | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | برای بررسی نصاب، قیمت طلا و نقره را وارد کنید. بارگذاری قیمت‌ها ممکن نشد؛ آن‌ها را دستی وارد کنید. | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | این محاسبه حذف شود؟ | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | محاسبهٔ ذخیره‌شده از تاریخچه حذف می‌شود. | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | تولا | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | ناموفق | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | موفق | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | قالب تصویر اشتراک‌گذاری | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | استوری 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | مربع 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | کلاسیک | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | اشتراک‌گذاری تصویر آیه ممکن نشد. | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | گروه‌بندی دانلودشده‌ها | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | نمایش به ترتیب الفبا | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | اتصال صوتی قطع شد. اینترنت خود را بررسی کنید و دوباره تلاش کنید. | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | شما آفلاین هستید. این آیه را دانلود کنید یا برای پخش آنلاین دوباره وصل شوید. | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | پخش صدای آیه ممکن نشد. | `lib/home/read.dart` |  |
| `repeatOnce` | Once | یک بار | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count} بار | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | بی‌نهایت | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0.5 ثانیه | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | به‌روزرسانی موجود است | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | در حال شروع | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | در حال بررسی | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | در حال استخراج | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | در حال نصب | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | ناموفق | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | منبع | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | همراه برنامه | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | دانلود در دسترس نیست | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | برای تغییر ترتیب، کاشی‌ها را بکشید. یک مورد در دسترس را روی کاشی فعال رها کنید تا جابه‌جا شوند، یا روی موردی در پایین بزنید تا سنجاق شود (کم‌استفاده‌ترین مورد جایگزین می‌شود). | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | جایگاه‌های فعال نوار پیمایش ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | موارد در دسترس سنجاق‌نشده | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | جایگاه {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | جایگاه {number} (مرکز قفل‌شده) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | {first} با {second} جابه‌جا شد | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | {item} از نوار پیمایش حذف شد | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | {item} سنجاق شد | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | {item} سنجاق شد ({displaced} جایگزین شد) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | داشبورد اصلی | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | قرآن کریم را بخوانید | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | اوقات نماز و اذان | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | تنظیمات سامانه | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | زکات | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | تقویم | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count} قاری | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count} مورد | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | همه دانلودهای {reciter} برای {surah} حذف شوند؟ | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | همه سوره‌ها | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | فیلتر و مرتب‌سازی دانلودها | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | کنترل بیشتر بر اینکه کدام تلاوت‌ها در کتابخانه شما نمایش داده شوند | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | جستجوی تلاوت‌ها یا سوره‌ها... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | گروه‌بندی بر اساس | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | مرتب‌سازی بر اساس | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | دسته‌بندی | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | نوع محتوا | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | قاری (الف ← ی) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | قاری (ی ← الف) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | حجم (بزرگ‌ترین اول) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | حجم (کوچک‌ترین اول) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | سوره (1 ← 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | سوره (114 ← 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | مثبت کردن | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | منفی کردن | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | بررسی دسترسی اعلان‌ها زمان‌بر شد. برنامه را دوباره باز کنید یا اعلان‌ها را در تنظیمات سیستم فعال کنید. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | بررسی دسترسی اعلان‌ها ممکن نشد. دوباره تلاش کنید یا اعلان‌ها را در تنظیمات سیستم فعال کنید. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | بررسی دسترسی هشدار دقیق زمان‌بر شد. برنامه را دوباره باز کنید یا «هشدارها و یادآورها» را در تنظیمات سیستم فعال کنید. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | بررسی دسترسی هشدار دقیق ممکن نشد. دوباره تلاش کنید یا «هشدارها و یادآورها» را در تنظیمات سیستم فعال کنید. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | حنفی | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | خودکار | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | هیچ‌کدام | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | نیمه‌شب | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | یک‌هفتم | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | مبتنی بر زاویه | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | بهترین برای مکان | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | رابطه جهان اسلام | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | مصری | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | ام‌القری | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | دبی / خلیج | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | کویت | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | قطر | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | کراچی | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | کمیته رؤیت هلال | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | مراکش | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | سنگاپور | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | تهران | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | ترکیه / دیانت | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | خودکار | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | MWL | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | دبی | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | رؤیت هلال | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | ترکیه | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | حداقل یک ابزار باید سنجاق شده باقی بماند. | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | ذخیره‌شده برای دسترسی سریع | `lib/duas/duas_page.dart` | re-drafted (was: برای دسترسی سریع، دعاها را در اینجا ذخیره کنید) |
| `prayerNextIn` | {prayer} in {time} | {prayer} در {time} دیگر | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | نمایش بیشتر | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, other{{count} نماز}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | یادداشت | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |

## Indonesian (`id`)

File: `lib/l10n/app_id.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` and the flagged `reciter` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | Balik urutan | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | NISAB BELUM DICEK | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | Zakat ternak tidak dihitung di sini, sehingga tidak termasuk dalam total. Silakan tanyakan kepada ulama yang berkompeten. | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | Masukkan jumlah terbayar dalam {currency} | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | Folder | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | Kelola folder | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | Tambahkan harga emas dan perak untuk memeriksa nisab. Harga tidak dapat dimuat, jadi masukkan secara manual. | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | Hapus perhitungan ini? | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | Perhitungan tersimpan ini akan dihapus dari riwayat. | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | tola | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | Gagal | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | Lulus | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | Format gambar untuk dibagikan | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | Story 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | Persegi 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | Klasik | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | Gambar ayah tidak dapat dibagikan. | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | Kelompokkan yang diunduh | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | Tampilkan urut abjad | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | Koneksi audio terputus. Periksa internet Anda dan coba lagi. | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | Anda sedang offline. Unduh ayah ini atau sambungkan kembali untuk memutarnya secara streaming. | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | Audio ayah tidak dapat diputar. | `lib/home/read.dart` |  |
| `repeatOnce` | Once | Sekali | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count} kali | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | Tanpa batas | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0,5 detik | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | Pembaruan tersedia | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | Memulai | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | Memverifikasi | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | Mengekstrak | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | Memasang | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | Gagal | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | Sumber daya | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | Bawaan | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | Unduhan tidak tersedia | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | Seret kartu untuk mengatur ulang. Seret item yang tersedia lalu lepaskan di kartu aktif untuk menukar, atau ketuk item di bawah untuk menyematkannya (menggantikan yang paling lama tidak dipakai). | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | Slot bilah navigasi aktif ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | Item tersedia yang belum disematkan | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | Slot {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | Slot {number} (hub terkunci) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | {first} ditukar dengan {second} | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | {item} dihapus dari bilah navigasi | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | {item} disematkan | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | {item} disematkan (menggantikan {displaced}) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | Dasbor utama | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | Baca Al-Quran | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | Waktu salat & azan | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | Preferensi sistem | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | Zakat | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | Kalender | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count} qari | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count} item | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | Hapus semua unduhan {reciter} untuk {surah}? | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | Semua surat | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | Filter & urutkan unduhan | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | Kendali lebih atas lantunan yang tampil di pustaka Anda | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | Cari lantunan atau surat... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | Kelompokkan menurut | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | Urutkan menurut | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | Kategori | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | Jenis konten | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | Qari (A → Z) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | Qari (Z → A) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | Ukuran (terbesar dulu) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | Ukuran (terkecil dulu) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | Surat (1 → 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | Surat (114 → 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | Jadikan positif | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | Jadikan negatif | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | Pemeriksaan izin notifikasi melewati batas waktu. Coba buka ulang aplikasi atau aktifkan notifikasi di pengaturan sistem. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | Tidak dapat memeriksa izin notifikasi. Coba lagi atau aktifkan notifikasi di pengaturan sistem. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | Pemeriksaan izin alarm yang tepat melewati batas waktu. Coba buka ulang aplikasi atau aktifkan alarm & pengingat di pengaturan sistem. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | Tidak dapat memeriksa izin alarm yang tepat. Coba lagi atau aktifkan alarm & pengingat di pengaturan sistem. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | Hanafi | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | Otomatis | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | Tidak ada | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | Tengah malam | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | Sepertujuh | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | Berbasis sudut | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | Terbaik untuk lokasi | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | Liga Muslim Dunia | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | Mesir | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | Umm al-Qura | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | Dubai / Teluk | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | Kuwait | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | Qatar | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | Karachi | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | Komite Rukyat Hilal | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | Maroko | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | Singapura | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | Teheran | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | Turki / Diyanet | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | Otomatis | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | MWL | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | Dubai | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | Rukyat | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | Turki | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | Setidaknya satu alat harus tetap disematkan. | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | Disimpan untuk akses cepat | `lib/duas/duas_page.dart` | re-drafted (was: Simpan doa di sini untuk akses cepat) |
| `prayerNextIn` | {prayer} in {time} | {prayer} dalam {time} | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | Tampilkan lebih banyak | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, other{{count} shalat}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | Catatan | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |

## Turkish (`tr`)

File: `lib/l10n/app_tr.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | Sırayı ters çevir | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | NİSAP KONTROL EDİLMEDİ | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | Hayvan zekâtı burada hesaplanmaz, bu yüzden toplama dahil edilmedi. Lütfen yetkin bir âlime danışın. | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | Ödenen miktarı {currency} cinsinden girin | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | Klasör | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | Klasörleri yönet | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | Nisabı kontrol etmek için altın ve gümüş fiyatlarını ekleyin. Fiyatlar yüklenemedi, bu yüzden elle girin. | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | Bu hesaplama silinsin mi? | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | Kayıtlı hesaplama geçmişinizden kaldırılır. | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | tola | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | Başarısız | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | Geçti | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | Paylaşım görseli biçimi | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | Story 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | Kare 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | Klasik | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | Ayet görseli paylaşılamadı. | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | İndirilenleri grupla | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | Alfabetik göster | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | Ses bağlantısı kesildi. İnternetinizi kontrol edip tekrar deneyin. | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | Çevrimdışısınız. Bu ayeti indirin veya akışla dinlemek için yeniden bağlanın. | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | Ayet sesi oynatılamadı. | `lib/home/read.dart` |  |
| `repeatOnce` | Once | Bir kez | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count} kez | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | Sınırsız | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0,5 saniye | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | Güncelleme mevcut | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | Başlatılıyor | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | Doğrulanıyor | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | Çıkarılıyor | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | Yükleniyor | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | Başarısız | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | Kaynak | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | Uygulamayla gelir | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | İndirme kullanılamıyor | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | Yeniden düzenlemek için kutucukları sürükleyin. Kullanılabilir bir öğeyi etkin bir kutucuğun üzerine bırakarak yer değiştirin veya aşağıdaki bir öğeye dokunarak sabitleyin (en uzun süredir kullanılmayanın yerini alır). | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | Etkin gezinme çubuğu yuvaları ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | Sabitlenmemiş kullanılabilir öğeler | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | Yuva {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | Yuva {number} (kilitli merkez) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | {first} ile {second} yer değiştirdi | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | {item} gezinme çubuğundan kaldırıldı | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | {item} sabitlendi | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | {item} sabitlendi ({displaced} yerine) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | Ana pano | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | Kur'an-ı Kerim'i okuyun | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | Namaz vakitleri ve ezan | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | Sistem tercihleri | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | Zekat | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | Takvim | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count} okuyucu | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count} öğe | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | {reciter} için {surah} indirmelerinin tümü kaldırılsın mı? | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | Tüm sureler | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | İndirmeleri filtrele ve sırala | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | Kitaplığınızda hangi tilavetlerin görüneceği üzerinde daha fazla denetim | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | Tilavet veya sure ara... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | Grupla | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | Sıralama | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | Kategori | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | İçerik türü | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | Okuyucu (A → Z) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | Okuyucu (Z → A) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | Boyut (en büyük önce) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | Boyut (en küçük önce) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | Sure (1 → 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | Sure (114 → 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | Pozitif yap | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | Negatif yap | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | Bildirim izni denetimi zaman aşımına uğradı. Uygulamayı yeniden açmayı veya bildirimleri sistem ayarlarından etkinleştirmeyi deneyin. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | Bildirim izni denetlenemedi. Tekrar deneyin veya bildirimleri sistem ayarlarından etkinleştirin. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | Tam alarm izni denetimi zaman aşımına uğradı. Uygulamayı yeniden açmayı veya alarmlar ve hatırlatıcıları sistem ayarlarından etkinleştirmeyi deneyin. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | Tam alarm izni denetlenemedi. Tekrar deneyin veya alarmlar ve hatırlatıcıları sistem ayarlarından etkinleştirin. | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | Hanefi | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | Otomatik | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | Yok | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | Gecenin ortası | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | Yedide bir | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | Açı tabanlı | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | Konum için en uygun | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | Müslüman Dünya Ligi | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | Mısır | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | Ümmü’l-Kurâ | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | Dubai / Körfez | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | Kuveyt | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | Katar | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | Karaçi | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | Hilal Gözlem Komitesi | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | Fas | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | Singapur | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | Tahran | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | Türkiye / Diyanet | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | Otomatik | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | MWL | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | Dubai | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | Hilal | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | Türkiye | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | En az bir araç sabitlenmiş kalmalıdır. | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | Hızlı erişim için kaydedildi | `lib/duas/duas_page.dart` | re-drafted (was: Hızlı erişim için duaları buraya kaydedin) |
| `prayerNextIn` | {prayer} in {time} | {prayer} {time} içinde | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | Daha fazla göster | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, other{{count} namaz}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | Not | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |

## Urdu (RTL) (`ur`)

File: `lib/l10n/app_ur.arb`. 97 new keys, 1 re-drafted, the 4 older drafts (`prayerNextIn`, `showMore`, `prayersCount`, `note`), plus `goldPriceGram` / `silverPriceGram` (see above).

| Key | English | Draft | Where it appears | Notes |
|---|---|---|---|---|
| `reverseOrder` | Reverse order | ترتیب الٹیں | `lib/home/main_page.dart` |  |
| `zakatNisabNotChecked` | NISAB NOT CHECKED | نصاب کی جانچ نہیں ہوئی | `lib/zakat/zakat_page.dart` |  |
| `zakatLivestockNotCalculated` | Livestock is not calculated here, so it is left out of the total. Please ask a qualified scholar. | مویشیوں کی زکوٰۃ یہاں شمار نہیں کی جاتی، اس لیے کل میں شامل نہیں۔ براہِ کرم کسی مستند عالم سے پوچھیں۔ | `lib/zakat/zakat_page.dart` (Livestock card) |  |
| `enterPaidAmountInCurrency` | Enter paid amount in {currency} | ادا شدہ رقم {currency} میں درج کریں | `lib/zakat/zakat_page.dart` | placeholders: `{currency}` |
| `savedFolderLabel` | Folder | فولڈر | `lib/widgets/favourites_list.dart` |  |
| `savedManageFolders` | Manage folders | فولڈرز کا انتظام | `lib/widgets/favourites_list.dart` |  |
| `zakatNisabNeedsRates` | Add the gold and silver rates to check the Nisab. They could not be loaded, so enter them manually. | نصاب جانچنے کے لیے سونے اور چاندی کے ریٹ درج کریں۔ ریٹ لوڈ نہیں ہو سکے، اس لیے خود درج کریں۔ | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordQuestion` | Delete this calculation? | یہ حساب حذف کریں؟ | `lib/zakat/zakat_page.dart` |  |
| `zakatDeleteRecordBody` | This removes the saved calculation from your history. | محفوظ شدہ حساب آپ کی تاریخ سے ہٹا دیا جائے گا۔ | `lib/zakat/zakat_page.dart` |  |
| `unitTola` | tola | تولہ | `lib/zakat/zakat_widgets.dart`, `lib/zakat/zakat_page.dart` |  |
| `hifzRatingFail` | Fail | ناکام | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `hifzRatingPass` | Pass | کامیاب | `lib/hifz/pages/hifz_session_page.dart`, `lib/hifz/pages/hifz_complete_screen.dart` |  |
| `shareImageFormat` | Share image format | شیئر کی جانے والی تصویر کا فارمیٹ | `lib/home/read.dart` |  |
| `shareFormatStory` | Story 9:16 | اسٹوری 9:16 | `lib/home/read.dart` |  |
| `shareFormatSquare` | Square 1:1 | چوکور 1:1 | `lib/home/read.dart` |  |
| `shareFormatClassic` | Classic | کلاسک | `lib/home/read.dart` |  |
| `unableToShareAyahImage` | Unable to share ayah image. | آیت کی تصویر شیئر نہیں کی جا سکی۔ | `lib/home/read.dart` |  |
| `reciterGroupDownloaded` | Group Downloaded | ڈاؤن لوڈ شدہ کو گروپ کریں | `lib/home/read.dart` |  |
| `reciterShowAlphabetical` | Show Alphabetical | حروفِ تہجی کی ترتیب میں دکھائیں | `lib/home/read.dart` |  |
| `audioConnectionInterrupted` | Audio connection was interrupted. Check your internet and try again. | آڈیو کنکشن منقطع ہو گیا۔ اپنا انٹرنیٹ چیک کریں اور دوبارہ کوشش کریں۔ | `lib/home/read.dart` |  |
| `offlineDownloadAyahOrReconnect` | You are offline. Download this ayah or reconnect to stream it. | آپ آف لائن ہیں۔ اس آیت کو ڈاؤن لوڈ کریں یا اسٹریم کرنے کے لیے دوبارہ کنیکٹ کریں۔ | `lib/home/read.dart` |  |
| `unableToPlayAyahAudio` | Unable to play ayah audio. | آیت کی آڈیو نہیں چلائی جا سکی۔ | `lib/home/read.dart` |  |
| `repeatOnce` | Once | ایک بار | `lib/home/read.dart` |  |
| `repeatTimes` | {count} times | {count} بار | `lib/home/read.dart` | placeholders: `{count}` |
| `repeatInfinite` | Infinite | لامحدود | `lib/home/read.dart` |  |
| `halfSecond` | 0.5 seconds | 0.5 سیکنڈ | `lib/home/read.dart` |  |
| `resourceStateUpdateAvailable` | Update available | اپ ڈیٹ دستیاب ہے | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseStarting` | Starting | شروع ہو رہا ہے | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseVerifying` | Verifying | تصدیق ہو رہی ہے | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseExtracting` | Extracting | نکالا جا رہا ہے | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseInstalling` | Installing | انسٹال ہو رہا ہے | `lib/utils/resource_labels.dart` |  |
| `resourcePhaseFailed` | Failed | ناکام | `lib/utils/resource_labels.dart` |  |
| `resourceTypeGeneric` | Resource | وسیلہ | `lib/utils/resource_labels.dart` |  |
| `translationBundled` | Bundled | ایپ کے ساتھ شامل | `lib/utils/resource_labels.dart` |  |
| `translationDownloadUnavailable` | Download unavailable | ڈاؤن لوڈ دستیاب نہیں | `lib/utils/resource_labels.dart` |  |
| `navigationSettingsHint` | Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used). | ترتیب بدلنے کے لیے ٹائلز کو گھسیٹیں۔ کسی دستیاب آئٹم کو فعال ٹائل پر چھوڑ کر ان کی جگہ بدلیں، یا نیچے کسی آئٹم پر ٹیپ کر کے اسے پن کریں (سب سے کم حالیہ استعمال شدہ آئٹم ہٹ جائے گا)۔ | `lib/home/navigation_settings_page.dart` |  |
| `navigationActiveSlots` | Active navbar slots ({count}/{max}) | فعال نیویگیشن بار سلاٹس ({count}/{max}) | `lib/home/navigation_settings_page.dart` | placeholders: `{count}`, `{max}` |
| `navigationAvailableItems` | Available unpinned items | دستیاب غیر پن شدہ آئٹمز | `lib/home/navigation_settings_page.dart` |  |
| `navigationSlot` | Slot {number} | سلاٹ {number} | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSlotLocked` | Slot {number} (Locked Hub) | سلاٹ {number} (مقفل ہب) | `lib/home/navigation_settings_page.dart` | placeholders: `{number}` |
| `navigationSwapped` | Swapped {first} with {second} | {first} اور {second} کی جگہ بدل دی گئی | `lib/home/navigation_settings_page.dart` | placeholders: `{first}`, `{second}` |
| `navigationRemoved` | Removed {item} from navbar | {item} کو نیویگیشن بار سے ہٹا دیا گیا | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinned` | Pinned {item} | {item} پن کر دیا گیا | `lib/home/navigation_settings_page.dart` | placeholders: `{item}` |
| `navigationPinnedDisplaced` | Pinned {item} (displaced {displaced}) | {item} پن کر دیا گیا ({displaced} ہٹا دیا گیا) | `lib/home/navigation_settings_page.dart` | placeholders: `{displaced}`, `{item}` |
| `navSubtitleHome` | Main Dashboard | مرکزی ڈیش بورڈ | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleQuran` | Read the Holy Quran | قرآنِ پاک پڑھیں | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitlePrayer` | Prayer Times & Adhan | نماز کے اوقات اور اذان | `lib/home/navigation_settings_page.dart` |  |
| `navSubtitleSettings` | System Preferences | سسٹم ترجیحات | `lib/home/navigation_settings_page.dart` |  |
| `dockZakat` | Zakat | زکوٰۃ | `lib/home/home.dart` |  |
| `dockCalendar` | Calendar | کیلنڈر | `lib/home/home.dart` |  |
| `downloadsReciterCount` | {count, plural, =1{1 reciter} other{{count} reciters}} | {count, plural, =1{1 قاری} other{{count} قاری}} | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsItemCount` | {count, plural, =1{1 item} other{{count} items}} | {count, plural, =1{1 آئٹم} other{{count} آئٹمز}} | `lib/home/downloads.dart` | placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `downloadsDeleteReciterBody` | Remove all downloads for {reciter} on {surah}? | {reciter} کے لیے {surah} کی تمام ڈاؤن لوڈز ہٹا دیں؟ | `lib/home/downloads.dart` | placeholders: `{reciter}`, `{surah}` |
| `downloadsAllSurahs` | All Surahs | تمام سورتیں | `lib/home/downloads.dart` |  |
| `downloadsFilterTitle` | Filter & Sort Downloads | ڈاؤن لوڈز فلٹر اور ترتیب دیں | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSubtitle` | More control over which recitations appear in your library | آپ کی لائبریری میں کون سی تلاوتیں نظر آئیں، اس پر مزید کنٹرول | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsFilterSearchHint` | Search recitations or surahs... | تلاوتیں یا سورتیں تلاش کریں... | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsGroupBy` | Group by | گروپ بندی بلحاظ | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortBy` | Sort by | ترتیب بلحاظ | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsCategory` | Category | زمرہ | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsContentType` | Content type | مواد کی قسم | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterAsc` | Reciter (A → Z) | قاری (ا ← ی) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortReciterDesc` | Reciter (Z → A) | قاری (ی ← ا) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeDesc` | Size (largest first) | سائز (سب سے بڑا پہلے) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSizeAsc` | Size (smallest first) | سائز (سب سے چھوٹا پہلے) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahAsc` | Surah (1 → 114) | سورہ (1 ← 114) | `lib/home/downloads_filter_sheet.dart` |  |
| `downloadsSortSurahDesc` | Surah (114 → 1) | سورہ (114 ← 1) | `lib/home/downloads_filter_sheet.dart` |  |
| `offsetSetPositive` | Set positive | مثبت کریں | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `offsetSetNegative` | Set negative | منفی کریں | `lib/prayer/prayer_settings_dialogs.dart` |  |
| `notificationPermissionCheckTimedOut` | Notification permission check timed out. Try reopening the app or enabling notifications in system settings. | نوٹیفکیشن کی اجازت کی جانچ کا وقت ختم ہو گیا۔ ایپ دوبارہ کھولیں یا سسٹم سیٹنگز میں نوٹیفکیشنز فعال کریں۔ | `lib/prayer/prayer_times_settings_page.dart` |  |
| `notificationPermissionCheckFailed` | Could not check notification permission. Try again or enable notifications in system settings. | نوٹیفکیشن کی اجازت چیک نہیں ہو سکی۔ دوبارہ کوشش کریں یا سسٹم سیٹنگز میں نوٹیفکیشنز فعال کریں۔ | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckTimedOut` | Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings. | درست الارم کی اجازت کی جانچ کا وقت ختم ہو گیا۔ ایپ دوبارہ کھولیں یا سسٹم سیٹنگز میں الارم اور ریمائنڈرز فعال کریں۔ | `lib/prayer/prayer_times_settings_page.dart` |  |
| `exactAlarmPermissionCheckFailed` | Could not check exact alarm permission. Try again or enable alarms & reminders in system settings. | درست الارم کی اجازت چیک نہیں ہو سکی۔ دوبارہ کوشش کریں یا سسٹم سیٹنگز میں الارم اور ریمائنڈرز فعال کریں۔ | `lib/prayer/prayer_times_settings_page.dart` |  |
| `asrMethodHanafi` | Hanafi | حنفی | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAutoTitle` | Auto | خودکار | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleNoneTitle` | None | کوئی نہیں | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleMiddleOfTheNightTitle` | Middle of the night | رات کا درمیان | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleOneSeventhTitle` | One seventh | ساتواں حصہ | `lib/prayer/prayer_localizations.dart` |  |
| `highLatitudeRuleAngleBasedTitle` | Angle based | زاویے پر مبنی | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodAuto` | Best for location | مقام کے لیے بہترین | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMuslimWorldLeague` | Muslim World League | مسلم ورلڈ لیگ | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodEgyptian` | Egyptian | مصری | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodUmmAlQura` | Umm al-Qura | ام القریٰ | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodDubai` | Dubai / Gulf | دبئی / خلیج | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKuwait` | Kuwait | کویت | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodQatar` | Qatar | قطر | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodKarachi` | Karachi | کراچی | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMoonsighting` | Moonsighting Committee | رویتِ ہلال کمیٹی | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodMorocco` | Morocco | مراکش | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodSingapore` | Singapore | سنگاپور | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTehran` | Tehran | تہران | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodTurkey` | Turkey / Diyanet | ترکی / دیانت | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortAuto` | Auto | خودکار | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMwl` | MWL | MWL | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortDubai` | Dubai | دبئی | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortMoonsighting` | Moonsighting | رویتِ ہلال | `lib/prayer/prayer_localizations.dart` |  |
| `prayerMethodShortTurkey` | Turkey | ترکی | `lib/prayer/prayer_localizations.dart` |  |
| `dailyToolsKeepOnePinned` | At least one tool must remain pinned. | کم از کم ایک ٹول پن شدہ رہنا چاہیے۔ | `lib/home_dashboard/daily_tools_edit_sheet.dart` |  |
| `saveDuasHere` | Saved for quick access | فوری رسائی کے لیے محفوظ | `lib/duas/duas_page.dart` | re-drafted (was: فوری رسائی کے لیے دعائیں یہاں محفوظ کریں۔) |
| `prayerNextIn` | {prayer} in {time} | {prayer} {time} میں | `lib/prayer/prayer_localizations.dart` | older machine draft (added before the diff base); placeholders: `{prayer}`, `{time}` |
| `showMore` | Show more | مزید دکھائیں | `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
| `prayersCount` | {count, plural, =1{1 prayer} other{{count} prayers}} | {count, plural, other{{count} نمازیں}} | `lib/home/statistics_redesign.dart` | older machine draft (added before the diff base); placeholders: `{count}`; ICU plural: keep the `{count, plural, ...}` structure; `=0`/`=1`/`one`/`other` (Arabic needs `zero`/`one`/`two`/`few`/`many`/`other`) |
| `note` | Note | نوٹ | `lib/widgets/reader_sheets.dart`, `lib/widgets/favourites_list.dart` | older machine draft (added before the diff base) |
