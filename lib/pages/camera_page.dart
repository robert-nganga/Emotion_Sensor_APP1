// camera_page.dart
import 'dart:async';

import 'package:app/main.dart'; // Or your own main.dart path
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/emotion_detector.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;

  final EmotionDetector _emotionDetector = EmotionDetector();
  Map<String, double> _emotionResults = {};
  String _predictedEmotion = '';
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _emotionDetector.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    await _emotionDetector.loadModel();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeCamera() async {
    // Use the front camera for selfies
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0], // Fallback to the first camera
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false, // Disabling audio can improve performance
    );

    try {
      await _cameraController!.initialize();
      _startDetectionStream();
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      _showSnackBar('Camera error: ${e.code}', isError: true);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e', isError: true);
    }
  }

  void _startDetectionStream() {
    if (_cameraController == null) return;

    _cameraController!.startImageStream((CameraImage cameraImage) async {
      // If a frame is already being processed, skip this one.
      if (_isDetecting) {
        return;
      }
      debugPrint("Processing frame for emotion detection...");

      setState(() {
        _isDetecting = true;
      });

      // Convert the CameraImage to a format our model can use
      final image = await _convertYUV420toImage(cameraImage);

      // Perform emotion detection
      final results = await _emotionDetector.detectEmotion(image);
      final predicted = _emotionDetector.getPredictedEmotion(results);

      // Update the UI with the results
      if (mounted) {
        setState(() {
          _emotionResults = results;
          _predictedEmotion =
              predicted.isNotEmpty ? predicted : 'No face detected';
        });
      }

      // Allow the next frame to be processed.
      setState(() {
        _isDetecting = false;
      });
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  img.Image _convertYUV420toImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    // Create a new RGB image
    final img.Image rgbImage = img.Image(width: width, height: height);

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;

        // Calculate the index for the U and V planes
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // Get the Y, U, and V values
        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        // Convert YUV to RGB using standard formula
        int r = (yValue + 1.402 * (vValue - 128)).round();
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round();
        int b = (yValue + 1.772 * (uValue - 128)).round();

        // Clamp values to the 0-255 range and set the pixel
        rgbImage.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }

    return rgbImage;
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the camera is initializing
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Detector')),
      body: Column(
        children: [
          // The camera preview
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child:
                _isCameraInitialized
                    ? CameraPreview(_cameraController!)
                    : Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          // Display the prediction on top of the camera preview
          Text(
            _predictedEmotion,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Display detailed emotion probabilities
          Expanded(
            child: ListView(
              children:
                  _emotionResults.entries.map((entry) {
                    return ListTile(
                      title: Text(
                        '${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%',
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
