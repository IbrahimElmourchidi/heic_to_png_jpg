import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';

void main() {
  group('ImageFormat', () {
    test('has jpg, png, and webp values', () {
      expect(ImageFormat.values, containsAll([ImageFormat.jpg, ImageFormat.png, ImageFormat.webp]));
    });

    test('name returns correct string', () {
      expect(ImageFormat.jpg.name, 'jpg');
      expect(ImageFormat.png.name, 'png');
      expect(ImageFormat.webp.name, 'webp');
    });
  });

  group('HeicImageInfo', () {
    test('stores width and height', () {
      const info = HeicImageInfo(width: 1920, height: 1080);
      expect(info.width, 1920);
      expect(info.height, 1080);
    });

    test('toString includes dimensions', () {
      const info = HeicImageInfo(width: 100, height: 200);
      expect(info.toString(), contains('100'));
      expect(info.toString(), contains('200'));
    });
  });

  group('HeicConversionTask', () {
    test('defaults are correct', () {
      final task = HeicConversionTask(heicData: Uint8List(0));
      expect(task.format, ImageFormat.jpg);
      expect(task.quality, 100);
      expect(task.maxWidth, isNull);
      expect(task.maxHeight, isNull);
    });

    test('accepts custom values', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final task = HeicConversionTask(
        heicData: data,
        format: ImageFormat.png,
        quality: 80,
        maxWidth: 800,
        maxHeight: 600,
      );
      expect(task.heicData, data);
      expect(task.format, ImageFormat.png);
      expect(task.quality, 80);
      expect(task.maxWidth, 800);
      expect(task.maxHeight, 600);
    });
  });

  group('HeicConversionException', () {
    test('base exception message', () {
      const e = HeicConversionException('test error');
      expect(e.message, 'test error');
      expect(e.toString(), contains('test error'));
    });

    test('InvalidHeicDataException default message', () {
      const e = InvalidHeicDataException();
      expect(e.message, 'Invalid HEIC data');
    });

    test('ConversionFailedException stores cause', () {
      final cause = Exception('root cause');
      final e = ConversionFailedException('failed', cause: cause);
      expect(e.message, 'failed');
      expect(e.cause, cause);
    });

    test('PlatformNotSupportedException', () {
      const e = PlatformNotSupportedException('not supported');
      expect(e.message, 'not supported');
    });

    test('exception hierarchy: subclasses are HeicConversionException', () {
      expect(const InvalidHeicDataException(), isA<HeicConversionException>());
      expect(const ConversionFailedException('x'), isA<HeicConversionException>());
      expect(const PlatformNotSupportedException('x'), isA<HeicConversionException>());
    });
  });

  group('HeicConverter.isHeic', () {
    Uint8List makeHeicBytes(String brand) {
      final bytes = Uint8List(12);
      // box size (4 bytes, ignored by isHeic)
      bytes[0] = 0; bytes[1] = 0; bytes[2] = 0; bytes[3] = 24;
      // 'ftyp' at offset 4
      final ftyp = 'ftyp'.codeUnits;
      bytes.setRange(4, 8, ftyp);
      // brand at offset 8
      final brandBytes = brand.codeUnits;
      bytes.setRange(8, 12, brandBytes);
      return bytes;
    }

    test('returns true for heic brand', () {
      expect(HeicConverter.isHeic(makeHeicBytes('heic')), isTrue);
    });

    test('returns true for heix brand', () {
      expect(HeicConverter.isHeic(makeHeicBytes('heix')), isTrue);
    });

    test('returns true for mif1 brand', () {
      expect(HeicConverter.isHeic(makeHeicBytes('mif1')), isTrue);
    });

    test('returns true for msf1 brand', () {
      expect(HeicConverter.isHeic(makeHeicBytes('msf1')), isTrue);
    });

    test('returns true for hevx brand', () {
      expect(HeicConverter.isHeic(makeHeicBytes('hevx')), isTrue);
    });

    test('returns false for JPEG magic bytes', () {
      // JPEG starts with FF D8 FF
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0]);
      expect(HeicConverter.isHeic(jpeg), isFalse);
    });

    test('returns false for PNG magic bytes', () {
      // PNG starts with 89 50 4E 47
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0]);
      expect(HeicConverter.isHeic(png), isFalse);
    });

    test('returns false for data shorter than 12 bytes', () {
      expect(HeicConverter.isHeic(Uint8List(11)), isFalse);
      expect(HeicConverter.isHeic(Uint8List(0)), isFalse);
    });

    test('returns false for unknown brand', () {
      expect(HeicConverter.isHeic(makeHeicBytes('jpeg')), isFalse);
    });
  });
}
