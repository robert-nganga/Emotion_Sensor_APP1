import 'dart:async';

import 'package:app/data/data_source/sensor_local_data_source.dart';
import 'package:app/main.dart';
import 'package:app/models/sensor_data.dart';
import 'package:app/widgets/charts/accel_chart.dart';
import 'package:app/widgets/charts/grs_chart.dart';
import 'package:app/widgets/charts/ppg_chart.dart';
import 'package:app/widgets/emotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/emotion_interpreter.dart';
import '../services/feature_extractor.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.cameraEmotion});
  final String? cameraEmotion;

  @override
  State<ScanPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ScanPage> {
  List<SensorData> _sensorDataList = [];
  double previousTimeStamp = 0.0;
  int maxDataPoint = 100;
  static const EventChannel event_channel = EventChannel(
    'com.example.emotion_sensor/shimmer/events',
  );
  static const MethodChannel _channel = MethodChannel(
    'com.example.emotion_sensor/shimmer',
  );

  StreamSubscription? _streamSubscription;
  final dataSource = SensorLocalDataSource(isar: isar);
  final emotionInterpreter = EmotionInterpreter();
  double? sampleRate = null;
  String? _predictedEmotion = null;
  bool _isStreaming = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    startListening();
    emotionInterpreter.loadModelAndScalers().then(
          (d) => _showSnackBar('Model loaded successfully', Colors.green),
    );
  }

  void startListening() async {
    await _startStreaming();
    listenSensorData();
  }

  @override
  void dispose() {
    super.dispose();
    _stopStreaming();
    _streamSubscription?.cancel();
  }

  Future<void> _stopStreaming() async {
    await _channel.invokeMethod('stopStreaming');
    setState(() {
      _isStreaming = false;
    });
  }

  Future<void> _startStreaming() async {
    await _channel.invokeMethod('startStreaming');
    setState(() {
      _isStreaming = true;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getShimmerEmotion() {
    final features = FeatureExtractor.extractFeatures(
      _sensorDataList,
      samplingRate: sampleRate!,
    );
    debugPrint('Extracted features $features');
    final output = emotionInterpreter.predict(features.values.toList());
    final emotion = emotionInterpreter.getEmotionFromValAndArousal(
      output.first,
      output.last,
    );
    return emotion;
  }

  void listenSensorData() {
    _streamSubscription = event_channel.receiveBroadcastStream().listen((
        event,
        ) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        if (data['type'] == 'sensorData') {
          debugPrint('sensor data: $data');
          sampleRate = 128.0;
          final currentTimeStamp = data['timeStamp'] as double;
          final sensorData = SensorData(
            timeStamp: data['timeStamp'] as double?,
            accelX: data['accel'] as double?,
            grs: data['gsrConductance'] as double?,
            ppg: data['ppgHeartRate'] as double?,
            emg: data['emgMuscleActivity'] as double?,
          );
          setState(() {
            _sensorDataList.add(sensorData);
          });
          previousTimeStamp = sensorData.timeStamp!;
        }
      }
    });
  }

  Widget _buildStatusCard() {
    double elapseTime = 0.0;
    if (_sensorDataList.length >= 2) {
      elapseTime =
          _sensorDataList.last.timeStamp! - _sensorDataList.first.timeStamp!;
      elapseTime = elapseTime / 1000.0;
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            icon: _isStreaming ? Icons.fiber_manual_record : Icons.stop_circle,
            label: 'Status',
            value: _isStreaming ? 'Recording' : 'Stopped',
            color: _isStreaming ? Colors.red : Colors.grey,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildStatusItem(
            icon: Icons.timeline,
            label: 'Samples',
            value: '${_sensorDataList.length}',
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildStatusItem(
            icon: Icons.timer,
            label: 'Duration',
            value: '${elapseTime.toStringAsFixed(1)}s',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double elapseTime = 10.0;
    if (_sensorDataList.length >= 2) {
      elapseTime =
          _sensorDataList.last.timeStamp! - _sensorDataList.first.timeStamp!;
      elapseTime = elapseTime / 1000.0;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Emotion Scan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isStreaming)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),

          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: 200,
                  child: AccelerometerChart(
                    sensorDataList: _sensorDataList,
                    windowSize: elapseTime,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: PpgChart(
                    sensorDataList: _sensorDataList,
                    windowSize: elapseTime,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: GrsChart(
                    sensorDataList: _sensorDataList,
                    windowSize: elapseTime,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_predictedEmotion != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emotion Detected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _predictedEmotion!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildActionButton(
                    label: _isStreaming ? "Stop & Analyze" : "Analyze Data",
                    onPressed: _sensorDataList.isEmpty || _isProcessing
                        ? null
                        : () async {
                      setState(() {
                        _isProcessing = true;
                      });

                      if (_isStreaming) {
                        await _stopStreaming();
                      }

                      try {
                        final emotion = _getShimmerEmotion();
                        setState(() {
                          _predictedEmotion = emotion;
                          _isProcessing = false;
                        });
                        await dataSource.saveScanSession(_sensorDataList, emotion);
                        _showSnackBar('Analysis complete!', Colors.green);
                      } catch (e) {
                        setState(() {
                          _isProcessing = false;
                        });
                        _showSnackBar('Analysis failed', Colors.red);
                      }
                    },
                    icon: _isStreaming ? Icons.stop : Icons.analytics,
                    color: _isStreaming ? Colors.red : Colors.blue,
                    isLoading: _isProcessing,
                  ),

                  const SizedBox(height: 12),

                  _buildActionButton(
                    label: "View Emotion Details",
                    onPressed: _predictedEmotion == null && !_isProcessing
                        ? null
                        : () async {
                      if (_predictedEmotion == null && !_isProcessing) {
                        final emotion = _getShimmerEmotion();
                        setState(() {
                          _predictedEmotion = emotion;
                        });
                      }

                      showDialog(
                        context: context,
                        builder: (context) {
                          return EmotionDialog(
                            cameraEmotion: widget.cameraEmotion,
                            sensorEmotion: _predictedEmotion!,
                            onClosed: () {
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                    icon: Icons.emoji_emotions,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}