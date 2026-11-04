import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadBackup(String contents, String name) {
  final blob = web.Blob([contents.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(seconds: 5), () => web.URL.revokeObjectURL(url));
}
