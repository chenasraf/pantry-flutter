package dev.casraf.pantry

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status

/**
 * The chip Wear draws at the bottom of the watch face while a shopping trip is
 * live.
 *
 * A notification outlives the process that posted it, so whatever Dart says
 * here stays said with nothing running to correct it — and a trip both advances
 * stores and closes, either of which can happen on the phone while the watch
 * app is dead. So the chip is not kept true: it says one thing that is true for
 * exactly as long as the trip is, and [TIMEOUT_MS] is Android's own ceiling on
 * how stale even that can get.
 */
object OngoingTripChip {
    private const val CHANNEL_ID = "shopping_trip"
    private const val NOTIFICATION_ID = 4701

    /**
     * How long the chip may outlive the last moment anything knew the trip was
     * live. Android enforces it, so the bound holds with no live process
     * anywhere — which is what makes a standalone, an F-Droid and an
     * out-of-range watch one case instead of three.
     */
    private const val TIMEOUT_MS = 30L * 60 * 1000

    /**
     * Draw the chip, or redraw it. Re-posting an identical notification is
     * precisely how [TIMEOUT_MS] is restarted, so this deliberately carries no
     * compare-before-waking guard: unlike the Tile, a suppressed duplicate here
     * would be the bug rather than the saving.
     *
     * [status] is the chip's whole content, and the notification channel's
     * user-visible name: one string, one meaning, and a channel re-declared
     * under the same id follows the wearer's language when it changes.
     */
    @SuppressLint("MissingPermission")
    fun post(context: Context, status: String) {
        val manager = NotificationManagerCompat.from(context)
        // On API 33+ an ungranted app posts nothing and is told nothing, so the
        // only legible failure is the one the settings row reads back.
        if (!manager.areNotificationsEnabled()) return

        channel(context, status)
        val touch = PendingIntent.getActivity(
            context,
            0,
            launchIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.widget_icon_cart)
            .setContentTitle(status)
            .setContentIntent(touch)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setOngoing(true)
            .setTimeoutAfter(TIMEOUT_MS)

        OngoingActivity.Builder(context, NOTIFICATION_ID, builder)
            .setStaticIcon(R.drawable.widget_icon_cart)
            .setTouchIntent(touch)
            .setStatus(Status.forPart(Status.TextPart(status)))
            .build()
            .apply(context)

        manager.notify(NOTIFICATION_ID, builder.build())
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /**
     * Low importance: the chip is a place to look, not something to be told.
     */
    private fun channel(context: Context, name: String) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW),
        )
    }

    /**
     * A plain launch, carrying no link. The shell derives its page set from
     * whether a trip is live, so it opens the session pager on the checklist by
     * itself; a host naming that destination would be redundant while the trip
     * runs and would point at nothing the moment it ends.
     */
    private fun launchIntent(context: Context): Intent =
        context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
}
