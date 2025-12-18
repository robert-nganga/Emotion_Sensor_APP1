import 'package:app/main.dart';
import 'package:app/pages/scan_page.dart';
import 'package:app/services/camera_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  bool _isCameraInitialize = false;
  bool _isDetecting = false;
  final CameraModel _cameraModel = CameraModel();
  Map<String, double> _emotionResults = {};
  String _predictedEmotion = "";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _cameraModel.dispose();
  }

  Future<void> _loadModel() async {
    await _cameraModel.loadModel();
    if (mounted) {
      setState(() {});
      _showSnackBar('Camera model loaded', Colors.green);
    }
  }

  Future<void> _initializeCamera() async {
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialize = true;
      });
      _startDetectionStream();
    } on CameraException catch (e) {
      _showSnackBar('Camera Error: ${e.description}', Colors.red);
    } catch (e) {
      _showSnackBar('Unexpected error: $e', Colors.red);
    }
  }

  void _startDetectionStream() {
    if (_cameraController == null) return;
    _cameraController!.startImageStream((CameraImage cameraImage) async {
      if (_isDetecting) {
        return;
      }
      setState(() {
        _isDetecting = true;
      });
      final image = _convertToRGB(cameraImage);
      final results = await _cameraModel.detectEmotion(image);
      final emotion = _cameraModel.getPredictedEmotion(results);
      if (mounted) {
        setState(() {
          _emotionResults = results;
          _predictedEmotion = emotion;
          _isDetecting = false;
        });
      }
    });
  }

  img.Image _convertToRGB(CameraImage cameraImage) {
    final img.Image rgbImage = img.Image(
      height: cameraImage.height,
      width: cameraImage.width,
    );
    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final yRowWidth = cameraImage.planes[0].bytesPerRow;
    final uvRowWidth = cameraImage.planes[1].bytesPerRow;
    final uvPixelWidth = cameraImage.planes[1].bytesPerPixel!;

    for (int y = 0; y < cameraImage.height; y++) {
      for (int x = 0; x < cameraImage.width; x++) {
        final int yIndex = y * yRowWidth + x;
        final int uvIndex = (y ~/ 2) * uvRowWidth + (x ~/ 2) * uvPixelWidth;
        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        int r = (yValue + 1.402 * (vValue - 128)).round();
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round();
        int b = (yValue + 1.772 * (uValue - 128)).round();

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return rgbImage;
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

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Colors.amber;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
      case 'anger':
        return Icons.sentiment_very_dissatisfied;
      case 'fear':
        return Icons.sentiment_dissatisfied;
      case 'surprise':
        return Icons.sentiment_satisfied;
      case 'disgust':
        return Icons.sentiment_neutral;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_satisfied_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final sortedEmotions = _emotionResults.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Camera Emotion Scan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isDetecting)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.purple.shade700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Analyzing',
                        style: TextStyle(
                          color: Colors.purple.shade700,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Camera Preview Section
            Container(
              height: height * 0.4,
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isCameraInitialize
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                    // Face detection overlay guide
                    Center(
                      child: Container(
                        width: 200,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(120),
                        ),
                      ),
                    ),
                  ],
                )
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Initializing camera...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Detected Emotion Card
            if (_predictedEmotion.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getEmotionColor(_predictedEmotion),
                      _getEmotionColor(_predictedEmotion).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getEmotionColor(_predictedEmotion).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getEmotionIcon(_predictedEmotion),
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detected Emotion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _predictedEmotion.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Emotion Probabilities Section
            if (_emotionResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Emotion Probabilities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...sortedEmotions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final emotion = entry.value.key;
                      final confidence = entry.value.value;
                      final isTopEmotion = index == 0;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < sortedEmotions.length - 1 ? 12.0 : 0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isTopEmotion
                                ? _getEmotionColor(emotion).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: isTopEmotion
                                ? Border.all(
                              color: _getEmotionColor(emotion),
                              width: 2,
                            )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getEmotionIcon(emotion),
                                color: _getEmotionColor(emotion),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emotion,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isTopEmotion
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                            BorderRadius.circular(3),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: confidence / 100,
                                          child: Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: _getEmotionColor(emotion),
                                              borderRadius:
                                              BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${confidence.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _getEmotionColor(emotion),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}