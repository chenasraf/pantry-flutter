package dev.casraf.pantry

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "dev.casraf.pantry/widget"
    private var pendingListId: Int? = null
    private var pendingHouseId: Int? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleWidgetIntent(intent)
        sendPendingWidgetTap()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getPendingWidgetTap") {
                    val listId = pendingListId
                    val houseId = pendingHouseId
                    if (listId != null) {
                        pendingListId = null
                        pendingHouseId = null
                        result.success(mapOf("listId" to listId, "houseId" to houseId))
                    } else {
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun handleWidgetIntent(intent: Intent?) {
        if (intent?.action == "dev.casraf.pantry.OPEN_LIST") {
            pendingListId = intent.getIntExtra("list_id", -1).takeIf { it != -1 }
            pendingHouseId = intent.getIntExtra("house_id", -1).takeIf { it != -1 }
        }
    }

    private fun sendPendingWidgetTap() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, channel).invokeMethod("onWidgetTap", null)
        }
    }
}
