import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:heif_converter/heif_converter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'platform_interface.dart';

class HeicToPngJpgMobile extends HeicToImagePlatform {
  @override
  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
  }) async {
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
        final Uint8List outputData = await outputFile.readAsBytes();

        // Clean up temporary files
        await heicFile.delete();
        await outputFile.delete();

        return outputData;
      } catch (e) {
        // Fallback to Dart implementation if heif_converter fails
        return _convertUsingDart(heicData, format, quality);
      }
    } else {
      // Fallback to Dart implementation for other platforms
      return _convertUsingDart(heicData, format, quality);
    }
  }

  Future<Uint8List> _convertUsingDart(
    Uint8List heicData,
    ImageFormat format,
    int quality,
  ) async {
    try {
      // Try to decode HEIC using the image package
      final image = img.decodeImage(heicData);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Encode as JPG or PNG based on format
      if (format == ImageFormat.jpg) {
        final jpgData = img.encodeJpg(image, quality: quality);
        return Uint8List.fromList(jpgData);
      } else {
        final pngData = img.encodePng(image);
        return Uint8List.fromList(pngData);
      }
    } catch (e) {
      throw Exception(
          'Failed to convert HEIC to ${format.name.toUpperCase()}: $e');
    }
  }
}
