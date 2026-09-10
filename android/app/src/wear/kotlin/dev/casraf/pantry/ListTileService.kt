package dev.casraf.pantry

import android.content.Context
import androidx.concurrent.futures.ResolvableFuture
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DeviceParametersBuilders.DeviceParameters
import androidx.wear.protolayout.DeviceParametersBuilders.SCREEN_SHAPE_ROUND
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.DimensionBuilders.wrap
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture

/**
 * The list Tile: the household's lists, one tap from the list you want.
 *
 * Deliberately names and nothing else. A Tile is drawn by the system whenever
 * it likes, with no engine of ours running and no way to fetch anything, so
 * every number it could show would be a number it could not correct — where a
 * list's *name* is as true a week later as it was when written. That is what
 * lets this carry no freshness interval: there is nothing here that goes stale.
 *
 * Data comes from [TileSnapshot], which the app pushes over
 * `dev.casraf.pantry/tile`.
 */
class ListTileService : TileService() {

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val snapshot = TileSnapshot.read(applicationContext)
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(resourcesVersion(snapshot))
            // Never on a schedule. Nothing here goes stale on its own, and a
            // Tile has no way to fetch anything even if it did; the app pushes
            // when a list changes and that is the only thing that moves this.
            .setFreshnessIntervalMillis(0)
            .setTileTimeline(
                TimelineBuilders.Timeline.fromLayoutElement(
                    layout(applicationContext, snapshot, requestParams.deviceConfiguration),
                ),
            )
            .build()
        return immediate(tile)
    }

    /**
     * The icons the current snapshot names, and only those. The version has to
     * change whenever the set does, or the renderer keeps serving the icons it
     * cached for the previous set of lists.
     */
    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> {
        val snapshot = TileSnapshot.read(applicationContext)
        val builder = ResourceBuilders.Resources.Builder()
            .setVersion(resourcesVersion(snapshot))
        for (key in iconKeys(snapshot)) {
            builder.addIdToImageMapping(
                key,
                ResourceBuilders.ImageResource.Builder()
                    .setAndroidResourceByResId(
                        ResourceBuilders.AndroidImageResourceByResId.Builder()
                            .setResourceId(iconResFor(applicationContext, key))
                            .build(),
                    )
                    .build(),
            )
        }
        return immediate(builder.build())
    }

    companion object {
        /** The extra a tapped row carries; [MainActivity] turns it back into a link. */
        const val EXTRA_LINK = "pantry_link"

        /** Google's round-screen guidance: keep content off the outer band. */
        const val ROUND_MARGIN_FRACTION = 0.104f
        const val SQUARE_MARGIN_FRACTION = 0.06f

        const val ROW_HEIGHT = 44f
        const val ROW_GAP = 4f
        const val ICON_SIZE = 18f
        const val TITLE_SIZE = 12f
        const val LABEL_SIZE = 15f

        /** The plane a row sits on — the app's raised surface, not pure black. */
        const val ROW_BACKGROUND = 0xFF17171A.toInt()
        const val LABEL = 0xFFECECEE.toInt()
        const val MUTED = 0xFF8A8A93.toInt()

        fun <T> immediate(value: T): ListenableFuture<T> =
            ResolvableFuture.create<T>().apply { set(value) }

        fun iconKeys(snapshot: TileSnapshot?): List<String> =
            snapshot?.lists.orEmpty().map { it.icon ?: "default" }.distinct()

        /**
         * The vectors the phone's home-screen widget already ships. They are in
         * the shared source set, so the watch binary carries them whether or not
         * anything draws them — reusing them costs nothing and keeps one list
         * icon set across every surface.
         */
        fun iconResFor(ctx: Context, key: String): Int {
            val name = "widget_icon_${key.replace('-', '_')}"
            val id = ctx.resources.getIdentifier(name, "drawable", ctx.packageName)
            return if (id != 0) id else R.drawable.widget_icon_default
        }

        fun resourcesVersion(snapshot: TileSnapshot?): String =
            iconKeys(snapshot).sorted().joinToString(",").ifEmpty { "none" }

        fun layout(
            ctx: Context,
            snapshot: TileSnapshot?,
            device: DeviceParameters,
        ): LayoutElementBuilders.LayoutElement {
            val fraction = if (device.screenShape == SCREEN_SHAPE_ROUND) {
                ROUND_MARGIN_FRACTION
            } else {
                SQUARE_MARGIN_FRACTION
            }
            val margin = device.screenWidthDp * fraction
            val content = if (snapshot == null || snapshot.lists.isEmpty()) {
                empty(ctx, snapshot)
            } else {
                lists(ctx, snapshot, device)
            }
            return LayoutElementBuilders.Box.Builder()
                .setWidth(expand())
                .setHeight(expand())
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setPadding(
                            ModifiersBuilders.Padding.Builder()
                                .setStart(dp(margin))
                                .setEnd(dp(margin))
                                .build(),
                        )
                        .build(),
                )
                .addContent(content)
                .build()
        }

        /**
         * The wearer's own font size. A Tile has no scrolling of any kind, so
         * this decides both how tall a row is and how many of them there is
         * room for — a row drawn past the bottom of the glass is not a row.
         */
        fun fontScale(ctx: Context): Float =
            ctx.resources.configuration.fontScale.coerceAtLeast(1f)

        /**
         * How many rows fit under the title on [device], at [scale].
         *
         * Trimmed rather than clipped: a wearer who asked for larger type gets
         * fewer lists they can read instead of the same number they cannot, and
         * the last one drawn is whole.
         */
        fun rowsThatFit(device: DeviceParameters, scale: Float, titled: Boolean): Int {
            val fraction = if (device.screenShape == SCREEN_SHAPE_ROUND) {
                ROUND_MARGIN_FRACTION
            } else {
                SQUARE_MARGIN_FRACTION
            }
            val available = device.screenHeightDp * (1 - 2 * fraction) -
                if (titled) (TITLE_SIZE * scale + ROW_GAP) else 0f
            val row = ROW_HEIGHT * scale + ROW_GAP
            return ((available + ROW_GAP) / row).toInt().coerceAtLeast(1)
        }

        fun lists(
            ctx: Context,
            snapshot: TileSnapshot,
            device: DeviceParameters,
        ): LayoutElementBuilders.LayoutElement {
            val scale = fontScale(ctx)
            val column = LayoutElementBuilders.Column.Builder()
                .setWidth(expand())
                .setHeight(wrap())
            val titled = snapshot.houseName != null
            snapshot.houseName?.let {
                column.addContent(title(it))
                column.addContent(spacer(ROW_GAP))
            }
            snapshot.lists.take(rowsThatFit(device, scale, titled))
                .forEachIndexed { index, entry ->
                    if (index > 0) column.addContent(spacer(ROW_GAP))
                    column.addContent(row(ctx, snapshot, entry, scale))
                }
            return column.build()
        }

        fun title(name: String) = LayoutElementBuilders.Text.Builder()
            .setText(name)
            .setMaxLines(1)
            .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE_END)
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(sp(TITLE_SIZE))
                    .setColor(argb(MUTED))
                    .build(),
            )
            .build()

        /**
         * One list. The whole row is the target rather than the icon or the
         * label — a wrist is aimed at roughly, and a row that is only partly
         * live reads as a row that did not respond.
         */
        fun row(
            ctx: Context,
            snapshot: TileSnapshot,
            entry: TileSnapshot.Entry,
            scale: Float,
        ): LayoutElementBuilders.LayoutElement {
            val tint = entry.color ?: snapshot.accent
            val height = ROW_HEIGHT * scale
            return LayoutElementBuilders.Row.Builder()
                .setWidth(expand())
                .setHeight(dp(height))
                .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setBackground(
                            ModifiersBuilders.Background.Builder()
                                .setColor(argb(ROW_BACKGROUND))
                                .setCorner(
                                    ModifiersBuilders.Corner.Builder()
                                        .setRadius(dp(height / 2))
                                        .build(),
                                )
                                .build(),
                        )
                        .setPadding(
                            ModifiersBuilders.Padding.Builder()
                                .setStart(dp(14f))
                                .setEnd(dp(14f))
                                .build(),
                        )
                        .setClickable(open(ctx, link(snapshot.houseId, entry.id)))
                        .setSemantics(
                            ModifiersBuilders.Semantics.Builder()
                                .setContentDescription(entry.name)
                                .build(),
                        )
                        .build(),
                )
                .addContent(
                    LayoutElementBuilders.Image.Builder()
                        .setResourceId(entry.icon ?: "default")
                        .setWidth(dp(ICON_SIZE * scale))
                        .setHeight(dp(ICON_SIZE * scale))
                        .setColorFilter(
                            LayoutElementBuilders.ColorFilter.Builder()
                                .setTint(argb(tint))
                                .build(),
                        )
                        .build(),
                )
                .addContent(
                    LayoutElementBuilders.Spacer.Builder().setWidth(dp(10f)).build(),
                )
                .addContent(
                    LayoutElementBuilders.Text.Builder()
                        .setText(entry.name)
                        .setMaxLines(1)
                        .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE_END)
                        .setFontStyle(
                            LayoutElementBuilders.FontStyle.Builder()
                                .setSize(sp(LABEL_SIZE))
                                .setColor(argb(LABEL))
                                .build(),
                        )
                        .build(),
                )
                .build()
        }

        /**
         * Nothing to offer, which is two different situations and one answer:
         * the app has never been signed in, or it has and this house has no
         * lists. Either way the Tile opens the app, because the app is the only
         * place either can be fixed.
         */
        fun empty(ctx: Context, snapshot: TileSnapshot?): LayoutElementBuilders.LayoutElement {
            val message = ctx.getString(
                if (snapshot == null) R.string.tile_signed_out else R.string.tile_no_lists,
            )
            return LayoutElementBuilders.Box.Builder()
                .setWidth(expand())
                .setHeight(expand())
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setClickable(open(ctx, null))
                        .build(),
                )
                .addContent(
                    LayoutElementBuilders.Text.Builder()
                        .setText(message)
                        .setMaxLines(3)
                        .setFontStyle(
                            LayoutElementBuilders.FontStyle.Builder()
                                .setSize(sp(14f))
                                .setColor(argb(MUTED))
                                .build(),
                        )
                        .build(),
                )
                .build()
        }

        fun spacer(height: Float) =
            LayoutElementBuilders.Spacer.Builder().setHeight(dp(height)).build()

        fun link(houseId: Int, listId: Int) = "pantry://list/$houseId/$listId"

        /**
         * A tile action can only name an activity and its extras — ProtoLayout
         * has no way to express a VIEW intent with a URI — so the link travels
         * as one string extra and the activity puts it back together. The
         * grammar is the same either way, which is what keeps a Tile tap and an
         * `adb`-fired `pantry://` intent from being two different paths.
         */
        fun open(ctx: Context, url: String?): ModifiersBuilders.Clickable {
            // The debug build carries an applicationId suffix, so the package
            // has to be read rather than written down.
            val activity = ActionBuilders.AndroidActivity.Builder()
                .setPackageName(ctx.packageName)
                .setClassName(MainActivity::class.java.name)
            if (url != null) {
                activity.addKeyToExtraMapping(
                    EXTRA_LINK,
                    ActionBuilders.AndroidStringExtra.Builder().setValue(url).build(),
                )
            }
            return ModifiersBuilders.Clickable.Builder()
                .setId(url ?: "open")
                .setOnClick(
                    ActionBuilders.LaunchAction.Builder()
                        .setAndroidActivity(activity.build())
                        .build(),
                )
                .build()
        }
    }
}
