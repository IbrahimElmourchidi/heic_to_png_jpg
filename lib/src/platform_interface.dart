import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

enum ImageFormat {
  jpg,
  png,
}

abstract class HeicToImagePlatform extends PlatformInterface {
  HeicToImagePlatform() : super(token: _token);

  static final Object _token = Object();
  static HeicToImagePlatform _instance = HeicToImageImplementation();

  static HeicToImagePlatform get instance => _instance;

  static set instance(HeicToImagePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
  }) {
    throw UnimplementedError('convertToImage has not been implemented.');
  }
}

class HeicToImageImplementation extends HeicToImagePlatform {
  @override
  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
  }) async {
    throw UnimplementedError('No implementation found for this platform');
  }
}
