import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/emotion_detector.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isDetecting = false;

  final EmotionDetector _emotionDetector = EmotionDetector();
  Map<String, double> _emotionResults = {};
  String _predictedEmotion = '';
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    //_initializeCamera();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _emotionDetector.loadModel();
    if (mounted) {
      setState(() {});
    }
  }

  // Future<void> _initializeCamera() async {
  //
  //   try {
  //     _cameras = await availableCameras();
  //     if (_cameras.isNotEmpty) {
  //       // Use front camera if available
  //       CameraDescription selectedCamera = _cameras.firstWhere(
  //             (camera) => camera.lensDirection == CameraLensDirection.front,
  //         orElse: () => _cameras.first,
  //       );
  //
  //       _cameraController = CameraController(
  //         selectedCamera,
  //         ResolutionPreset.medium,
  //         enableAudio: false,
  //       );
  //
  //       await _cameraController!.initialize();
  //
  //       if (mounted) {
  //         setState(() {
  //           _isCameraInitialized = true;
  //         });
  //         _startContinuousDetection();
  //       }
  //     }
  //   } catch (e) {
  //     print('Error initializing camera: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to initialize camera: $e')),
  //     );
  //   }
  // }

  // void _startContinuousDetection() {
  //   _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
  //     if (_emotionDetector.isModelLoaded && !_isDetecting) {
  //       _detectEmotionFromCamera();
  //     }
  //   });
  // }

  // Future<void> _detectEmotionFromCamera() async {
  //   if (_cameraController == null || !_cameraController!.value.isInitialized || _isDetecting) {
  //     return;
  //   }
  //
  //   setState(() {
  //     _isDetecting = true;
  //   });
  //
  //   try {
  //     final XFile imageFile = await _cameraController!.takePicture();
  //     final Uint8List imageBytes = await imageFile.readAsBytes();
  //
  //     final results = await _emotionDetector.detectEmotion(imageBytes);
  //     final predicted = _emotionDetector.getPredictedEmotion(results);
  //
  //     if (mounted) {
  //       setState(() {
  //         _emotionResults = results;
  //         _predictedEmotion = predicted;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error detecting emotion: $e');
  //   } finally {
  //     setState(() {
  //       _isDetecting = false;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _emotionDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Emotion Detection'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing Camera...'),
                  ],
                ),
              ),
            ),
          ),

          // Results Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Model Status
                  Row(
                    children: [
                      Icon(
                        _emotionDetector.isModelLoaded
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _emotionDetector.isModelLoaded
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _emotionDetector.isModelLoaded
                            ? 'Model Loaded'
                            : 'Loading Model...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_isDetecting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Predicted Emotion
                  if (_predictedEmotion.isNotEmpty) ...[
                    Text(
                      'Detected Emotion:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        _predictedEmotion.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Confidence Scores
                  if (_emotionResults.isNotEmpty) ...[
                    Text(
                      'Confidence Scores:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _emotionResults.length,
                        itemBuilder: (context, index) {
                          final emotion = _emotionResults.keys.elementAt(index);
                          final confidence = _emotionResults[emotion]!;
                          final percentage = (confidence * 100);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    emotion,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: confidence,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.deepPurple.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}