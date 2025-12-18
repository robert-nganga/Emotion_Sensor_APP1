import 'dart:async';
import 'dart:math';
import 'package:app/models/sensor_chart_data.dart';
import 'package:app/models/sensor_data.dart';
import 'package:app/pages/camera_page.dart';
import 'package:app/pages/scan_history_page.dart';
import 'package:app/pages/scan_page.dart';
import 'package:app/services/shimmer_service.dart';
import 'package:app/widgets/charts/accel_chart.dart';
import 'package:app/widgets/charts/emg_chart.dart';
import 'package:app/widgets/charts/grs_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isConnected = false;
  String connectionState = "Disconnected";
  double timeStamp = 0.0;
  double accelX = 0.0;
  bool isScanPageVisible = false;
  List<SensorData> _sensorDataList = [];
  double previousTimeStamp = 0.0;
  int maxDataPoint = 100;
  bool _isStreaming = false;

  static const EventChannel event_channel = EventChannel(
    'com.example.emotion_sensor/shimmer/events',
  );

  static const MethodChannel _channel = MethodChannel(
    'com.example.emotion_sensor/shimmer',
  );

  Future<void> _connectToShimmer() async {
    await ShimmerService.connect();
  }

  Future<void> _startStreaming() async {
    await _channel.invokeMethod('startStreaming');
    setState(() {
      _isStreaming = true;
    });
  }

  Future<void> _stopStreaming() async {
    await _channel.invokeMethod('stopStreaming');
    setState(() {
      _isStreaming = false;
    });
  }

  Future<void> _disconnectShimmer() async {
    await _channel.invokeMethod('disconnect');
  }

  @override
  void initState() {
    super.initState();
    listenConnectionStatus();
  }

  void listenConnectionStatus() {
    event_channel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        if (data['type'] == 'connectionData') {
          setState(() {
            connectionState = data['State'] ?? 'Unknown';
            _isConnected = connectionState.toLowerCase().contains('connected');
          });
        } else if (data['type'] == 'sensorData') {
          final currentTimeStamp = data['timeStamp'] as double;
          if (currentTimeStamp > previousTimeStamp + 100.0) {
            final sensorData = SensorData(
              timeStamp: data['timeStamp'] as double?,
              accelX: data['accel'] as double?,
              grs: data['gsrConductance'] as double?,
              ppg: data['ppgHeartRate'] as double?,
              emg: data['emgMuscleActivity'] as double?,
            );
            setState(() {
              timeStamp = data['timeStamp'] as double;
              accelX = data['accel'] as double;
              _sensorDataList.add(sensorData);
              if (_sensorDataList.length > maxDataPoint) {
                _sensorDataList.removeAt(0);
              }
            });
            previousTimeStamp = sensorData.timeStamp!;
          }
        }
      }
    });
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              size: 60,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            connectionState,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _isConnected ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
          if (_isConnected && _sensorDataList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_sensorDataList.length} data points',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          elevation: isOutlined ? 0 : 2,
          side: isOutlined ? BorderSide(color: color, width: 2) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Shimmer3 Sensor",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConnectionStatus(),
                const SizedBox(height: 24),

                // Connection button
                _buildActionButton(
                  label: _isConnected ? "Disconnect" : "Connect to Sensor",
                  onPressed: () async {
                    if (!_isConnected) {
                      await _connectToShimmer();
                    } else {
                      await _disconnectShimmer();
                    }
                  },
                  icon: _isConnected ? Icons.bluetooth_disabled : Icons.bluetooth,
                  color: _isConnected ? Colors.red : Colors.blue,
                  isOutlined: !_isConnected,
                ),

                const SizedBox(height: 16),

                // Scan button
                _buildActionButton(
                  label: "Start Scan",
                  onPressed: _isConnected
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanPage(),
                      ),
                    );
                  }
                      : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please connect to sensor first'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: Icons.monitor_heart,
                  color: Colors.green,
                ),

                const SizedBox(height: 16),

                // Camera scan button
                _buildActionButton(
                  label: "Camera Emotion Scan",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraPage(),
                      ),
                    );
                  },
                  icon: Icons.camera_alt,
                  color: Colors.purple,
                ),

                const SizedBox(height: 24),

                // Streaming controls
                Text(
                  'Streaming Controls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Start',
                        onPressed: _isConnected && !_isStreaming
                            ? _startStreaming
                            : () {},
                        icon: Icons.play_arrow,
                        color: Colors.green,
                        isOutlined: !_isConnected || _isStreaming,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Stop',
                        onPressed: _isStreaming ? _stopStreaming : () {},
                        icon: Icons.stop,
                        color: Colors.red,
                        isOutlined: !_isStreaming,
                      ),
                    ),
                  ],
                ),

                // Debug info (optional - can be removed)
                if (_isConnected && _sensorDataList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Live Data',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Timestamp:',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              timeStamp.toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Accel X:',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              accelX.toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Overlay scan view
          if (isScanPageVisible)
            Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  Expanded(
                    child: AccelerometerChart(sensorDataList: _sensorDataList),
                  ),
                  Expanded(
                    child: EmgChart(sensorDataList: _sensorDataList),
                  ),
                  Expanded(
                    child: GrsChart(sensorDataList: _sensorDataList),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildActionButton(
                      label: "Stop Streaming",
                      onPressed: () {
                        _stopStreaming();
                        setState(() {
                          isScanPageVisible = false;
                        });
                      },
                      icon: Icons.stop,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}