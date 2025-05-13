import 'dart:async';
import 'dart:typed_data';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:convert';

import 'platform_interface.dart';

// Factory function to create the platform implementation
HeicToImagePlatform getPlatformImplementation() {
  return HeicToPngJpgWeb();
}

class HeicToPngJpgWeb extends HeicToImagePlatform {
  static void registerWith(Registrar registrar) {
    HeicToImagePlatform.instance = HeicToPngJpgWeb();
  }

  @override
  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 80,
    int? maxWidth,
  }) async {
    if (!_isLibheifAvailable()) {
      throw Exception("libheif-js not found. Ensure you've included "
          "<script src='https://cdn.jsdelivr.net/npm/libheif-js@1.18.2/libheif/libheif.min.js'></script> "
          "in your index.html");
    }

    try {
      // Debug: Log input size
      print(
          'Input HEIC size: ${(heicData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // Initialize libheif if it's a function (WebAssembly module constructor)
      js.JsObject libheifInstance = js.context['libheif'];
      if (js.context['libheif'].hasProperty('prototype')) {
        print('libheif is a function, attempting to instantiate...');
        try {
          libheifInstance = js.JsObject(js.context['libheif']);
          print('libheif instantiated: $libheifInstance');
        } catch (e) {
          print('Failed to instantiate libheif: $e');
        }
      }

      // Wait for initialization if ready Promise exists
      if (libheifInstance.hasProperty('ready')) {
        print('Waiting for libheif.ready...');
        await _waitForJsPromise(libheifInstance['ready']);
        print('libheif initialized');
      } else {
        print('No ready Promise found, assuming libheif is ready');
      }

      // Check for Module property (common in WebAssembly)
      if (libheifInstance.hasProperty('Module')) {
        print('Found libheif.Module, switching to Module');
        libheifInstance = libheifInstance['Module'];
      }

      // Log all properties of the initialized libheif
      final libheifProps = _getJsObjectProperties(libheifInstance);
      print('libheif properties: $libheifProps');

      // Convert Uint8List to JavaScript Uint8Array
      final jsHeicData = js.JsObject(js.context['Uint8Array'], [heicData]);

      // Try to find a decoding method
      String? decodeMethod;
      if (libheifInstance.hasProperty('decodeBuffer')) {
        decodeMethod = 'decodeBuffer';
      } else if (libheifInstance.hasProperty('decode')) {
        decodeMethod = 'decode';
      } else if (libheifInstance.hasProperty('HeifDecoder')) {
        print('Trying HeifDecoder...');
        final decoder = js.JsObject(libheifInstance['HeifDecoder']);
        if (decoder.hasProperty('decode')) {
          decodeMethod = 'decode';
          libheifInstance = decoder; // Use decoder instance
        }
      }

      if (decodeMethod == null) {
        throw Exception(
            'No valid decode method found in libheif-js. Available properties: $libheifProps');
      }
      print('Using decode method: $decodeMethod');

      // Decode HEIC data
      dynamic images;
      try {
        // Try with ArrayBuffer
        final buffer = jsHeicData['buffer'];
        if (buffer == null) {
          throw Exception('Uint8Array buffer is null');
        }
        images = libheifInstance.callMethod(decodeMethod, [buffer]);
      } catch (e) {
        print('Failed with ArrayBuffer: $e, trying Uint8Array directly');
        // Fallback: Try passing Uint8Array directly
        images = libheifInstance.callMethod(decodeMethod, [jsHeicData]);
      }

      if (images == null || images.length == 0) {
        throw Exception('No valid images found in HEIC file');
      }

      // Use the first image
      final image = images[0];
      if (image == null) {
        throw Exception('First image is null');
      }

      // Verify display method exists
      if (!image.hasProperty('display')) {
        throw Exception('Image display method not available');
      }

      // Get image dimensions
      final width = image.callMethod('get_width') as int?;
      final height = image.callMethod('get_height') as int?;
      if (width == null || height == null || width <= 0 || height <= 0) {
        throw Exception(
            'Invalid image dimensions: width=$width, height=$height');
      }

      // Calculate target dimensions for resizing (if maxWidth is specified)
      int targetWidth = width;
      int targetHeight = height;
      if (maxWidth != null && maxWidth < width) {
        targetWidth = maxWidth;
        targetHeight = (height * maxWidth / width).round();
        print('Resizing to: ${targetWidth}x$targetHeight');
      }

      // Create canvas with target dimensions
      final canvas =
          html.CanvasElement(width: targetWidth, height: targetHeight);
      final context = canvas.context2D;

      // Create image data for the original dimensions
      final imageData = context.createImageData(width, height);

      // Render image to image data
      final completer = Completer<void>();
      image.callMethod('display', [
        imageData,
        js.allowInterop((dynamic displayData) {
          if (displayData == null) {
            completer.completeError(
                Exception('HEIF processing error: display returned null'));
          } else {
            completer.complete();
          }
        })
      ]);

      await completer.future;

      // Draw image data on canvas (resize if needed)
      if (targetWidth != width || targetHeight != height) {
        // Create a temporary canvas for the original image
        final tempCanvas = html.CanvasElement(width: width, height: height);
        final tempContext = tempCanvas.context2D;
        tempContext.putImageData(imageData, 0, 0);

        // Draw the temporary canvas onto the resized canvas
        context.drawImageScaled(tempCanvas, 0, 0, targetWidth, targetHeight);
      } else {
        context.putImageData(imageData, 0, 0);
      }

      // Convert to PNG or JPG
      final mimeType = format == ImageFormat.jpg ? 'image/jpeg' : 'image/png';
      final dataUrl = canvas.toDataUrl(
          mimeType, format == ImageFormat.jpg ? quality / 100.0 : null);

      // Extract base64 data
      final base64 = dataUrl.split(',').last;
      final outputData = base64Decode(base64);

      // Debug: Log output size
      print(
          'Output ${format.name.toUpperCase()} size: ${(outputData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // Free the image handle if free method exists
      if (image.hasProperty('free')) {
        image.callMethod('free');
      }

      return outputData;
    } catch (e) {
      throw Exception(
          'Failed to convert HEIC to ${format.name.toUpperCase()}: $e');
    }
  }

  bool _isLibheifAvailable() {
    final available = js.context.hasProperty('libheif');
    print('libheif available: $available');
    if (available) {
      print('libheif object (pre-init): ${js.context['libheif']}');
    }
    return available;
  }

  // Helper to wait for a JavaScript Promise
  Future<void> _waitForJsPromise(dynamic promise) async {
    final completer = Completer<void>();
    if (promise == null) {
      completer.completeError(Exception('Promise is null'));
      return completer.future;
    }
    promise.callMethod('then', [
      js.allowInterop((_) => completer.complete()),
      js.allowInterop(
          (error) => completer.completeError(Exception(error.toString()))),
    ]);
    return completer.future;
  }

  // Helper to get all properties of a JS object
  List<String> _getJsObjectProperties(js.JsObject obj) {
    final props = <String>[];
    final jsArray = js.context['Object']
        .callMethod('getOwnPropertyNames', [obj]) as js.JsArray;
    for (var i = 0; i < jsArray.length; i++) {
      props.add(jsArray[i].toString());
    }
    return props;
  }
}
