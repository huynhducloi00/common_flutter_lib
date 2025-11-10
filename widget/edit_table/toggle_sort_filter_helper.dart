import 'package:flutter/material.dart';

import '../../data/cloud_obj.dart';
import '../../data/cloud_table.dart';
import '../../utils.dart';
import '../../utils/auto_form.dart';
import '../common.dart';
import 'current_query_notifier.dart';
import 'parent_param.dart';

Widget toggleSort(BuildContext context,
    CurrentQueryNotifier currentQueryNotifier, String fieldName) {
  return CommonButton.getButton(context, () {
    var newParam = currentQueryNotifier.parentParam.deepClone();
    if (newParam.sortKey == fieldName) {
      // change sort direction
      newParam.sortKeyDescending = !newParam.sortKeyDescending!;
    } else {
      newParam.sortKey = fieldName;
      newParam.sortKeyDescending = false;
    }
    if (newParam.filterDataWrappers![fieldName] != null &&
        newParam.filterDataWrappers![fieldName]!.exactMatchValue != null) {
      // cannot be sorted and have exact value
      newParam.filterDataWrappers!.remove(fieldName);
    }
    currentQueryNotifier.parentParam = newParam;
  },
      iconData: currentQueryNotifier.parentParam.sortKey == fieldName
          ? (currentQueryNotifier.parentParam.sortKeyDescending!
              ? Icons.arrow_downward
              : Icons.arrow_upward)
          : Icons.check_box_outline_blank,
      isDense: true,
      regularColor: Colors.transparent);
}

Widget toggleFilter(
    BuildContext context,
    CurrentQueryNotifier currentQueryNotifier,
    InputInfo inputInfo,
    String fieldName) {
  return CommonButton.getButton(context, () {
    if (currentQueryNotifier.parentParam.filterDataWrappers!
        .containsKey(fieldName)) {
      var newParam = currentQueryNotifier.parentParam.deepClone();
      newParam.filterDataWrappers!.remove(fieldName);
      currentQueryNotifier.parentParam = newParam;
      return;
    }
    var newParam = currentQueryNotifier.parentParam.deepClone();
    late InputInfoMap usedMap;
    switch (inputInfo.dataType) {
      case DataType.string:
        usedMap = strFilterInfoMap;
        // TODO: Handle this case.
        break;
      case DataType.html:
        // TODO: Handle this case.
        break;
      case DataType.int:
        usedMap = intFilterInfoMap(inputInfo.optionMap);
        break;
      case DataType.timestamp:
        usedMap = timestampFilterInfoMap;
        break;
      case DataType.boolean:
        usedMap = booleanFilterInfoMap;
        break;
      case DataType.double:
        // TODO: Handle this case.
        break;
      case DataType.firebaseImage:
        // TODO: Handle this case.
        break;
    }
    showAlertDialog(context, title: "Bộ loc ${inputInfo.fieldDes}",
        builder: (_) {
      return AutoForm.createAutoForm(context, usedMap, {exactMatchStr: true},
          saveClickFuture: (valueMap) {
        FilterDataWrapper? filterResult;
        switch (inputInfo.dataType) {
          case DataType.string:
            filterResult = convertFromStringFilterMap(valueMap);
            break;
          case DataType.html:
            // TODO: Handle this case.
            break;
          case DataType.int:
            filterResult = convertFromIntFilterMap(valueMap);
            break;
          case DataType.timestamp:
            filterResult = convertFromTimeStampFilterMap(valueMap);
            break;
          case DataType.boolean:
            filterResult = convertFromBooleanFilterMap(valueMap);
            break;
          case DataType.double:
            // TODO: Handle this case.
            break;
          case DataType.firebaseImage:
            // TODO: Handle this case.
            break;
        }

        newParam.filterDataWrappers![fieldName] = filterResult;
        if (filterResult!.exactMatchValue != null) {
          if (newParam.sortKey == fieldName) {
            // cannot have both exact match and sortkey
            // newParam.sortKey = widget.cloudTable!.sortKey;
            // newParam.sortKeyDescending =
            //     widget.cloudTable!.sortDescending;
          }
        } else {
          // filter range, all other keys must not have filter range.
          List<String> removeField = [];
          newParam.filterDataWrappers!.forEach((field, value) {
            if (value!.exactMatchValue == null && field != fieldName) {
              removeField.add(field);
            }
          });
          newParam.filterDataWrappers!
              .removeWhere((key, value) => removeField.contains(key));
        }
        currentQueryNotifier.parentParam = newParam;
        return null;
      });
    });
  },
      iconColor:
          currentQueryNotifier.parentParam.filterDataWrappers![fieldName] ==
                  null
              ? null
              : Colors.red,
      iconData: Icons.filter_list,
      regularColor: Colors.transparent,
      isDense: true);
}
