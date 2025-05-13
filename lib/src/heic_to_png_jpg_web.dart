import 'dart:async';
import 'dart:typed_data';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:convert';

import 'platform_interface.dart';

class HeicToPngJpgWeb extends HeicToImagePlatform {
  static void registerWith(Registrar registrar) {
    HeicToImagePlatform.instance = HeicToPngJpgWeb();
  }

  @override
  Future<Uint8List> convertToImage({
    required Uint8List heicData,
    ImageFormat format = ImageFormat.jpg,
    int quality = 90,
  }) async {
    if (!_isLibheifAvailable()) {
      throw Exception("libheif-js not found. Ensure you've included "
          "<script src='https://cdn.jsdelivr.net/npm/libheif-js@1.18.2/libheif/libheif.min.js'></script> "
          "in your index.html");
    }

    try {
      // Convert Uint8List to JavaScript Uint8Array
      var jsHeicData =
          js.context.callMethod('Uint8Array', [js.JsObject.jsify(heicData)]);

      // Create HeifDecoder
      var decoder = js.JsObject(js.context['libheif']['HeifDecoder']);

      // Decode HEIC data
      var images = decoder.callMethod('decode', [jsHeicData]);

      if (images.length == 0) {
        throw Exception('No images found in HEIC file');
      }

      // Use the first image
      var image = images[0];

      // Get image dimensions
      var width = image.callMethod('get_width');
      var height = image.callMethod('get_height');

      // Create canvas
      var canvas = html.CanvasElement(width: width, height: height);
      var context = canvas.context2D;
      var imageData = context.createImageData(width, height);

      // Render image to canvas
      var completer = Completer<void>();
      image.callMethod('display', [
        imageData,
        js.allowInterop((displayData) {
          if (displayData == null) {
            completer.completeError(Exception('HEIF processing error'));
          } else {
            completer.complete();
          }
        })
      ]);

      await completer.future;

      // Draw imageData on canvas
      context.putImageData(imageData, 0, 0);

      // Convert to PNG or JPG
      var mimeType = format == ImageFormat.jpg ? 'image/jpeg' : 'image/png';
      var dataUrl = canvas.toDataUrl(
          mimeType, format == ImageFormat.jpg ? quality / 100.0 : null);

      // Extract base64 data
      var base64 = dataUrl.split(',').last;
      var outputData = base64Decode(base64);

      return outputData;
    } catch (e) {
      throw Exception(
          'Failed to convert HEIC to ${format.name.toUpperCase()}: $e');
    }
  }

  bool _isLibheifAvailable() {
    return js.context.hasProperty('libheif');
  }
}
