import 'package:flutter/material.dart';

class CategoryStyle {
  final Color primary;
  final Color bg;
  final List<Color> gradient;

  const CategoryStyle({required this.primary, required this.bg, required this.gradient});
}

const _styles = <String, CategoryStyle>{
  'politics': CategoryStyle(
    primary: Color(0xFF5B8DEF),
    bg: Color(0xFF0D1B3E),
    gradient: [Color(0xFF1A2A5E), Color(0xFF0D1525)],
  ),
  'crypto': CategoryStyle(
    primary: Color(0xFFF7931A),
    bg: Color(0xFF2D1A00),
    gradient: [Color(0xFF2D1F00), Color(0xFF120D00)],
  ),
  'sports': CategoryStyle(
    primary: Color(0xFF00D09E),
    bg: Color(0xFF002D24),
    gradient: [Color(0xFF003D30), Color(0xFF001A14)],
  ),
  'science': CategoryStyle(
    primary: Color(0xFFB57BFF),
    bg: Color(0xFF1A0D3D),
    gradient: [Color(0xFF221050), Color(0xFF0D0820)],
  ),
  'finance': CategoryStyle(
    primary: Color(0xFFFFD700),
    bg: Color(0xFF2D2500),
    gradient: [Color(0xFF2D2800), Color(0xFF141200)],
  ),
  'entertainment': CategoryStyle(
    primary: Color(0xFFFF6B9D),
    bg: Color(0xFF3D0020),
    gradient: [Color(0xFF3D0025), Color(0xFF1A0010)],
  ),
  'world': CategoryStyle(
    primary: Color(0xFF4DC8FF),
    bg: Color(0xFF00203D),
    gradient: [Color(0xFF002D55), Color(0xFF001020)],
  ),
};

const _default = CategoryStyle(
  primary: Color(0xFF00D09E),
  bg: Color(0xFF1A1A2E),
  gradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
);

CategoryStyle categoryStyle(String? category) {
  if (category == null) return _default;
  final key = category.toLowerCase();
  for (final entry in _styles.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return _default;
}
