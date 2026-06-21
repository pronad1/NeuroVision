import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

void downloadFileImpl(String filename, String content) async {
  try {
    if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
      Uint8List data = Uint8List.fromList(content.codeUnits);
      
      String name = filename;
      String ext = 'txt';
      if (filename.contains('.')) {
        var parts = filename.split('.');
        ext = parts.last;
        name = parts.sublist(0, parts.length - 1).join('.');
      }
      
      await FileSaver.instance.saveAs(
        name: name,
        fileExtension: ext,
        bytes: data,
        mimeType: MimeType.text,
      );
    }
  } catch (e) {
    // Ignore errors
  }
}
