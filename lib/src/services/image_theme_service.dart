import 'package:flutter/material.dart';

class ImageThemeService {
  // Cache for ColorScheme objects
  final Map<String, ColorScheme> _colorSchemeCache = {};
  // Cache for the extracted dominant color
  final Map<String, Color?> _dominantColorCache = {};

  Future<Color?> getDominantColor(String imageUrl,
      {double imageScale = 1.0}) async {
    if (imageUrl.isEmpty) return null;

    if (_dominantColorCache.containsKey(imageUrl)) {
      return _dominantColorCache[imageUrl];
    }

    try {
      final ColorScheme colorScheme = await ColorScheme.fromImageProvider(
        provider: NetworkImage(imageUrl, scale: imageScale),
     
      );

      final Color dominantColor = colorScheme.primary;

      _colorSchemeCache[imageUrl] =
          colorScheme; 
      _dominantColorCache[imageUrl] = dominantColor;
      return dominantColor;
    } catch (e) {
      debugPrint("Error generating ColorScheme from image in service: $e");
      return null;
    }
  }

  void clearCache() {
    _colorSchemeCache.clear();
    _dominantColorCache.clear();
  }
}
