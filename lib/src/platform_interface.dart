import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

enum ImageFormat {
  jpg,
  png,
}

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
    int quality = 80,
    int? maxWidth,
  });
}
