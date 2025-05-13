# HEIC to PNG/JPG Converter

A Flutter package to convert HEIC images to PNG or JPG format on both web and mobile platforms.

## Features

- Convert HEIC images to PNG or JPG format
- Support for Web, iOS, and Android platforms
- Simple API with dedicated functions for PNG and JPG conversion
- Adjustable quality for JPG output

## Getting Started

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  heic_to_png_jpg: ^0.1.0
```

Run:

```bash
flutter pub get
```

### Web Setup

For web support, add the following script to your `web/index.html`:

```html
<script src="https://cdn.jsdelivr.net/npm/libheif-js@1.18.2/libheif/libheif.min.js"></script>
```

## Usage

```dart
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';
import 'dart:typed_data';

Future<void> convertImage() async {
  // Get your HEIC image data as Uint8List
  Uint8List heicData = ...; // from file, network, etc.
  
  try {
    // Convert to PNG
    Uint8List pngData = await HeicConverter.convertToPNG(heicData: heicData);
    
    // Convert to JPG with custom quality
    Uint8List jpgData = await HeicConverter.convertToJPG(
      heicData: heicData,
      quality: 80,
    );
    
    // Use the converted image data
    // ...
  } catch (e) {
    print('Error converting image: $e');
  }
}
```

## Example with FlutterFlow

Integrate this package with FlutterFlow using custom functions:

```dart
// In your FlutterFlow custom functions
Future<Uint8List> convertHeicToPng(Uint8List heicData) async {
  return await HeicConverter.convertToPNG(heicData: heicData);
}

Future<Uint8List> convertHeicToJpg(Uint8List heicData, int quality) async {
  return await HeicConverter.convertToJPG(heicData: heicData, quality: quality);
}
```

## Notes

- **Mobile**: Uses the `heif_converter` package for iOS and Android, which requires temporary file operations.
- **Web**: Requires the `libheif-js` script in `index.html` for HEIC decoding.
- **Fallback**: If `heif_converter` fails or is unsupported, the package falls back to the `image` package, which may have limited HEIC support.

## Issues and Contributions

Please file any issues, bugs, or feature requests on our [GitHub](https://github.com/utanium/heic_to_png_jpg) page.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.