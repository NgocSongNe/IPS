import 'package:tflite_flutter/tflite_flutter.dart';
class WiFiPredictor {
  late Interpreter _interpreter;

  // Load the model
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    print("Model loaded successfully");
  }

  // Predict location from RSSI values
  Future<List<double>> predict(List<double> input) async {
    if (_interpreter == null) {
      throw Exception("Model is not loaded");
    }

    // Reshape input data if needed
    var inputData = [input]; // Reshaped as a 2D array: [[rssi1, rssi2, ...]]
    
    // Output data with a shape of [1, 2] (latitude, longitude)
    var outputData = List.filled(2, 0.0); // [lat, lng]
    
    // Run the model prediction
    _interpreter.run(inputData, outputData);
    
    print("Prediction result: $outputData");
    return outputData;
  }
}
