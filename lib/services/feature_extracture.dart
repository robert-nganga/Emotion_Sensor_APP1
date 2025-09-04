import 'dart:ffi';
import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:app/models/sensor_data.dart';
import 'package:flutter/cupertino.dart';

class FeatureExtracture {
  static Map<String, double> extractFeatures(List<SensorData> dataWindow) {
    Map<String, double> features = {}; //empty map
    List<double> accelList =
        dataWindow
            .where((d) => d.accelX != null && d.accelX != -1.0)
            .map((d) => d.accelX!)
            .toList();
    debugPrint('Accel List $accelList');
    List<double> grsList =
        dataWindow
            .where((d) => d.grs != null && d.grs != -1.0)
            .map((d) => d.grs!)
            .toList();
    debugPrint('GRS List $grsList');

    List<double> ppgList =
        dataWindow
            .where((d) => d.ppg != null && d.ppg != -1.0)
            .map((d) => d.ppg!)
            .toList();
    debugPrint('PPG List $ppgList');

    if (accelList.isEmpty) {
      features['Accel_mean'] = _mean(accelList);
      features['Accel_std'] = _std(accelList);
      features['Accel_variance'] = _variance(accelList);
      features['Accel_range'] = _range(accelList);
    }

    if (grsList.isEmpty) {
      features['Grs_mean'] = _mean(accelList);
      features['Grs_std'] = _std(accelList);
      features['Grs_slope'] = _slope(accelList);
      features['Grs_peak'] = _peak(accelList);
    }

    if (ppgList.isEmpty) {
      // find out how to calculate the heart rate from ppg
      features['Ppg_mean'] = _mean(accelList);
      features['Ppg_std'] = _std(accelList);
      features['Ppg_slope'] = _slope(accelList);
      features['Ppg_peak'] = _peak(accelList);
    }

    return features;
  }

  //----------------------------------------------------------------

  static double _mean(List<double> values) {
    return values.reduce((e, b) => e + b) /
        values.length; //calculate the avarage of the values
  }

  static double _std(List<double> values) {
    double variance = _variance(values);
    return sqrt(variance);
  }

  static double _variance(List<double> values) {
    double mean = _mean(values);
    double variance =
        values.map((e) => pow(e - mean, 2)).reduce((e, b) => e + b) /
        values.length;
    return variance;
  }

  static double _range(List<double> values) {
    return values.reduce(max) - values.reduce(min);
  }

  //----------------------------------------------------------------

  static double _slope(List<double> values) {
    int total = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0; //X2 means X^2
    for (int i = 0; i < total; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    return (total * sumXY - sumX * sumY) / (total * sumX2 - sumX * sumX);
  }

  static double _peak(List<double> values) {
    double peaks = 0.0;
    double threshold = _std(values) * 0.5;
    for (int i = 0; i < values.length; i++) {
      if (values[i] > values[i - 1] &&
          values[i] > values[i + 1] &&
          values[i] > threshold) {
        peaks++;
      }
    }
    return peaks;
  }
}
