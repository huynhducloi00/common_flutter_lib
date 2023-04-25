import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/cloud_obj.dart';
import '../../data/cloud_table.dart';

const String containsStr = 'CONTAIN_STR';
const String exactMatchStr = 'EXACT_MATCH_STR';
InputInfoMap strFilterInfoMap = InputInfoMap({
  containsStr: InputInfo(DataType.string,
      fieldDes: 'Bắt đầu bằng', validator: InputInfo.nonEmptyStrValidator),
  exactMatchStr: InputInfo(DataType.boolean,
      fieldDes: 'Chính xác', validator: InputInfo.nonEmptyStrValidator,
  ),
});

FilterDataWrapper convertFromStringFilterMap(Map val) {
  String? strStart = val[containsStr];
  if (val[exactMatchStr]) {
    return FilterDataWrapper(
      exactMatchValue: strStart,
    );
  } else {
    String strEnd = strStart!;
    strEnd = strEnd.substring(0, strEnd.length - 1) +
        String.fromCharCode(strEnd.codeUnitAt(strEnd.length - 1) + 1);
    return FilterDataWrapper(
        filterStartValue: strStart,
        filterEndValue: strEnd,
        filterEndIncludeValue: false);
  }
}

const String exactMatchInt = '_EXACT_MATCH_INT';

InputInfoMap intFilterInfoMap(
        Map<dynamic, String?>? originalFieldOptionMap) =>
    InputInfoMap({
      exactMatchInt: InputInfo(DataType.int,
          optionMap: originalFieldOptionMap,
          fieldDes: 'Bằng',
          validator: InputInfo.nonNullValidator),
    });

FilterDataWrapper convertFromIntFilterMap(Map val) {
  return FilterDataWrapper(
    exactMatchValue: val[exactMatchInt],
  );
}

const String startDate = '_START_DATE';
const String endDate = '_END_DATE';
const String includeStartDate = '_INCLUDE_START_DATE';
const String includeEndDate = '_INCLUDE_END_DATE';
InputInfoMap timestampFilterInfoMap = InputInfoMap({
  startDate: InputInfo(DataType.timestamp, fieldDes: 'Ngày bắt đầu'),
  includeStartDate: InputInfo(DataType.boolean,
      fieldDes: 'Bao gồm ngày bắt đầu', validator: InputInfo.nonNullValidator),
  endDate: InputInfo(DataType.timestamp, fieldDes: 'Ngày kết thúc'),
  includeEndDate: InputInfo(DataType.boolean,
      fieldDes: 'Bao gồm ngày kết thúc', validator: InputInfo.nonNullValidator),
});

FilterDataWrapper convertFromTimeStampFilterMap(Map val) {
  return FilterDataWrapper(
      filterStartValue: val[startDate],
      filterEndValue: val[endDate],
      filterStartIncludeValue: val[includeStartDate],
      filterEndIncludeValue: val[includeEndDate]);
}

const String booleanValue = '_BOOLEAN_VALUE';
InputInfoMap booleanFilterInfoMap = InputInfoMap({
  booleanValue: InputInfo(DataType.boolean, fieldDes: 'Giá trị'),
});

FilterDataWrapper convertFromBooleanFilterMap(Map val) {
  return FilterDataWrapper(exactMatchValue: val[booleanValue]);
}

Query? specificFilter(var original, String fieldName,
    FilterDataWrapper filterDataWrapper, bool toSort) {
  if (filterDataWrapper.exactMatchValue != null) {
    return original.where(fieldName,
        isEqualTo: filterDataWrapper.exactMatchValue);
  }
  // use inequality
  if (toSort) {
    original = original.orderBy(fieldName);
  }
  return original.where(fieldName,
      isGreaterThan: filterDataWrapper.filterStartIncludeValue!
          ? null
          : filterDataWrapper.filterStartValue,
      isGreaterThanOrEqualTo: filterDataWrapper.filterStartIncludeValue!
          ? filterDataWrapper.filterStartValue
          : null,
      isLessThanOrEqualTo: filterDataWrapper.filterEndIncludeValue!
          ? filterDataWrapper.filterEndValue
          : null,
      isLessThan: filterDataWrapper.filterEndIncludeValue!
          ? null
          : filterDataWrapper.filterEndValue);
}

//Sometimes there is no filter
dynamic applyFilterToQuery(
    CollectionReference collectionReference, ParentParam parentParam) {
  var result;
  parentParam.filterDataWrappers!.forEach((fieldName, filterDataWrapper) {
    result ??= collectionReference;
    // Only sort for other filter keys and not sortKey.
    result = specificFilter(
        result,
        fieldName,
        filterDataWrapper!,
        /* toSort= */
        fieldName != parentParam.sortKey);
  });
  return result ?? collectionReference;
}

// return true to include the row
typedef PostFilterFunction = bool Function(Map row);

class FilterDataWrapper {
  dynamic filterStartValue;
  bool? filterStartIncludeValue;
  dynamic filterEndValue;
  bool? filterEndIncludeValue;
  dynamic exactMatchValue;
  PostFilterFunction? postFilterFunction;

  FilterDataWrapper(
      {this.filterEndIncludeValue = true,
      this.filterEndValue,
      this.filterStartIncludeValue = true,
      this.filterStartValue,
      this.exactMatchValue,
      this.postFilterFunction});

  @override
  String toString() {
    return '$filterStartValue $filterEndValue $exactMatchValue';
  }
}

typedef PostColorDecorationCondition = Color Function(
    Map<String, dynamic> dataMap);

class ParentParam {
  String? sortKey;
  bool? sortKeyDescending;
  Map<String, FilterDataWrapper?>? filterDataWrappers;
  PostColorDecorationCondition? postColorDecorationCondition;

  ParentParam(
      {this.filterDataWrappers,
      this.sortKey,
      this.sortKeyDescending = false,
      this.postColorDecorationCondition}) {
    filterDataWrappers ??= {};
  }
  ParentParam deepClone() {
    return ParentParam(
        filterDataWrappers: filterDataWrappers,
        sortKey: sortKey,
        sortKeyDescending: sortKeyDescending,
        postColorDecorationCondition: postColorDecorationCondition);
  }

  @override
  String toString() {
    return 'SortKey:$sortKey Descending: $sortKeyDescending-$filterDataWrappers';
  }
}
