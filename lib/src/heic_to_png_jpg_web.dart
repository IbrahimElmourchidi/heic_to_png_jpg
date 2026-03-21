import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:web/web.dart' as web;

import 'exceptions.dart';
import 'platform_interface.dart';

@JS('libheif')
external JSObject libheif();

extension type LibheifModule._(JSObject _) implements JSObject {}

@JS('libheifModule.HeifImage')
extension type HeifImage._(JSObject _) implements JSObject {
  external HeifImage();

  @JS('get_width')
  external int getWidth();

  @JS('get_height')
  external int getHeight();

  @JS('display')
  external void display(JSObject displayData, JSFunction callback);

  @JS('free')
  external void free();
}

@JS('libheifModule.HeifDecoder')
extension type HeifDecoder._(JSObject _) implements JSObject {
  external HeifDecoder();

  external JSArray<HeifImage> decode(JSUint8Array data);
}

// Define a JS function type
typedef DisplayCallback = void Function(JSObject displayData);

// Factory function to create the platform implementation
HeicToImagePlatform getPlatformImplementation() {
  return HeicToPngJpgWeb();
}

const defaultLibheifUrl =
    'https://cdn.jsdelivr.net/npm/libheif-js@1.19.8/libheif-wasm/libheif-bundle.js';

class HeicToPngJpgWeb extends HeicToImagePlatform {
  HeicToPngJpgWeb();

  static void registerWith(Registrar registrar) {
    HeicToImagePlatform.instance = HeicToPngJpgWeb();
  }

  @override
  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
    String? libheifJsUrl,
  }) async {
    // Validate quality
    if (quality < 0 || quality > 100) {
      throw InvalidHeicDataException(
          'quality must be between 0 and 100, got $quality');
    }

    if (!_isLibheifAvailable()) {
      try {
        await _loadScript(libheifJsUrl ?? defaultLibheifUrl);
      } catch (e) {
        throw ConversionFailedException(
            "libheif-js not found. Ensure you've included "
            "<script src='${libheifJsUrl ?? defaultLibheifUrl}'></script> "
            "in your index.html");
      }
    }

    try {
      HeifDecoder libheifInstance = HeifDecoder();
      final images = libheifInstance.decode(heicData.toJS);

      if (images.toDart.isEmpty) {
        throw const ConversionFailedException('No valid images found in HEIC file');
      }

      final image = images[0];
      final width = image.getWidth();
      final height = image.getHeight();
      if (width <= 0 || height <= 0) {
        throw ConversionFailedException(
            'Invalid image dimensions: width=$width, height=$height');
      }

      // Calculate target dimensions (contain mode when both are set)
      int targetWidth = width;
      int targetHeight = height;

      if (maxWidth != null && maxHeight != null) {
        final scaleW = maxWidth / width;
        final scaleH = maxHeight / height;
        final scale = scaleW < scaleH ? scaleW : scaleH;
        if (scale < 1.0) {
          targetWidth = (width * scale).round();
          targetHeight = (height * scale).round();
        }
      } else if (maxWidth != null && maxWidth < width) {
        targetWidth = maxWidth;
        targetHeight = (height * maxWidth / width).round();
      } else if (maxHeight != null && maxHeight < height) {
        targetHeight = maxHeight;
        targetWidth = (width * maxHeight / height).round();
      }

      // Create canvas with target dimensions
      final canvas = web.HTMLCanvasElement();
      canvas.width = targetWidth;
      canvas.height = targetHeight;
      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (context == null) {
        throw const ConversionFailedException('Failed to get canvas context');
      }

      // Create image data for the original dimensions
      final imageData = context.createImageData(width.toJS, height);

      // Render image to image data
      final completer = Completer<void>();

      void displayCallback(JSObject? displayData) {
        if (displayData == null) {
          completer.completeError(
              const ConversionFailedException('HEIF processing error: display returned null'));
        } else {
          completer.complete();
        }
      }

      image.display(imageData, displayCallback.toJS);

      await completer.future;

      // Draw image data on canvas (resize if needed)
      if (targetWidth != width || targetHeight != height) {
        final tempCanvas = web.HTMLCanvasElement();
        tempCanvas.width = width;
        tempCanvas.height = height;
        final tempContext = tempCanvas.context2D;
        tempContext.putImageData(imageData, 0, 0);

        context.drawImage(
            tempCanvas, 0, 0, targetWidth.toDouble(), targetHeight.toDouble());
      } else {
        context.putImageData(imageData, 0, 0);
      }

      // Convert to target format
      final String mimeType;
      final num? qualityArg;
      switch (format) {
        case ImageFormat.jpg:
          mimeType = 'image/jpeg';
          qualityArg = quality / 100.0;
        case ImageFormat.png:
          mimeType = 'image/png';
          qualityArg = null;
        case ImageFormat.webp:
          mimeType = 'image/webp';
          qualityArg = quality / 100.0;
      }

      final dataUrl = canvas.toDataUrl(mimeType, qualityArg);
      final base64 = dataUrl.split(',').last;
      final outputData = base64Decode(base64);

      image.free();

      return outputData;
    } on HeicConversionException {
      rethrow;
    } catch (e) {
      throw ConversionFailedException(
          'Failed to convert HEIC to ${format.name.toUpperCase()}', cause: e);
    }
  }

  bool _isLibheifAvailable() {
    return globalContext.hasProperty('libheifModule'.toJS).toDart;
  }

  Future<void> _loadScript(String url) async {
    final script = web.HTMLScriptElement();
    script.type = 'application/javascript';
    script.src = url;
    script.defer = true;

    final completer = Completer<void>();

    script.addEventListener(
        'load',
        (web.Event _) {
          globalContext['libheifModule'] = libheif();
          completer.complete();
        }.toJS);

    script.addEventListener(
        'error',
        (web.Event _) {
          completer.completeError(
              ConversionFailedException('Failed to load script: $url'));
        }.toJS);

    web.document.head!.append(script);
    return completer.future;
  }
}
