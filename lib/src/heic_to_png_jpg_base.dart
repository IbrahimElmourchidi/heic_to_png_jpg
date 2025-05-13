import 'dart:async';
import 'dart:typed_data';

// Import implementations conditionally
// This is the proper way to do conditional imports
import 'heic_to_png_jpg_web.dart'
    if (dart.library.io) 'heic_to_png_jpg_mobile.dart' as implementation;
import 'platform_interface.dart';

class HeicConverter {
  static Future<Uint8List> convertToJPG({
    required Uint8List heicData,
    int quality = 90,
  }) async {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.jpg,
      quality: quality,
    );
  }

  static Future<Uint8List> convertToPNG({
    required Uint8List heicData,
  }) async {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.png,
    );
  }

  static Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
  }) async {
    // Use the properly imported implementation
    // Let the implementation decide which platform-specific code to run
    HeicToImagePlatform.instance = implementation.getPlatformImplementation();

    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: format,
      quality: quality,
    );
  }
}
