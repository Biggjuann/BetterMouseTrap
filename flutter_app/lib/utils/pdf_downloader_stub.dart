import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Save PDF and open/share it using platform-appropriate method.
void downloadPdfBytes(Uint8List bytes, String filename) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes);

  if (Platform.isIOS) {
    // Use native share sheet via method channel
    const channel = MethodChannel('com.mousetrap.app/share');
    await channel.invokeMethod('shareFile', {'path': file.path});
  } else if (Platform.isMacOS) {
    await Process.run('open', [file.path]);
  } else if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', file.path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [file.path]);
  }
}
