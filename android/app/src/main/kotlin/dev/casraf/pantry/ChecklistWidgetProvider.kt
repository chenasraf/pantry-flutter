package dev.casraf.pantry

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import org.json.JSONObject

/// Single-checklist home-screen widget: shows one list's items (active, then a
/// Done section), grouped as the checklist page groups them. Per-instance data
/// lives under `checklist_widget_<id>` in HomeWidgetPreferences.
class ChecklistWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) updateWidget(ctx, mgr, id)
    }

    override fun onDeleted(ctx: Context, ids: IntArray) {
        val prefs = ctx.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        prefs.edit().apply {
            for (id in ids) remove("checklist_widget_$id")
        }.apply()
    }

    companion object {
        fun widgetIds(ctx: Context): IntArray =
            AppWidgetManager.getInstance(ctx).getAppWidgetIds(
                ComponentName(ctx, ChecklistWidgetProvider::class.java),
            )

        fun updateWidget(ctx: Context, mgr: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(ctx.packageName, R.layout.widget_checklist)

            val isDark = WidgetTheme.isDark(ctx)
            val bg = ContextCompat.getColor(
                ctx,
                if (isDark) R.color.widget_bg_dark else R.color.widget_bg_light,
            )
            val fg = ContextCompat.getColor(
                ctx,
                if (isDark) R.color.widget_fg_dark else R.color.widget_fg_light,
            )
            views.setInt(R.id.widget_root, "setBackgroundColor", bg)
            views.setTextColor(R.id.widget_title, fg)
            views.setTextColor(R.id.widget_empty, fg)
            views.setInt(R.id.widget_config, "setColorFilter", fg)

            val prefs = ctx.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE,
            )
            val stored = prefs.getString("checklist_widget_$widgetId", null)
            val title = runCatching {
                JSONObject(stored ?: "{}").optString("listName")
            }.getOrNull()
            views.setTextViewText(
                R.id.widget_title,
                if (title.isNullOrEmpty()) ctx.getString(R.string.app_name) else title,
            )

            val serviceIntent = Intent(ctx, ChecklistWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                putExtra("update_token", System.currentTimeMillis())
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list, serviceIntent)
            views.setEmptyView(R.id.widget_list, R.id.widget_empty)

            // All row taps route through the invisible WidgetActionActivity (a
            // collection has one click template). Each row's fill-in supplies a
            // pantry-widget:// URI it acts on. A mutable template lets the
            // fill-in set that URI.
            val actionIntent = Intent(ctx, WidgetActionActivity::class.java)
            val actionTemplate = PendingIntent.getActivity(
                ctx,
                widgetId,
                actionIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.widget_list, actionTemplate)

            // Header cog opens the config screen for this widget.
            val configIntent = Intent(ctx, ChecklistWidgetConfigActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                data = Uri.parse("pantry-checklist-widget://configure/$widgetId")
            }
            val pendingConfig = PendingIntent.getActivity(
                ctx,
                widgetId,
                configIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_config, pendingConfig)

            mgr.updateAppWidget(widgetId, views)
            mgr.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
        }
    }
}
