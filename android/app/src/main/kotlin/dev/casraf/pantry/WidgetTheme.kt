package dev.casraf.pantry

import android.content.Context
import android.content.res.Configuration

/**
 * Resolves the widget's effective brightness from the app's saved preference
 * (written by Dart via `HomeWidget.saveWidgetData('widget_theme', ...)`).
 * Falls back to the system night-mode configuration when no preference is set
 * yet — e.g. on first install before Dart has written anything.
 */
object WidgetTheme {
    fun isDark(ctx: Context): Boolean {
        val prefs = ctx.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        return when (prefs.getString("widget_theme", null)) {
            "dark" -> true
            "light" -> false
            else -> {
                val nightFlag = ctx.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK
                nightFlag == Configuration.UI_MODE_NIGHT_YES
            }
        }
    }
}
