package dev.casraf.pantry

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

class PantryWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        PantryWidgetFactory(applicationContext)
}

private class PantryWidgetFactory(
    private val ctx: Context,
) : RemoteViewsService.RemoteViewsFactory {

    data class ListEntry(
        val id: Int,
        val name: String,
        val houseId: Int,
        val houseName: String?,
        val iconKey: String?,
        val unchecked: Int?,
        val total: Int?,
    )

    private var items: List<ListEntry> = emptyList()
    private var itemColor: Int = 0
    private var pillRes: Int = R.drawable.widget_count_pill_light
    private var showHouseSubtitle: Boolean = false

    override fun onCreate() = load()
    override fun onDataSetChanged() = load()
    override fun onDestroy() {}

    private fun load() {
        val isDark = WidgetTheme.isDark(ctx)
        itemColor = ContextCompat.getColor(
            ctx,
            if (isDark) R.color.widget_fg_dark else R.color.widget_fg_light,
        )
        pillRes = if (isDark) {
            R.drawable.widget_count_pill_dark
        } else {
            R.drawable.widget_count_pill_light
        }

        // home_widget stores data in HomeWidgetPreferences SharedPreferences.
        val prefs = ctx.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("pinned_lists", "[]") ?: "[]"
        items = try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                ListEntry(
                    id = obj.getInt("id"),
                    name = obj.getString("name"),
                    houseId = obj.getInt("houseId"),
                    houseName = obj.optStringOrNull("houseName"),
                    iconKey = obj.optStringOrNull("icon"),
                    unchecked = obj.optIntOrNull("unchecked"),
                    total = obj.optIntOrNull("total"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
        // Show the house subtitle on each row only if the pinned set spans
        // more than one house — otherwise it's noise.
        showHouseSubtitle = items.map { it.houseId }.distinct().size > 1
    }

    override fun getCount() = items.size
    override fun getViewTypeCount() = 1
    override fun hasStableIds() = true
    override fun getItemId(pos: Int) = items[pos].id.toLong()
    override fun getLoadingView(): RemoteViews? = null

    override fun getViewAt(pos: Int): RemoteViews {
        val item = items[pos]
        val rv = RemoteViews(ctx.packageName, R.layout.widget_item)

        rv.setTextViewText(R.id.widget_item_name, item.name)
        rv.setTextColor(R.id.widget_item_name, itemColor)

        rv.setImageViewResource(R.id.widget_item_icon, iconDrawableFor(item.iconKey))
        rv.setInt(R.id.widget_item_icon, "setColorFilter", itemColor)

        if (showHouseSubtitle && !item.houseName.isNullOrEmpty()) {
            rv.setTextViewText(R.id.widget_item_house, item.houseName)
            rv.setTextColor(R.id.widget_item_house, itemColor)
            rv.setViewVisibility(R.id.widget_item_house, android.view.View.VISIBLE)
        } else {
            rv.setViewVisibility(R.id.widget_item_house, android.view.View.GONE)
        }

        if (item.total != null && item.unchecked != null) {
            rv.setTextViewText(
                R.id.widget_item_count,
                "${item.unchecked}/${item.total}",
            )
            rv.setTextColor(R.id.widget_item_count, itemColor)
            rv.setInt(R.id.widget_item_count, "setBackgroundResource", pillRes)
            rv.setViewVisibility(R.id.widget_item_count, android.view.View.VISIBLE)
        } else {
            rv.setViewVisibility(R.id.widget_item_count, android.view.View.GONE)
        }

        // Fill-in intent merged with the template set in PantryWidgetProvider.
        val fillIn = Intent().apply {
            putExtra("list_id", item.id)
            putExtra("house_id", item.houseId)
        }
        rv.setOnClickFillInIntent(R.id.widget_item_root, fillIn)
        return rv
    }

    private fun iconDrawableFor(key: String?): Int {
        if (key == null) return R.drawable.widget_icon_default
        // Resource names use underscores; checklist icon keys use hyphens.
        val resName = "widget_icon_${key.replace('-', '_')}"
        val id = ctx.resources.getIdentifier(resName, "drawable", ctx.packageName)
        return if (id != 0) id else R.drawable.widget_icon_default
    }
}

private fun JSONObject.optStringOrNull(key: String): String? =
    if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }

private fun JSONObject.optIntOrNull(key: String): Int? =
    if (isNull(key) || !has(key)) null else optInt(key)
