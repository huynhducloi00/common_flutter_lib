import '../../../data/customer_model.dart';
import '../../loadingstate/loading_state.dart';
import 'common_child_table.dart';

import '../../data/cloud_obj.dart';
import '../../utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/cloud_table.dart';
import '../common.dart';
import 'current_query_notifier.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';
import 'toggle_sort_filter_helper.dart';

class SelectedIndicesChangeNotifier extends ValueNotifier<List<bool>> {
  SelectedIndicesChangeNotifier(List<bool> value) : super(value);
  static createEmptyBoolList(int length) {
    return List<bool>.generate(length, (int index) => false);
  }
}

class ChildEditTable extends StatefulWidget {
  final CollectionReference databaseRef;
  final bool showAllData;
  final bool showNewButton;
  const ChildEditTable(this.databaseRef,
      {this.showAllData = false, this.showNewButton = true});

  @override
  _ChildEditTableState createState() => _ChildEditTableState();
}

class _ChildEditTableState
    extends LoadingState<ChildEditTable, SchemaAndData<CloudObject>?> {
  CurrentQueryNotifier? currentQueryNotifier;
  List<String>? officialColumns;
  late SchemaAndData<CloudObject> schemaAndData;

  _ChildEditTableState() : super(isRequireData: true);

  void onSort(int index, bool ascending) {
    var newParentParam = currentQueryNotifier!.parentParam.deepClone();
    newParentParam.sortKey = officialColumns![index];
    newParentParam.sortKeyDescending = !ascending;
    currentQueryNotifier!.parentParam = newParentParam;
  }

  getNavigator(BuildContext context) {
    ParentParam parentParam = currentQueryNotifier!.parentParam;
    if (schemaAndData.data.isEmpty) {
      return CommonButton.getButton(context, () {
        currentQueryNotifier!.currentPagingQuery =
            currentQueryNotifier!.originalQuery;
      }, title: 'Về trang đầu');
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
        children: [
      SizedBox(
        width: screenWidth(context) * 0.3,
        height: screenHeight(context) * 0.1,
        child: tableOfTwo({
          'Trường sắp xếp':
              '${schemaAndData.cloudTableSchema.inputInfoMap.map![parentParam.sortKey!]!.fieldDes}-${parentParam.sortKeyDescending! ? "Giảm dần" : "Tăng dần"}',
          // 'Hiển thị sau': toText(
          //     context, databasePagerNotifier.value.startAfter),
          // 'Hiển thị trước': toText(
          //     context, databasePagerNotifier.value.endBefore),
          'Số lượng hiển thị': '${schemaAndData.data.length}',
        }, boldRight: true),
      ),
      widget.showAllData
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamProvider<bool>.value(
                  initialData: false,
                  value: isLoading ? Stream<bool>.value(false) : hasBefore,
                  catchError: (_,error){
                    print("Loi 1 $error");
                    return false;
                  },
                  child: Builder(
                    builder: (BuildContext context) {
                      bool existBefore = Provider.of<bool>(context);
                      return CommonButton.getButton(context, () {
                        // go back
                        currentQueryNotifier!.currentPagingQuery =
                            originalQuery.limit(tableTableRowLimit).endBeforeDocument(
                                schemaAndData.documentSnapshots.first);
                      },
                          title: "",
                          iconData: existBefore ? Icons.navigate_before : null,
                          isEnabled: existBefore);
                    },
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                StreamProvider<bool>.value(
                  initialData: false,
                  value: isLoading ? Stream<bool>.value(false) : hasAfter,
                  catchError: (_,error){
                    print("Loi 2 $error");
                    return false;
                  },
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
              ],
            ),
    ].whereType<Widget>().toList());
  }

  getTableAndHeader(BuildContext context) {
    Map<String, InputInfo> filterVisibleFieldMap =
        schemaAndData.cloudTableSchema.inputInfoMap.filterVisibleFields();
    var selectedIndicesChangeNotifier =
        Provider.of<SelectedIndicesChangeNotifier>(context, listen: false);
    var officialColumnsInputInfo = schemaAndData.cloudTableSchema.inputInfoMap
        .filterVisibleFields()
        .entries
        .map((e) => e.value)
        .toList();

    List<TableRow> extraDataRow = [];
    if (schemaAndData.data.length < tableTableRowLimit) {
      for (int i = 0; i < tableTableRowLimit - schemaAndData.data.length; i++) {
        extraDataRow.add(TableRow(
            children: filterVisibleFieldMap.keys
                .map((e) => Text(
                      'a',
                      style: TextStyle(fontSize: 20),
                    ))
                .toList()));
      }
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
            columns: officialColumnsInputInfo
                .asMap()
                .entries
                .map((entry) => DataColumn(
                        label: Expanded(
                            child: Column(children: [
                      Text(entry.value.fieldDes),
                      Row(children: [
                        toggleSort(context, currentQueryNotifier!,
                            officialColumns![entry.key]),
                        toggleFilter(context, currentQueryNotifier!,
                            entry.value, officialColumns![entry.key]),
                      ])
                    ]))))
                .toList(),
            rows: schemaAndData.data.asMap().entries.map((entry) {
              CloudObject eachRowMap = entry.value;
              Map inducedRow = SchemaAndData.fillInOptionData(
                  eachRowMap.dataMap,
                  schemaAndData.cloudTableSchema.inputInfoMap.map);
              return DataRow(
                  selected: selectedIndicesChangeNotifier.value[entry.key],
                  onSelectChanged: (selected) {
                    selectedIndicesChangeNotifier.value[entry.key] = selected!;
                    setState(() {});
                  },
                  cells: filterVisibleFieldMap.keys.map((field) {
                    return DataCell(Text(
                      toText(context, inducedRow[field] ?? '') ?? '',
                      overflow: TextOverflow.ellipsis,
                      textAlign: schemaAndData.cloudTableSchema.inputInfoMap
                                  .map![field]!.dataType ==
                              DataType.int
                          ? TextAlign.right
                          : TextAlign.left,
                      style: TextStyle(fontSize: 20),
                    ));
                  }).toList());
            }).toList()
            // +
            // extraDataRow
            ));
  }

  getPanelButton(BuildContext context) {
    final cusMap = Provider.of<CustomerMap?>(context);
    ParentParam parentParam = currentQueryNotifier!.parentParam;
    return Consumer<SelectedIndicesChangeNotifier>(builder:
        (BuildContext buildContext,
            SelectedIndicesChangeNotifier selectedIndicesChangeNotifier,
            Widget? child) {
      PrintInfo defaultWindowPrint = schemaAndData.cloudTableSchema.printInfos!
          .where((element) => element.isDefault)
          .toList()[0];
      List<PrintInfo> otherPrints = schemaAndData.cloudTableSchema.printInfos!
          .where((element) => !element.isDefault)
          .toList();
      var selectedIndices = selectedIndicesChangeNotifier.value
          .asMap()
          .entries
          .where((element) => element.key <schemaAndData.data.length && element.value)
          .map((e) => e.key)
          .toList();
      Map? inducedRow = selectedIndices.length == 1
          ? SchemaAndData.fillInOptionData(
              schemaAndData.data[selectedIndices[0]].dataMap,
              schemaAndData.cloudTableSchema.inputInfoMap.map)
          : null;
      return Wrap(
        runSpacing: 30,
        alignment: WrapAlignment.spaceAround,
        children: [
          ChildTableUtils.printButton(
            context,
            widget.databaseRef,
            defaultWindowPrint,
            parentParam,
          ),
          ChildTableUtils.printLineButton(
            context,
            schemaAndData.cloudTableSchema.printTicket,
            inducedRow,
            selectedIndices.length == 1,
          ),
          otherPrints.isNotEmpty
              ? Container(
                  color: getLoiButtonStyle(context).regularColor,
                  child: DropdownButton(
                    value:0,
                    items: otherPrints.asMap().entries
                        .map((printInfo) => DropdownMenuItem(
                              child: ChildTableUtils.printButton(context,
                                  widget.databaseRef, printInfo.value, parentParam,
                                  backgroundColor: Colors.transparent),
                    value: printInfo.key,
                    ))
                        .toList(),
                    onChanged: (dynamic value) {},
                  ),
                )
              : null,
          widget.showNewButton
              ? ChildTableUtils.newButton(context, widget.databaseRef,
                  schemaAndData.cloudTableSchema.inputInfoMap)
              : null,
          ChildTableUtils.duplicate(
              context, widget.databaseRef, schemaAndData, selectedIndices),
          ChildTableUtils.editButton(
              context, widget.databaseRef, schemaAndData, selectedIndices),
          ChildTableUtils.deleteButton(
              context, widget.databaseRef, schemaAndData, selectedIndices,
              toPopWindow: false)
        ].whereType<Widget>().toList(),
      );
    });
  }

  // if (widget.parentParam.sortKey == fieldName) {
  // // change sort direction
  // widget.parentParam.sortKeyDescending =
  // !widget.parentParam.sortKeyDescending!;
  // } else {
  // widget.parentParam.sortKey = fieldName;
  // widget.parentParam.sortKeyDescending = false;
  // }
  // if (widget.parentParam.filterDataWrappers![fieldName] != null &&
  // widget.parentParam.filterDataWrappers![fieldName]!
  //     .exactMatchValue !=
  // null) {
  // // cannot be sorted and have exact value
  // widget.parentParam.filterDataWrappers!.remove(fieldName);
  // }
  // setState(() {});
  @override
  Widget delegateBuild(BuildContext context) {
    currentQueryNotifier =
        Provider.of<CurrentQueryNotifier>(context, listen: false);
    schemaAndData = data!;
    officialColumns = schemaAndData.cloudTableSchema.inputInfoMap
        .filterVisibleFields()
        .entries
        .map((e) => e.key)
        .toList();
    return ChangeNotifierProvider(create: (_) {
      return SelectedIndicesChangeNotifier(
          SelectedIndicesChangeNotifier.createEmptyBoolList(
              tableTableRowLimit));
    }, child: Builder(
      builder: (BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              getTableAndHeader(context),
              getNavigator(context),
              SizedBox(
                height: 20,
              ),
              getPanelButton(context)
            ]);
      },
    ));
  }
}
