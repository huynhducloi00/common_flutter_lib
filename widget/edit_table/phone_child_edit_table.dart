// import 'dart:html';

import '../../data/cloud_obj.dart';
import '../../loadingstate/loading_state.dart';
import '../../utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/cloud_table.dart';
import '../common.dart';
import 'common_child_table.dart';
import 'current_query_notifier.dart';

class PhoneChildEditTable<SchemaAndData> extends StatefulWidget {
  final CollectionReference databaseRef;
  DataPickerBundle? dataPickerBundle;
  bool showAllData;
  bool showNewButton;
  PhoneChildEditTable(this.databaseRef,
      {Key? key,
      this.dataPickerBundle,
      this.showAllData = false,
      this.showNewButton = true})
      : super(key: key);

  @override
  _PhoneChildEditTableState createState() => _PhoneChildEditTableState();
}

class _PhoneChildEditTableState
    extends LoadingState<PhoneChildEditTable, SchemaAndData?> {
  CurrentQueryNotifier? currentQueryNotifier;
  _PhoneChildEditTableState() : super(isRequireData: true);

  String _concat(Map row, List<String> fieldList) {
    String result = toText(context, row[fieldList[0]]) ?? '';
    fieldList.sublist(1).forEach((field) {
      result += ', ${toText(context, row[field]) ?? ''}';
    });
    return result;
  }

  Widget getNavigator() {
    SchemaAndData<CloudObject> schemaAndData = data!;
    var parentParam = currentQueryNotifier!.parentParam;
    var moreInfoWidget =
        ExpansionTile(title: Text('Thông tin thêm'), children: <Widget>[
      Wrap(
          runSpacing: 4,
          spacing: 8,
          children: schemaAndData.cloudTableSchema.printInfos!
              .map(
                (printInfo) => ChildTableUtils.printButton(
                  context,
                  widget.databaseRef,
                  printInfo,
                  parentParam,
                  isDense: true,
                ),
              )
              .toList()),
      SizedBox(
        width: screenWidth(context),
        height: screenHeight(context) * 0.1,
        child: tableOfTwo({
          'Trường sắp xếp':
              '${schemaAndData.cloudTableSchema.inputInfoMap.map![parentParam.sortKey!]!.fieldDes}-${parentParam.sortKeyDescending! ? "Giảm dần" : "Tăng dần"}',
          'Số lượng hiển thị': '${schemaAndData.data.length}',
        }, boldRight: true),
      ),
    ]);
    var newButton = widget.dataPickerBundle == null && widget.showNewButton
        ? ChildTableUtils.newButton(context, widget.databaseRef,
            schemaAndData.cloudTableSchema.inputInfoMap,
            isPhone: true)
        : null;

    if (widget.showAllData) {
      return moreInfoWidget;
    } else {
      if (schemaAndData.data.isEmpty) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CommonButton.getButton(context, () {
                // databasePagerNotifier.value = ChildParam();
              }, title: 'Về trang đầu'),
              newButton
            ].whereType<Widget>().toList());
      }
      var originalQuery = currentQueryNotifier!.originalQuery;
      var hasBefore = originalQuery
          .endBeforeDocument(schemaAndData.documentSnapshots.first)
          .limit(1)
          .snapshots()
          .map((QuerySnapshot snapshot) {
        return snapshot.docs.length > 0;
      });
      var hasAfter = originalQuery
          .startAfterDocument(schemaAndData.documentSnapshots.last)
          .limit(1)
          .snapshots()
          .map((QuerySnapshot event) {
        return event.docs.length > 0;
      });
      return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.dataPickerBundle != null ? null : moreInfoWidget,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreamProvider<bool>.value(
                  initialData: false,
                  value: isLoading ? Stream<bool>.value(false) : hasBefore,
                  child: Builder(
                    builder: (BuildContext context) {
                      bool existBefore = Provider.of<bool>(context);
                      return CommonButton.getButton(context, () {
                        // go back
                        currentQueryNotifier!.currentPagingQuery =
                            originalQuery.endBeforeDocument(
                                schemaAndData.documentSnapshots.first);
                      },
                          title: "",
                          iconData: existBefore ? Icons.navigate_before : null,
                          isEnabled: existBefore);
                    },
                  ),
                ),
                StreamProvider<bool>.value(
                  initialData: false,
                  value: isLoading ? Stream<bool>.value(false) : hasAfter,
                  child: Builder(builder: (BuildContext context) {
                    bool existAfter = Provider.of<bool>(context);
                    return CommonButton.getButton(context, () {
                      // go forward
                      currentQueryNotifier!.currentPagingQuery =
                          originalQuery.startAfterDocument(
                              schemaAndData.documentSnapshots.last);
                    },
                        title: "",
                        iconData: existAfter ? Icons.navigate_next : null,
                        isEnabled: existAfter);
                  }),
                ),
                newButton
              ].whereType<Widget>().toList(),
            ),
          ].whereType<Widget>().toList());
    }
  }

  getTable() {
    SchemaAndData<CloudObject> schemaAndData = data!;
    var parentParam = currentQueryNotifier!.parentParam;
    return schemaAndData.data.asMap().entries.map((entry) {
      var index = entry.key;
      var cloudObj = entry.value;
      var row = SchemaAndData.fillInOptionData(
          cloudObj.dataMap, schemaAndData.cloudTableSchema.inputInfoMap.map);
      var inputInfoMap = schemaAndData.cloudTableSchema.inputInfoMap;

      return Card(
          color: parentParam.postColorDecorationCondition != null
              ? parentParam.postColorDecorationCondition!(cloudObj.dataMap)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ListTile(
            leading: schemaAndData.cloudTableSchema.showIconDataOnRow
                ? Icon(schemaAndData.cloudTableSchema.iconData)
                : null,
            title: Text(
                _concat(row, schemaAndData.cloudTableSchema.primaryFields!)),
            subtitle: tableOfTwo(schemaAndData.cloudTableSchema.subtitleFields!
                .asMap()
                .map((index, fieldName) => MapEntry(
                    inputInfoMap.map![fieldName]!.fieldDes,
                    inputInfoMap.map![fieldName]!
                        .displayConverter(context, row[fieldName])))),
            trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: schemaAndData.cloudTableSchema.trailingFields!
                    .map((fieldName) =>
                        Text(toText(context, row[fieldName]) ?? ''))
                    .toList()),
            onTap: () {
              if (widget.dataPickerBundle != null) {
                Navigator.pop(
                    context, [row[widget.dataPickerBundle!.fieldName], row]);
                return;
              }
              showAlertDialog(context, builder: (_) {
                return columnWithGap([
                  ChildTableUtils.printLineButton(context,
                      schemaAndData.cloudTableSchema.printTicket, row, true),
                  ChildTableUtils.editButton(
                      context, widget.databaseRef, schemaAndData, [index],
                      isPhone: true),
                  ChildTableUtils.deleteButton(
                      context, widget.databaseRef, schemaAndData, [index])
                ], crossAxisAlignment: CrossAxisAlignment.center);
              });
            },
          ));
    }).toList();
  }

  @override
  Widget delegateBuild(BuildContext context) {
    currentQueryNotifier =
        Provider.of<CurrentQueryNotifier>(context, listen: false);
    var navigator = getNavigator();
    var itemList = getTable();

    return Column(
        mainAxisSize: MainAxisSize.min, children: [navigator] + itemList);
  }
}
