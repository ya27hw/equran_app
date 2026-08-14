package com.app.equran

import android.content.Context
import androidx.compose.ui.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin

internal data class PrayerWidgetPalette(
  val bgColor: Color,
  val surfaceColor: Color,
  val primaryColor: Color,
  val primaryStrongColor: Color,
  val textColor: Color,
  val textSecondaryColor: Color,
  val textMutedColor: Color,
  val goldColor: Color,
  val borderColor: Color,
  val onPrimaryColor: Color,
)

internal data class PrayerWidgetLabels(
  val headerLabel: String,
  val fajrLabel: String,
  val sunriseLabel: String,
  val dhuhrLabel: String,
  val asrLabel: String,
  val maghribLabel: String,
  val ishaLabel: String,
  val updatedLabel: String,
  val placeholderLabel: String,
)

internal data class PrayerWidgetState(
  val fajr: String?,
  val sunrise: String,
  val dhuhr: String,
  val asr: String,
  val maghrib: String,
  val isha: String,
  val next: String,
  val nextTime: String,
  val loc: String,
  val updated: String,
  val palette: PrayerWidgetPalette,
  val labels: PrayerWidgetLabels,
)

internal fun loadPrayerWidgetState(context: Context): PrayerWidgetState {
  val prefs = HomeWidgetPlugin.getData(context)

  val themeMode = prefs.getString("theme_mode", "auto") ?: "auto"
  val isSystemDark = (context.resources.configuration.uiMode and
      android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
      android.content.res.Configuration.UI_MODE_NIGHT_YES

  val isDarkMode = when (themeMode) {
      "dark" -> true
      "light" -> false
      else -> prefs.getBoolean("is_dark_mode", isSystemDark)
  }

  val bgKey = if (isDarkMode) "w_bg_dark" else "w_bg_light"
  val surfaceKey = if (isDarkMode) "w_surface_dark" else "w_surface_light"
  val primaryKey = if (isDarkMode) "w_primary_dark" else "w_primary_light"
  val primaryStrongKey = if (isDarkMode) "w_primary_strong_dark" else "w_primary_strong_light"
  val textKey = if (isDarkMode) "w_text_dark" else "w_text_light"
  val textSecKey = if (isDarkMode) "w_text_sec_dark" else "w_text_sec_light"
  val textMutedKey = if (isDarkMode) "w_text_muted_dark" else "w_text_muted_light"
  val goldKey = if (isDarkMode) "w_gold_dark" else "w_gold_light"
  val borderKey = if (isDarkMode) "w_border_dark" else "w_border_light"
  val onPrimaryKey = if (isDarkMode) "w_on_primary_dark" else "w_on_primary_light"

  val defaultBg = if (isDarkMode) "FF07110E" else "FFFAFAF7"
  val defaultSurface = if (isDarkMode) "FF111A17" else "FFFFFFFF"
  val defaultPrimary = if (isDarkMode) "FF1E7A61" else "FF176B55"
  val defaultPrimaryStrong = if (isDarkMode) "FF125B49" else "FF145D4A"
  val defaultText = if (isDarkMode) "FFF3F7F4" else "FF1E2420"
  val defaultTextSec = if (isDarkMode) "FFB8C2BC" else "FF69716B"
  val defaultTextMuted = if (isDarkMode) "FF83908A" else "FF8A918B"
  val defaultGold = "FFD6A84F"
  val defaultBorder = if (isDarkMode) "FF26332E" else "FFE5E7DF"
  val defaultOnPrimary = "FFFFFFFF"

  val bgColorStr = prefs.getString(bgKey, null) ?: prefs.getString("w_bg", null) ?: defaultBg
  val surfaceColorStr = prefs.getString(surfaceKey, null) ?: prefs.getString("w_surface", null) ?: defaultSurface
  val primaryColorStr = prefs.getString(primaryKey, null) ?: prefs.getString("w_primary", null) ?: defaultPrimary
  val primaryStrongColorStr = prefs.getString(primaryStrongKey, null) ?: prefs.getString("w_primary_strong", null) ?: defaultPrimaryStrong
  val textColorStr = prefs.getString(textKey, null) ?: prefs.getString("w_text", null) ?: defaultText
  val textSecondaryColorStr = prefs.getString(textSecKey, null) ?: prefs.getString("w_text_sec", null) ?: defaultTextSec
  val textMutedColorStr = prefs.getString(textMutedKey, null) ?: prefs.getString("w_text_muted", null) ?: defaultTextMuted
  val goldColorStr = prefs.getString(goldKey, null) ?: prefs.getString("w_gold", null) ?: defaultGold
  val borderColorStr = prefs.getString(borderKey, null) ?: prefs.getString("w_border", null) ?: defaultBorder
  val onPrimaryColorStr = prefs.getString(onPrimaryKey, null) ?: prefs.getString("w_on_primary", null) ?: defaultOnPrimary

  val palette = PrayerWidgetPalette(
    bgColor = hexToColor(bgColorStr),
    surfaceColor = hexToColor(surfaceColorStr),
    primaryColor = hexToColor(primaryColorStr),
    primaryStrongColor = hexToColor(primaryStrongColorStr),
    textColor = hexToColor(textColorStr),
    textSecondaryColor = hexToColor(textSecondaryColorStr),
    textMutedColor = hexToColor(textMutedColorStr),
    goldColor = hexToColor(goldColorStr),
    borderColor = hexToColor(borderColorStr),
    onPrimaryColor = hexToColor(onPrimaryColorStr),
  )

  val labels = PrayerWidgetLabels(
    headerLabel = prefs.getString("label_header", "Prayer Times") ?: "Prayer Times",
    fajrLabel = prefs.getString("label_fajr", "Fajr") ?: "Fajr",
    sunriseLabel = prefs.getString("label_sunrise", "Sunrise") ?: "Sunrise",
    dhuhrLabel = prefs.getString("label_dhuhr", "Dhuhr") ?: "Dhuhr",
    asrLabel = prefs.getString("label_asr", "Asr") ?: "Asr",
    maghribLabel = prefs.getString("label_maghrib", "Maghrib") ?: "Maghrib",
    ishaLabel = prefs.getString("label_isha", "Isha") ?: "Isha",
    updatedLabel = prefs.getString("label_updated", "Updated") ?: "Updated",
    placeholderLabel = prefs.getString(
      "label_placeholder",
      "Tap to load prayer times"
    ) ?: "Tap to load prayer times",
  )

  return PrayerWidgetState(
    fajr = prefs.getString("fajr_time", null),
    sunrise = prefs.getString("sunrise_time", "---") ?: "---",
    dhuhr = prefs.getString("dhuhr_time", "---") ?: "---",
    asr = prefs.getString("asr_time", "---") ?: "---",
    maghrib = prefs.getString("maghrib_time", "---") ?: "---",
    isha = prefs.getString("isha_time", "---") ?: "---",
    next = prefs.getString("next_prayer", "") ?: "",
    nextTime = prefs.getString("next_prayer_time", "") ?: "",
    loc = prefs.getString("location_name", "") ?: "",
    updated = prefs.getString("last_updated", "") ?: "",
    palette = palette,
    labels = labels,
  )
}

internal fun hexToColor(hex: String): Color {
  val normalized = hex.removePrefix("#")
  return Color(android.graphics.Color.parseColor("#$normalized"))
}

internal fun prayerLabelForId(id: String, labels: PrayerWidgetLabels): String {
  return when (id) {
    "fajr" -> labels.fajrLabel
    "sunrise" -> labels.sunriseLabel
    "dhuhr" -> labels.dhuhrLabel
    "asr" -> labels.asrLabel
    "maghrib" -> labels.maghribLabel
    "isha" -> labels.ishaLabel
    else -> ""
  }
}

internal fun prayerTimeForId(state: PrayerWidgetState, prayerId: String): String {
  return when (prayerId) {
    "fajr" -> state.fajr ?: "---"
    "sunrise" -> state.sunrise
    "dhuhr" -> state.dhuhr
    "asr" -> state.asr
    "maghrib" -> state.maghrib
    "isha" -> state.isha
    else -> "---"
  }
}

internal fun headerSupportingLine(loc: String, updatedLabel: String, updated: String): String {
  val trimmedLoc = loc.trim()
  if (trimmedLoc.length in 1..16) {
    return trimmedLoc
  }
  if (updated.isNotEmpty()) {
    return "$updatedLabel $updated"
  }
  return ""
}

internal fun compactSupportingLine(loc: String, updated: String): String {
  val trimmedLoc = loc.trim()
  if (trimmedLoc.length in 1..18) {
    return trimmedLoc
  }
  if (updated.length in 1..10) {
    return updated
  }
  return ""
}
