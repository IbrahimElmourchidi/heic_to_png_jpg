import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
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
  }) async {
    // Debug: Log input size
    print(
        'Input HEIC size: ${(heicData.length / 1024 / 1024).toStringAsFixed(2)} MB');

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
            print('Resized to: ${maxWidth}x$targetHeight');
          }
        }

        // Debug: Log output size
        print(
            'Output ${format.name.toUpperCase()} size: ${(outputData.length / 1024 / 1024).toStringAsFixed(2)} MB');

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
      print('Using Dart fallback for HEIC conversion');

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
        print('Resized to: ${maxWidth}x$targetHeight');
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

      // Debug: Log output size
      print(
          'Output ${format.name.toUpperCase()} size: ${(outputData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      return outputData;
    } catch (e) {
      throw Exception(
          'Failed to convert HEIC to ${format.name.toUpperCase()}: $e');
    }
  }
}
