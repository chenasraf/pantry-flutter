package dev.casraf.pantry

import android.content.Intent
import android.net.Uri
import android.view.InputDevice
import android.view.MotionEvent
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

    private val dataLayer by lazy { DataLayerChannel(applicationContext) }
    private val remoteActivity by lazy { RemoteActivityHelper(applicationContext) }

    private var rotaryEvents: EventChannel.EventSink? = null

    private var deepLinkEvents: EventChannel.EventSink? = null

    /** A link that arrived before Dart was listening, held until it is. */
    private var pendingDeepLink: String? = null

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

        MethodChannel(messenger, hostChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openOnPhone" -> openOnPhone(call.argument<String>("url"), result)
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
