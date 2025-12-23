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

For web support, no need to add anything to `web/index.html` the package takes car of it for you.

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
- **Web**: Uses the `libheif-js` package, it auto loads it the background no need to add it to `web/index.html`. 
- **Fallback**: If `heif_converter` fails or is unsupported, the package falls back to the `image` package, which may have limited HEIC support.

## Issues and Contributions

Please file any issues, bugs, or feature requests on our [GitHub](https://github.com/IbrahimElmourchidi/heic_to_png_jpg/tree/main) page.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 About the Author

<div align="center">
<a href="https://github.com/IbrahimElmourchidi">
<img src="https://github.com/IbrahimElmourchidi.png" width="80" alt="Ibrahim El Mourchidi" style="border-radius: 50%;">
</a>
<h3>Ibrahim El Mourchidi</h3>
<p>Flutter & Firebase Developer • Cairo, Egypt</p>
<p>
<a href="https://github.com/IbrahimElmourchidi">
<img src="https://img.shields.io/github/followers/IbrahimElmourchidi?label=Follow&style=social" alt="GitHub Follow">
</a>
<a href="mailto:ibrahimelmourchidi@gmail.com">
<img src="https://img.shields.io/badge/Email-D14836?logo=gmail&logoColor=white" alt="Email">
</a>
<a href="https://www.linkedin.com/in/IbrahimElmourchidi">
<img src="https://img.shields.io/badge/LinkedIn-Profile-blue?style=flat&logo=linkedin" alt="LinkedIn Profile">
</a>
</p>
</div>

- 🔹 Top-rated Flutter freelancer (100% Job Success on [Upwork](https://www.upwork.com/freelancers/~0105391a1bbefa5522))
- 🔹 Built 20+ production apps with real-time & payment features
- 🔹 Passionate about clean architecture, compliance, and UX

---


👥 Contributors
We appreciate all contributions to this project! <br><br>
<a href="https://github.com/IbrahimElmourchidi/heic_to_png_jpg/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=IbrahimElmourchidi/heic_to_png_jpg" />
</a>