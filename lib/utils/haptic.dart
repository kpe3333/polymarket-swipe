import 'package:flutter/services.dart';
import '../models/app_settings.dart';

class Haptic {
  static final _s = AppSettings();

  // On Android: selectionClick = lightest, mediumImpact = medium, vibrate = strongest
  static void light() {
    if (_s.hapticLevel >= 1) HapticFeedback.selectionClick();
  }

  static void medium() {
    if (_s.hapticLevel >= 2) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_s.hapticLevel >= 3) HapticFeedback.vibrate();
  }

  static void selection() {
    if (_s.hapticLevel >= 1) HapticFeedback.selectionClick();
  }

  // Direct fire for demo — bypasses level check
  static void demoForLevel(int level) {
    switch (level) {
      case 1: HapticFeedback.selectionClick(); break;
      case 2: HapticFeedback.mediumImpact(); break;
      case 3: HapticFeedback.vibrate(); break;
      default: break;
    }
  }
}
