package dev.casraf.pantry

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import org.json.JSONArray

class PantryWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        PantryWidgetFactory(applicationContext)
}

private class PantryWidgetFactory(
    private val ctx: Context,
) : RemoteViewsService.RemoteViewsFactory {

    data class ListEntry(val id: Int, val name: String, val houseId: Int)

    private var items: List<ListEntry> = emptyList()
    private var itemColor: Int = 0

    override fun onCreate() = load()
    override fun onDataSetChanged() = load()
    override fun onDestroy() {}

    private fun load() {
        itemColor = ContextCompat.getColor(
            ctx,
            if (WidgetTheme.isDark(ctx)) R.color.widget_fg_dark else R.color.widget_fg_light,
        )

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
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
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

        // Fill-in intent merged with the template set in PantryWidgetProvider.
        val fillIn = Intent().apply {
            putExtra("list_id", item.id)
            putExtra("house_id", item.houseId)
        }
        rv.setOnClickFillInIntent(R.id.widget_item_root, fillIn)
        return rv
    }
}
