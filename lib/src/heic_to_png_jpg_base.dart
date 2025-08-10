import 'dart:async';
import 'dart:typed_data';

import 'package:heic_to_png_jpg/src/image_format.dart';

// Conditional import using js_interop for web per package:web guidance
import 'heic_to_png_jpg_mobile.dart' if (dart.library.js_interop) 'heic_to_png_jpg_web.dart'
    as implementation;
import 'platform_interface.dart';

class HeicConverter {
  static Future<Uint8List> convertToJPG({
    required Uint8List heicData,
    int quality = 90,
    int? maxWidth,

    /// To override the default libheif js cdn url.
    String? libheifJsUrl,
  }) async {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.jpg,
      quality: quality,
      maxWidth: maxWidth,
      libheifJsUrl: libheifJsUrl,
    );
  }

  static Future<Uint8List> convertToPNG({
    required Uint8List heicData,
    int? maxWidth,

    /// To override the default libheif js cdn url.
    String? libheifJsUrl,
  }) async {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.png,
      maxWidth: maxWidth,
      libheifJsUrl: libheifJsUrl,
    );
  }

  static Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
    int? maxWidth,

    /// To override the default libheif js cdn url.
    String? libheifJsUrl,
  }) async {
    // Use the properly imported implementation
    // Let the implementation decide which platform-specific code to run
    HeicToImagePlatform.instance = implementation.getPlatformImplementation();

    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: format,
      quality: quality,
      maxWidth: maxWidth,
      libheifJsUrl: libheifJsUrl,
    );
  }
}
