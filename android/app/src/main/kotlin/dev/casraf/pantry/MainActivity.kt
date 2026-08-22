package dev.casraf.pantry

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "dev.casraf.pantry/widget"
    private val shortcutChannel = "dev.casraf.pantry/shortcuts"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shortcutChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "pinListShortcut") {
                    val listId = call.argument<Int>("listId")
                    val houseId = call.argument<Int>("houseId")
                    val name = call.argument<String>("name") ?: ""
                    if (listId == null || houseId == null) {
                        result.success(false)
                    } else {
                        result.success(pinListShortcut(houseId, listId, name))
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun pinListShortcut(houseId: Int, listId: Int, name: String): Boolean {
        if (!ShortcutManagerCompat.isRequestPinShortcutSupported(this)) return false
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("pantry://list/$houseId/$listId"))
            .setPackage(packageName)
        val shortcut = ShortcutInfoCompat.Builder(this, "list_${houseId}_${listId}")
            .setShortLabel(name)
            .setLongLabel(name)
            .setIcon(IconCompat.createWithResource(this, R.mipmap.ic_launcher))
            .setIntent(intent)
            .build()
        return ShortcutManagerCompat.requestPinShortcut(this, shortcut, null)
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
