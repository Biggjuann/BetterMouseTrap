import 'dart:typed_data';

/// Stub download — does nothing on unsupported platforms.
/// On Windows desktop, saving files would require path_provider + file picker.
/// For now, PDF download is supported on web only.
void downloadPdfBytes(Uint8List bytes, String filename) {
  // No-op on non-web platforms. Could show a snackbar via callback if needed.
}
