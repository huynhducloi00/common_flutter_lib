import 'common_child_table.dart';
import 'phone_child_edit_table.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../data/cloud_obj.dart';
import '../../data/cloud_table.dart';
import '../../loadingstate/loading_stream_builder.dart';
import '../../utils.dart';
import '../../utils/auto_form.dart';
import '../../widget/edit_table/child_edit_table.dart';
import '../../widget/edit_table/child_param.dart';
import '../../widget/edit_table/parent_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common.dart';

class EditTableWrapper extends StatefulWidget {
  ParentParam parentParam;
  CloudTableSchema? cloudTable;
  DataPickerBundle? dataPickerBundle;
  bool showAllData;
  bool showFilterBar;
  bool showNewButton;

  EditTableWrapper(this.cloudTable, this.parentParam,
      {this.dataPickerBundle,
      this.showAllData = false,
      this.showFilterBar = true, this.showNewButton=true});

  @override
  _EditTableWrapperState createState() => _EditTableWrapperState();
}

class _EditTableWrapperState extends State<EditTableWrapper> {
  Widget getFilterButton() {
    return ExpansionTile(
      title: Text('Lọc'),
      children: widget.cloudTable!.inputInfoMap.map!.entries
          .map((entry) {
            var fieldName = entry.key;
            var inputInfo = entry.value;
            if (inputInfo.needSaving) {
              return ListTile(
                  title: Text(inputInfo.fieldDes!),
                  subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Sắp xếp'),
                        toggleSort(fieldName),
                        Text('Lọc'),
                        toggleFilter(inputInfo, fieldName)
                      ]));
            }
            return null;
          })
          .whereType<Widget>().toList(),
    );
  }

  Widget toggleSort(String fieldName) {
    return SizedBox(
        height: 20,
        child: CommonButton.getButton(context, () {
          if (widget.parentParam.sortKey == fieldName) {
            // change sort direction
            widget.parentParam.sortKeyDescending =
                !widget.parentParam.sortKeyDescending!;
          } else {
            widget.parentParam.sortKey = fieldName;
            widget.parentParam.sortKeyDescending = false;
          }
          if (widget.parentParam.filterDataWrappers![fieldName] != null &&
              widget.parentParam.filterDataWrappers![fieldName]!
                      .exactMatchValue !=
                  null) {
            // cannot be sorted and have exact value
            widget.parentParam.filterDataWrappers!.remove(fieldName);
          }
          setState(() {});
        },
            iconData: widget.parentParam.sortKey == fieldName
                ? (widget.parentParam.sortKeyDescending!
                    ? Icons.arrow_downward
                    : Icons.arrow_upward)
                : Icons.check_box_outline_blank,
            isDense: true,
            regularColor: Colors.transparent));
  }

  Widget toggleFilter(InputInfo inputInfo, String fieldName) {
    return SizedBox(
      height: 20,
      child: CommonButton.getButton(context, () {
        if (widget.parentParam.filterDataWrappers!.containsKey(fieldName)) {
          widget.parentParam.filterDataWrappers!.remove(fieldName);
          setState(() {});
          return;
        }
        late InputInfoMap usedMap;
        switch (inputInfo.dataType) {
          case DataType.string:
            usedMap = STRING_FILTER_INFO_MAP;
            // TODO: Handle this case.
            break;
          case DataType.html:
            // TODO: Handle this case.
            break;
          case DataType.int:
            usedMap = INT_FILTER_INFO_MAP(inputInfo.optionMap);
            break;
          case DataType.timestamp:
            usedMap = TIME_STAMP_FILTER_INFO_MAP;
            break;
          case DataType.boolean:
            usedMap = BOOLEAN_FILTER_INFO_MAP;
            break;
        }
        showAlertDialog(context, title: "Bộ loc ${inputInfo.fieldDes}",
            builder: (_) {
          return AutoForm.createAutoForm(context, usedMap, {},
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
            }

            widget.parentParam.filterDataWrappers![fieldName] = filterResult;
            if (filterResult!.exactMatchValue != null) {
              if (widget.parentParam.sortKey == fieldName) {
                // cannot have both exact match and sortkey
                widget.parentParam.sortKey = widget.cloudTable!.sortKey;
                widget.parentParam.sortKeyDescending =
                    widget.cloudTable!.sortDescending;
              }
            } else {
              // filter range, all other keys must not have filter range.
              List<String> removeField = [];
              widget.parentParam.filterDataWrappers!.forEach((field, value) {
                if (value!.exactMatchValue == null && field != fieldName) {
                  removeField.add(field);
                }
              });
              widget.parentParam.filterDataWrappers!
                  .removeWhere((key, value) => removeField.contains(key));
            }
            setState(() {});
            return null;
          });
        });
      },
          iconColor: widget.parentParam.filterDataWrappers![fieldName] == null
              ? null
              : Colors.red,
          iconData: Icons.filter_list,
          regularColor: Colors.transparent,
          isDense: true),
    );
  }

  List getHeaderRow() {
    var filteredMap = widget.cloudTable!.inputInfoMap.filterVisibleFields();
    var tableCells = filteredMap.entries.map((e) {
      var fieldName = e.key;
      var inputInfo = e.value;
      return SizedBox(
        height: 80,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(
                inputInfo.fieldDes ?? fieldName,
                style: BIG_FONT,
                maxLines: 2,
              )),
              widget.showFilterBar ? toggleSort(fieldName) : null,
              widget.showFilterBar ? toggleFilter(inputInfo, fieldName) : null
            ].where((element) => element != null).toList() as List<Widget>),
      );
    }).toList();
    TableWidthAndSize tableWidthAndSize =
        getEditTableColWidths(context, filteredMap);
    return [
      Table(
        columnWidths: tableWidthAndSize.colWidths,
        border: TableBorder(
            top: EDIT_TABLE_HORIZONTAL_BORDER_SIDE,
            bottom: EDIT_TABLE_HORIZONTAL_BORDER_SIDE,
            verticalInside: EDIT_TABLE_HORIZONTAL_BORDER_SIDE,
            horizontalInside: EDIT_TABLE_HORIZONTAL_BORDER_SIDE),
        children: [TableRow(children: tableCells)],
      ),
      tableWidthAndSize.width
    ];
  }

  @override
  Widget build(BuildContext context) {
    var content = Provider.value(
        value: widget.parentParam,
        child: TableWrapper(
          widget.cloudTable,
          widget.dataPickerBundle,
          showNewButton: widget.showNewButton,
          showAllData: widget.showAllData,
        ));
    var mobile = SingleChildScrollView(
      child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            widget.showFilterBar ? getFilterButton() : null,
            content,
          ].whereType<Widget>().toList()),
    );
    var tablet = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      var headerRowBundle = getHeaderRow();
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: headerRowBundle[1],
          child: Column(
            children: [
              headerRowBundle[0],
              content,
            ],
          ),
        ),
      );
    });
    return widget.dataPickerBundle != null
        ? mobile
        : ScreenTypeLayout(
            // breakpoints: forDebuggingScreenBreakpoints(),
            mobile: mobile,
            tablet: tablet);
  }
}

class DatabasePagerNotifier extends ValueNotifier<ChildParam> {
  DatabasePagerNotifier(ChildParam value) : super(value);
}

class TableWrapper extends StatefulWidget {
  @override
  _TableWrapperState createState() => _TableWrapperState();

  CloudTableSchema? cloudTable;
  DataPickerBundle? dataPickerBundle;
  bool showAllData;
  bool showNewButton;
  TableWrapper(this.cloudTable, this.dataPickerBundle,
      {this.showAllData = false, this.showNewButton=true});
}

class _TableWrapperState extends State<TableWrapper> {
  DatabasePagerNotifier databasePagerNotifier =
      DatabasePagerNotifier(ChildParam());
  final LIMIT = 10;

  @override
  Widget build(BuildContext context) {
    databasePagerNotifier.value.startAfter = null;
    databasePagerNotifier.value.endBefore = null;
    return ChangeNotifierProvider(create: (BuildContext context) {
      return databasePagerNotifier;
    }, child: Consumer<DatabasePagerNotifier>(
      builder: (BuildContext context, DatabasePagerNotifier _, Widget? child) {
        ParentParam parentParam =
            Provider.of<ParentParam>(context, listen: false);
        CollectionReference _databaseRef = widget.cloudTable!.getCollectionRef();
        // Apply both parent and child params.
        var query = applyFilterToQuery(_databaseRef, parentParam);
        // startAfter ... table ... endBefore, which affected by sort direction
        bool reverse = false;
        if (!widget.showAllData) {
          if (parentParam.sortKeyDescending!) {
            if (databasePagerNotifier.value.endBefore != null) {
              // reverse of endBefore is start after
              query = query
                  .orderBy(parentParam.sortKey, descending: false)
                  .startAfter([databasePagerNotifier.value.endBefore]);
              reverse = true;
            } else {
              query = query.orderBy(parentParam.sortKey, descending: true);
              if (databasePagerNotifier.value.startAfter != null) {
                query =
                    query.startAfter([databasePagerNotifier.value.startAfter]);
              }
            }
          } else {
            // ascending
            if (databasePagerNotifier.value.endBefore != null) {
              // reverse of endBefore is start after
              query = query
                  .orderBy(parentParam.sortKey, descending: true)
                  .startAfter([databasePagerNotifier.value.endBefore]);
              reverse = true;
            } else {
              query = query.orderBy(parentParam.sortKey, descending: false);
              if (databasePagerNotifier.value.startAfter != null) {
                query =
                    query.startAfter([databasePagerNotifier.value.startAfter]);
              }
            }
          }
          query = query.limit(LIMIT);
        }
        Stream<SchemaAndData<CloudObject>> newSnapshot =
            (query as Query).snapshots().map((event) {
          List<DocumentSnapshot> snapshots = [];
          snapshots.addAll(event.docs);
          if (reverse) {
            snapshots = snapshots.reversed.toList();
          }
          return widget.cloudTable!.convertSnapshotToDataList(snapshots);
        });
        return createStreamBuilder<SchemaAndData<CloudObject>, Widget>(
            stream: newSnapshot,
            child: widget.dataPickerBundle == null
                ? ScreenTypeLayout(
                    // breakpoints: forDebuggingScreenBreakpoints(),
                    tablet: ChildEditTable(
                      _databaseRef,
                      showAllData: widget.showAllData,
                      showNewButton: widget.showNewButton,
                    ),
                    mobile: PhoneChildEditTable(
                      _databaseRef,
                      showAllData: widget.showAllData,
                      showNewButton: widget.showNewButton,
                    ))
                // always use phone pick styles when there is a need to pick
                : PhoneChildEditTable(
                    _databaseRef,
                    dataPickerBundle: widget.dataPickerBundle,
                    showAllData: widget.showAllData,
                  ));
      },
    ));
  }
}
