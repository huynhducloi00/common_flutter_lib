import 'package:canxe/common/data/cloud_obj.dart';
import 'package:canxe/common/data/cloud_table.dart';
import 'package:canxe/common/loadingstate/loading_stream_builder.dart';
import 'package:canxe/common/utils/auto_form.dart';
import 'package:canxe/common/widget/edit_table/child_edit_table.dart';
import 'package:canxe/common/widget/edit_table/child_param.dart';
import 'package:canxe/common/widget/edit_table/parent_param.dart';
import 'package:canxe/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common.dart';

class EditTableWrapper extends StatefulWidget {
  ParentParam parentParam;
  CloudTableSchema cloudTable;

  EditTableWrapper(this.cloudTable, this.parentParam) {
    if (parentParam.sortKey == null) {
      parentParam.sortKey = cloudTable.inputInfoMap.keys.first;
      parentParam.sortKeyDescending = false;
    }
  }

  @override
  _EditTableWrapperState createState() => _EditTableWrapperState();
}

class _EditTableWrapperState extends State<EditTableWrapper> {
  @override
  Widget build(BuildContext context) {
    var tableCells = widget.cloudTable.inputInfoMap.entries.map((e) {
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
              SizedBox(
                height: 20,
                child: CommonButton.getButton(context, () {
                  if (widget.parentParam.sortKey == fieldName) {
                    // change sort direction
                    widget.parentParam.sortKeyDescending =
                        !widget.parentParam.sortKeyDescending;
                  } else {
                    widget.parentParam.sortKey = fieldName;
                    widget.parentParam.sortKeyDescending = false;
                  }
                  setState(() {});
                },
                    iconData: widget.parentParam.sortKey == fieldName
                        ? (widget.parentParam.sortKeyDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward)
                        : Icons.check_box_outline_blank,
                    isDense: true),
              ),
              SizedBox(
                height: 20,
                child: CommonButton.getButton(context, () {
                  if (widget.parentParam.filterDataWrappers
                      .containsKey(fieldName)) {
                    widget.parentParam.filterDataWrappers.remove(fieldName);
                    setState(() {});
                    return;
                  }
                  Map usedMap;
                  switch (inputInfo.dataType) {
                    case DataType.string:
                      usedMap = STRING_FILTER_INFO_MAP;
                      // TODO: Handle this case.
                      break;
                    case DataType.html:
                      // TODO: Handle this case.
                      break;
                    case DataType.int:
                      // TODO: Handle this case.
                      break;
                    case DataType.timestamp:
                      usedMap = TIME_STAMP_FILTER_INFO_MAP;
                      // TODO: Handle this case.
                      break;
                    case DataType.boolean:
                      // TODO: Handle this case.
                      break;
                  }
                  showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text("Bộ loc ${inputInfo.fieldDes}"),
                          content: AutoForm.createAutoForm(context, usedMap, {},
                              saveClickFuture: (valueMap) {
                            FilterDataWrapper filterResult;
                            switch (inputInfo.dataType) {
                              case DataType.string:
                                filterResult =
                                    convertFromStringFilterMap(valueMap);
                                break;
                              case DataType.html:
                                // TODO: Handle this case.
                                break;
                              case DataType.int:
                                // TODO: Handle this case.
                                break;
                              case DataType.timestamp:
                                filterResult =
                                    convertFromTimeStampFilterMap(valueMap);
                                break;
                              case DataType.boolean:
                                // TODO: Handle this case.
                                break;
                            }

                            widget.parentParam.filterDataWrappers[fieldName] =
                                filterResult;

                            setState(() {});
                            return null;
                          }),
                        );
                      });
                },
                    iconColor:
                        widget.parentParam.filterDataWrappers[fieldName] == null
                            ? null
                            : Colors.red,
                    iconData: Icons.filter_list,
                    isDense: true),
              )
            ]),
      );
    }).toList();
    TableWidthAndSize tableWidthAndSize =
        getEditTableColWidths(context, widget.cloudTable.inputInfoMap);
    Table headerRow = Table(
      columnWidths: tableWidthAndSize.colWidths,
      border: TableBorder(
          top: EDIT_TABLE_BORDER_SIDE,
          bottom: EDIT_TABLE_BORDER_SIDE,
          verticalInside: EDIT_TABLE_BORDER_SIDE,
          horizontalInside: EDIT_TABLE_BORDER_SIDE),
      children: [TableRow(children: tableCells)],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidthAndSize.width,
        child: Column(
          children: [
            headerRow,
            Provider.value(
                value: widget.parentParam,
                child: TableWrapper(widget.cloudTable))
          ],
        ),
      ),
    );
  }
}

class DatabasePagerNotifier extends ValueNotifier<ChildParam> {
  DatabasePagerNotifier(ChildParam value) : super(value);
}

class TableWrapper extends StatefulWidget {
  @override
  _TableWrapperState createState() => _TableWrapperState();

  CloudTableSchema cloudTable;

  TableWrapper(this.cloudTable);
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
      builder: (BuildContext context, DatabasePagerNotifier _, Widget child) {
        ParentParam parentParam =
            Provider.of<ParentParam>(context, listen: false);
        CollectionReference _databaseRef =
            Firestore.instance.collection(widget.cloudTable.tableName);
        var query = applyFilterToQuery(_databaseRef, parentParam);
        // startAfter ... table ... endBefore, which affected by sort direction
        bool reverse = false;
        if (parentParam.sortKeyDescending) {
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
//        print(query.buildArguments());

        Stream<SchemaAndData<CloudObject>> newSnapshot =
        (query as Query).snapshots().map((event) {
          List<DocumentSnapshot> snapshots = List();
          snapshots.addAll(event.documents);
          if (reverse) {
            snapshots = snapshots.reversed.toList();
          }
          return widget.cloudTable.convertSnapshotToDataList(snapshots);
        });
        return createStreamBuilder<SchemaAndData<CloudObject>, ChildEditTable>(
            stream: newSnapshot, child: ChildEditTable(_databaseRef));
      },
    ));
  }
}
