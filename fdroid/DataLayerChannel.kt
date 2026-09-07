package dev.casraf.pantry

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The link, in a build with no Play services to carry it.
 *
 * The Wear Data Layer *is* Google Play services — there is no FLOSS transport
 * between a phone and a watch to swap in — so the FLOSS build answers honestly
 * instead of pretending. The channels are still registered: a caller that gets
 * `false` from `isAvailable` can hide its pairing entry point, where one that
 * gets a `MissingPluginException` can only crash.
 *
 * Copied over the real implementation by tool/fdroid/apply.sh, alongside the
 * removal of the play-services-wearable dependency.
 */
class DataLayerChannel(@Suppress("UNUSED_PARAMETER") context: Context) {
    private companion object {
        const val METHOD_CHANNEL = "dev.casraf.pantry/data_layer"
        const val EVENT_CHANNEL = "dev.casraf.pantry/data_layer/events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    fun attachTo(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(false)
                    else -> result.success(null)
                }
            }
        }

        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) = Unit
                override fun onCancel(arguments: Any?) = Unit
            })
        }
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }
}
