package dev.casraf.pantry

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import androidx.core.content.ContextCompat

class PantryWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) updateWidget(ctx, mgr, id)
    }

    companion object {
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

            // Adapter intent — URI must be unique per widget ID so Android
            // doesn't reuse a stale factory for a different widget instance.
            val serviceIntent = Intent(ctx, PantryWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
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

            mgr.updateAppWidget(widgetId, views)
            mgr.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
        }
    }
}
