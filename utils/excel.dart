import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:danhgiadn/common/data/cloud_obj.dart';
import 'package:danhgiadn/common/data/cloud_table.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

import 'auto_form.dart';

class ExcelOperation {
  CollectionReference collectionReference;

  ExcelOperation({this.collectionReference});

  File file;
  List<String> fieldNames;
  List<Map> rows;

  StreamController<String> _wholeProcess = StreamController();

  Future<String> getFile() {
    Completer<String> completer = Completer();
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.accept = '.xlsx';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files.length == 1) {
        completer.complete(null);
        file = files[0];
      } else {
        completer.complete("Không thể chọn nhiều hơn 1 file");
      }
    });
    return completer.future;
  }

  Future<void> runWholeProcess(Map map) async {
    _wholeProcess.sink.add("Đang xoá tất cả dữ liệu");
    await _deleteAllData();
    _wholeProcess.sink.add("Đã xoá xong, đang lưu dữ liệu");
    await _decodeTableAndSave(map);
    _wholeProcess.sink.add("Đã lưu xong");
    _wholeProcess.sink.close();
  }

  Stream<String> get wholeProcess => _wholeProcess.stream;

  Future<bool> _createDeleteFuture(doc) async {
    await doc.reference.delete();
    _wholeProcess.add("Đã xoá ${doc.data['cusId']}");
  }

  Future<bool> _deleteAllData() async {
    QuerySnapshot result = await collectionReference.getDocuments();
    List<Future> list = result.documents.map((doc) {
      return _createDeleteFuture(doc);
    }).toList();
    _wholeProcess.sink.add("Tạo danh mục xoá thành công");
    await Future.wait(list);
  }

  Future<void> _createAddFuture(row) async {
    await collectionReference.document().setData(row);
    _wholeProcess.sink.add("Thêm ${row}");
  }

  Future<bool> _decodeTableAndSave(Map<String, String> map) async {
    await decodeTable(map, null);
    List<Future> listFutures =
        rows.map((row) => _createAddFuture(row)).toList();
    _wholeProcess.sink.add("Tạo danh mục thêm thành công");
    await Future.wait(listFutures);
  }

  Future<Map<String, String>> getMatchingColumns(
    context,
    List<DeciderField> deciderFields,
    List<String> inFileNames,
  ) {
    Completer<Map<String, String>> completer = Completer();
    Map<String, InputInfo> inputInfoMap = Map();
    deciderFields.forEach((value) {
      inputInfoMap[value.fieldName] = InputInfo(DataType.string,
          fieldDes: value.fieldDes, options: inFileNames, validator: (inFile) {
        return InputInfo.nonNullValidator(inFile) ??
            (inFileNames.contains(inFile)
                ? null
                : "Cột này không có trong file");
      });
    });
    Map<String, String> initValue = Map();
    deciderFields.forEach((element) {
      initValue[element.fieldName] = element.inFileDes;
    });
    AlertDialog alert = AlertDialog(
      content: AutoForm.createAutoForm(context, inputInfoMap, initValue,
          saveClickFuture: (resultMap) {
        if (resultMap.values.length != resultMap.values.toSet().length) {
          // list contains duplicate
          completer.complete(null);
        } else
          completer.complete(
              resultMap.map((key, value) => MapEntry(key, value as String)));
        return null;
      }, onPop: () {
        completer.complete(null);
      }),
    );
    showDialog(
        context: context,
        builder: (_) {
          return alert;
        });
    return completer.future;
  }

  // key is fullname (Ngay thang), value is shortname (date)
  Future<String> decodeTable(context, List<DeciderField> decodeFieldNames) {
    Completer<String> completer = Completer();
    var reader = FileReader();
    reader.onLoadEnd.listen((event) async {
      final decoder = Excel.decodeBytes(reader.result);
      final tabName = decoder.tables.keys.toList()[0];
      var table = decoder.tables[tabName];
      Map<String, String> mapping = await getMatchingColumns(context,
          decodeFieldNames, table.rows[0].map((e) => e as String).toList());
      if (mapping == null) {
        completer.complete("Không có đủ dữ liệu");
        return;
      }
      // map from in file to fieldName
      mapping = mapping.map((key, value) => MapEntry(value, key));
      List<String> columnIndexMap = List(table.rows[0].length);
      table.rows[0].asMap().entries.forEach((pair) {
        columnIndexMap[pair.key] = mapping[pair.value];
      });
      // at this step, we know that table contains all required fields.
      fieldNames = columnIndexMap;
      List<List> rowList=table.rows;
      rowList.removeAt(0);
      rows = List(rowList.length);
      rowList.asMap().entries.forEach((pair) {
        var row = pair.value;
        Map<String, dynamic> map = Map();
        row.asMap().entries.forEach((pair) {
          int colIndex = pair.key;
          var fieldName = columnIndexMap[colIndex];
          if (fieldName != null) {
            map[fieldName] = pair.value?.toString();
          }
        });
        rows[pair.key] = map;
      });
      completer.complete(null);
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }

  static void write(Sheet sheetObject, int col, int row, dynamic val) {
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = val;
  }

  static void writeData(
      List<String> listFields,
      Map<String, DeciderField> deciderFieldMap,
      Sheet sheetObject,
      List<Map> data) {
    listFields.asMap().entries.forEach((col) {
      write(sheetObject, col.key, 0, deciderFieldMap[col.value].fieldDes);
    });
    data.asMap().entries.forEach((entry) {
      var rowIndex = entry.key + 1;
      var row = entry.value;
      listFields.asMap().entries.forEach((fieldEntry) {
        var colIndex = fieldEntry.key;
        write(sheetObject, colIndex, rowIndex, row[fieldEntry.value]);
      });
    });
  }
  static Future downloadWeb(Excel excel, fileName) async {
    Completer<String> completer = Completer();
    excel.encode().then((bytes) {
      var downloadName = '$fileName.xlsx';
      // Encode our file in base64
      final _base64 = base64Encode(bytes);
      // Create the link with the file
      final anchor = AnchorElement(
          href: 'data:application/octet-stream;base64,$_base64')
        ..target = 'blank';
      // add the name
      if (downloadName != null) {
        anchor.download = downloadName;
      }
      // trigger download
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      completer.complete(null);
    });
    await completer.future;
  }
}

class DeciderField {
  String fieldName;
  String fieldDes;
  String inFileDes;

  DeciderField(this.fieldName, {this.fieldDes, this.inFileDes}) {
    if (inFileDes == null) {
      inFileDes = fieldDes;
    }
  }
}
