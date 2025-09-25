import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EmotionDetector {
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;
  List<String> get labels => _labels;

  Future<void> loadModel() async {
    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      _isModelLoaded = true;
      print('Model loaded successfully with ${_labels.length} labels');
      print('Labels: $_labels');
    } catch (e) {
      print('Failed to load model: $e');
      _isModelLoaded = false;
    }
  }

  Future<Map<String, double>> detectEmotion(img.Image inputImage) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded');
    }

    try {
      // // Decode and preprocess the image
      // img.Image? image = img.decodeImage(inputImage);
      // if (image == null) {
      //   throw Exception('Failed to decode image');
      // }

      // Resize to 224x224 (Teachable Machine default) or check your model's expected input size
      // You may need to adjust this size based on your actual model requirements
      img.Image resizedImage = img.copyResize(inputImage, width: 224, height: 224);

      // Convert to Float32List and normalize (0-1) for RGB input
      var input = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          // Get pixel as Pixel object (new API)
          final pixel = resizedImage.getPixel(x, y);
          // Add RGB values normalized to 0-1
          input[pixelIndex++] = pixel.r / 255.0;     // Red
          input[pixelIndex++] = pixel.g / 255.0;     // Green
          input[pixelIndex++] = pixel.b / 255.0;     // Blue
        }
      }

      // Reshape input for the model [1, 224, 224, 3]
      var inputData = input.reshape([1, 224, 224, 3]);

      // Prepare output tensor
      var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      // Run inference
      _interpreter.run(inputData, output);

      // Process results
      List<double> probabilities = output[0].cast<double>();

      // Create result map
      Map<String, double> results = {};
      for (int i = 0; i < _labels.length; i++) {
        results[_labels[i]] = probabilities[i];
      }

      return results;
    } catch (e) {
      print('Error during emotion detection: $e');
      rethrow;
    }
  }

  String getPredictedEmotion(Map<String, double> results) {
    String maxEmotion = '';
    double maxConfidence = 0.0;

    results.forEach((emotion, confidence) {
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        maxEmotion = emotion;
      }
    });

    return maxEmotion;
  }

  void dispose() {
    _interpreter.close();
  }
}