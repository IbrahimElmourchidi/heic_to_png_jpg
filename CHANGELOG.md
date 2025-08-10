# Changelog

## 0.0.5
- Moved web implementation to `package:web` and `dart:js_interop` to support wasm compilations.
- The plugin handles loading the `libheif-bundle.js` itself, no longer do you need to add it manually to your index.html.
- You can provide a different libheif js version in the convertors e.g. 
```dart
final output = await HeicConverter.convertToPNG(
    heicData: heicData, 
    maxWidth: maxWidth, 
    libheifJsUrl:'https://cdn.jsdelivr.net/npm/libheif-js@1.19.8/libheif-wasm/libheif-bundle.js',
);
```

## 0.0.4
- fixed the web support bug.

## 0.0.3
- fixed the web support bug.

## 0.0.2
- Fixed "No implementation found for this platform" error by removing default `HeicToImageImplementation` and ensuring explicit platform instantiation.

## 0.0.1
- Initial release of `heic_to_png_jpg`.
- Supports HEIC to PNG and JPG conversion on web (via libheif-js) and mobile (via heif_converter).
- Includes platform interface for extensibility.