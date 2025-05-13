import 'dart:typed_data';
import 'dart:async';

import 'platform_interface.dart';

class HeicConverter {
  static Future<Uint8List> convertToJPG({
    required Uint8List heicData,
    int quality = 90,
  }) async {
    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: ImageFormat.jpg,
      quality: quality,
    );
  }

  static Future<Uint8List> convertToPNG({
    required Uint8List heicData,
  }) async {
    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: ImageFormat.png,
    );
  }

  static Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
  }) async {
    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: format,
      quality: quality,
    );
  }
}
