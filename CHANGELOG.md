# Changelog
## [0.0.6] - 2024-12-23

### Changed
- **BREAKING**: Default quality increased from 80 to 100 for maximum quality output
- Quality parameter now applies correctly even when `maxWidth` is not specified
- Optimized conversion process to avoid unnecessary re-encoding when quality is 100% (default)

### Fixed
- Fixed issue where quality parameter was only applied during image resizing
- Fixed quality not being respected when converting without resizing
- Improved image quality preservation in all conversion scenarios

### Improved
- Better performance: Skip re-encoding when using default quality (100%) and no resizing
- More efficient memory usage by avoiding decode/encode cycles when not needed
- Enhanced quality control consistency across different conversion paths

### Technical Details
- Added smart processing detection: only re-encodes when quality < 100 or resizing is needed
- Maintained backward compatibility with existing API
- Quality parameter now works as expected in all scenarios:
  - Converting without resizing (previously ignored)
  - Converting with resizing (previously worked)
  - Converting with custom quality settings

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