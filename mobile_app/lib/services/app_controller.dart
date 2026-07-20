import 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  static final AppController _instance = AppController._internal();

  factory AppController() {
    return _instance;
  }

  AppController._internal();

  double anxiety = 0.0;
  double gratitude = 0.0;
  double reactivity = 0.0;
  double humility = 0.0;

  void updateEmotion(String emotion) {
    if (emotion == "anxiety") anxiety += 0.1;
    if (emotion == "gratitude") gratitude += 0.1;
    if (emotion == "anger") reactivity += 0.1;
    if (emotion == "pride") humility -= 0.1;

    notifyListeners();
  }
}