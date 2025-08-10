import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:heif_converter/heif_converter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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
    int quality = 80,
    int? maxWidth,

    /// It's not used in mobile platform.
    String? libheifJsUrl,
  }) async {
    // Debug: Log input size

    if (Platform.isIOS || Platform.isAndroid) {
      try {
        final tempDir = await getTemporaryDirectory();
        final heicPath = '${tempDir.path}/temp.heic';
        final outputPath = '${tempDir.path}/temp.${format.name}';

        // Write HEIC data to temporary file
        final heicFile = File(heicPath);
        await heicFile.writeAsBytes(heicData);

        // Convert using heif_converter
        final resultPath = await HeifConverter.convert(
          heicPath,
          output: outputPath,
          format: format == ImageFormat.jpg ? 'jpg' : 'png',
        );

        if (resultPath == null) {
          throw Exception('Conversion failed: No output file generated');
        }

        // Read output data
        final outputFile = File(resultPath);
        Uint8List outputData = await outputFile.readAsBytes();

        // Clean up temporary files
        await heicFile.delete();
        await outputFile.delete();

        // Resize if maxWidth is specified
        if (maxWidth != null) {
          final image = img.decodeImage(outputData);
          if (image == null) {
            throw Exception('Failed to decode converted image for resizing');
          }
          if (maxWidth < image.width) {
            final targetHeight =
                (image.height * maxWidth / image.width).round();
            final resizedImage = img.copyResize(
              image,
              width: maxWidth,
              height: targetHeight,
              interpolation: img.Interpolation.average,
            );
            outputData = format == ImageFormat.jpg
                ? Uint8List.fromList(
                    img.encodeJpg(resizedImage, quality: quality))
                : Uint8List.fromList(img.encodePng(resizedImage));
          }
        }

        return outputData;
      } catch (e) {
        // Fallback to Dart implementation if heif_converter fails
        return _convertUsingDart(heicData, format, quality, maxWidth);
      }
    } else {
      // Fallback to Dart implementation for other platforms
      return _convertUsingDart(heicData, format, quality, maxWidth);
    }
  }

  Future<Uint8List> _convertUsingDart(
    Uint8List heicData,
    ImageFormat format,
    int quality,
    int? maxWidth,
  ) async {
    try {
      // Debug: Log fallback usage

      // Decode HEIC using the image package
      final image = img.decodeImage(heicData);
      if (image == null) {
        throw Exception('Failed to decode HEIC image');
      }

      // Resize if maxWidth is specified
      img.Image outputImage = image;
      if (maxWidth != null && maxWidth < image.width) {
        final targetHeight = (image.height * maxWidth / image.width).round();
        outputImage = img.copyResize(
          image,
          width: maxWidth,
          height: targetHeight,
          interpolation: img.Interpolation.average,
        );
      }

      // Encode to JPG or PNG
      final Uint8List outputData;
      if (format == ImageFormat.jpg) {
        outputData = Uint8List.fromList(
          img.encodeJpg(outputImage, quality: quality),
        );
      } else {
        outputData = Uint8List.fromList(
          img.encodePng(outputImage),
        );
      }

      return outputData;
    } catch (e) {
      throw Exception(
          'Failed to convert HEIC to ${format.name.toUpperCase()}: $e');
    }
  }
}
