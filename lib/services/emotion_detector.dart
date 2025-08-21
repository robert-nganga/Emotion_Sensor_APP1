import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import 'feature_extractor.dart';// your SensorData model

enum EmotionType {
  neutral,
  happy,
  stressed,
  excited,
  calm,
  frustrated
}

class EmotionResult {
  final EmotionType emotion;
  final double confidence;
  final DateTime timestamp;
  final Map<String, double> features;

  EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
    required this.features,
  });
}

class EmotionDetector {
  static const int _windowSize = 50;
  static const int _minDataPoints = 20;

  static EmotionResult? detectEmotion(List<SensorData> sensorDataList) {
    if (sensorDataList.length < _minDataPoints) return null;

    List<SensorData> dataWindow = sensorDataList.length > _windowSize
        ? sensorDataList.sublist(sensorDataList.length - _windowSize)
        : sensorDataList;

    Map<String, double> features = FeatureExtractor.extractFeatures(dataWindow);
    return _classifyEmotion(features);
  }

  static EmotionResult _classifyEmotion(Map<String, double> features) {
    EmotionType emotion = EmotionType.neutral;
    double confidence = 0.5;

    double gsrMean = features['gsr_mean'] ?? 0.0;
    double ppgMean = features['ppg_mean'] ?? 0.0;
    double ppgStd = features['ppg_std'] ?? 0.0;
    double accelStd = features['accel_std'] ?? 0.0;
    double gsrSlope = features['gsr_slope'] ?? 0.0;

    if (gsrMean > 0.7 && ppgMean > 80) {
      if (accelStd > 0.5) {
        emotion = EmotionType.excited;
        confidence = 0.8;
      } else {
        emotion = EmotionType.stressed;
        confidence = 0.75;
      }
    } else if (gsrMean > 0.5 && ppgStd > 10) {
      emotion = EmotionType.frustrated;
      confidence = 0.7;
    } else if (ppgMean > 75 && accelStd > 0.3 && gsrSlope > 0) {
      emotion = EmotionType.happy;
      confidence = 0.75;
    } else if (gsrMean < 0.3 && ppgMean < 70 && accelStd < 0.2) {
      emotion = EmotionType.calm;
      confidence = 0.8;
    } else {
      emotion = EmotionType.neutral;
      confidence = 0.6;
    }

    return EmotionResult(
      emotion: emotion,
      confidence: confidence,
      timestamp: DateTime.now(),
      features: features,
    );
  }

  static Color getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return Colors.yellow;
      case EmotionType.excited:
        return Colors.orange;
      case EmotionType.stressed:
        return Colors.red;
      case EmotionType.frustrated:
        return Colors.deepOrange;
      case EmotionType.calm:
        return Colors.blue;
      case EmotionType.neutral:
        return Colors.grey;
    }
  }

  static String getEmotionDescription(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return "Happy - Positive arousal with moderate activity";
      case EmotionType.excited:
        return "Excited - High arousal with high activity";
      case EmotionType.stressed:
        return "Stressed - High arousal with low activity";
      case EmotionType.frustrated:
        return "Frustrated - Variable arousal with tension";
      case EmotionType.calm:
        return "Calm - Low arousal with relaxed state";
      case EmotionType.neutral:
        return "Neutral - Balanced emotional state";
    }
  }
}
