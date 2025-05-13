# Changelog

## 0.0.2
- Fixed "No implementation found for this platform" error by removing default `HeicToImageImplementation` and ensuring explicit platform instantiation.

## 0.0.1
- Initial release of `heic_to_png_jpg`.
- Supports HEIC to PNG and JPG conversion on web (via libheif-js) and mobile (via heif_converter).
- Includes platform interface for extensibility.