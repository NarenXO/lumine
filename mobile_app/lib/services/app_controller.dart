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

  bool keyboardActive = false;

  String currentEmotion = 'calm';

  void updateEmotion(String emotion) {
    final e = emotion.toLowerCase().trim();

    if (e == 'anxiety' || e == 'anxious') {
      anxiety += 0.1;
      currentEmotion = 'anxious';
    } else if (e == 'gratitude' || e == 'grateful') {
      gratitude += 0.1;
      currentEmotion = 'grateful';
    } else if (e == 'anger' || e == 'angry') {
      reactivity += 0.1;
      currentEmotion = 'angry';
    } else if (e == 'sadness' || e == 'sad') {
      currentEmotion = 'sad';
    } else if (e == 'joy' || e == 'happy') {
      currentEmotion = 'happy';
    } else if (e == 'stress' || e == 'stressed') {
      anxiety += 0.05;
      currentEmotion = 'stressed';
    } else if (e == 'hopeful') {
      currentEmotion = 'hopeful';
    } else if (e == 'optimistic') {
      currentEmotion = 'optimistic';
    } else if (e == 'depressed') {
      currentEmotion = 'depressed';
    } else if (e == 'calm' || e == 'neutral') {
      currentEmotion = 'calm';
    } else {
      currentEmotion = e;
    }

    notifyListeners();
  }

  void setEmotion(String emotion) {
    currentEmotion = emotion.toLowerCase().trim();
    notifyListeners();
  }

  void setKeyboardActive(bool active) {
    if (keyboardActive == active) return;
    keyboardActive = active;
    notifyListeners();
  }
}