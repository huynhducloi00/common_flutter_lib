import 'package:canxe/common/data/cloud_obj.dart';
import 'package:canxe/common/data/cloud_table.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

import '../utils.dart';

class ExcelCreator {
  static Excel createFile(
    BuildContext context,
    PrintInfo printInfo,
    List<CloudObject> data,
  ) {
    var excel = Excel.createExcel();
    String sheetName = "Sheet1";

    Sheet sheetObject = excel[sheetName];

    // CellStyle cellStyleBold =
    //     CellStyle(fontFamily: getFontFamily(FontFamily.Calibri), bold: true);

    sheetObject.merge(
        CellIndex.indexByString("A1"), CellIndex.indexByString("E1"),
        customValue: "CÔNG TY TNHH MTV HUỲNH HIỆP HƯNG");

    sheetObject.merge(
        CellIndex.indexByString("A2"), CellIndex.indexByString("E2"),
        customValue: "XUÂN ĐỊNH- XUÂN LỘC-ĐỒNG NAI");

    sheetObject.merge(
        CellIndex.indexByString("A3"), CellIndex.indexByString("E3"),
        customValue: printInfo.title);

    sheetObject.merge(
        CellIndex.indexByString("A4"), CellIndex.indexByString("E4"),
        customValue: "Ngày in: ${formatDatetime(context, DateTime.now())}");

    // parse titleId to title description
    List<String> titleDescription = printInfo.printFields!
        .map((titleId) => printInfo.inputInfoMap.map![titleId]!.fieldDes)
        .toList();
    sheetObject.insertRowIterables(titleDescription, 7);

    int indexRowData = 8;

    // mapping key to value (V -> Vo, B -> Ba)
    data.forEach((row) {
      row.dataMap = SchemaAndData.fillInOptionData(
          row.dataMap, printInfo.inputInfoMap.map);
    });

    // parse data to list<row>
    data.forEach((element) {
      List<dynamic> row = printInfo.printFields!.map((key) {
        if (key == 'dateIn') return formatDate(context, element.dataMap['dateIn']);
        if (key == 'timeIn') return formatTime(context, element.dataMap['dateIn']);
        return toText(context, element.dataMap[key]);
      }).toList();
      sheetObject.insertRowIterables(row, indexRowData);
      indexRowData += 1;
    });
    return excel;
  }
}