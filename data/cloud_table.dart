import 'dart:core';

import 'package:canxe/common/widget/edit_table/parent_param.dart';

import '../data/cloud_obj.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef UseDataCalculation = dynamic Function(List<dynamic> data);

class CalculateFunction {
  List<String> fieldNames;
  UseDataCalculation useDataCalculation;

  CalculateFunction(this.fieldNames, this.useDataCalculation);
}

class InputInfo {
  String field;
  String fieldDes;

  // relative to 1.0
  double flex;
  Function validator;
  bool canUpdate;
  DataType dataType;
  CalculateFunction calculate;

  // option to option description
  Map<dynamic, String> optionMap;
  bool limitToOptions;

  // good for 6 figures
  static const SMALL_INT_COLUMN = 0.4;
  static const BIG_INT_COLUMN = 0.6;
  static const String CANT_BE_NULL = "Không thể bỏ trống";

  InputInfo(this.dataType,
      {this.validator,
      this.fieldDes,
      this.calculate,
      this.canUpdate = true,
      this.flex,
      this.optionMap,
      this.limitToOptions = false}) {
    if (flex == null) {
      if (dataType == DataType.int)
        flex = SMALL_INT_COLUMN;
      else
        flex = 1.0;
    }
  }

  static Map<dynamic, String> createSameKeyValueMap(List<dynamic> vals) {
    Map<dynamic, String> tmp = Map();
    for (var val in vals) {
      tmp[val] = val;
    }
    return tmp;
  }

  static String Function(String) nonNullValidator =
      (String value) => (value?.isEmpty ?? false) ? CANT_BE_NULL : null;
}

class PrintInfo {
  bool isDefault;
  String title;
  String buttonTitle;
  List<String> printFields;
  ParentParam parentParam;
  bool printVertical;
  Map<String, InputInfo> inputInfoMap;

  PrintInfo(Map<String, InputInfo> allInputInfoMap,
      {this.title,
      this.buttonTitle,
      this.printFields,
      this.parentParam,
      this.printVertical = false,
      this.isDefault = false}) {
    inputInfoMap = _printInputInfoMap(allInputInfoMap);
  }

  Map<String, InputInfo> _printInputInfoMap(
      Map<String, InputInfo> allInputInfoMap) {
    Map<String, InputInfo> tmp = Map();
    printFields.forEach((fieldName) {
      tmp[fieldName] = allInputInfoMap[fieldName];
    });
    return tmp;
  }
}

abstract class CloudTableSchema<T extends CloudObject> {
  String tableName;
  String tableDescription;
  Map<String, InputInfo> inputInfoMap;
  List<PrintInfo> printInfos;

  CloudTableSchema(
      {this.tableName,
      this.tableDescription,
      this.printInfos,
      this.inputInfoMap}) {
    if (printInfos == null) {
      printInfos = [
        PrintInfo(inputInfoMap,
            title: tableDescription ?? tableName,
            buttonTitle: 'In mặc định',
            isDefault: true,
            printFields: inputInfoMap.keys.toList(),
            parentParam: null)
      ];
    }
  }

  SchemaAndData<T> convertSnapshotToDataList(List<DocumentSnapshot> event);
}

class SchemaAndData<T extends CloudObject> {
  CloudTableSchema<T> cloudTableSchema;
  List<T> data;

  SchemaAndData(this.cloudTableSchema, this.data) {
    fillInCalculatedData(data, cloudTableSchema.inputInfoMap);
  }

  static void fillInCalculatedData(data, inputInfoMap) {
    data.forEach((row) {
      inputInfoMap.forEach((fieldName, inputInfo) {
        if (inputInfo.calculate != null) {
          var list = inputInfo.calculate.fieldNames
              .map((fieldName) => row.dataMap[fieldName])
              .toList();
          row.dataMap[fieldName] = inputInfo.calculate.useDataCalculation(list);
        }
      });
    });
  }
}
