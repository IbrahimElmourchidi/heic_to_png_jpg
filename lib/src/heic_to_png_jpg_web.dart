import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:heic_to_png_jpg/src/image_format.dart';
import 'package:web/web.dart' as web;

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
    int quality = 80,
    int? maxWidth,
    String? libheifJsUrl,
  }) async {
    if (!_isLibheifAvailable()) {
      try {
        await _loadScript(libheifJsUrl ?? defaultLibheifUrl);
      } catch (e) {
        throw Exception("libheif-js not found. Ensure you've included "
            "<script src='${libheifJsUrl ?? defaultLibheifUrl}'></script> "
            "in your index.html");
      }
    }

    try {
      // Debug: Log input size
      log('Input HEIC size: ${(heicData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // Initialize libheif if it's a function (WebAssembly module constructor)
      HeifDecoder libheifInstance = HeifDecoder();
      final images = libheifInstance.decode(heicData.toJS);

      if (images.toDart.isEmpty) {
        throw Exception('No valid images found in HEIC file');
      }

      // Use the first image
      final image = images[0];
      // Get image dimensions
      final width = image.getWidth();
      final height = image.getHeight();
      if (width <= 0 || height <= 0) {
        throw Exception('Invalid image dimensions: width=$width, height=$height');
      }

      // Calculate target dimensions for resizing (if maxWidth is specified)
      int targetWidth = width;
      int targetHeight = height;
      if (maxWidth != null && maxWidth < width) {
        targetWidth = maxWidth;
        targetHeight = (height * maxWidth / width).round();
        log('Resizing to: ${targetWidth}x$targetHeight');
      }

      // Create canvas with target dimensions
      final canvas = web.HTMLCanvasElement();
      canvas.width = targetWidth;
      canvas.height = targetHeight;
      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (context == null) {
        throw Exception('Failed to get canvas context');
      }

      // Create image data for the original dimensions
      final imageData = context.createImageData(width.toJS, height);

      // Render image to image data
      final completer = Completer<void>();

      void displayCallback(JSObject? displayData) {
        if (displayData == null) {
          completer.completeError(Exception('HEIF processing error: display returned null'));
        } else {
          completer.complete();
        }
      }

      image.display(imageData, displayCallback.toJS);

      await completer.future;

      // Draw image data on canvas (resize if needed)
      if (targetWidth != width || targetHeight != height) {
        // Create a temporary canvas for the original image
        final tempCanvas = web.HTMLCanvasElement();
        tempCanvas.width = width;
        tempCanvas.height = height;
        final tempContext = tempCanvas.context2D;
        tempContext.putImageData(imageData, 0, 0);

        // Draw the temporary canvas onto the resized canvas
        context.drawImageScaled(tempCanvas, 0, 0, targetWidth.toDouble(), targetHeight.toDouble());
      } else {
        context.putImageData(imageData, 0, 0);
      }

      // Convert to PNG or JPG
      final mimeType = format == ImageFormat.jpg ? 'image/jpeg' : 'image/png';
      final dataUrl =
          canvas.toDataUrl(mimeType, format == ImageFormat.jpg ? quality / 100.0 : null);

      // Extract base64 data
      final base64 = dataUrl.split(',').last;
      final outputData = base64Decode(base64);

      // Debug: Log output size
      log('Output ${format.name.toUpperCase()} size: ${(outputData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // Free the image handle if free method exists
      image.free();

      return outputData;
    } catch (e) {
      throw Exception('Failed to convert HEIC to ${format.name.toUpperCase()}: $e');
    }
  }

  bool _isLibheifAvailable() {
    final available = globalContext.hasProperty('libheifModule'.toJS);
    log('libheif available: $available');
    if (available.toDart) {
      log('libheif object (pre-init): ${web.window['libheifModule']}');
    }
    return available.toDart;
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
          completer.completeError(Exception('Failed to load script: $url'));
        }.toJS);

    web.document.head!.append(script);
    return completer.future;
  }
}
