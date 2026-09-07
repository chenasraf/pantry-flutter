package dev.casraf.pantry

import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.wear.ambient.AmbientLifecycleObserver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Host for the ambient probe, in the `wearDebug` source set so neither the
 * release watch build nor any phone build carries it — the activity, the
 * manifest entry and the `androidx.wear:wear` dependency behind it are all
 * scoped to this one variant.
 *
 * Ambient is driven here through [AmbientLifecycleObserver], the AndroidX route.
 * The earlier measurement drove it through `wear_plus`, which wraps the
 * pre-AndroidX `WearableActivityController`, and recorded zero callbacks; which
 * of the two routes that result belonged to was never established.
 *
 * **The counters live here rather than in Dart.** Whether Flutter keeps running
 * — let alone keeps a channel drained — is one of the things under test, so a
 * count accumulated on the Dart side would go missing in exactly the case worth
 * measuring. Dart reads `snapshot`; the event stream is a liveness cue on top,
 * never the record.
 */
class AmbientProbeActivity : FlutterActivity() {
    private val methodChannel = "dev.casraf.pantry/ambient_probe"
    private val eventChannel = "dev.casraf.pantry/ambient_probe_events"

    private var events: EventChannel.EventSink? = null

    private var enters = 0
    private var exits = 0
    private var updates = 0

    /** Wall-clock trace, so a callback can be placed against the doze it belongs to. */
    private val log = mutableListOf<Map<String, Any?>>()

    private var burnInProtectionRequired: Boolean? = null
    private var deviceHasLowBitAmbient: Boolean? = null

    private val callback = object : AmbientLifecycleObserver.AmbientLifecycleCallback {
        override fun onEnterAmbient(ambientDetails: AmbientLifecycleObserver.AmbientDetails) {
            enters++
            burnInProtectionRequired = ambientDetails.burnInProtectionRequired
            deviceHasLowBitAmbient = ambientDetails.deviceHasLowBitAmbient
            record(
                "enter",
                mapOf(
                    "burnInProtectionRequired" to ambientDetails.burnInProtectionRequired,
                    "deviceHasLowBitAmbient" to ambientDetails.deviceHasLowBitAmbient,
                ),
            )
        }

        override fun onUpdateAmbient() {
            updates++
            record("update", emptyMap())
        }

        override fun onExitAmbient() {
            exits++
            record("exit", emptyMap())
        }
    }

    private val observer by lazy { AmbientLifecycleObserver(this, callback) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // After super, so the registry exists. It is already CREATED by now and
        // replays that event into a newly added observer, which is what lets the
        // observer make its own `setAmbientEnabled` call on time.
        lifecycle.addObserver(observer)
        record("registered", mapOf("aodSetting" to aodSetting()))
    }

    private fun record(event: String, extra: Map<String, Any?>) {
        val entry = HashMap<String, Any?>(extra)
        entry["event"] = event
        entry["at"] = System.currentTimeMillis()
        synchronized(log) {
            log.add(entry)
            // A probe left running overnight should not be the reason the watch
            // runs out of memory.
            if (log.size > 500) log.removeAt(0)
        }
        Log.i(TAG, "$event  enters=$enters exits=$exits updates=$updates $extra")
        runOnUiThread { events?.success(entry) }
    }

    /**
     * Best-effort read of the watch's always-on display setting, which is the
     * variable the earlier run never controlled for: with it off, the system
     * hands the screen to the watch face no matter what the app registered, so
     * a run recording zeroes proves nothing. Reported on the probe's own screen
     * so a result cannot be recorded without it.
     *
     * `ambient_enabled` is not public API and may read null on some builds —
     * null means unknown, and the watch's own settings screen is then the only
     * answer.
     */
    private fun aodSetting(): Int? = try {
        Settings.Global.getInt(contentResolver, "ambient_enabled")
    } catch (e: Settings.SettingNotFoundException) {
        null
    }

    private fun snapshot(): Map<String, Any?> = mapOf(
        "enters" to enters,
        "exits" to exits,
        "updates" to updates,
        "isAmbient" to (try { observer.isAmbient } catch (e: IllegalStateException) { false }),
        "burnInProtectionRequired" to burnInProtectionRequired,
        "deviceHasLowBitAmbient" to deviceHasLowBitAmbient,
        "aodSetting" to aodSetting(),
        "isWatch" to packageManager.hasSystemFeature("android.hardware.type.watch"),
        "log" to synchronized(log) { log.toList() },
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, methodChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "snapshot" -> result.success(snapshot())
                "reset" -> {
                    enters = 0
                    exits = 0
                    updates = 0
                    synchronized(log) { log.clear() }
                    record("reset", mapOf("aodSetting" to aodSetting()))
                    result.success(snapshot())
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, eventChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    events = sink
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                }
            },
        )
    }

    override fun onDestroy() {
        events = null
        lifecycle.removeObserver(observer)
        super.onDestroy()
    }

    companion object {
        const val TAG = "AmbientProbe"
    }
}
