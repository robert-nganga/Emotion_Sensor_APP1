import 'dart:math' as math;

import 'package:app/models/sensor_data.dart';

class FeatureExtractor {
  /// Extract features from a data window.
  /// [dataWindow] should be a list of channels (List<List<double>>),
  /// where dataWindow[39] = PPG and dataWindow[37] = GSR.
  static Map<String, double> extractFeatures(
    List<SensorData> dataWindow, {
    double samplingRate = 128.0,
  }) {
    final Map<String, double> features = {};

    // Extract PPG (39) and GSR (37)
    final List<double> ppg =
        dataWindow.where((d)=> d.ppg != null).map((d)=> d.ppg!).toList();
    final List<double> gsr =
        dataWindow.where((d)=> d.grs != null).map((d)=> d.grs!).toList();


    // PPG Features
    if (ppg.isNotEmpty) {
      final List<int> peaks = findPeaks(ppg, samplingRate: samplingRate);

      if (peaks.length >= 2) {
        final double hr = calculateHeartRate(peaks, ppg.length, samplingRate);
        features['hr'] = hr;

        if (peaks.length >= 3) {
          final double hrv = calculateRmssd(peaks, samplingRate);
          features['hrv'] = hrv;
        }
      }

      features['signal_quality'] = calculateSignalQuality(ppg);
      features['pulse_amplitude'] =
          calculatePulseAmplitude(ppg, peaks, samplingRate);
    }

    // GSR Features
    if (gsr.isNotEmpty) {
      features['gsr_mean'] = calculateGsrMean(gsr);
      features['gsr_std'] = calculateGsrStd(gsr);
      features['gsr_slope'] = calculateGsrSlope(gsr, samplingRate);
      features['gsr_peak_count'] =
          calculateGsrPeakCount(gsr, samplingRate).toDouble();
    }

    return features;
  }

  // ---------------- GSR ----------------

  static double calculateGsrMean(List<double> gsr) {
    if (gsr.isEmpty) return 0.0;
    return _mean(gsr);
  }

  static double calculateGsrStd(List<double> gsr) {
    if (gsr.length < 2) return 0.0;
    return _std(gsr, ddof: 1);
  }

  static double calculateGsrSlope(List<double> gsr, double samplingRate) {
    if (gsr.length < 2) return 0.0;
    final int n = gsr.length;
    final List<double> x = List<double>.generate(n, (i) => i / samplingRate);
    final double sumX = x.fold(0.0, (a, b) => a + b);
    final double sumY = gsr.fold(0.0, (a, b) => a + b);
    double sumXY = 0.0, sumX2 = 0.0;
    for (int i = 0; i < n; i++) {
      sumXY += x[i] * gsr[i];
      sumX2 += x[i] * x[i];
    }
    final double denom = (n * sumX2 - sumX * sumX);
    if (denom.abs() < 1e-12) return 0.0;
    final double slope = (n * sumXY - sumX * sumY) / denom;
    return _clip(slope, -1000.0, 1000.0);
  }

  static int calculateGsrPeakCount(List<double> gsr, double samplingRate) {
    if (gsr.length < 3) return 0;
    final int windowSize = math.max(1, (samplingRate * 0.5).floor());
    final List<double> smoothed = _movingAverageValid(gsr, windowSize);
    if (smoothed.length < 3) return 0;

    final List<double> derivative =
        _diff(smoothed).map((v) => v * samplingRate).toList();
    final double threshold = _std(derivative, ddof: 1) * 1.5;
    final int minDistance = math.max(1, (samplingRate * 2.0).floor());

    final List<int> peaks = _findLocalMaxima(
      derivative,
      threshold: threshold,
      minDistance: minDistance,
    );
    return peaks.length;
  }

  // ---------------- PPG ----------------

  static List<int> findPeaks(List<double> signal, {required double samplingRate}) {
    final int minDistance = math.max(1, (samplingRate * 0.3).floor());
    const int windowSize = 5;
    final List<double> smoothed = _movingAverageValid(signal, windowSize);
    if (smoothed.isEmpty) return <int>[];

    final double m = _mean(smoothed);
    final double mx = smoothed.reduce(math.max);
    final double threshold = m + (mx - m) * 0.3;

    final List<int> peaks = _findLocalMaxima(
      smoothed,
      threshold: threshold,
      minDistance: minDistance,
    );

    final int offset = (windowSize - 1) ~/ 2;
    return peaks
        .map((i) => i + offset)
        .where((idx) => idx >= 0 && idx < signal.length)
        .toList();
  }

  static double calculateHeartRate(
      List<int> peaks, int totalSamples, double samplingRate) {
    if (peaks.length < 2) return 0.0;
    final List<int> diffs = _diffInt(peaks);
    final double totalInterval = diffs.fold(0.0, (a, b) => a + b) / samplingRate;
    final double avgInterval = totalInterval / (peaks.length - 1);
    if (avgInterval <= 0) return 0.0;
    final double hr = 60.0 / avgInterval;
    return _clip(hr, 30.0, 200.0);
  }

  static double calculateRmssd(List<int> peaks, double samplingRate) {
    if (peaks.length < 3) return 0.0;
    final List<int> intervalSamples = _diffInt(peaks);
    final List<double> intervalsMs =
        intervalSamples.map((s) => s / samplingRate * 1000.0).toList();
    if (intervalsMs.length < 2) return 0.0;
    final List<double> diffSq = _diff(intervalsMs).map((d) => d * d).toList();
    final double meanSq = _mean(diffSq);
    final double rmssd = math.sqrt(meanSq);
    return _clip(rmssd, 0.0, 1000.0);
  }

  static double calculateSignalQuality(List<double> signal) {
    if (signal.isEmpty) return 0.0;
    final double mean = _mean(signal);
    final double std = (signal.length < 2) ? 0.0 : _std(signal, ddof: 1);
    final double ratio = (std > 0) ? (mean / std) : 0.0;
    return _clip(ratio, 0.0, 100.0);
  }

  static double calculatePulseAmplitude(
      List<double> signal, List<int> peaks, double samplingRate) {
    if (peaks.isEmpty || signal.isEmpty) return 0.0;
    final int windowSize = (samplingRate * 0.4).floor();
    final List<double> amplitudes = [];
    for (final peak in peaks) {
      if (peak > windowSize && peak < signal.length - windowSize) {
        final List<double> window =
            signal.sublist(peak - windowSize, peak + windowSize);
        final double minVal = window.reduce(math.min);
        final double amplitude = signal[peak] - minVal;
        if (amplitude > 0) amplitudes.add(amplitude);
      }
    }
    return amplitudes.isNotEmpty ? _mean(amplitudes) : 0.0;
  }

  // ---------------- Helpers ----------------

  static double _mean(List<double> data) =>
      data.fold(0.0, (a, b) => a + b) / data.length;

  static double _std(List<double> data, {int ddof = 0}) {
    if (data.length <= ddof) return 0.0;
    final double mean = _mean(data);
    final double sumSq =
        data.fold(0.0, (a, b) => a + math.pow(b - mean, 2).toDouble());
    return math.sqrt(sumSq / (data.length - ddof));
  }

  static List<double> _diff(List<double> data) =>
      [for (int i = 1; i < data.length; i++) data[i] - data[i - 1]];

  static List<int> _diffInt(List<int> data) =>
      [for (int i = 1; i < data.length; i++) data[i] - data[i - 1]];

  static List<double> _movingAverageValid(List<double> data, int window) {
    if (data.length < window) return [];
    final List<double> result = [];
    final double invWin = 1.0 / window;
    for (int i = 0; i <= data.length - window; i++) {
      final double sum =
          data.sublist(i, i + window).fold(0.0, (a, b) => a + b);
      result.add(sum * invWin);
    }
    return result;
  }

  static List<int> _findLocalMaxima(List<double> data,
      {required double threshold, required int minDistance}) {
    final List<int> peaks = [];
    int lastPeak = -minDistance;
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > threshold && data[i] > data[i - 1] && data[i] > data[i + 1]) {
        if (i - lastPeak >= minDistance) {
          peaks.add(i);
          lastPeak = i;
        }
      }
    }
    return peaks;
  }

  static double _clip(double v, double minVal, double maxVal) =>
      v.clamp(minVal, maxVal);
}
