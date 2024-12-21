package app.voice_news

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "tts_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val tfliteService = TfliteService(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "synthesizeSpeech") {
                val text = call.argument<String>("text") ?: ""
                Thread {
                    try {
                        println("main activity: $text")
                        val audioFilePath = tfliteService.runTtsInference(text)
                        runOnUiThread {
                            result.success(audioFilePath)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("ERROR", e.localizedMessage, null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }
}
