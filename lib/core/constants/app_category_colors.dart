import 'package:flutter/material.dart';

class ColorShadeFamily {
  final String name;
  final List<Color> shades;

  const ColorShadeFamily({
    required this.name,
    required this.shades,
  });
}

class AppCategoryColors {
  static const List<ColorShadeFamily> shadeFamilies = [
    ColorShadeFamily(
      name: 'Red',
      shades: [
        Color(0xFFFF8A80), Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFD50000),
        Color(0xFFEF5350), Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828),
        Color(0xFFB71C1C), Color(0xFF880E4F),
      ],
    ),
    ColorShadeFamily(
      name: 'Orange',
      shades: [
        Color(0xFFFFD180), Color(0xFFFFAB40), Color(0xFFFF9100), Color(0xFFFF6D00),
        Color(0xFFFFA726), Color(0xFFFB8C00), Color(0xFFF57C00), Color(0xFFEF6C00),
        Color(0xFFE65100), Color(0xFFD84315),
      ],
    ),
    ColorShadeFamily(
      name: 'Yellow',
      shades: [
        Color(0xFFFFFF8D), Color(0xFFFFE57F), Color(0xFFFFD740), Color(0xFFFFC400),
        Color(0xFFFFEE58), Color(0xFFFDD835), Color(0xFFFBC02D), Color(0xFFF9A825),
        Color(0xFFF57F17), Color(0xFFFFB300),
      ],
    ),
    ColorShadeFamily(
      name: 'Green',
      shades: [
        Color(0xFFB9F6CA), Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00C853),
        Color(0xFFA7FFEB), Color(0xFF64FFDA), Color(0xFF1DE9B6), Color(0xFF00BFA5),
        Color(0xFF66BB6A), Color(0xFF43A047), Color(0xFF2E7D32), Color(0xFF1B5E20),
        Color(0xFF26A69A), Color(0xFF00897B), Color(0xFF004D40),
      ],
    ),
    ColorShadeFamily(
      name: 'Blue',
      shades: [
        Color(0xFF80D8FF), Color(0xFF40C4FF), Color(0xFF00B0FF), Color(0xFF0091EA),
        Color(0xFF82B1FF), Color(0xFF448AFF), Color(0xFF2979FF), Color(0xFF2962FF),
        Color(0xFF42A5F5), Color(0xFF1E88E5), Color(0xFF1565C0), Color(0xFF0D47A1),
        Color(0xFF1E3A5F), Color(0xFF2A4D69), Color(0xFF0F2027),
      ],
    ),
    ColorShadeFamily(
      name: 'Purple',
      shades: [
        Color(0xFFEA80FC), Color(0xFFE040FB), Color(0xFFD500F9), Color(0xFFAA00FF),
        Color(0xFFB388FF), Color(0xFF7C4DFF), Color(0xFF651FFF), Color(0xFF6200EA),
        Color(0xFFAB47BC), Color(0xFF7B1FA2),
      ],
    ),
    ColorShadeFamily(
      name: 'Pink',
      shades: [
        Color(0xFFFF80AB), Color(0xFFFF4081), Color(0xFFF50057), Color(0xFFC51162),
        Color(0xFFEC407A), Color(0xFFE91E63), Color(0xFFD81B60), Color(0xFFC2185B),
        Color(0xFFAD1457), Color(0xFF880E4F),
      ],
    ),
    ColorShadeFamily(
      name: 'Brown',
      shades: [
        Color(0xFFD7CCC8), Color(0xFFBCAAA4), Color(0xFFA1887F), Color(0xFF8D6E63),
        Color(0xFF795548), Color(0xFF6D4C41), Color(0xFF5D4037), Color(0xFF4E342E),
        Color(0xFF3E2723), Color(0xFF8D7B68),
      ],
    ),
    ColorShadeFamily(
      name: 'Gray & Slate',
      shades: [
        Color(0xFFCFD8DC), Color(0xFFB0BEC5), Color(0xFF90A4AE), Color(0xFF78909C),
        Color(0xFF607D8B), Color(0xFF546E7A), Color(0xFF455A64), Color(0xFF37474F),
        Color(0xFF263238), Color(0xFF4A5568), Color(0xFF2D3748), Color(0xFF1A202C),
      ],
    ),
  ];

  static List<Color> get allColors {
    final list = <Color>[];
    for (final fam in shadeFamilies) {
      list.addAll(fam.shades);
    }
    return list;
  }
}
