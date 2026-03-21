import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:heif_converter/heif_converter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'exceptions.dart';
import 'platform_interface.dart';

// Factory function to create the platform implementation
HeicToImagePlatform getPlatformImplementation() {
  return HeicToPngJpgMobile();
}

class HeicToPngJpgMobile extends HeicToImagePlatform {
  @override
  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,

    /// It's not used in mobile platform.
    String? libheifJsUrl,
  }) async {
    // Validate quality
    if (quality < 0 || quality > 100) {
      throw InvalidHeicDataException(
          'quality must be between 0 and 100, got $quality');
    }

    if (Platform.isIOS || Platform.isAndroid) {
      final tempDir = await getTemporaryDirectory();
      final id = DateTime.now().microsecondsSinceEpoch;
      // heif_converter doesn't support WebP — use jpg as intermediate for WebP output
      final nativeFormat = format == ImageFormat.webp ? 'jpg' : format.name;
      final heicPath = '${tempDir.path}/heic_$id.heic';
      final outputPath = '${tempDir.path}/heic_$id.$nativeFormat';
      final heicFile = File(heicPath);

      try {
        // Write HEIC data to temporary file
        await heicFile.writeAsBytes(heicData);
        final resultPath = await HeifConverter.convert(
          heicPath,
          output: outputPath,
          format: nativeFormat,
        );

        if (resultPath == null) {
          throw const ConversionFailedException('Conversion failed: No output file generated');
        }

        final outputFile = File(resultPath);
        Uint8List outputData = await outputFile.readAsBytes();

        // Clean up temporary files
        await _deleteIfExists(heicFile);
        await _deleteIfExists(outputFile);

        // Apply quality, resize, or WebP re-encode if needed
        final needsProcessing = maxWidth != null ||
            maxHeight != null ||
            format == ImageFormat.webp ||
            (format == ImageFormat.jpg && quality != 100);

        if (needsProcessing) {
          outputData = await _processImage(
            outputData,
            format: format,
            quality: quality,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          );
        }

        return outputData;
      } catch (e) {
        await _deleteIfExists(heicFile);
        // Fallback to Dart implementation if heif_converter fails
        if (e is HeicConversionException) rethrow;
        return _convertUsingDart(heicData, format, quality, maxWidth, maxHeight);
      }
    } else {
      // Fallback to Dart implementation for desktop/other platforms
      return _convertUsingDart(heicData, format, quality, maxWidth, maxHeight);
    }
  }

  Future<Uint8List> _processImage(
    Uint8List data, {
    required ImageFormat format,
    required int quality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final image = img.decodeImage(data);
    if (image == null) {
      throw const ConversionFailedException('Failed to decode converted image for processing');
    }

    img.Image processedImage = _resizeImage(image, maxWidth, maxHeight);

    return _encodeImage(processedImage, format: format, quality: quality);
  }

  Future<Uint8List> _convertUsingDart(
    Uint8List heicData,
    ImageFormat format,
    int quality,
    int? maxWidth,
    int? maxHeight,
  ) async {
    try {
      final image = img.decodeImage(heicData);
      if (image == null) {
        throw const ConversionFailedException('Failed to decode HEIC image');
      }

      final outputImage = _resizeImage(image, maxWidth, maxHeight);
      return _encodeImage(outputImage, format: format, quality: quality);
    } on HeicConversionException {
      rethrow;
    } catch (e) {
      throw ConversionFailedException(
          'Failed to convert HEIC to ${format.name.toUpperCase()}', cause: e);
    }
  }

  img.Image _resizeImage(img.Image image, int? maxWidth, int? maxHeight) {
    if (maxWidth == null && maxHeight == null) return image;

    int targetWidth = image.width;
    int targetHeight = image.height;

    if (maxWidth != null && maxHeight != null) {
      // Contain mode: fit within bounding box preserving aspect ratio
      final scaleW = maxWidth / image.width;
      final scaleH = maxHeight / image.height;
      final scale = scaleW < scaleH ? scaleW : scaleH;
      if (scale >= 1.0) return image; // no upscale
      targetWidth = (image.width * scale).round();
      targetHeight = (image.height * scale).round();
    } else if (maxWidth != null) {
      if (maxWidth >= image.width) return image;
      targetWidth = maxWidth;
      targetHeight = (image.height * maxWidth / image.width).round();
    } else if (maxHeight != null) {
      if (maxHeight >= image.height) return image;
      targetHeight = maxHeight;
      targetWidth = (image.width * maxHeight / image.height).round();
    }

    return img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );
  }

  Uint8List _encodeImage(img.Image image,
      {required ImageFormat format, required int quality}) {
    switch (format) {
      case ImageFormat.jpg:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      case ImageFormat.png:
        return Uint8List.fromList(img.encodePng(image));
      case ImageFormat.webp:
        // The image package does not include a WebP encoder on mobile.
        // Fall back to PNG (lossless, supports transparency) as the
        // closest equivalent. Web platform uses native canvas WebP.
        return Uint8List.fromList(img.encodePng(image));
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
