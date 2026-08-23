package dev.casraf.pantry

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

class ChecklistWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        return ChecklistWidgetFactory(applicationContext, widgetId)
    }
}

private const val TYPE_ITEM = 0
private const val TYPE_HEADER = 1

private class ChecklistWidgetFactory(
    private val ctx: Context,
    private val widgetId: Int,
) : RemoteViewsService.RemoteViewsFactory {

    private var rows: JSONArray = JSONArray()
    private var houseId: Int = -1
    private var listId: Int = -1
    private var locked: Boolean = false
    private var fg: Int = 0
    private var pillRes: Int = R.drawable.widget_count_pill_light

    override fun onCreate() = load()
    override fun onDataSetChanged() = load()
    override fun onDestroy() {}

    private fun load() {
        val isDark = WidgetTheme.isDark(ctx)
        fg = ContextCompat.getColor(
            ctx,
            if (isDark) R.color.widget_fg_dark else R.color.widget_fg_light,
        )
        pillRes = if (isDark) {
            R.drawable.widget_count_pill_dark
        } else {
            R.drawable.widget_count_pill_light
        }
        val prefs = ctx.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("checklist_widget_$widgetId", null)
        rows = try {
            val obj = JSONObject(json ?: "{}")
            houseId = obj.optInt("houseId", -1)
            listId = obj.optInt("listId", -1)
            locked = obj.optBoolean("locked", false)
            obj.optJSONArray("rows") ?: JSONArray()
        } catch (_: Exception) {
            houseId = -1
            listId = -1
            locked = false
            JSONArray()
        }
    }

    override fun getCount() = rows.length()
    override fun getViewTypeCount() = 2
    override fun hasStableIds() = false
    override fun getItemId(pos: Int) = pos.toLong()
    override fun getLoadingView(): RemoteViews? = null

    override fun getViewAt(pos: Int): RemoteViews {
        val row = rows.optJSONObject(pos) ?: return RemoteViews(
            ctx.packageName,
            R.layout.widget_checklist_header,
        )
        return when (row.optString("t")) {
            "item" -> itemView(row)
            "done" -> headerView(
                "${ctx.getString(R.string.widget_done)} · ${row.optInt("count")}",
                null,
            )
            else -> headerView(row.optString("label"), row.optStringOrNull("color"))
        }
    }

    private fun headerView(label: String, colorHex: String?): RemoteViews {
        val rv = RemoteViews(ctx.packageName, R.layout.widget_checklist_header)
        rv.setTextViewText(R.id.widget_header_label, label)
        rv.setTextColor(R.id.widget_header_label, parseColor(colorHex) ?: fg)
        return rv
    }

    private fun itemView(row: JSONObject): RemoteViews {
        val rv = RemoteViews(ctx.packageName, R.layout.widget_checklist_item)
        val done = row.optBoolean("done")

        // Item text/chips only dim when done (RemoteViews.setInt can't bind
        // TextView.setAlpha, a float, so fold the alpha into each colour). The
        // checkbox dims when the widget is locked, to signal it can't be tapped.
        val alpha = if (done) 140 else 255

        rv.setTextViewText(R.id.widget_item_name, row.optString("name"))
        rv.setTextColor(R.id.widget_item_name, dim(fg, alpha))
        val flags = Paint.ANTI_ALIAS_FLAG or
            if (done) Paint.STRIKE_THRU_TEXT_FLAG else 0
        rv.setInt(R.id.widget_item_name, "setPaintFlags", flags)

        rv.setImageViewResource(
            R.id.widget_item_check,
            if (done) R.drawable.widget_check_on else R.drawable.widget_check_off,
        )
        rv.setInt(R.id.widget_item_check, "setColorFilter", fg)
        // setImageAlpha honours alpha on an ImageView; setColorFilter doesn't.
        rv.setInt(R.id.widget_item_check, "setImageAlpha", if (locked) 90 else 255)

        val pills = row.optJSONArray("pills") ?: JSONArray()
        val pillIds = intArrayOf(
            R.id.widget_item_pill1,
            R.id.widget_item_pill2,
            R.id.widget_item_pill3,
        )
        for (i in pillIds.indices) {
            val pill = pills.optJSONObject(i)
            if (pill == null) {
                rv.setViewVisibility(pillIds[i], View.GONE)
            } else {
                rv.setViewVisibility(pillIds[i], View.VISIBLE)
                rv.setTextViewText(pillIds[i], pill.optString("text"))
                rv.setTextColor(
                    pillIds[i],
                    dim(parseColor(pill.optStringOrNull("color")) ?: fg, alpha),
                )
                rv.setInt(pillIds[i], "setBackgroundResource", pillRes)
            }
        }

        // Fill-ins on the two child targets: checkbox toggles, content opens.
        // When locked, set EMPTY fill-ins (a no-op at the trampoline) rather
        // than omitting them — recycled row views keep a previously-set fill-in,
        // so the intent must be overwritten to actually disable the tap.
        val itemId = row.optInt("id")
        rv.setOnClickFillInIntent(
            R.id.widget_item_check,
            if (locked) {
                Intent()
            } else {
                Intent().apply {
                    data = Uri.parse(
                        "pantry-widget://toggle/$houseId/$listId/$itemId/$widgetId",
                    )
                }
            },
        )
        rv.setOnClickFillInIntent(
            R.id.widget_item_content,
            if (locked) {
                Intent()
            } else {
                Intent().apply {
                    data = Uri.parse("pantry-widget://open/$houseId/$listId/$itemId")
                }
            },
        )
        return rv
    }

    private fun dim(color: Int, alpha: Int): Int =
        (color and 0x00FFFFFF) or (alpha shl 24)

    // Mirrors Dart's parseHexColor: accepts "#RRGGBB", "RRGGBB" or "AARRGGBB"
    // (the app stores colours without a leading '#', which Color.parseColor
    // can't handle).
    private fun parseColor(hex: String?): Int? {
        if (hex.isNullOrEmpty()) return null
        var h = hex.removePrefix("#")
        if (h.length == 6) h = "FF$h"
        return h.toLongOrNull(16)?.toInt()
    }

    private fun JSONObject.optStringOrNull(key: String): String? =
        if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }
}
