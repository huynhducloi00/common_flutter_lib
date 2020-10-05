import 'dart:convert';
import 'dart:html';

class HtmlUtils {
  static void downloadWeb(List<int> byteList, String downloadName) async {
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
}
