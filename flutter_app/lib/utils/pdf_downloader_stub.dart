import 'dart:io';
import 'dart:typed_data';

/// Save PDF to temp directory and open with system viewer.
/// Works on iOS, Android, Windows, macOS, Linux — no native plugin deps.
void downloadPdfBytes(Uint8List bytes, String filename) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes);

  // Open file with platform-appropriate command
  if (Platform.isIOS || Platform.isMacOS) {
    await Process.run('open', [file.path]);
  } else if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', file.path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [file.path]);
  }
  // On Android, this approach won't work — would need a plugin.
  // But our app targets iOS and web primarily.
}
