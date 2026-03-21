# HEIC to PNG / JPG / WebP Converter

A Flutter package to convert HEIC images to PNG, JPG, or WebP on mobile, web, and desktop.

[![pub.dev](https://img.shields.io/pub/v/heic_to_png_jpg)](https://pub.dev/packages/heic_to_png_jpg)

## Features

- Convert HEIC/HEIF images to **JPG, PNG, or WebP**
- **Web, iOS, Android, macOS, Windows, Linux** support
- Resize by `maxWidth`, `maxHeight`, or both (aspect-ratio-preserving contain mode)
- Adjustable JPG / WebP quality (0–100)
- `isHeic()` — fast magic-byte check, no decode required
- `getImageInfo()` — read dimensions without full conversion
- `convertBatch()` — convert multiple files concurrently
- `convertFile()` — file-path API (mobile / desktop)
- Custom exception types for fine-grained error handling
- Isolate-based processing keeps the UI thread free

## Platform support

| Feature | Android | iOS | Web | macOS | Windows | Linux |
|---------|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
| JPG / PNG | ✅ | ✅ | ✅ | ✅* | ✅* | ✅* |
| WebP | ✅* | ✅* | ✅ | ✅* | ✅* | ✅* |
| `convertFile()` | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |

\* Desktop and WebP on mobile use the Dart `image` package fallback (HEIC support may be limited; WebP output falls back to PNG on mobile).

## Installation

```yaml
dependencies:
  heic_to_png_jpg: ^0.1.0
```

```bash
flutter pub get
```

No changes to `web/index.html` are needed — the package loads libheif-js automatically.

## Usage

### Basic conversion

```dart
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';

final Uint8List heicData = ...; // from file, network, etc.

// Convert to JPG
final jpg = await HeicConverter.convertToJPG(heicData: heicData, quality: 85);

// Convert to PNG
final png = await HeicConverter.convertToPNG(heicData: heicData);

// Convert to WebP (web: native; mobile: falls back to PNG)
final webp = await HeicConverter.convertToWebP(heicData: heicData, quality: 85);

// Generic — choose format at runtime
final output = await HeicConverter.convertToImage(
  heicData: heicData,
  format: ImageFormat.jpg,
  quality: 85,
  maxWidth: 1280,
  maxHeight: 720, // NEW: contain-mode when both are set
);
```

### Resize

```dart
// Scale to fit within 800 × 600, preserving aspect ratio
final resized = await HeicConverter.convertToJPG(
  heicData: heicData,
  maxWidth: 800,
  maxHeight: 600,
);

// Constrain only width
final byWidth = await HeicConverter.convertToPNG(
  heicData: heicData,
  maxWidth: 1024,
);
```

### Check if a file is HEIC

```dart
// Fast — checks magic bytes only, no decoding
if (HeicConverter.isHeic(bytes)) {
  // safe to convert
}
```

### Read image dimensions

```dart
final info = await HeicConverter.getImageInfo(heicData);
print('${info.width} × ${info.height}');
```

### Batch conversion

```dart
final tasks = [
  HeicConversionTask(heicData: data1, format: ImageFormat.jpg, quality: 85),
  HeicConversionTask(heicData: data2, format: ImageFormat.png, maxWidth: 800),
];

final results = await HeicConverter.convertBatch(
  tasks: tasks,
  concurrency: 3, // max simultaneous conversions
);
```

### File-path API (mobile / desktop only)

```dart
final outputPath = await HeicConverter.convertFile(
  inputPath: '/path/to/photo.heic',
  format: ImageFormat.jpg,
  quality: 85,
  maxWidth: 1280,
);
```

### Error handling

```dart
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';

try {
  final jpg = await HeicConverter.convertToJPG(heicData: data);
} on InvalidHeicDataException catch (e) {
  // Bad input (wrong format, invalid quality value)
  print(e.message);
} on ConversionFailedException catch (e) {
  // Encoding / decoding error
  print('${e.message} — caused by: ${e.cause}');
} on PlatformNotSupportedException catch (e) {
  // Feature not available on this platform
  print(e.message);
} on HeicConversionException catch (e) {
  // Any other conversion error
  print(e.message);
}
```

### Custom libheif-js URL (web)

```dart
final png = await HeicConverter.convertToPNG(
  heicData: heicData,
  libheifJsUrl: 'https://cdn.jsdelivr.net/npm/libheif-js@1.19.8/libheif-wasm/libheif-bundle.js',
);
```

## Migration from 0.0.x

| Before (0.0.x) | After (0.1.0) |
|---|---|
| `ImageFormat.jpg` / `.png` only | + `ImageFormat.webp` |
| `maxWidth` only | + `maxHeight` |
| Generic `Exception` thrown | Typed `HeicConversionException` subclasses |
| No way to check if file is HEIC | `HeicConverter.isHeic(data)` |
| No batch API | `HeicConverter.convertBatch(tasks: [...])` |
| Must read file manually | `HeicConverter.convertFile(inputPath: ...)` |

The core API (`convertToJPG`, `convertToPNG`, `convertToImage`, `maxWidth`, `quality`, `libheifJsUrl`) is **fully backward compatible**.

## Notes

- **Mobile (iOS / Android):** Uses `heif_converter` for native decoding, falls back to the Dart `image` package if it fails.
- **Web:** Uses libheif-js (WebAssembly); auto-loaded from jsDelivr CDN.
- **Desktop:** Uses the Dart `image` package fallback (HEIC support may be limited).
- **WebP on mobile:** The `image` package has no WebP encoder, so WebP output falls back to PNG. Web uses the browser's native canvas encoder.

## Issues and Contributions

Please file issues, bugs, or feature requests on [GitHub](https://github.com/IbrahimElmourchidi/heic_to_png_jpg).

## License

MIT — see [LICENSE](LICENSE).

## About the Author

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

- Top-rated Flutter freelancer (100% Job Success on [Upwork](https://www.upwork.com/freelancers/~0105391a1bbefa5522))
- Built 20+ production apps with real-time & payment features
- Passionate about clean architecture, compliance, and UX

---

👥 Contributors

We appreciate all contributions to this project!

<a href="https://github.com/IbrahimElmourchidi/heic_to_png_jpg/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=IbrahimElmourchidi/heic_to_png_jpg" />
</a>
