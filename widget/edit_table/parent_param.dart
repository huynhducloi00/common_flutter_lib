import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/cloud_obj.dart';
import '../../data/cloud_table.dart';

const String _CONTAIN_STR = 'CONTAIN_STR';
const String _EXACT_MATCH_STR = 'EXACT_MATCH_STR';
Map<String, InputInfo> STRING_FILTER_INFO_MAP = {
  _CONTAIN_STR: InputInfo(DataType.string,
      fieldDes: 'Bắt đầu bằng', validator: InputInfo.nonNullValidator),
  _EXACT_MATCH_STR: InputInfo(DataType.boolean,
      fieldDes: 'Chính xác', validator: InputInfo.nonNullValidator),
};
const String _START_DATE = '_START_DATE';
const String _END_DATE = '_END_DATE';
const String _INCLUDE_START_DATE = '_INCLUDE_START_DATE';
const String _INCLUDE_END_DATE = '_INCLUDE_END_DATE';
Map<String, InputInfo> TIME_STAMP_FILTER_INFO_MAP = {
  _START_DATE: InputInfo(DataType.timestamp,
      fieldDes: 'Ngày bắt đầu', validator: InputInfo.nonNullValidator),
  _INCLUDE_START_DATE: InputInfo(DataType.boolean,
      fieldDes: 'Bao gồm ngày bắt đầu', validator: InputInfo.nonNullValidator),
  _END_DATE: InputInfo(DataType.timestamp,
      fieldDes: 'Ngày kết thúc', validator: InputInfo.nonNullValidator),
  _INCLUDE_END_DATE: InputInfo(DataType.boolean,
      fieldDes: 'Bao gồm ngày kết thúc', validator: InputInfo.nonNullValidator),
};

FilterDataWrapper convertFromTimeStampFilterMap(Map val) {
  return FilterDataWrapper(
      filterStartValue: val[_START_DATE],
      filterEndValue: val[_END_DATE],
      filterStartIncludeValue: val[_INCLUDE_START_DATE],
      filterEndIncludeValue: val[_INCLUDE_END_DATE]);
}

FilterDataWrapper convertFromStringFilterMap(Map val) {
  String strStart = val[_CONTAIN_STR];
  if (val[_EXACT_MATCH_STR]) {
    return FilterDataWrapper(
      exactMatchValue: strStart,
    );
  } else {
    String strEnd = strStart;
    strEnd = strEnd.substring(0, strEnd.length - 1) +
        String.fromCharCode(strEnd.codeUnitAt(strEnd.length - 1) + 1);
    return FilterDataWrapper(
        filterStartValue: strStart,
        filterEndValue: strEnd,
        filterEndIncludeValue: false);
  }
}

Query specificFilter(var original, String fieldName,
    FilterDataWrapper filterDataWrapper, bool toSort) {
  if (filterDataWrapper.exactMatchValue == null) {
    if (toSort) {
      original = original.orderBy(fieldName);
    }
    return original.where(fieldName,
        isGreaterThan: filterDataWrapper.filterStartIncludeValue
            ? null
            : filterDataWrapper.filterStartValue,
        isGreaterThanOrEqualTo: filterDataWrapper.filterStartIncludeValue
            ? filterDataWrapper.filterStartValue
            : null,
        isLessThanOrEqualTo: filterDataWrapper.filterEndIncludeValue
            ? filterDataWrapper.filterEndValue
            : null,
        isLessThan: filterDataWrapper.filterEndIncludeValue
            ? null
            : filterDataWrapper.filterEndValue);
  }
  return original.where(fieldName,
      isEqualTo: filterDataWrapper.exactMatchValue);
}

//Sometimes there is no filter
dynamic applyFilterToQuery(
    CollectionReference collectionReference, ParentParam parentParam) {
  var result;
  parentParam.filterDataWrappers.forEach((fieldName, filterDataWrapper) {
    if (result == null) {
      result = collectionReference;
    }
    // Only sort for other filter keys and not sortKey.
    result = specificFilter(
        result,
        fieldName,
        filterDataWrapper,
        /* toSort= */
        fieldName != parentParam.sortKey);
  });
  return result ?? collectionReference;
}

class FilterDataWrapper {
  dynamic filterStartValue;
  bool filterStartIncludeValue;
  dynamic filterEndValue;
  bool filterEndIncludeValue;
  dynamic exactMatchValue;

  FilterDataWrapper({
    this.filterEndIncludeValue = true,
    this.filterEndValue,
    this.filterStartIncludeValue = true,
    this.filterStartValue,
    this.exactMatchValue,
  });

  @override
  String toString() {
    return '$filterStartValue $filterEndValue $exactMatchValue';
  }
}

class ParentParam {
  String sortKey;
  bool sortKeyDescending;
  Map<String, FilterDataWrapper> filterDataWrappers;

  ParentParam({this.filterDataWrappers, this.sortKey, this.sortKeyDescending=false});

  @override
  String toString() {
    return 'SortKey:${sortKey} ${filterDataWrappers}';
  }
}
