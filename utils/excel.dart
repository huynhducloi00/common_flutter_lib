import 'dart:async';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

import '../data/cloud_obj.dart';
import '../data/cloud_table.dart';
import '../utils.dart';
import 'auto_form.dart';
import 'html/html_utils.dart';

class ExcelOperation {
  CollectionReference? collectionReference;

  ExcelOperation({this.collectionReference});

  late File file;
  List<String?>? fieldNames;
  late List<Map?> rows;

  StreamController<String> _wholeProcess = StreamController();

  Future<String> getFile() {
    Completer<String> completer = Completer();
    InputElement uploadInput = FileUploadInputElement() as InputElement;
    uploadInput.accept = '.xlsx';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files!;
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
    await _decodeTableAndSave(map as Map<String, String>);
    _wholeProcess.sink.add("Đã lưu xong");
    _wholeProcess.sink.close();
  }

  Stream<String> get wholeProcess => _wholeProcess.stream;

  Future<bool> _createDeleteFuture(doc) async {
    var tmp = await doc.reference.delete();
    _wholeProcess.add("Đã xoá ${doc.data['cusId']}");
    return tmp;
  }

  Future<bool> _deleteAllData() async {
    QuerySnapshot result = await collectionReference!.get();
    List<Future<bool>> list = result.docs.map((doc) {
      return _createDeleteFuture(doc);
    }).toList();
    _wholeProcess.sink.add("Tạo danh mục xoá thành công");
    var allResults =await Future.wait(list);
    return allResults.contains(false);
  }

  Future<void> _createAddFuture(row) async {
    await collectionReference!.doc().set(row);
    _wholeProcess.sink.add("Thêm $row");
  }

  Future<bool> _decodeTableAndSave(Map<String, String> map) async {
    await decodeTable(map, null);
    List<Future> listFutures =
        rows.map((row) => _createAddFuture(row)).toList();
    _wholeProcess.sink.add("Tạo danh mục thêm thành công");
    await Future.wait(listFutures);
    return true;
  }

  Future<Map<String, String>> getMatchingColumns(
    context,
    List<DeciderField> deciderFields,
    List<String?> inFileNames,
  ) {
    Completer<Map<String, String>> completer = Completer();
    Map<String, InputInfo> inputInfoMap = Map();
    deciderFields.forEach((value) {
      inputInfoMap[value.fieldName] = InputInfo(DataType.string,
          fieldDes: value.fieldDes,
          optionMap: InputInfo.createSameKeyValueMap(inFileNames),
          validator: (inFile) {
        return InputInfo.nonEmptyStrValidator(inFile) ??
            (inFileNames.contains(inFile)
                ? null
                : "Cột này không có trong file");
      });
    });
    Map<String, String?> initValue = Map();
    deciderFields.forEach((element) {
      initValue[element.fieldName] = element.inFileDes;
    });
    showAlertDialog(context, percentageWidth: 0.6, builder: (_) {
      return AutoForm.createAutoForm(
          context, InputInfoMap(inputInfoMap), initValue,
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
      });
    });
    return completer.future;
  }

  // key is fullname (Ngay thang), value is shortname (date)
  Future<String> decodeTable(context, List<DeciderField>? decodeFieldNames) {
    Completer<String> completer = Completer();
    var reader = FileReader();
    reader.onLoadEnd.listen((event) async {
      final decoder = Excel.decodeBytes(reader.result as List<int>);
      final tabName = decoder.tables.keys.toList()[0];
      var table = decoder.tables[tabName]!;
      Map<String, String> mapping = await getMatchingColumns(context,
          decodeFieldNames!, table.rows[0].map((e) => e as String?).toList());
      if (mapping == null) {
        completer.complete("Không có đủ dữ liệu");
        return;
      }
      // map from in file to fieldName
      mapping = mapping.map((key, value) => MapEntry(value, key));
      List<String?> columnIndexMap =List.filled(table.rows[0].length, null);
      table.rows[0].asMap().entries.forEach((pair) {
        columnIndexMap[pair.key] = mapping[pair.value as String];
      });
      // at this step, we know that table contains all required fields.
      fieldNames = columnIndexMap;
      List<List> rowList = table.rows;
      rowList.removeAt(0);
      rows = List.filled(rowList.length, null);
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
      write(sheetObject, col.key, 0, deciderFieldMap[col.value]!.fieldDes);
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

  static void downloadWeb(Excel excel, fileName) async {
    var bytes = excel.encode()!;
    (HtmlUtils()).downloadWeb(bytes, '$fileName.xlsx');
  }
}

class DeciderField {
  String fieldName;
  String fieldDes;
  String? inFileDes;

  DeciderField(this.fieldName, {required this.fieldDes, this.inFileDes}) {
    if (inFileDes == null) {
      inFileDes = fieldDes;
    }
  }
}
