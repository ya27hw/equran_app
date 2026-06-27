package com.app.equran

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.TimeZone
import java.util.Calendar

class BootReceiver: BroadcastReceiver() {

  override fun onReceive(
    context: Context,
    intent: Intent) {

    if (intent.action !=
      Intent.ACTION_BOOT_COMPLETED &&
      intent.action !=
      "android.intent.action.QUICKBOOT_POWERON")
      return

    // Read last known prayer times from
    // SharedPreferences — these were saved
    // by the Flutter app last time it ran.
    // On first boot after install they
    // won't exist, but after first app open
    // they will persist across reboots.
    val prefs = context.getSharedPreferences(
      "FlutterSharedPreferences",
      Context.MODE_PRIVATE)

    // home_widget saves to specific prefs
    // file — read from there directly.
    // key prefix used by home_widget is
    // "flutter." prepended to each key.
    val hwPrefs = context.getSharedPreferences(
      "HomeWidgetPreferences",
      Context.MODE_PRIVATE)

    val fajr = hwPrefs.getString(
      "fajr_time", null)

    if (fajr != null) {
      // Data exists from before reboot —
      // trigger widget redraw with existing data
      CoroutineScope(Dispatchers.Main).launch {
        PrayerTimesWidget().updateAll(context)
        NextPrayerWidget().updateAll(context)
      }
      PrayerAlarmScheduler.scheduleNext(context)
    } else {
      // No data yet — compute native prayer
      // times using stored coordinates
      // and update widget natively
      _computeAndUpdateNative(context, hwPrefs)
    }
  }

  private fun _computeAndUpdateNative(
    context: Context,
    prefs: SharedPreferences) {

    // Read stored coordinates
    val lat = prefs.getString(
      "widget_lat", null)
      ?.toDoubleOrNull() ?: return
    val lng = prefs.getString(
      "widget_lng", null)
      ?.toDoubleOrNull() ?: return

    // Use simple sun angle calculation
    // to approximate prayer times natively
    // without the Dart adhan_dart package.
    // This is only fallback for boot —
    // the Flutter app will correct it on
    // first open.

    // Get current local time
    val tz = TimeZone.getDefault()
    val cal = Calendar.getInstance(tz)
    val offsetHours = tz.rawOffset / 3600000.0

    // Simple fixed offset approximation
    // based on longitude (solar noon offset)
    // Longitude offset from UTC in hours
    val lonOffset = lng / 15.0
    val solarNoon = 12.0 - lonOffset +
      (tz.rawOffset / 3600000.0 - lonOffset)

    // Approximate prayer times relative
    // to solar noon (rough but usable)
    fun toTimeStr(decimalHour: Double): String {
      val h = decimalHour.toInt()
        .coerceIn(0, 23)
      val m = ((decimalHour - h) * 60)
        .toInt().coerceIn(0, 59)
      return "${h.toString().padStart(2,'0')}:" +
        "${m.toString().padStart(2,'0')}"
    }

    val sunriseTime = toTimeStr(solarNoon - 5.5)
    val fajrTime = toTimeStr(solarNoon - 6.0)
    val dhuhrTime = toTimeStr(solarNoon)
    val asrTime = toTimeStr(solarNoon + 3.5)
    val maghribTime = toTimeStr(solarNoon + 6.5)
    val ishaTime = toTimeStr(solarNoon + 8.0)

    // Determine next prayer
    val nowHour = cal.get(Calendar.HOUR_OF_DAY) +
      cal.get(Calendar.MINUTE) / 60.0
    val nextPrayer = when {
      nowHour < solarNoon - 6.0 -> "fajr"
      nowHour < solarNoon - 5.5 -> "sunrise"
      nowHour < solarNoon -> "dhuhr"
      nowHour < solarNoon + 3.5 -> "asr"
      nowHour < solarNoon + 6.5 -> "maghrib"
      nowHour < solarNoon + 8.0 -> "isha"
      else -> "fajr"
    }

    val nextPrayerTime = when (nextPrayer) {
      "fajr" -> fajrTime
      "sunrise" -> sunriseTime
      "dhuhr" -> dhuhrTime
      "asr" -> asrTime
      "maghrib" -> maghribTime
      "isha" -> ishaTime
      else -> fajrTime
    }

    // Write to HomeWidget SharedPreferences
    // using exact same keys as Flutter
    prefs.edit().apply {
      putString("fajr_time", fajrTime)
      putString("dhuhr_time", dhuhrTime)
      putString("asr_time", asrTime)
      putString("maghrib_time", maghribTime)
      putString("isha_time", ishaTime)
      putString("sunrise_time", sunriseTime)
      putString("next_prayer", nextPrayer)
      putString("next_prayer_time", nextPrayerTime)
      putString("location_name","")
      putString("last_updated", toTimeStr(nowHour))
      apply()
    }

    // Trigger widget redraw
    CoroutineScope(Dispatchers.Main).launch {
      PrayerTimesWidget().updateAll(context)
      NextPrayerWidget().updateAll(context)
    }
    PrayerAlarmScheduler.scheduleNext(context)
  }
}
