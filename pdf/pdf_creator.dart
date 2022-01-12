import 'dart:async';
import 'dart:typed_data';

import '../utils/html/html_no_op.dart'
    if (dart.library.html) '../utils/html/html_utils.dart' as html_utils;
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

class GroupByKey {
  List<dynamic> values;

  GroupByKey(this.values);

  @override
  int get hashCode => hashList(values);

  @override
  bool operator ==(other) =>
      other is GroupByKey && (listEquals(other.values, values));

  @override
  String toString() {
    return values.toString();
  }
}

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

  Future<List<int>> _generatingPdfSummary(
      BuildContext buildContext,
      DateTime timeOfPrint,
      PrintInfo printInfo,
      List<Map<String, dynamic>> data) {
    final Document pdf = pw.Document();
    Map<int, pw.TableColumnWidth> colWidths = Map();
    double sumFraction = 0;

    Map<String, InputInfo?> usedInputInfoMap = printInfo.inputInfoMap
        .filterMap((printInfo.groupByFields ?? []) + printInfo.printFields!);
    usedInputInfoMap.entries.forEach((e) {
      InputInfo inputInfo = e.value!;
      sumFraction += inputInfo.printFlex!;
    });
    usedInputInfoMap.entries.toList().asMap().forEach((key, value) {
      colWidths[key] = pw.FractionColumnWidth(value.value!.printFlex! / sumFraction);
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
              .map((e) => PdfUtils.writeRegular(e.value!.fieldDes!))
              .toList())
    ]);
    List<pw.TableRow> tableRows = [];
    List<pw.Table> tables = [];
    Map<String, int?> aggregationStatInt = {};
    if (printInfo.groupByFields != null) {
      Map<GroupByKey, Map<String, int>> grouped = {};
      data.forEach((row) {
        GroupByKey groupByKey =
            GroupByKey(printInfo.groupByFields!.map((e) => row[e]).toList());
        var map;
        if (grouped[groupByKey]==null){
          map = {};
          grouped[groupByKey] = map;
        } else {
          map = grouped[groupByKey];
        }
        printInfo.printFields!.forEach((fieldName) {
          if (!printInfo.groupByFields!.contains(fieldName)) {
            if (map[fieldName] == null) {
              map[fieldName] = row[fieldName] ?? 0;
            } else {
              map[fieldName] +=  row[fieldName] ??0;
            }
          }
        });
      });
      data.clear();
      grouped.entries.forEach((e) {
        Map<String, dynamic> newMap = Map.from(e.value);
        printInfo.groupByFields!.asMap().forEach((index, groupedField) {
          newMap[groupedField] = e.key.values[index];
        });
        data.add(newMap);
      });
    }
    data.forEach((row) {
      printInfo.aggregateFields!.forEach((fieldName) {
        if (aggregationStatInt.containsKey(fieldName)) {
          aggregationStatInt[fieldName] =
              sum([aggregationStatInt[fieldName], row[fieldName]]);
        } else {
          aggregationStatInt[fieldName] = row[fieldName] ?? 0;
        }
      });
      count++;
      tableRows.add(pw.TableRow(
          children: usedInputInfoMap.keys.map((fieldName) {
        return PdfUtils.writeLight(toText(buildContext, row[fieldName]) ?? "",
            maxLine: 1);
      }).toList()));
      if ((tables.length == 0 && count == limitFirstPage) ||
          (tables.length > 0 && count == limitOtherPage)) {
        tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
        count = 0;
        tableRows = [];
      }
    });
    if (tableRows.isNotEmpty) {
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
              PdfUtils.writeRegular(printInfo.title!.toUpperCase()),
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
          List<Map<String?, String?>?> maps = partitionMap(
              aggregationStatInt.map((fieldName, value) => MapEntry(
                  printInfo.inputInfoMap.map![fieldName]!.fieldDes,
                  toText(buildContext, value))),
              LAST_PAGE_COLUMN_NUM);
          List<pw.Widget> mapWidgets =
              maps.map((map) => PdfUtils.tableOfTwo(map!, width: 100)).toList();
          children.add(pw.Container(
              decoration:
                  const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide()))));
          children.add(pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              mainAxisSize: pw.MainAxisSize.max,
              children: mapWidgets));
          return children;
        }));
    return pdf.save();
  }

  @override
  Future createPdfSummary(BuildContext context, DateTime timeOfPrint,
      PrintInfo printInfo, List<CloudObject> data) async {
    List<int> bytes = await _generatingPdfSummary(context, timeOfPrint,
        printInfo, data.map((e) => e.dataMap).toList());
    if (kIsWeb) {
      if (html_utils.HtmlUtils().isSafari()!) {
        (html_utils.HtmlUtils()).downloadWeb(bytes, 'report.pdf');
      } else {
        (html_utils.HtmlUtils()).viewBytes(bytes);
      }
      return null;
    } else {
      // android
      return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
        return bytes as FutureOr<Uint8List>;
      });
    }
  }

  @override
  Future createPdfTicket(BuildContext buildContext, DateTime timeOfPrint,
      PrintTicket? printTicket, Map? dataMap) {
    return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final Document pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(15),
          orientation: printTicket!.printVertical
              ? pw.PageOrientation.natural
              : pw.PageOrientation.landscape,
          build: (pw.Context context) {
            List<pw.Widget> children = [];
            children.addAll([
              PdfUtils.writeRegular(PdfUtils.REPORT_TITLE),
              PdfUtils.writeLight(PdfUtils.REPORT_SUBTITLE),
              PdfUtils.center(
                PdfUtils.writeRegular(printTicket.title!.toUpperCase()),
              ),
              PdfUtils.center(PdfUtils.writeRegular(
                  'Ngày in: ${formatDatetime(buildContext, timeOfPrint)}')),
              _columnGap,
            ]);
            printTicket.ticketParagraphs.forEach((paragraph) {
              if (paragraph.fieldNames != null) {
                List lists = partitionListToBin(
                    paragraph.fieldNames!, paragraph.numColumn);
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
                    paragraph.hardCodeTexts!, paragraph.numColumn);
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
                    height: paragraph.numLineBreak! * DOT_PER_CM * 1.0));
              }
            });
            return children;
          }));
      return pdf.save();
    });
  }

  pw.Widget tableOfTwo(BuildContext buildContext, List<String> fieldNames,
      Map<String, InputInfo>? inputInfoMap, Map? dataMap) {
    return PdfUtils.tableOfTwo(
        fieldNames.asMap().map((key, fieldName) {
          return MapEntry(inputInfoMap![fieldName]!.fieldDes,
              toText(buildContext, dataMap![fieldName] ?? ''));
        }),
        width: null);
  }
}
