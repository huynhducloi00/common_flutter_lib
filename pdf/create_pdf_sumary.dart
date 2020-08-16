import 'dart:html';

import 'package:canxe/common/data/cloud_obj.dart';
import 'package:canxe/common/data/cloud_table.dart';
import 'package:canxe/common/utils.dart';
import 'package:canxe/common/pdf/pdf_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

class PdfSummary {
  static final COLUMN_GAP = pw.SizedBox(height: 15);

  static Future<void> createPdfSummary(BuildContext buildContext, String title,
      DateTime timeOfPrint, SchemaAndData schemaAndData) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final Document pdf = pw.Document();
      Map<int, pw.TableColumnWidth> colWidths = Map();
      double sumFraction = 0;

      Map<String, InputInfo> usedInputInfoMap =
          schemaAndData.cloudTableSchema.printInputInfoMap;
      usedInputInfoMap.entries.forEach((e) {
        InputInfo inputInfo = e.value;
        sumFraction += inputInfo.flex;
      });
      usedInputInfoMap.entries.toList().asMap().forEach((key, value) {
        colWidths[key] = pw.FractionColumnWidth(value.value.flex / sumFraction);
      });
      int count = 0;
      // for landscape
      final int LIMIT = 32;
      pw.Table header = pw.Table(columnWidths: colWidths, children: [
        pw.TableRow(
            children: usedInputInfoMap.entries
                .map((e) => PdfUtils.writeRegular(e.value.fieldDes))
                .toList())
      ]);
      List<pw.TableRow> tableRows = List();
      List<pw.Table> tables = List();
      Map<String, int> aggregationStatInt = Map();
      schemaAndData.data.forEach((row) {
        count++;
        tableRows.add(pw.TableRow(
            children: usedInputInfoMap.keys.map((fieldName) {
          if (usedInputInfoMap[fieldName].dataType == DataType.int) {
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
        if (count == LIMIT) {
          tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
          count = 0;
          tableRows = List();
        }
      });
      if (tableRows.length!=0){
        tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
      }
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(15),
          orientation: pw.PageOrientation.landscape,
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
                PdfUtils.writeRegular(title),
              ),
              PdfUtils.center(PdfUtils.writeRegular(
                  'Ngày in: ${formatDatetime(buildContext, timeOfPrint)}')),
              COLUMN_GAP,
              header,
            ]);
            if (tables.length == 0) {
              return children;
            }
            children.addAll([tables[0], pw.NewPage()]);
            for (int i = 1; i < tables.length - 1; i++) {
              children.addAll([header, tables[i], pw.NewPage()]);
            }
            if (tables.length > 1) {
              children.addAll([header, tables.last]);
            }
            int LAST_PAGE_COLUMN_NUM = 3;
            List<Map<String, String>> maps = partitionMap(
                aggregationStatInt.map((fieldName, value) => MapEntry(
                    schemaAndData
                        .cloudTableSchema.inputInfoMap[fieldName].fieldDes,
                    toText(buildContext, value))),
                LAST_PAGE_COLUMN_NUM);
            List<pw.Widget> mapWidgets = maps
                .map((map) => PdfUtils.tableOfTwo(map, width: 100))
                .toList();
            children.add(pw.Container(
                decoration:
                    pw.BoxDecoration(border: pw.BoxBorder(bottom: true))));
            // add summary for last page
            children.add(pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                mainAxisSize: pw.MainAxisSize.max,
                children: mapWidgets));
            return children;
          }));

      return pdf.save();
    });
  }
}
