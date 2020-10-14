import '../../loadingstate/loading_stream_builder.dart';
import '../../utils.dart';
import '../../widget/edit_table/child_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/cloud_table.dart';
import '../common.dart';
import 'common_child_table.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';

class PhoneChildEditTable<SchemaAndData> extends StatefulWidget {
  final CollectionReference databaseRef;
  DataPickerBundle dataPickerBundle;
  bool showAllData;

  PhoneChildEditTable(this.databaseRef,
      {this.dataPickerBundle, this.showAllData = false});

  @override
  _PhoneChildEditTableState createState() => _PhoneChildEditTableState();
}

class _PhoneChildEditTableState
    extends StreamStatefulChildState<PhoneChildEditTable, SchemaAndData> {
  String inducedField(val, InputInfo inputInfo) {
    var calculated;
    if (val != null) {
      calculated =
          inputInfo.optionMap == null ? null : inputInfo.optionMap[val];
    }
    return calculated == null ? '${toText(context, val ?? '')}' : '$calculated';
  }

  String _concat(Map row, List<String> fieldList) {
    String result = toText(context, row[fieldList[0]]) ?? '';
    fieldList.sublist(1).forEach((field) {
      result += ', ${toText(context, row[field]) ?? ''}';
    });
    return result;
  }

  @override
  Widget delegateBuild(BuildContext context) {
    ParentParam parentParam = Provider.of<ParentParam>(context, listen: false);
    var schemaAndData = data;
    Widget navigator;
    if (!widget.showAllData) {
      navigator = Consumer<DatabasePagerNotifier>(builder:
          (BuildContext context, DatabasePagerNotifier databasePagerNotifier,
              Widget child) {
        var newButton = widget.dataPickerBundle == null
            ? ChildTableUtils.newButton(
                context, widget.databaseRef, schemaAndData.cloudTableSchema.inputInfoMap,
                isPhone: true)
            : null;
        if (schemaAndData.data.length == 0) {
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CommonButton.getButton(context, () {
                  databasePagerNotifier.value = ChildParam();
                }, title: 'Về trang đầu'),
                newButton
              ]);
        }
        var beforeQuery = applyFilterToQuery(widget.databaseRef, parentParam)
            .orderBy(parentParam.sortKey,
                descending: parentParam.sortKeyDescending)
            .endBefore([
          schemaAndData.data.first.dataMap[parentParam.sortKey]
        ]).limit(1) as Query;
        var afterQuery = applyFilterToQuery(widget.databaseRef, parentParam)
            .orderBy(parentParam.sortKey,
                descending: parentParam.sortKeyDescending)
            .startAfter([
          schemaAndData.data.last.dataMap[parentParam.sortKey]
        ]).limit(1) as Query;
        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.dataPickerBundle != null
                  ? null
                  : ExpansionTile(title: Text('Thông tin thêm'), children: <
                      Widget>[
                      Wrap(
                          runSpacing: 4,
                          spacing: 8,
                          children: schemaAndData.cloudTableSchema.printInfos
                              .map(
                                (printInfo) => ChildTableUtils.printButton(
                                    context,
                                    widget.databaseRef,
                                    printInfo,
                                    parentParam,
                                    isDense: true),
                              )
                              .toList()),
                      SizedBox(
                        width: screenWidth(context),
                        height: screenHeight(context) * 0.1,
                        child: tableOfTwo({
                          'Trường sắp xếp':
                              '${schemaAndData.cloudTableSchema.inputInfoMap.map[parentParam.sortKey].fieldDes}-${parentParam.sortKeyDescending ? "Giảm dần" : "Tăng dần"}',
                          'Hiển thị sau': toText(
                              context, databasePagerNotifier.value.startAfter),
                          'Hiển thị trước': toText(
                              context, databasePagerNotifier.value.endBefore),
                          'Số lượng hiển thị': '${schemaAndData.data.length}',
                        }, boldRight: true),
                      ),
                    ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StreamProvider<bool>.value(
                    value: isLoading
                        ? Stream<bool>.value(false)
                        : beforeQuery.snapshots().map((event) {
                            return event.documents.length > 0;
                          }),
                    child: Builder(
                      builder: (BuildContext context) {
                        bool existBefore = Provider.of<bool>(context) ?? false;
                        return CommonButton.getButton(context, () {
                          // go back
                          databasePagerNotifier.value = ChildParam(
                              endBefore: schemaAndData
                                  .data.first.dataMap[parentParam.sortKey]);
                        },
                            title: "",
                            iconData:
                                existBefore ? Icons.navigate_before : null,
                            isEnabled: existBefore);
                      },
                    ),
                  ),
                  StreamProvider<bool>.value(
                    value: isLoading
                        ? Stream<bool>.value(false)
                        : afterQuery
                            .snapshots()
                            .map((event) => event.documents.length > 0),
                    child: Builder(builder: (BuildContext context) {
                      bool existAfter = Provider.of<bool>(context) ?? false;
                      return CommonButton.getButton(context, () {
                        // go forward
                        databasePagerNotifier.value = ChildParam(
                            startAfter: schemaAndData
                                .data.last.dataMap[parentParam.sortKey]);
                      },
                          title: "",
                          iconData: existAfter ? Icons.navigate_next : null,
                          isEnabled: existAfter);
                    }),
                  ),
                  newButton
                ].where((element) => element != null).toList(),
              ),
            ].where((element) => element != null).toList());
      });
    }
    List<Widget> itemList = schemaAndData.data.asMap().entries.map((entry) {
      var index = entry.key;
      var cloudObj = entry.value;
      var row = SchemaAndData.fillInOptionData(
          cloudObj.dataMap, schemaAndData.cloudTableSchema.inputInfoMap.map);
      var inputInfoMap = schemaAndData.cloudTableSchema.inputInfoMap;

      return Card(
          color: parentParam.postColorDecorationCondition != null
              ? parentParam.postColorDecorationCondition(row)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ListTile(
            leading: schemaAndData.cloudTableSchema.showIconDataOnRow
                ? Icon(schemaAndData.cloudTableSchema.iconData)
                : null,
            title: Text(_concat(
                    row, schemaAndData.cloudTableSchema.primaryFields)) ??
                '',
            subtitle: tableOfTwo(schemaAndData.cloudTableSchema.subtitleFields
                .asMap()
                .map((index, fieldName) => MapEntry(
                    inputInfoMap.map[fieldName].fieldDes,
                    toText(context, row[fieldName])))),
            trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: schemaAndData.cloudTableSchema.trailingFields
                    .map((fieldName) =>
                        Text(toText(context, row[fieldName]) ?? ''))
                    .toList()),
            onTap: () {
              if (widget.dataPickerBundle != null) {
                Navigator.pop(context, [row[widget.dataPickerBundle.fieldName], row]);
                return;
              }
              showAlertDialog(context, builder: (_) {
                return columnWithGap([
                  ChildTableUtils.printLineButton(context,
                      schemaAndData.cloudTableSchema.printTicket, row, true),
                  ChildTableUtils.editButton(
                      context, widget.databaseRef, schemaAndData, index,
                      isPhone: true),
                  ChildTableUtils.deleteButton(
                      context, widget.databaseRef, schemaAndData, index)
                ], crossAxisAlignment: CrossAxisAlignment.center);
              });
            },
          ));
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: navigator == null ? itemList : [navigator] + itemList,
    );
  }
}
