import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionInterpreter {
  Interpreter? interpreter;
  Map<String, dynamic>? scalerParameters;
  final int totalFeatures;

  EmotionInterpreter({this.totalFeatures = 8});
  
  Future<void> loadModelAndScalers() async{

    interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');
    final scalerJson =  await rootBundle.loadString('assets/scaler_params.json');
    scalerParameters = json.decode(scalerJson);

  }

  List<double> predict (List<double> features){
    List<double> output = [];
    if(interpreter == null && scalerParameters == null){
      return output;
    }
    final featureMean = List<double>.from(scalerParameters!['feature_scaler']['mean']);
    final featureScale= List<double>.from(scalerParameters!['feature_scaler']['scale']);

    List<double> scaledInput = List<double>.filled(totalFeatures, 0); 
    for(int i = 0; i<totalFeatures; i++){
      scaledInput[i] = (features[i]- featureMean[i])/featureScale[i];
    }

    final input = [scaledInput];
    final prediction = List.filled(2, 0.0).reshape([1,2]);
    interpreter!.run(input, prediction);

    final labelMean = List<double>.from(scalerParameters!['label_scaler']['mean']);
    final labelScale= List<double>.from(scalerParameters!['label_scaler']['scale']);
    
    List<double> finalOutput = List<double>.filled(2,0);
    for(int i = 0; i<2; i++){
      finalOutput[i] = (prediction[0][i]*labelScale[i])*labelMean[i];
    }

    return finalOutput;
  }

  void dispose(){
    interpreter?.close();
  }


  String getEmotionFromValAndArousal(double valence, double arousal){

    double midPoint = 4.5;
    if( valence >= midPoint && arousal >= midPoint){
      return 'Happy';
    } else if(valence < midPoint && arousal >= midPoint){
      return 'Angry';
    } else if(valence < midPoint && arousal < midPoint){
      return 'Sad';
    } else if(valence >= midPoint && arousal < midPoint){
      return 'Relaxed';
    }
    return 'Neutral';
  }
 
}