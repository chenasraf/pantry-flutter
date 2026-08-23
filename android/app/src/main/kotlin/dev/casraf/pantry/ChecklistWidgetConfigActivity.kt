package dev.casraf.pantry

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Configuration screen for the single-checklist widget. Runs a lean Flutter
/// app via the `/checklist-widget-config/<id>` initial route. Declared as the
/// widget's `android:configure` and also opened by its header cog. Returns
/// RESULT_OK only once the user saves so the launcher commits the widget.
class ChecklistWidgetConfigActivity : FlutterActivity() {
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

    override fun getInitialRoute(): String = "/checklist-widget-config/$appWidgetId"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, configChannel).setMethodCallHandler { call, result ->
            if (call.method == "finish") {
                val ok = call.argument<Boolean>("ok") ?: false
                val id = appWidgetId
                if (ok && id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    // Just finalize the widget. The rows were already pushed by
                    // setConfig; rendering happens via the launcher's post-config
                    // onUpdate. Binding the collection service from this activity
                    // (updateWidget) leaks it and leaves the widget pending.
                    setResult(
                        RESULT_OK,
                        Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id),
                    )
                }
                result.success(null)
                finish()
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, widgetChannel).setMethodCallHandler { call, result ->
            if (call.method == "getChecklistWidgetIds") {
                result.success(ChecklistWidgetProvider.widgetIds(this).toList())
            } else {
                result.notImplemented()
            }
        }
    }
}
