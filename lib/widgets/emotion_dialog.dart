
import 'package:flutter/material.dart';

class EmotionDialog extends StatelessWidget {
  const EmotionDialog({super.key, required this.sensorEmotion, this.cameraEmotion, required this.onClosed});
  final String sensorEmotion;
  final String? cameraEmotion;
  final Function() onClosed;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cameraEmotion == null? 'Sensor Emotion was $sensorEmotion': displayEmotionText(cameraEmotion!, sensorEmotion),
                style: TextStyle(color: Colors.black),
              ),

              SizedBox(height: 20),

              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onClosed,
                    child: Text(
                      "Close",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


String displayEmotionText(String cameraEmotion, String sensorEmotion){
  String output = '';
  if(cameraEmotion == sensorEmotion){
    output = 'The emotion detected by the camera and by the Shimmer Sensor was $cameraEmotion ';
  }else {
    output = 'The emotion detected by the camera was $cameraEmotion, but by the Shimmer Sensor was $sensorEmotion';
  }
 return output; 
}