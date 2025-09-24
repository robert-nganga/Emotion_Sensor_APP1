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
  bool _isCameraInialize = false;
  bool _isDetecting = false;
  final CameraModel _cameraModel = CameraModel();
  Map<String, double> _emotionResults = {};
  String _predictedEmotion = "";

  @override
  void initState() {
    super.initState();
    _inializeCamera();
    _loadModel();
  }

  @override
  void dispose(){
    super.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _cameraModel.dispose();
  }

  Future<void> _loadModel() async{
    await _cameraModel.loadModel();
    if(mounted){
      setState(() {
      
      });
    }
  }

  Future<void> _inializeCamera() async{
    final frontCamera = cameras.firstWhere(
      (camera)=> camera.lensDirection == CameraLensDirection.front,
      orElse: ()=>cameras.first
    );
    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    try{
      await _cameraController!.initialize();
      setState(() {
        _isCameraInialize = true;
      },);
      _startDetectionStream();
    }on CameraException catch(e){
      _showSnackBar('Camera Error ${e.description}');
    } catch(e){
      _showSnackBar('Unexpected error happen $e');
    }
  } 

  void _startDetectionStream(){
    if(_cameraController == null) return;
    _cameraController!.startImageStream(
      (CameraImage cameraImage) async{
        if(_isDetecting){
          return;
        }
        setState(() {
          _isDetecting = true;
        },);
        final image = _convertToRBG(cameraImage);
        final results = await _cameraModel.detectEmotion(image);
        final emotion = _cameraModel.getPredictedEmotion(results);
        if(mounted){
          setState(() {
            _emotionResults = results;
            _predictedEmotion = emotion;
            _isDetecting = false;
          });
        }
      }
);
  }

  img.Image _convertToRBG(CameraImage cameraImage){
    final img.Image rgbImage = img.Image(height: cameraImage.height,width: cameraImage.width);
    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final yRowWidth = cameraImage.planes[0].bytesPerRow;
    final uvRowWidth = cameraImage.planes[1].bytesPerRow;
    final uvPixelWidth = cameraImage.planes[1].bytesPerPixel!;

    for(int y=0; y < cameraImage.height; y++){
      for(int x = 0; x < cameraImage.width; x++){
        final int yIndex = y * yRowWidth + x;
        final int uvIndex = (y~/2)*uvRowWidth + (x~/2)*uvPixelWidth;
        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        int r = (yValue + 1.402 *(vValue-128)).round();
        int g = (yValue - 0.344136 * (uValue - 128)- 0.714136 * (vValue - 128)).round();
        int b = (yValue + 1.772 * (uValue - 128)).round();

        rgbImage.setPixelRgb(x, y, r, g, b);

      }
    }

    return rgbImage;
  }


 void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Scanner'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: height * 0.5,
            width: double.infinity,
            child: _isCameraInialize ? CameraPreview(_cameraController!) : Center(child: CircularProgressIndicator(),),
          ),
          if(_predictedEmotion.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.green
              ),
              child: Text(
                _predictedEmotion.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          if(_emotionResults.isNotEmpty)
            Expanded(child: ListView.builder(
            itemCount: _emotionResults.length,
            itemBuilder:(context, index) {
              final emotion = _emotionResults.keys.elementAt(index);
              final confident = _emotionResults[emotion];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, //criar espaço
                children: [
                  Text(
                    emotion
                  ),
                  Text(
                    '${confident?.toStringAsFixed(1)}%'
                  )
                ],
              );
            },
            ),
            ),
          SizedBox(height: 10),

           SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      //_startStreaming();
                      /*setState(() { 
                        isScanPageVisible = true; 
                      });*/
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ScanPage(cameraEmotion: _predictedEmotion.isEmpty? null: _predictedEmotion);
                          },
                        ),
                      );
                    },

                    child: Text(
                      "Proceed so Shimmer Sensor Scan",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}