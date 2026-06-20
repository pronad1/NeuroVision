import 'dart:io';

void downloadFileImpl(String filename, String content) async {
  try {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        final file = File('${dir.path}/$filename');
        await file.writeAsString(content);
        return;
      }
    }
  } catch (e) {
    // Ignore errors
  }
}

