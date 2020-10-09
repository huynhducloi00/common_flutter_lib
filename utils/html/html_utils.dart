import 'dart:convert';
import 'dart:html';
import 'package:canxe/common/utils/html/html_interface.dart';
import 'package:platform_detect/platform_detect.dart';

class HtmlUtils extends HtmlUtilsInterface {
  @override
  Future downloadWeb(List<int> byteList, String downloadName) {
    // Encode our file in base64
    final _base64 = base64Encode(byteList);
    // Create the link with the file
    final anchor =
    AnchorElement(href: 'data:application/octet-stream;base64,$_base64')
      ..target = 'blank';
    // add the name
    if (downloadName != null) {
      anchor.download = downloadName;
    }
    // trigger download
    document.body.append(anchor);
    anchor.click();
    anchor.remove();
  }

  // Only works on Android web, not iOS
  @override
  void viewBytes(List<int> bytes) {
    final blob = Blob([bytes], 'application/pdf');
    final url = Url.createObjectUrlFromBlob(blob);
    window.open(url, "_blank");
    Url.revokeObjectUrl(url);
  }
  @override
  bool isSafari() {
    return browser.isSafari;
  }
}
