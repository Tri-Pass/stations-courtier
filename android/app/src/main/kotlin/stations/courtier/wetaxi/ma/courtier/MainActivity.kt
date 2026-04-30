package stations.courtier.wetaxi.ma.courtier

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.sunmi.pay.hardware.aidl.AidlConstants
import com.sunmi.pay.hardware.aidlv2.readcard.CheckCardCallbackV2
import com.sunmi.pay.hardware.aidlv2.readcard.ReadCardOptV2
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import sunmi.paylib.SunmiPayKernel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "courtier/card_methods"
    private val EVENT_CHANNEL = "courtier/card_events"

    private var mSMPayKernel: SunmiPayKernel? = null
    private var mReadCardOptV2: ReadCardOptV2? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Guards against findRFCard + findRFCardEx both firing for the same tap,
    // and against the card being held on the reader triggering repeated callbacks.
    // Reset only inside startNfcScan().
    @Volatile private var cardProcessed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        mSMPayKernel = SunmiPayKernel.getInstance()
        mSMPayKernel!!.initPaySDK(this, object : SunmiPayKernel.ConnectCallback {
            override fun onConnectPaySDK() {
                mReadCardOptV2 = mSMPayKernel!!.mReadCardOptV2
                Log.d("NFC", "Sunmi Pay SDK connected")
                mainHandler.post {
                    eventSink?.success(mapOf("status" to "SDK_READY"))
                }
            }

            override fun onDisconnectPaySDK() {
                Log.e("NFC", "Sunmi Pay SDK disconnected")
                mainHandler.post {
                    eventSink?.success(mapOf("event" to "SDK_DISCONNECTED"))
                }
            }
        })
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startNfcScan" -> {
                        if (mReadCardOptV2 != null) {
                            startNfcScan()
                            result.success("OK")
                        } else {
                            result.error("SDK_NOT_READY", "SDK not initialized", null)
                        }
                    }
                    "stopNfcScan" -> {
                        stopNfcScan()
                        result.success("OK")
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                    Log.d("NFC", "EventChannel: listener attached")
                    // Send current SDK state immediately so Flutter knows where we are
                    if (mReadCardOptV2 != null) {
                        sink.success(mapOf("status" to "SDK_READY"))
                    } else {
                        sink.success(mapOf("status" to "SDK_CONNECTING"))
                    }
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("NFC", "EventChannel: listener removed")
                    eventSink = null
                }
            })
    }

    // ── scan control ──────────────────────────────────────────────────────────

    private fun startNfcScan() {
        // Must be reset before the new checkCard call so that when the
        // SDK callback fires on its background thread it sees false.
        cardProcessed = false
        try {
            mReadCardOptV2?.cancelCheckCard()
            mReadCardOptV2?.checkCard(
                AidlConstants.CardType.MIFARE.value,
                mCheckCardCallback,
                60
            )
            Log.d("NFC", "Scan started")
        } catch (e: Exception) {
            Log.e("NFC", "startNfcScan error: ${e.message}")
        }
    }

    private fun stopNfcScan() {
        mainHandler.removeCallbacksAndMessages(null)   // cancel any pending restarts
        try {
            mReadCardOptV2?.cancelCheckCard()
            Log.d("NFC", "Scan stopped")
        } catch (e: Exception) {
            Log.e("NFC", "stopNfcScan error: ${e.message}")
        }
    }

    // ── card callback ─────────────────────────────────────────────────────────

    private fun notifyCardFound(uuid: String) {
        if (cardProcessed) {
            Log.d("NFC", "Duplicate callback ignored for: $uuid")
            return
        }
        cardProcessed = true
        Log.d("NFC", "Card accepted: $uuid")

        // 1. Tell Flutter immediately
        mainHandler.post {
            eventSink?.success(mapOf("event" to "CARD_FOUND", "type" to "NFC", "details" to uuid))
        }

        // 2. Restart the scan automatically on the Kotlin side after 800 ms.
        //    This keeps the restart entirely within Kotlin — no Flutter round-trip,
        //    no timing race between Dart Future.delayed and the Kotlin callback thread.
        mainHandler.postDelayed({
            Log.d("NFC", "Auto-restarting scan after card detection")
            startNfcScan()
        }, 800)
    }

    private val mCheckCardCallback: CheckCardCallbackV2 = object : CheckCardCallback() {
        override fun findRFCard(uuid: String) {
            Log.d("NFC", "findRFCard: $uuid")
            notifyCardFound(uuid)
        }

        override fun findRFCardEx(info: Bundle) {
            val uuid = info.getString("uuid") ?: return
            Log.d("NFC", "findRFCardEx: $uuid")
            notifyCardFound(uuid)
        }

        override fun onError(code: Int, message: String) {
            Log.e("NFC", "Callback error $code: $message")
            if (code == -20001) return          // repeated-call race — harmless, ignore
            if (code == -30005) {               // scan timeout — restart immediately
                mainHandler.postDelayed({ startNfcScan() }, 200)
                return
            }
            // Other errors: notify Flutter and still restart so the reader stays live
            mainHandler.post {
                eventSink?.success(mapOf("event" to "SCAN_ERROR", "code" to code, "message" to message))
            }
            mainHandler.postDelayed({ startNfcScan() }, 500)
        }
    }
}
