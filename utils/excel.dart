import 'dart:async';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ExcelOperation {
  CollectionReference collectionReference;

  ExcelOperation({this.collectionReference});

  File file;
  StreamController<String> _wholeProcess = StreamController();

  Future<bool> getFile() {
    Completer<bool> completer = Completer();
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files.length == 1) {
        completer.complete(true);
        file = files[0];
      } else {
        completer.complete(false);
      }
    });
    return completer.future;
  }

  Future<void> runWholeProcess() async {
    _wholeProcess.sink.add("Đang xoá tất cả dữ liệu");
    await _deleteAllData();
    _wholeProcess.sink.add("Đã xoá xong, đang lưu dữ liệu");
    await _decodeTableAndSave();
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
    List<Future> list=result.documents.map((doc){return _createDeleteFuture(doc);}
    ).toList();
    _wholeProcess.sink.add("Tạo danh mục xoá thành công");
    await Future.wait(list);
  }

  Future<void> _createAddFuture(columnIndexMap, row) async {
      Map<String, dynamic> data = Map();
      row.asMap().entries.forEach((pair) {
        data['${columnIndexMap[pair.key]}'] = pair.value;
      });
      await collectionReference.document().setData(data);
      _wholeProcess.sink.add("Thêm ${row}");
  }

  Future<bool> _decodeTableAndSave() {
    Completer<bool> completer = Completer();
    var reader = FileReader();
    reader.onLoadEnd.listen((event) async {
      final decoder = SpreadsheetDecoder.decodeBytes(reader.result);
      final tabName = decoder.tables.keys.toList()[0];
      var table = decoder.tables[tabName];
      List<String> columnIndexMap = List(table.rows[0].length);
      table.rows[0].asMap().entries.forEach((pair) {
        columnIndexMap[pair.key] = pair.value;
      });
      table.rows.removeAt(0);
      List<Future> listFutures =
      table.rows.map((row) => _createAddFuture(columnIndexMap, row)).toList();
      _wholeProcess.sink.add("Tạo danh mục thêm thành công");
      await Future.wait(listFutures);
      completer.complete(true);
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }
}
