import 'dart:math';

import '../models/sensor_data.dart';

class FeatureExtractor {
  static Map<String, double> extractFeatures(List<SensorData> dataWindow) {
    Map<String, double> features = {};

    List<double> accelX = dataWindow.where((d) => d.accelX != null).map((d) => d.accelX!).toList();
    List<double> gsr = dataWindow.where((d) => d.grs != null).map((d) => d.grs!).toList();
    List<double> ppg = dataWindow.where((d) => d.ppg != null).map((d) => d.ppg!).toList();

    if (accelX.isNotEmpty) {
      features['accel_mean'] = _mean(accelX);
      features['accel_std'] = _std(accelX);
      features['accel_variance'] = _variance(accelX);
      features['accel_range'] = _range(accelX);
    }

    if (gsr.isNotEmpty) {
      features['gsr_mean'] = _mean(gsr);
      features['gsr_std'] = _std(gsr);
      features['gsr_slope'] = _slope(gsr);
      features['gsr_peaks'] = _countPeaks(gsr);
    }

    if (ppg.isNotEmpty) {
      features['ppg_mean'] = _mean(ppg);
      features['ppg_std'] = _std(ppg);
      features['ppg_rmssd'] = _rmssd(ppg);
    }

    return features;
  }

  static double _mean(List<double> values) => values.reduce((a, b) => a + b) / values.length;

  static double _std(List<double> values) {
    double mean = _mean(values);
    double variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  static double _variance(List<double> values) {
    double mean = _mean(values);
    return values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
  }

  static double _range(List<double> values) => values.reduce(max) - values.reduce(min);

  static double _slope(List<double> values) {
    int n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }
    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  static double _countPeaks(List<double> values) {
    int peaks = 0;
    double threshold = _std(values) * 0.5;
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i] > values[i - 1] && values[i] > values[i + 1] && values[i] > threshold) {
        peaks++;
      }
    }
    return peaks.toDouble();
  }

  static double _rmssd(List<double> values) {
    double sum = 0;
    for (int i = 1; i < values.length; i++) {
      sum += pow(values[i] - values[i - 1], 2);
    }
    return sqrt(sum / (values.length - 1));
  }

  static double _rms(List<double> values) {
    double sum = values.map((x) => x * x).reduce((a, b) => a + b);
    return sqrt(sum / values.length);
  }
}
