// Stub that delegates to platform-specific implementation via conditional import.
// ignore: uri_does_not_exist
export 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart';
