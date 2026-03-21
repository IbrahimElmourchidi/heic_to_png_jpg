# heic_to_png_jpg — Update Plan (v0.1.0)

> Current version: **0.0.6** | Target version: **0.1.0**
> Date: 2026-03-21

---

## 1. Bug Fixes & Code Quality Issues

### 1.1 Fixed Temp File Name (Concurrency Bug)
**File:** `lib/src/heic_to_png_jpg_mobile.dart:33-34`
**Problem:** Temp files use a hardcoded name `temp.heic` / `temp.jpg`. If two conversions run simultaneously, they overwrite each other's temp files, causing corrupt output or crashes.
**Fix:** Use a UUID or timestamp-based unique filename per conversion call.

```dart
// Before
final heicPath = '${tempDir.path}/temp.heic';
final outputPath = '${tempDir.path}/temp.${format.name}';

// After
final id = DateTime.now().microsecondsSinceEpoch;
final heicPath = '${tempDir.path}/heic_$id.heic';
final outputPath = '${tempDir.path}/heic_$id.${format.name}';
```

### 1.2 Remove Debug Log Statements from Production Code
**File:** `lib/src/heic_to_png_jpg_web.dart:81,107-108,164,179-182`
**Problem:** `dart:developer` `log()` calls are left in production code. These are noisy for consumers and expose internal details.
**Fix:** Remove all `log()` calls, or gate them behind a debug flag / `kDebugMode`.

### 1.3 Temp File Cleanup on Error
**File:** `lib/src/heic_to_png_jpg_mobile.dart:91-94`
**Problem:** If conversion fails, the catch block jumps to the Dart fallback without cleaning up the temp `.heic` file that was already written.
**Fix:** Add a `finally` block (or cleanup in `catch`) to delete temp files regardless of outcome.

### 1.4 Quality Parameter Validation
**Problem:** No validation on the `quality` parameter. Values outside 0-100 are silently passed through, leading to undefined behavior in encoders.
**Fix:** Clamp or throw on invalid quality values.

---

## 2. New Features

### 2.1 WebP Output Format Support
**Priority:** High
**Why:** WebP is the modern standard for web images — smaller file sizes than JPG at similar quality, supports transparency like PNG. Most developers converting HEIC would also want WebP as an output option.

**Changes:**
- Add `webp` to the `ImageFormat` enum
- Add `HeicConverter.convertToWebP()` convenience method
- Mobile: Use `img.encodeWebP()` from the `image` package (already a dependency, already supports WebP encoding)
- Web: Use `canvas.toDataUrl('image/webp', quality)` (widely supported in browsers)

```dart
enum ImageFormat {
  jpg,
  png,
  webp,  // NEW
}
```

### 2.2 maxHeight Parameter
**Priority:** High
**Why:** Only `maxWidth` exists. Users frequently need to constrain by height (e.g., thumbnails, profile avatars, feed images with fixed height). Every major image processing library offers both dimensions.

**Changes:**
- Add `int? maxHeight` parameter to all conversion methods and the platform interface
- Resize logic: if both `maxWidth` and `maxHeight` are set, fit within the bounding box while preserving aspect ratio (contain mode)
- If only one is set, scale proportionally based on that axis

```dart
static Future<Uint8List> convertToImage({
  required Uint8List heicData,
  ImageFormat format = ImageFormat.jpg,
  int quality = 100,
  int? maxWidth,
  int? maxHeight,  // NEW
  String? libheifJsUrl,
})
```

### 2.3 Isolate-Based Conversion (Mobile)
**Priority:** High
**Why:** Image decoding and encoding is CPU-intensive. Currently all processing runs on the main UI thread, causing UI jank/freezes on large HEIC files (iPhone photos are typically 2-5 MB). This is the #1 performance issue.

**Changes:**
- Wrap the `image` package decode/encode operations in `Isolate.run()` or `compute()`
- The `heif_converter` call itself is already async (native), but the post-processing (decode → resize → encode) blocks the UI thread
- Only the Dart fallback and post-processing paths need isolate wrapping

```dart
// In _convertUsingDart and the post-processing block:
final outputData = await Isolate.run(() {
  final image = img.decodeImage(heicData);
  // ... resize, encode ...
  return encoded;
});
```

### 2.4 Batch Conversion
**Priority:** Medium
**Why:** Apps often need to convert multiple HEIC files (gallery imports, bulk uploads). Converting sequentially is slow; a batch API enables parallel/pooled conversion.

**Changes:**
- Add `HeicConverter.convertBatch()` method
- Accept a list of `HeicConversionTask` objects (heicData + per-file options)
- Return a list of results (or a map keyed by index)
- Use `Future.wait` with optional concurrency limit to prevent memory exhaustion

```dart
class HeicConversionTask {
  final Uint8List heicData;
  final ImageFormat format;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;

  const HeicConversionTask({
    required this.heicData,
    this.format = ImageFormat.jpg,
    this.quality = 100,
    this.maxWidth,
    this.maxHeight,
  });
}

static Future<List<Uint8List>> convertBatch({
  required List<HeicConversionTask> tasks,
  int concurrency = 3,
}) async { ... }
```

### 2.5 File-Path Based API
**Priority:** Medium
**Why:** Many apps already have HEIC files on disk (camera roll, downloads). Currently users must read the entire file into memory as `Uint8List` before converting, then write the result back. A file-path API avoids this unnecessary memory copy and simplifies usage.

**Changes:**
- Add `HeicConverter.convertFile()` that accepts an input file path and optional output file path
- Returns the output file path (auto-generates one in temp dir if not provided)
- Mobile-only (web has no file system) — throw `UnsupportedError` on web

```dart
/// Converts a HEIC file on disk. Returns the output file path.
/// Throws [UnsupportedError] on web.
static Future<String> convertFile({
  required String inputPath,
  String? outputPath,
  ImageFormat format = ImageFormat.jpg,
  int quality = 100,
  int? maxWidth,
  int? maxHeight,
}) async { ... }
```

### 2.6 HEIC Validation / Detection
**Priority:** Medium
**Why:** Users often need to check if a file is actually HEIC before attempting conversion. Currently they must attempt conversion and catch errors, which is slow and wasteful.

**Changes:**
- Add `HeicConverter.isHeic(Uint8List data)` static method
- Check the file's magic bytes (HEIC/HEIF files start with an `ftyp` box at offset 4, with brand identifiers like `heic`, `heix`, `hevc`, `mif1`)
- Pure Dart, works on all platforms, no dependencies needed

```dart
/// Returns true if the data appears to be a valid HEIC/HEIF file.
static bool isHeic(Uint8List data) {
  if (data.length < 12) return false;
  // Check for 'ftyp' box at offset 4
  final ftyp = String.fromCharCodes(data.sublist(4, 8));
  if (ftyp != 'ftyp') return false;
  // Check brand
  final brand = String.fromCharCodes(data.sublist(8, 12));
  return const {'heic', 'heix', 'hevc', 'mif1', 'msf1', 'hevx'}
      .contains(brand);
}
```

### 2.7 Image Info Extraction (Without Full Conversion)
**Priority:** Low
**Why:** Sometimes you need to know the dimensions of a HEIC image (for layout calculations, validation) without paying the cost of full conversion.

**Changes:**
- Add `HeicConverter.getImageInfo(Uint8List heicData)` method
- Returns a `HeicImageInfo` object with `width`, `height`, and optionally `hasAlpha`
- On web: use libheif decoder's `getWidth()`/`getHeight()` without rendering
- On mobile: use `heif_converter` or `image` package header parsing

```dart
class HeicImageInfo {
  final int width;
  final int height;

  const HeicImageInfo({required this.width, required this.height});
}

static Future<HeicImageInfo> getImageInfo(Uint8List heicData) async { ... }
```

### 2.8 Desktop Platform Support (macOS, Windows, Linux)
**Priority:** Low
**Why:** Flutter desktop is growing. The package currently falls through to the Dart `image` package fallback on desktop, but the platforms aren't declared in pubspec.yaml, so `pub.dev` won't list them.

**Changes:**
- Add `macos`, `windows`, `linux` to the `platforms:` block in pubspec.yaml
- The existing Dart fallback (`_convertUsingDart`) already handles non-iOS/Android platforms
- Test on each desktop platform to verify the `image` package can decode HEIC (limited support — document caveats)
- Consider using `heif_converter` FFI bindings for better desktop HEIC support in the future

```yaml
platforms:
  android:
  ios:
  web:
  macos:    # NEW
  windows:  # NEW
  linux:    # NEW
```

---

## 3. Architecture & Code Quality

### 3.1 Custom Exception Types
**Problem:** All errors throw generic `Exception('message')`. Consumers can't distinguish between different failure modes programmatically (invalid input vs. conversion failure vs. unsupported platform).

**Changes:**
- Create `HeicConversionException` hierarchy:

```dart
/// Base exception for all HEIC conversion errors.
class HeicConversionException implements Exception {
  final String message;
  final Object? cause;
  const HeicConversionException(this.message, {this.cause});
  @override
  String toString() => 'HeicConversionException: $message';
}

/// Thrown when the input data is not a valid HEIC file.
class InvalidHeicDataException extends HeicConversionException {
  const InvalidHeicDataException([String message = 'Invalid HEIC data'])
      : super(message);
}

/// Thrown when conversion fails due to an encoding/decoding error.
class ConversionFailedException extends HeicConversionException {
  const ConversionFailedException(super.message, {super.cause});
}

/// Thrown when a feature is not supported on the current platform.
class PlatformNotSupportedException extends HeicConversionException {
  const PlatformNotSupportedException(super.message);
}
```

### 3.2 Export All Public Types from Barrel File
**File:** `lib/heic_to_png_jpg.dart`
**Problem:** Only `HeicConverter` and `ImageFormat` are exported. New types (exceptions, `HeicImageInfo`, `HeicConversionTask`) should also be exported.

### 3.3 Platform Instance Re-assignment on Every Call
**File:** `lib/src/heic_to_png_jpg_base.dart:55`
**Problem:** Every call to `convertToImage()` re-creates and re-assigns the platform instance. This is unnecessary — the platform doesn't change at runtime.

**Fix:** Initialize the platform instance once (lazy singleton):

```dart
static HeicToImagePlatform get _platform {
  HeicToImagePlatform.instance ??= implementation.getPlatformImplementation();
  return HeicToImagePlatform.instance;
}
```

---

## 4. Testing

### 4.1 Unit Tests
**Problem:** The `test/` directory is completely empty. No automated tests exist.

**Add tests for:**
- `isHeic()` — valid HEIC magic bytes, invalid data, too-short data, JPEG/PNG data
- `ImageFormat` enum values
- Quality clamping / validation
- `HeicImageInfo` construction
- `HeicConversionTask` defaults
- Exception types and messages
- Mock-based platform interface tests (verify correct delegation)

### 4.2 Integration Tests
- Test actual HEIC → JPG/PNG conversion with small sample HEIC files
- Test batch conversion
- Test maxWidth / maxHeight resizing
- Test quality parameter effect on file size (JPG q=10 should be smaller than q=100)
- Include sample HEIC test fixtures in `test/fixtures/`

### 4.3 CI/CD Pipeline
- Add GitHub Actions workflow for:
  - `flutter analyze` (lint)
  - `flutter test` (unit tests)
  - `dart format --set-exit-if-changed .` (formatting)
  - `pana` score check (pub.dev quality)
  - Automated publishing to pub.dev on tag/release

---

## 5. Documentation & Package Quality

### 5.1 Dartdoc Comments
- Add `///` documentation to all public classes, methods, and parameters
- Include code examples in doc comments using `/// ```dart` blocks
- This improves pub.dev score and IDE developer experience

### 5.2 Update README
- Add badges (pub.dev version, build status, coverage)
- Add a feature comparison table
- Document new features (WebP, batch, file API, isHeic, getImageInfo)
- Add platform support matrix
- Add migration guide from 0.0.x to 0.1.0

### 5.3 Update CHANGELOG
- Document all changes following Keep a Changelog format

### 5.4 Improve pub.dev Score
- Add `topics:` to pubspec.yaml (e.g., `image`, `heic`, `converter`, `heif`)
- Add `screenshots:` or `funding:` if applicable
- Ensure all public APIs have dartdoc
- Ensure example/ is clean and demonstrates all features

---

## 6. Implementation Order

| Phase | Tasks | Breaking? |
|-------|-------|-----------|
| **Phase 1 — Bug Fixes** | 1.1 (temp file names), 1.2 (remove logs), 1.3 (cleanup on error), 1.4 (quality validation), 3.3 (singleton) | No |
| **Phase 2 — Core Features** | 2.1 (WebP), 2.2 (maxHeight), 2.6 (isHeic validation) | No |
| **Phase 3 — Performance** | 2.3 (isolate-based conversion) | No |
| **Phase 4 — Exceptions** | 3.1 (custom exceptions), 3.2 (exports) | **Yes** (error types change) |
| **Phase 5 — Extended Features** | 2.4 (batch), 2.5 (file-path API), 2.7 (image info) | No |
| **Phase 6 — Platform & Tests** | 2.8 (desktop platforms), 4.1-4.3 (tests, CI/CD) | No |
| **Phase 7 — Docs & Polish** | 5.1-5.4 (dartdoc, README, CHANGELOG, pub score) | No |

---

## 7. Summary of New Public API Surface

```dart
// New enum value
enum ImageFormat { jpg, png, webp }

// New methods on HeicConverter
static bool isHeic(Uint8List data);
static Future<HeicImageInfo> getImageInfo(Uint8List heicData);
static Future<Uint8List> convertToWebP({...});
static Future<List<Uint8List>> convertBatch({...});
static Future<String> convertFile({...});  // mobile only

// New parameter on all conversion methods
int? maxHeight;

// New classes
class HeicImageInfo { final int width; final int height; }
class HeicConversionTask { ... }
class HeicConversionException implements Exception { ... }
class InvalidHeicDataException extends HeicConversionException { ... }
class ConversionFailedException extends HeicConversionException { ... }
class PlatformNotSupportedException extends HeicConversionException { ... }
```

---

## 8. Dependencies Impact

| Change | Dependency Impact |
|--------|-------------------|
| WebP support | None — `image` package already supports WebP; browsers support `image/webp` |
| Isolate conversion | None — `dart:isolate` is in the SDK |
| isHeic validation | None — pure Dart byte checking |
| Desktop platforms | None — existing fallback already works |
| Custom exceptions | None |
| Batch conversion | None |
| File-path API | None — already uses `dart:io` and `path_provider` |

**No new dependencies required for any proposed feature.**
