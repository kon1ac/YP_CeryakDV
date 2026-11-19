import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadTextFile(String content, String filename, {String mime = 'text/csv'}) {
  final bytes = utf8.encode(content);
  final data = bytes.buffer.toJS;
  final blob = web.Blob(
    [data].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
