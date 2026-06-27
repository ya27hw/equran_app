package com.app.equran

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.glance.appwidget.updateAll
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Calendar

class PrayerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "com.app.equran.PRAYER_ALARM") return

        CoroutineScope(Dispatchers.Main).launch {
            PrayerTimesWidget().updateAll(context)
            NextPrayerWidget().updateAll(context)
        }

        PrayerAlarmScheduler.scheduleNext(context)
    }
}

object PrayerAlarmScheduler {

    private const val ACTION_PRAYER_ALARM = "com.app.equran.PRAYER_ALARM"
    private const val REQUEST_CODE = 0x7170

    fun scheduleNext(context: Context) {
        try {
            val prefs = HomeWidgetPlugin.getData(context)

            val keys = listOf(
                "fajr_time",
                "sunrise_time",
                "dhuhr_time",
                "asr_time",
                "maghrib_time",
                "isha_time",
            )

            val now = Calendar.getInstance()

            // Collect all future prayer times for today
            var earliest: Calendar? = null

            for (key in keys) {
                val timeStr = prefs.getString(key, null) ?: continue
                val cal = parseTimeToCalendar(timeStr) ?: continue

                // Skip times that have already passed
                if (!cal.after(now)) continue

                if (earliest == null || cal.before(earliest)) {
                    earliest = cal
                }
            }

            if (earliest == null) {
                // All prayers have passed for today — schedule tomorrow's Fajr
                val fajrStr = prefs.getString("fajr_time", null) ?: return
                val tomorrowFajr = parseTimeToCalendar(fajrStr) ?: return
                tomorrowFajr.add(Calendar.DAY_OF_YEAR, 1)
                earliest = tomorrowFajr
            }

            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val intent = Intent(ACTION_PRAYER_ALARM).apply {
                setPackage(context.packageName)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    earliest.timeInMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    earliest.timeInMillis,
                    pendingIntent,
                )
            }
        } catch (e: Exception) {
            // Silent no-op — scheduler must never crash the caller
        }
    }

    /**
     * Parses a prayer time string into a [Calendar] set to today at that time.
     *
     * Supports both 24-hour format ("HH:mm", e.g. "05:23", "13:45") and
     * 12-hour AM/PM format ("h:mm AM" / "h:mm PM", e.g. "5:23 AM", "1:45 PM").
     *
     * Returns null if the string cannot be parsed.
     */
    fun parseTimeToCalendar(timeStr: String): Calendar? {
        val trimmed = timeStr.trim()

        return try {
            val cal = Calendar.getInstance()

            val amPmRegex = Regex(
                """^(\d{1,2}):(\d{2})\s*(AM|PM)$""",
                RegexOption.IGNORE_CASE,
            )
            val match24 = Regex("""^(\d{1,2}):(\d{2})$""").matchEntire(trimmed)
            val matchAmPm = amPmRegex.matchEntire(trimmed)

            when {
                matchAmPm != null -> {
                    var hour = matchAmPm.groupValues[1].toInt()
                    val minute = matchAmPm.groupValues[2].toInt()
                    val period = matchAmPm.groupValues[3].uppercase()
                    if (period == "PM" && hour != 12) hour += 12
                    if (period == "AM" && hour == 12) hour = 0
                    cal.set(Calendar.HOUR_OF_DAY, hour)
                    cal.set(Calendar.MINUTE, minute)
                    cal.set(Calendar.SECOND, 0)
                    cal.set(Calendar.MILLISECOND, 0)
                    cal
                }
                match24 != null -> {
                    val hour = match24.groupValues[1].toInt()
                    val minute = match24.groupValues[2].toInt()
                    cal.set(Calendar.HOUR_OF_DAY, hour)
                    cal.set(Calendar.MINUTE, minute)
                    cal.set(Calendar.SECOND, 0)
                    cal.set(Calendar.MILLISECOND, 0)
                    cal
                }
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }
}
