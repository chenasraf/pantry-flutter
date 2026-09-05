package dev.casraf.pantry

import android.content.Context
import android.graphics.Color
import org.json.JSONArray
import org.json.JSONObject

/**
 * What the list Tile draws, as the app last published it.
 *
 * The Tile is built with no Flutter engine running — the system asks for a
 * layout whenever it pleases, most often long after the app has died — so it
 * cannot read the Dart caches and cannot ask Dart anything. The app pushes this
 * instead, and the Tile is rendered from it alone.
 */
data class TileSnapshot(
    val houseId: Int,
    val houseName: String?,
    val accent: Int,
    val lists: List<Entry>,
) {
    data class Entry(val id: Int, val name: String, val icon: String?, val color: Int?)

    companion object {
        private const val PREFS = "PantryTile"
        private const val KEY = "list_tile"

        /** The accent to draw when none was published, matching the app's own default seed. */
        private const val FALLBACK_ACCENT = 0xFF0082C9.toInt()

        private fun prefs(ctx: Context) =
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun read(ctx: Context): TileSnapshot? =
            prefs(ctx).getString(KEY, null)?.let(::parse)

        /**
         * Store [json], answering whether anything changed. The app republishes
         * on every read it does — once a minute while a page is open — and the
         * answer is almost always "no", so the comparison here is what keeps a
         * poll from waking a system surface it has nothing new to tell.
         */
        fun write(ctx: Context, json: String?): Boolean {
            val store = prefs(ctx)
            if (store.getString(KEY, null) == json) return false
            store.edit().apply { if (json == null) remove(KEY) else putString(KEY, json) }.apply()
            return true
        }

        private fun parse(json: String): TileSnapshot? = try {
            val obj = JSONObject(json)
            val arr = obj.optJSONArray("lists") ?: JSONArray()
            TileSnapshot(
                houseId = obj.getInt("houseId"),
                houseName = obj.optString("houseName").takeIf { it.isNotEmpty() },
                accent = parseColor(obj.optString("accent")) ?: FALLBACK_ACCENT,
                lists = (0 until arr.length()).mapNotNull { i ->
                    val entry = arr.optJSONObject(i) ?: return@mapNotNull null
                    Entry(
                        id = entry.getInt("id"),
                        name = entry.optString("name"),
                        icon = entry.optString("icon").takeIf { it.isNotEmpty() },
                        color = parseColor(entry.optString("color")),
                    )
                },
            )
        } catch (e: Exception) {
            null
        }

        private fun parseColor(hex: String?): Int? {
            if (hex.isNullOrEmpty()) return null
            return try {
                Color.parseColor(if (hex.startsWith("#")) hex else "#$hex")
            } catch (e: IllegalArgumentException) {
                null
            }
        }
    }
}
