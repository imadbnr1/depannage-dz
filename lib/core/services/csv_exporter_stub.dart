import 'package:flutter/services.dart';

Future<void> exportCsvFile({
  required String fileName,
  required String content,
}) async {
  await Clipboard.setData(ClipboardData(text: content));
}
