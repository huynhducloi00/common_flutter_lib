import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

class PdfUtils {
  static String REPORT_TITLE = 'CÔNG TY TNHH MTV HUỲNH HIỆP HƯNG';
  static String REPORT_SUBTITLE = 'XUÂN ĐỊNH- XUÂN LỘC-ĐỒNG NAI';
  static pw.TextStyle lightTextStyle;
  static pw.TextStyle regularTextStyle;

  static Future init() async {
    lightTextStyle = pw.TextStyle(
        font: pw.Font.ttf(await rootBundle.load('assets/Roboto-Light.ttf')));
    regularTextStyle = pw.TextStyle(
        font: pw.Font.ttf(await rootBundle.load('assets/Roboto-Regular.ttf')));
  }

  static pw.Text writeLight(String text,
      {double fontSize = 12, int maxLine = 2}) {
    return pw.Text(text,
        maxLines: maxLine, style: lightTextStyle.copyWith(fontSize: fontSize));
  }

  static pw.Text writeRegular(String text, {double fontSize = 12}) {
    return pw.Text(text, style: regularTextStyle.copyWith(fontSize: fontSize));
  }

  static pw.Widget center(pw.Widget widget) {
    return pw.Center(child: widget);
  }

  static pw.Widget colon() => pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 10), child: pw.Text(":"));

  static pw.Widget tableOfTwo(Map<String, String> map,
      {bool boldLeft = false, bool boldRight = false, double width=200}) {
    List<pw.TableRow> list = [];
    for (int i = 0; i < map.entries.length; i++) {
      var e = map.entries.elementAt(i);
      list.add(pw.TableRow(children: [writeLight(e.key), pw.Container(
          alignment: pw.Alignment.centerRight,
          child:writeLight(e.value))]));
    }
    return pw.Table(
        columnWidths: {1: pw.FixedColumnWidth(width)},
        children: list);
  }
}