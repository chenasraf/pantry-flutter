package dev.casraf.pantry

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Configuration screen for the lists widget. Runs a lean Flutter app (the list
/// selector) in its own engine via the `/widget-config/<id>` initial route.
/// Declared as the widget's `android:configure`, so it opens when a widget is
/// added, and is also launched by the widget's header cog to reconfigure.
/// Returns RESULT_OK only once the user saves, so the launcher commits the
/// widget; backing out leaves the default RESULT_CANCELED.
class WidgetConfigActivity : FlutterActivity() {
    private val configChannel = "dev.casraf.pantry/widget_config"
    private val widgetChannel = "dev.casraf.pantry/widget"

    private val appWidgetId: Int
        get() = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        setResult(
            RESULT_CANCELED,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
        )
        super.onCreate(savedInstanceState)
    }

    override fun getInitialRoute(): String = "/widget-config/$appWidgetId"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, configChannel).setMethodCallHandler { call, result ->
            if (call.method == "finish") {
                val ok = call.argument<Boolean>("ok") ?: false
                val id = appWidgetId
                if (ok && id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    setResult(
                        RESULT_OK,
                        Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id),
                    )
                    PantryWidgetProvider.updateWidget(
                        this,
                        AppWidgetManager.getInstance(this),
                        id,
                    )
                }
                result.success(null)
                finish()
            } else {
                result.notImplemented()
            }
        }

        // The config engine's WidgetService needs live widget ids to resync the
        // launcher shortcut union when a selection is saved.
        MethodChannel(messenger, widgetChannel).setMethodCallHandler { call, result ->
            if (call.method == "getListsWidgetIds") {
                result.success(PantryWidgetProvider.widgetIds(this).toList())
            } else {
                result.notImplemented()
            }
        }
    }
}
