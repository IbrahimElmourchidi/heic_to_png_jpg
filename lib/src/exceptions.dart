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
