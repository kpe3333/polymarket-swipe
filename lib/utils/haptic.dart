import 'package:flutter/services.dart';
import '../models/app_settings.dart';

class Haptic {
  static final _s = AppSettings();

  static void light() {
    if (_s.hapticLevel >= 1) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_s.hapticLevel >= 2) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_s.hapticLevel >= 3) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (_s.hapticLevel >= 1) HapticFeedback.selectionClick();
  }
}
