package dev.casraf.pantry

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/// Invisible trampoline for checklist-widget row taps. A collection has a single
/// click template, so every row tap lands here as a foreground activity (which,
/// unlike a background isolate, is allowed to start other activities):
///   pantry-widget://toggle/... -> fire home_widget's background callback (no UI)
///   pantry-widget://open/...   -> open the item in the app
/// It renders nothing and finishes immediately, so the toggle path shows no flash.
class WidgetActionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val uri = intent?.data
        when (uri?.host) {
            "toggle" -> HomeWidgetBackgroundIntent.getBroadcast(this, uri).send()
            "open" -> {
                val segs = uri.pathSegments
                if (segs.size >= 3) {
                    startActivity(
                        Intent(
                            Intent.ACTION_VIEW,
                            Uri.parse("pantry://item/${segs[0]}/${segs[1]}/${segs[2]}"),
                        ).apply {
                            setPackage(packageName)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        },
                    )
                }
            }
        }
        finish()
    }
}
