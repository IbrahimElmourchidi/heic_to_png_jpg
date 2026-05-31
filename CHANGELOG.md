# Changelog

## [0.1.2] - 2026-05-31

### Fixed
- Bump `heif_converter` dependency to `^1.0.6` — adds Swift Package Manager (SPM)
  support on iOS, silencing Flutter's *"plugins do not support Swift Package Manager"*
  warning that appeared on Flutter 3.24+.
- Minimum iOS deployment target is now **12.0** (transitive requirement from
  `heif_converter` 1.0.3+; iOS 11 is no longer supported).
- Raise Flutter SDK floor to `>=3.24.0` to match stable SPM support.

### Changed
- Bump `flutter_lints` dev dependency to `^5.0.0` (was `^2.0.1`).
- Refresh lockfile to latest within-constraint versions of all transitive
  dependencies (`image` 4.5.4 → 4.9.1, `path_provider_android` 2.2.17 → 2.3.1,
  `path_provider_foundation` 2.4.1 → 2.6.0, `archive`, `crypto`, `ffi`, `xml`,
  and others). No API changes; bug-fix and performance improvements only.
- Apply `use_super_parameters` to `InvalidHeicDataException`.
- Remove unnecessary `library` directive from `lib/heic_to_png_jpg.dart`.

## [0.1.1] - 2026-03-21
- fixed the documentation comments

## [0.1.0] - 2026-03-21

### Added
- **WebP output format** — new `ImageFormat.webp` value and `HeicConverter.convertToWebP()` convenience method. Web uses native canvas `image/webp`; mobile falls back to PNG (the `image` package has no WebP encoder).
- **`maxHeight` parameter** on all conversion methods. When both `maxWidth` and `maxHeight` are set, images are scaled to fit within the bounding box (contain mode) while preserving aspect ratio.
- **`HeicConverter.isHeic()`** — pure-Dart magic-byte check; no decode needed.
- **`HeicConverter.getImageInfo()`** — returns `HeicImageInfo` (width, height) by decoding in an isolate.
- **`HeicConverter.convertToWebP()`** — convenience wrapper for WebP output.
- **`HeicConverter.convertBatch()`** — converts a list of `HeicConversionTask` objects concurrently with a configurable `concurrency` limit (default 3).
- **`HeicConverter.convertFile()`** — file-path based API (mobile/desktop only); reads from disk, writes result back, returns output path.
- **Custom exception hierarchy** — `HeicConversionException`, `InvalidHeicDataException`, `ConversionFailedException`, `PlatformNotSupportedException`.
- **`HeicImageInfo`** class — holds `width` and `height` of a HEIC image.
- **`HeicConversionTask`** class — describes a single job for `convertBatch()`.
- **Desktop platform support** — added `macos`, `windows`, `linux` to `pubspec.yaml` platforms block (existing Dart fallback handles them).
- **Unit tests** — 20 tests covering `isHeic`, enum values, exception hierarchy, and data classes.
- **`topics`** in pubspec.yaml for better pub.dev discoverability (`image`, `heic`, `heif`, `converter`).

### Fixed
- **Temp file name collision** — temp files now use a microsecond timestamp (`heic_<id>.heic`) instead of the hardcoded `temp.heic`, preventing corruption when multiple conversions run concurrently.
- **Temp file cleanup on error** — a `finally`-style delete ensures the input `.heic` temp file is removed even when `heif_converter` throws.
- **Debug `log()` calls removed** — all `dart:developer` `log()` calls have been removed from `heic_to_png_jpg_web.dart`.
- **Quality parameter validation** — values outside 0–100 now throw `InvalidHeicDataException` instead of being silently passed to encoders.

### Changed
- **Lazy platform singleton** — `HeicToImagePlatform` is now instantiated once (lazy singleton) instead of on every `convertToImage()` call.
- **`drawImageScaled` replaced** with `drawImage` (the former was deprecated in `package:web`).
- **Barrel file** now exports `HeicConversionException`, `InvalidHeicDataException`, `ConversionFailedException`, `PlatformNotSupportedException`, `HeicImageInfo`, and `HeicConversionTask`.
- **Version bump** to `0.1.0`.

---

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
