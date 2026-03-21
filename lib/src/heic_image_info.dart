/// Metadata about a HEIC image extracted without full conversion.
class HeicImageInfo {
  final int width;
  final int height;

  const HeicImageInfo({required this.width, required this.height});

  @override
  String toString() => 'HeicImageInfo(width: $width, height: $height)';
}
