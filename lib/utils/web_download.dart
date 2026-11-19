import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart' as impl;

void downloadTextFile(String content, String filename, {String mime = 'text/csv'}) {
  impl.downloadTextFile(content, filename, mime: mime);
}
