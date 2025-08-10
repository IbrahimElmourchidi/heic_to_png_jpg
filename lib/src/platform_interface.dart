import 'dart:typed_data';

import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class HeicToImagePlatform extends PlatformInterface {
  HeicToImagePlatform() : super(token: _token);

  static final Object _token = Object();
  static HeicToImagePlatform? _instance;

  static HeicToImagePlatform get instance {
    return _instance ??= throw Exception('HeicToImagePlatform instance not set');
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
    int quality = 80,
    int? maxWidth,

    /// To override the default libheif js cdn url.
    String? libheifJsUrl,
  });
}
