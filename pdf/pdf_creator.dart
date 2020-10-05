import 'package:canxe/common/html_utils.dart';
import 'package:flutter/foundation.dart';

import 'pdf_interface.dart';

import '../data/cloud_table.dart';
import 'pdf_utils.dart';
import 'package:flutter/material.dart';
import '../data/cloud_obj.dart';
import '../utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

class PdfCreator extends PdfCreatorInterface {
  static final _columnGap = pw.SizedBox(height: 15);
  static const HORIZONTAL_FIRST_PAGE_LIMIT = 32;
  static const HORIZONTAL_OTHER_PAGE_LIMIT = 37;
  static const VERTICAL_FIRST_PAGE_LIMIT = 50;
  static const VERTICAL_OTHER_PAGE_LIMIT = 55;

  @override
  Future init() {
    return PdfUtils.init();
  }
  List<int> _generatingPdfSummary(BuildContext buildContext, DateTime timeOfPrint,
      PrintInfo printInfo, List data){
    final Document pdf = pw.Document();
    Map<int, pw.TableColumnWidth> colWidths = Map();
    double sumFraction = 0;

    Map<String, InputInfo> usedInputInfoMap =
    printInfo.inputInfoMap.filterMap(printInfo.printFields);
    usedInputInfoMap.entries.forEach((e) {
      InputInfo inputInfo = e.value;
      sumFraction += inputInfo.flex;
    });
    usedInputInfoMap.entries.toList().asMap().forEach((key, value) {
      colWidths[key] = pw.FractionColumnWidth(value.value.flex / sumFraction);
    });
    int count = 0;
    // for landscape
    var limitFirstPage = printInfo.printVertical
        ? VERTICAL_FIRST_PAGE_LIMIT
        : HORIZONTAL_FIRST_PAGE_LIMIT;
    var limitOtherPage = printInfo.printVertical
        ? VERTICAL_OTHER_PAGE_LIMIT
        : HORIZONTAL_OTHER_PAGE_LIMIT;
    pw.Table header = pw.Table(columnWidths: colWidths, children: [
      pw.TableRow(
          children: usedInputInfoMap.entries
              .map((e) => PdfUtils.writeRegular(e.value.fieldDes))
              .toList())
    ]);
    List<pw.TableRow> tableRows = List();
    List<pw.Table> tables = List();
    Map<String, int> aggregationStatInt = Map();
    data.forEach((row) {
      count++;
      tableRows.add(pw.TableRow(
          children: usedInputInfoMap.keys.map((fieldName) {
            if (usedInputInfoMap[fieldName].dataType == DataType.int &&
                usedInputInfoMap[fieldName].optionMap == null) {
              if (aggregationStatInt.containsKey(fieldName)) {
                aggregationStatInt[fieldName] =
                    sum([aggregationStatInt[fieldName], row.dataMap[fieldName]]);
              } else {
                aggregationStatInt[fieldName] = row.dataMap[fieldName] ?? 0;
              }
            }
            return PdfUtils.writeLight(
                toText(buildContext, row.dataMap[fieldName]) ?? "",
                maxLine: 1);
          }).toList()));
      if ((tables.length == 0 && count == limitFirstPage) ||
          (tables.length > 0 && count == limitOtherPage)) {
        tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
        count = 0;
        tableRows = List();
      }
    });
    if (tableRows.length != 0) {
      tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
    }
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(15),
        orientation: printInfo.printVertical
            ? pw.PageOrientation.natural
            : pw.PageOrientation.landscape,
        footer: (pw.Context context) {
          return pw.Container(
              alignment: pw.Alignment.centerRight,
              child: PdfUtils.writeLight(
                '${context.pageNumber} / ${context.pagesCount}',
              ));
        },
        build: (pw.Context context) {
          List<pw.Widget> children = [];
          children.addAll([
            PdfUtils.writeRegular(PdfUtils.REPORT_TITLE),
            PdfUtils.writeLight(PdfUtils.REPORT_SUBTITLE),
            PdfUtils.center(
              PdfUtils.writeRegular(printInfo.title.toUpperCase()),
            ),
            PdfUtils.center(PdfUtils.writeRegular(
                'Ngày in: ${formatDatetime(buildContext, timeOfPrint)}')),
            _columnGap,
            header,
          ]);
          if (tables.length == 0) {
            return children;
          }
          int lastCount = limitFirstPage - tables[0].children.length;
          children.addAll([tables[0]]);
          for (int i = 1; i < tables.length; i++) {
            children.addAll([pw.NewPage(), header, tables[i]]);
            lastCount = limitOtherPage - tables[i].children.length;
          }

          // add summary for last page
          const LAST_PAGE_COLUMN_NUM = 3;
          if (lastCount < LAST_PAGE_COLUMN_NUM) {
            // NOT enough space for adding summary
            children.add(pw.NewPage());
          }
          List<Map<String, String>> maps = partitionMap(
              aggregationStatInt.map((fieldName, value) => MapEntry(
                  printInfo.inputInfoMap.map[fieldName].fieldDes,
                  toText(buildContext, value))),
              LAST_PAGE_COLUMN_NUM);
          List<pw.Widget> mapWidgets = maps
              .map((map) => PdfUtils.tableOfTwo(map, width: 100))
              .toList();
          children.add(pw.Container(
              decoration:
              pw.BoxDecoration(border: pw.BoxBorder(bottom: true))));
          children.add(pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              mainAxisSize: pw.MainAxisSize.max,
              children: mapWidgets));
          return children;
        }));
    return pdf.save();
  }
  @override
  Future createPdfSummary(BuildContext buildContext, DateTime timeOfPrint,
      PrintInfo printInfo, List data, bool isPhone) {
    List<int> bytes=_generatingPdfSummary(buildContext, timeOfPrint, printInfo, data);
    if (kIsWeb){
      if (isPhone){
        // Mobile web
        HtmlUtils.downloadWeb(bytes, 'report.pdf');
        return null;
      } else {
        // Chrome
        return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
          return bytes;
        });
      }
    } else {
      // android
      return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
        return bytes;
      });
    }
  }
  @override
  Future createPdfTicket(BuildContext buildContext, DateTime timeOfPrint,
      PrintTicket printTicket, Map dataMap) {
    return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final Document pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(15),
          orientation: printTicket.printVertical
              ? pw.PageOrientation.natural
              : pw.PageOrientation.landscape,
          build: (pw.Context context) {
            List<pw.Widget> children = [];
            children.addAll([
              PdfUtils.writeRegular(PdfUtils.REPORT_TITLE),
              PdfUtils.writeLight(PdfUtils.REPORT_SUBTITLE),
              PdfUtils.center(
                PdfUtils.writeRegular(printTicket.title.toUpperCase()),
              ),
              PdfUtils.center(PdfUtils.writeRegular(
                  'Ngày in: ${formatDatetime(buildContext, timeOfPrint)}')),
              _columnGap,
            ]);
            printTicket.ticketParagraphs.forEach((paragraph) {
              if (paragraph.fieldNames != null) {
                List lists = partitionListToBin(
                    paragraph.fieldNames, paragraph.numColumn);
                children.add(pw.Row(
                    mainAxisSize: pw.MainAxisSize.max,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: lists.map((list) {
                      return tableOfTwo(buildContext, list,
                          printTicket.inputInfoMap.map, dataMap);
                    }).toList()));
              } else if (paragraph.hardCodeTexts != null) {
                List<List> lists = partitionListToBin(
                    paragraph.hardCodeTexts, paragraph.numColumn);
                children.add(pw.Row(
                    mainAxisSize: pw.MainAxisSize.max,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: lists.map((list) {
                      return pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: list
                              .map((text) => PdfUtils.writeLight(text))
                              .toList());
                    }).toList()));
              } else {
                // Both are null, meaning just line breaks
                // 1 line break is 1cm
                children.add(pw.SizedBox(
                    height: paragraph.numLineBreak * DOT_PER_CM * 1.0));
              }
            });
            return children;
          }));
      return pdf.save();
    });
  }

  pw.Widget tableOfTwo(BuildContext buildContext, List<String> fieldNames,
      Map<String, InputInfo> inputInfoMap, Map dataMap) {
    return PdfUtils.tableOfTwo(
        fieldNames.asMap().map((key, fieldName) {
          return MapEntry(inputInfoMap[fieldName].fieldDes,
              toText(buildContext, dataMap[fieldName] ?? ''));
        }),
        width: null);
  }
}
