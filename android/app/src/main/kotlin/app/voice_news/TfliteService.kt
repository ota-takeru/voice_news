package app.voice_news

import android.content.Context
import org.tensorflow.lite.Interpreter
import java.io.*
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import org.json.JSONObject
import org.tensorflow.lite.flex.FlexDelegate
import java.util.Locale
import com.google.gson.Gson

class TfliteService(private val context: Context) {

    private val gson = Gson()
    fun runTtsInference(text: String): String {
        println("Text to synthesize: $text")
        val text2 = "hello world this is a test of the text to speech system"
        // トークナイザーを読み込み
        val tokenizer = loadTokenizer()

        // FastSpeech2モデルで推論
        val (tacOutput, sampleRate) = fastspeechInfer(text2, tokenizer)
        println("FastSpeech2 inference done")

        // MelGANで音声を生成
        val waveform = runMelgan(tacOutput)
        println("MelGAN inference done")

        // 音声データをWAVファイルに保存
        val audioFilePath = saveWaveformAsWav(waveform, sampleRate)
        println("WAV file saved: $audioFilePath")
        // ファイルパスを返す
        return audioFilePath
    }

    private fun loadTokenizer(): Map<String, Int> {
        val jsonStr = context.assets.open("ljspeech_mapper.json").bufferedReader().use { it.readText() }
        println("Loaded JSON string: $jsonStr")
        val jsonObject = JSONObject(jsonStr)

        val symbolToId = jsonObject.getJSONObject("symbol_to_id")
        println("Contents of 'symbol_to_id': $symbolToId")

        val tokenizer = mutableMapOf<String, Int>()
        val keys = symbolToId.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = symbolToId.optInt(key, -1) // 安全に値を取得
            if (value != -1) {
                tokenizer[key] = value
            } else {
                println("Failed to parse value for key: $key")
            }
        }

        println("Final tokenizer size: $tokenizer")
        return tokenizer
    }


    private fun fastspeechInfer(inputText: String, tokenizer: Map<String, Int>): Pair<Array<Array<FloatArray>>, Int> {
        val model = loadModelFile("fastspeech_quant.tflite")

        val options = Interpreter.Options()
        val flexDelegate = FlexDelegate()
        options.addDelegate(flexDelegate)

        val interpreter = Interpreter(model, options)

        // テキストをトークンIDに変換（int型の配列として保持）
        val inputIds = textToSequence(inputText, tokenizer)
        println(inputIds.contentToString())

        // 入力テンソルのサイズを調整
        interpreter.resizeInput(0, intArrayOf(1, inputIds.size)) // [1, シーケンス長]
        interpreter.resizeInput(1, intArrayOf(1))               // 他の入力
        interpreter.resizeInput(2, intArrayOf(1))
        interpreter.resizeInput(3, intArrayOf(1))
        interpreter.resizeInput(4, intArrayOf(1))
        interpreter.allocateTensors() // 必須

        // 入力データを準備
        val inputs = arrayOf(
            arrayOf(inputIds),
            intArrayOf(0),       // INT32, shape=[1]
            floatArrayOf(1.0f),  // FLOAT32, shape=[1]
            floatArrayOf(1.0f),  // FLOAT32, shape=[1]
            floatArrayOf(1.0f)   // FLOAT32, shape=[1]
        )

        // 出力サイズを取得して動的に配列を作成
        val output0Shape = interpreter.getOutputTensor(0).shape() // [1, X, Y]
        val output1Shape = interpreter.getOutputTensor(1).shape() // [1, X, Y]

        val output0 = Array(output0Shape[0]) { Array(output0Shape[1]) { FloatArray(output0Shape[2]) } }
        val output1 = Array(output1Shape[0]) { Array(output1Shape[1]) { FloatArray(output1Shape[2]) } }

        val outputs = mutableMapOf(
            0 to output0,
            1 to output1
        )
        println("Output shapes: ${outputs.mapValues { it.value.size }}")

        try {
            interpreter.runForMultipleInputsOutputs(inputs, outputs as Map<Int, Any>)
        } catch (e: Exception) {
            println("Error during inference: ${e.localizedMessage}")
        }

        interpreter.close()

        // FastSpeech2の出力形式をデバッグ
        println("FastSpeech2 Output0 shape: ${output0Shape.contentToString()}")
        println("FastSpeech2 Output1 shape: ${output1Shape.contentToString()}")
        println("Output1 sample: ${output1[0][0].contentToString()}")

        return Pair(output0, 22050)
    }


    private fun runMelgan(melSpec: Array<Array<FloatArray>>): DoubleArray {
        // melSpec: [1, T, MelDim] と仮定 (多くの場合 MelDim = 80)
        val T = melSpec[0].size
        val melDim = melSpec[0][0].size

        // MelGANが [1, T, MelDim] を期待する場合に対応
        val transposedMelSpec = Array(1) { Array(T) { FloatArray(melDim) } }
        for (t in 0 until T) {
            for (m in 0 until melDim) {
                transposedMelSpec[0][t][m] = melSpec[0][t][m]
            }
        }

        val model = loadModelFile("melgan_float16.tflite")

        val options = Interpreter.Options()
        val flexDelegate = FlexDelegate()
        options.addDelegate(flexDelegate)

        val interpreter = Interpreter(model, options)
        println("Interpreter created")

        println("MelSpec shape: [${melSpec.size}, ${T}, ${melDim}]")
        println("Transposed shape: [1, $T, $melDim]")

        val inputShape = interpreter.getInputTensor(0).shape()
        println("Input shape before resize: ${inputShape.contentToString()}")

        // MelGAN入力を [1, T, MelDim] にリサイズ
        interpreter.resizeInput(0, intArrayOf(1, T, melDim))
        interpreter.allocateTensors()

        // リサイズ後の入力テンソル形状をデバッグ出力
        val resizedShape = interpreter.getInputTensor(0).shape()
        println("Input shape after resize: ${resizedShape.contentToString()}")

        // 出力データ用のバッファを準備（可変長に対応する）
        val outputBuffer = Array(1) { Array(20480) { FloatArray(1) } }

        try {
            interpreter.run(transposedMelSpec, outputBuffer)
        } catch (e: Exception) {
            println("Error during inference: ${e.localizedMessage}")
            throw e
        } finally {
            interpreter.close()
        }

        // 出力データをフラットな配列に変換
        val totalSize = outputBuffer.sumOf { it.size }
        val flatArray = DoubleArray(totalSize)
        var index = 0
        for (array in outputBuffer) {
            for (value in array) {
                flatArray[index++] = value[0].toDouble()
            }
        }
        return flatArray
    }






    private fun saveWaveformAsWav(waveform: DoubleArray, sampleRate: Int): String {
        val fileName = "output_${System.currentTimeMillis()}.wav"
        val file = File(context.cacheDir, fileName)

        val byteBuffer = ByteBuffer.allocate(waveform.size * 2) // 16-bit PCM
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        for (sample in waveform) {
            val value = (sample * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            byteBuffer.putShort(value.toShort())
        }

        val wavData = createWavFile(byteBuffer.array(), sampleRate)

        val outputStream = FileOutputStream(file)
        outputStream.write(wavData)
        outputStream.close()

        return file.absolutePath
    }

    private fun createWavFile(audioData: ByteArray, sampleRate: Int): ByteArray {
        val byteRate = 16 * sampleRate / 8
        val wavHeader = ByteArray(44)

        // RIFF/WAVE header
        wavHeader[0] = 'R'.code.toByte()
        wavHeader[1] = 'I'.code.toByte()
        wavHeader[2] = 'F'.code.toByte()
        wavHeader[3] = 'F'.code.toByte()
        val chunkSize = 36 + audioData.size
        wavHeader[4] = (chunkSize and 0xff).toByte()
        wavHeader[5] = ((chunkSize shr 8) and 0xff).toByte()
        wavHeader[6] = ((chunkSize shr 16) and 0xff).toByte()
        wavHeader[7] = ((chunkSize shr 24) and 0xff).toByte()
        wavHeader[8] = 'W'.code.toByte()
        wavHeader[9] = 'A'.code.toByte()
        wavHeader[10] = 'V'.code.toByte()
        wavHeader[11] = 'E'.code.toByte()
        wavHeader[12] = 'f'.code.toByte()
        wavHeader[13] = 'm'.code.toByte()
        wavHeader[14] = 't'.code.toByte()
        wavHeader[15] = ' '.code.toByte()
        wavHeader[16] = 16 // Subchunk1Size for PCM
        wavHeader[17] = 0
        wavHeader[18] = 1 // AudioFormat PCM
        wavHeader[19] = 0
        wavHeader[20] = 1 // NumChannels
        wavHeader[21] = 0
        wavHeader[22] = (sampleRate and 0xff).toByte()
        wavHeader[23] = ((sampleRate shr 8) and 0xff).toByte()
        wavHeader[24] = ((sampleRate shr 16) and 0xff).toByte()
        wavHeader[25] = ((sampleRate shr 24) and 0xff).toByte()
        wavHeader[26] = (byteRate and 0xff).toByte()
        wavHeader[27] = ((byteRate shr 8) and 0xff).toByte()
        wavHeader[28] = ((byteRate shr 16) and 0xff).toByte()
        wavHeader[29] = ((byteRate shr 24) and 0xff).toByte()
        wavHeader[30] = (2).toByte() // BlockAlign
        wavHeader[31] = 0
        wavHeader[32] = 16 // BitsPerSample
        wavHeader[33] = 0
        wavHeader[34] = 'd'.code.toByte()
        wavHeader[35] = 'a'.code.toByte()
        wavHeader[36] = 't'.code.toByte()
        wavHeader[37] = 'a'.code.toByte()
        val dataSize = audioData.size
        wavHeader[38] = (dataSize and 0xff).toByte()
        wavHeader[39] = ((dataSize shr 8) and 0xff).toByte()
        wavHeader[40] = ((dataSize shr 16) and 0xff).toByte()
        wavHeader[41] = ((dataSize shr 24) and 0xff).toByte()
        wavHeader[42] = 0
        wavHeader[43] = 0

        val wavFile = ByteArray(wavHeader.size + audioData.size)
        System.arraycopy(wavHeader, 0, wavFile, 0, wavHeader.size)
        System.arraycopy(audioData, 0, wavFile, wavHeader.size, audioData.size)

        return wavFile
    }

    private fun loadModelFile(modelPath: String): MappedByteBuffer {
        val assetFileDescriptor = context.assets.openFd(modelPath)
        val inputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = assetFileDescriptor.startOffset
        val declaredLength = assetFileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    private fun textToSequence(text: String, tokenizer: Map<String, Int>): IntArray {
        return text.lowercase(Locale.getDefault()).mapNotNull { char -> tokenizer[char.toString()] }.toIntArray()
    }
}
