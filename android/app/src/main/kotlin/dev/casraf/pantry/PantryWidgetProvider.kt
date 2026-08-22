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

class PantryWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) updateWidget(ctx, mgr, id)
    }

    override fun onDeleted(ctx: Context, ids: IntArray) {
        val prefs = ctx.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        prefs.edit().apply {
            for (id in ids) remove("lists_widget_$id")
        }.apply()
    }

    companion object {
        /// App widget ids for every placed instance of this provider.
        fun widgetIds(ctx: Context): IntArray =
            AppWidgetManager.getInstance(ctx).getAppWidgetIds(
                ComponentName(ctx, PantryWidgetProvider::class.java),
            )

        fun updateWidget(ctx: Context, mgr: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(ctx.packageName, R.layout.widget_pantry)

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

            // Adapter intent — URI must be unique per widget ID so Android
            // doesn't reuse a stale factory for a different widget instance,
            // and must change between updates so Android recreates the
            // factory (otherwise the cached RemoteViewsFactory keeps serving
            // stale rows after the underlying SharedPrefs change).
            val serviceIntent = Intent(ctx, PantryWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                putExtra("update_token", System.currentTimeMillis())
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list, serviceIntent)
            views.setEmptyView(R.id.widget_list, R.id.widget_empty)

            // Template intent: each list item fills in list_id + house_id via
            // setOnClickFillInIntent, then Android merges it with this template.
            val templateIntent = Intent(ctx, MainActivity::class.java).apply {
                action = "dev.casraf.pantry.OPEN_LIST"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingTemplate = PendingIntent.getActivity(
                ctx,
                widgetId,
                templateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.widget_list, pendingTemplate)

            // Header cog: reconfigure this widget's list selection by opening
            // the same config activity used when the widget is added.
            val configIntent = Intent(ctx, WidgetConfigActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                // Unique data so distinct widgets don't share one PendingIntent.
                data = Uri.parse("pantry-widget://configure/$widgetId")
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
