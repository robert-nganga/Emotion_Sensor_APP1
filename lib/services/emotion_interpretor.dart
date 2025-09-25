import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionInterpretor {
  Interpreter? _interpreter;
  Map<String, dynamic>? _scalerParams;
  final int numFeatures;

  EmotionInterpretor({this.numFeatures = 8});

  Future<void> loadModelAndScalers() async {
    // Load the TFLite model
    _interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');

    // Load the scaler parameters
    final scalerJson = await rootBundle.loadString('assets/scaler_params.json');
    _scalerParams = json.decode(scalerJson);
  }

  bool get isReady => _interpreter != null && _scalerParams != null;

  List<double> predict(List<double> rawInput) {
    if (!isReady) {
      throw Exception("Model or scaler not loaded");
    }

    // 1. Preprocess input
    final featureMean = List<double>.from(_scalerParams!['feature_scaler']['mean']);
    final featureScale = List<double>.from(_scalerParams!['feature_scaler']['scale']);

    List<double> scaledInput = List<double>.filled(numFeatures, 0);
    for (int i = 0; i < numFeatures; i++) {
      scaledInput[i] = (rawInput[i] - featureMean[i]) / featureScale[i];
    }

    final input = [scaledInput];
    final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    // 2. Run inference
    _interpreter!.run(input, output);

    // 3. Postprocess output
    final labelMean = List<double>.from(_scalerParams!['label_scaler']['mean']);
    final labelScale = List<double>.from(_scalerParams!['label_scaler']['scale']);

    List<double> finalOutput = List<double>.filled(2, 0);
    for (int i = 0; i < 2; i++) {
      finalOutput[i] = (output[0][i] * labelScale[i]) + labelMean[i];
    }

    return finalOutput;
  }

  void dispose() {
    _interpreter?.close();
  }
}
