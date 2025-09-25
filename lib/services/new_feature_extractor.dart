import 'dart:math' as math;

import '../models/sensor_data.dart';

class NewFeatureExtractor {
  static Map<String, double> extractFeatures(
      List<SensorData> dataWindow, {
        double samplingRate = 128.0, // Configurable sampling rate
      }) {
    Map<String, double> features = {};

    List<double> ppg = dataWindow.where((d) => d.ppg != null).map((d) => d.ppg!).toList();
    List<double> gsr = dataWindow.where((d) => d.grs != null).map((d) => d.grs!).toList();

    if (ppg.isNotEmpty) {
      List<int> peaks = findPeaks(ppg, samplingRate: samplingRate);
      if (peaks.length >= 2) {
        double heartRate = calculateHeartRate(peaks, ppg.length, samplingRate);
        features['hr'] = heartRate;

        if (peaks.length >= 3) {
          double hrv = calculateRMSSD(peaks, samplingRate);
          features['hrv'] = hrv;
        }
      }
      features['signal_quality'] = calculateSignalQuality(ppg);
      features['pulse_amplitude'] = calculatePulseAmplitude(ppg, peaks, samplingRate);
    }

    if (gsr.isNotEmpty) {
      features['gsr_mean'] = calculateGSRMean(gsr);
      features['gsr_std'] = calculateGSRStd(gsr);
      features['gsr_slope'] = calculateGSRSlope(gsr, samplingRate);
      features['gsr_peak_count'] = calculateGSRPeakCount(gsr, samplingRate).toDouble();
    }

    return features;
  }

  // GSR Feature Calculation Methods

  static double calculateGSRMean(List<double> gsr) {
    if (gsr.isEmpty) return 0.0;
    return gsr.reduce((a, b) => a + b) / gsr.length;
  }

  static double calculateGSRStd(List<double> gsr) {
    if (gsr.isEmpty) return 0.0;

    double mean = calculateGSRMean(gsr);
    double variance = gsr.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / (gsr.length - 1);
    return math.sqrt(variance);
  }

  static double calculateGSRSlope(List<double> gsr, double samplingRate) {
    if (gsr.length < 2) return 0.0;

    // Linear regression to find slope (trend)
    double n = gsr.length.toDouble();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < gsr.length; i++) {
      double x = i / samplingRate; // Time in seconds
      double y = gsr[i];

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    // Calculate slope using least squares formula
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope.clamp(-1000.0, 1000.0); // Clamp to prevent extreme values
  }

  static int calculateGSRPeakCount(List<double> gsr, double samplingRate) {
    if (gsr.length < 3) return 0;

    // Find SCRs (Skin Conductance Responses) - rapid increases in GSR
    List<double> smoothed = [];
    int windowSize = (samplingRate * 0.5).round(); // 0.5 second smoothing window

    // Apply moving average smoothing
    for (int i = 0; i < gsr.length; i++) {
      int start = (i - windowSize ~/ 2).clamp(0, gsr.length - 1);
      int end = (i + windowSize ~/ 2 + 1).clamp(0, gsr.length);
      double avg = gsr.sublist(start, end).reduce((a, b) => a + b) / (end - start);
      smoothed.add(avg);
    }

    // Calculate first derivative (rate of change)
    List<double> derivative = [];
    for (int i = 1; i < smoothed.length; i++) {
      derivative.add((smoothed[i] - smoothed[i - 1]) * samplingRate);
    }

    // Find peaks in the derivative (rapid increases)
    int peakCount = 0;
    double threshold = calculateGSRStd(derivative) * 1.5; // Adaptive threshold
    int minDistance = (samplingRate * 2.0).round(); // Minimum 2 seconds between peaks
    int lastPeak = -minDistance;

    for (int i = 1; i < derivative.length - 1; i++) {
      if (derivative[i] > derivative[i - 1] &&
          derivative[i] > derivative[i + 1] &&
          derivative[i] > threshold &&
          i - lastPeak > minDistance) {
        peakCount++;
        lastPeak = i;
      }
    }

    return peakCount;
  }

  // Find peaks in PPG signal using adaptive threshold and smoothing
  static List<int> findPeaks(List<double> signal, {required double samplingRate}) {
    List<int> peaks = [];
    int minDistance = (samplingRate * 0.3).round(); // Minimum 300ms between peaks (adjustable)

    // Simple moving average to smooth signal
    List<double> smoothed = [];
    int windowSize = 5; // Smoothing window
    for (int i = 0; i < signal.length; i++) {
      int start = (i - windowSize ~/ 2).clamp(0, signal.length - 1);
      int end = (i + windowSize ~/ 2 + 1).clamp(0, signal.length);
      double avg = signal.sublist(start, end).reduce((a, b) => a + b) / (end - start);
      smoothed.add(avg);
    }

    // Calculate adaptive threshold
    double mean = smoothed.reduce((a, b) => a + b) / smoothed.length;
    double maxVal = smoothed.reduce((a, b) => a > b ? a : b);
    double threshold = mean + (maxVal - mean) * 0.3;

    for (int i = 1; i < smoothed.length - 1; i++) {
      // Check if current point is a local maximum above threshold
      if (smoothed[i] > smoothed[i - 1] &&
          smoothed[i] > smoothed[i + 1] &&
          smoothed[i] > threshold) {
        // Ensure minimum distance from last peak
        if (peaks.isEmpty || i - peaks.last > minDistance) {
          peaks.add(i);
        }
      }
    }

    return peaks;
  }

  static double calculateHeartRate(List<int> peaks, int totalSamples, double samplingRate) {
    if (peaks.length < 2) return 0.0;

    // Calculate average interval between peaks in seconds
    double totalInterval = 0.0;
    for (int i = 1; i < peaks.length; i++) {
      totalInterval += (peaks[i] - peaks[i - 1]) / samplingRate;
    }

    double avgInterval = totalInterval / (peaks.length - 1);

    // Convert to beats per minute, clamp to reasonable range (30-200 BPM)
    double heartRate = 60.0 / avgInterval;
    return heartRate.clamp(30.0, 200.0);
  }

  static double calculateRMSSD(List<int> peaks, double samplingRate) {
    if (peaks.length < 3) return 0.0;

    List<double> intervals = [];

    // Convert peak indices to time intervals (in milliseconds)
    for (int i = 1; i < peaks.length; i++) {
      double interval = (peaks[i] - peaks[i - 1]) / samplingRate * 1000;
      intervals.add(interval);
    }

    // Calculate successive differences
    double sumSquaredDiffs = 0.0;
    for (int i = 1; i < intervals.length; i++) {
      double diff = intervals[i] - intervals[i - 1];
      sumSquaredDiffs += diff * diff;
    }

    // Return RMSSD, clamp to prevent outliers
    double rmssd = math.sqrt(sumSquaredDiffs / (intervals.length - 1));
    return rmssd.clamp(0.0, 1000.0); // Reasonable range for RMSSD
  }


  static double calculateSignalQuality(List<double> signal) {
    if (signal.isEmpty) return 0.0;

    // Calculate SNR with smoothing
    double mean = signal.reduce((a, b) => a + b) / signal.length;
    double variance = signal.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / (signal.length - 1);
    double std = math.sqrt(variance);

    // Return signal-to-noise ratio (higher is better), clamped to prevent extreme values
    return std > 0 ? (mean.abs() / std).clamp(0.0, 100.0) : 0.0;
  }

  static double calculatePulseAmplitude(List<double> signal, List<int> peaks, double samplingRate) {
    if (peaks.isEmpty || signal.isEmpty) return 0.0;

    double totalAmplitude = 0.0;
    int validPeaks = 0;
    int windowSize = (samplingRate * 0.4).round(); // Window ~400ms around peak

    for (int peak in peaks) {
      if (peak > windowSize && peak < signal.length - windowSize) {
        // Find local minimum in window around peak
        double minVal = signal.sublist(peak - windowSize, peak + windowSize).reduce((a, b) => a < b ? a : b);
        double amplitude = signal[peak] - minVal;
        if (amplitude > 0) { // Ensure positive amplitude
          totalAmplitude += amplitude;
          validPeaks++;
        }
      }
    }

    return validPeaks > 0 ? totalAmplitude / validPeaks : 0.0;
  }
}