import 'dart:typed_data';

import 'image_format.dart';

/// Describes a single HEIC conversion job for use with [HeicConverter.convertBatch].
class HeicConversionTask {
  final Uint8List heicData;
  final ImageFormat format;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;

  const HeicConversionTask({
    required this.heicData,
    this.format = ImageFormat.jpg,
    this.quality = 100,
    this.maxWidth,
    this.maxHeight,
  });
}
