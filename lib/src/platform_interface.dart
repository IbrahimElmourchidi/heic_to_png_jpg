import 'dart:typed_data';

import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:heic_to_png_jpg/src/heic_image_info.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class HeicToImagePlatform extends PlatformInterface {
  HeicToImagePlatform() : super(token: _token);

  static final Object _token = Object();
  static HeicToImagePlatform? _instance;

  static HeicToImagePlatform get instance {
    return _instance ??=
        throw Exception('HeicToImagePlatform instance not set');
  }

  static set instance(HeicToImagePlatform? instance) {
    if (instance != null) {
      PlatformInterface.verifyToken(instance, _token);
    }
    _instance = instance;
  }

  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,

    /// To override the default libheif js cdn url.
    String? libheifJsUrl,
  });

  /// Returns basic metadata about a HEIC image.
  Future<HeicImageInfo> getImageInfo(Uint8List heicData);

  /// Converts a HEIC file on disk and returns the output file path.
  ///
  /// Throws [PlatformNotSupportedException] on platforms without file system access.
  Future<String> convertFile({
    required String inputPath,
    String? outputPath,
    ImageFormat format = ImageFormat.jpg,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
  });
}
