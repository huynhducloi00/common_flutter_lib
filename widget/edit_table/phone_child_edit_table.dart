import '../../loadingstate/loading_stream_builder.dart';
import '../../utils.dart';
import '../../widget/edit_table/child_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pdf/no_op_create_pdf.dart'
    if (dart.library.html) '../../pdf/pdf_creator.dart' as create_pdf;
import '../../data/cloud_table.dart';
import '../../utils/auto_form.dart';
import '../common.dart';
import 'common_child_table.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';

class PhoneChildEditTable<SchemaAndData> extends StatefulWidget {
  final CollectionReference databaseRef;

  PhoneChildEditTable(this.databaseRef);

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
    String result = toText(context, row[fieldList[0]]);
    fieldList.sublist(1).forEach((field) {
      result += ', ${toText(context, row[field])}';
    });
    return result;
  }

  @override
  Widget delegateBuild(BuildContext context) {
    ParentParam parentParam = Provider.of<ParentParam>(context, listen: false);
    var schemaAndData = data;
    SchemaAndData.fillInOptionData(
        schemaAndData.data, schemaAndData.cloudTableSchema.inputInfoMap);
    Widget navigator = Consumer<DatabasePagerNotifier>(builder:
        (BuildContext context, DatabasePagerNotifier databasePagerNotifier,
            Widget child) {
      if (schemaAndData.data.length == 0) {
        return CommonButton.getButton(context, () {
          databasePagerNotifier.value = ChildParam();
        }, title: 'Về trang đầu');
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
      return Column(mainAxisSize: MainAxisSize.min, children: [
        ExpansionTile(title: Text('Thông tin thêm'), children: <Widget>[
          Wrap(
              runSpacing: 4,
              spacing: 8,
              children: schemaAndData.cloudTableSchema.printInfos
                  .map(
                    (printInfo) => ChildTableUtils.printDefault(
                        context, widget.databaseRef, printInfo, parentParam),
                  )
                  .toList()),
          SizedBox(
            width: screenWidth(context),
            height: screenHeight(context) * 0.1,
            child: tableOfTwo({
              'Trường sắp xếp':
                  '${schemaAndData.cloudTableSchema.inputInfoMap[parentParam.sortKey].fieldDes}-${parentParam.sortKeyDescending ? "Giảm dần" : "Tăng dần"}',
              'Hiển thị sau':
                  toText(context, databasePagerNotifier.value.startAfter),
              'Hiển thị trước':
                  toText(context, databasePagerNotifier.value.endBefore),
              'Số lượng hiển thị': '${schemaAndData.data.length}',
            }, boldRight: true),
          ),
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                      isDense: true,
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
                      startAfter:
                          schemaAndData.data.last.dataMap[parentParam.sortKey]);
                },
                    title: "",
                    iconData: existAfter ? Icons.navigate_next : null,
                    isEnabled: existAfter);
              }),
            ),
            SizedBox(
              width: 20,
            ),
            ChildTableUtils.newButton(
                context, widget.databaseRef, schemaAndData)
          ],
        ),
      ]);
    });
    List<Widget> itemList = schemaAndData.data.asMap().entries.map((entry) {
      var index = entry.key;
      var cloudObj = entry.value;
      var row = cloudObj.dataMap;
      var inputInfoMap = schemaAndData.cloudTableSchema.inputInfoMap;
      return Card(
          child: ListTile(
        title: Text(_concat(row, schemaAndData.cloudTableSchema.primaryFields)),
        subtitle: tableOfTwo(schemaAndData.cloudTableSchema.subtitleFields
            .asMap()
            .map((index, fieldName) => MapEntry(
                inputInfoMap[fieldName].fieldDes,
                toText(context, row[fieldName])))),
        trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: schemaAndData.cloudTableSchema.trailingFields
                .map((fieldName) => Text(toText(context, row[fieldName])))
                .toList()),
        onTap: () {
          showAlertDialog(context, builder: (_) {
            return columnWithGap([
              ChildTableUtils.editButton(
                  context, widget.databaseRef, schemaAndData, index),
              ChildTableUtils.deleteButton(
                  context, widget.databaseRef, schemaAndData, index)
            ], crossAxisAlignment: CrossAxisAlignment.center);
          });
        },
      ));
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [navigator] + itemList,
    );
  }
}
