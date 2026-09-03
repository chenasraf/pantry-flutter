package dev.casraf.pantry

import android.content.Intent
import android.net.Uri
import android.view.InputDevice
import android.view.MotionEvent
import androidx.wear.remote.interactions.RemoteActivityHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The watch half of the app. Same fully-qualified name as the phone's, in the
 * mutually exclusive `wear` source set, so neither binary carries an `if` on
 * the other's concerns and rotary code never reaches a phone.
 */
class MainActivity : FlutterActivity() {
    private val rotaryChannel = "dev.casraf.pantry/rotary"
    private val hostChannel = "dev.casraf.pantry/wear_host"

    private val dataLayer by lazy { DataLayerChannel(applicationContext) }
    private val remoteActivity by lazy { RemoteActivityHelper(applicationContext) }

    private var rotaryEvents: EventChannel.EventSink? = null

    /**
     * Screen shape reaches Dart before the first frame rather than over a
     * channel: the round layout draws curved rows, and the first channel round
     * trip lands 311 ms after the first frame, which is one visible reflow per
     * launch. This runs during `super.onCreate`, so it reads the configuration
     * itself rather than a field some later callback would fill in.
     */
    override fun getDartEntrypointArgs(): List<String> =
        listOf(if (resources.configuration.isScreenRound) "round" else "square")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        dataLayer.attachTo(flutterEngine)

        EventChannel(messenger, rotaryChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    rotaryEvents = sink
                }

                override fun onCancel(arguments: Any?) {
                    rotaryEvents = null
                }
            },
        )

        MethodChannel(messenger, hostChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openOnPhone" -> openOnPhone(call.argument<String>("url"), result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * The bezel and crown arrive here as [MotionEvent.AXIS_SCROLL] on a
     * non-touch source, one detent per ±1.0. The engine's own pointer-signal
     * path never sees them — it reads the h/v scroll axes, which stay at zero —
     * so forwarding the raw axis is the only way rotary reaches Dart.
     */
    override fun onGenericMotionEvent(event: MotionEvent): Boolean {
        val sink = rotaryEvents
        val isRotary = event.action == MotionEvent.ACTION_SCROLL &&
            event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER)
        if (sink != null && isRotary) {
            sink.success(event.getAxisValue(MotionEvent.AXIS_SCROLL).toDouble())
            return true
        }
        return super.onGenericMotionEvent(event)
    }

    override fun onDestroy() {
        dataLayer.detach()
        rotaryEvents = null
        super.onDestroy()
    }

    private fun openOnPhone(url: String?, result: MethodChannel.Result) {
        if (url.isNullOrEmpty()) {
            result.success(false)
            return
        }
        val intent = Intent(Intent.ACTION_VIEW)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .setData(Uri.parse(url))
        val pending = try {
            remoteActivity.startRemoteActivity(intent)
        } catch (e: IllegalArgumentException) {
            result.success(false)
            return
        }
        pending.addListener(
            {
                result.success(
                    try {
                        pending.get()
                        true
                    } catch (e: Exception) {
                        false
                    },
                )
            },
            mainExecutor,
        )
    }
}
