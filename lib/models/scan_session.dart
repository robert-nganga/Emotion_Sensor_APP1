import 'package:app/models/sensor_data.dart';

class ScanSession {
  final int id;
  final DateTime startTime;
  final List<SensorData> sensorDataList;
  final String emotion;
  ScanSession({
    required this.startTime, required this.sensorDataList, required this.id, required this.emotion
  });
}