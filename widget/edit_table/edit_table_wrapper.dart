import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../data/cloud_obj.dart';
import '../../data/cloud_table.dart';
import '../../widget/edit_table/child_edit_table.dart';
import '../../widget/edit_table/parent_param.dart';
import 'common_child_table.dart';
import 'current_query_notifier.dart';
import 'phone_child_edit_table.dart';
import 'toggle_sort_filter_helper.dart';

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
      this.showFilterBar = true,
      this.showNewButton = true});

  @override
  _EditTableWrapperState createState() => _EditTableWrapperState();
}

class _EditTableWrapperState extends State<EditTableWrapper> {
  Widget getFilterButtonForMobile(CurrentQueryNotifier currentQueryNotifier) {
    return ExpansionTile(
      title: Text('Lọc'),
      children: widget.cloudTable!.inputInfoMap.map!.entries
          .map((entry) {
            var fieldName = entry.key;
            var inputInfo = entry.value;
            if (inputInfo.needSaving) {
              return ListTile(
                  title: Text(inputInfo.fieldDes),
                  subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Sắp xếp'),
                        toggleSort(context, currentQueryNotifier, fieldName),
                        Text('Lọc'),
                        toggleFilter(
                            context, currentQueryNotifier, inputInfo, fieldName)
                      ]));
            }
            return null;
          })
          .whereType<Widget>()
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final cusMap = Provider.of<CustomerMap?>(context);
    var content = TableWrapper(
      widget.cloudTable,
      widget.dataPickerBundle,
      showNewButton: widget.showNewButton,
      showAllData: widget.showAllData,
    );
    var mobileBuilder = Builder(builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              widget.showFilterBar
                  ? getFilterButtonForMobile(
                      Provider.of<CurrentQueryNotifier>(context))
                  : null,
              content,
            ].whereType<Widget>().toList()),
      );
    });
    return ChangeNotifierProvider(
        create: (_) {
          CollectionReference _databaseRef =
              widget.cloudTable!.getCollectionRef();
          return CurrentQueryNotifier(_databaseRef, widget.parentParam,
              widget.cloudTable!.tableRowLimit);
        },
        child: widget.dataPickerBundle == null
            ? ScreenTypeLayout(
                // breakpoints: forDebuggingScreenBreakpoints(),
                mobile: mobileBuilder,
                tablet: content)
            : mobileBuilder);
  }
}

class TableWrapper extends StatefulWidget {
  @override
  _TableWrapperState createState() => _TableWrapperState();

  CloudTableSchema? cloudTable;
  DataPickerBundle? dataPickerBundle;
  bool showAllData;
  bool showNewButton;

  TableWrapper(this.cloudTable, this.dataPickerBundle,
      {Key? key, this.showAllData = false, this.showNewButton = true})
      : super(key: key);
}

class _TableWrapperState extends State<TableWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentQueryNotifier>(
      builder: (BuildContext context, CurrentQueryNotifier currentQueryNotifier,
          Widget? child) {
        // startAfter ... table ... endBefore, which affected by sort direction
        bool reverse = false;
        if (!widget.showAllData) {}
        Stream<SchemaAndData<CloudObject>?> newSnapshotStream =
            currentQueryNotifier.currentPagingQuery.snapshots().map((snapshot) {
          return widget.cloudTable!.convertSnapshotToDataList(snapshot);
        });
        return StreamProvider.value(
            value: newSnapshotStream,
            initialData: null,
            catchError: (context, error) {
              print("Stream Error $error");
              return null;
            },
            child: widget.dataPickerBundle == null
                ? ScreenTypeLayout(
                    // breakpoints: forDebuggingScreenBreakpoints(),
                    tablet: ChildEditTable(
                      currentQueryNotifier.colRef,
                      showAllData: widget.showAllData,
                      showNewButton: widget.showNewButton,
                      tableRowLimit: widget.cloudTable!.tableRowLimit,
                    ),
                    mobile: PhoneChildEditTable(
                      currentQueryNotifier.colRef,
                      showAllData: widget.showAllData,
                      showNewButton: widget.showNewButton,
                    ))

                // always use phone pick styles when there is a need to pick
                : PhoneChildEditTable(
                    currentQueryNotifier.colRef,
                    dataPickerBundle: widget.dataPickerBundle,
                    showAllData: widget.showAllData,
                  ));
      },
    );
  }
}
