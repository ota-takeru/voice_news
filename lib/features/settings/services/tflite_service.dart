// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:tflite_flutter/tflite_flutter.dart';

// class TfliteService {
//   late Map<String, int> _symbolToId;
//   late Interpreter _fastSpeechInterpreter;
//   late Interpreter _mbMelGanInterpreter;

//   Future<void> init() async {
//     try {
//       await loadTokenMapping();
//       await loadFastSpeechModel();
//       await loadMBMelGanModel();
//     } catch (e) {
//       print("Initialization failed: $e");
//       rethrow;
//     }
//   }

//   Future<void> loadTokenMapping() async {
//     try {
//       String jsonString =
//           await rootBundle.loadString('assets/models/ljspeech_mapper.json');
//       Map<String, dynamic> jsonMap = json.decode(jsonString);

//       if (!jsonMap.containsKey('symbol_to_id')) {
//         throw Exception("JSON does not contain 'symbol_to_id' key");
//       }

//       _symbolToId = Map<String, int>.from(jsonMap['symbol_to_id']);
//     } catch (e) {
//       print("Failed to load token mapping: $e");
//       rethrow;
//     }
//   }

//   Future<void> loadFastSpeechModel() async {
//     try {
//       _fastSpeechInterpreter =
//           await Interpreter.fromAsset('assets/models/fastspeech_quant.tflite');
//     } catch (e) {
//       print("Failed to load FastSpeech model: $e");
//       rethrow;
//     }
//   }

//   Future<void> loadMBMelGanModel() async {
//     try {
//       _mbMelGanInterpreter =
//           await Interpreter.fromAsset('assets/models/hifigan_float16.tflite');
//     } catch (e) {
//       print("Failed to load MB-MelGAN model: $e");
//       rethrow;
//     }
//   }

//   String normalizeText(String text) {
//     text = text.toLowerCase();
//     // text = text.replaceAll(RegExp(r"[^\w\s']"), '');
//     // 日本語の文字を許可する正規表現に修正
//     text = text.replaceAll(RegExp(r"[^\w\s'\u3040-\u30FF\u4E00-\u9FFF]"), '');
//     text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
//     return text;
//   }

//   List<int> textToSequence(String text) {
//     String normalizedText = normalizeText(text);
//     if (normalizedText.isEmpty) {
//       return [];
//     }

//     List<String> characters = normalizedText.split('');

//     List<int> sequence = [];
//     for (String char in characters) {
//       if (_symbolToId.containsKey(char)) {
//         sequence.add(_symbolToId[char]!);
//       } else if (_symbolToId.containsKey(' ')) {
//         sequence.add(_symbolToId[' ']!);
//       } else {
//         // 未定義の文字の場合、スキップまたはデフォルトの値を使用
//         continue;
//       }
//     }
//     return sequence;
//   }

//   Future<List<List<double>>> runFastSpeech2(List<int> inputIds) async {
//     try {
//       // 入力テンソルのリサイズ
//       _fastSpeechInterpreter.resizeInputTensor(0, [1, inputIds.length]);
//       _fastSpeechInterpreter.resizeInputTensor(1, [1]);
//       _fastSpeechInterpreter.resizeInputTensor(2, [1]);
//       _fastSpeechInterpreter.resizeInputTensor(3, [1]);
//       _fastSpeechInterpreter.resizeInputTensor(4, [1]);
//       _fastSpeechInterpreter.allocateTensors();

//       // 入力データの準備
//       var inputIdsTensor = [inputIds];
//       var speakersTensor = [
//         [0]
//       ]; // 2次元リストにする
//       var speedRatiosTensor = [
//         [1.0]
//       ];
//       var f0RatiosTensor = [
//         [1.0]
//       ];
//       var energyRatiosTensor = [
//         [1.0]
//       ];

//       var inputs = [
//         inputIdsTensor,
//         speakersTensor,
//         speedRatiosTensor,
//         f0RatiosTensor,
//         energyRatiosTensor
//       ];

//       // 出力テンソルの形状を取得
//       var output0 = _fastSpeechInterpreter.getOutputTensor(0);
//       var output1 = _fastSpeechInterpreter.getOutputTensor(1);

//       var output0Shape = output0.shape; // 例: [1, melLength, 80]
//       var output1Shape = output1.shape; // 例: [1]

//       // 出力バッファの初期化
//       var output0Data = List.generate(
//         output0Shape[0],
//         (_) => List.generate(
//           output0Shape[1],
//           (_) => List.filled(output0Shape[2], 0.0),
//         ),
//       );

//       var output1Data = List.filled(output1Shape[0], 0);

//       var outputs = {0: output0Data, 1: output1Data};

//       // モデルの実行
//       _fastSpeechInterpreter.runForMultipleInputs(inputs, outputs);

//       var melSpectrogram = outputs[0] as List<List<List<double>>>;

//       return melSpectrogram[0];
//     } catch (e) {
//       print("Error running FastSpeech model: $e");
//       rethrow;
//     }
//   }

//   Future<List<double>> runMBMelGan(List<List<double>> melSpectrogram) async {
//     try {
//       // 入力テンソルのリサイズ
//       _mbMelGanInterpreter.resizeInputTensor(
//           0, [1, melSpectrogram.length, melSpectrogram[0].length]);
//       _mbMelGanInterpreter.allocateTensors();

//       var input = [melSpectrogram];

//       // 出力テンソルの形状を取得
//       var outputTensor = _mbMelGanInterpreter.getOutputTensor(0);
//       var outputShape = outputTensor.shape; // 例: [1, outputLength]

//       // 出力バッファの初期化
//       var outputData = List.generate(
//         outputShape[0],
//         (_) => List.filled(outputShape[1], 0.0),
//       );

//       var outputs = {0: outputData};

//       // モデルの実行
//       _mbMelGanInterpreter.runForMultipleInputs([input], outputs);

//       var audioWaveform = outputs[0] as List<List<double>>;

//       return audioWaveform[0];
//     } catch (e) {
//       print("Error running MB-MelGAN model: $e");
//       rethrow;
//     }
//   }

//   Future<List<double>> generateWaveForm(String text) async {
//     try {
//       print("Generating waveform for: $text");
//       if (text.isEmpty) {
//         return [];
//       }
//       List<int> inputIds = textToSequence(text);
//       print("inputIds: $inputIds");
//       List<List<double>> melSpectrogram = await runFastSpeech2(inputIds);
//       List<double> audioWaveform = await runMBMelGan(melSpectrogram);
//       return audioWaveform;
//     } catch (e) {
//       print("Error generating waveform: $e");
//       rethrow;
//     }
//   }

//   void dispose() {
//     try {
//       _fastSpeechInterpreter.close();
//       _mbMelGanInterpreter.close();
//     } catch (e) {
//       print("Error disposing interpreters: $e");
//     }
//   }
// }

import 'dart:async';
import 'package:flutter/services.dart';

class TfliteService {
  static const MethodChannel _channel = MethodChannel('tts_service');

  Future<String> synthesize(String text) async {
    try {
      final String audioFilePath =
          await _channel.invokeMethod('synthesizeSpeech', {'text': text});

      return audioFilePath;
    } catch (e) {
      // エラーハンドリング
      print('Error synthesizing speech: $e');
      rethrow;
    }
  }
}
