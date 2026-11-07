package com.th3.english

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), RecognitionListener {
    private lateinit var speechChannel: MethodChannel
    private var generation = 0
    private var phase = "idle"
    private var recognizer: SpeechRecognizer? = null
    private var pending: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null
    private var permissionRequestCode = 0
    private var permissionAction: (() -> Unit)? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var started = 0L
    private var ended = 0L
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { fail("TIMEOUT", "Hết thời gian thu âm. Hãy thử lại.") }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReminderReceiver.schedule(this)
        tts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val language = tts?.setLanguage(Locale.US) ?: TextToSpeech.LANG_NOT_SUPPORTED
                ttsReady = language >= TextToSpeech.LANG_AVAILABLE
                tts?.setSpeechRate(0.8f)
            }
        }
        speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "th3/speech")
        speechChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listen" -> {
                    if (pending != null || permissionRequestCode != 0) result.error("BUSY", "Đang thu âm hoặc xin quyền.", null)
                    else withPermission(Manifest.permission.RECORD_AUDIO, 201, result) { listen(result) }
                }
                "stop" -> {
                    if (pending != null && phase == "ready") {
                        state("processing")
                        ended = SystemClock.elapsedRealtime()
                        handler.removeCallbacks(timeout)
                        handler.postDelayed(timeout, 15000)
                        try { recognizer?.stopListening() }
                        catch (e: Exception) { fail("STOP", "Không thể kết thúc thu âm: ${e.message}") }
                    }
                    result.success(null)
                }
                "cancel" -> {
                    if (permissionRequestCode == 201) {
                        permissionAction = null
                        permissionResult?.error("CANCELLED", "Đã hủy thu âm.", null)
                        permissionResult = null
                    }
                    fail("CANCELLED", "Đã hủy thu âm.")
                    result.success(null)
                }
                "speak" -> {
                    if (!ttsReady) result.error("TTS", "Chưa có giọng tiếng Anh. Cài dữ liệu Text-to-speech trong cài đặt Android.", null)
                    else if (pending != null) result.error("BUSY", "Hãy kết thúc thu âm trước khi nghe mẫu.", null)
                    else {
                        val status = tts?.speak(call.argument<String>("text") ?: "", TextToSpeech.QUEUE_FLUSH, null, "sample")
                        if (status == TextToSpeech.ERROR) result.error("TTS", "Không phát được giọng mẫu.", null) else result.success(null)
                    }
                }
                "reminder" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val action = {
                        getSharedPreferences("reminder", MODE_PRIVATE).edit()
                            .putBoolean("enabled", enabled)
                            .putInt("hour", call.argument<Int>("hour") ?: 20)
                            .putInt("minute", call.argument<Int>("minute") ?: 0).apply()
                        ReminderReceiver.schedule(this)
                        result.success(null)
                    }
                    if (enabled && android.os.Build.VERSION.SDK_INT >= 33) withPermission(Manifest.permission.POST_NOTIFICATIONS, 202, result, action)
                    else action()
                }
                "testReminder" -> {
                    val action = { ReminderReceiver.notify(this); result.success(null) }
                    if (android.os.Build.VERSION.SDK_INT >= 33) withPermission(Manifest.permission.POST_NOTIFICATIONS, 202, result, action) else action()
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun withPermission(permission: String, code: Int, result: MethodChannel.Result, action: () -> Unit) {
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) action()
        else if (permissionRequestCode != 0) result.error("BUSY", "Đang xin quyền khác.", null)
        else {
            permissionRequestCode = code
            permissionResult = result; permissionAction = action
            requestPermissions(arrayOf(permission), code)
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 201 && requestCode != 202) return
        val result = permissionResult
        val action = permissionAction
        permissionRequestCode = 0
        permissionResult = null; permissionAction = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) action?.invoke()
        else result?.error("PERMISSION", "Quyền bị từ chối. Bạn có thể cấp lại trong cài đặt ứng dụng.", null)
    }
    private fun listen(result: MethodChannel.Result) {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            result.error("UNAVAILABLE", "Máy chưa có dịch vụ nhận dạng. Cài/bật Speech Services và giọng tiếng Anh.", null); return
        }
        tts?.stop()
        pending = result; started = 0L; ended = 0L
        state("starting")
        handler.postDelayed(timeout, 45000)
        try {
            releaseRecognizer()
            recognizer = SpeechRecognizer.createSpeechRecognizer(this)
            val session = generation
            recognizer?.setRecognitionListener(object : RecognitionListener {
                private fun active() = session == generation && pending != null
                override fun onReadyForSpeech(params: Bundle?) { if (active()) this@MainActivity.onReadyForSpeech(params) }
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() { if (active()) this@MainActivity.onEndOfSpeech() }
                override fun onError(error: Int) { if (active()) this@MainActivity.onError(error) }
                override fun onResults(results: Bundle?) { if (active()) this@MainActivity.onResults(results) }
                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            recognizer?.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            })
        } catch (e: Exception) { fail("START", "Không thể mở micro: ${e.message}") }
    }
    private fun state(value: String) {
        phase = value
        speechChannel.invokeMethod("speechState", value)
    }
    private fun releaseRecognizer() {
        generation++ // Ignore late callbacks from the previous recognition session.
        val old = recognizer
        recognizer = null
        old?.cancel()
        old?.destroy()
    }
    private fun fail(code: String, message: String) {
        val result = pending ?: return
        pending = null
        handler.removeCallbacks(timeout)
        releaseRecognizer()
        state("idle")
        result.error(code, message, null)
    }
    override fun onResults(results: Bundle?) {
        val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
        if (text.isNullOrBlank()) { fail("EMPTY", "Không nghe rõ. Hãy thử lại."); return }
        handler.removeCallbacks(timeout)
        val result = pending; pending = null
        releaseRecognizer()
        state("idle")
        val confidence = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)?.firstOrNull()?.takeIf { it >= 0 }
        result?.success(mapOf("text" to text, "confidence" to confidence?.toDouble(),
            "seconds" to (((if (ended > 0) ended else SystemClock.elapsedRealtime()) - (if (started > 0) started else SystemClock.elapsedRealtime())) / 1000).toInt().coerceIn(1, 45)))
    }
    override fun onError(error: Int) {
        val message = when(error) {
            SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Lỗi mạng. Kiểm tra Internet và thử lại."
            SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Không nghe rõ lời nói. Hãy đọc gần micro ở nơi yên tĩnh."
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Dịch vụ giọng nói đang bận. Thử lại sau."
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Chưa được cấp quyền micro."
            else -> "Không nhận dạng được giọng nói (mã $error). Hãy thử lại."
        }
        fail("SPEECH_$error", message)
    }
    override fun onReadyForSpeech(params: Bundle?) {
        if (started == 0L) started = SystemClock.elapsedRealtime()
        if (phase == "starting") state("ready")
    }
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {
        ended = SystemClock.elapsedRealtime()
        state("processing")
        handler.removeCallbacks(timeout)
        handler.postDelayed(timeout, 15000)
    }
    override fun onPartialResults(partialResults: Bundle?) {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
    override fun onStop() {
        if (pending != null) fail("CANCELLED", "Phiên thu âm đã dừng khi ứng dụng vào nền.")
        tts?.stop()
        super.onStop()
    }
    override fun onDestroy() {
        handler.removeCallbacks(timeout)
        releaseRecognizer(); tts?.shutdown()
        super.onDestroy()
    }
}
