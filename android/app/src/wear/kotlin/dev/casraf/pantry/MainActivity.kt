package dev.casraf.pantry

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.InputDevice
import android.view.MotionEvent
import androidx.core.app.NotificationManagerCompat
import androidx.wear.ambient.AmbientLifecycleObserver
import androidx.wear.remote.interactions.RemoteActivityHelper
import androidx.wear.tiles.TileService
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
    private val tileChannel = "dev.casraf.pantry/tile"
    private val deepLinkChannel = "dev.casraf.pantry/deep_link"
    private val ongoingChannel = "dev.casraf.pantry/ongoing_activity"
    private val ambientChannel = "dev.casraf.pantry/ambient"

    private val dataLayer by lazy { DataLayerChannel(applicationContext) }
    private val remoteActivity by lazy { RemoteActivityHelper(applicationContext) }

    private var rotaryEvents: EventChannel.EventSink? = null

    private var deepLinkEvents: EventChannel.EventSink? = null

    /** A link that arrived before Dart was listening, held until it is. */
    private var pendingDeepLink: String? = null

    private var ambientEvents: EventChannel.EventSink? = null

    /**
     * Ambient is absolute state, not a series of events: a listener attaching
     * mid-doze has to be told where it already is, or the watch would draw the
     * interactive theme over a dimmed screen until the next callback — up to a
     * minute away, since updates arrive about once a minute.
     */
    private var ambient = ambientState(false)

    private fun ambientState(
        isAmbient: Boolean,
        burnIn: Boolean = false,
        lowBit: Boolean = false,
    ): Map<String, Any?> = mapOf(
        "isAmbient" to isAmbient,
        "burnInProtectionRequired" to burnIn,
        "deviceHasLowBitAmbient" to lowBit,
    )

    private val ambientCallback = object : AmbientLifecycleObserver.AmbientLifecycleCallback {
        override fun onEnterAmbient(ambientDetails: AmbientLifecycleObserver.AmbientDetails) {
            emitAmbient(
                ambientState(
                    true,
                    ambientDetails.burnInProtectionRequired,
                    ambientDetails.deviceHasLowBitAmbient,
                ),
            )
        }

        /**
         * The system's cue to redraw, roughly once a minute. Forwarded even
         * though the state is unchanged: the wearer sees a clock and a count,
         * and this is the only moment either is allowed to move.
         */
        override fun onUpdateAmbient() = emitAmbient(ambient)

        override fun onExitAmbient() = emitAmbient(ambientState(false))
    }

    private val ambientObserver by lazy { AmbientLifecycleObserver(this, ambientCallback) }

    private fun emitAmbient(state: Map<String, Any?>) {
        ambient = state
        ambientEvents?.success(state)
    }

    /**
     * Registered here rather than lazily from Dart: the observer makes its own
     * `setAmbientEnabled` call when it receives `ON_CREATE`, and an activity
     * that asks after it is already resumed has missed the window in which the
     * system decides whether this is an ambient component at all.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(ambientObserver)
    }

    /**
     * Screen shape reaches Dart before the first frame rather than over a
     * channel: the round layout draws curved rows, and the first channel round
     * trip lands 311 ms after the first frame, which is one visible reflow per
     * launch. This runs during `super.onCreate`, so it reads the configuration
     * itself rather than a field some later callback would fill in.
     *
     * The launch link rides the same argument list for the same reason. A Tile
     * tap names the list it wants, and delivering that over a channel would
     * draw the previous list first and correct itself a third of a second
     * later — on the one launch where the wearer has said where they are going.
     */
    override fun getDartEntrypointArgs(): List<String> = buildList {
        add(if (resources.configuration.isScreenRound) "round" else "square")
        linkFrom(intent)?.let(::add)
    }

    /**
     * `singleTop`, so a Tile tap on a watch that is already showing the app
     * lands here rather than in a new process. Entrypoint arguments are long
     * spent by then, so this half of the same question travels by channel.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = linkFrom(intent) ?: return
        val sink = deepLinkEvents
        if (sink == null) pendingDeepLink = link else sink.success(link)
    }

    /**
     * The link an intent is asking for, whichever way it carries it: a VIEW
     * intent's own data, or the string extra a Tile row puts there — ProtoLayout
     * actions can name an activity and extras and nothing else, so a Tile cannot
     * fire a URI even though the manifest declares the filter for one. Both
     * become the same `pantry://` string, so Dart knows one grammar.
     */
    private fun linkFrom(intent: Intent?): String? {
        if (intent == null) return null
        intent.getStringExtra(ListTileService.EXTRA_LINK)?.let { return it }
        return intent.data?.takeIf { it.scheme == "pantry" }?.toString()
    }

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

        EventChannel(messenger, deepLinkChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    deepLinkEvents = sink
                    pendingDeepLink?.let {
                        pendingDeepLink = null
                        sink?.success(it)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    deepLinkEvents = null
                }
            },
        )

        EventChannel(messenger, ambientChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    ambientEvents = sink
                    sink?.success(ambient)
                }

                override fun onCancel(arguments: Any?) {
                    ambientEvents = null
                }
            },
        )

        MethodChannel(messenger, hostChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openOnPhone" -> openOnPhone(call.argument<String>("url"), result)
                "hasRotary" -> result.success(hasRotary())
                "notificationsEnabled" ->
                    result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
                "requestNotifications" -> requestNotifications(result)
                "openNotificationSettings" -> openNotificationSettings(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, ongoingChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "post" -> {
                    OngoingTripChip.post(
                        applicationContext,
                        call.argument<String>("status").orEmpty(),
                    )
                    result.success(null)
                }
                "cancel" -> {
                    OngoingTripChip.cancel(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, tileChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> publishTile(call.argument<String>("payload"), result)
                "clear" -> publishTile(null, result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Store what the Tile draws, and wake it only when the answer moved. The
     * app republishes on every read it does, so without the comparison a
     * 60-second poll would ask the system to redraw a surface 60 times an hour
     * to show it the same list names.
     */
    private fun publishTile(payload: String?, result: MethodChannel.Result) {
        if (TileSnapshot.write(applicationContext, payload)) {
            TileService.getUpdater(applicationContext)
                .requestUpdate(ListTileService::class.java)
        }
        result.success(null)
    }

    /**
     * Ask for the runtime notification grant, answering nothing.
     *
     * The prompt is answered long after this returns, and Android suppresses it
     * outright once it has been refused — so a boolean handed back here would
     * describe neither. `notificationsEnabled` is the one reader of the grant,
     * and it reads the system rather than anything remembered.
     */
    private fun requestNotifications(result: MethodChannel.Result) {
        val needed = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        if (needed) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
        result.success(null)
    }

    /**
     * The system's own notification screen for this app. Never an in-app
     * prompt: a prompt is suppressed after a refusal and can only ever grant,
     * so a row offering one would do different things on two identical taps and
     * could never take a grant back.
     */
    private fun openNotificationSettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(intent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.success(false)
        }
    }

    /**
     * Whether any attached input device speaks rotary, asked of the same source
     * [onGenericMotionEvent] filters on. Enumeration is what the platform will
     * say before a single detent has been turned, which is when a settings page
     * has to draw or hide the row that configures them.
     */
    private fun hasRotary(): Boolean = InputDevice.getDeviceIds().any { id ->
        InputDevice.getDevice(id)?.supportsSource(InputDevice.SOURCE_ROTARY_ENCODER) == true
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
        deepLinkEvents = null
        ambientEvents = null
        lifecycle.removeObserver(ambientObserver)
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
