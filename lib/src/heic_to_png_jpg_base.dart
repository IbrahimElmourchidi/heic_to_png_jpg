import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// Conditional import using js_interop for web per package:web guidance
import 'heic_to_png_jpg_mobile.dart'
    if (dart.library.js_interop) 'heic_to_png_jpg_web.dart' as implementation;
import 'exceptions.dart';
import 'heic_image_info.dart';
import 'heic_conversion_task.dart';
import 'platform_interface.dart';

class HeicConverter {
  // Lazy singleton — platform instance is created once and reused.
  static HeicToImagePlatform? _platformInstance;
  static HeicToImagePlatform get _platform {
    return _platformInstance ??=
        implementation.getPlatformImplementation();
  }

  /// Returns `true` if [data] appears to be a valid HEIC/HEIF file.
  ///
  /// Checks the magic bytes only — does not decode the image.
  static bool isHeic(Uint8List data) {
    if (data.length < 12) return false;
    final ftyp = String.fromCharCodes(data.sublist(4, 8));
    if (ftyp != 'ftyp') return false;
    final brand = String.fromCharCodes(data.sublist(8, 12));
    return const {'heic', 'heix', 'hevc', 'mif1', 'msf1', 'hevx'}
        .contains(brand);
  }

  /// Returns basic metadata about a HEIC image.
  ///
  /// On mobile/desktop the `image` package decodes the image to read dimensions.
  static Future<HeicImageInfo> getImageInfo(Uint8List heicData) async {
    final result = await Isolate.run(() {
      final image = img.decodeImage(heicData);
      if (image == null) {
        throw const ConversionFailedException('Failed to decode HEIC image for info');
      }
      return (width: image.width, height: image.height);
    });
    return HeicImageInfo(width: result.width, height: result.height);
  }

  /// Converts [heicData] to JPG.
  static Future<Uint8List> convertToJPG({
    required Uint8List heicData,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
    String? libheifJsUrl,
  }) {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.jpg,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      libheifJsUrl: libheifJsUrl,
    );
  }

  /// Converts [heicData] to PNG.
  static Future<Uint8List> convertToPNG({
    required Uint8List heicData,
    int? maxWidth,
    int? maxHeight,
    String? libheifJsUrl,
  }) {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.png,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      libheifJsUrl: libheifJsUrl,
    );
  }

  /// Converts [heicData] to WebP.
  ///
  /// On web, the browser's native WebP encoder is used.
  /// On mobile, the output falls back to PNG because the `image` package
  /// does not include a WebP encoder.
  static Future<Uint8List> convertToWebP({
    required Uint8List heicData,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
    String? libheifJsUrl,
  }) {
    return convertToImage(
      heicData: heicData,
      format: ImageFormat.webp,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      libheifJsUrl: libheifJsUrl,
    );
  }

  /// Converts [heicData] to the specified [format].
  static Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
    String? libheifJsUrl,
  }) async {
    HeicToImagePlatform.instance = _platform;
    return HeicToImagePlatform.instance.convertToImage(
      heicData: heicData,
      format: format,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      libheifJsUrl: libheifJsUrl,
    );
  }

  /// Converts multiple HEIC files concurrently.
  ///
  /// [concurrency] limits the number of simultaneous conversions to prevent
  /// memory exhaustion (default: 3).
  static Future<List<Uint8List>> convertBatch({
    required List<HeicConversionTask> tasks,
    int concurrency = 3,
    String? libheifJsUrl,
  }) async {
    final results = List<Uint8List?>.filled(tasks.length, null);
    var index = 0;

    Future<void> runNext() async {
      while (index < tasks.length) {
        final i = index++;
        final task = tasks[i];
        results[i] = await convertToImage(
          heicData: task.heicData,
          format: task.format,
          quality: task.quality,
          maxWidth: task.maxWidth,
          maxHeight: task.maxHeight,
          libheifJsUrl: libheifJsUrl,
        );
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, tasks.length.clamp(1, concurrency)),
      (_) => runNext(),
    );
    await Future.wait(workers);

    return results.cast<Uint8List>();
  }

  /// Converts a HEIC file on disk and returns the output file path.
  ///
  /// If [outputPath] is not provided, a unique path in the system temp
  /// directory is used.
  ///
  /// Throws [UnsupportedError] on web (no file system access).
  static Future<String> convertFile({
    required String inputPath,
    String? outputPath,
    ImageFormat format = ImageFormat.jpg,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
  }) async {
    // dart:io is unavailable on web — this check is compile-time safe because
    // this method is only meaningful on non-web targets.
    final heicData = await File(inputPath).readAsBytes();

    final outputData = await convertToImage(
      heicData: heicData,
      format: format,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    final String resolvedOutputPath;
    if (outputPath != null) {
      resolvedOutputPath = outputPath;
    } else {
      final tempDir = await getTemporaryDirectory();
      final id = DateTime.now().microsecondsSinceEpoch;
      resolvedOutputPath = '${tempDir.path}/heic_$id.${format.name}';
    }

    await File(resolvedOutputPath).writeAsBytes(outputData);
    return resolvedOutputPath;
  }
}
