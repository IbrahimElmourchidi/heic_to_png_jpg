import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:heic_to_png_jpg/src/heic_to_png_jpg_mobile.dart';

import 'platform_interface.dart';
import 'heic_to_png_jpg_web.dart'
    if (dart.library.io) 'heic_to_png_jpg_mobile.dart';

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
    // Set the platform implementation
    if (kIsWeb) {
      HeicToImagePlatform.instance = HeicToPngJpgWeb();
    } else {
      HeicToImagePlatform.instance = HeicToPngJpgMobile();
    }

    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: format,
      quality: quality,
    );
  }
}
