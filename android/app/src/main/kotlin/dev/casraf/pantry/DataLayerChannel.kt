package dev.casraf.pantry

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets

/**
 * The link between a paired phone and watch, over the Wear Data Layer.
 *
 * Both flavors attach it: the phone is the half that sends the credential, so
 * this is the one piece of the wear surface that cannot be watch-only.
 *
 * Two delivery verbs, because the Data Layer's two clients differ in ways that
 * matter here. A [MessageClient] message is fire-and-forget and leaves nothing
 * behind, which is the only acceptable carrier for a credential. A
 * [DataClient] item persists and is included in cloud backup, so it carries
 * only state worth mirroring — and every write is `setUrgent`, or the system
 * may sit on it for half an hour.
 */
class DataLayerChannel(private val context: Context) {
    private companion object {
        const val METHOD_CHANNEL = "dev.casraf.pantry/data_layer"

        /**
         * A MethodChannel and an EventChannel are both just named message
         * handlers on one messenger, so the stream needs a name of its own
         * rather than sharing the method channel's.
         */
        const val EVENT_CHANNEL = "dev.casraf.pantry/data_layer/events"

        const val PAYLOAD_KEY = "json"
        const val DELIVERY_MESSAGE = "message"
        const val DELIVERY_DATA_ITEM = "dataItem"
    }

    private val main = Handler(Looper.getMainLooper())

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var events: EventChannel.EventSink? = null

    private val messageListener = MessageClient.OnMessageReceivedListener { event ->
        emit(DELIVERY_MESSAGE, event.path, String(event.data, StandardCharsets.UTF_8), event.sourceNodeId)
    }

    private val dataListener = DataClient.OnDataChangedListener { buffer ->
        forEachChangedItem(buffer) { path, payload, nodeId ->
            emit(DELIVERY_DATA_ITEM, path, payload, nodeId)
        }
    }

    fun attachTo(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler { call, result -> onMethodCall(call.method, call, result) }
        }

        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    events = sink
                    if (!isAvailable()) return
                    Wearable.getMessageClient(context).addListener(messageListener)
                    Wearable.getDataClient(context).addListener(dataListener)
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                    if (!isAvailable()) return
                    Wearable.getMessageClient(context).removeListener(messageListener)
                    Wearable.getDataClient(context).removeListener(dataListener)
                }
            })
        }
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        if (isAvailable()) {
            Wearable.getMessageClient(context).removeListener(messageListener)
            Wearable.getDataClient(context).removeListener(dataListener)
        }
        events = null
    }

    private fun onMethodCall(
        method: String,
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        if (method == "isAvailable") {
            result.success(isAvailable())
            return
        }
        if (!isAvailable()) {
            result.success(null)
            return
        }
        when (method) {
            "nodes" -> nodes(result)
            "send" -> send(
                call.argument<String>("path").orEmpty(),
                call.argument<String>("payload").orEmpty(),
                call.argument<String>("nodeId"),
                result,
            )
            "publish" -> publish(
                call.argument<String>("path").orEmpty(),
                call.argument<String>("payload").orEmpty(),
                result,
            )
            "clear" -> clear(call.argument<String>("path").orEmpty(), result)
            else -> result.notImplemented()
        }
    }

    /**
     * Play services carries the Data Layer, and the FLOSS build ships without
     * it. Callers get `false` rather than an exception so a pairing entry point
     * can hide itself.
     */
    private fun isAvailable(): Boolean =
        GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS

    private fun nodes(result: MethodChannel.Result) {
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                result.success(
                    nodes.map { mapOf("id" to it.id, "name" to it.displayName, "nearby" to it.isNearby) },
                )
            }
            .addOnFailureListener { result.success(emptyList<Map<String, Any>>()) }
    }

    private fun send(path: String, payload: String, nodeId: String?, result: MethodChannel.Result) {
        val bytes = payload.toByteArray(StandardCharsets.UTF_8)
        val client = Wearable.getMessageClient(context)
        if (nodeId != null) {
            client.sendMessage(nodeId, path, bytes)
                .addOnSuccessListener { result.success(true) }
                .addOnFailureListener { result.success(false) }
            return
        }
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) {
                    result.success(false)
                    return@addOnSuccessListener
                }
                var remaining = nodes.size
                var anyDelivered = false
                nodes.forEach { node ->
                    client.sendMessage(node.id, path, bytes)
                        .addOnSuccessListener { anyDelivered = true }
                        .addOnCompleteListener {
                            remaining -= 1
                            if (remaining == 0) result.success(anyDelivered)
                        }
                }
            }
            .addOnFailureListener { result.success(false) }
    }

    private fun publish(path: String, payload: String, result: MethodChannel.Result) {
        val request = PutDataMapRequest.create(path).apply {
            dataMap.putString(PAYLOAD_KEY, payload)
        }
        Wearable.getDataClient(context)
            .putDataItem(request.asPutDataRequest().setUrgent())
            .addOnSuccessListener { result.success(true) }
            .addOnFailureListener { result.success(false) }
    }

    private fun clear(path: String, result: MethodChannel.Result) {
        Wearable.getDataClient(context)
            .deleteDataItems(android.net.Uri.parse("wear://*$path"))
            .addOnSuccessListener { result.success(true) }
            .addOnFailureListener { result.success(false) }
    }

    private inline fun forEachChangedItem(
        buffer: DataEventBuffer,
        body: (path: String, payload: String, nodeId: String?) -> Unit,
    ) {
        buffer.forEach { event ->
            if (event.type != DataEvent.TYPE_CHANGED) return@forEach
            val item = event.dataItem
            val payload = DataMapItem.fromDataItem(item).dataMap.getString(PAYLOAD_KEY) ?: return@forEach
            body(item.uri.path.orEmpty(), payload, item.uri.host)
        }
    }

    private fun emit(delivery: String, path: String, payload: String, nodeId: String?) {
        main.post {
            events?.success(
                mapOf(
                    "delivery" to delivery,
                    "path" to path,
                    "payload" to payload,
                    "nodeId" to nodeId,
                ),
            )
        }
    }
}
