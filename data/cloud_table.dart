import 'dart:collection';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/cloud_obj.dart';
import '../utils.dart';
import '../widget/edit_table/parent_param.dart';

class UseDataCalculationResult {
  dynamic value;

  UseDataCalculationResult(this.value);

  @override
  String toString() {
    return '$value';
  }
}

typedef UseDataCalculationFuture = Future<UseDataCalculationResult>? Function(
    Map<String, dynamic>? data, Map<String, dynamic>? predefined);
// returns null to keep the same value as before
typedef UseDataCalculation = UseDataCalculationResult? Function(
    Map<String, dynamic>? data, Map<String, DataBundle>? predefined);
typedef InitialDataCalculation = UseDataCalculationResult Function(
    Map<String, DataBundle> predefined);

class DropdownSearchAdmin<T> {
  final MapEntry<String, T> itemSelected;
  final Map<String, T> map;

  DropdownSearchAdmin(this.itemSelected, this.map);
}

class LinkedData {
  String tableName;
  String linkedFieldName;

  LinkedData(this.tableName, this.linkedFieldName);

  static UseDataCalculation getLinkedUseDataCalculation(
      String tableName, String fieldContainsDocumentId, String getField) {
    return (row, predefined) {
      if (predefined == null) return null;
      DataBundle bundle = predefined[tableName]!;
      for (var otherTableRow in bundle.dataRows) {
        if (otherTableRow[CloudTableSchema.documentIdField] ==
            row![fieldContainsDocumentId]) {
          return UseDataCalculationResult(otherTableRow[getField]);
        }
      }
      return null;
    };
  }

  static UseDataCalculation getLinkedUseDataCalculationUsingFunction(
      String tableName,
      String fieldContainsDocumentId,
      dynamic Function(Map<String, dynamic>) getFieldFunc) {
    return (row, predefined) {
      if (predefined == null) return null;
      DataBundle bundle = predefined[tableName]!;
      for (var otherTableRow in bundle.dataRows) {
        if (otherTableRow[CloudTableSchema.documentIdField] ==
            row![fieldContainsDocumentId]) {
          return UseDataCalculationResult(
              getFieldFunc(otherTableRow as Map<String, dynamic>));
        }
      }
      return null;
    };
  }
}

class InputInfo {
  String fieldDes;

  // relative to 1.0
  double? displayFlex;
  double? printFlex;
  Function? validator;

  // Calculate only happens when initializing data, or when its contributor variables changes.
  UseDataCalculation? calculate;
  InitialDataCalculation? initializeFunc;
  UseDataCalculationFuture? fillData;
  String? Function(BuildContext, dynamic) displayConverter;
  dynamic Function()? onNewData;
  bool canUpdate;

  // needSaving can be true for some calculated variables, or for nonUpdatale variables, mainly
  // used for server database query.
  bool needSaving;

  // in sypnosis view only.
  bool isVisible;
  DataType dataType;
  List<String>? fieldsForCalculation;

  // option to option description
  Map<dynamic, String?>? optionMap;

  bool? isDropdownGetKey;
  DropdownSearchAdmin? dropdownSearchAdmin;
  List<String>? fieldsFilledByDropdownSelected;

  bool limitToOptions;
  LinkedData? linkedData;

  // 4 or less
  static const SMALL_INT_COLUMN = 0.4;

  // good for 6 figures
  static const BIG_INT_COLUMN = 0.5;

  // good for >=7 figures
  static const SUPER_BIG_INT_COLUMN = 0.7;
  static const String CANT_BE_NULL = "Không thể bỏ trống";

  InputInfo(this.dataType,
      {this.validator,
      required this.fieldDes,
      this.fieldsForCalculation,
      this.calculate,
      this.fillData,
      this.onNewData,
      this.displayConverter = toText,
      this.canUpdate = true,
      this.needSaving = true,
      this.isVisible = true,
      this.initializeFunc,
      this.displayFlex,
      this.printFlex,
      this.linkedData,
      this.optionMap,
      this.dropdownSearchAdmin,
      this.isDropdownGetKey,
      this.fieldsFilledByDropdownSelected,
      this.limitToOptions = false}) {
    if (displayFlex == null) {
      if (dataType == DataType.int) {
        displayFlex = SMALL_INT_COLUMN;
      } else {
        displayFlex = 1.0;
      }
    }
    if (printFlex == null) {
      if (dataType == DataType.int) {
        printFlex = SMALL_INT_COLUMN;
      } else {
        printFlex = displayFlex;
      }
    }
  }

  static Map<dynamic, String?> createSameKeyValueMap(List<dynamic> vals) {
    Map<dynamic, String?> tmp = Map();
    for (var val in vals) {
      tmp[val] = val;
    }
    return tmp;
  }

  static String? nonEmptyStrValidator(String? value) {
    return (value?.isEmpty ?? false) ? CANT_BE_NULL : null;
  }

  static String? nonNullValidator(dynamic value) {
    return value == null ? CANT_BE_NULL : null;
  }

  @override
  String toString() {
    return '$fieldDes-$linkedData}';
  }
}

class PrintTicket {
  String? title;
  String? subtitle;
  bool printVertical;
  List<TicketParagraph> ticketParagraphs;
  InputInfoMap inputInfoMap;

  PrintTicket(this.ticketParagraphs, this.inputInfoMap,
      {this.printVertical = true, this.title, this.subtitle});
}

class TicketParagraph {
  List<String>? fieldNames;
  List<String>? hardCodeTexts;
  int numColumn;
  int? numLineBreak;

  TicketParagraph(
      {this.fieldNames,
      this.hardCodeTexts,
      this.numColumn = 1,
      this.numLineBreak});
}

class DataBundle {
  String tableName;
  List<Map> dataRows;

  DataBundle(this.tableName, this.dataRows);

  @override
  String toString() {
    // TODO: implement toString
    return '$tableName $dataRows';
  }
}

typedef DocumentSnapshotConversion = Map Function(DocumentSnapshot);

class RelatedTableData {
  String tableName;
  Query? query;
  DocumentSnapshotConversion? documentSnapshotConversion;

  RelatedTableData(this.tableName,
      {this.query, this.documentSnapshotConversion});
}

class InputInfoMap {
  Map<String, InputInfo>? map;
  LinkedHashSet<String>? calculatingOrder;
  Map<String, List<String>>? fieldChangedFieldMap;
  List<RelatedTableData>? relatedTables;
  List<String>? fieldDropdown;

  InputInfoMap(this.map, {this.relatedTables, this.fieldDropdown}) {
    _computeCalculatingOrder();
  }

  InputInfoMap._();

  InputInfoMap cloneInputInfoMap(Map<String, InputInfo>? map) {
    var result = InputInfoMap._();
    result.map = map;
    result.calculatingOrder = calculatingOrder;
    result.fieldChangedFieldMap = fieldChangedFieldMap;
    result.relatedTables = relatedTables;
    result.fieldDropdown = fieldDropdown;
    return result;
  }

  Map<String, InputInfo> filterMap(List<String> printFields) {
    return Map.fromEntries(printFields.map((e) {
      return MapEntry(e, map![e]!);
    }).toList());
  }

  Map<String, InputInfo> filterVisibleFields() {
    return Map.fromEntries(
        map!.entries.where((element) => element.value.isVisible));
  }

  void transverse(Map<String, List<String>> edges, Set<String> visited,
      String currentNode) {
    if (edges[currentNode] != null) {
      edges[currentNode]!.forEach((element) {
        visited.add(element);
        transverse(edges, visited, element);
      });
    }
  }

  void _computeCalculatingOrder() {
    Map<String, List<String>> edges = Map();
    Map<String, List<String>> reversedEdges = Map();
    map!.forEach((fieldName, inputInfo) {
      if (inputInfo.fieldsForCalculation != null) {
        edges[fieldName] = [];
        inputInfo.fieldsForCalculation!.forEach((usedField) {
          edges[fieldName]!.add(usedField);
          if (reversedEdges[usedField] == null) {
            reversedEdges[usedField] = [];
          }
          reversedEdges[usedField]!.add(fieldName);
        });
      }
    });
    LinkedHashSet<String> order = LinkedHashSet();
    if (edges.isEmpty) {
      calculatingOrder = order;
      fieldChangedFieldMap = reversedEdges;
    }
    Set<String> variableFields = Set();
    bool stopLoop;
    while (true) {
      stopLoop = true;
      bool hasStartNodes = false;
      edges.forEach((fieldName, links) {
        if (links.isEmpty) {
          order.add(fieldName);
        } else {
          stopLoop = false;
          for (int i = links.length - 1; i >= 0; i--) {
            var end = links[i];
            variableFields.add(end);
            // There exists a node which does not have incoming edges.
            if (edges[end] == null || edges[end]!.isEmpty) {
              hasStartNodes = true;
              links.removeAt(i);
            }
          }
        }
      });
      if (!stopLoop && !hasStartNodes) {
        stopLoop = true;
        throw Exception('The calculate map has cycle. STOP NOW.');
      }
      if (stopLoop) break;
    }
    bool DEBUG = false;
    variableFields.removeWhere((element) => order.contains(element));
    if (DEBUG && order.isNotEmpty) {
      print('Su dung $variableFields');
      print('Tao ra $order');
    }
    if (DEBUG) print(reversedEdges);
    List calculatingOrderList = order.toList();
    reversedEdges.forEach((startNode, value) {
      Set<String> visited = Set();
      transverse(reversedEdges, visited, startNode);
      if (DEBUG) print('From $startNode $visited');
      var list = visited.toList();
      list.sort((a, b) {
        return calculatingOrderList.indexOf(a) -
            calculatingOrderList.indexOf(b);
      });
      reversedEdges[startNode] = list;
    });
    if (DEBUG) print('Reversed edge $reversedEdges');
    calculatingOrder = order;
    fieldChangedFieldMap = reversedEdges;
  }
}

class PrintInfo {
  bool isDefault;
  String? title;
  String? buttonTitle;
  List<String>? printFields;
  ParentParam? parentParam;
  bool printVertical;
  InputInfoMap inputInfoMap;
  List<String>? aggregateFields;
  List<String>? groupByFields;

  PrintInfo(this.inputInfoMap,
      {this.title,
      this.buttonTitle,
      this.printFields,
      this.parentParam,
      this.printVertical = false,
      this.isDefault = false,
      this.aggregateFields,
      this.groupByFields}) {
    printFields ??= inputInfoMap.map!.keys.toList();
    aggregateFields ??= inputInfoMap.map!.entries
        .where((element) =>
            element.value.dataType == DataType.int &&
            element.value.optionMap == null)
        .map((e) => e.key)
        .toList();
  }
}

abstract class CloudTableSchema<T extends CloudObject> {
  static const documentIdField = 'documentId';
  String? tableName;
  String? tableDescription;
  String? sortKey;
  bool? sortDescending;
  InputInfoMap inputInfoMap;
  T Function(String, Object?) convertData;
  LinkedHashSet<String>? calculatingOrder;
  List<PrintInfo>? printInfos;
  List<String>? defaultPrintFields;
  PrintTicket? printTicket;
  bool defaultPrintVertical;
  bool showDocumentId;

  // The following is for phone view ONLY
  List<String>? primaryFields;
  List<String>? subtitleFields;
  List<String>? trailingFields;
  IconData? iconData;
  bool showIconDataOnRow;
  bool isTableSpecial;

  // cache data from
  CollectionReference getCollectionRef() {
    return FirebaseFirestore.instance.collection(tableName!);
  }

  CloudTableSchema({
    this.tableName,
    this.tableDescription,
    this.printInfos,
    required this.inputInfoMap,
    required this.convertData,
    this.defaultPrintFields,
    this.showDocumentId = false,
    this.defaultPrintVertical = true,
    this.sortKey,
    this.sortDescending,
    this.primaryFields,
    this.subtitleFields,
    this.trailingFields,
    this.iconData,
    this.printTicket,
    this.showIconDataOnRow = false,
    this.isTableSpecial = false,
  }) {
    List<String> allVisibleKeys =
        inputInfoMap.filterVisibleFields().keys.toList();
    defaultPrintFields ??= allVisibleKeys;
    printTicket ??= PrintTicket(
        [TicketParagraph(fieldNames: defaultPrintFields)], inputInfoMap,
        title: tableDescription ?? tableName);
    printInfos ??= [
      PrintInfo(inputInfoMap,
          title: 'TẤT CẢ $tableDescription',
          buttonTitle: 'In cửa sổ',
          isDefault: true,
          printFields: defaultPrintFields,
          printVertical: defaultPrintVertical,
          parentParam: null)
    ];
    primaryFields ??= allVisibleKeys.sublist(0, 1);
    subtitleFields ??= allVisibleKeys.sublist(1);
    trailingFields ??= [];
    sortKey ??= allVisibleKeys.first;
    sortDescending ??= false;
  }

  SchemaAndData<T> convertSnapshotToDataList(QuerySnapshot snapshot) {
    List<T> result = snapshot.docs.asMap().entries.map((e) {
      return convertData(e.value.id, e.value.data());
    }).toList();
    return SchemaAndData<T>(this, result, snapshot.docs);
  }

  Stream<List<T>> getStream() {
    return getCollectionRef().snapshots().map((snapshot) {
      return convertSnapshotToDataList(snapshot).data;
    });
  }
}

class SchemaAndData<T extends CloudObject> {
  CloudTableSchema<T> cloudTableSchema;
  List<DocumentSnapshot> documentSnapshots;
  List<T> data;

  SchemaAndData(this.cloudTableSchema, this.data, this.documentSnapshots) {
    fillInCalculatedData(data, cloudTableSchema.inputInfoMap);
  }

  static void fillInCalculatedData(data, InputInfoMap inputInfoMap) {
    data.forEach((cloudObj) {
      inputInfoMap.calculatingOrder!.forEach((fieldName) {
        // Since this is initializing calculation, no need to calculate saved data.
        if (!inputInfoMap.map![fieldName]!.needSaving) {
          var result = inputInfoMap.map![fieldName]!.calculate!(
              cloudObj.dataMap, /* predefined= */ null);
          cloudObj.dataMap[fieldName] = result == null ? null : result.value;
        }
      });
    });
  }

  static Map<String, dynamic> fillInOptionData(
      Map row, Map<String, InputInfo>? inputInfoMap) {
    Map<String, dynamic> result = {};
    row.keys.forEach((fieldName) {
      var inputInfo = inputInfoMap![fieldName];
      if (inputInfo != null && inputInfo.optionMap != null) {
        result[fieldName] =
            inputInfo.optionMap![row[fieldName]] ?? row[fieldName];
      } else {
        result[fieldName] = row[fieldName];
      }
    });
    return result;
  }
}
